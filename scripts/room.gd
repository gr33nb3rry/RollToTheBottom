extends Node3D

const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
var is_ball_inside : bool = false
var players_inside_count : int = 0
@export var is_initial : bool = false
var is_completed : bool = false

func _ready() -> void:
	if !is_initial: process_mode = Node.PROCESS_MODE_DISABLED
	if multiplayer.is_server():
		open_door($Door1)
	if multiplayer.get_unique_id() != 1:
		disable()

func disable() -> void:
	$Area1.process_mode = Node.PROCESS_MODE_DISABLED

func get_jumping_start_position() -> Vector3:
	return to_global($Pos1.position + Vector3(0, 0, 5))
	
	
func _on_area_1_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		players_inside_count += 1
	elif body.name == "Ball":
		is_ball_inside = true
	if players_inside_count == 1 and is_ball_inside and !is_completed:
		close_door($Door1)
		open_door($Door2)
		if !is_initial: Globals.world.end()
		else: Globals.world.start()
		
func _on_area_1_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		players_inside_count -= 1
	elif body.name == "Ball":
		is_ball_inside = false
	if !is_ball_inside and players_inside_count == 0 and $Door1.visible:
		close_door($Door2)
		#Globals.enemy_spawner.start()

func open_door(door) -> void:
	print("open ", door)
	var t = get_tree().create_tween()
	t.tween_property(door, "rotation_degrees:x", -90 if door == $Door1 else 90, 1)
func close_door(door) -> void:
	if door == $Door1:
		is_completed = true
	var t = get_tree().create_tween()
	t.tween_property(door, "rotation_degrees:x", 0, 1)
