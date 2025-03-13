extends Node3D

@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World
const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
var is_ball_inside : bool = false
var players_inside_count : int = 0


func _ready() -> void:
	process_mode = PROCESS_MODE_DISABLED


func get_jumping_start_position() -> Vector3:
	return to_global($Pos1.position + Vector3(0, 0, 5))
	
	
func _on_area_1_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		players_inside_count += 1
	elif body.name == "Ball":
		is_ball_inside = true
	if players_inside_count == 1 and is_ball_inside:
		world.end()
func _on_area_1_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		players_inside_count -= 1
	elif body.name == "Ball":
		is_ball_inside = false

# START 
func _on_area_2_body_exited(body: Node3D) -> void:
	pass # Replace with function body.
