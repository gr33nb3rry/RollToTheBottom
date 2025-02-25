extends Node3D

@onready var ball = $/root/Main/World/Ball
@onready var path: Path3D = $Path3D
var ball_radius : float = 2.0

func _ready() -> void:
	$Curve.get_child(0).create_trimesh_collision()
	if has_node("CurveB"): 
		for i in $CurveB.get_children():
			i.get_child(0).create_trimesh_collision()

func _process(delta: float) -> void:
	var ball_dir : Vector3 = ball.get_linear_velocity()
	ball_dir.y = 0.0
	var ball_pos : Vector3 = ball.global_position + ball_dir.normalized() * 25.0
	var marker_pos : Vector3 = $Marker.global_position
	var p = path.curve.get_closest_point(path.to_local(ball_pos))
	var r = $Curve.radius_profile.sample(path.curve.get_closest_offset(path.to_local(marker_pos)) / path.curve.get_baked_length()) * $Curve.radius
	$Marker.global_position = path.to_global(p) + Vector3(0, r + ball_radius, 0)
	
func get_next_zone_position() -> Vector3:
	return $Room/Pos2.global_position
func get_next_zone_rotation() -> Vector3:
	return $Room.rotation + rotation

func get_next_marker() -> Vector3:
	return $Marker.global_position
