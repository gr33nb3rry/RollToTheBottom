extends Decal

var type : int
var is_selected : bool = false

@rpc("any_peer")
func select() -> void:
	is_selected = true
	modulate = Color(1, 0.941, 0)
	if multiplayer.is_server():
		Globals.world.select_decal()
