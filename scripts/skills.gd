extends Node

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner

# ACTIVE INDIVIDUAL SKILLS

func kick_ball(peer_id, force:float) -> void:
	var player = ms.get_player_by_id(peer_id)
	if player.ray_hit.is_colliding() and player.ray_hit.get_collider().name == "Ball":
		var direction : Vector3 = ball.global_position - player.global_position
		ball.apply_central_impulse(Vector3(direction.x,0.0,direction.z) * force)
		
func pull_ball(peer_id, force:float) -> void:
	var player = ms.get_player_by_id(peer_id)
	var direction : Vector3 = ball.global_position - player.global_position
	ball.apply_central_impulse(-direction * force)
	
# ACTIVE GLOBAL SKILLS

func kill_all_ants() -> void:
	get_tree().call_group("Ant", "damage")

func freeze_ball() -> void:
	$/root/Main/World/Ball.freeze_on_time(3.0)
	
func refresh_ball() -> void:
	$/root/Main/World/Ball.refresh_size()
	

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_1):
		kill_all_ants()
	if Input.is_key_pressed(KEY_2):
		freeze_ball()
	if Input.is_key_pressed(KEY_3):
		refresh_ball()
	if Input.is_key_pressed(KEY_4):
		kick_ball(1, 150.0)
	if Input.is_key_pressed(KEY_5):
		pull_ball(1, 150.0)
