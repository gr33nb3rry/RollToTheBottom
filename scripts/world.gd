extends Node3D

@onready var ball = $/root/Main/World/Ball

var zone : int = 1
var current_zone_instance : Node3D

func start() -> void:
	current_zone_instance = get_zone()
	ball.is_simplified = true
	
func get_zone() -> Node3D:
	return $Map.get_child(zone-1)
	
func get_zone_next_marker() -> Vector3:
	return current_zone_instance.get_next_marker()
	
func _physics_process(delta: float) -> void:
	return
	if ball.linear_velocity.length() > 0.1 and current_zone_instance:
		var direction = (get_zone_next_marker() - ball.global_position).normalized()
		ball.linear_velocity += direction * delta * 5
		if ball.linear_velocity.length() < 0.1:
			ball.linear_velocity = Vector3.ZERO

	
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_0): start()
	
