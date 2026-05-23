class_name AttackSweep
extends Node2D

@export var lifetime := 0.18
@export var outer_color := Color(1.0, 0.92, 0.72, 0.68)
@export var inner_color := Color(1.0, 0.76, 0.52, 0.48)

var age := 0.0
var variant_index := 0
var swing_side := 1


func setup(direction: Vector2, new_variant_index: int, new_swing_side := 1) -> void:
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction.length_squared() <= 0.001:
		normalized_direction = Vector2.RIGHT
	rotation = normalized_direction.angle()
	variant_index = clampi(new_variant_index, 0, 4)
	swing_side = -1 if new_swing_side < 0 else 1
	scale.y = float(swing_side)


func _process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress: float = clampf(age / lifetime, 0.0, 1.0)
	var fade: float = 1.0 - progress
	var grow: float = 1.0 + progress * 0.16
	var start_angle: float = _variant_start_angle()
	var sweep_angle: float = _variant_sweep_angle()
	var outer_radius: float = _variant_outer_radius() * grow
	var inner_radius: float = _variant_inner_radius() * grow

	_draw_rounded_arc(outer_radius, 12.0, _with_alpha(outer_color, fade), start_angle, sweep_angle)
	_draw_rounded_arc(inner_radius, 8.0, _with_alpha(inner_color, fade * 0.92), start_angle + 0.08, sweep_angle * 0.86)


func _draw_rounded_arc(radius: float, width: float, color: Color, start_angle: float, sweep_angle: float) -> void:
	var points := PackedVector2Array()
	var segments := 14
	for index in range(segments + 1):
		var amount: float = float(index) / float(segments)
		var angle: float = start_angle + sweep_angle * amount
		points.append(Vector2(cos(angle), sin(angle)) * radius)

	draw_polyline(points, color, width, true)
	if points.size() > 0:
		draw_circle(points[0], width * 0.5, color)
		draw_circle(points[points.size() - 1], width * 0.5, color)


func _variant_start_angle() -> float:
	match variant_index:
		1:
			return -0.92
		2:
			return -0.68
		3:
			return -0.84
		4:
			return -0.76
		_:
			return -0.78


func _variant_sweep_angle() -> float:
	match variant_index:
		1:
			return 1.48
		2:
			return 1.62
		3:
			return 1.42
		4:
			return 1.55
		_:
			return 1.52


func _variant_outer_radius() -> float:
	match variant_index:
		1:
			return 78.0
		2:
			return 88.0
		3:
			return 82.0
		4:
			return 92.0
		_:
			return 84.0


func _variant_inner_radius() -> float:
	match variant_index:
		1:
			return 52.0
		2:
			return 58.0
		3:
			return 50.0
		4:
			return 62.0
		_:
			return 56.0


func _with_alpha(color: Color, alpha_multiplier: float) -> Color:
	return Color(color.r, color.g, color.b, color.a * clampf(alpha_multiplier, 0.0, 1.0))
