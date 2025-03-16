extends Node3D

var is_able_to_claim := true

func claim(player:CharacterBody3D) -> void:
	#is_able_to_claim = false
	#$Orb.visible = false
	if player.get_multiplayer_authority() == multiplayer.get_unique_id():
		Globals.skills.open(player)

func _on_area_body_entered(body: Node3D) -> void:
	if is_able_to_claim and body.is_in_group("Player"):
		claim(body)
