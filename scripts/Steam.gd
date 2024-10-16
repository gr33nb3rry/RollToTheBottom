extends Node


func _ready() -> void:
	OS.set_environment("SteamAppId", str(480))
	OS.set_environment("SteamGameId", str(480))
	Steam.steamInitEx()


func _process(delta: float) -> void:
	Steam.run_callbacks()
