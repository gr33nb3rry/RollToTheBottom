extends RigidBody3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World

const MOVE_SPEED : float = 5.0
const MOVE_DELAY : float = 0.5
const JUMP_HEIGHT : float = 5.0
const RADIUS : float = 0.5
const DETECTION_RADIUS : float = 20.0
const ATTACK_DELAY : float = 2.0

var target
var target_pos : Vector3
var direction : Vector3

func _ready() -> void:
	await get_tree().create_timer(1.0).timeout
	move()

		
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

func is_near_enough() -> bool:
	var distance_squared = global_position.distance_squared_to(ms.get_nearest_player(global_position).global_position)
	return distance_squared < DETECTION_RADIUS * DETECTION_RADIUS

func damage() -> void:
	linear_velocity = Vector3.ZERO
	gravity_scale = 1.0
	var direction : Vector3 = (Vector3(randf_range(-1.0, 1.0), randf_range(1.0, 3.0), randf_range(-1.0, 1.0))).normalized()
	apply_central_impulse(direction * 10.0)

func death() -> void:
	queue_free()
