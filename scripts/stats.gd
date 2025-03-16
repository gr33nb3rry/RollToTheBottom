extends Node

var last_ping_time: float  

func _process(delta: float) -> void:
	ping(multiplayer.get_unique_id())

@rpc("any_peer")
func ping(target_id: int, iam_asking: bool = true) -> void:  
	if iam_asking:  
		last_ping_time = Time.get_unix_time_from_system()
		ping.rpc(target_id, false)  
	else:  
		var sender_id: int = multiplayer.get_remote_sender_id()
		print_ping.rpc(sender_id)

@rpc("any_peer")      
func print_ping():
	print("Ping delay: ", str(Time.get_unix_time_from_system() - last_ping_time))  
