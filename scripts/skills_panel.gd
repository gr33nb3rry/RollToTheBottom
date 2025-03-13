extends HBoxContainer

@onready var container: HBoxContainer = $VBox/Container

const SKILLS = {
	"FIREPROOF SPIRIT": "Fire damage is reduced by N%.",
	"SERPENT'S BANE": "Poison effect duration is reduced by N%.",
	"FROZEN RESOLVE": "Ice effect duration is reduced by N%.",
	"SHINIGAMI’S SIGHT": "See invisible enemies from N% farther.",
	"MOUNTAIN’S STRENGTH": "Ball pushing force increased by N%.",
	"WAY OF THE BLADE": "Your damage increases by N%.",
	"TENGU’S LEAP": "Gain a double jump.",
	"IRON WILL": "You take N% less damage.",
	"FORTUNE BECKONS": "Earn N% more cash.",
	"BLOOD PACT": "Heal for N% of the damage you deal.",
	"KILLER INSTINCT": "After each kill, your damage increases by N%, stacking up to 5 times.",
	"SKYWARD STRIKE": "Deal N% more damage while in the air.",
	"SHADOW FLOW": "Weapon cooldowns are reduced by N%.",
	"CURSED BLOOD": "Enemies have N% less health."
}

var player : CharacterBody3D
var current_skills : Dictionary = {}

func open(player:CharacterBody3D) -> void:
	self.player = player
	player.is_active = false
	player.stop()
	visible = true
	update_skills()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.is_active = true
	
func choose_skill(id:int) -> void:
	var selected_skill = current_skills[id]
	Saving.skills.append(selected_skill["title"])
	Saving.save_data()
	for card in container.get_children():
		card.turn_over()
	await get_tree().create_timer(0.2).timeout
	update_skills()
	
func get_skill() -> Dictionary:
	var title : String = SKILLS.keys()[randi() % SKILLS.size()]
	var description : String = SKILLS[title]
	return {"title":title, "description":description}
	
func update_skills() -> void:
	current_skills = {0:get_skill(),1:get_skill(),2:get_skill()}
	for skill in current_skills:
		var title = current_skills[skill]["title"]
		var description = current_skills[skill]["description"]
		#container.get_child(skill).get_node("Container/Margin/HBox/TitleLabel").text = "[center]"+title+"[/center]"
		#container.get_child(skill).get_node("Container/Margin/HBox/DescriptionLabel").text = description
		container.get_child(skill).update_info(current_skills[skill])
	await get_tree().create_timer(1.0).timeout
	for card in container.get_children():
		card.turn_over()
