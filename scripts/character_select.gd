extends Control

@onready var c_1_p_1: Control = $"VBox/Cards/1/Main/Players/P1"
@onready var c_1_p_2: Control = $"VBox/Cards/1/Main/Players/P2"
@onready var c_2_p_1: Control = $"VBox/Cards/2/Main/Players/P1"
@onready var c_2_p_2: Control = $"VBox/Cards/2/Main/Players/P2"

var selection : Array = [-1, -1]
var is_able_to_select : bool = true

func _ready() -> void:
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
	play_not_host.rpc_id(Globals.ms.get_second_player_peer_id())
	close()

@rpc("any_peer")
func play_not_host() -> void:
	var player = Globals.ms.get_player_by_id(multiplayer.get_unique_id())
	var type : int = selection[0 if multiplayer.get_unique_id() == 1 else 1]
	player.type = type
	close()
