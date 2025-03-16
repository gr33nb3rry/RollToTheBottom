extends Node

var skills
var ball
var ms
var world
var processor
var projectile_spawner
var enemy_spawner

func define() -> void:
	skills = $/root/Main/Canvas/Skills
	ball = $/root/Main/World/Ball
	ms = $/root/Main/World/MultiplayerSpawner
	world = $/root/Main/World
	processor = $/root/Main/World/Processor
	projectile_spawner = $/root/Main/World/ProjectileSpawner
	enemy_spawner = $/root/Main/World/EnemySpawner
