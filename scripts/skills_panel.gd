extends HBoxContainer


const DESCRIPTIONS : Dictionary = {
	"BALL KICKER": "Ability to kick the ball with N force",
	"PULL THE BALL": "Ability to pull the ball with N force",
	"FREEZE IT UP": "Ability to freeze the ball for N seconds",
	"ANT KILLER": "Kill all ants",
	"BALL REFRESHER": "Refresh ball size"
}
const POSSIBLE_VALUES : Dictionary = {
	"BALL KICKER": [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
	"PULL THE BALL": [10, 20, 30, 40, 50, 60, 70, 80, 90, 100],
	"FREEZE IT UP": [1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5],
	"ANT KILLER": [],
	"BALL REFRESHER": []
}
var player : CharacterBody3D

func open(player:CharacterBody3D) -> void:
	self.player = player
	player.is_active = false
	player.stop()
	visible = true
	update_skills({0:get_skill(),1:get_skill(),2:get_skill()})
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func choose_skill(id:int) -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.is_active = true
	
func get_skill() -> Dictionary:
	var title : String = DESCRIPTIONS.keys()[randi() % DESCRIPTIONS.size()]
	var description : String = DESCRIPTIONS[title]
	var possible_values : Array = POSSIBLE_VALUES[title]
	var value = str(possible_values[randi() % possible_values.size()]) if !possible_values.is_empty() else ""
	return {"title":title,"value":value}
	
func update_skills(skills:Dictionary) -> void:
	for skill in skills:
		var title = skills[skill]["title"]
		var description = DESCRIPTIONS[title]
		var value = skills[skill]["value"]
		get_child(skill).get_node("Container/Margin/HBox/TitleLabel").text = "[center]"+title+"[/center]"
		get_child(skill).get_node("Container/Margin/HBox/DescriptionLabel").text = description
		get_child(skill).get_node("Container/Margin/HBox/ValueLabel").text = "[center][b]"+value+"[/b][/center]"
