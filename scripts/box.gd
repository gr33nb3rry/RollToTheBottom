extends RigidBody3D

const DECAL_0 = preload("res://images/kohaku_icon.png")
const DECAL_1 = preload("res://images/utsuri_icon.png")

var type : int = 0

func _ready() -> void:
	generate_type()

func generate_type() -> void:
	if multiplayer.is_server(): return
	type = randi_range(0, 1)
	update_by_type(type)
	update_by_type.rpc_id(1, type)

@rpc("any_peer")
func update_by_type(t:int) -> void:
	type = t
	$Mesh/Decal.texture_albedo = DECAL_0 if type == 0 else DECAL_1
	$Mesh.mesh.material.albedo_color = Color.WHITE if type == 0 else Color.BLACK

	
	
func damage(player_type:int) -> void:
	if player_type == type:
		if multiplayer.is_server(): death()
		else: death.rpc_id(1)
		
@rpc("any_peer")
func death() -> void:
	queue_free()

func clip_to_ground(pivot:Vector3) -> void:
	visible = false
	look_at(pivot)
	rotation_degrees.x += 90
	await get_tree().create_timer(0.2).timeout
	global_position = $Ray.get_collision_point() + ($Ray.get_collision_point() - pivot).normalized() * 1.5
	visible = true
