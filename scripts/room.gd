extends Node3D

const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
const RADIUS : float = 23.0
var is_ball_inside : bool = false
var is_both_players_inside : bool = false
@export var is_initial : bool = false
var status : int = 0

func _ready() -> void:
	if !is_initial: process_mode = Node.PROCESS_MODE_DISABLED
	if multiplayer.is_server():
		open_door($Door1)
	#if multiplayer.get_unique_id() != 1:
	#	disable()

func _process(delta: float) -> void:
	$Flower.rotation.y += 0.05 * delta
	if !multiplayer.is_server(): return
	var distance_to_ball : float = global_position.distance_squared_to(Globals.ball.global_position)
	is_ball_inside = distance_to_ball < RADIUS * RADIUS
	var players_inside_count : int = 0
	for p in get_tree().get_nodes_in_group("Player"):
		var distance : float = global_position.distance_squared_to(p.global_position)
		if distance < RADIUS * RADIUS:
			players_inside_count += 1
	is_both_players_inside = players_inside_count == get_tree().get_node_count_in_group("Player")
		
	if status == 0 and is_ball_inside and is_both_players_inside:
		print("Everybody in")
		status = 1
		close_door($Door1)
		if !is_initial: Globals.world.end()
		else: Globals.world.start()
	elif status == 1 and !is_ball_inside and !is_both_players_inside:
		print("Everybody out")
		status = 2
		close_door($Door2)
		#Globals.enemy_spawner.start()

func disable() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED

func get_jumping_start_position() -> Vector3:
	return to_global($Pos1.position + Vector3(0, 0, 5))
	
	

func open_door(door) -> void:
	print("open ", door)
	var t = get_tree().create_tween()
	t.tween_property(door, "rotation_degrees:x", -90 if door == $Door1 else -90, 1)
func close_door(door) -> void:
	var t = get_tree().create_tween()
	t.tween_property(door, "rotation_degrees:x", 0, 1)
