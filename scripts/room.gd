extends Node3D

@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World
const FLYING_S = preload("res://scenes/e_flying_s.tscn")
const FLYING_D = preload("res://scenes/e_flying_d.tscn")
var is_ball_inside : bool = false
var players_inside_count : int = 0

func add_flying(type:int) -> void:
	var a = FLYING_S.instantiate() if type == 0 else FLYING_D.instantiate()
	world.add_child(a)
	

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying(0)
	if Input.is_key_pressed(KEY_8):
		add_flying(1)


func _on_area_body_entered(body: Node3D) -> void:
	if body.name == "Ball":
		is_ball_inside = true
	elif body.is_in_group("Player"):
		players_inside_count += 1
	if is_ball_inside and players_inside_count == ms.get_players_count():
		world.end()


func _on_area_body_exited(body: Node3D) -> void:
	if body.name == "Ball":
		is_ball_inside = false
	elif body.is_in_group("Player"):
		players_inside_count -= 1
