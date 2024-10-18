extends CharacterBody3D

@onready var model : Node3D = $Model
@onready var animation_tree : AnimationTree = $Model/Sophia/AnimationTree
@onready var animation_player: AnimationPlayer = $Model/Sophia/AnimationPlayer
@onready var camera: Camera3D = $CamRoot/CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_hit: RayCast3D = $Model/Sophia/RayHit
@onready var ray_push: RayCast3D = $Model/Sophia/RayPush

var gravity_force = Vector3(0,-1,0)
var is_changed_gravity_to_steb := false
var is_rolling := false

var jump_buffer := 0.0
const ROTATION_SPEED := 10.0
const JUMP_VELOCITY := 20.0
const PUSH_FORCE := 2.0
const HIT_FORCE := 100.0

func _ready() -> void:
	camera.current = is_multiplayer_authority()

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	#var d = global_position - planet.global_position
	#var gravity_force = (-d.normalized()).normalized()
	if is_changed_gravity_to_steb:
		var d = global_position - Vector3.ZERO
		d.y = 0
		gravity_force = (-d.normalized()).normalized()
	
	jump_buffer = clamp((jump_buffer - delta * 10.0), 0.0, 50.0)
	velocity = gravity_force * 10.0 + global_transform.basis.y * jump_buffer
	
	if jump_buffer <= 10.0:
		animation_tree["parameters/conditions/fall"] = true
	
	var up_direction = -gravity_force.normalized()
	var orientation_direction = Quaternion(global_transform.basis.y, up_direction) * global_transform.basis.get_rotation_quaternion()
	var rotation = global_transform.basis.get_rotation_quaternion().slerp(orientation_direction.normalized(), 5.0 * delta)
	global_rotation = rotation.get_euler()
	
	var movement := Vector3.ZERO
	var forward : Vector3 = -$CamRoot/CamYaw.global_transform.basis.z
	var right : Vector3 = $CamRoot/CamYaw.global_transform.basis.x
	var up : Vector3 = global_transform.basis.y
	var direction = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	forward *= direction.y
	right *= direction.x
	movement += forward + right
	if movement != Vector3.ZERO:
		if jump_buffer == 0.0: animation_tree["parameters/conditions/run"] = true
		$Look/Point.position = Vector3(direction.x, 0, -direction.y)
		$Model/Sophia.rotation.y = lerp_angle($Model/Sophia.rotation.y, $CamRoot/CamYaw.rotation.y + deg_to_rad(180), ROTATION_SPEED * delta)
		var model_transform = model.transform.interpolate_with(model.transform.looking_at($Look/Point.position), ROTATION_SPEED * delta)
		model.transform = model_transform

		velocity += movement.normalized() * 5.0
	elif jump_buffer == 0.0: animation_tree["parameters/conditions/idle"] = true
	
	move_and_slide()
	if ray_push.is_colliding() and ray_push.get_collider().name == "Ball" and !is_rolling:
		is_rolling = true
	elif !ray_push.is_colliding() and is_rolling:
		is_rolling = false
	apply_impulse()
	
func apply_impulse() -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider() is RigidBody3D:
			collision.get_collider().apply_central_impulse(-collision.get_normal() * PUSH_FORCE)
			
func hit() -> void:
	if ray_hit.is_colliding() and ray_hit.get_collider().name == "Ball":
		ray_hit.get_collider().apply_central_impulse(-$CamRoot/CamYaw.global_transform.basis.z * HIT_FORCE)

func change_gravity() -> void:
	is_changed_gravity_to_steb = !is_changed_gravity_to_steb
	if !is_changed_gravity_to_steb: gravity_force = Vector3(0,-1,0)

func _input(event) -> void:
	if !is_multiplayer_authority(): return
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	elif Input.is_action_just_pressed("hit"):
		hit()
	elif Input.is_action_just_pressed("change_gravity"):
		change_gravity()
	elif Input.is_action_just_pressed("jump") and jump_buffer == 0.0 and animation_tree["parameters/playback"].get_fading_from_node() == "": 
		jump_buffer = JUMP_VELOCITY
		animation_tree["parameters/conditions/jump"] = true
