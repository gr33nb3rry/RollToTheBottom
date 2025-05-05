extends CharacterBody3D

@onready var model : Node3D = $Model
@onready var camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_hit: RayCast3D = $Model/Body/RayHit
@onready var ray_push: RayCast3D = $Model/Body/RayPush
@onready var ray_ground: RayCast3D = $RayGround
@onready var ray_crosshair: RayCast3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/RayCrosshair
@onready var animation_tree: AnimationTree = $Model/AnimationTree
@onready var sucked_soot_pos: Marker3D = $Model/Body/ArmR/Hand/Melee/SuckedSoot
@onready var hit_melee_pos: Marker3D = $Model/Body/ArmR/Hand/Melee/HitMelee
@onready var hit_knife_pos: Marker3D = $Model/Body/ArmR/Hand/Knife/HitKnife

@export var vel : Vector3 = Vector3.ZERO:
	set(v):
		velocity = v
		vel = v

var type : int = 0:
	set(v):
		type = v
		model.get_node("Body/Body0").visible = type == 0
		model.get_node("Body/Body1").visible = type == 1
var gravity_force = Vector3(0,-1,0)
var gravity_acceleration : float = 0.0
@export var is_rolling : bool = false
@export var is_attacking : bool = false
var is_jumping : bool = false
var jump_count : int = 0
var attack_count : int = 0

const GRAVITY : float = 9.8
const GRAVITY_ACCELERATION : float = 1.0

var is_active : bool = false
@export var is_running : bool = false

@export var jump_buffer := 0.0
const ROTATION_SPEED := 10.0
const WALK_SPEED := 10.0
const RUN_SPEED := 20.0
const JUMP_VELOCITY := 25.0
const HIT_FORCE := 14.0

var sucked_soot : Node3D = null

func _ready() -> void:
	if is_multiplayer_authority():
		camera.current = true
	ray_push.add_exception(self)
	ray_hit.add_exception(self)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	apply_impulse()
	apply_gravity(delta)
	rotate_to_gravity(delta)
	#if !is_active: return
	
	var movement = move(delta)
		
	if !ray_ground.is_colliding() and vel.y < 0:
		#animation_tree["parameters/Movement/conditions/fall"] = true
		pass
	elif ray_ground.is_colliding() and vel.y <= 0: 
		is_jumping = false
		jump_count = 0
		gravity_acceleration = 0.0
		is_running = movement != Vector3.ZERO
		#animation_tree["parameters/Movement/conditions/" + ("walk" if movement != Vector3.ZERO else "idle")] = true
		if !is_rolling:
			animation_tree["parameters/Movement/walk/TimeScale/scale"] = 4.4 if Input.is_action_pressed("run") else 2.2
		else:
			animation_tree["parameters/Movement/walk/TimeScale/scale"] = 1.5
	
	move_and_slide()
	if ray_push.is_colliding() and ray_push.get_collider().name == "Ball" and !is_rolling:
		is_rolling = true
		blend_on("HandsBlend", 0.1)
	elif !ray_push.is_colliding() and is_rolling:
		is_rolling = false
		blend_off("HandsBlend", 0.1)
		
func _process(delta: float) -> void:
	if type == 0 and Input.is_action_pressed("aim") and sucked_soot == null:
		suck_soot()
	if sucked_soot != null:
		if multiplayer.get_unique_id() != 1: Globals.processor.change_soot_position.rpc_id(1, sucked_soot, sucked_soot.global_position.lerp(sucked_soot_pos.global_position, 10.0 * delta))
		else: Globals.processor.change_soot_position(sucked_soot, sucked_soot.global_position.lerp(sucked_soot_pos.global_position, 10.0 * delta))

@rpc("any_peer")
func blend_on(blend_name:String, time:float) -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/"+blend_name+"/blend_amount", 1.0, time)
	if multiplayer.get_unique_id() == 1: blend_on.rpc_id(Globals.ms.get_second_player_peer_id(), blend_name, time)
	else: blend_on.rpc_id(1, blend_name, time)
@rpc("any_peer")
func blend_off(blend_name:String, time:float) -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/"+blend_name+"/blend_amount", 0.0, time)
	if multiplayer.get_unique_id() == 1: blend_off.rpc_id(Globals.ms.get_second_player_peer_id(), blend_name, time)
	else: blend_off.rpc_id(1, blend_name, time)

func apply_gravity(delta:float) -> void:
	gravity_acceleration += GRAVITY_ACCELERATION * delta
	jump_buffer = clamp((jump_buffer - delta * 10.0), 0.0, 50.0)
	vel = gravity_force * (GRAVITY + GRAVITY * gravity_acceleration) + global_transform.basis.y * jump_buffer

func rotate_to_gravity(delta:float) -> void :
	var up_dir = -gravity_force.normalized()
	var orientation_direction = Quaternion(global_transform.basis.y, up_dir) * global_transform.basis.get_rotation_quaternion()
	var rot = global_transform.basis.get_rotation_quaternion().slerp(orientation_direction.normalized(), 5.0 * delta)
	global_rotation = rot.get_euler()
	
func rotate_model_to_direction(delta:float, direction:Vector2) -> void:
	$Look/Point.position = Vector3(direction.x, 0, -direction.y)
	var model_transform = model.transform.interpolate_with(model.transform.looking_at($Look/Point.position), ROTATION_SPEED * delta)
	model.transform = model_transform
func rotate_model_to_camera(delta:float) -> void:
	$Model/Body.rotation.y = lerp_angle($Model/Body.rotation.y, $CamRoot/CamYaw.rotation.y, ROTATION_SPEED * delta)
	
func move(delta:float) -> Vector3:
	if !is_active: return Vector3.ZERO
	var movement := Vector3.ZERO
	var forward : Vector3 = -$CamRoot/CamYaw.global_transform.basis.z
	var right : Vector3 = $CamRoot/CamYaw.global_transform.basis.x
	#var up : Vector3 = global_transform.basis.y
	var direction = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	forward *= direction.y
	right *= direction.x
	movement += forward + right
	if movement != Vector3.ZERO:
		rotate_model_to_direction(delta, direction if !Input.is_action_pressed("aim") else Vector2(0,1))
		rotate_model_to_camera(delta)
		vel += movement.normalized() * (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
	elif Input.is_action_pressed("aim"):
		rotate_model_to_camera(delta)
	return movement

func stop() -> void:
	vel = Vector3.ZERO
	#animation_tree["parameters/Movement/conditions/idle"] = true
	
func jump() -> void:
	var max_jump_count = Globals.processor.get_skill(multiplayer.get_unique_id(), "Tengu’s Leap")
	if jump_count <= max_jump_count:
		jump_count += 1
		jump_buffer = JUMP_VELOCITY
		is_jumping = true
		gravity_acceleration = 0.0
		#animation_tree["parameters/Movement/conditions/jump"] = true
	
func damage(amount:int) -> void:
	print("Damage in player")
	if multiplayer.get_unique_id() != 1:
		Globals.processor.change_health.rpc_id(1, multiplayer.get_unique_id(), -amount)
	else:
		Globals.processor.change_health(multiplayer.get_unique_id(), -amount)

@rpc("any_peer")
func death() -> void:
	model.visible = false
	await get_tree().create_timer(5.0).timeout
	resurrect()

func resurrect() -> void:
	model.visible = true

func apply_impulse() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Ball":
			if multiplayer.get_unique_id() != 1:
				Globals.processor.rpc_id(1, "push_ball", multiplayer.get_unique_id(), is_attacking)
			else:
				Globals.processor.push_ball(1, is_attacking)
			break
			
@rpc("any_peer")
func hit() -> void:
	animation_tree.set("parameters/hit_melee/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if multiplayer.get_unique_id() == 1: hit.rpc_id(Globals.ms.get_second_player_peer_id())
	else: hit.rpc_id(1)
func hit_check() -> void:
	if !multiplayer.is_server(): return
	var ball_r : float = Globals.ball.radius
	if hit_melee_pos.global_position.distance_squared_to(Globals.ball.global_position) < ball_r * ball_r + 1.0:
		Globals.processor.hit_ball(1)
		#if multiplayer.get_unique_id() != 1:
		#	Globals.processor.rpc_id(1, "hit_ball", multiplayer.get_unique_id())
		#else:
		#	Globals.processor.hit_ball(1)
		print("Hit melee: Ball")
	for soot in get_tree().get_nodes_in_group("Soot"):
		print(hit_melee_pos.global_position.distance_to(soot.global_position), " < ", soot.RADIUS * soot.RADIUS + 1.0)
		if hit_melee_pos.global_position.distance_to(soot.global_position) < soot.RADIUS + 1.0:
			Globals.processor.damage_soot(soot, multiplayer.get_unique_id(), 1.0)
			#if multiplayer.get_unique_id() != 1: Globals.processor.damage_soot.rpc_id(1, soot, multiplayer.get_unique_id(), 1.0)
			#else: Globals.processor.damage_soot(soot, multiplayer.get_unique_id(), 1.0)
			print("Hit melee: ", soot)

func suck_soot() -> void:
	if ray_crosshair.is_colliding() and sucked_soot == null:
		var collider = ray_crosshair.get_collider()
		if collider.is_in_group("Soot") and !collider.is_alive:
			sucked_soot = collider
func blow_soot() -> void:
	if sucked_soot != null:
		#if multiplayer.get_unique_id() != 1: Globals.processor.blow_soot.rpc_id(1, sucked_soot, global_position + (-camera.global_transform.basis.z).normalized())
		#else: Globals.processor.blow_soot(sucked_soot, global_position + (-camera.global_transform.basis.z).normalized())
		var t = get_tree().create_tween()
		t.tween_property(sucked_soot, "global_position", global_position + (-camera.global_transform.basis.z).normalized() * 30.0, 3.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		sucked_soot = null
@rpc("any_peer")
func blow_soot_animation() -> void:
	animation_tree.set("parameters/blow/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if multiplayer.get_unique_id() == 1: blow_soot_animation.rpc_id(Globals.ms.get_second_player_peer_id())
	else: blow_soot_animation.rpc_id(1)
	
func attack() -> void:
	var anim : String = "hit_" + str(attack_count)
	animation_tree.tree_root.get_node("hit_knife").animation = anim
	animation_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	attack_count += 1
	if attack_count > 5: attack_count = 0
	
	for s in $Model/Body/AreaKnife.get_overlapping_bodies():
		if s.is_in_group("Soot"):
			if multiplayer.get_unique_id() != 1: Globals.processor.damage_soot.rpc_id(1, s, multiplayer.get_unique_id(), 1.0)
			else: Globals.processor.damage_soot(s, multiplayer.get_unique_id(), 1.0)
			print("Attack: ", s)
	
	if multiplayer.get_unique_id() != 1: 
		attack_animation.rpc_id(1, anim)
		Globals.processor.attack.rpc_id(1)
	else: 
		attack_animation.rpc_id(Globals.ms.get_second_player_peer_id(), anim)
		Globals.processor.attack()
func end_attack() -> void:
	attack_count = 0

@rpc("any_peer")
func attack_animation(anim:String) -> void:
	animation_tree.tree_root.get_node("hit_knife").animation = anim
	animation_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func aim(is_aim:bool) -> void:
	$/root/Main/Canvas/Crosshair.visible = is_aim

func flying_camera() -> void:
	stop()
	is_active = !is_active
	$CamRoot.top_level = !is_active
	aim(!is_active)
	$CamRoot.status = 0 if is_active else 1
	if $CamRoot.status == 0:
		$CamRoot.position = Vector3(0, 1, 0)
	var t = get_tree().create_tween()
	t.tween_property($CamRoot/CamYaw/CamPitch/SpringArm3D, "spring_length", 7 if $CamRoot.status == 0 else 0, 0.1)

func _input(_event) -> void:
	if !is_multiplayer_authority(): return
	if Input.is_action_just_pressed("switch_camera"):
		flying_camera()
	if !is_active: return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("jump"): 
		jump()
	elif Input.is_action_just_pressed("aim"):
		aim(true)
		if type == 0: blend_on("SuckBlend", 0.2)
	elif Input.is_action_just_released("aim"):
		aim(false)
		if type == 0: 
			blend_off("SuckBlend", 0.2)
			blow_soot_animation()
			
	elif !Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		hit() if type == 0 else attack()
