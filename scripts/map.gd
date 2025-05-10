extends Node3D

const ZONES : Array[PackedScene] = [
	preload("res://scenes/zones/zone1.tscn"),
	preload("res://scenes/zones/zone2.tscn"),
	preload("res://scenes/zones/zone3.tscn"),
	preload("res://scenes/zones/zone_end.tscn")
]

var zones : Array

func generate() -> void:
	if !multiplayer.is_server(): return
	for i in 3: 
		var is_end : bool = i == 2
		var zone_index : int = randi_range(0, ZONES.size()-2) if !is_end else -1
		add_zone(zone_index, is_end)
		add_zone.rpc_id(Globals.ms.get_second_player_peer_id(), zone_index, is_end)

@rpc("any_peer")
func add_zone(zone_index:int, is_end:bool) -> void:
	var zone = ZONES[zone_index].instantiate()
	add_child(zone)
	var pos = $Room/Pos2.global_position if zones.size() == 0 else zones[-1].get_next_zone_position() 
	var rot = Vector3.ZERO if zones.size() == 0 else zones[-1].get_next_zone_rotation()
	zone.global_position = pos
	zone.rotation = rot
	zone.is_end = is_end
	zones.append(zone)
	
