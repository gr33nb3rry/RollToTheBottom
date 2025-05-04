extends Decal

var type : int
var is_selected : bool = false

func select() -> void:
	is_selected = true
	modulate = Color(1, 0.941, 0)
	Globals.world.select_decal()
