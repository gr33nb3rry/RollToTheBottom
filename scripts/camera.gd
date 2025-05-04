extends CharacterBody3D

@export var player : CharacterBody3D
@onready var yaw_node = $CamYaw
@onready var pitch_node = $CamYaw/CamPitch
@onready var spring_arm = $CamYaw/CamPitch/SpringArm3D
@onready var camera = $CamYaw/CamPitch/SpringArm3D/Camera3D
@onready var ray_crosshair: RayCast3D = $CamYaw/CamPitch/SpringArm3D/RayCrosshair

var yaw : float = 0
var pitch : float = 0
var yaw_sensitivity : float = 0.07
var pitch_sensitivity : float = 0.07
var yaw_acceleration : float = 30
var pitch_acceleration : float = 15
var pitch_max : float = 75
var pitch_min : float = -90
var position_offset : Vector3 = Vector3(0, 1, 0)
var position_offset_target : Vector3 = Vector3(0, 1, 0)

var status : int = 0
var is_aiming := false

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	spring_arm.add_excluded_object(player.get_rid())
	$CamYaw/CamPitch/SpringArm3D/RayCrosshair.add_exception(player)
	#top_level = true

func _input(event):
	if status == 0 and !player.is_active: return
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += -event.relative.y * pitch_sensitivity
	if status == 1 and !Input.is_action_pressed("aim") and Input.is_action_just_pressed("hit"):
		select_decal()
	if Input.is_key_pressed(KEY_BRACKETRIGHT):
		var decals : Array = Globals.world.get_node("Decals").get_children()
		for decal in decals:
			if !decal.is_selected and Globals.world.activity_type == 0 and Globals.world.activity_value == str(decal.type):
				decal.select()
				if multiplayer.get_unique_id() == 1:
					decal.select.rpc_id(Globals.ms.get_second_player_peer_id())
				else:
					decal.select.rpc_id(1)
		
func _process(_delta: float) -> void:
	if status == 0 and !player.is_active: return
	var view = Input.get_vector("view_left", "view_right", "view_down", "view_up")
	yaw += -view.x * yaw_sensitivity * 5.0
	pitch += view.y * pitch_sensitivity * 5.0

func _physics_process(delta):
	if status == 0 and !player.is_active: return
	pitch = clamp(pitch, pitch_min, pitch_max)
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(pitch_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	
	#if you don't want to lerp, set them directly
	#yaw_node.rotation_degrees.y = yaw
	#pitch_node.rotation_degrees.x = pitch
	
	if status == 1:
		var movement := Vector3.ZERO
		var forward : Vector3 = -$CamYaw/CamPitch.global_transform.basis.z
		var right : Vector3 = $CamYaw.global_transform.basis.x
		var up : Vector3 = $CamYaw/CamPitch.global_transform.basis.y
		var direction = Input.get_vector("move_left", "move_right", "move_back", "move_forward")
		forward *= direction.y
		right *= direction.x
		if Input.is_action_pressed("flying_camera_up"): up *= 1
		elif Input.is_action_pressed("flying_camera_down"): up *= -1
		else: up *= 0
		movement += forward + right + up
		velocity = lerp(velocity, movement.normalized() * (player.RUN_SPEED * 4.0 if Input.is_action_pressed("run") else player.RUN_SPEED * 2.0), 0.15)
		#global_position += movement * delta
		move_and_slide()

func select_decal() -> void:
	var decals : Array = Globals.world.get_node("Decals").get_children()
	var point : Vector3 = ray_crosshair.get_collision_point()
	var nearest_decal_to_point : Decal = null
	var nearest_distance : float = INF
	for decal in decals:
		var distance = point.distance_squared_to(decal.get_node("Ray").get_collision_point())
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_decal_to_point = decal
	print("Selected decal.  Distance: ", nearest_distance, "  Type: ", nearest_decal_to_point.type)
	if !nearest_decal_to_point.is_selected and nearest_distance <= 2.0 and Globals.world.activity_type == 0 and Globals.world.activity_value == str(nearest_decal_to_point.type):
		nearest_decal_to_point.select()
		if multiplayer.get_unique_id() == 1:
			nearest_decal_to_point.select.rpc_id(Globals.ms.get_second_player_peer_id())
		else:
			nearest_decal_to_point.select.rpc_id(1)
			
