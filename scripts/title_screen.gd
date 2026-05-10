extends Control

@onready var title_image: TextureRect = $TitleImage
@onready var prompt: Label = $Prompt
@onready var theme_player: AudioStreamPlayer = $ThemePlayer

func _ready() -> void:
	var tex := _load_first(["res://assets/title_screen.png", "res://assets/halo_finn_title.png"])
	if tex != null:
		title_image.texture = tex
	if ResourceLoader.exists("res://assets/Theme.mp3"):
		theme_player.stream = load("res://assets/Theme.mp3")
		theme_player.play()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept") or Input.is_key_pressed(KEY_ENTER):
		get_tree().change_scene_to_file("res://scenes/level1.tscn")

func _load_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null
