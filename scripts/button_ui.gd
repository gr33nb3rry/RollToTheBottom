extends Control

var is_clicked : bool = false
@export var method_owner : Node
@export var method_name : String
@export var additional_parameter : String = ""
@export var title : String
@export var scale_factor : float = 1.2
@export var font_size : int = 24
@export var font_max_length : int = -1
@export var font_color : Color = Color.BLACK
@export var bg_color : Color = Color.WHITE
@export var initial_bg_alpha : float = 0.5
@export var is_uppercase : bool = false
@export var font_outline_size : int = 0


func update() -> void:
	$Main.pivot_offset.x = $Main.size.x/2
	$Main.pivot_offset.y = $Main.size.y/2
	$Main/ButtonContainer/Button.self_modulate = bg_color
	$Main/ButtonContainer/Button.self_modulate.a = initial_bg_alpha
	if font_max_length != -1:
		title = shorten_string(title, font_max_length)
	$Main/ButtonContainer/Button/Label.text = title if !is_uppercase else title.to_upper()
	$Main/ButtonContainer/Button/Label.set("theme_override_font_sizes/font_size", font_size)
	$Main/ButtonContainer/Button/Label.set("theme_override_colors/font_color", font_color)

func shorten_string(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return text.substr(0, max_length - 3) + "..."


func hover_selection_start() -> void:
	if is_clicked: return
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(scale_factor, scale_factor), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button, "self_modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button/Label, "theme_override_constants/outline_size", font_outline_size, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func hover_selection_end() -> void:
	if is_clicked: return
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button, "self_modulate:a", initial_bg_alpha, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button/Label, "theme_override_constants/outline_size", 0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
func click() -> void:
	is_clicked = true
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button, "self_modulate:a", initial_bg_alpha, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property($Main/ButtonContainer/Button/Label, "theme_override_constants/outline_size", 0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await t.finished
	is_clicked = false
	var call : Callable = Callable(method_owner, method_name)
	if additional_parameter != "": call.call(additional_parameter)
	else: call.call()

func deactivate() -> void:
	$Main/ButtonContainer/Button.disabled = true
func activate() -> void:
	$Main/ButtonContainer/Button.disabled = false
