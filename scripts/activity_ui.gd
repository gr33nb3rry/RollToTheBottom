extends Control

var type : int
var value : String
var answer : String
var tween_current : Tween

@rpc("any_peer")
func update(type:int, value:String, answer:String) -> void:
	visible = true
	self.type = type
	self.value = value
	self.answer = answer
	match type:
		Globals.world.Activities.COUNTER:
			$HBox/VBox/Task/Label.text = "[center]Find all [img=50]res://images/decals/decal" + value + ".png[/img]"
			$HBox/VBox/Current/Label.text = "[center][b]" + str(Globals.world.selected_decals) + "[/b]/" + answer
			$HBox/VBox/Current/Label.scale = Vector2.ZERO
			$HBox/VBox/Current.visible = true
			var t = get_tree().create_tween()
			t.tween_property($HBox/VBox/Current/Label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT_IN)
@rpc("any_peer")
func update_current() -> void:
	match type:
		Globals.world.Activities.COUNTER:
			$HBox/VBox/Current/Label.text = "[center][b]" + str(Globals.world.selected_decals) + "[/b]/" + answer
			$HBox/VBox/Current/Label.scale = Vector2(1.3, 1.3)
			if tween_current != null and tween_current.is_running(): tween_current.kill()
			tween_current = get_tree().create_tween()
			tween_current.tween_property($HBox/VBox/Current/Label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
@rpc("any_peer")
func finish() -> void:
	visible = false
	$HBox/VBox/Current.visible = false
