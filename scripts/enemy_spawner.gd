extends MultiplayerSpawner

const SOOT_FLYING = preload("res://scenes/soot_flying.tscn")
const SOOT_JUMPING = preload("res://scenes/soot_jumping.tscn")
const SOOT_STEALING = preload("res://scenes/soot_stealing.tscn")
const SOOT_WAITING = preload("res://scenes/soot_waiting.tscn")

func add_flying() -> void:
	var a = SOOT_FLYING.instantiate()
	add_child(a, true)
func add_stealing() -> void:
	var a = SOOT_STEALING.instantiate()
	add_child(a, true)
func add_jumping() -> void:
	var a = SOOT_JUMPING.instantiate()
	add_child(a, true)
	

# LEVEL STARTS
# WAVE
#   DEFINING ENEMIES OF WAVE
#   SPAWN ENEMIES
# NEW WAVE IN N TIME

func _ready() -> void:
	if multiplayer.get_unique_id() != 1:
		process_mode = Node.PROCESS_MODE_DISABLED
		
func start() -> void:
	var level_duration : float = 180.0
	var delay : float = 36.0
	var waves : int = level_duration / delay
	
	for wave in waves:
		start_wave()
		await get_tree().create_timer(delay).timeout
	end()

func end() -> void:
	pass

	
func start_wave() -> void:
	var enemies : Array[String] = ["J", "F", "F", "J", "S"]
	for enemy in enemies:
		match enemy:
			"J": add_jumping()
			"F": add_flying()
			"S": if get_tree().get_node_count_in_group("Stealing") == 0: add_stealing()
		await get_tree().create_timer(0.5).timeout
	
func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_9):
		add_flying()
	if Input.is_key_pressed(KEY_8):
		add_jumping()
	if Input.is_key_pressed(KEY_7):
		add_stealing()
