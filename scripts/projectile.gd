extends Node3D

@export var type : int = 0
var direction : Vector3
var power : float = 20.0
var rotation_deg : float = 360.0
var is_on_ground : bool = false

func _ready() -> void:
	$Model.look_at(global_position + direction * 10)
	await get_tree().create_timer(20).timeout
	queue_free()
	
func _process(delta: float) -> void:
	global_position += direction * power * delta
	
func _on_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"): return
	if body.is_in_group("Soot"):
		body.damage(1)
		queue_free()
	death()
	
func death() -> void:
	queue_free()
