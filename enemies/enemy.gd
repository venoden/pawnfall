extends CharacterBody2D

signal died(enemy: Node)

@export_category("Stats")
@export var max_health := 70.0
@export var move_speed := 190.0
@export var contact_damage := 9.0
@export var attack_interval := 0.72
@export var detection_radius := 510.0
@export var collision_radius := 17.0
@export var contact_padding := 8.0

@export_category("Visuals")
@export var turn_smoothing := 9.0
@export var hit_flash_duration := 0.14
@export var walk_turn_rate := 8.0
@export var walk_turn_amount := 0.065
@export var sprite_rotation_offset := PI

@export_category("Burn")
@export var burn_feedback_interval := 0.72
@export var burn_spike_interval := 1.0
@export var max_burn_spikes := 5

@onready var sprite: Sprite2D = $Sprite2D

var current_health := 70.0
var player: Node2D
var attack_timer := 0.0
var burn_spike_damage := 0.0
var burn_spikes_remaining := 0
var burn_spike_timer := 0.0
var burn_feedback_timer := 0.0
var dead := false
var wander_angle := 0.0
var facing := Vector2.DOWN
var hit_flash_timer := 0.0
var walk_turn_timer := 0.0
var walk_turn_sway := 0.0


func _ready() -> void:
	current_health = max_health
	wander_angle = randf() * TAU
	player = get_tree().get_first_node_in_group("player") as Node2D
	sprite.rotation = sprite_rotation_offset


func _physics_process(delta: float) -> void:
	if dead:
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	_update_hit_flash(delta)
	_update_burn(delta)
	if dead:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if not player:
			return

	var to_player := player.global_position - global_position
	var distance_to_player := to_player.length()
	var desired := Vector2.ZERO
	if distance_to_player < detection_radius and distance_to_player > 1.0:
		desired = to_player.normalized()
	else:
		wander_angle += sin(Time.get_ticks_msec() * 0.001 + global_position.x) * delta * 0.4
		desired = Vector2(cos(wander_angle), sin(wander_angle)) * 0.25

	if desired.length() > 0.0:
		var desired_direction: Vector2 = desired.normalized()
		walk_turn_timer += delta * walk_turn_rate
		walk_turn_sway = sin(walk_turn_timer) * walk_turn_amount
		_update_facing(desired_direction, delta)
		var next_position := global_position + desired_direction * move_speed * delta
		velocity = desired_direction * move_speed if not _blocked_by_ward(next_position) else Vector2.ZERO
		move_and_slide()
		distance_to_player = global_position.distance_to(player.global_position)
	else:
		walk_turn_sway = lerpf(walk_turn_sway, 0.0, _turn_blend(delta))

	if distance_to_player <= _contact_damage_radius() and attack_timer <= 0.0:
		if not _player_inside_ward():
			player.call("take_damage", contact_damage, "enemy")
		attack_timer = attack_interval


func take_damage(amount: float, _source := "") -> void:
	if dead:
		return
	_start_hit_flash()
	current_health = maxf(0.0, current_health - amount)
	if current_health <= 0.0:
		_die()


func ignite(damage_per_spike: float, spike_count: int) -> void:
	if damage_per_spike <= 0.0 or spike_count <= 0:
		return
	if damage_per_spike > 6.0:
		damage_per_spike = 5.0
	var requested_spikes: int = mini(max_burn_spikes, spike_count)
	if burn_spikes_remaining <= 0:
		burn_spike_timer = maxf(0.05, burn_spike_interval)
	else:
		burn_spike_timer = minf(burn_spike_timer, maxf(0.05, burn_spike_interval))
	burn_spike_damage = damage_per_spike
	burn_spikes_remaining = maxi(burn_spikes_remaining, requested_spikes)
	burn_feedback_timer = 0.0


func apply_knockback(force: Vector2) -> void:
	var next_position := global_position + force * 0.08
	if not _blocked_by_ward(next_position):
		global_position = next_position


func apply_mace_knockback(swing_side: int, force: float) -> void:
	var side: float = -1.0 if swing_side < 0 else 1.0
	apply_knockback(Vector2(side * force, 0.0))


func apply_mace_hit_reaction(hit_direction: Vector2, force: float) -> void:
	var direction: Vector2 = hit_direction.normalized()
	if direction.length_squared() <= 0.001:
		direction = facing
	apply_knockback(direction * force)


func _start_hit_flash() -> void:
	hit_flash_timer = hit_flash_duration
	sprite.modulate = Color(1.0, 0.28, 0.28)


func _update_hit_flash(delta: float) -> void:
	if hit_flash_timer <= 0.0:
		return
	hit_flash_timer = maxf(0.0, hit_flash_timer - delta)
	if hit_flash_timer <= 0.0:
		sprite.modulate = Color.WHITE


func _update_facing(direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.001:
		return
	facing = direction.normalized()
	var target_rotation: float = facing.angle() + PI / 2.0
	target_rotation += sprite_rotation_offset + walk_turn_sway
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, _turn_blend(delta))


func _turn_blend(delta: float) -> float:
	return clampf(1.0 - exp(-turn_smoothing * delta), 0.0, 1.0)


func _player_contact_radius() -> float:
	if not is_instance_valid(player):
		return 24.0
	var collision_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape == null or collision_shape.shape == null:
		return 24.0
	if collision_shape.shape is CircleShape2D:
		var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
		return circle_shape.radius
	return 24.0


func _contact_damage_radius() -> float:
	return collision_radius + _player_contact_radius() + contact_padding


func _update_burn(delta: float) -> void:
	if burn_spikes_remaining <= 0:
		return
	burn_spike_timer -= delta
	burn_feedback_timer = maxf(0.0, burn_feedback_timer - delta)

	var interval: float = maxf(0.05, burn_spike_interval)
	while burn_spike_timer <= 0.0 and burn_spikes_remaining > 0:
		burn_spike_timer += interval
		burn_spikes_remaining -= 1
		take_damage(burn_spike_damage, "burn")
		burn_feedback_timer = burn_feedback_interval
		if dead:
			return


func _die() -> void:
	dead = true
	died.emit(self)
	queue_free()


func _blocked_by_ward(position_to_check: Vector2) -> bool:
	for blocker in get_tree().get_nodes_in_group("hostile_blockers"):
		if blocker.has_method("blocks_hostile_position") and blocker.blocks_hostile_position(position_to_check, collision_radius):
			return true
	return false


func _player_inside_ward() -> bool:
	for blocker in get_tree().get_nodes_in_group("hostile_blockers"):
		if blocker.has_method("contains_player") and blocker.contains_player(player.global_position):
			return true
	return false
