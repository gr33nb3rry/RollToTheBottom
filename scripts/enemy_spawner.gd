extends MultiplayerSpawner

const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")

func add_flying() -> void:
	var a = SOOT_FLYING.instantiate()
	add_child(a)
func add_stealing() -> void:
	var a = SOOT_STEALING.instantiate()
	add_child(a)
func add_jumping() -> void:
	var a = SOOT_JUMPING.instantiate()
	add_child(a)
	

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying()
	if Input.is_key_pressed(KEY_8):
		add_jumping()
	if Input.is_key_pressed(KEY_7):
		add_stealing()
