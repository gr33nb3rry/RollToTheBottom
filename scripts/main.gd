extends Node2D

var lobby_id: int = 0

@onready var ms: MultiplayerSpawner = $MultiplayerSpawner


func _ready() -> void:
	ms.spawn_function = spawn_level
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(_on_lobby_match_list)
	open_lobby_list()

func spawn_level(data):
	var a = (load(data) as PackedScene).instantiate()
	return a

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby.    ID: ", this_lobby_id)
	# Make the lobby join request to Steam
	Steam.joinLobby(this_lobby_id)
	lobby_id = this_lobby_id
	$HostButton.hide()
	$RefreshButton.hide()
	$LobbiesContainer/Lobbies.hide()


func create_lobby() -> void:
	# Make sure a lobby is not already set
	if lobby_id == 0:
		Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC)
		#ms.spawn("res://level.tscn")
		ms.spawn("res://node_3d.tscn")
		$HostButton.hide()
		$RefreshButton.hide()
		$LobbiesContainer/Lobbies.hide()

func _on_lobby_created(connect, id) -> void:
	if connect:
		lobby_id = id
		Steam.setLobbyData(lobby_id, "name", str(Steam.getPersonaName())+"'s lobby")
		Steam.setLobbyJoinable(lobby_id, true)
		print("Lobby created.               ID: ", lobby_id)
		

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
		$LobbiesContainer/Lobbies.add_child(lobby_button)


func refresh_lobby_list() -> void:
	if $LobbiesContainer/Lobbies.get_child_count() > 0:
		for n in $LobbiesContainer/Lobbies.get_children():
			n.queue_free()
		open_lobby_list()
