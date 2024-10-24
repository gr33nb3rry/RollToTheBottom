extends RigidBody3D

func _process(delta: float) -> void:
	#grow(0.5 * delta)
	pass

func grow(value:float) -> void:
	$Mesh.scale += Vector3(value, value, value)
	$Collision.scale += Vector3(value, value, value)
func shrink(value:float) -> void:
	$Mesh.scale -= Vector3(value, value, value)
	$Collision.scale -= Vector3(value, value, value)


func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_1): shrink(0.5)
	elif Input.is_key_pressed(KEY_2): grow(0.5)
