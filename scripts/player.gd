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
var is_alive : bool = true
@export var is_running : bool = false

@export var jump_buffer : float = 0.0
const ROTATION_SPEED : float = 10.0
const WALK_SPEED : float = 10.0
const RUN_SPEED : float = 20.0
const JUMP_VELOCITY : float = 25.0
const HIT_FORCE : float = 14.0
const RADIUS : float = 0.5

func _ready() -> void:
	if is_multiplayer_authority():
		camera.current = true
	ray_push.add_exception(self)
	ray_hit.add_exception(self)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	apply_impulse()
	apply_gravity(delta)
	#if !is_active: return
	if is_alive and global_position.y < Globals.world.dead_line: death()
	if !is_alive: return
	var movement = move(delta)
		
	if !is_on_floor() and vel.y < 0:
		#animation_tree["parameters/Movement/conditions/fall"] = true
		pass
	elif is_on_floor() and vel.y <= 0: 
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
	if !is_rolling and is_ball_near_enough(0.3):
		is_rolling = true
		blend_on("HandsBlend", 0.1)
	elif is_rolling and !is_ball_near_enough(0.3):
		is_rolling = false
		blend_off("HandsBlend", 0.1)
		
func blend_on(blend_name:String, time:float) -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/"+blend_name+"/blend_amount", 1.0, time)

func blend_off(blend_name:String, time:float) -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/"+blend_name+"/blend_amount", 0.0, time)

func apply_gravity(delta:float) -> void:
	gravity_acceleration += GRAVITY_ACCELERATION * delta
	jump_buffer = clamp((jump_buffer - delta * 10.0), 0.0, 50.0)
	vel = gravity_force * (GRAVITY + GRAVITY * gravity_acceleration) + global_transform.basis.y * jump_buffer

	
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

func death() -> void:
	is_alive = false
	model.visible = false
	await get_tree().create_timer(1.0).timeout
	resurrect()

func resurrect() -> void:
	model.visible = true
	if multiplayer.get_unique_id() == 1: Globals.processor.resurrect(1)
	else: Globals.processor.resurrect.rpc_id(1, multiplayer.get_unique_id())

@rpc("any_peer")
func tp_resurrect(pos:Vector3) -> void:
	global_position = pos
	is_alive = true

func apply_impulse() -> void:
	if Globals.processor.health[0 if multiplayer.get_unique_id() == 1 else 1] < 0.16: return
	if is_ball_near_enough(0.25):
		if multiplayer.get_unique_id() != 1:
			Globals.processor.push_ball.rpc_id(1, multiplayer.get_unique_id(), is_attacking)
		else:
			Globals.processor.push_ball(1, is_attacking)
			
func is_ball_near_enough(distance:float) -> bool:
	var distance_squared = global_position.distance_squared_to(Globals.ball.global_position)
	var min_distance : float = Globals.ball.radius + RADIUS + distance
	return distance_squared < min_distance * min_distance
			
@rpc("any_peer")
func hit() -> void:
	if Globals.processor.health[0 if multiplayer.get_unique_id() == 1 else 1] < 10.0: return
	animation_tree.set("parameters/hit_melee/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	if multiplayer.get_unique_id() == 1: hit.rpc_id(Globals.ms.get_second_player_peer_id())
	else: hit.rpc_id(1)
func hit_check() -> void:
	if !is_multiplayer_authority(): return
	for i in $Model/Body/AreaMelee.get_overlapping_bodies():
		if i == Globals.ball:
			#Globals.processor.hit_ball()
			if multiplayer.get_unique_id() != 1:
				Globals.processor.hit_ball.rpc_id()
			else:
				Globals.processor.hit_ball()
			print("Hit melee: Ball")
		elif i.is_in_group("Attackable"):
			i.damage(0)


	
func attack() -> void:
	if Globals.processor.health[0 if multiplayer.get_unique_id() == 1 else 1] < 10.0: return
	var anim : String = "hit_" + str(attack_count)
	animation_tree.tree_root.get_node("hit_knife").animation = anim
	animation_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	attack_count += 1
	if attack_count > 5: attack_count = 0
	
	if is_ball_near_enough(1.8) and ray_crosshair.is_colliding() and ray_crosshair.get_collider() == Globals.ball:
		if multiplayer.get_unique_id() == 1: Globals.processor.toss_ball()
		else: Globals.processor.toss_ball.rpc_id(1)
	elif ray_crosshair.is_colliding() and ray_crosshair.get_collider().is_in_group("Attackable"):
		ray_crosshair.get_collider().damage(1)
	
	Globals.health.hit_ball()
	if multiplayer.get_unique_id() != 1: 
		attack_animation.rpc_id(1, anim)
		Globals.health.hit_ball.rpc_id(1)
	else: 
		attack_animation.rpc_id(Globals.ms.get_second_player_peer_id(), anim)
		Globals.health.hit_ball.rpc_id(Globals.ms.get_second_player_peer_id())
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
		Globals.main.leave_lobby()
	elif Input.is_action_just_pressed("jump") and is_on_floor(): 
		jump()
	elif Input.is_action_just_pressed("aim"):
		aim(true)
	elif Input.is_action_just_released("aim"):
		aim(false)
	elif type == 0 and !Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		hit()
	elif type == 1 and Input.is_action_just_pressed("hit"):
		attack()
