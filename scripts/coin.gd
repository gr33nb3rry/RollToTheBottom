extends Node3D

const RADIUS : float = 0.5
const JUMP_HEIGHT : float = 3.0
const HEIGHT : float = 0.5
var target_pos : Vector3

func _process(delta: float) -> void:
	rotation_degrees.y += 90 * delta
	if is_near_enough():
		collect()
	
func move() -> void:
	var nearest_pos : Vector3 = Globals.world.get_coin_position(global_position)
	$Ray.global_position = nearest_pos + Vector3(0, 10, 0)
	await get_tree().create_timer(0.1).timeout
	var pos : Vector3 = $Ray.get_collision_point() + Vector3(0, RADIUS, 0)
	target_pos = pos
	
	var t = get_tree().create_tween()
	t.tween_property(self, "global_position:x", target_pos.x, 1.5)
	t.parallel().tween_property(self, "global_position:z", target_pos.z, 1.5)
	var t2 = get_tree().create_tween()
	t2.tween_property(self, "global_position:y", global_position.y + JUMP_HEIGHT, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t2.tween_property(self, "global_position:y", target_pos.y, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t2.tween_property(self, "global_position:y", target_pos.y + HEIGHT, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	

func collect() -> void:
	if multiplayer.is_server():
		Globals.processor.change_coins(1)
	queue_free()
	
func is_near_enough() -> bool:
	var distance_squared = global_position.distance_squared_to(Globals.ms.get_nearest_player(global_position).global_position)
	return distance_squared < RADIUS * RADIUS + 1.0
