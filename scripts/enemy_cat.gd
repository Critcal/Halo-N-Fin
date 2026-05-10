extends CharacterBody2D

@export var speed: float = 105.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var patrol_distance: float = 260.0
@export var max_hp: int = 3
@export var detection_range: float = 360.0
@export var attack_range: float = 70.0
@export var hit_cooldown: float = 0.9

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var start_x: float
var direction: float = -1.0
var hp: int = 3
var hit_timer: float = 0.0

func _ready() -> void:
	start_x = global_position.x
	hp = max_hp
	add_to_group("enemies")
	_setup_frames()
	sprite.play("walk")

func _physics_process(delta: float) -> void:
	if hit_timer > 0.0:
		hit_timer -= delta

	if not is_on_floor():
		velocity.y += gravity * delta

	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		_patrol()
	else:
		var delta_to_player := player.global_position - global_position
		var dist := delta_to_player.length()
		if dist <= detection_range:
			direction = sign(delta_to_player.x)
			if direction == 0.0:
				direction = -1.0
			if dist > attack_range:
				velocity.x = direction * speed
				sprite.play("walk")
			else:
				velocity.x = 0.0
				sprite.play("attack")
				if hit_timer <= 0.0 and player.has_method("take_hit"):
					player.take_hit()
					hit_timer = hit_cooldown
		else:
			_patrol()

	sprite.flip_h = direction > 0.0
	move_and_slide()

func _patrol() -> void:
	velocity.x = direction * speed * 0.75
	if global_position.x < start_x - patrol_distance:
		direction = 1.0
	elif global_position.x > start_x + patrol_distance:
		direction = -1.0
	sprite.play("walk")

func _setup_frames() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("walk")
	frames.add_animation("attack")
	frames.set_animation_speed("walk", 10.0)
	frames.set_animation_speed("attack", 11.0)
	frames.set_animation_loop("walk", true)
	frames.set_animation_loop("attack", true)
	var walk_tex := _load_first(["res://assets/cat_walk.png"])
	var attack_tex := _load_first(["res://assets/cat_attack.png"])
	if walk_tex != null:
		_add_frames(frames, "walk", walk_tex, 8)
	if attack_tex != null:
		_add_frames(frames, "attack", attack_tex, 6)
	sprite.sprite_frames = frames

func _load_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _add_frames(frames: SpriteFrames, anim: String, texture: Texture2D, cols: int) -> void:
	var fw := int(texture.get_width() / cols)
	var fh := texture.get_height()
	for i in range(cols):
		var at := AtlasTexture.new()
		at.atlas = texture
		at.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(anim, at)

func take_hit(amount: int = 1) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
