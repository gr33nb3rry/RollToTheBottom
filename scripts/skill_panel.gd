extends Control

func choose() -> void:
	get_parent().choose_skill(get_index())


func _on_button_mouse_entered() -> void:
	print("start")
	var t = get_tree().create_tween()
	t.tween_property($Container, "position:y", -25, 0.2).set_trans(Tween.TRANS_CUBIC)


func _on_button_mouse_exited() -> void:
	print("end")
	var t = get_tree().create_tween()
	t.tween_property($Container, "position:y", 0, 0.2)
