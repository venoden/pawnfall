extends Area2D

signal picked_up

@export var bob_height := 3.0
@export var bob_speed := 3.2

@onready var sprite: Sprite2D = $Sprite2D

var base_sprite_position := Vector2.ZERO
var bob_time := 0.0


func _ready() -> void:
	base_sprite_position = sprite.position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	bob_time += delta * bob_speed
	sprite.position = base_sprite_position + Vector2(0.0, sin(bob_time) * bob_height)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	picked_up.emit()
	queue_free()
