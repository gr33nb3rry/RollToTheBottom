extends MultiplayerSpawner


func _on_despawned(node:Node) -> void:
	if multiplayer.is_server(): return
	print("222222    ", get_child_count(), "   ", Globals.decals.get_child_count())
	if get_child_count() == 0 and Globals.decals.get_child_count() == 0:
		Globals.world.start_level.rpc_id(1)
		#print("2 all")
		#Globals.world.start_level()

func _on_spawned(node: Node) -> void:
	if multiplayer.is_server(): return
	Globals.world.add_barrier.rpc_id(1, get_child_count()-1)
	#Globals.world.add_barrier(get_child_count()-1)
	#update_decal_position_rotation_type(get_child_count()-1, pos, rot, type)
