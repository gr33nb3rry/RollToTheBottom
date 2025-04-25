extends Control

var selection : Array = [-1, -1]

func _ready() -> void:
	update_selection()
	
func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for p in Globals.ms.players.values():
		p.is_active = false
func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	for p in Globals.ms.players:
		p.is_active = true
	
func select(index:int) -> void:
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
	print($"HBox/1/Main/Players/P1/Main".scale.x)
	if $"HBox/1/Main/Players/P1/Main".scale.x < 0.1 and selection[0] == 0: update_player_icon(1, 1, true)
	elif $"HBox/1/Main/Players/P1/Main".scale.x > 0.9 and selection[0] != 0: update_player_icon(1, 1, false)
	if $"HBox/1/Main/Players/P2/Main".scale.x < 0.1 and selection[1] == 0: update_player_icon(1, 2, true)
	elif $"HBox/1/Main/Players/P2/Main".scale.x > 0.9 and selection[1] != 0: update_player_icon(1, 2, false)
	if $"HBox/2/Main/Players/P1/Main".scale.x < 0.1 and selection[0] == 1: update_player_icon(2, 1, true)
	elif $"HBox/2/Main/Players/P1/Main".scale.x > 0.9 and selection[0] != 1: update_player_icon(2, 1, false)
	if $"HBox/2/Main/Players/P2/Main".scale.x < 0.1 and selection[1] == 1: update_player_icon(2, 2, true)
	elif $"HBox/2/Main/Players/P2/Main".scale.x > 0.9 and selection[1] != 1: update_player_icon(2, 2, false)
	if selection[0] == 0: $"HBox/1/Main/Players/P1".visible = selection[0] == 0
	if selection[1] == 0: $"HBox/1/Main/Players/P2".visible = selection[1] == 0
	if selection[0] == 1: $"HBox/2/Main/Players/P1".visible = selection[0] == 1
	if selection[1] == 1: $"HBox/2/Main/Players/P2".visible = selection[1] == 1
	
func update_player_icon(card:int, player:int, is_show:bool) -> void:
	var t : Tween = get_tree().create_tween()
	if is_show:
		t.tween_property(get_node("HBox/"+str(card)+"/Main/Players/P"+str(player)+"/Main"), "scale", Vector2.ONE, 1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	else:
		t.tween_property(get_node("HBox/"+str(card)+"/Main/Players/P"+str(player)+"/Main"), "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	$"HBox/1/Main/Players/P1".visible = selection[0] == 0
	$"HBox/1/Main/Players/P2".visible = selection[1] == 0
	$"HBox/2/Main/Players/P1".visible = selection[0] == 1
	$"HBox/2/Main/Players/P2".visible = selection[1] == 1

func hover_selection_start(index:int) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($"HBox/1/Main" if index == 0 else $"HBox/2/Main", "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hover_selection_end(index:int) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($"HBox/1/Main" if index == 0 else $"HBox/2/Main", "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
