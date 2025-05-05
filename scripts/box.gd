extends RigidBody3D

const DECAL_0 = preload("res://images/decals/decal1.png")
const DECAL_1 = preload("res://images/decals/decal5.png")

var type : int = 0

func _ready() -> void:
	generate_type()

func generate_type() -> void:
	type = randi_range(0, 1)
	$Mesh/Decal.texture_albedo = DECAL_0 if type == 0 else DECAL_1
	
func damage(player_type:int) -> void:
	if player_type == type:
		death()
		
func death() -> void:
	queue_free()

func clip_to_ground() -> void:
	var angle = get_angle_to_point_around_z(Globals.world.get_zone().get_node("ActivityPoint").global_position)
	rotation_degrees.z -= angle
	
	global_position = $Ray.get_collision_point()
	position.y += 1.0

	
func get_angle_to_point_around_z(target_point: Vector3) -> float:
	var origin = global_transform.origin
	var to_target = (target_point - origin).normalized()
	var down = -global_transform.basis.y
	var from_vec = Vector2(down.x, down.y).normalized()
	var to_vec = Vector2(to_target.x, to_target.y).normalized()
	var angle_rad = from_vec.angle_to(to_vec)
	var angle_deg = rad_to_deg(angle_rad)
	return angle_deg
