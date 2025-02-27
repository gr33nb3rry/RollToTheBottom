extends RigidBody3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World

const MOVE_SPEED : float = 20.0
const PUSH_FORCE : float = 200.0
const TIME_TO_DIE : float = 20.0
const FLYING_DEADZONE : float = 1.0

var is_active := true
var target
var target_pos : Vector3
var state : int = 0

func _ready() -> void:
	target = ms.get_random_player()
	calculate_target_pos()
	
func _physics_process(delta: float) -> void:
	if state == 0:
		get_parent().progress += MOVE_SPEED * delta
		if get_parent().progress_ratio == 1.0:
			reparent(world)
			state = 1
	elif state == 1:
		var direction = target_pos - global_position
		direction.y = 0.0
		global_position += direction.normalized() * MOVE_SPEED * delta
		if abs(global_position.x - target_pos.x) < FLYING_DEADZONE and abs(global_position.z - target_pos.z) < FLYING_DEADZONE:
			state = 2
	elif state == 2:
		achieve_target_pos() 
	
		
	
func calculate_target_pos() -> void:
	var pos = await world.get_near_flying_position(target)
	target_pos = pos
	
func check_for_position_change() -> void:
	pass
	
func achieve_target_pos() -> void:
	state = 3
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:y", target_pos.y, abs(target_pos.y - global_position.y) / MOVE_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	check_for_position_change()
	idle_moving()
	
func idle_moving() -> void:
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:y", target_pos.y + 1.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "global_position:y", target_pos.y, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	if state == 3: idle_moving()
	
func damage() -> void:
	is_active = false
	linear_velocity = Vector3.ZERO
	gravity_scale = 1.0
	var direction : Vector3 = (Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 3.0), randf_range(-1.0, 1.0))).normalized()
	apply_central_impulse(direction * 10.0)
	await get_tree().create_timer(TIME_TO_DIE).timeout
	death()
	
func death() -> void:
	is_active = false
	$Explosion.emitting = true
	$Mesh.visible = false
	await get_tree().create_timer(5.0).timeout
	queue_free()
