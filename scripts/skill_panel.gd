extends Control

@onready var front: Panel = $Main/SubViewport/Front
var is_hovering : bool = false
var is_able_to_hover : bool = false
var is_rotated : bool = false

func choose() -> void:
	$/root/Main/Canvas/Skills.choose_skill(get_index())

func turn_over() -> void:
	$Animation.play("show_back" if is_rotated else "show_front")
	is_rotated = !is_rotated

func update_info(info:Dictionary) -> void:
	var title = info["title"]
	var description = info["description"]
	front.get_node("Margin/HBox/TitleLabel").text = "[center]"+title+"[/center]"
	front.get_node("Margin/HBox/DescriptionLabel").text = description

func _on_button_mouse_entered() -> void:
	is_hovering = true
	var t = get_tree().create_tween()
	t.tween_property($Main, "position:y", -25, 0.2).set_trans(Tween.TRANS_CUBIC)

func _on_button_mouse_exited() -> void:
	is_hovering = false
	var t = get_tree().create_tween()
	t.tween_property($Main, "position:y", 0, 0.2)
	reset_rot()

func _on_main_gui_input(event: InputEvent) -> void:
	if !is_hovering or !is_rotated: return
	var mouse_pos: Vector2 = get_local_mouse_position()
	var diff: Vector2 = (position + size) - mouse_pos
	var lerp_val_x: float = remap(mouse_pos.x, 0.0, size.x, 0, 1)
	var lerp_val_y: float = remap(mouse_pos.y, 0.0, size.y, 0, 1)
	var max_angle : float = deg_to_rad(10.0)
	var rot_x: float = rad_to_deg(lerp_angle(-max_angle, max_angle, lerp_val_x))
	var rot_y: float = rad_to_deg(lerp_angle(max_angle, -max_angle, lerp_val_y))
	$Main.material.set_shader_parameter("x_rot", rot_y)
	$Main.material.set_shader_parameter("y_rot", rot_x)
func reset_rot() -> void:
	var t = get_tree().create_tween().set_parallel()
	t.tween_property($Main.material, "shader_parameter/x_rot", 0.0, 0.2)
	t.tween_property($Main.material, "shader_parameter/y_rot", 0.0, 0.2)
