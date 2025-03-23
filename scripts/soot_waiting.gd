extends RigidBody3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World

const MOVE_SPEED : float = 7.0
const MOVE_DELAY : float = 0.5
const JUMP_HEIGHT : float = 3.0
const RADIUS : float = 2.0
const BALL_RADIUS : float = 2.0
const DETECTION_RADIUS : float = 20.0
const ATTACK_FORCE : float = 50.0
const ATTACK_DAMAGE : float = 1

var target
var direction : Vector3
var is_opened : bool = false
var is_attacking : bool = false


func _process(_delta: float) -> void:
	if !multiplayer.is_server(): return
	if !is_opened and is_near_enough():
		body_entered(ball)
	elif is_opened and !is_near_enough():
		body_exited(ball)
	var player : CharacterBody3D = ms.get_nearest_player(self.global_position)
	if !is_attacking and is_near_enough_to_attack(player):
		attack(player)
	elif !is_attacking and is_near_enough_to_attack_ball():
		attack(ball)
	
func is_near_enough() -> bool:
	var distance_squared = global_position.distance_squared_to(ball.global_position)
	return distance_squared < DETECTION_RADIUS * DETECTION_RADIUS
func is_near_enough_to_attack(obj:Node3D) -> bool:
	var distance_squared = global_position.distance_squared_to(obj.global_position)
	return distance_squared < RADIUS * RADIUS
func is_near_enough_to_attack_ball() -> bool:
	var distance_squared = global_position.distance_squared_to(ball.global_position)
	return distance_squared < (BALL_RADIUS + RADIUS) * (BALL_RADIUS + RADIUS)
	
func body_entered(body: Node3D) -> void:
	if body.name == "Ball": 
		is_opened = true
		$Shell.visible = false
func body_exited(body: Node3D) -> void:
	if body.name == "Ball": 
		is_opened = false
		$Shell.visible = true

func attack(body: Node3D) -> void:
	if !is_opened: return
	is_attacking = true
	if body.name == "Ball":
		ball.add_impulse(self, ATTACK_FORCE)
		death()
	elif body.is_in_group("Player"):
		body.damage(ATTACK_DAMAGE)
		death()
	
func damage(v:float) -> void:
	if !is_opened: return
	death()

func death() -> void:
	queue_free()
