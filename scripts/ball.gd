extends RigidBody3D

const INITIAL_MASS : float = 25.0

func grow(value:float) -> void:
	$Mesh.scale += Vector3(value, value, value)
	$Collision.scale += Vector3(value, value, value)
	$Area/Collision.scale += Vector3(value, value, value)
	mass += clamp(INITIAL_MASS * value, 1.0, 75.0)
	update_pieces()
func shrink(value:float) -> void:
	$Mesh.scale -= Vector3(value, value, value)
	$Collision.scale -= Vector3(value, value, value)
	$Area/Collision.scale -= Vector3(value, value, value)
	mass -= clamp(INITIAL_MASS * value, 1.0, 75.0)
	update_pieces()

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_1): shrink(0.05)
	elif Input.is_key_pressed(KEY_2): grow(0.05)


func _on_area_area_entered(area: Area3D) -> void:
	var item = area.get_parent()
	if item.has_meta("dung"):
		var r1 = $Mesh.mesh.radius * $Mesh.scale.x
		var r2 = item.get_node("Mesh").mesh.radius * item.scale.x
		var v1 = get_volume(r1)
		var v2 = get_volume(r2)
		var scale_increase : float = get_radius(v1+v2)/r1-1.0
		grow(scale_increase * 5.0)
		item.queue_free()


func _on_area_area_exited(area: Area3D) -> void:
	pass
	
func update_pieces() -> void:
	for p in $Pieces.get_children():
		var direction = (p.position - Vector3.ZERO).normalized()
		p.position = direction * 2.0 * $Mesh.scale.x

func get_volume(r:float):
	return (4.0/3.0)*PI*pow(r,3)
func get_radius(v:float):
	return pow((3.0 * v / (4.0 * PI)),(1.0 / 3.0))
