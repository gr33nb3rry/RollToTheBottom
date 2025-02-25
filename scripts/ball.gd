extends RigidBody3D

const INITIAL_MASS : float = 25.0
const STRENGTH : float = 20.0
const DUNG_PICKUP_VALUE_MULTIPLIER : float = 5.0
const MIN_TIME_IN_AIR_TO_BREAK : float = 0.5

var is_on_ground : bool = true
var time_in_air : float = 0.0
var direction : Vector3
const GRAVITY : float = 7.0
@onready var world = $/root/Main/World

var is_simplified : bool = false
var simplicity_level : float = 7.0
var simplicity_current : float = 1.0

func _physics_process(delta: float) -> void:
	#$/root/Main/Canvas/DebugLabel.text = str(direction.length())
	#if !is_on_ground:
	#	time_in_air += delta
	#else: time_in_air = 0.0
	
	linear_velocity = direction + Vector3(0,-1,0) * GRAVITY
	if direction.length() > 0.01:
		if is_simplified:
			var simplicity_direction = (world.get_zone_next_marker() - global_position).normalized()
			linear_velocity += simplicity_direction * simplicity_level * simplicity_current
		direction /= 1.0 + delta * 3
		simplicity_current /= 1.0 + delta * 3
	else:
		direction = Vector3.ZERO

func add_impulse(player:CharacterBody3D, push_force:float) -> void:
	var max_linear_velocity = 20.0 / $Mesh.scale.x
	var push_normal : Vector3 = global_position - player.global_position
	direction = Vector3(push_normal.x,push_normal.y,push_normal.z).normalized() * push_force
	simplicity_current = 1.0


func grow(value:float) -> void:
	$Mesh.scale += Vector3(value, value, value)
	$Collision.scale += Vector3(value, value, value)
	$Area/Collision.scale += Vector3(value, value, value)
	mass = clamp(mass + INITIAL_MASS * value, 1.0, 75.0)
	update_pieces()
func shrink(value:float) -> void:
	$Mesh.scale -= Vector3(value, value, value)
	$Collision.scale -= Vector3(value, value, value)
	$Area/Collision.scale -= Vector3(value, value, value)
	mass = clamp(mass - INITIAL_MASS * value, 1.0, 75.0)
	update_pieces()


func _on_area_area_entered(area: Area3D) -> void:
	var item = area.get_parent()
	if item.has_meta("dung"):
		var r1 = $Mesh.mesh.radius * $Mesh.scale.x
		var r2 = item.get_node("Mesh").mesh.radius * item.scale.x
		var v1 = get_volume(r1)
		var v2 = get_volume(r2)
		var scale_increase : float = get_radius(v1+v2)/r1-1.0
		grow(scale_increase * DUNG_PICKUP_VALUE_MULTIPLIER)
		item.queue_free()
func _on_area_area_exited(area: Area3D) -> void:
	pass
	
func update_pieces() -> void:
	for p in $Pieces.get_children():
		var direction = (p.position - Vector3.ZERO).normalized()
		p.position = direction * $Mesh.mesh.radius * $Mesh.scale.x - direction * 0.25
	$Pieces.visible = $Mesh.scale.x > 0.7
		

func get_volume(r:float):
	return (4.0/3.0)*PI*pow(r,3)
func get_radius(v:float):
	return pow((3.0 * v / (4.0 * PI)),(1.0 / 3.0))


func _on_area_body_entered(body: Node3D) -> void:
	if !is_on_ground and body.is_in_group("Ground"): 
		is_on_ground = true
		if time_in_air > MIN_TIME_IN_AIR_TO_BREAK:
			var break_value = time_in_air / STRENGTH
			print("Ball break: ",break_value)
			if break_value < $Mesh.scale.x:
				shrink(break_value)
			else: queue_free()
	elif body.is_in_group("Ant"):
		body.touch()
func _on_area_body_exited(body: Node3D) -> void:
	for b in $Area.get_overlapping_bodies(): if b.is_in_group("Ground"): return
	if body.is_in_group("Ground"): is_on_ground = false
	
func freeze_on_time(time:float) -> void:
	set_freeze_enabled(true)
	await get_tree().create_timer(time).timeout
	time_in_air = 0.0
	set_freeze_enabled(false)

func refresh_size() -> void:
	$Mesh.scale = Vector3.ONE
	$Collision.scale = Vector3.ONE
	$Area/Collision.scale = Vector3.ONE
	mass = INITIAL_MASS
	update_pieces()
