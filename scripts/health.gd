extends Control

var ball_player : Node
var is_rolling : bool = false

@rpc("any_peer")
func update(max_health:Array, health:Array) -> void:
	var type_0_index : int = 0 if Globals.ms.players.values()[0].type == 0 else 1
	var type_1_index : int = 0 if Globals.ms.players.values()[0].type == 1 else 1
	
	$HP1.max_value = max_health[type_1_index]
	$HP1.value = health[type_1_index]
	$HP1/Label.text = str(health[type_1_index]) + "/" + str(max_health[type_1_index])
	$HP2.max_value = max_health[type_0_index]
	$HP2.value = health[type_0_index]
	$HP2/Label.text = str(health[type_0_index]) + "/" + str(max_health[type_0_index])

func push_ball(is_start:bool) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($HP2, "position:x", 60 if is_start else 80, 0.2)

@rpc("any_peer")
func hit_ball() -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($HP1, "position:y", -55, 0.1)
	t.tween_property($HP1, "position:y", -35, 0.1)
	
func _process(delta: float) -> void:
	if ball_player == null:
		var p2 = Globals.ms.get_ball_player()
		if p2 == null:
			return
		ball_player = p2
	
	if is_rolling and !ball_player.is_rolling: 
		is_rolling = false
		push_ball(false)
	elif !is_rolling and ball_player.is_rolling: 
		is_rolling = true
		push_ball(true)
