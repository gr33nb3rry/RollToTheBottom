extends Node3D

@onready var ball = $/root/Main/World/Ball
@onready var path: Path3D = $Path3D
var ball_radius : float = 2.0

func _ready() -> void:
	$Curve.get_child(1).create_trimesh_collision()
	if has_node("CurveB"): 
		for i in $CurveB.get_children():
			i.get_child(0).create_trimesh_collision()

func _process(delta: float) -> void:
	var ball_dir : Vector3 = ball.get_linear_velocity()
	ball_dir.y = 0.0
	var ball_pos : Vector3 = ball.global_position + ball_dir.normalized() * 25.0
	var marker_pos : Vector3 = $Marker.global_position
	var p = path.curve.get_closest_point(path.to_local(ball_pos))
	var r = get_radius_on_pos(path.to_local(marker_pos))
	$Marker.global_position = path.to_global(p) + Vector3(0, r + ball_radius, 0)
	
func get_next_zone_position() -> Vector3:
	return $Room/Pos2.global_position
func get_next_zone_rotation() -> Vector3:
	return $Room.rotation + rotation

func get_next_marker() -> Vector3:
	return $Marker.global_position

func get_closest_point_of(of:Node3D) -> Vector3:
	return path.curve.get_closest_point(path.to_local(of.global_position))
	
func get_radius_on_pos(pos:Vector3) -> float:
	return $Curve.radius_profile.sample(path.curve.get_closest_offset(pos) / path.curve.get_baked_length()) * $Curve.radius

func get_near_flying_position(of:Node3D) -> Vector3:
	var r = get_radius_on_pos(path.to_local(of.global_position))
	var h_off = (r + randi_range(0,10)) * (1 if randi() % 2 else -1)
	var v_off = r + randf_range(0,5)
	print("r: ",r," h: ",h_off," v: ",v_off)
	$Curve/PathFollow.progress = path.curve.get_closest_offset(path.to_local(of.global_position))
	$Curve/PathFollow.h_offset = h_off
	$Curve/PathFollow.v_offset = v_off
	await get_tree().process_frame
	return $Curve/PathFollow.global_position
