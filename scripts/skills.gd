extends Node


func kill_all_ants() -> void:
	get_tree().call_group("Ant", "damage")

func freeze_ball() -> void:
	$/root/Main/World/Ball.freeze_on_time(3.0)
	

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_1):
		kill_all_ants()
	if Input.is_key_pressed(KEY_2):
		freeze_ball()
