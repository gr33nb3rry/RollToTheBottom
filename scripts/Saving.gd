extends Node

var skills : Array
var bonus_decals : Dictionary = {0: false,1: false,2: false,3: false,4: false,5: false,6: false,7: false,8: false,9: false,10: false,11: false,12: false,13: false,14: false,15: false,16: false,17: false,18: false,19: false,20: false,21: false,22: false,23: false}

var save_path = "user://save_data.json"

func _ready() -> void:
	load_data()

func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var object = {
		"bonus_decals": bonus_decals
	}
	var json_string = JSON.stringify(object)
	file.store_line(json_string)

func load_data() -> void:
	print("Loaded bonus decals:  ", bonus_decals)
	if not FileAccess.file_exists(save_path): 
		#PlayerStats.coins = 10000
		return
	var loaded_data = get_saved_data(save_path)
	#bonus_decals = get_loaded_data(loaded_data, "bonus_decals", {0: false,1: false,2: false,3: false,4: false,5: false,6: false,7: false,8: false,9: false,10: false})
	var raw_bonus_decals = get_loaded_data(loaded_data, "bonus_decals", {0: false,1: false,2: false,3: false,4: false,5: false,6: false,7: false,8: false,9: false,10: false,11: false,12: false,13: false,14: false,15: false,16: false,17: false,18: false,19: false,20: false,21: false,22: false,23: false})

	bonus_decals = {}
	for key in raw_bonus_decals.keys():
		var int_key = int(key)
		bonus_decals[int_key] = raw_bonus_decals[key]

	print("Loaded bonus decals:  ", bonus_decals)
func get_loaded_data(loaded_data:Dictionary, key:String, default_value):
	if loaded_data.has(key):
		return loaded_data[key]
	else: return default_value
func get_saved_data(path:String):
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_line()
	var json = JSON.new()
	var _parse_result = json.parse(json_string)
	return json.get_data()
