extends Node3D

enum Activities {
	COUNTER
}

var zone : int = 1
var activity_type : int = -1
var activity_value : String
var activity_answer : String
var selected_decals : int

var current_zone_instance : Node3D
var is_able_to_zone_up : bool = false
var current_room : Node3D
var dead_line : float
var is_playing : bool = true

func _ready() -> void:
	Globals.define()
	#start()
	Globals.character_select.open()
	
func start() -> void:
	current_zone_instance = get_zone()
	Globals.ball.is_simplified = true
	is_able_to_zone_up = true
	if current_zone_instance.has_node("Room"): dead_line = get_room().global_position.y - 25.0
	else: dead_line = 0.0
	sync_dead_line.rpc_id(Globals.ms.get_second_player_peer_id(), dead_line)
	#add_waiting_soots()
	if $Map.get_child(zone).has_node("Room"):
		$Map.get_child(zone).get_node("Room").process_mode = Node.PROCESS_MODE_INHERIT
	if zone >= 2:
		$Map.get_node("Room").disable()
		if zone >= 3:
			$Map.get_child(zone-2).disable()
			#$Map.get_child(zone-2).call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)
	generate_zone()

func generate_zone() -> void:
	selected_decals = 0
	activity_type = -1
	is_playing = true
	current_zone_instance.is_activity_started = false
	current_zone_instance.is_activity_finished = false
	current_zone_instance.is_finished = false
	for decal in Globals.world.get_node("Decals").get_children(): decal.queue_free()
	for decal in Globals.world.get_node("Barriers").get_children(): decal.queue_free()
	await get_tree().create_timer(0.2).timeout
	current_zone_instance.generate_decals()
	
func end() -> void:
	if is_able_to_zone_up:
		get_tree().call_group("Soot", "death")
		zone += 1
		Globals.ball.is_simplified = false
		is_able_to_zone_up = false
		start()
	
func game_over() -> void:
	# tp to room
	var count : int = 0
	for p in Globals.ms.players:
		if p == 1:
			Globals.ms.players[p].tp_resurrect(get_previous_room().get_node("StartPos" + str(count)).global_position)
		else:
			Globals.ms.players[p].tp_resurrect.rpc_id(Globals.ms.get_second_player_peer_id(), get_previous_room().get_node("StartPos" + str(count)).global_position)
		count += 1
	Globals.ball.global_position = get_previous_room().get_node("StartPosBall").global_position
	# start
	generate_zone()
	#Globals.ball.freeze = true
	
	
@rpc("any_peer")
func sync_dead_line(dl:float) -> void:
	dead_line = dl

func generate_activity() -> void:
	activity_type = Activities.COUNTER
	match activity_type:
		Activities.COUNTER: 
			var decal_type : int = randi_range(0, 5)
			activity_answer = str(get_zone().get_decal_count(decal_type))
			activity_value = str(decal_type)
	print("Activity generated.  Type: ", activity_type, "  Value: ", activity_value, "  Answer: ", activity_answer)
	sync_activity.rpc_id(Globals.ms.get_second_player_peer_id(), activity_type, activity_value, activity_answer)

@rpc("any_peer")
func sync_activity(type:int, value:String, answer:String) -> void:
	activity_type = type
	activity_value = value
	activity_answer = answer

func select_decal() -> void:
	print("Selected decals: ", selected_decals)
	selected_decals += 1
	Globals.activity.update_current()
	sync_selected_decals.rpc_id(Globals.ms.get_second_player_peer_id(), selected_decals)
	if str(selected_decals) == activity_answer:
		finish_activity()

@rpc("any_peer")
func sync_selected_decals(v:int) -> void:
	selected_decals = v
	Globals.activity.update_current()

func start_activity() -> void:
	generate_activity()
	print("Activity started")
	Globals.activity.update(activity_type, activity_value, activity_answer)
	Globals.activity.update.rpc_id(Globals.ms.get_second_player_peer_id(), activity_type, activity_value, activity_answer)
	
func finish_activity() -> void:
	print("Activity finished")
	current_zone_instance.is_activity_finished = true
	Globals.activity.finish()
	Globals.activity.finish.rpc_id(Globals.ms.get_second_player_peer_id())
	
	
func get_zone() -> Node3D:
	return $Map.get_child(zone)
func get_room() -> Node3D:
	return current_zone_instance.get_node("Room")
func get_previous_room() -> Node3D:
	if zone == 1: return $Map.get_child(0)
	return $Map.get_child(zone - 1).get_node("Room")
	
func get_zone_next_marker() -> Vector3:
	return current_zone_instance.get_next_marker()

func get_closest_point_of(of:Node3D) -> Vector3:
	return current_zone_instance.get_closest_point_of(of)

func get_coin_position(pos:Vector3) -> Vector3:
	return current_zone_instance.get_coin_position(pos)
	
	
func get_radius_on_pos(pos:Vector3) -> float:
	return current_zone_instance.get_radius_on_pos(pos)

func is_marker_completed() -> bool:
	return current_zone_instance.is_marker_completed()
	
func get_near_flying_position() -> Vector3:
	return current_zone_instance.get_near_flying_position()
	
func get_next_near_flying_position() -> Vector3:
	return current_zone_instance.get_next_near_flying_position()
	
func get_resurrect_position(pos:Vector3) -> Vector3:
	return current_zone_instance.get_resurrect_position(pos)
	
func add_waiting_soots() -> void:
	current_zone_instance.add_waiting_soots()

func get_jumping_start_position() -> Vector3:
	return get_room().get_jumping_start_position()

func get_passed_position() -> float:
	return current_zone_instance.get_passed_position()

func get_length() -> float:
	return current_zone_instance.get_length()
