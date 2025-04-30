extends MultiplayerSpawner

const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")

var max_progress : float = 0.0
var next_progress_point : float = INF
var last_progress_point : float = 0.0
var progress_step : float = 0.0
var is_on : bool = false

func add_flying() -> void:
	var a = SOOT_FLYING.instantiate()
	add_child(a, true)
	var health : float = 1.0
	a.health = health - health * float(Globals.processor.get_skill(1, "Cursed Blood")) / 100.0
func add_stealing() -> void:
	var a = SOOT_STEALING.instantiate()
	add_child(a, true)
	var health : float = 1.0
	a.health = health - health * float(Globals.processor.get_skill(1, "Cursed Blood")) / 100.0
func add_jumping() -> void:
	var a = SOOT_JUMPING.instantiate()
	add_child(a, true)
	var health : float = 1.0
	a.health = health - health * float(Globals.processor.get_skill(1, "Cursed Blood")) / 100.0
	

# LEVEL STARTS
# WAVE
#   DEFINING ENEMIES OF WAVE
#   SPAWN ENEMIES
# NEW WAVE IN N TIME

func _ready() -> void:
	if multiplayer.get_unique_id() != 1:
		process_mode = Node.PROCESS_MODE_DISABLED
		
func _process(delta: float) -> void:
	if !is_on: return
	var current_progress : float = Globals.world.get_passed_position()
	if current_progress > max_progress: 
		max_progress = current_progress
		if current_progress > next_progress_point:
			next_progress_point += progress_step
			add_enemy()
		
func start() -> void:
	is_on = true
	max_progress = 0.0
	next_progress_point = 0.0 + 20.0
	last_progress_point = Globals.world.get_length() - 20.0
	progress_step = 20.0
	

func end() -> void:
	pass

	
func add_enemy() -> void:
	print("Added new enemy")
	var enemies : Array[String] = ["J", "F", "S"]
	var enemy : String = enemies[randi_range(0, enemies.size()-1)]
	match enemy:
		"J": add_jumping()
		"F": add_flying()
		"S": if get_tree().get_node_count_in_group("Stealing") == 0: add_stealing()
	
func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying()
	if Input.is_key_pressed(KEY_8):
		add_jumping()
	if Input.is_key_pressed(KEY_7):
		add_stealing()
