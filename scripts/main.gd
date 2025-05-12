extends Node3D

var lobby_id: int = 0
var peer = SteamMultiplayerPeer.new()

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner

const BG_COLORS : Dictionary = {
	"Start": Color(0.951, 0.74, 0.397),
	"HowToPlay": Color(0.433, 0.775, 0.298)
}
var active_panel : String = "Start"

func _ready() -> void:
	multiplayer_spawner.spawn_function = spawn_level
	peer.lobby_created.connect(_on_lobby_created)
	Steam.lobby_match_list.connect(show_lobby_list)
	Steam.join_requested.connect(accept_invite)
	Steam.lobby_chat_update.connect(_on_lobby_chat_update)
	peer.lobby_joined.connect(_on_lobby_joined)
	open_lobby_list()
	#$Canvas/HostButton.emit_signal("pressed")
	check_command_line()
	
func check_command_line() -> void:
	var these_arguments: Array = OS.get_cmdline_args()
	if these_arguments.size() > 0:
		if these_arguments[0] == "+connect_lobby":
			if int(these_arguments[1]) > 0:
				print("Command line lobby ID: %s" % these_arguments[1])
				join_lobby(int(these_arguments[1]))

func spawn_level(data):
	var a = (load(data) as PackedScene).instantiate()
	return a

func join_lobby(this_lobby_id: int) -> void:
	print("Attempting to join lobby.    ID: ", this_lobby_id)
	peer.connect_lobby(this_lobby_id)
	multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer.as_relay = true
	lobby_id = this_lobby_id
	start_game()
	
func _on_lobby_joined(_this_lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	#start_game()
	pass
	
func leave_lobby() -> void:
	if lobby_id != 0:
		var member_count : int = Steam.getNumLobbyMembers(lobby_id)
		for i in range(member_count):
			var member_steam_id : int = Steam.getLobbyMemberByIndex(lobby_id, i)
			if member_steam_id != SteamGlobal.steam_id:
				Steam.closeP2PSessionWithUser(member_steam_id)

		Steam.leaveLobby(lobby_id)
		var left_lobby_id = lobby_id  # сохранить для дебага, если надо
		lobby_id = 0
		multiplayer.multiplayer_peer = null

		if has_node("World"):
			$World.queue_free()
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$Canvas/BG.show()
			$Canvas/Start.show()

	

func create_lobby() -> void:
	if lobby_id == 0:
		#Steam.createLobby(Steam.LOBBY_TYPE_FRIENDS_ONLY)
		peer.create_lobby(SteamMultiplayerPeer.LOBBY_TYPE_FRIENDS_ONLY, 2)
		multiplayer.multiplayer_peer = peer

func _on_lobby_created(is_connect, this_lobby_id) -> void:
	if is_connect:
		lobby_id = this_lobby_id
		var lobby_name : String = str(Steam.getPersonaName())+"'s lobby"
		Steam.setLobbyData(lobby_id, "name", lobby_name)
		Steam.setLobbyJoinable(lobby_id, true)
		var relay = Steam.allowP2PPacketRelay(true)
		print("Lobby created.               ID: ", lobby_id, "  NAME: ", lobby_name)
		multiplayer_spawner.spawn("res://world.tscn")
		start_game()

func _on_lobby_chat_update(this_lobby_id: int, change_id: int, making_change_id: int, chat_state: int) -> void:
	# Get the user who has made the lobby change
	var changer_name: String = Steam.getFriendPersonaName(change_id)
	# If a player has joined the lobby
	if chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
		print("%s has joined the lobby." % changer_name)
	# Else if a player has left the lobby
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
		print("%s has left the lobby." % changer_name)
	# Else if a player has been kicked
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
		print("%s has been kicked from the lobby." % changer_name)
	# Else if a player has been banned
	elif chat_state == Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
		print("%s has been banned from the lobby." % changer_name)
	# Else there was some unknown change
	else:
		print("%s did... something." % changer_name)


func pregame() -> void:
	var lobby_members_count : int = Steam.getNumLobbyMembers(lobby_id)
	if lobby_members_count == 1: start_game()
	else:
		await get_tree().create_timer(2.0).timeout
		pregame()

func start_game() -> void:
	#var is_host : bool = Steam.getLobbyOwner(lobby_id) == SteamGlobal.steam_id
	#print("Start game.   is host: ", is_host)
	#if is_host: multiplayer_spawner.spawn("res://world.tscn")
	$Canvas/BG.hide()
	$Canvas/Start.hide()


func open_invite_overlay() -> void:
	Steam.activateGameOverlayInviteDialog(lobby_id)
	
func open_lobby_list():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()
	#show_lobby_list_with_profiles(get_lobbies_with_friends())
	
func show_lobby_list(lobbies:Array):
	show_lobby_list_with_profiles(get_lobbies_with_friends())
	return
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

func get_friends() -> Array:
	var results: Array = []
	for i in range(0, Steam.getFriendCount()):
		var steam_id: int = Steam.getFriendByIndex(i, Steam.FRIEND_FLAG_IMMEDIATE)
		if steam_id == 0: continue
		var game_info: Dictionary = Steam.getFriendGamePlayed(steam_id)
		if game_info.is_empty():
			results.append(steam_id)
		else:
			var app_id: int = game_info['id']
			var lobby = game_info['lobby']
			if app_id != Steam.getAppID() or lobby is String:
				continue
			results.append(steam_id)
	return results

func invite(steam_id:int) -> void:
	Steam.inviteUserToLobby(lobby_id, steam_id)
	print("User ", steam_id, " invited")

func accept_invite(lobby_id: int, steam_id: int) -> void:
	join_lobby(lobby_id)

func refresh_lobby_list() -> void:
	if $Canvas/LobbiesContainer/Lobbies.get_child_count() > 0:
		for n in $Canvas/LobbiesContainer/Lobbies.get_children():
			n.queue_free()
		open_lobby_list()

func _process(_delta: float) -> void:
	$Canvas/FPSLabel.text = str(Engine.get_frames_per_second())
	
	
func open_panel(title:String) -> void:
	print(title)
	$Canvas.get_node(active_panel).hide()
	$Canvas.get_node(title).show()
	$Canvas/BG.self_modulate = BG_COLORS[title]
	active_panel = title

func exit() -> void:
	get_tree().quit()
