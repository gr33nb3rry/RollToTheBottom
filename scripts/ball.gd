extends RigidBody3D

const INITIAL_MASS : float = 25.0
const STRENGTH : float = 20.0
const DUNG_PICKUP_VALUE_MULTIPLIER : float = 5.0
const MIN_TIME_IN_AIR_TO_BREAK : float = 0.5

var radius : float = 2.0
var is_on_ground : bool = true
var is_hitted : bool = false
var time_in_air : float = 0.0
var direction : Vector3
var jump_force : float = 20.0
const GRAVITY : float = 7.0
@onready var world = $/root/Main/World

var is_simplified : bool = false
var simplicity_level : float = 7.0 # 7 MAX 3.5 OK
var simplicity_current : float = 1.0

var is_active : bool = true:
	set(v):
		is_active = v
		gravity_scale = 1 if is_active else 0

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if Globals.world.is_playing and global_position.y < Globals.world.dead_line:
		Globals.world.is_playing = false
		Globals.world.game_over()
	if !is_active: return
	$/root/Main/Canvas/DebugLabel.text = str(is_on_ground)
	#if !is_on_ground:
	#	time_in_air += delta
	#else: time_in_air = 0.0
	if is_hitted and direction.length() < Globals.processor.BALL_PUSH_FORCE:
		is_hitted = false
	linear_velocity = direction + Vector3(0,-1,0) * GRAVITY
	if direction.length() > 0.01:
		if is_simplified:
			var simplicity_direction = (world.get_zone_next_marker() - global_position).normalized()
			if !world.is_marker_completed(): 
				linear_velocity += simplicity_direction * simplicity_level * simplicity_current
			
		if linear_velocity.length() > direction.length():
			linear_velocity.x = linear_velocity.normalized().x * direction.length()
			linear_velocity.z = linear_velocity.normalized().z * direction.length()
			
		direction /= 1.0 + delta * 3
		simplicity_current /= 1.0 + delta * 3
	else:
		direction = Vector3.ZERO

func add_impulse(from:Node3D, push_force:float, is_hit:bool = false) -> void:
	var push_normal : Vector3 = global_position - from.global_position
	#direction = Vector3(push_normal.x,push_normal.y,push_normal.z).normalized() * push_force
	if !is_hitted:
		direction.x = push_normal.normalized().x * push_force
		direction.z = push_normal.normalized().z * push_force
	else:
		direction.x = direction.normalized().x * direction.length()
		direction.z = direction.normalized().z * direction.length()
	if !is_hitted:
		is_hitted = is_hit
	simplicity_current = 1.0

@rpc("any_peer")
func jump() -> void:
	direction.y = jump_force
		
func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_P):
		jump()
	elif Input.is_key_pressed(KEY_O):
		var pos = Globals.ms.get_player_by_id(1).global_position + Vector3(0, 5, 0)
		global_position = pos

func grow(value:float) -> void:
	$Mesh.scale += Vector3(value, value, value)
	$Collision.scale += Vector3(value, value, value)
	$Area/Collision.scale += Vector3(value, value, value)
	mass = clamp(mass + INITIAL_MASS * value, 1.0, 75.0)
	radius = $Mesh.mesh.radius * $Mesh.scale.x
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
		var r2 = item.get_node("Mesh").mesh.radius * item.scale.x
		var v1 = get_volume(radius)
		var v2 = get_volume(r2)
		var scale_increase : float = get_radius(v1+v2)/radius-1.0
		grow(scale_increase * DUNG_PICKUP_VALUE_MULTIPLIER)
		item.queue_free()
func _on_area_area_exited(_area: Area3D) -> void:
	pass
	
func update_pieces() -> void:
	for p in $Pieces.get_children():
		var dir = (p.position - Vector3.ZERO).normalized()
		p.position = dir * $Mesh.mesh.radius * $Mesh.scale.x - dir * 0.25
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
			print("Ball break: ", break_value)
			if break_value < $Mesh.scale.x:
				shrink(break_value)
			else: queue_free()
	elif body.is_in_group("Soot"):
		var r2 = body.get_node("Mesh").mesh.radius * body.scale.x
		var v1 = get_volume(radius)
		var v2 = get_volume(r2)
		var scale_increase : float = get_radius(v1+v2)/radius-1.0
		grow(scale_increase * DUNG_PICKUP_VALUE_MULTIPLIER)
		body.queue_free()
		if multiplayer.is_server():
			Globals.processor.change_coins(1)
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

func stop() -> void:
	angular_velocity = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	
