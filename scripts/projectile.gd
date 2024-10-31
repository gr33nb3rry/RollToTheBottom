extends Node3D

const SPEED : float = 10.0
var direction : Vector3
var is_ballistic := true
	
func _process(delta: float) -> void:
	if direction != Vector3.ZERO:
		global_position += direction * SPEED * delta
		if is_ballistic:
			direction.y -= 1.0 * delta
