extends Node

var main
var skills
var ball
var ms
var world
var map
var processor
var enemy_spawner
var health
var activity
var stats
var decals
var barriers
var character_select

func define() -> void:
	main = $/root/Main
	skills = $/root/Main/World/Canvas/Skills
	ball = $/root/Main/World/Ball
	ms = $/root/Main/World/MultiplayerSpawner
	world = $/root/Main/World
	map = $/root/Main/World/Map
	processor = $/root/Main/World/Processor
	enemy_spawner = $/root/Main/World/EnemySpawner
	health = $/root/Main/World/Canvas/Health
	activity = $/root/Main/World/Canvas/Activity
	stats = $/root/Main/World/Stats
	decals = $/root/Main/World/Decals
	barriers = $/root/Main/World/Barriers
	character_select = $/root/Main/World/Canvas/CharacterSelect
