extends Node3D

@export var type : int = 0
@export var direction : Vector3
var power : float = 70.0
var rotation_deg : float = 360.0
var is_on_ground : bool = false

func _ready() -> void:
	if !multiplayer.is_server(): return
	#$Model.look_at(global_position + direction * 10)
	await get_tree().create_timer(20).timeout
	queue_free()
	
func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	global_position += direction * power * delta
	
func _on_area_body_entered(body: Node3D) -> void:
	if !multiplayer.is_server(): return
	if body.is_in_group("Player"): return
	if body.is_in_group("Soot"):
		body.damage(1)
		queue_free()
	death()
	
func death() -> void:
	queue_free()
