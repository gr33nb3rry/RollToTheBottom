extends Node3D

var lobby_id: int = 0
var peer = SteamMultiplayerPeer.new()


@onready var ms: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	ms.spawn_function = spawn_level
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	#Steam.lobby_joined.connect(_on_lobby_joined)
	open_lobby_list()

func spawn_level(data):
	var a = (load(data) as PackedScene).instantiate()
	return a

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby.    ID: ", this_lobby_id)
	# Make the lobby join request to Steam
	peer.connect_lobby(this_lobby_id)
	multiplayer.multiplayer_peer = peer
	lobby_id = this_lobby_id
	$Canvas/HostButton.hide()
	$Canvas/RefreshButton.hide()
	$Canvas/LobbiesContainer/Lobbies.hide()
	
func _on_lobby_joined(this_lobby_id: int, _permissions: int, _locked: bool, response: int) -> void:
	pass


func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		peer.create_lobby(peer.LOBBY_TYPE_PUBLIC)
		multiplayer.multiplayer_peer = peer
		#Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)
		#ms.spawn("res://level.tscn")
		ms.spawn("res://node_3d.tscn")
		$Canvas/HostButton.hide()
		$Canvas/RefreshButton.hide()
		$Canvas/LobbiesContainer/Lobbies.hide()

func _on_lobby_created(connect, this_lobby_id) -> void:
	if connect:
		lobby_id = this_lobby_id
		var lobby_name : String = str(Steam.getPersonaName())+"'s lobby"
		Steam.setLobbyData(lobby_id, "name", lobby_name)
		Steam.setLobbyJoinable(lobby_id, true)
		#var relay = Steam.allowP2PPacketRelay(true)
		print("Lobby created.               ID: ", lobby_id, "  NAME: ", lobby_name)
		

func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	
func _on_lobby_match_list(lobbies):
	for lobby in lobbies:
		var lobby_name = Steam.getLobbyData(lobby, "name")
		var member_count = Steam.getNumLobbyMembers(lobby)
		
		var lobby_button = Button.new()
		lobby_button.set_text(str(lobby_name,"  //  Players: ", member_count))
		lobby_button.set_size(Vector2(500, 10))
		lobby_button.connect("pressed", Callable(self,"join_lobby").bind(lobby))
		$Canvas/LobbiesContainer/Lobbies.add_child(lobby_button)


func refresh_lobby_list() -> void:
	if $Canvas/LobbiesContainer/Lobbies.get_child_count() > 0:
		for n in $Canvas/LobbiesContainer/Lobbies.get_children():
			n.queue_free()
		open_lobby_list()
