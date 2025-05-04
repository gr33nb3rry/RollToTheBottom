extends Control

var type : int
var value : String
var answer : String

func update(type:int, value:String, answer:String) -> void:
	visible = true
	self.type = type
	self.value = value
	self.answer = answer
	match type:
		Globals.world.Activities.COUNTER:
			$HBox/VBox/Task/Label.text = "[center]Find all [img=50]res://images/decals/decal" + value + ".png[/img]"
			$HBox/VBox/Current/Label.text = "[center][b]" + str(Globals.world.selected_decals) + "[/b]/" + answer
			$HBox/VBox/Current.visible = true

func update_current() -> void:
	match type:
		Globals.world.Activities.COUNTER:
			$HBox/VBox/Current/Label.text = "[center][b]" + str(Globals.world.selected_decals) + "[/b]/" + answer

func finish() -> void:
	visible = false
	$HBox/VBox/Current.visible = false
