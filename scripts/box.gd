extends RigidBody3D

const DECAL_0 = preload("res://images/kohaku_icon.png")
const DECAL_1 = preload("res://images/utsuri_icon.png")

var type : int = 0
var rotation_speed : Vector3
var pivot : Vector3

func _ready() -> void:
	rotation_speed = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	match randi_range(1, 3):
		1: rotation_speed.x = 0.0
		2: rotation_speed.y = 0.0
		3: rotation_speed.z = 0.0
	rotation_speed = rotation_speed.normalized()
	

func _physics_process(delta: float) -> void:
	$Mesh.rotate_object_local(Vector3.RIGHT, rotation_speed.x * delta)
	$Mesh.rotate_object_local(Vector3.UP, rotation_speed.y * delta)
	$Mesh.rotate_object_local(Vector3.BACK, rotation_speed.z * delta)


func generate_type() -> void:
	#if multiplayer.is_server(): return
	type = randi_range(0, 1)
	var h : float = randf_range(1.5, 2.5)
	update_by_type(type, h)
	update_by_type.rpc_id(1, type, h)

@rpc("any_peer")
func update_by_type(t:int, height:float) -> void:
	type = t
	$Mesh/Decal.texture_albedo = DECAL_0 if type == 0 else DECAL_1
	clip_to_ground(height)
	
	
func damage(player_type:int) -> void:
	if player_type == type:
		if multiplayer.is_server(): death()
		else: death.rpc_id(1)
		
@rpc("any_peer")
func death() -> void:
	$Stick/Sphere.visible = true
	$Mesh.visible = false

func clip_to_ground(height:float) -> void:
	visible = false
	look_at(pivot)
	rotation_degrees.x += 90
	await get_tree().create_timer(0.2).timeout
	global_position = $Ray.get_collision_point() + ($Ray.get_collision_point() - pivot).normalized() * height
	visible = true
