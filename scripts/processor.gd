extends Node

const PROJECTILE = preload("res://scenes/projectile.tscn")
const COIN = preload("res://scenes/coin.tscn")
const BALL_PUSH_FORCE : float = 7.0
const BALL_HIT_FORCE : float = 20.0

var max_health : Array = [20.0, 20.0]
var health : Array = [max_health[0], max_health[1]]
var coins : float = 0.0

# NAME: [P, FOR, Step, Max]
var skills = {
	"Fireproof Spirit": [0, 'B', 10, 100],
	"Serpent's Bane": [0, 'B', 10, 100],
	"Frozen Resolve": [0, 'B', 10, 100],
	"Shinigami’s Sight": [0, 'B', 15, 150],
	"Mountain’s Strength": [0, 'F', 5, 50],
	"Way of the Blade": [0, 'M', 3, 30],
	"Tengu’s Leap": [0, 'M', 1, 2],
	"Iron Will": [0, 'B', 2, 30],
	"Fortune Beckons": [0, 'E', 5, 100],
	"Blood Pact": [0, 'M', 1, 5],
	"Killer Instinct": [0, 'M', 2, 10],
	"Skyward Strike": [0, 'M', 4, 20],
	"Shadow Flow": [0, 'M', 3, 30],
	"Cursed Blood": [0, 'E', 5, 50]
}

func _ready() -> void:
	await get_tree().process_frame
	#Globals.health.update(max_health, health)

@rpc("any_peer")
func get_skill(peer_id:int, skill_name:String) -> int:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return 0
	return skills[skill_name][0]
@rpc("any_peer")
func add_skill(peer_id:int, skill_name:String) -> void:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return
	if skills[skill_name][0] + skills[skill_name][2] <= skills[skill_name][3]: 
		skills[skill_name][0] += skills[skill_name][2]
		if peer_id != 1:
			sync_skills.rpc_id(Globals.ms.get_second_player_peer_id(), skills)
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
func is_skill_max(peer_id:int, skill_name:String) -> bool:
	var index : int = 0 if peer_id == 1 else 1
	if !skills.has(skill_name):
		print("Skill ", skill_name, " not found")
		return true
	return skills[skill_name][0] >= skills[skill_name][3]

	
@rpc("any_peer")
func change_health(peer_id:int, v:float) -> void:
	print("Damage in processor")
	print("peer id: ", peer_id, " MS: ", Globals.ms.get_second_player_peer_id())
	var index : int = 0 if peer_id == 1 else 1
	if v < 0:
		var percent : float = float(get_skill(peer_id, "Iron Will")) / 100.0
		var damage : float = -v - -v * percent
		health[index] = clamp(health[index] - damage, 0.0, max_health[index])
		if health[index] == 0.0:
			Globals.ms.get_player_by_id(peer_id).death()
			Globals.ms.get_player_by_id(peer_id).death.rpc_id(Globals.ms.get_second_player_peer_id())
	Globals.health.update(max_health, health)
	Globals.health.update.rpc_id(Globals.ms.get_second_player_peer_id(), max_health, health)
	
@rpc("any_peer")
func change_coins(v:float) -> void:
	print("Change coins: ", v)
	if v > 0:
		coins += v + v * float(get_skill(1, "Fortune Beckons")) / 100.0
@rpc("any_peer")
func add_coin(pos:Vector3) -> void:
	var c = COIN.instantiate()
	Globals.projectile_spawner.add_child(c, true)
	c.global_position = pos
	c.move()
	
@rpc("any_peer")
func push_ball(peer_id: int, is_attacking: bool) -> void:
	var player = Globals.ms.get_player_by_id(peer_id)
	var force : float = BALL_PUSH_FORCE + BALL_PUSH_FORCE * float(get_skill(peer_id, "Mountain’s Strength")) / 100.0
	if is_attacking: force /= 2.0
	Globals.ball.add_impulse(player, force, false)
@rpc("any_peer")
func hit_ball() -> void:
	var player = Globals.ms.players.values()[0] if Globals.ms.players.values()[0].type == 0 else Globals.ms.players.values()[1]
	Globals.ball.add_impulse(player, BALL_HIT_FORCE, true)
	
@rpc("any_peer")
func shoot(peer_id: int, is_in_the_air:bool) -> void:
	var player = Globals.ms.get_player_by_id(peer_id)
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
	p.owner_peer_id = peer_id
	var damage : float = 1.0
	p.damage = damage + damage * float(get_skill(peer_id, "Way of the Blade")) / 100.0
	if is_in_the_air: p.damage += damage * float(get_skill(peer_id, "Skyward Strike")) / 100.0

@rpc("any_peer")
func damage_soot(soot:Node3D, peer_id:int, damage:float) -> void:
	print("Damage soot ", soot, " : ", peer_id)
	soot.health -= damage
	if soot.health <= 0.0:
		print("Kill soot ", soot)
		change_health(peer_id, damage * float(get_skill(peer_id, "Blood Pact")) / 100.0)
		print("Heal player on kill: ", damage * float(get_skill(peer_id, "Blood Pact")) / 100.0)
		#add_coin(soot.global_position)
		soot.death()
		soot.death.rpc_id(Globals.ms.get_second_player_peer_id())

@rpc("any_peer")
func change_soot_position(soot:Node3D, pos:Vector3) -> void:
	soot.global_position = pos
@rpc("any_peer")
func blow_soot(soot:Node3D, dir:Vector3) -> void:
	var t = get_tree().create_tween()
	t.tween_property(soot, "global_position", dir * 30.0, 3.0).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
