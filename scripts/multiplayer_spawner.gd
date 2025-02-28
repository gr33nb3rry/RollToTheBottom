extends MultiplayerSpawner

@onready var player_scene = preload("res://scenes/player.tscn")
@onready var ball_scene = preload("res://scenes/ball.tscn")
var players = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_function = spawnPlayer
	if is_multiplayer_authority():
		spawn(1)
		#add_player_location(1, Steam.getLocalPingLocation()["location"])
		multiplayer.peer_connected.connect(spawn)
		multiplayer.peer_disconnected.connect(removePlayer)

func spawnPlayer(data):
	var p = player_scene.instantiate()
	p.position = Vector3(-150.0,1583.0,57.0)
	p.set_multiplayer_authority(data)
	players[data] = p
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
		if distance_squared < min_distance_squared:
			min_distance_squared = distance_squared
			nearest_player = player
	return nearest_player

func get_players_count() -> int:
	return players.size()
