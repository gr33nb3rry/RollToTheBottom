extends Node3D

const ANT = preload("res://scenes/ant.tscn")
const FLYING_SPEED : float = 10.0

func add_flying() -> void:
	$FlyPath/PathFollow.progress = 0.0
	var a = ANT.instantiate()
	$FlyPath/PathFollow.add_child(a)
	a.position = Vector3.ZERO
	

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying()
