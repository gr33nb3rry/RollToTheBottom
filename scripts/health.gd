extends Control

var ball_player : Node
var is_rolling : bool = false

@rpc("any_peer")
func update(max_health:Array, health:Array) -> void:
	print("Damage in health")
	$HP1.max_value = max_health[0]
	$HP1.value = health[0]
	$HP1/Label.text = str(health[0]) + "/" + str(max_health[0])
	$HP2.max_value = max_health[1]
	$HP2.value = health[1]
	$HP2/Label.text = str(health[1]) + "/" + str(max_health[1])

func push_ball(is_start:bool) -> void:
	var t : Tween = get_tree().create_tween()
	t.tween_property($HP2, "position:x", 60 if is_start else 80, 0.2)

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
