extends Node

@rpc("any_peer")
func apply_impulse_to_ball(requesting_peer_id: int) -> void:
	var player = Globals.ms.get_player_by_id(requesting_peer_id)
	Globals.ball.add_impulse(player, player.PUSH_FORCE)
