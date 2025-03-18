extends Node

const PROJECTILE = preload("res://scenes/projectile.tscn")

var max_health : Array = [100, 100]
var health : Array = [max_health[0], max_health[1]]

func _ready() -> void:
	await get_tree().process_frame
	Globals.health.update()
	
@rpc("any_peer")
func change_health(peer_id:int, v:int) -> void:
	var index : int = 0 if peer_id == 1 else 1
	health[index] = clamp(health[index] + v, 0, max_health[index])
	if health[index] == 0:
		Globals.ms.get_player_by_id(peer_id).death()
	Globals.health.update()
	

@rpc("any_peer")
func apply_impulse_to_ball(requesting_peer_id: int) -> void:
	var player = Globals.ms.get_player_by_id(requesting_peer_id)
	Globals.ball.add_impulse(player, player.PUSH_FORCE)

@rpc("any_peer")
func shoot(requesting_peer_id: int) -> void:
	var player = Globals.ms.get_player_by_id(requesting_peer_id)
	var direction : Vector3
	var pos : Vector3 = player.global_position + Vector3(0, 1.7, 0)
	if player.ray_crosshair.is_colliding():
		direction = (player.ray_crosshair.get_collision_point() - pos).normalized()
	else:
		direction = (-player.camera.global_transform.basis.z).normalized()
	var p = PROJECTILE.instantiate()
	Globals.projectile_spawner.add_child(p, true)
	p.global_position = pos
	p.direction = direction
