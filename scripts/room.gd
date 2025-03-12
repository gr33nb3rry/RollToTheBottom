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


func add_flying(type:int) -> void:
	var a = SOOT_FLYING.instantiate()
	world.add_child(a)
func add_stealing(type:int) -> void:
	var a = SOOT_STEALING.instantiate()
	world.add_child(a)
func add_jumping() -> void:
	var a = SOOT_JUMPING.instantiate()
	world.add_child(a)
	a.global_position = to_global($Pos1.position + Vector3(0, 0, 5))
	

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying(0)
	if Input.is_key_pressed(KEY_8):
		add_jumping()
	if Input.is_key_pressed(KEY_7):
		add_stealing(0)

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
