extends Node3D

const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")
@onready var ball = $/root/Main/World/Ball
@onready var world = $/root/Main/World
@onready var enemy_spawner = $/root/Main/World/EnemySpawner
@onready var path: Path3D = $Path3D
@onready var path_follow: PathFollow3D = $Curve/PathFollow
@onready var marker: MeshInstance3D = $Curve/PathFollow/Marker
@onready var marker_r: MeshInstance3D = $Curve/PathFollow/Marker/R
@onready var marker_l: MeshInstance3D = $Curve/PathFollow/Marker/L

var ball_radius : float = 2.0
var max_h_offset : float = 10.0

func _ready() -> void:
	$Curve.get_child(1).create_trimesh_collision()
	if has_node("CurveB"): 
		for i in $CurveB.get_children():
			i.get_child(0).create_trimesh_collision()

func _process(delta: float) -> void:
	var ball_dir : Vector3 = ball.get_linear_velocity()
	ball_dir.y = 0.0
	var ball_pos : Vector3 = ball.global_position + ball_dir.normalized() * 25.0
	var p = path.curve.get_closest_offset(path.to_local(ball_pos))
	var r = get_radius_on_pos(path.to_local(marker.global_position))
	path_follow.progress = p
	path_follow.v_offset = r + ball_radius
	marker_l.position.x = -r
	marker_r.position.x = r
	
func get_next_zone_position() -> Vector3:
	return $Room/Pos2.global_position
func get_next_zone_rotation() -> Vector3:
	return $Room.rotation + rotation

func get_next_marker() -> Vector3:
	return marker.global_position

func get_closest_point_of(of:Node3D) -> Vector3:
	return path.curve.get_closest_point(path.to_local(of.global_position))
	
func get_radius_on_pos(pos:Vector3) -> float:
	return $Curve.radius_profile.sample(path.curve.get_closest_offset(pos) / path.curve.get_baked_length()) * $Curve.radius

func is_marker_completed() -> bool:
	return path.curve.get_closest_offset(path.to_local(marker.global_position)) == path.curve.get_baked_length()

func get_near_flying_position() -> Vector3:
	var h_off = randi_range(0, max_h_offset) * (1 if randi() % 2 else -1)
	var v_off = randf_range(2, 6)
	var side : Vector3 = marker_l.global_position if h_off < 0 else marker_r.global_position
	side.x += h_off
	side.y += v_off
	print("h: ",h_off," v: ",v_off)
	return side

func get_next_near_flying_position() -> Vector3:
	var r : float = get_radius_on_pos(path.to_local(marker.global_position))
	var h_off = randi_range(0, max_h_offset + r) * (1 if randi() % 2 else -1)
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
		enemy_spawner.add_child(soot)
		soot.global_position = global_point
