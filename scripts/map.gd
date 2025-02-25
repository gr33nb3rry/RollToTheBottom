extends Node3D

const ZONES : Array[PackedScene] = [
	preload("res://scenes/zones/zone1.tscn"),
	preload("res://scenes/zones/zone2.tscn"),
	preload("res://scenes/zones/zone3.tscn")
]

var zones : Array

func _ready() -> void:
	for i in 1:
		generate()
	
func _input(_event) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()

func generate() -> void:
	var zone = ZONES[0].instantiate()
	add_child(zone)
	var pos = global_position if zones.size() == 0 else zones[-1].get_next_zone_position() 
	var rot = Vector3.ZERO if zones.size() == 0 else zones[-1].get_next_zone_rotation()
	zone.global_position = pos
	zone.rotation = rot
	zones.append(zone)
	
