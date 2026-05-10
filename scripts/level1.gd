extends Node2D

@export var starting_lives: int = 3
@export var coin_goal_for_life: int = 100

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var coins_label: Label = $HUD/CoinsLabel
@onready var lives_label: Label = $HUD/LivesLabel
@onready var hp_bar: TextureProgressBar = $HUD/HPBar
@onready var head: TextureRect = $HUD/Head
@onready var coins_root: Node2D = $Coins
@onready var sky: Sprite2D = $ParallaxBackground/SkyLayer/Sky
@onready var neighborhood: Sprite2D = $ParallaxBackground/NeighborhoodLayer/Neighborhood
@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var coin_sfx: AudioStreamPlayer = $CoinSfx

const COIN_SCENE := preload("res://scenes/coin.tscn")

var coins: int = 0
var lives: int = 3

func _ready() -> void:
	lives = starting_lives
	player.add_to_group("player")
	_apply_backgrounds()
	_setup_audio()
	_style_hud()
	_load_head_icon()
	_update_hud()
	player.player_died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	if ResourceLoader.exists("res://assets/Level1.mp3"):
		level_music.stream = load("res://assets/Level1.mp3")
		level_music.play()
	_spawn_coins()

func _process(_delta: float) -> void:
	var target_zoom := Vector2(0.95, 0.95)
	if player.velocity.y < -40.0:
		target_zoom = Vector2(0.82, 0.82)
	camera.zoom = camera.zoom.lerp(target_zoom, 0.08)

func _setup_audio() -> void:
	var coin_stream := _load_first_audio(["res://assets/coin_sound.mp3"])
	if coin_stream != null:
		coin_sfx.stream = coin_stream

func _apply_backgrounds() -> void:
	var sky_tex := _load_first_texture(["res://assets/sky.png"])
	if sky_tex != null:
		sky.texture = sky_tex
	var n_tex := _load_first_texture(["res://assets/background_level.png", "res://assets/neighborhood.png"])
	if n_tex != null:
		neighborhood.texture = n_tex

func _load_first_texture(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			var r := load(p)
			if r is Texture2D:
				return r
	return null

func _load_first_audio(paths: Array[String]) -> AudioStream:
	for p in paths:
		if ResourceLoader.exists(p):
			var r := load(p)
			if r is AudioStream:
				return r
	return null


func _load_head_icon() -> void:
	var head_tex := _load_first_texture(["res://assets/logo.png", "res://assets/design_studio_logo.png"])
	if head_tex != null:
		head.texture = head_tex

func _style_hud() -> void:
	var label_settings := LabelSettings.new()
	label_settings.font_size = 34
	label_settings.outline_size = 6
	label_settings.font_color = Color(1, 0.97, 0.85)
	label_settings.outline_color = Color(0.1, 0.14, 0.25)
	coins_label.label_settings = label_settings
	lives_label.label_settings = label_settings

func _on_coin_picked() -> void:
	coins += 1
	if coin_sfx.stream != null:
		coin_sfx.stop()
		coin_sfx.play()
	if coins >= coin_goal_for_life:
		coins -= coin_goal_for_life
		lives += 1
	_update_hud()

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = max(current, 0)

func _on_player_died(enemy_defeat: bool) -> void:
	lives -= 1
	if lives <= 0:
		get_tree().reload_current_scene()
		return
	player.global_position = Vector2(220, 590)
	player.reset_for_respawn()
	if not enemy_defeat:
		# fall deaths respawn instantly; enemy death animation is handled in player
		pass
	_update_hud()

func _update_hud() -> void:
	coins_label.text = "Coins: %d" % coins
	lives_label.text = "Lives: %d" % lives

func _spawn_coins() -> void:
	for i in range(100):
		var c = COIN_SCENE.instantiate()
		c.add_to_group("coins")
		var x := 320 + i * 72
		var y := 500
		if i % 10 in [3, 4, 5]:
			y = 440
		c.position = Vector2(x, y)
		coins_root.add_child(c)
		c.picked.connect(_on_coin_picked)
