extends Node

const PROJECTILE = preload("res://scenes/projectile.tscn")
const COIN = preload("res://scenes/coin.tscn")
const BALL_PUSH_FORCE : float = 7.0
const BALL_HIT_FORCE : float = 20.0

var max_health : Array = [100.0, 100.0]
@export var health : Array = [max_health[0], max_health[1]]
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
func change_stamina(peer_id:int, v:float) -> void:
	var index : int = 0 if peer_id == 1 else 1
	if v < 0:
		var damage : float = -v
		health[index] = clamp(snapped(health[index] - damage, 0.01), 0.0, max_health[index])
	else:
		health[index] = v
	Globals.health.update(max_health, health)
	Globals.health.update.rpc_id(Globals.ms.get_second_player_peer_id(), max_health, health)
	get_node("RefreshStamina" + str(index + 1)).start()

func refresh_stamina_1(last_stamina:float = health[0]) -> void:
	if last_stamina > health[0] or last_stamina >= max_health[0]: return
	var refresh_time : float = 100.0
	var new_stamina : float = clamp(snapped(last_stamina + max_health[0] / refresh_time, 0.01), 0.0, max_health[0])
	change_stamina(1, new_stamina)
	await get_tree().create_timer(0.1).timeout
	refresh_stamina_1(new_stamina)
	
func refresh_stamina_2(last_stamina:float = health[1]) -> void:
	if last_stamina > health[1] or last_stamina >= max_health[1]: return
	var refresh_time : float = 100.0
	var new_stamina : float = clamp(snapped(last_stamina + max_health[1] / refresh_time, 0.01), 0.0, max_health[1])
	change_stamina(Globals.ms.get_second_player_peer_id(), new_stamina)
	await get_tree().create_timer(0.1).timeout
	refresh_stamina_2(new_stamina)

@rpc("any_peer")
func resurrect(peer_id:int) -> void:
	var player = Globals.ms.get_player_by_id(peer_id)
	if peer_id == 1:
		player.tp_resurrect(Globals.world.get_resurrect_position(player.global_position))
	else:
		player.tp_resurrect.rpc_id(peer_id, Globals.world.get_resurrect_position(player.global_position))
	
@rpc("any_peer")
func push_ball(peer_id: int, is_attacking: bool) -> void:
	var player = Globals.ms.get_player_by_id(peer_id)
	var force : float = BALL_PUSH_FORCE + BALL_PUSH_FORCE * float(get_skill(peer_id, "Mountain’s Strength")) / 100.0
	if is_attacking: force /= 2.0
	Globals.ball.add_impulse(player, force, false)
	change_stamina(peer_id, -0.16)
@rpc("any_peer")
func hit_ball() -> void:
	var player = Globals.ms.players.values()[0] if Globals.ms.players.values()[0].type == 0 else Globals.ms.players.values()[1]
	Globals.ball.add_impulse(player, BALL_HIT_FORCE, true)
	change_stamina(1 if Globals.ms.get_player_by_id(1).type == 0 else Globals.ms.get_second_player_peer_id(), -10.0)
@rpc("any_peer")
func toss_ball() -> void:
	Globals.ball.jump()
	change_stamina(1 if Globals.ms.get_player_by_id(1).type == 1 else Globals.ms.get_second_player_peer_id(), -10.0)
