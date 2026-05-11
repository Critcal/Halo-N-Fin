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
const ENEMY_SCENE := preload("res://scenes/enemy_cat.tscn")

var coins: int = 0
var lives: int = 3

func _ready() -> void:
	lives = starting_lives
	player.add_to_group("player")
	_apply_backgrounds()
	_setup_audio()
	_style_hud()
	_load_head_icon()
	_setup_platform_visuals()
	_update_hud()
	player.player_died.connect(_on_player_died)
	player.health_changed.connect(_on_health_changed)
	if ResourceLoader.exists("res://assets/Level1.mp3"):
		level_music.stream = load("res://assets/Level1.mp3")
		level_music.play()
	_spawn_enemies()
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
	var n_tex := _load_first_texture(["res://assets/neighborhood.png", "res://assets/background_level.png"])
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
	for child in coins_root.get_children():
		child.queue_free()
	var coin_positions := [
		Vector2(420, 540), Vector2(560, 500), Vector2(740, 455), Vector2(940, 545),
		Vector2(1080, 425), Vector2(1250, 385), Vector2(1410, 430), Vector2(1620, 550),
		Vector2(1860, 500), Vector2(2060, 375), Vector2(2230, 340), Vector2(2400, 395),
		Vector2(2590, 530), Vector2(2790, 490), Vector2(3010, 455), Vector2(3220, 455),
		Vector2(3400, 520), Vector2(3640, 560), Vector2(3880, 520), Vector2(4120, 465),
		Vector2(4340, 355), Vector2(4510, 350), Vector2(4680, 385), Vector2(4900, 540),
		Vector2(5140, 500), Vector2(5380, 455), Vector2(5600, 430), Vector2(5780, 470),
		Vector2(6020, 540), Vector2(6280, 515), Vector2(6530, 480), Vector2(6790, 445),
		Vector2(7040, 535), Vector2(7280, 500), Vector2(7520, 465)
	]
	for p in coin_positions:
		var c = COIN_SCENE.instantiate()
		c.add_to_group("coins")
		c.position = p
		coins_root.add_child(c)
		c.picked.connect(_on_coin_picked)

func _spawn_enemies() -> void:
	var enemies_root := $Enemies
	for child in enemies_root.get_children():
		child.queue_free()
	var enemy_positions := [
		Vector2(920, 590), Vector2(1710, 590), Vector2(2790, 590), Vector2(3980, 590),
		Vector2(1090, 450), Vector2(2140, 385), Vector2(4360, 400), Vector2(5620, 440), Vector2(7200, 590)
	]
	for p in enemy_positions:
		var enemy := ENEMY_SCENE.instantiate()
		enemy.position = p
		enemies_root.add_child(enemy)

func _setup_platform_visuals() -> void:
	if not ResourceLoader.exists("res://assets/platform.png"):
		return
	var tex := load("res://assets/platform.png") as Texture2D
	if tex == null:
		return
	for s in get_tree().get_nodes_in_group("platform_sprite_targets"):
		if s is Sprite2D:
			s.texture = tex
