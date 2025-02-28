extends Node3D

@onready var ball = $/root/Main/World/Ball

var zone : int = 1
var current_zone_instance : Node3D

func start() -> void:
	current_zone_instance = get_zone()
	ball.is_simplified = true
func end() -> void:
	get_tree().call_group("Ant", "death")
	
	
func get_zone() -> Node3D:
	return $Map.get_child(zone-1)
	
func get_zone_next_marker() -> Vector3:
	return current_zone_instance.get_next_marker()

func get_closest_point_of(of:Node3D) -> Vector3:
	return current_zone_instance.get_closest_point_of(of)
	
func get_radius_on_pos(pos:Vector3) -> float:
	return current_zone_instance.get_radius_on_pos(pos)

func get_near_flying_position(of:Node3D) -> Vector3:
	return await current_zone_instance.get_near_flying_position(of)
	
func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_0): start()
	
