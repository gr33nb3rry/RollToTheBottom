extends MultiplayerSpawner

const DECAL_0 = preload("res://images/decals/decal0.png")
const DECAL_1 = preload("res://images/decals/decal1.png")
const DECAL_2 = preload("res://images/decals/decal2.png")
const DECAL_3 = preload("res://images/decals/decal3.png")
const DECAL_4 = preload("res://images/decals/decal4.png")
const DECAL_5 = preload("res://images/decals/decal5.png")

func _on_despawned(node:Node) -> void:
	if multiplayer.is_server(): return
	print("111111    ", get_child_count(), "   ", Globals.barriers.get_child_count())
	if get_child_count() == 0 and Globals.barriers.get_child_count() == 0:
		Globals.world.start_level.rpc_id(1)
		#print("1 all")
		#Globals.world.start_level()


func _on_spawned(node: Node) -> void:
	if multiplayer.is_server(): return
	print("Request add new decal with index ", get_child_count()-1)
	Globals.world.add_decal.rpc_id(1, get_child_count()-1)
	#Globals.world.add_decal(get_child_count()-1)
	#update_decal_position_rotation_type(get_child_count()-1, pos, rot, type)
