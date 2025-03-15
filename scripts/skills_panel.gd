extends HBoxContainer

@onready var container: HBoxContainer = $VBox/Container

const SKILLS = {
	"Fireproof Spirit": "Fire damage is reduced by XX%.",
	"Serpent's Bane": "Poison effect duration is reduced by XX%.",
	"Frozen Resolve": "Ice effect duration is reduced by XX%.",
	"Shinigami’s Sight": "See invisible enemies from XX% farther.",
	"Mountain’s Strength": "Ball pushing force increased by XX%.",
	"Way of the Blade": "Your damage increases by XX%.",
	"Tengu’s Leap": "Gain a double jump.",
	"Iron Will": "You take XX% less damage.",
	"Fortune Beckons": "Earn XX% more cash.",
	"Blood Pact": "Heal for XX% of the damage you deal.",
	"Killer Instinct": "After each kill, your damage increases by XX%, stacking up to XX times.",
	"Skyward Strike": "Deal XX% more damage while in the air.",
	"Shadow Flow": "Weapon cooldowns are reduced by XX%.",
	"Cursed Blood": "Enemies have XX% less health."
};


var player : CharacterBody3D
var current_skills : Dictionary = {}

func open(initiator:CharacterBody3D) -> void:
	print("skills opened")
	player = initiator
	player.is_active = false
	player.stop()
	visible = true
	update_skills()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.is_active = true
	for card in container.get_children():
		card.reset()
	
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
