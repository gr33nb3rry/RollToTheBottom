extends Node3D

func _ready() -> void:
	$CurveMesh3D.get_child(0).create_trimesh_collision()
