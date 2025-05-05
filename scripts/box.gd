extends RigidBody3D

var gravity : Vector3

func _ready() -> void:
	await get_tree().create_timer(1).timeout
	gravity = Globals.world.get_zone().get_node("ActivityPoint").global_position
	clip_to_ground()
	
func _physics_process(delta: float) -> void:
	return
	if !$RayGround.is_colliding(): 
		linear_velocity = -gravity.normalized() * 9.8 * delta

func clip_to_ground() -> void:
	var angle = get_angle_to_point_around_z(gravity)
	rotation_degrees.z -= angle
	
	global_position = $Ray.get_collision_point()
	position.y += 1.0

	
func get_angle_to_point_around_z(target_point: Vector3) -> float:
	var origin = global_transform.origin
	var to_target = (target_point - origin).normalized()

	# В 2D-проекции на XY-плоскость (оси X и Y), т.к. вращаем по Z
	var down = -global_transform.basis.y
	var from_vec = Vector2(down.x, down.y).normalized()
	var to_vec = Vector2(to_target.x, to_target.y).normalized()

	var angle_rad = from_vec.angle_to(to_vec) # в радианах
	var angle_deg = rad_to_deg(angle_rad)
	return angle_deg
