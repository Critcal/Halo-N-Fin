extends Node2D

@export var starting_lives: int = 3
@export var coin_goal_for_life: int = 100

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var coins_label: Label = $HUD/CoinsLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var coins_root: Node2D = $Coins
@onready var sky: Sprite2D = $ParallaxBackground/SkyLayer/Sky
@onready var neighborhood: Sprite2D = $ParallaxBackground/NeighborhoodLayer/Neighborhood
@onready var level_music: AudioStreamPlayer = $LevelMusic

const COIN_SCENE := preload("res://scenes/coin.tscn")

var coins: int = 0
var lives: int = 3

func _ready() -> void:
	lives = starting_lives
	player.add_to_group("player")
	_apply_backgrounds()
	_update_hud()
	player.player_died.connect(_on_player_died)
	if ResourceLoader.exists("res://assets/Level1.mp3"):
		level_music.stream = load("res://assets/Level1.mp3")
		level_music.play()
	_spawn_coins()

func _process(_delta: float) -> void:
	var target_zoom := Vector2(0.95, 0.95)
	if player.velocity.y < -40.0:
		target_zoom = Vector2(0.78, 0.78)
	camera.zoom = camera.zoom.lerp(target_zoom, 0.08)

func _apply_backgrounds() -> void:
	var sky_tex := _load_first(["res://assets/sky.png"])
	if sky_tex != null:
		sky.texture = sky_tex
	var n_tex := _load_first(["res://assets/neighborhood.png"])
	if n_tex != null:
		neighborhood.texture = n_tex

func _load_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _on_coin_picked() -> void:
	coins += 1
	if coins >= coin_goal_for_life:
		coins -= coin_goal_for_life
		lives += 1
	_update_hud()

func _on_player_died() -> void:
	lives -= 1
	if lives <= 0:
		get_tree().reload_current_scene()
		return
	player.global_position = Vector2(220, 500)
	player.reset_for_respawn()
	_update_hud()

func _update_hud() -> void:
	coins_label.text = "Coins: %d" % coins
	lives_label.text = "Lives: %d" % lives

func _spawn_coins() -> void:
	for i in range(120):
		var c = COIN_SCENE.instantiate()
		c.add_to_group("coins")
		var x := 320 + i * 58
		var y := 500
		if i % 12 in [3, 4, 5]:
			y = 430
		c.position = Vector2(x, y)
		coins_root.add_child(c)
		c.picked.connect(_on_coin_picked)
