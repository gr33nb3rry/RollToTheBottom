extends Node

@onready var ball = $/root/Main/World/Ball
@onready var ms = $/root/Main/World/MultiplayerSpawner

# ACTIVE INDIVIDUAL SKILLS

func kick_ball(peer_id, force:float) -> void:
	var player = ms.get_player_by_id(peer_id)
	if player.ray_hit.is_colliding() and player.ray_hit.get_collider().name == "Ball":
		#var direction : Vector3 = ball.global_position - player.global_position
		ball.add_impulse(player, force)
		
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
	
