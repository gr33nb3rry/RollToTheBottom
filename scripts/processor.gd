extends Node

const PROJECTILE = preload("res://scenes/projectile.tscn")

var max_health : Array = [20, 20]
var health : Array = [max_health[0], max_health[1]]

# NAME: [P1, P2, Step, Max]
var skills = {
	"Fireproof Spirit": [0, 0],
	"Serpent's Bane": [0, 0],
	"Frozen Resolve": [0, 0],
	"Shinigami’s Sight": [0, 0],
	"Mountain’s Strength": [0, 0],
	"Way of the Blade": [0, 0],
	"Tengu’s Leap": [0, 0, 1, 1],
	"Iron Will": [0, 0],
	"Fortune Beckons": [0, 0],
	"Blood Pact": [0, 0],
	"Killer Instinct": [0, 0],
}

func _ready() -> void:
	await get_tree().process_frame
	Globals.health.update(max_health, health)

@rpc("any_peer")
func get_skill(peer_id:int, skill_name:String) -> int:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return 0
	return skills[skill_name][index]
@rpc("any_peer")
func add_skill(peer_id:int, skill_name:String) -> void:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return
	if skills[skill_name][index] + skills[skill_name][2] <= skills[skill_name][3]: 
		skills[skill_name][index] += skills[skill_name][2]
@rpc("any_peer")
func reset_skill(peer_id:int, skill_name:String) -> void:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return
	skills[skill_name][index] = 0
@rpc("any_peer")
func sync_skills(received_skills:Dictionary) -> void:
	print("Received skills: ", received_skills)
	skills = received_skills

@rpc("any_peer")
func change_health(peer_id:int, v:int) -> void:
	print("Damage in processor")
	print("peer id: ", peer_id, " MS: ", Globals.ms.get_second_player_peer_id())
	var index : int = 0 if peer_id == 1 else 1
	health[index] = clamp(health[index] + v, 0, max_health[index])
	if health[index] == 0:
		Globals.ms.get_player_by_id(peer_id).death()
		Globals.ms.get_player_by_id(peer_id).death.rpc_id(Globals.ms.get_second_player_peer_id())
	Globals.health.update(max_health, health)
	Globals.health.update.rpc_id(Globals.ms.get_second_player_peer_id(), max_health, health)
	

@rpc("any_peer")
func apply_impulse_to_ball(requesting_peer_id: int) -> void:
	var player = Globals.ms.get_player_by_id(requesting_peer_id)
	Globals.ball.add_impulse(player, player.PUSH_FORCE)

@rpc("any_peer")
func shoot(requesting_peer_id: int) -> void:
	var player = Globals.ms.get_player_by_id(requesting_peer_id)
	var direction : Vector3
	var pos : Vector3 = player.global_position + Vector3(0, 1.7, 0)
	if player.ray_crosshair.is_colliding():
		direction = (player.ray_crosshair.get_collision_point() - pos).normalized()
	else:
		direction = (-player.camera.global_transform.basis.z).normalized()
	var p = PROJECTILE.instantiate()
	Globals.projectile_spawner.add_child(p, true)
	p.global_position = pos
	p.direction = direction

func _input(event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_N):
		sync_skills.rpc_id(Globals.ms.get_second_player_peer_id(), skills)
