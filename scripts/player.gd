extends CharacterBody2D

signal player_died

@export var speed: float = 240.0
@export var run_speed_multiplier: float = 1.5
@export var jump_velocity: float = -500.0
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var attack_duration: float = 0.28
@export var stomp_bounce_velocity: float = -320.0
@export var max_hp: int = 3
@export var power_jump_bonus: float = 260.0
@export var max_charge_time: float = 3.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea2D
@onready var attack_shape: CollisionShape2D = $AttackArea2D/CollisionShape2D
@onready var jump_sfx: AudioStreamPlayer = $JumpSfx
@onready var swing_sfx: AudioStreamPlayer = $SwingSfx
@onready var hit_sfx: AudioStreamPlayer = $HitSfx
@onready var bark_sfx: AudioStreamPlayer = $BarkSfx

var is_attacking := false
var attack_timer := 0.0
var is_crouching := false
var charge_time := 0.0
var hp := 3
var hurt_cooldown := 0.0
var attack_targets_hit: Dictionary = {}
var attack_landed := false
var landed_punch_count := 0

func _ready() -> void:
	hp = max_hp
	_setup_input_map()
	_setup_frames()
	_setup_audio()
	sprite.animation = "walk"
	sprite.frame = 0
	attack_shape.disabled = true

func _physics_process(delta: float) -> void:
	if hurt_cooldown > 0.0:
		hurt_cooldown -= delta

	var direction := Input.get_axis("move_left", "move_right")
	var crouch_held := Input.is_action_pressed("crouch")
	var attack_pressed := Input.is_action_just_pressed("attack")
	var jump_pressed := Input.is_action_just_pressed("jump")
	var run_held := Input.is_action_pressed("run")
	var current_speed := speed * (run_speed_multiplier if run_held else 1.0)

	if not is_on_floor():
		velocity.y += gravity * delta

	if crouch_held and is_on_floor() and not is_attacking:
		is_crouching = true
		charge_time = min(charge_time + delta, max_charge_time)
		velocity.x = move_toward(velocity.x, 0.0, current_speed)
		sprite.play("crouch")
	elif is_crouching:
		is_crouching = false
		if is_on_floor() and charge_time >= max_charge_time:
			velocity.y = jump_velocity - power_jump_bonus
			sprite.play("power_jump")
			_play_jump_sound()
			_play_bark()
		charge_time = 0.0

	if jump_pressed and is_on_floor() and not is_crouching and not is_attacking:
		velocity.y = jump_velocity
		_play_jump_sound()

	if attack_pressed and not is_attacking and is_on_floor() and not is_crouching:
		_start_attack()

	if direction != 0.0 and not is_crouching:
		velocity.x = direction * current_speed
		sprite.flip_h = direction < 0.0
		attack_area.position.x = -42 if sprite.flip_h else 42
	elif not is_crouching:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)

	if not is_attacking and not is_crouching:
		if not is_on_floor():
			if velocity.y < -20.0:
				sprite.play("power_jump")
			elif sprite.animation != "jump":
				sprite.play("jump")
		elif abs(velocity.x) > speed * 1.05 and sprite.sprite_frames.has_animation("run"):
			sprite.play("run")
		elif abs(velocity.x) > 5.0:
			sprite.play("walk")
		else:
			sprite.stop()
			sprite.animation = "walk"
			sprite.frame = 0

	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			_end_attack()

	move_and_slide()
	_handle_enemy_stomp()
	_handle_attack_hits()

	if global_position.y > 1200.0:
		emit_signal("player_died")

func take_hit() -> void:
	if hurt_cooldown > 0.0:
		return
	hp -= 1
	hurt_cooldown = 0.5
	if hp <= 0:
		emit_signal("player_died")

func reset_for_respawn() -> void:
	hp = max_hp
	hurt_cooldown = 0.0
	velocity = Vector2.ZERO
	is_attacking = false
	is_crouching = false
	charge_time = 0.0
	attack_shape.disabled = true
	attack_targets_hit.clear()
	attack_landed = false

func _setup_input_map() -> void:
	_bind_action_key("move_left", KEY_LEFT)
	_bind_action_key("move_right", KEY_RIGHT)
	_bind_action_key("jump", KEY_CTRL)
	_bind_action_key("attack", KEY_SPACE)
	_bind_action_key("crouch", KEY_DOWN)
	_bind_action_key("run", KEY_SHIFT)
	_bind_joy_button("jump", JOY_BUTTON_A)
	_bind_joy_button("attack", JOY_BUTTON_X)
	_bind_joy_button("crouch", JOY_BUTTON_DPAD_DOWN)
	_bind_joy_button("run", JOY_BUTTON_LEFT_SHOULDER)
	_bind_joy_button("run", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_bind_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)

func _bind_action_key(action: String, keycode: Key) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)

func _bind_joy_button(action: String, button: JoyButton) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button:
			return
	var joy_event := InputEventJoypadButton.new()
	joy_event.button_index = button
	InputMap.action_add_event(action, joy_event)

func _bind_joy_axis(action: String, axis: JoyAxis, axis_value: float) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return
	var motion_event := InputEventJoypadMotion.new()
	motion_event.axis = axis
	motion_event.axis_value = axis_value
	InputMap.action_add_event(action, motion_event)

func _setup_frames() -> void:
	var frames := SpriteFrames.new()
	for anim in ["walk", "run", "jump", "attack", "crouch", "power_jump"]:
		frames.add_animation(anim)
	frames.set_animation_speed("walk", 12.0)
	frames.set_animation_speed("run", 14.0)
	frames.set_animation_speed("jump", 12.0)
	frames.set_animation_speed("attack", 14.0)
	frames.set_animation_speed("crouch", 8.0)
	frames.set_animation_speed("power_jump", 12.0)
	frames.set_animation_loop("walk", true)
	frames.set_animation_loop("run", true)
	frames.set_animation_loop("jump", false)
	frames.set_animation_loop("attack", false)
	frames.set_animation_loop("crouch", true)
	frames.set_animation_loop("power_jump", false)

	var walk_tex := _load_first(["res://assets/finn_walk_strip.png"])
	var run_tex := _load_first(["res://assets/finn_run_strip.png", "res://assets/finn_running_strip.png"])
	var jump_tex := _load_first(["res://assets/finn_jump_strip.png"])
	var attack_tex := _load_first(["res://assets/finn_attack_strip.png", "res://assets/finn_punch_strip.png"])
	var crouch_tex := _load_first(["res://assets/finn_crouch_strip.png"])
	var power_jump_tex := _load_first(["res://assets/finn_power_jump_strip.png"])

	if walk_tex != null:
		_add_grid_frames(frames, "walk", walk_tex, 8, 1, 8)
	if run_tex != null:
		_add_grid_frames(frames, "run", run_tex, 8, 1, 8)
	elif walk_tex != null:
		_add_grid_frames(frames, "run", walk_tex, 8, 1, 8)
	if jump_tex != null:
		_add_grid_frames(frames, "jump", jump_tex, 7, 1, 7)
	if attack_tex != null:
		_add_grid_frames(frames, "attack", attack_tex, 6, 1, 6)
	if crouch_tex != null:
		_add_grid_frames(frames, "crouch", crouch_tex, 4, 1, 4)
	if power_jump_tex != null:
		_add_grid_frames(frames, "power_jump", power_jump_tex, 7, 1, 7)

	sprite.sprite_frames = frames

func _setup_audio() -> void:
	if ResourceLoader.exists("res://assets/finn_16bit_style_jump_reverb.wav"):
		jump_sfx.stream = load("res://assets/finn_16bit_style_jump_reverb.wav")
	if ResourceLoader.exists("res://assets/punch_swing.mp3"):
		swing_sfx.stream = load("res://assets/punch_swing.mp3")
	if ResourceLoader.exists("res://assets/punch_hit.mp3"):
		hit_sfx.stream = load("res://assets/punch_hit.mp3")
	if ResourceLoader.exists("res://assets/bark.mp3"):
		bark_sfx.stream = load("res://assets/bark.mp3")

func _load_first(paths: Array[String]) -> Texture2D:
	for p in paths:
		if ResourceLoader.exists(p):
			return load(p)
	return null

func _add_grid_frames(frames: SpriteFrames, anim: String, texture: Texture2D, cols: int, rows: int, frame_count: int) -> void:
	var fw := int(texture.get_width() / cols)
	var fh := int(texture.get_height() / rows)
	for i in range(frame_count):
		var at := AtlasTexture.new()
		at.atlas = texture
		at.region = Rect2(i * fw, 0, fw, fh)
		frames.add_frame(anim, at)

func _start_attack() -> void:
	is_attacking = true
	attack_timer = attack_duration
	attack_shape.disabled = false
	attack_targets_hit.clear()
	attack_landed = false
	sprite.play("attack")
	if swing_sfx.stream != null:
		swing_sfx.play()

func _end_attack() -> void:
	is_attacking = false
	attack_shape.disabled = true

func _handle_enemy_stomp() -> void:
	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider and collider.is_in_group("enemies") and collision.get_normal().y < -0.6 and velocity.y > 0.0:
			collider.call_deferred("take_hit", 3)
			velocity.y = stomp_bounce_velocity

func _handle_attack_hits() -> void:
	if not is_attacking:
		return
	for body in attack_area.get_overlapping_bodies():
		if body and body.is_in_group("enemies"):
			var id := body.get_instance_id()
			if attack_targets_hit.has(id):
				continue
			attack_targets_hit[id] = true
			body.call_deferred("take_hit", 1)
			if not attack_landed:
				attack_landed = true
				_play_landed_punch_sound()

func _play_landed_punch_sound() -> void:
	landed_punch_count += 1
	if hit_sfx.stream == null:
		return
	if landed_punch_count % 2 == 0 and ResourceLoader.exists("res://assets/punch_light_hit.mp3"):
		hit_sfx.stream = load("res://assets/punch_light_hit.mp3")
	elif ResourceLoader.exists("res://assets/punch_hit.mp3"):
		hit_sfx.stream = load("res://assets/punch_hit.mp3")
	hit_sfx.play()
	if landed_punch_count % 3 == 0:
		_play_bark()

func _play_jump_sound() -> void:
	if jump_sfx.stream != null:
		jump_sfx.play()

func _play_bark() -> void:
	if bark_sfx.stream != null:
		bark_sfx.play()
