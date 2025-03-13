extends Node

var skills : Array

var save_path = "user://save_data.json"

func _ready() -> void:
	load_data()

func save_data() -> void:
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	var object = {
		"skills": skills
	}
	var json_string = JSON.stringify(object)
	file.store_line(json_string)

func load_data() -> void:
	if not FileAccess.file_exists(save_path): 
		#PlayerStats.coins = 10000
		return
	var loaded_data = get_saved_data(save_path)
	skills = get_loaded_data(loaded_data, "skills", [])
	
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
