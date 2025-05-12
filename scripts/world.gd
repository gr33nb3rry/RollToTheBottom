extends Node3D

enum Activities {
	COUNTER
}

@export var zone : int = 1
var activity_type : int = -1
var activity_value : String
var activity_answer : String
var selected_decals : int

@export var current_zone_instance : Node3D
var is_able_to_zone_up : bool = false
var current_room : Node3D
var dead_line : float
var is_playing : bool = true
var is_waiting_to_remove_elements : bool = false

@export var decal_info : Array = []
@export var barrier_info : Array = []

@rpc("any_peer")
func add_decal(i) -> void:
	print(222)
	var pos = decal_info[i][0]
	var rot = decal_info[i][1]
	var type = decal_info[i][2]
	update_decal_position_rotation_type(i, pos, rot, type)
	update_decal_position_rotation_type.rpc_id(Globals.ms.get_second_player_peer_id(), i, pos, rot, type)
@rpc("any_peer")
func add_barrier(i) -> void:
	var pos = barrier_info[i][0]
	var pivot = barrier_info[i][1]
	update_barrier(i, pos, pivot)
	update_barrier.rpc_id(Globals.ms.get_second_player_peer_id(), i, pos, pivot)

@rpc("any_peer")
func update_barrier(index:int, pos:Vector3, pivot:Vector3) -> void:
	print("Index: ", index, " pivot: ", pivot, " Pipa: ", Globals.world.get_node("Barriers").get_child(index))
	Globals.world.get_node("Barriers").get_child(index).global_position = pos
	Globals.world.get_node("Barriers").get_child(index).pivot = pivot
	Globals.world.get_node("Barriers").get_child(index).generate_type()


@rpc("any_peer")
func update_decal_position_rotation_type(index:int, pos:Vector3, rot:Vector3, type:int) -> void:
	print(333)
	print("Index: ", index, " pos: ", pos)
	
	Globals.world.get_node("Decals").get_child(index).global_position = pos
	Globals.world.get_node("Decals").get_child(index).global_rotation = rot
	Globals.world.get_node("Decals").get_child(index).type = type
	Globals.world.get_node("Decals").get_child(index).update_type()



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
			
	generate_zone()

func generate_zone() -> void:
	if !multiplayer.is_server(): return
	selected_decals = 0
	sync_selected_decals.rpc_id(Globals.ms.get_second_player_peer_id(), selected_decals)
	activity_type = -1
	is_playing = true
	decal_info = []
	barrier_info = []
	is_waiting_to_remove_elements = true
	current_zone_instance.is_activity_started = false
	current_zone_instance.is_activity_finished = false
	current_zone_instance.is_finished = false
	for decal in Globals.world.get_node("Decals").get_children(): decal.queue_free()
	for barrier in Globals.world.get_node("Barriers").get_children(): barrier.queue_free()
	
	start_level()
	#await get_tree().create_timer(0.2).timeout
	#current_zone_instance.generate_decals()

@rpc("any_peer")
func start_level() -> void:
	if !is_waiting_to_remove_elements: return
	is_waiting_to_remove_elements = false
	Globals.ball.is_active = true
	Globals.ball.freeze = false
	current_zone_instance.generate_decals()
	
func end() -> void:
	if is_able_to_zone_up:
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
