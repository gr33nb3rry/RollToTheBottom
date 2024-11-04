extends HBoxContainer


const DESCRIPTIONS : Dictionary = {
	"TITLE1": "Description of Title1",
	"TITLE2": "Description of Title2",
	"TITLE3": "Description of Title3"
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
	var possible_values : Array
	match title:
		"TITLE1": possible_values = [10,20,30,40,50]
		"TITLE2": possible_values = [10,20,30,40,50]
		"TITLE3": possible_values = [10,20,30,40,50]
	var value = possible_values[randi() % possible_values.size()]
	return {"title":title,"value":value}
	
func update_skills(skills:Dictionary) -> void:
	for skill in skills:
		var title = skills[skill]["title"]
		var description = DESCRIPTIONS[title]
		var value = skills[skill]["value"]
		get_child(skill).get_node("MarginContainer/HBoxContainer/TitleLabel").text = title
		get_child(skill).get_node("MarginContainer/HBoxContainer/DescriptionLabel").text = description
		get_child(skill).get_node("MarginContainer/HBoxContainer/ValueLabel").text = "[center][b]"+str(value)+"[/b][/center]"
