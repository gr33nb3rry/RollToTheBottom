extends Node3D

@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World
const ANT = preload("res://scenes/e_flying_s.tscn")
var is_ball_inside : bool = false
var players_inside_count : int = 0

func add_flying() -> void:
	var paths : Array[int]
	for i in 10:
		if get_node("Paths/FlyPath" + str(i+1) + "/PathFollow").progress == 0.0:
			paths.append(i + 1)
	if paths.size() == 0: return
	var path = get_node("Paths/FlyPath" + str(paths[randi_range(0, paths.size()-1)]) + "/PathFollow")
	var a = ANT.instantiate()
	path.add_child(a)
	a.position = Vector3.ZERO
	

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying()


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
