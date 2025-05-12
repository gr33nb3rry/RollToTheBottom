extends Decal

const DECAL_0 = preload("res://images/decals/decal0.png")
const DECAL_1 = preload("res://images/decals/decal1.png")
const DECAL_2 = preload("res://images/decals/decal2.png")
const DECAL_3 = preload("res://images/decals/decal3.png")
const DECAL_4 = preload("res://images/decals/decal4.png")
const DECAL_5 = preload("res://images/decals/decal5.png")

var type : int
var bonus_type : int = -1
var is_selected : bool = false

func update_type() -> void:
	match type:
		0: texture_albedo = DECAL_0
		1: texture_albedo = DECAL_1
		2: texture_albedo = DECAL_2
		3: texture_albedo = DECAL_3
		4: texture_albedo = DECAL_4
		5: texture_albedo = DECAL_5
	if type == 6:
		var available_type : Array
		for i in Saving.bonus_decals:
			if Saving.bonus_decals[i] == false: available_type.append(i)
		if available_type.size() < 1:
			print("No more bonus decals")
			is_selected = true
			visible = false
		else:
			bonus_type = available_type[randi_range(0, available_type.size()-1)]
			texture_albedo = load("res://images/fruits/"+str(bonus_type)+".png")
			modulate = Color.WHITE

@rpc("any_peer")
func select() -> void:
	is_selected = true
	modulate = Color(1, 0.941, 0)
	if multiplayer.is_server():
		Globals.world.select_decal()

func select_bonus() -> void:
	print("Select bonus decal with type ", bonus_type)
	is_selected = true
	visible = false
	Saving.bonus_decals[bonus_type] = true
	print("Bonus decals: ", Saving.bonus_decals)
	Saving.save_data()
