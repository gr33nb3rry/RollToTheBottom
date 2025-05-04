extends Node3D

enum Activities {
	COUNTER
}

var zone : int = 1
var activity_type : int
var activity_value : String
var activity_answer : String
var selected_decals : int

var current_zone_instance : Node3D
var is_able_to_zone_up : bool = false
var current_room : Node3D

func _ready() -> void:
	Globals.define()
	#start()
	Globals.character_select.open()
	
func start() -> void:
	current_zone_instance = get_zone()
	generate_activity()
	Globals.ball.is_simplified = true
	is_able_to_zone_up = true
	#add_waiting_soots()
	$Map.get_child(zone).get_node("Room").process_mode = Node.PROCESS_MODE_INHERIT
	if zone >= 2:
		$Map.get_node("Room").disable()
		if zone >= 3:
			$Map.get_child(zone-2).disable()
			#$Map.get_child(zone-2).call_deferred("set_process_mode", Node.PROCESS_MODE_DISABLED)
	
func end() -> void:
	if is_able_to_zone_up:
		get_tree().call_group("Soot", "death")
		zone += 1
		Globals.ball.is_simplified = false
		is_able_to_zone_up = false
		start()
	
func generate_activity() -> void:
	selected_decals = 0
	activity_type = Activities.COUNTER
	match activity_type:
		Activities.COUNTER: 
			var decal_type : int = randi_range(0, 5)
			activity_answer = str(get_zone().get_decal_count(decal_type))
			activity_value = str(decal_type)
	print("Activity generated.  Type: ", activity_type, "  Value: ", activity_value, "  Answer: ", activity_answer)

func select_decal() -> void:
	print("Selected decals: ", selected_decals)
	selected_decals += 1
	if str(selected_decals) == activity_answer:
		finish_activity()

func start_activity() -> void:
	print("Activity started")
	
func finish_activity() -> void:
	print("Activity finished")
	
	
func get_zone() -> Node3D:
	return $Map.get_child(zone)
	
func get_room() -> Node3D:
	return current_zone_instance.get_node("Room")
	
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
	
func get_next_jumping_position(pos:Vector3) -> Vector3:
	return current_zone_instance.get_next_jumping_position(pos)
	
func add_waiting_soots() -> void:
	current_zone_instance.add_waiting_soots()

func get_jumping_start_position() -> Vector3:
	return get_room().get_jumping_start_position()

func get_passed_position() -> float:
	return current_zone_instance.get_passed_position()

func get_length() -> float:
	return current_zone_instance.get_length()
