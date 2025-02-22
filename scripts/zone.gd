extends Node3D

func _ready() -> void:
	$CurveMesh3D.get_child(0).create_trimesh_collision()

func get_next_zone_position() -> Vector3:
	return $Room/Pos2.global_position
func get_next_zone_rotation() -> Vector3:
	return $Room.rotation + rotation
