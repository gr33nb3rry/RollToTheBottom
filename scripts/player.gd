extends CharacterBody3D

@onready var model : Node3D = $Model
@onready var animation_tree : AnimationTree = $Model/Sophia/AnimationTree
@onready var animation_player: AnimationPlayer = $Model/Sophia/AnimationPlayer
@onready var camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_hit: RayCast3D = $Model/Sophia/RayHit
@onready var ray_push: RayCast3D = $Model/Sophia/RayPush
@onready var ray_ground: RayCast3D = $RayGround
@onready var ray_crosshair: RayCast3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/RayCrosshair

@onready var path = $/root/Main/World/Steb/Path3D/PathFollow3D
#@onready var path_camera = $/root/Main/World/Steb/Path3D/PathFollow3D/Camera3D
@onready var ball = $/root/Main/World/Ball

var gravity_force = Vector3(0,-1,0)
var gravity_acceleration := 0.0
@export var is_rolling := false
var is_jumping := false

const GRAVITY := 9.8
const GRAVITY_ACCELERATION := 1.0

var is_active := true

var jump_buffer := 0.0
const ROTATION_SPEED := 10.0
const WALK_SPEED := 10.0
const RUN_SPEED := 20.0
const JUMP_VELOCITY := 20.0
const PUSH_FORCE := 7.0
const HIT_FORCE := 14.0

func _ready() -> void:
	if is_multiplayer_authority():
		camera.current = true
	ray_push.add_exception(self)
	ray_hit.add_exception(self)

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	if !is_active: return
	apply_impulse()
	apply_gravity(delta)
	rotate_to_gravity(delta)
	
	var movement = move(delta)
		
	if !ray_ground.is_colliding() and velocity.y < 0 and animation_tree["parameters/playback"].get_fading_from_node() == "":
		animation_tree["parameters/conditions/fall"] = true
	elif ray_ground.is_colliding(): 
		is_jumping = false
		gravity_acceleration = 0.0
		animation_tree["parameters/conditions/" + ("run" if movement != Vector3.ZERO else "idle")] = true
		animation_tree["parameters/Run/TimeScale/scale"] = 1.3 if Input.is_action_pressed("run") else 0.8
	
	move_and_slide()
	if ray_push.is_colliding() and ray_push.get_collider().name == "Ball" and !is_rolling:
		is_rolling = true
	elif !ray_push.is_colliding() and is_rolling:
		is_rolling = false

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
	$Model/Sophia.rotation.y = lerp_angle($Model/Sophia.rotation.y, $CamRoot/CamYaw.rotation.y + deg_to_rad(180), ROTATION_SPEED * delta)
	
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
	animation_tree["parameters/conditions/idle"] = true
	
func jump() -> void:
	jump_buffer = JUMP_VELOCITY
	is_jumping = true
	gravity_acceleration = 0.0
	animation_tree["parameters/conditions/jump"] = true
	
func damage(_amount:int) -> void:
	pass
	
	
func apply_impulse() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Ball":
			if multiplayer.get_unique_id() != 1:
				Globals.processor.rpc_id(1, "apply_impulse_to_ball", multiplayer.get_unique_id())
			else:
				Globals.processor.apply_impulse_to_ball(1)
			break

func aim(is_aim:bool) -> void:
	$/root/Main/Canvas/Crosshair.visible = is_aim

func shoot() -> void:
	if multiplayer.get_unique_id() != 1:
		Globals.processor.rpc_id(1, "shoot", multiplayer.get_unique_id())
	else:
		Globals.processor.shoot(1)

func _input(_event) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("jump"): 
		jump()
	elif Input.is_action_just_pressed("aim"):
		aim(true)
	elif Input.is_action_just_released("aim"):
		aim(false)
	elif Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		shoot()
