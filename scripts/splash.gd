extends Control

@export var splash_duration: float = 2.0

@onready var logo: TextureRect = $Logo

func _ready() -> void:
	var tex := _load_first(["res://assets/design_studio_logo.png", "res://assets/bink_design_studio_logo.png"])
	if tex != null:
		logo.texture = tex
	await get_tree().create_timer(splash_duration).timeout
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _load_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null
