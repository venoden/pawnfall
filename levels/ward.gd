extends Area2D

@export var radius := 126.0
@export var burn_dps := 18.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius
	queue_redraw()


func _physics_process(delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.call("take_damage", burn_dps * delta, "ward", false)


func blocks_hostile_position(position_to_check: Vector2, body_radius := 0.0) -> bool:
	return global_position.distance_to(position_to_check) < radius + body_radius


func contains_player(position_to_check: Vector2) -> bool:
	return global_position.distance_to(position_to_check) < radius


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.72, 0.2, 0.29, 0.11))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, Color(0.85, 0.36, 0.27, 0.76), 4.0)
	draw_arc(Vector2.ZERO, radius - 11.0, 0.0, TAU, 96, Color(0.72, 0.2, 0.29, 0.46), 2.0)
