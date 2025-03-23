extends Node3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World

const MOVE_SPEED : float = 7.0
const MOVE_DELAY : float = 0.5
const JUMP_HEIGHT : float = 3.0
const RADIUS : float = 0.5
const DETECTION_RADIUS : float = 17.0
const ATTACK_RADIUS : float = 0.5
const ATTACK_DELAY : float = 2.0

var target
var direction : Vector3
var is_attacking : bool = false

func _ready() -> void:
	if !multiplayer.is_server(): return
	await get_tree().create_timer(1.0).timeout
	global_position = world.get_jumping_start_position()
	move()

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if !is_attacking: return
	var dir : Vector3 = (target.global_position - global_position).normalized()
	global_position += dir * MOVE_SPEED * 2.0 * delta
	if is_near_enough_to_attack(): 
		target.damage(1)
		death()
		
func move() -> void:
	if !is_near_enough():
		var next_pos : Vector3 = world.get_next_jumping_position(global_position + direction * MOVE_SPEED)
		direction = (next_pos - global_position).normalized()
		$Ray.global_position = next_pos + Vector3(0, 10, 0)
		await get_tree().create_timer(0.1).timeout
		var pos : Vector3 = $Ray.get_collision_point() + Vector3(0, RADIUS, 0)
		var t = get_tree().create_tween()
		t.tween_property(self, "global_position:x", pos.x, 1.0)
		t.parallel().tween_property(self, "global_position:z", pos.z, 1.0)
		var t2 = get_tree().create_tween()
		t2.tween_property(self, "global_position:y", pos.y + JUMP_HEIGHT, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t2.tween_property(self, "global_position:y", pos.y, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await get_tree().create_timer(1.1 + MOVE_DELAY).timeout
		move()
	else:
		target = ms.get_nearest_player(global_position)
		is_attacking = true
		var t = get_tree().create_tween()
		t.tween_property(self, "global_position:y", global_position.y + JUMP_HEIGHT, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func is_near_enough() -> bool:
	var distance_squared = global_position.distance_squared_to(ms.get_nearest_player(global_position).global_position)
	return distance_squared < DETECTION_RADIUS * DETECTION_RADIUS

func is_near_enough_to_attack() -> bool:
	var distance_squared = global_position.distance_squared_to(ms.get_nearest_player(global_position).global_position)
	return distance_squared < ATTACK_RADIUS * ATTACK_RADIUS

func damage(v:float) -> void:
	death()

func death() -> void:
	queue_free()
