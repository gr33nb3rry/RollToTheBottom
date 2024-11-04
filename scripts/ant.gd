extends RigidBody3D

@onready var agent = $Agent
@onready var ball = $/root/Main/World/Ball

const MOVE_SPEED : float = 700.0
const PUSH_FORCE := 200.0
const TIME_TO_DIE : float = 20.0

var is_active := true

func _ready() -> void:
	update_path()

func _process(delta: float) -> void:
	if !agent.is_navigation_finished() and is_active:
		var new_velocity: Vector3 = agent.get_next_path_position() - global_position
		var velocity = new_velocity.normalized() * MOVE_SPEED * delta
		linear_velocity = velocity
	if !ball.is_on_ground and ball.time_in_air > 1.0:
		death()

func update_path() -> void:
	if !is_active: return
	if ball.is_on_ground:
		agent.target_position = ball.global_position
	var delay : float
	if get_tree().get_node_count_in_group("Ant") > 5:
		delay = clamp(global_position.distance_squared_to(ball.global_position) / 4000.0, 1, 10.0)
	else:
		delay = clamp(get_tree().get_node_count_in_group("Ant") * 0.1, 0.1, 10.0)
	await get_tree().create_timer(delay).timeout
	update_path()
		
func touch() -> void:
	var push_normal : Vector3 = ball.global_position - global_position
	ball.apply_central_impulse(Vector3(push_normal.x,0.0,push_normal.z) * PUSH_FORCE)
	death()
	
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
