extends Control

func update() -> void:
	var found_count : int = 0
	for i in Saving.bonus_decals:
		if Saving.bonus_decals[i] == true: found_count += 1
	$Container/VBox/FoundCount/Count.text = str(found_count) + "/" + str(Saving.bonus_decals.size())
	var count : int = 0
	for i in $Container/VBox/Grid.get_children():
		i.get_node("Texture").texture = load("res://images/fruits/"+str(count)+".png")
		if Saving.bonus_decals[count] == true:
			i.get_node("Texture").modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			i.get_node("Texture").modulate = Color(0.45, 0.45, 0.45, 0.5)
		count += 1
