extends Node3D

@export var type : int = 0
var direction : Vector3
var power : float = 20.0
var rotation_deg : float = 360.0
var is_on_ground : bool = false

func _ready() -> void:
	if !multiplayer.is_server(): return
	$Model.look_at(global_position + direction * 10)
	await get_tree().create_timer(20).timeout
	queue_free()
	
func _process(delta: float) -> void:
	if !multiplayer.is_server(): return
	global_position += direction * power * delta
	rotation_degrees.y += rotation_deg * delta
	
func _on_area_body_entered(body: Node3D) -> void:
	if !multiplayer.is_server(): return
	if body.is_in_group("Soot") or is_on_ground: return
	if body.is_in_group("Player"):
		hit(body)
		queue_free()
	death()
	
func death() -> void:
	direction = Vector3.ZERO
	rotation_deg = 0.0
	is_on_ground = true

func hit(body: Node3D) -> void:
	print(hit," ",body)
	if type == 0:
		body.damage(1)
	elif type == 1:
		body.damage(1)
