extends RigidBody3D

@export var type : int = 0

func _ready() -> void:
	await get_tree().create_timer(20).timeout
	queue_free()
	
func _on_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Ant"): return
	if body.is_in_group("Player"):
		hit(body)
		queue_free()
	death()
	
func death() -> void:
	queue_free()

func hit(body: Node3D) -> void:
	if type == 0:
		body.damage(1)
	elif type == 1:
		body.damage(1)
