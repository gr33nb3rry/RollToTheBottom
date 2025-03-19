extends Control

@rpc("any_peer")
func update(max_health:Array, health:Array) -> void:
	print("Damage in health")
	$Progress1.max_value = max_health[0]
	$Progress1.value = health[0]
	$Progress2.max_value = max_health[1]
	$Progress2.value = health[1]
