extends Node

const STEAM_APP_ID := 480
var is_on_steam_deck: bool
var is_online: bool
var is_owned: bool
var steam_id: int
var steam_username: String


func _ready() -> void:
	OS.set_environment("SteamAppId", str(STEAM_APP_ID))
	OS.set_environment("SteamGameId", str(STEAM_APP_ID))
	initialize_steam()
	
func initialize_steam() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	Steam.initRelayNetworkAccess()
	Steam.inputInit()

	if initialize_response['status'] == 0:
		is_on_steam_deck= Steam.isSteamRunningOnSteamDeck()
		is_online = Steam.loggedOn()
		is_owned = Steam.isSubscribed()
		steam_id = Steam.getSteamID()
		steam_username = Steam.getPersonaName()
	else:
		print("Failed to initialize Steam, shutting down: ", initialize_response)
		get_tree().quit()


func _process(delta: float) -> void:
	Steam.run_callbacks()
