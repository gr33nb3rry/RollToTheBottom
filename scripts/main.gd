extends Node3D

var lobby_id: int = 0
var peer = SteamMultiplayerPeer.new()

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	multiplayer_spawner.spawn_function = spawn_level
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(show_lobby_list)
	peer.lobby_joined.connect(_on_lobby_joined)
	open_lobby_list()
	#$Canvas/HostButton.emit_signal("pressed")

func spawn_level(data):
	var a = (load(data) as PackedScene).instantiate()
	return a

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby.    ID: ", this_lobby_id)
	peer.connect_lobby(this_lobby_id)
	multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer.as_relay = true
	lobby_id = this_lobby_id
	
func _on_lobby_joined(_this_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	start_game()

func create_lobby() -> void:
	if lobby_id == 0:
		peer.create_lobby(peer.LOBBY_TYPE_PUBLIC)
		multiplayer.multiplayer_peer = peer

func _on_lobby_created(is_connect, this_lobby_id) -> void:
	if is_connect:
		lobby_id = this_lobby_id
		var lobby_name : String = str(Steam.getPersonaName())+"'s lobby"
		Steam.setLobbyData(lobby_id, "name", lobby_name)
		Steam.setLobbyJoinable(lobby_id, true)
		#var relay = Steam.allowP2PPacketRelay(true)
		print("Lobby created.               ID: ", lobby_id, "  NAME: ", lobby_name)
		start_game()

func pregame() -> void:
	var lobby_members_count : int = Steam.getNumLobbyMembers(lobby_id)
	if lobby_members_count == 1: start_game()
	else:
		await get_tree().create_timer(2.0).timeout
		pregame()

func start_game() -> void:
	var is_host : bool = Steam.getLobbyOwner(lobby_id) == SteamGlobal.steam_id
	print("Start game.   is host: ", is_host)
	if is_host: multiplayer_spawner.spawn("res://world.tscn")
	$Canvas/HostButton.hide()
	$Canvas/RefreshButton.hide()
	$Canvas/StartButton.hide()
	$Canvas/LobbiesContainer/Lobbies.hide()

	
func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	#show_lobby_list_with_profiles(get_lobbies_with_friends())
	
func show_lobby_list(lobbies:Array):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		var lobby_button = Button.new()
		lobby_button.set_text(str(lobby_name,"  //  Players: ", member_count))
		lobby_button.set_size(Vector2(500, 10))
		lobby_button.connect("pressed", Callable(self,"join_lobby").bind(lobby))
		$Canvas/LobbiesContainer/Lobbies.add_child(lobby_button)
func show_lobby_list_with_profiles(lobbies:Dictionary):
	for lobby in lobbies:
		var profile_steam_id = lobbies[lobby]
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		var lobby_button = Button.new()
		lobby_button.set_text(str(lobby_name,"  //  Players: ", member_count))
		lobby_button.set_size(Vector2(500, 10))
		lobby_button.connect("pressed", Callable(self,"join_lobby").bind(lobby))
		$Canvas/LobbiesContainer/Lobbies.add_child(lobby_button)

func get_lobbies_with_friends() -> Dictionary:
	var results: Dictionary = {}
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)
		if game_info.is_empty():
			continue
		else:
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']
			if app_id != Steam.getAppID() or lobby is String:
				continue
			if not results.has(lobby):
				results[lobby] = []
			results[lobby].append(steam_id)
	return results

func refresh_lobby_list() -> void:
	if $Canvas/LobbiesContainer/Lobbies.get_child_count() > 0:
		for n in $Canvas/LobbiesContainer/Lobbies.get_children():
			n.queue_free()
		open_lobby_list()

func _process(_delta: float) -> void:
	$Canvas/FPSLabel.text = str(Engine.get_frames_per_second())
	
