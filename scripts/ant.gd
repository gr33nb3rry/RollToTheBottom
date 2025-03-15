extends RigidBody3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var projectile_spawner = $/root/Main/World/ProjectileSpawner
@onready var world = $/root/Main/World
const PROJECTILE_S = preload("res://scenes/projectile_s.tscn")

const MOVE_SPEED : float = 20.0
const PUSH_FORCE : float = 200.0
const TIME_TO_DIE : float = 20.0
const FLYING_DEADZONE : float = 1.0
const DETECTION_RADIUS : float = 35.0
const ATTACK_DELAY : float = 2.0

@export var type : int = 0
var is_active := true
var is_idling : bool = false
var target
var target_pos : Vector3
var state : int = 0

func _ready() -> void:
	if !multiplayer.is_server(): return
	calculate_target_pos()
	await get_tree().process_frame
	var pos : Vector3 = target_pos
	pos.y -= 40.0
	global_position = pos
	
	
func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if state == 0:
		achieve_target_pos() 
	elif state == 1:
		var direction = target_pos - global_position
		direction.y = 0.0
		global_position += direction.normalized() * MOVE_SPEED * delta
		if abs(global_position.x - target_pos.x) < FLYING_DEADZONE and abs(global_position.z - target_pos.z) < FLYING_DEADZONE:
			state = 0
	
		
func calculate_target_pos() -> void:
	target = ms.get_nearest_player(global_position)
	var pos = world.get_near_flying_position() if !is_idling else world.get_next_near_flying_position()
	target_pos = pos
	
func check_for_position_change() -> void:
	var distance_squared = global_position.distance_squared_to(world.get_zone_next_marker())
	if distance_squared < DETECTION_RADIUS * DETECTION_RADIUS:
		attack()
		await get_tree().create_timer(ATTACK_DELAY).timeout
		check_for_position_change()
	else:
		calculate_target_pos()
		state = 1

func attack() -> void:
	var direction : Vector3 = (target.global_position - global_position).normalized()
	var p
	if type == 0: p = PROJECTILE_S.instantiate()
	projectile_spawner.add_child(p)
	p.global_position = global_position
	p.direction = direction
	
func achieve_target_pos() -> void:
	state = 2
	if !is_idling:
		var t = get_tree().create_tween()
		t.tween_property(self, "global_position:y", target_pos.y, abs(target_pos.y - global_position.y) / MOVE_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await t.finished
		check_for_position_change()
		is_idling = true
		idle_moving()
	else:
		check_for_position_change()
	
func idle_moving() -> void:
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:y", target_pos.y + 1.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "global_position:y", target_pos.y, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	idle_moving()
	
func damage(v:int) -> void:
	death()
	
func death() -> void:
	queue_free()
