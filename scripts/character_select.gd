extends Control

const BUTTON_UI = preload("res://scenes/button_ui.tscn")
@onready var c_1_p_1: Control = $"VBox/Cards/1/Main/Players/P1"
@onready var c_1_p_2: Control = $"VBox/Cards/1/Main/Players/P2"
@onready var c_2_p_1: Control = $"VBox/Cards/2/Main/Players/P1"
@onready var c_2_p_2: Control = $"VBox/Cards/2/Main/Players/P2"

var selection : Array = [-1, -1]
var is_able_to_select : bool = true

var friends : Dictionary = {}
var is_friend_list_opened : bool = false

func _ready() -> void:
	Steam.avatar_loaded.connect(update_avatar)
	update_selection()
	#$VBox/Footer/Play.deactivate()
	
func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#for p in Globals.ms.players.values():
	#	p.is_active = false
func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Globals.ms.get_player_by_id(multiplayer.get_unique_id()).is_active = true
	Globals.health.visible = true
	
func select(index:int) -> void:
	#if !is_able_to_select or Globals.ms.players.size() == 1: return
	if !is_able_to_select: return
	selection[0 if multiplayer.get_unique_id() == 1 else 1] = index
	hover_selection_end(index)
	send_selection()
	update_selection()

func send_selection() -> void:
	var receiver_id : int = 1 if multiplayer.get_unique_id() != 1 else Globals.ms.get_second_player_peer_id()
	receive_selection.rpc_id(receiver_id, selection)
	
@rpc("any_peer")
func receive_selection(received_selection:Array) -> void:
	selection = received_selection
	update_selection()
	
func update_selection() -> void:
	if c_1_p_1.get_node("Main").scale.x < 0.1 and selection[0] == 0: update_player_icon(1, 1, true)
	elif c_1_p_1.get_node("Main").scale.x > 0.9 and selection[0] != 0: update_player_icon(1, 1, false)
	if c_1_p_2.get_node("Main").scale.x < 0.1 and selection[1] == 0: update_player_icon(1, 2, true)
	elif c_1_p_2.get_node("Main").scale.x > 0.9 and selection[1] != 0: update_player_icon(1, 2, false)
	if c_2_p_1.get_node("Main").scale.x < 0.1 and selection[0] == 1: update_player_icon(2, 1, true)
	elif c_2_p_1.get_node("Main").scale.x > 0.9 and selection[0] != 1: update_player_icon(2, 1, false)
	if c_2_p_2.get_node("Main").scale.x < 0.1 and selection[1] == 1: update_player_icon(2, 2, true)
	elif c_2_p_2.get_node("Main").scale.x > 0.9 and selection[1] != 1: update_player_icon(2, 2, false)
	if selection[0] == 0: c_1_p_1.visible = selection[0] == 0
	if selection[1] == 0: c_1_p_2.visible = selection[1] == 0
	if selection[0] == 1: c_2_p_1.visible = selection[0] == 1
	if selection[1] == 1: c_2_p_2.visible = selection[1] == 1
	
func update_player_icon(card:int, player:int, is_show:bool) -> void:
	is_able_to_select = false
	var t : Tween = get_tree().create_tween()
	if is_show:
		t.tween_property(get_node("VBox/Cards/"+str(card)+"/Main/Players/P"+str(player)+"/Main"), "scale", Vector2.ONE, 1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(get_node("VBox/Cards/"+str(card)+"/Main/Players/P"+str(player)+"/Main"), "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	is_able_to_select = true
	c_1_p_1.visible = selection[0] == 0
	c_1_p_2.visible = selection[1] == 0
	c_2_p_1.visible = selection[0] == 1
	c_2_p_2.visible = selection[1] == 1

func hover_selection_start(index:int) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($"VBox/Cards/1/Main" if index == 0 else $"VBox/Cards/2/Main", "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hover_selection_end(index:int) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($"VBox/Cards/1/Main" if index == 0 else $"VBox/Cards/2/Main", "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func play() -> void:
	if !multiplayer.is_server(): return
	#if selection[0] == -1 or selection[1] == -1 or selection[0] == selection[1]: return
	var player = Globals.ms.get_player_by_id(multiplayer.get_unique_id())
	var type : int = selection[0 if multiplayer.get_unique_id() == 1 else 1]
	player.type = type
	#Globals.ms.get_player_by_id(Globals.ms.get_second_player_peer_id()).type = 0 if type == 1 else 1
	play_not_host.rpc_id(Globals.ms.get_second_player_peer_id())
	Globals.map.generate()
	close()

@rpc("any_peer")
func play_not_host() -> void:
	var player = Globals.ms.get_player_by_id(multiplayer.get_unique_id())
	var type : int = selection[0 if multiplayer.get_unique_id() == 1 else 1]
	player.type = type
	Globals.ms.get_player_by_id(1).type = 0 if type == 1 else 1
	close()

func invite() -> void:
	if is_friend_list_opened: return
	#Globals.main.open_invite_overlay()
	get_friends()
	is_friend_list_opened = true

func get_friends() -> void:
	friends.clear()
	var new_friends : Array = Globals.main.get_friends()
	new_friends.sort_custom(func(a, b):
		return Steam.getFriendPersonaState(a) > Steam.getFriendPersonaState(b)
	)
	if $FriendsContainer/Main/Friends.get_child_count() > 0:
		for f in $FriendsContainer/Main/Friends.get_children(): f.queue_free()
	for f in new_friends:
		friends[f] = create_friend(f)
		Steam.getPlayerAvatar(2, f)
	var t = get_tree().create_tween()
	t.tween_property($FriendsContainer/Main, "position:x", 0, 0.5).set_trans(Tween.TRANS_SPRING).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(10.0).timeout
	is_friend_list_opened = false
	var t2 = get_tree().create_tween()
	t2.tween_property($FriendsContainer/Main, "position:x", 250, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
func create_friend(steam_id) -> Node:
	var b = BUTTON_UI.instantiate()
	b.title = str(Steam.getFriendPersonaName(steam_id))
	if Steam.getFriendPersonaState(steam_id) == Steam.PERSONA_STATE_OFFLINE:
		b.modulate = Color(0.5, 0.5, 0.5)
	b.method_owner = Globals.main
	b.method_name = "invite"
	b.additional_parameter = str(steam_id)
	b.scale_factor = 0.9
	b.font_max_length = 15
	b.font_color = Color.WHITE
	b.bg_color = Color(0.561, 0.746, 0.982)
	b.custom_minimum_size = Vector2(250, 50)
	$FriendsContainer/Main/Friends.add_child(b)
	return b


func update_avatar(id:int, s:int, data:Array) -> void:
	if not friends.has(id):
		print("No friend found for avatar: ", id)
		return
	var avatar_image: Image = Image.create_from_data(s, s, false, Image.FORMAT_RGBA8, data)
	var friend_button = friends[id]
	friend_button.get_node("Main/ButtonContainer/Button/Profile/Texture").texture = ImageTexture.create_from_image(avatar_image)
	friend_button.get_node("Main/ButtonContainer/Button/Profile").visible = true
