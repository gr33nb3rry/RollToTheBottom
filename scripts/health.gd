extends Control

func update() -> void:
	$Progress.max_value = Globals.processor.max_health[0]
	$Progress.value = Globals.processor.health[0]
