extends Node

var skills
var ball
var ms
var processor

func define() -> void:
	skills = $/root/Main/Canvas/Skills
	ball = $/root/Main/World/Ball
	ms = $/root/Main/World/MultiplayerSpawner
	processor = $/root/Main/World/Processor
