extends Node3D

const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")
const DECAL_ZONE = preload("res://scenes/decal_zone.tscn")
const BARRIER_P = preload("res://scenes/barrier_p.tscn")
const DECAL_0 = preload("res://images/decals/decal0.png")
const DECAL_1 = preload("res://images/decals/decal1.png")
const DECAL_2 = preload("res://images/decals/decal2.png")
const DECAL_3 = preload("res://images/decals/decal3.png")
const DECAL_4 = preload("res://images/decals/decal4.png")
const DECAL_5 = preload("res://images/decals/decal5.png")

var STEPS : Dictionary = {
	"BARRIER_MIN": 75.0,
	"BARRIER_AVG": 30.0,
	"BARRIER_MAX": 10.0,
	"BARRIER_CHAOS": 2.5
}

@onready var path: Path3D = $Path3D
@onready var path_follow: PathFollow3D = $Curve/PathFollow
@onready var marker: MeshInstance3D = $Curve/PathFollow/Marker
@onready var marker_r: MeshInstance3D = $Curve/PathFollow/Marker/R
@onready var marker_l: MeshInstance3D = $Curve/PathFollow/Marker/L
@onready var decals_maker: PathFollow3D = $Curve/DecalsMaker
@onready var decals_center: MeshInstance3D = $Curve/DecalsMaker/Center
@onready var activity_point: Marker3D = $ActivityPoint/Pos


var decals_count : Array = [0, 0, 0, 0, 0, 0]
var barrier_pivots : Array = []
var is_activity_started : bool = false
var is_activity_finished : bool = false
var is_finished : bool = false
var is_end : bool = false

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
	if multiplayer.get_unique_id() != 1:
		decals_maker.queue_free()

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
		Globals.ball.freeze = true
		var t = get_tree().create_tween()
		t.tween_property(Globals.ball, "global_position", $ActivityPoint/BallPos.global_position, 2.0).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
		Globals.world.start_activity()
	elif !is_finished and is_activity_started and is_activity_finished:
		is_finished = true
		Globals.ball.is_active = true
		Globals.ball.freeze = false
	

func generate_decals() -> void:
	if !multiplayer.is_server(): return
	var offset : float = 20.0
	var end_offset : float = 40.0 if !is_end else 120.0
	var max : float = path.curve.get_baked_length() - end_offset
	var step : float = 7.0
	var iteration_count : int = floori(max / step)
	decals_maker.progress = offset
	decals_count = [0, 0, 0, 0, 0, 0]
	# DECALS
	
	var count : int = 0
	for i in iteration_count:
		var m : MeshInstance3D = decals_center.get_node("Mesh")
		var type : int = randi_range(0, 5)
		decals_count[type] += 1
		decals_maker.progress += step
		decals_center.get_node("Mesh").rotation_degrees.y = randf_range(0.0, 360.0)
		decals_center.rotation_degrees.z = randf_range(0.0, 360.0)
		await get_tree().physics_frame
		var d : Decal = DECAL_ZONE.instantiate()
		var pos : Vector3 = m.global_position - m.global_transform.basis.y * 8.0
		var rot : Vector3 = m.global_rotation
		Globals.world.decal_info.append([pos, rot, type])
		Globals.world.get_node("Decals").add_child(d, true)
		#update_decal_position_rotation_type(count, pos, rot, type)
		#update_decal_position_rotation_type.rpc_id(Globals.ms.get_second_player_peer_id(), count, pos, rot, type)
		count += 1
	# REFRESH
	decals_maker.progress = offset
	barrier_pivots = []
	step = get_barriers_step()
	iteration_count = floori(max / step)
	#iteration_count = 1
	for i in $Markers.get_children(): i.queue_free()
	# MARKERS
	for i in iteration_count:
		decals_maker.progress += step
		decals_center.rotation_degrees.z = randf_range(-33.0, 33.0)
		await get_tree().physics_frame
		var m : Marker3D = Marker3D.new()
		$Markers.add_child(m)
		barrier_pivots.append(decals_maker.global_position)
		m.global_position = decals_center.get_node("Mesh").global_position
	var arr : Array[Vector3] = []
	for i in $Markers.get_children():
		arr.append(i.global_position)
	add_barriers(arr, barrier_pivots)

func add_barriers(arr:Array, barrier_pivots:Array) -> void:
	var count : int = 0
	for i in arr:
		var b : RigidBody3D = BARRIER_P.instantiate()
		Globals.world.barrier_info.append([arr[count], barrier_pivots[count]])
		Globals.world.get_node("Barriers").add_child(b, true)
		#update_barrier(count, arr[count], barrier_pivots[count])
		#update_barrier.rpc_id(Globals.ms.get_second_player_peer_id(), count, arr[count], barrier_pivots[count])
		if count == arr.size() - 1:
			print("End")
			Globals.world.get_previous_room().open()
		count += 1
		
@rpc("any_peer")
func update_barrier(index:int, pos:Vector3, pivot:Vector3) -> void:
	print("Index: ", index, " pivot: ", pivot, " Pipa: ", Globals.world.get_node("Barriers").get_child(index))
	Globals.world.get_node("Barriers").get_child(index).global_position = pos
	Globals.world.get_node("Barriers").get_child(index).pivot = pivot
	Globals.world.get_node("Barriers").get_child(index).generate_type()

@rpc("any_peer")
func update_decal_position_rotation_type(index:int, pos:Vector3, rot:Vector3, type:int) -> void:
	print(333)
	print("Index: ", index, " pos: ", pos)
	
	Globals.world.get_node("Decals").get_child(index).global_position = pos
	Globals.world.get_node("Decals").get_child(index).global_rotation = rot
	Globals.world.get_node("Decals").get_child(index).type = type
	match type:
		0: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_0
		1: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_1
		2: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_2
		3: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_3
		4: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_4
		5: Globals.world.get_node("Decals").get_child(index).texture_albedo = DECAL_5
	
func get_barriers_step() -> float:
	var steps : Array
	if !is_end:
		steps = ["BARRIER_MIN","BARRIER_MIN","BARRIER_AVG","BARRIER_AVG","BARRIER_AVG","BARRIER_MAX","BARRIER_MAX","BARRIER_CHAOS"]
	else:
		steps = ["BARRIER_MIN","BARRIER_MIN","BARRIER_AVG"]
	return STEPS[steps[randi_range(0, steps.size() - 1)]]
	
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

func get_resurrect_position(pos:Vector3) -> Vector3:
	var r = get_radius_on_pos(path.to_local(pos))
	var p : Vector3 = path.curve.get_closest_point(path.to_local(pos))
	var result_pos : Vector3 = path.to_global(p)
	result_pos.y += r + 5.0
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

func _input(event: InputEvent) -> void:
	if multiplayer.is_server():
		if Input.is_key_pressed(KEY_L):
			update_decal_position_rotation_type.rpc_id(Globals.ms.get_second_player_peer_id(), 0, Vector3(1, 1000, 3), Vector3.ZERO, 0)
