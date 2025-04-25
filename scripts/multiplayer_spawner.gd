extends MultiplayerSpawner

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var ball_scene = preload("res://scenes/ball.tscn")
var players = {}
var second_player_peer_id : int


func _ready() -> void:
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)

func spawnPlayer(data):
	var p = player_scene.instantiate()
	p.position = Vector3(-150.0,1583.0,57.0)
	p.set_multiplayer_authority(data)
	players[data] = p
	if players.size() > 1: second_player_peer_id = data
	return p
	
func removePlayer(data):
	players[data].queue_free()
	players.erase(data)
	
	
func get_player_by_id(peer_id: int) -> Node:
	if players.has(peer_id):
		return players[peer_id]
	return null

func get_random_player() -> Node:
	if players.is_empty(): return null
	var keys = players.keys()
	var random_key = keys[randi() % keys.size()]
	return players[random_key]
	
func get_nearest_player(pos: Vector3) -> Node:
	if players.is_empty(): return null
	var nearest_player = null
	var min_distance_squared = INF
	for player in players.values():
		var distance_squared = pos.distance_squared_to(player.global_position)
		if distance_squared < min_distance_squared and player.is_active:
			min_distance_squared = distance_squared
			nearest_player = player
	return nearest_player

func get_players_count() -> int:
	return players.size()

func get_second_player_peer_id() -> int:
	return second_player_peer_id

func get_ball_player() -> Node:
	if players.is_empty(): return null
	for player in players.values():
		if player.type == 0: return player
	return null
