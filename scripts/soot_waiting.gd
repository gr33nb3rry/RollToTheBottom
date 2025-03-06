extends Node3D

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var world = $/root/Main/World

const MOVE_SPEED : float = 7.0
const MOVE_DELAY : float = 0.5
const JUMP_HEIGHT : float = 3.0
const RADIUS : float = 2.0
const DETECTION_RADIUS : float = 20.0
const ATTACK_FORCE : float = 50.0
const ATTACK_DAMAGE : float = 1

var target
var direction : Vector3
var is_opened : bool = false
var is_attacking : bool = false

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if !is_opened and is_near_enough():
		_on_area_open_body_entered(ball)
	elif is_opened and !is_near_enough():
		_on_area_open_body_exited(ball)
	var player : CharacterBody3D = ms.get_nearest_player(self)
	if !is_attacking and is_near_enough_to_attack(player):
		_on_area_attack_body_entered(player)
	elif !is_attacking and is_near_enough_to_attack(ball):
		_on_area_attack_body_entered(ball)
	
func is_near_enough() -> bool:
	var distance_squared = global_position.distance_squared_to(ball.global_position)
	return distance_squared < DETECTION_RADIUS * DETECTION_RADIUS
func is_near_enough_to_attack(obj:Node3D) -> bool:
	var distance_squared = global_position.distance_squared_to(obj.global_position)
	return distance_squared < RADIUS * RADIUS
	
func _on_area_open_body_entered(body: Node3D) -> void:
	if body.name == "Ball": 
		is_opened = true
		$Shell.visible = false
func _on_area_open_body_exited(body: Node3D) -> void:
	if body.name == "Ball": 
		is_opened = false
		$Shell.visible = true

func _on_area_attack_body_entered(body: Node3D) -> void:
	if !is_opened: return
	if body.name == "Ball":
		ball.add_impulse(self, ATTACK_FORCE)
		death()
	elif body.is_in_group("Player"):
		body.damage(ATTACK_DAMAGE)
		death()
	
func damage(v:int) -> void:
	death()

func death() -> void:
	queue_free()
