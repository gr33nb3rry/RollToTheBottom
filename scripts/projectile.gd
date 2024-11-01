extends RigidBody3D

const TIME_TO_FALL := 5.0
const TIME_TO_DIE := 10.0

func _ready() -> void:
	await get_tree().create_timer(TIME_TO_FALL).timeout
	fall()

func _on_area_body_entered(body: Node3D) -> void:
	if body == self: return
	if body.is_in_group("Ant"):
		body.damage()
		queue_free()
	fall()
	
func fall() -> void:
	gravity_scale = 1
	await get_tree().create_timer(TIME_TO_DIE).timeout
	queue_free()
