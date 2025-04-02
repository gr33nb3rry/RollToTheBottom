extends CharacterBody3D

@onready var model : Node3D = $Model
@onready var camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_hit: RayCast3D = $Model/Body/RayHit
@onready var ray_push: RayCast3D = $Model/Body/RayPush
@onready var ray_ground: RayCast3D = $RayGround
@onready var ray_crosshair: RayCast3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/RayCrosshair
@onready var animation_tree: AnimationTree = $Model/AnimationTree
@onready var sucked_soot_pos: Marker3D = $Model/Body/ArmR/Hand/Melee/SuckedSoot

var type : int = 0
var gravity_force = Vector3(0,-1,0)
var gravity_acceleration : float = 0.0
@export var is_rolling : bool = false
@export var is_attacking : bool = false
var is_jumping : bool = false
var jump_count : int = 0
var attack_count : int = 0

const GRAVITY : float = 9.8
const GRAVITY_ACCELERATION : float = 1.0

var is_active : bool = true

var jump_buffer := 0.0
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
	
	var movement = move(delta)
		
	if !ray_ground.is_colliding() and velocity.y < 0:
		animation_tree["parameters/Movement/conditions/fall"] = true
	elif ray_ground.is_colliding() and velocity.y <= 0: 
		is_jumping = false
		jump_count = 0
		gravity_acceleration = 0.0
		animation_tree["parameters/Movement/conditions/" + ("walk" if movement != Vector3.ZERO else "idle")] = true
		if !is_rolling:
			animation_tree["parameters/Movement/walk/TimeScale/scale"] = 4.4 if Input.is_action_pressed("run") else 2.2
		else:
			animation_tree["parameters/Movement/walk/TimeScale/scale"] = 1.5
	
	move_and_slide()
	if ray_push.is_colliding() and ray_push.get_collider().name == "Ball" and !is_rolling:
		is_rolling = true
		hands_blend_on()
	elif !ray_push.is_colliding() and is_rolling:
		is_rolling = false
		hands_blend_off()
		
func _process(delta: float) -> void:
	if type == 0 and Input.is_action_pressed("aim") and sucked_soot == null:
		suck_soot()
	elif type == 0 and Input.is_action_just_released("aim") and sucked_soot != null:
		blow_soot()
	if sucked_soot != null:
		sucked_soot.global_position = sucked_soot.global_position.lerp(sucked_soot_pos.global_position, 10.0 * delta)

func hands_blend_on() -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/HandsBlend/blend_amount", 1.0, 0.1)
	print("Hands blend ON")
func hands_blend_off() -> void:
	var t = get_tree().create_tween()
	t.tween_property(animation_tree, "parameters/HandsBlend/blend_amount", 0.0, 0.1)
	print("Hands blend OFF")

func apply_gravity(delta:float) -> void:
	gravity_acceleration += GRAVITY_ACCELERATION * delta
	jump_buffer = clamp((jump_buffer - delta * 10.0), 0.0, 50.0)
	velocity = gravity_force * (GRAVITY + GRAVITY * gravity_acceleration) + global_transform.basis.y * jump_buffer

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
		velocity += movement.normalized() * (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
	elif Input.is_action_pressed("aim"):
		rotate_model_to_camera(delta)
	return movement

func stop() -> void:
	velocity = Vector3.ZERO
	animation_tree["parameters/Movement/conditions/idle"] = true
	
func jump() -> void:
	var max_jump_count = Globals.processor.get_skill(multiplayer.get_unique_id(), "Tengu’s Leap")
	if jump_count <= max_jump_count:
		jump_count += 1
		jump_buffer = JUMP_VELOCITY
		is_jumping = true
		gravity_acceleration = 0.0
		animation_tree["parameters/Movement/conditions/jump"] = true
	
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
	if is_attacking: return
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Ball":
			if multiplayer.get_unique_id() != 1:
				Globals.processor.rpc_id(1, "push_ball", multiplayer.get_unique_id())
			else:
				Globals.processor.push_ball(1)
			break

func hit() -> void:
	animation_tree.set("parameters/hit_melee/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
func hit_check() -> void:
	if ray_hit.is_colliding() and ray_hit.get_collider().name == "Ball":
		if multiplayer.get_unique_id() != 1:
			Globals.processor.rpc_id(1, "hit_ball", multiplayer.get_unique_id())
		else:
			Globals.processor.hit_ball(1)

func suck_soot() -> void:
	if ray_crosshair.is_colliding() and sucked_soot == null:
		var collider = ray_crosshair.get_collider()
		if collider.is_in_group("Soot"):
			sucked_soot = collider

func blow_soot() -> void:
	var t = get_tree().create_tween()
	t.tween_property(sucked_soot, "global_position", global_position + (-camera.global_transform.basis.z).normalized() * 30.0, 3.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
	sucked_soot = null

func attack() -> void:
	animation_tree.tree_root.get_node("hit_knife").animation = "hit_" + str(attack_count)
	animation_tree.set("parameters/hit/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	attack_count += 1
	if attack_count > 5: attack_count = 0
func end_attack() -> void:
	attack_count = 0

func aim(is_aim:bool) -> void:
	$/root/Main/Canvas/Crosshair.visible = is_aim

func shoot() -> void:
	if multiplayer.get_unique_id() != 1:
		Globals.processor.rpc_id(1, "shoot", multiplayer.get_unique_id(), !ray_ground.is_colliding())
	else:
		Globals.processor.shoot(1, !ray_ground.is_colliding())

func _input(_event) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("jump"): 
		jump()
	elif Input.is_action_just_pressed("aim"):
		aim(true)
	elif Input.is_action_just_released("aim"):
		aim(false)
	elif !Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		hit() if type == 0 else attack()
	elif Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		shoot()
	if Input.is_key_pressed(KEY_M):
		damage(1)
