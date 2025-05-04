extends Node

var main
var skills
var ball
var ms
var world
var processor
var enemy_spawner
var health
var activity
var stats
var character_select

func define() -> void:
	main = $/root/Main
	skills = $/root/Main/World/Canvas/Skills
	ball = $/root/Main/World/Ball
	ms = $/root/Main/World/MultiplayerSpawner
	world = $/root/Main/World
	processor = $/root/Main/World/Processor
	enemy_spawner = $/root/Main/World/EnemySpawner
	health = $/root/Main/World/Canvas/Health
	activity = $/root/Main/World/Canvas/Activity
	stats = $/root/Main/World/Stats
	character_select = $/root/Main/World/Canvas/CharacterSelect
