extends Area2D

@export var owner_id := "player"
@export var speed := 430.0
@export var damage := 24.0
@export var burn_damage_per_spike := 0.0
@export var burn_spike_count := 0
@export var lifetime := 2.0
@export var collision_radius := 8.0

var direction := Vector2.RIGHT


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(new_direction: Vector2, new_damage: float, new_burn_damage_per_spike: float, new_burn_spike_count: int, new_owner_id: String) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	burn_damage_per_spike = new_burn_damage_per_spike
	burn_spike_count = new_burn_spike_count
	owner_id = new_owner_id
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var next_position := global_position + direction * speed * delta
	if _blocked_by_static_body(global_position, next_position):
		queue_free()
		return
	if owner_id == "boss" and _blocked_by_ward(next_position):
		queue_free()
		return

	global_position = next_position


func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		queue_free()
		return

	if owner_id == "player":
		if body.is_in_group("hostiles") and body.has_method("take_damage"):
			body.call("take_damage", damage, &"blunt")
			if body.has_method("ignite"):
				body.call("ignite", burn_damage_per_spike, burn_spike_count)
			queue_free()
		return

	if owner_id == "boss" and body.is_in_group("player") and body.has_method("take_damage"):
		body.call("take_damage", damage, &"boss_projectile")
		queue_free()


func _blocked_by_ward(position_to_check: Vector2) -> bool:
	for blocker in get_tree().get_nodes_in_group("hostile_blockers"):
		if blocker.has_method("blocks_hostile_position") and blocker.blocks_hostile_position(position_to_check, collision_radius):
			return true
	return false


func _blocked_by_static_body(from_position: Vector2, to_position: Vector2) -> bool:
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from_position, to_position)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true

	var result: Dictionary = space_state.intersect_ray(query)
	if result.is_empty():
		return false

	var collider: Object = result.get("collider") as Object
	return collider is StaticBody2D
