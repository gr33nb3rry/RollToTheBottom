extends Node3D

func _ready() -> void:
	await get_tree().process_frame
	clip_to_ground_boxes()

func clip_to_ground_boxes() -> void:
	for box in $Boxes.get_children():
		box.clip_to_ground()
		await get_tree().physics_frame
