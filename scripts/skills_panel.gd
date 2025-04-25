extends HBoxContainer

@onready var container: HBoxContainer = $VBox/Container

const SKILLS : Dictionary = {
	"Fireproof Spirit": "Fire damage is reduced by XX%.",
	"Serpent's Bane": "Poison effect duration is reduced by XX%.",
	"Frozen Resolve": "Ice effect duration is reduced by XX%.",
	"Shinigami’s Sight": "See invisible enemies from XX% farther.",
	"Mountain’s Strength": "Ball pushing force increased by XX%.", # DONE
	"Way of the Blade": "Your damage increases by XX%.", # DONE
	"Tengu’s Leap": "Gain a double jump.", # DONE
	"Iron Will": "You take XX% less damage.", # DONE
	"Fortune Beckons": "Earn XX% more cash.", # DONE
	"Blood Pact": "Heal for XX% of damage after killing.", # DONE
	"Killer Instinct": "After each kill, your damage increases by XX% by 5 seconds.",
	"Skyward Strike": "Deal XX% more damage while in the air.", # DONE
	"Shadow Flow": "Weapon cooldowns are reduced by XX%.",
	"Cursed Blood": "Enemies have XX% less health." # DONE
}
const PRICES : Dictionary = {
	"Fireproof Spirit": 10,
	"Serpent's Bane": 8,
	"Frozen Resolve": 8,
	"Shinigami’s Sight": 18,
	"Mountain’s Strength": 14,
	"Way of the Blade": 22,
	"Tengu’s Leap": 10,
	"Iron Will": 16,
	"Fortune Beckons": 10,
	"Blood Pact": 24,
	"Killer Instinct": 27,
	"Skyward Strike": 14,
	"Shadow Flow": 16,
	"Cursed Blood": 30
}



var player : CharacterBody3D
var current_skills : Array[Dictionary] = []

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
	if multiplayer.get_unique_id() != 1:
		Globals.processor.add_skill.rpc_id(1, multiplayer.get_unique_id(), selected_skill["title"])
	else:
		Globals.processor.add_skill(multiplayer.get_unique_id(), selected_skill["title"])
	Saving.skills.append(selected_skill["title"])
	Saving.save_data()
	
	for card in container.get_children():
		card.turn_over()
	await get_tree().create_timer(0.2).timeout
	update_skills()
	
func get_skill() -> Dictionary:
	var available_skills : Dictionary = {}
	for skill in SKILLS:
		if Globals.processor.is_skill_max(multiplayer.get_unique_id(), skill):
			continue
		if current_skills.size() > 0 and current_skills[0]["title"] == skill:
			continue
		if current_skills.size() > 1 and current_skills[1]["title"] == skill:
			continue
		available_skills[skill] = SKILLS[skill]
	var title : String = available_skills.keys()[randi() % available_skills.size()]
	var description : String = available_skills[title]
	var price : int = PRICES[title]
	return {"title":title, "description":description, "price":price}
	
func update_skills() -> void:
	current_skills = []
	current_skills.append(get_skill())
	current_skills.append(get_skill())
	current_skills.append(get_skill())
	var count : int = 0
	for skill in current_skills:
		container.get_child(count).update_info(skill)
		count += 1
	await get_tree().create_timer(1.0).timeout
	for card in container.get_children():
		card.turn_over()
