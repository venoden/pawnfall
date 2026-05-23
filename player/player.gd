extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal weapon_changed(weapon_id: StringName)
signal died(source: StringName)

@export_category("Movement")
@export var move_speed := 180.0
@export var turn_smoothing := 12.0
@export var walk_cycle_rate := 12.5
@export var leg_swing := 0.58
@export var weapon_jiggle := 0.34

@export_category("Health")
@export var max_health := 100.0
@export var damage_invulnerability := 0.36

@export_category("Starter Weapon")
@export var starter_weapon_id: StringName = &"mace"
@export var mace_weapon_id: StringName = &"mace"
@export var starter_damage := 34.0
@export var starter_range := 112.0
@export var starter_spread_radians := 0.95
@export var starter_cooldown := 0.35
@export var starter_sweep_scene: PackedScene = preload("res://player/AttackSweep.tscn")

@export_category("Crossbow")
@export var crossbow_weapon_id: StringName = &"crossbow"
@export var crossbow_damage := 28.0
@export var crossbow_cooldown := 0.58
@export var crossbow_burn_damage_per_spike := 9.0
@export var crossbow_burn_spike_count := 5
@export var blunt_projectile_scene: PackedScene = preload("res://player/BluntProjectile.tscn")

@export_category("Targeting")
@export var facing_detection_radius := 720.0
@export_flags_2d_physics var auto_aim_block_mask: int = 1

@onready var visual: Node2D = $Visual
@onready var leg_left: Sprite2D = $Visual/LegLeft
@onready var leg_right: Sprite2D = $Visual/LegRight
@onready var weapon_sprite: Sprite2D = $Visual/WeaponSprite

const MACE_TEXTURE := preload("res://sprites/mace.png")
const BLUNTBOW_TEXTURE := preload("res://sprites/bluntbow.png")
const MACE_REGION := Rect2(638, 370, 272, 238)
const BLUNTBOW_REGION := Rect2(170, 330, 590, 360)
const STARTER_SWEEP_VARIANT_COUNT := 5

var current_health := 100.0
var weapon_id: StringName
var facing := Vector2.RIGHT
var attack_timer := 0.0
var invulnerability_timer := 0.0
var walk_timer := 0.0
var is_walking := false
var dead := false
var starter_sweep_variant: int = 0
var mace_swing_side := -1
var mace_swing_visual_timer := 0.0
var mace_swing_visual_side := -1
var last_damage_source: StringName = &""


func _ready() -> void:
	_ensure_input_map()
	current_health = max_health
	set_weapon(starter_weapon_id)
	health_changed.emit(current_health, max_health)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if mouse_event.pressed else Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if dead:
		return

	attack_timer = maxf(0.0, attack_timer - delta)
	mace_swing_visual_timer = maxf(0.0, mace_swing_visual_timer - delta)
	invulnerability_timer = maxf(0.0, invulnerability_timer - delta)

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	is_walking = input_vector.length() > 0.05
	if is_walking:
		walk_timer += delta * walk_cycle_rate
	velocity = input_vector * move_speed
	move_and_slide()

	_update_auto_aim(input_vector)
	_update_visuals(delta)

	if Input.is_action_pressed("attack"):
		_try_attack()


func apply_health_pickup(heal_amount: float, max_health_bonus: float) -> void:
	max_health += max_health_bonus
	current_health = minf(max_health, current_health + heal_amount)
	health_changed.emit(current_health, max_health)


func set_weapon(new_weapon_id: StringName) -> void:
	weapon_id = new_weapon_id
	if weapon_id == crossbow_weapon_id:
		weapon_sprite.texture = _atlas_texture(BLUNTBOW_TEXTURE, BLUNTBOW_REGION)
		weapon_sprite.scale = Vector2(0.16, 0.16)
	else:
		weapon_sprite.texture = _atlas_texture(MACE_TEXTURE, MACE_REGION)
		weapon_sprite.scale = Vector2(0.36, 0.36)
	weapon_changed.emit(weapon_id)


func weapon_display_name() -> String:
	if weapon_id == mace_weapon_id:
		return "Mace"
	return "Bluntbow"


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture


func take_damage(amount: float, source: StringName = &"", use_invulnerability := true) -> void:
	if dead:
		return
	if use_invulnerability and invulnerability_timer > 0.0:
		return

	last_damage_source = source
	current_health = maxf(0.0, current_health - amount)
	if use_invulnerability:
		invulnerability_timer = damage_invulnerability
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		dead = true
		velocity = Vector2.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		died.emit(last_damage_source)


func _try_attack() -> void:
	if attack_timer > 0.0:
		return

	if weapon_id == crossbow_weapon_id:
		attack_timer = crossbow_cooldown
		_fire_crossbow()
		return

	attack_timer = starter_cooldown
	_melee_attack()


func _melee_attack() -> void:
	var swing_side: int = mace_swing_side
	mace_swing_side *= -1
	mace_swing_visual_timer = starter_cooldown
	mace_swing_visual_side = swing_side
	var attack_direction: Vector2 = facing.rotated(float(swing_side) * 0.38)
	_spawn_starter_sweep(attack_direction, swing_side)
	for target in get_tree().get_nodes_in_group("hostiles"):
		if not is_instance_valid(target) or not (target is Node2D) or not target.has_method("take_damage"):
			continue
		var target_node: Node2D = target as Node2D
		var to_target: Vector2 = target_node.global_position - global_position
		if to_target.length() > starter_range:
			continue
		if absf(attack_direction.angle_to(to_target.normalized())) > starter_spread_radians:
			continue
		if not _has_line_of_sight_to(target_node):
			continue
		target_node.call("take_damage", starter_damage, &"starter")
		if target_node.has_method("apply_mace_hit_reaction"):
			target_node.call("apply_mace_hit_reaction", attack_direction, 48.0)


func _spawn_starter_sweep(attack_direction: Vector2, swing_side: int) -> void:
	if starter_sweep_scene == null:
		return
	var sweep: AttackSweep = starter_sweep_scene.instantiate() as AttackSweep
	if sweep == null:
		return
	sweep.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().current_scene.add_child(sweep)
	sweep.global_position = global_position
	sweep.setup(attack_direction, starter_sweep_variant, swing_side)
	starter_sweep_variant = (starter_sweep_variant + 1) % STARTER_SWEEP_VARIANT_COUNT


func _fire_crossbow() -> void:
	var projectile: Node2D = blunt_projectile_scene.instantiate() as Node2D
	if projectile == null:
		return
	projectile.process_mode = Node.PROCESS_MODE_PAUSABLE
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + facing * 36.0
	projectile.call("setup", facing, crossbow_damage, crossbow_burn_damage_per_spike, crossbow_burn_spike_count, "player")


func _update_auto_aim(input_vector: Vector2) -> void:
	var target: Node2D = _nearest_hostile()
	if target != null:
		var to_target: Vector2 = target.global_position - global_position
		if to_target.length_squared() > 0.001:
			facing = to_target.normalized()
	elif input_vector.length() > 0.05:
		facing = input_vector.normalized()


func _nearest_hostile() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance_squared: float = INF
	var max_distance: float = _auto_aim_range_for_weapon()
	var max_distance_squared: float = max_distance * max_distance
	for target in get_tree().get_nodes_in_group("hostiles"):
		if not is_instance_valid(target) or not (target is Node2D):
			continue
		var target_node: Node2D = target as Node2D
		var distance_squared: float = global_position.distance_squared_to(target_node.global_position)
		if distance_squared > max_distance_squared:
			continue
		if distance_squared >= nearest_distance_squared:
			continue
		if not _has_line_of_sight_to(target_node):
			continue
		nearest_distance_squared = distance_squared
		nearest = target_node
	return nearest


func _auto_aim_range_for_weapon() -> float:
	return facing_detection_radius


func _has_line_of_sight_to(target_node: Node2D) -> bool:
	if auto_aim_block_mask <= 0:
		return true

	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, target_node.global_position)
	query.collision_mask = auto_aim_block_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return true

	var collider: Object = result.get("collider") as Object
	return collider == target_node


func _update_visuals(delta: float) -> void:
	var target_rotation: float = facing.angle() + PI / 2.0
	visual.rotation = lerp_angle(visual.rotation, target_rotation, _turn_blend(delta))
	var leg_phase: float = walk_timer if is_walking else 0.0
	leg_left.rotation = sin(leg_phase) * leg_swing
	leg_right.rotation = sin(leg_phase + PI) * leg_swing
	leg_left.position.y = 18.0 + sin(leg_phase) * 3.0
	leg_right.position.y = 18.0 + sin(leg_phase + PI) * 3.0

	var flop := 0.0
	var bob := 0.0
	if is_walking:
		flop = sin(walk_timer * 1.45) * weapon_jiggle + sin(walk_timer * 2.7) * 0.08
		bob = sin(walk_timer * 1.1) * 2.8

	if weapon_id == crossbow_weapon_id:
		weapon_sprite.position = Vector2(28.0, bob * 0.35)
		weapon_sprite.rotation = -PI / 2.0 + flop * 0.18
	else:
		var swing_amount := 0.0
		if mace_swing_visual_timer > 0.0:
			var swing_progress: float = 1.0 - mace_swing_visual_timer / starter_cooldown
			swing_amount = sin(clampf(swing_progress, 0.0, 1.0) * PI) * float(mace_swing_visual_side)
		weapon_sprite.position = Vector2(24.0, 12.0 + bob + swing_amount * 4.0)
		weapon_sprite.rotation = -0.82 + flop * 0.42 + swing_amount * 0.64


func _turn_blend(delta: float) -> float:
	return clampf(1.0 - exp(-turn_smoothing * delta), 0.0, 1.0)


func _ensure_input_map() -> void:
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("attack", [KEY_SPACE])
	_add_mouse_action("attack", MOUSE_BUTTON_LEFT)
	_add_joy_axis_action("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis_action("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis_action("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis_action("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button_action("attack", JOY_BUTTON_A)


func _add_key_action(action: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
		for keycode in keycodes:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)


func _add_mouse_action(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)


func _add_joy_axis_action(action: StringName, axis: int, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)


func _add_joy_button_action(action: StringName, button: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
