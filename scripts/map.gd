extends Node3D

const ZONES : Array[PackedScene] = [
	preload("res://scenes/zones/zone1.tscn"),
	preload("res://scenes/zones/zone2.tscn"),
	preload("res://scenes/zones/zone3.tscn")
]

var zones : Array

func _ready() -> void:
	for i in 5:
		generate()

func generate() -> void:
	var zone = ZONES[0].instantiate()
	add_child(zone)
	var pos = $Room/Pos2.global_position if zones.size() == 0 else zones[-1].get_next_zone_position() 
	var rot = Vector3.ZERO if zones.size() == 0 else zones[-1].get_next_zone_rotation()
	zone.global_position = pos
	zone.rotation = rot
	zones.append(zone)
	
