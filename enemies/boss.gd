extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal defeated

@export_category("Stats")
@export var max_health := 360.0
@export var move_speed := 46.0
@export var club_hits_to_kill := 3
@export var contact_interval := 1.05
@export var collision_radius := 58.0
@export var reflect_damage_percent := 0.05
@export var reflected_damage_sources: Array[StringName] = [&"starter", &"blunt", &"burn"]

@export_category("Visuals")
@export var turn_smoothing := 7.5

@export_category("Burn")
@export var burn_feedback_interval := 0.72
@export var burn_spike_interval := 1.0
@export var max_burn_spikes := 5

@onready var sprite: Sprite2D = $Sprite2D

var current_health := 360.0
var player: Node2D
var contact_timer := 0.0
var burn_spike_damage := 0.0
var burn_spikes_remaining := 0
var burn_spike_timer := 0.0
var burn_feedback_timer := 0.0
var dead := false
var facing := Vector2.DOWN


func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player") as Node2D
	health_changed.emit(current_health, max_health)


func _physics_process(delta: float) -> void:
	if dead:
		return

	_update_burn(delta)
	if dead:
		return

	contact_timer = maxf(0.0, contact_timer - delta)

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D
		if not player:
			return

	var to_player := player.global_position - global_position
	var distance_to_player := to_player.length()
	if distance_to_player > 1.0:
		var direction := to_player.normalized()
		var next_position := global_position + direction * move_speed * delta
		velocity = direction * move_speed if not _blocked_by_ward(next_position) else Vector2.ZERO
		move_and_slide()
		_update_facing(direction, delta)

	if distance_to_player <= collision_radius + 28.0 and contact_timer <= 0.0:
		if not _player_inside_ward():
			player.call("take_damage", _club_damage_for_player(), &"boss_club")
		contact_timer = contact_interval


func take_damage(amount: float, source: StringName = &"") -> void:
	if dead:
		return
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	_reflect_damage(amount, source)
	if current_health <= 0.0:
		_die()


func ignite(damage_per_spike: float, spike_count: int) -> void:
	if damage_per_spike <= 0.0 or spike_count <= 0:
		return
	var requested_spikes: int = mini(max_burn_spikes, spike_count)
	if burn_spikes_remaining <= 0:
		burn_spike_timer = maxf(0.05, burn_spike_interval)
	else:
		burn_spike_timer = minf(burn_spike_timer, maxf(0.05, burn_spike_interval))
	burn_spike_damage = damage_per_spike
	burn_spikes_remaining = maxi(burn_spikes_remaining, requested_spikes)
	burn_feedback_timer = 0.0


func apply_knockback(force: Vector2) -> void:
	var next_position := global_position + force * 0.04
	if not _blocked_by_ward(next_position):
		global_position = next_position


func _update_facing(direction: Vector2, delta: float) -> void:
	if direction.length_squared() <= 0.001:
		return
	facing = direction.normalized()
	var target_rotation: float = facing.angle() + PI / 2.0
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, _turn_blend(delta))


func _turn_blend(delta: float) -> float:
	return clampf(1.0 - exp(-turn_smoothing * delta), 0.0, 1.0)


func _club_damage_for_player() -> float:
	if not is_instance_valid(player):
		return 0.0
	var player_max_health: Variant = player.get("max_health")
	if not (player_max_health is float) and not (player_max_health is int):
		return 0.0
	return float(player_max_health) / float(maxi(1, club_hits_to_kill))


func _reflect_damage(amount: float, source: StringName) -> void:
	if amount <= 0.0 or reflect_damage_percent <= 0.0:
		return
	if not reflected_damage_sources.has(source):
		return
	if not is_instance_valid(player) or not player.has_method("take_damage"):
		return
	player.call("take_damage", amount * reflect_damage_percent, &"boss_reflect", false)


func _update_burn(delta: float) -> void:
	if burn_spikes_remaining <= 0:
		return
	burn_spike_timer -= delta
	burn_feedback_timer = maxf(0.0, burn_feedback_timer - delta)

	var interval: float = maxf(0.05, burn_spike_interval)
	while burn_spike_timer <= 0.0 and burn_spikes_remaining > 0:
		burn_spike_timer += interval
		burn_spikes_remaining -= 1
		take_damage(burn_spike_damage, &"burn")
		burn_feedback_timer = burn_feedback_interval
		if dead:
			return


func _die() -> void:
	dead = true
	defeated.emit()
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
