extends CharacterBody3D

@onready var model : Node3D = $Model
@onready var animation_tree : AnimationTree = $Model/Sophia/AnimationTree
@onready var animation_player: AnimationPlayer = $Model/Sophia/AnimationPlayer
@onready var camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_hit: RayCast3D = $Model/Sophia/RayHit
@onready var ray_push: RayCast3D = $Model/Sophia/RayPush
@onready var ray_ground: RayCast3D = $RayGround
@onready var ray_back: RayCast3D = $Model/Sophia/RayBack

@onready var ms = $/root/Main/World/MultiplayerSpawner
@onready var path = $/root/Main/World/Steb/Path3D/PathFollow3D
@onready var path_camera = $/root/Main/World/Steb/Path3D/PathFollow3D/Camera3D
@onready var ball = $/root/Main/World/Ball

var gravity_force = Vector3(0,-1,0)
var gravity_acceleration := 0.0
var is_changed_gravity_to_steb := false
var is_rolling := false
var is_jumping := false

const GRAVITY := 9.8
const GRAVITY_ACCELERATION := 1.0

var is_active := true

var jump_buffer := 0.0
const ROTATION_SPEED := 10.0
const WALK_SPEED := 10.0
const RUN_SPEED := 20.0
const JUMP_VELOCITY := 20.0
const PUSH_FORCE := 5.0
const HIT_FORCE := 100.0

func _ready() -> void:
	camera.current = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority() or !is_active: return
	apply_impulse()
	
	apply_gravity(delta)
	
	if is_changed_gravity_to_steb and ray_back.is_colliding() and ray_back.get_collider().name == "Steb" and !is_jumping:
		change_gravity()
	if is_jumping and jump_buffer <= 10.0 or (!ray_ground.is_colliding() and !is_jumping):
		animation_tree["parameters/conditions/fall"] = true
	
	var up_direction = -gravity_force.normalized()
	var orientation_direction = Quaternion(global_transform.basis.y, up_direction) * global_transform.basis.get_rotation_quaternion()
	var rot = global_transform.basis.get_rotation_quaternion().slerp(orientation_direction.normalized(), 5.0 * delta)
	global_rotation = rot.get_euler()
	
	var movement := Vector3.ZERO
	var forward : Vector3 = -$CamRoot/CamYaw.global_transform.basis.z
	var right : Vector3 = $CamRoot/CamYaw.global_transform.basis.x
	var up : Vector3 = global_transform.basis.y
	var direction = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	forward *= direction.y
	right *= direction.x
	movement += forward + right
	if movement != Vector3.ZERO:
		#if jump_buffer <= 0.01: animation_tree["parameters/conditions/run"] = true
		if ray_ground.is_colliding() and jump_buffer <= 0.01: 
			is_jumping = false
			gravity_acceleration = 0.0
			animation_tree["parameters/conditions/run"] = true
		$Look/Point.position = Vector3(direction.x, 0, -direction.y)
		$Model/Sophia.rotation.y = lerp_angle($Model/Sophia.rotation.y, $CamRoot/CamYaw.rotation.y + deg_to_rad(180), ROTATION_SPEED * delta)
		var model_transform = model.transform.interpolate_with(model.transform.looking_at($Look/Point.position), ROTATION_SPEED * delta)
		model.transform = model_transform

		velocity += movement.normalized() * (RUN_SPEED if Input.is_action_pressed("run") else WALK_SPEED)
		#var anim_run_speed = sqrt(pow(velocity.x, 2) + pow(velocity.z, 2))
		animation_tree["parameters/Run/TimeScale/scale"] = 1.5 if Input.is_action_pressed("run") else 1
	#elif jump_buffer <= 0.01: animation_tree["parameters/conditions/idle"] = true
	elif ray_ground.is_colliding() and jump_buffer <= 0.01: 
		is_jumping = false
		gravity_acceleration = 0.0
		animation_tree["parameters/conditions/idle"] = true
	
	move_and_slide()
	if ray_push.is_colliding() and ray_push.get_collider().name == "Ball" and !is_rolling:
		is_rolling = true
	elif !ray_push.is_colliding() and is_rolling:
		is_rolling = false

func apply_gravity(delta:float) -> void:
	#var d = global_position - planet.global_position
	#var gravity_force = (-d.normalized()).normalized()
	#if is_changed_gravity_to_steb:
	#	var d = global_position - Vector3.ZERO
		#var d = global_position - ray_ground.get_collision_point()
	#	d.y = 0
		#var d = ray_gravity.get_collision_normal()
	#	gravity_force = (-d.normalized()).normalized()
	#var d = ray_gravity.get_collision_normal()
	#gravity_force = (-d.normalized()).normalized()
	gravity_acceleration += GRAVITY_ACCELERATION * delta
	jump_buffer = clamp((jump_buffer - delta * 10.0), 0.0, 50.0)
	velocity = gravity_force * (GRAVITY + GRAVITY * gravity_acceleration) + global_transform.basis.y * jump_buffer
	
func apply_impulse() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().name == "Ball":
			if get_multiplayer().get_unique_id() != 1:
				rpc_id(1, "apply_impulse_to_ball", get_multiplayer().get_unique_id())
			else:
				collision.get_collider().apply_central_impulse(-collision.get_normal() * PUSH_FORCE)
			break
@rpc("any_peer")
func apply_impulse_to_ball(requesting_peer_id: int) -> void:
	var player = ms.get_player_by_id(requesting_peer_id)
	ball.apply_central_impulse(-player.get_node("CamRoot/CamYaw").global_transform.basis.z * PUSH_FORCE)
		
func hit() -> void:
	if ray_hit.is_colliding() and ray_hit.get_collider().name == "Ball":
		ray_hit.get_collider().apply_central_impulse(-$CamRoot/CamYaw.global_transform.basis.z * HIT_FORCE)
@rpc("any_peer")
func hit_request(requesting_peer_id: int) -> void:
	var player = ms.get_player_by_id(requesting_peer_id)
	if player.ray_hit.is_colliding() and player.ray_hit.get_collider().name == "Ball":
		player.ray_hit.get_collider().apply_central_impulse(-player.get_node("CamRoot/CamYaw").global_transform.basis.z * HIT_FORCE)

func change_gravity() -> void:
	is_changed_gravity_to_steb = !is_changed_gravity_to_steb
	if is_changed_gravity_to_steb:
		reparent(ms)
	else:
		is_active = false
		#reparent(path)
		#position = Vector3.ZERO
		camera.current = false
		path_camera.current = true
		var t = get_tree().create_tween()
		t.tween_property(path, "progress_ratio", 1.0, 10.0)

func _input(event) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("hit"):
		if is_multiplayer_authority():
			hit()
		elif get_multiplayer().get_unique_id() != 1:
			rpc_id(1, "hit_request", get_multiplayer().get_unique_id())
	elif Input.is_action_just_pressed("change_gravity"):
		change_gravity()
	#elif Input.is_action_just_pressed("jump") and ray_ground.is_colliding() and !is_changed_gravity_to_steb and animation_tree["parameters/playback"].get_fading_from_node() == "": 
	elif Input.is_action_just_pressed("jump") and !is_changed_gravity_to_steb and animation_tree["parameters/playback"].get_fading_from_node() == "": 
		jump_buffer = JUMP_VELOCITY
		is_jumping = true
		animation_tree["parameters/conditions/jump"] = true
	
