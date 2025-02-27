extends RigidBody3D

func _ready() -> void:
	await get_tree().create_timer(20).timeout
	queue_free()
	
func _on_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ant"): return
	if body.is_in_group("Player"):
		body.damage(1)
		queue_free()
	death()
	
func death() -> void:
	queue_free()
