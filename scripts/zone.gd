extends Node3D

@onready var ball = $/root/Main/World/Ball
@onready var path: Path3D = $Path3D
@onready var path_follow: PathFollow3D = $Curve/PathFollow
@onready var marker: MeshInstance3D = $Curve/PathFollow/Marker
@onready var marker_r: MeshInstance3D = $Curve/PathFollow/Marker/R
@onready var marker_l: MeshInstance3D = $Curve/PathFollow/Marker/L

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

func get_near_flying_position() -> Vector3:
	var h_off = randi_range(0,10) * (1 if randi() % 2 else -1)
	var v_off = randf_range(2,6)
	var side : Vector3 = marker_l.global_position if h_off < 0 else marker_r.global_position
	side.x += h_off
	side.y += v_off
	print("h: ",h_off," v: ",v_off)
	return side
