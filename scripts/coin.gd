extends Area2D

signal picked

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") or body.name == "Player":
		emit_signal("picked")
		queue_free()
