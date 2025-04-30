extends RigidBody3D

const PROJECTILE_S = preload("res://scenes/projectile_s.tscn")
const GOLD_MATERIAL = preload("res://materials/gold_ver2_material.tres")

const RADIUS : float = 0.5
const MOVE_SPEED : float = 20.0
const PUSH_FORCE : float = 200.0
const TIME_TO_DIE : float = 20.0
const FLYING_DEADZONE : float = 1.0
const DETECTION_RADIUS : float = 35.0
const ATTACK_DELAY : float = 2.0

@export var type : int = 0
var health : float = 1.0
var is_active := true
var is_idling : bool = false
var target
var target_pos : Vector3
var state : int = 0
var tween_idle : Tween

var is_alive : bool = true

func _ready() -> void:
	if !multiplayer.is_server(): return
	calculate_target_pos()
	await get_tree().process_frame
	var pos : Vector3 = target_pos
	pos.y -= 40.0
	global_position = pos
	
	
func _physics_process(delta: float) -> void:
	if !multiplayer.is_server(): return
	if !is_alive: return
	if state == 0:
		achieve_target_pos() 
	elif state == 1:
		var direction = target_pos - global_position
		direction.y = 0.0
		global_position += direction.normalized() * MOVE_SPEED * delta
		if abs(global_position.x - target_pos.x) < FLYING_DEADZONE and abs(global_position.z - target_pos.z) < FLYING_DEADZONE:
			state = 0
	
		
func calculate_target_pos() -> void:
	target = Globals.ms.get_nearest_player(global_position)
	var pos = Globals.world.get_near_flying_position() if !is_idling else Globals.world.get_next_near_flying_position()
	target_pos = pos
	
func check_for_position_change() -> void:
	if !is_alive: return
	var distance_squared = global_position.distance_squared_to(Globals.world.get_zone_next_marker())
	if distance_squared < DETECTION_RADIUS * DETECTION_RADIUS:
		attack()
		await get_tree().create_timer(ATTACK_DELAY).timeout
		check_for_position_change()
	else:
		calculate_target_pos()
		state = 1

func attack() -> void:
	var direction : Vector3 = (target.global_position - global_position).normalized()
	var p
	if type == 0: p = PROJECTILE_S.instantiate()
	Globals.projectile_spawner.add_child(p, true)
	p.global_position = global_position
	p.direction = direction
	
func achieve_target_pos() -> void:
	state = 2
	if !is_idling:
		var t = get_tree().create_tween()
		t.tween_property(self, "global_position:y", target_pos.y, abs(target_pos.y - global_position.y) / MOVE_SPEED).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		await t.finished
		check_for_position_change()
		is_idling = true
		idle_moving()
	else:
		check_for_position_change()
	
func idle_moving() -> void:
	if !is_alive: return
	tween_idle = get_tree().create_tween()
	tween_idle.tween_property(self, "global_position:y", target_pos.y + 1.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween_idle.tween_property(self, "global_position:y", target_pos.y, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween_idle.finished
	idle_moving()
	
func damage(peer_id:int, damage:float) -> void:
	if multiplayer.is_server():
		Globals.processor.damage_soot(self, peer_id, damage)
	
func death() -> void:
	is_alive = false
	if tween_idle != null: tween_idle.kill()
	$Mesh.material_override = GOLD_MATERIAL
