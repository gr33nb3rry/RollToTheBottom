extends Node3D

const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")
const DECAL_0 = preload("res://images/decals/decal0.png")
const DECAL_1 = preload("res://images/decals/decal1.png")
const DECAL_2 = preload("res://images/decals/decal2.png")
const DECAL_3 = preload("res://images/decals/decal3.png")
const DECAL_4 = preload("res://images/decals/decal4.png")
const DECAL_5 = preload("res://images/decals/decal5.png")

@onready var path: Path3D = $Path3D
@onready var path_follow: PathFollow3D = $Curve/PathFollow
@onready var marker: MeshInstance3D = $Curve/PathFollow/Marker
@onready var marker_r: MeshInstance3D = $Curve/PathFollow/Marker/R
@onready var marker_l: MeshInstance3D = $Curve/PathFollow/Marker/L
@onready var decals_maker: PathFollow3D = $Curve/DecalsMaker
@onready var decals_center: MeshInstance3D = $Curve/DecalsMaker/Center
@onready var activity_point: Marker3D = $ActivityPoint/Pos


var decals_count : Array = [0, 0, 0, 0, 0, 0]
var is_activity_started : bool = false
var is_activity_finished : bool = false

var ball_radius : float = 2.0
var max_h_offset : float = 10.0

func _ready() -> void:
	$Curve.get_child(2).create_trimesh_collision()
	$Curve.get_child(2).get_child(0).set_collision_layer_value(3, true)
	$Curve.get_child(2).set_layer_mask(524288)
	if has_node("CurveB"): 
		for i in $CurveB.get_children():
			i.get_child(0).create_trimesh_collision()
			i.get_child(0).get_child(0).set_collision_layer_value(3, true)
			i.get_child(0).set_layer_mask(524288)
	#process_mode = Node.PROCESS_MODE_DISABLED
	activity_decal_animation()
	generate_decals()

func _process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	# BALL SIMPLICITY
	var ball_dir : Vector3 = Globals.ball.get_linear_velocity()
	ball_dir.y = 0.0
	var ball_pos : Vector3 = Globals.ball.global_position + ball_dir.normalized() * 25.0
	var p = path.curve.get_closest_offset(path.to_local(ball_pos))
	var r = get_radius_on_pos(path.to_local(marker.global_position))
	path_follow.progress = p
	path_follow.v_offset = r + ball_radius
	marker_l.position.x = -r
	marker_r.position.x = r
	# ACTIVITY CHECKER
	if !is_activity_started and activity_point.global_position.distance_squared_to(Globals.ball.global_position) < 289.0:
		is_activity_started = true
		Globals.ball.stop()
		Globals.ball.is_active = false
		var t = get_tree().create_tween()
		t.tween_property(Globals.ball, "global_position", $ActivityPoint/BallPos.global_position, 2.0).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		Globals.world.start_activity()
	elif is_activity_started and is_activity_finished:
		Globals.ball.is_active = true
	
func generate_decals() -> void:
	if !multiplayer.is_server(): return
	var offset : float = 20.0
	var step : float = 7.0
	var max : float = path.curve.get_baked_length() - offset
	var iteration_count : int = floori(max / step)
	decals_maker.progress = offset
	
	for i in iteration_count:
		var decal : Decal = decals_center.get_node("Mesh/Decal")
		var type : int = randi_range(0, 5)
		match type:
			0: decal.texture_albedo = DECAL_0
			1: decal.texture_albedo = DECAL_1
			2: decal.texture_albedo = DECAL_2
			3: decal.texture_albedo = DECAL_3
			4: decal.texture_albedo = DECAL_4
			5: decal.texture_albedo = DECAL_5
		decals_count[type] += 1
		decals_maker.progress += step
		decals_center.get_node("Mesh").rotation_degrees.y = randf_range(0.0, 360.0)
		decals_center.rotation_degrees.z = randf_range(0.0, 360.0)
		await get_tree().process_frame
		await get_tree().process_frame
		var d : Decal = decal.duplicate()
		d.type = type
		$Decals.add_child(d)
		update_decal_position_rotation_type(d, decal.global_position, decal.global_rotation, d.type)
		update_decal_position_rotation_type.rpc_id(Globals.ms.get_second_player_peer_id(), d, decal.global_position, decal.global_rotation, d.type)
		
	decals_maker.queue_free()
	print(decals_count)

@rpc("any_peer")
func update_decal_position_rotation_type(decal:Decal, pos:Vector3, rot:Vector3, type:int) -> void:
	decal.global_position = pos
	decal.global_rotation = rot
	decal.type = type
	
func get_decals() -> Array:
	return $Decals.get_children()
func get_decal_count(type:int) -> int:
	return decals_count[type]
	
func get_next_zone_position() -> Vector3:
	return $Room/Pos2.global_position
func get_next_zone_rotation() -> Vector3:
	return $Room.rotation + rotation

func get_next_marker() -> Vector3:
	return marker.global_position

func get_closest_point_of(of:Node3D) -> Vector3:
	return path.to_global(path.curve.get_closest_point(path.to_local(of.global_position)))
	
func get_coin_position(pos:Vector3) -> Vector3:
	var local_pos : Vector3 = path.to_local(pos)
	return path.to_global(path.curve.get_closest_point(local_pos)) + Vector3.UP * get_radius_on_pos(local_pos)

func get_radius_on_pos(pos:Vector3) -> float:
	return $Curve.radius_profile.sample(path.curve.get_closest_offset(pos) / path.curve.get_baked_length()) * $Curve.radius

func is_marker_completed() -> bool:
	return path.curve.get_closest_offset(path.to_local(marker.global_position)) == path.curve.get_baked_length()

func get_near_flying_position() -> Vector3:
	var h_off = randf_range(0, max_h_offset) * (1 if randi() % 2 else -1)
	var v_off = randf_range(2, 6)
	var side : Vector3 = marker_l.global_position if h_off < 0 else marker_r.global_position
	side.x += h_off
	side.y += v_off
	print("h: ",h_off," v: ",v_off)
	return side

func get_next_near_flying_position() -> Vector3:
	var r : float = get_radius_on_pos(path.to_local(marker.global_position))
	var h_off = randf_range(0, max_h_offset + r) * (1 if randi() % 2 else -1)
	var v_off = randf_range(2, 6) + r
	var pos : Vector3 = marker.global_position
	pos.x += h_off
	pos.y += v_off
	print("h: ",h_off," v: ",v_off)
	return pos

func get_next_jumping_position(pos:Vector3) -> Vector3:
	var r = get_radius_on_pos(path.to_local(pos))
	var p : Vector3 = path.curve.get_closest_point(path.to_local(pos))
	var result_pos : Vector3 = path.to_global(p)
	result_pos.y += r
	print("r: ",r," pos: ",pos," result_pos: ",result_pos)
	return result_pos

func add_waiting_soots() -> void:
	var soot_count := 10
	var path_length := path.curve.get_baked_length()
	var min_offset := 10.0
	var max_offset := path_length - 10.0

	for i in range(soot_count):
		var offset := min_offset + (max_offset - min_offset) * (float(i) / float(soot_count - 1))  
		var point := path.curve.sample_baked(offset)
		var global_point := path.to_global(point) + Vector3(0, get_radius_on_pos(point) - 1.0, 0)
		print("Spawning SOOT_WAITING at:", global_point)
		var soot := SOOT_WAITING.instantiate()
		Globals.enemy_spawner.add_child(soot, true)
		soot.global_position = global_point
	
func get_passed_position() -> float:
	return path_follow.progress

func get_length() -> float:
	return path.curve.get_baked_length()

func activity_decal_animation() -> void:
	$ActivityPoint/Decal.rotation_degrees.y = 0
	var t = get_tree().create_tween()
	t.tween_property($ActivityPoint/Decal, "rotation_degrees:y", -360, 20.0)
	await t.finished
	activity_decal_animation()

func disable() -> void:
	process_mode = PROCESS_MODE_DISABLED
	$Room.disable()
	for decal in $Decals.get_children(): decal.queue_free()
