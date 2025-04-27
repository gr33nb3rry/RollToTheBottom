extends Control

var is_clicked : bool = false
@export var method_owner: Node
@export var method_name: String

func hover_selection_start() -> void:
	if is_clicked: return
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(1.2, 1.2), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func hover_selection_end() -> void:
	if is_clicked: return
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func click() -> void:
	is_clicked = true
	var t : Tween = get_tree().create_tween()
	t.tween_property($Main, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	await t.finished
	is_clicked = false
	var call : Callable = Callable(method_owner, method_name)
	call.call()

func deactivate() -> void:
	$Main/ButtonContainer/Button.disabled = true
func activate() -> void:
	$Main/ButtonContainer/Button.disabled = false
