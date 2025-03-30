extends RigidBody3D

const PROJECTILE_S = preload("res://scenes/projectile_s.tscn")

const MOVE_SPEED : float = 10.0
const MOVE_WITH_BALL_SPEED : float = 5.0
const PUSH_FORCE : float = 200.0
const TIME_TO_DIE : float = 20.0
const FLYING_DETECT_RADIUS : float = 5.0
const FLYING_DEADZONE : float = 0.5
const DETECTION_RADIUS : float = 35.0
const ATTACK_DELAY : float = 2.0
const RADIUS : float = 0.5
const BALL_RADIUS : float = 2.0
const INITIAL_HEIGHT : float = 40.0

@export var type : int = 0
var health : float = 1.0
var is_active := true
var is_achieved : bool = false
var target_pos : Vector3
var state : int = 0

func _ready() -> void:
	if !multiplayer.is_server(): return
	calculate_target_pos()
	await get_tree().process_frame
	var pos : Vector3 = target_pos
	pos.y -= INITIAL_HEIGHT
	global_position = pos
	
func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if state == 0:
		achieve_target_pos() 
	elif state == 1:
		var pos : Vector3 = Globals.ball.global_position + Vector3(0, BALL_RADIUS + RADIUS, 0)
		var direction = pos - global_position
		if abs(global_position.x - pos.x) > FLYING_DETECT_RADIUS or abs(global_position.z - pos.z) > FLYING_DETECT_RADIUS:
			direction.y = 0.0
		if global_position.distance_squared_to(pos) < FLYING_DEADZONE * FLYING_DEADZONE:
			if !is_achieved: achieve_final_pos()
			return
		global_position += direction.normalized() * MOVE_SPEED * delta
	elif state == 2:
		Globals.ball.global_position = global_position - Vector3(0, BALL_RADIUS + RADIUS, 0)
		
		
func calculate_target_pos() -> void:
	var pos = Globals.world.get_near_flying_position()
	target_pos = pos
	
	
func achieve_target_pos() -> void:
	state = -1
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:y", target_pos.y, abs(target_pos.y - global_position.y) / MOVE_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	state = 1
	
func achieve_final_pos() -> void:
	is_achieved = true
	await get_tree().create_timer(ATTACK_DELAY).timeout
	steal()
	
func steal() -> void:
	Globals.ball.is_simplified = false
	Globals.ball.stop()
	state = 2
	var pos : float = global_position.y + 4.0
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:y", pos, abs(pos - global_position.y) / MOVE_WITH_BALL_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "global_position:x", target_pos.x, abs(target_pos.x - global_position.x) / MOVE_WITH_BALL_SPEED)
	t.parallel().tween_property(self, "global_position:z", target_pos.z, abs(target_pos.z - global_position.z) / MOVE_WITH_BALL_SPEED)
	t.tween_property(self, "global_position:y", target_pos.y-INITIAL_HEIGHT, abs(target_pos.y-INITIAL_HEIGHT - global_position.y) / MOVE_WITH_BALL_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
func damage(peer_id:int, damage:float) -> void:
	if multiplayer.is_server():
		Globals.processor.damage_soot(self, peer_id, damage)

func death() -> void:
	Globals.ball.is_simplified = true
	queue_free()
