extends Node2D

signal enemy_defeated_count_changed(count: int)

@export_category("Scenes")
@export var player_scene: PackedScene = preload("res://player/Player.tscn")
@export var enemy_scene: PackedScene = preload("res://enemies/Enemy.tscn")
@export var boss_scene: PackedScene = preload("res://enemies/Boss.tscn")
@export var pickup_scene: PackedScene = preload("res://scenes/Pickup.tscn")
@export var torch_scene: PackedScene = preload("res://levels/Torch.tscn")

@export_category("Room")
@export var background_texture: Texture2D = preload("res://sprites/dungeon_bg_lg.png")
@export var room_size := Vector2(1448, 1086)
@export var tile_size := 72
@export var wall_thickness := 72.0
@export var obstacle_rects: Array[Rect2] = [
]

@export_category("Obstacles")
@export var obstacle_texture: Texture2D = preload("res://sprites/5_dungeon.png")
@export var obstacle_regions: Array[Rect2] = [
	Rect2(96, 330, 190, 260),
	Rect2(352, 350, 196, 238),
	Rect2(604, 432, 194, 160),
	Rect2(846, 346, 250, 260),
	Rect2(1110, 462, 340, 150),
]
@export var obstacle_positions: Array[Vector2] = [
]
@export var obstacle_collision_sizes: Array[Vector2] = [
	Vector2(78, 104),
	Vector2(86, 94),
	Vector2(92, 54),
	Vector2(116, 100),
	Vector2(138, 44),
]
@export var obstacle_collision_offsets: Array[Vector2] = [
	Vector2(0, 24),
	Vector2(0, 18),
	Vector2(0, 26),
	Vector2(0, 34),
	Vector2(0, 28),
]
@export var obstacle_visual_scale := 0.52

@export_category("Spawns")
@export var player_spawn := Vector2(160, 543)
@export var boss_spawn := Vector2(1278, 543)
@export var enemy_count := 5
@export var enemy_spawn_points: Array[Vector2] = [
	Vector2(328, 252),
	Vector2(386, 822),
	Vector2(724, 318),
	Vector2(760, 758),
	Vector2(1058, 294),
	Vector2(1128, 812),
	Vector2(1244, 440),
]

@export_category("Pickups")
@export var health_pickup_points: Array[Vector2] = [
	Vector2(292, 700),
	Vector2(724, 266),
	Vector2(1118, 656),
]
@export var health_pickup_heal := 15.0
@export var health_pickup_max_bonus := 15.0

@export_category("Hazards")
@export var torch_burn_dps := 3.0
@export var torch_points: Array[Vector2] = [
	Vector2(184, 156),
	Vector2(184, 918),
	Vector2(528, 224),
	Vector2(914, 874),
	Vector2(1264, 190),
	Vector2(1264, 898),
]
@export var enemy_respawn_delay := 5.0
@export var bluntbow_drop_kill_count := 5
@export var placement_retry_count := 10

var player: Node2D
var boss: Node2D
var live_enemies: Array[Node] = []
var defeated_enemy_count := 0
var regular_goblin_kill_count := 0
var bluntbow_dropped := false
var boss_defeated := false
var obstacle_variant_indices: Array[int] = []
var placed_obstacle_indices: Array[int] = []
var reserved_points: Array[Vector2] = []
var reserved_radii: Array[float] = []


func _ready() -> void:
	randomize()
	reserved_points.clear()
	reserved_radii.clear()
	_create_collision()
	_spawn_obstacles()
	_spawn_hazards()
	_spawn_pickups()
	_spawn_player()
	_spawn_boss()
	for _index in range(enemy_count):
		_spawn_enemy(_best_spawn_point())
	enemy_defeated_count_changed.emit(defeated_enemy_count)
	queue_redraw()


func _draw() -> void:
	if background_texture != null:
		draw_texture(background_texture, Vector2.ZERO)
	else:
		draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.085, 0.095, 0.1))
		for x in range(0, int(room_size.x), tile_size):
			for y in range(0, int(room_size.y), tile_size):
				var tile_tone_index: int = int(x / tile_size + y / tile_size) % 3
				var tone: float = 0.11 + float(tile_tone_index) * 0.012
				draw_rect(Rect2(x, y, tile_size, tile_size), Color(tone, tone + 0.01, tone + 0.015))
				draw_rect(Rect2(x, y, tile_size, tile_size), Color(0.95, 0.88, 0.68, 0.045), false, 1.0)

		for rect in obstacle_rects:
			draw_rect(rect, Color(0.18, 0.2, 0.2))
			draw_rect(rect, Color(0.95, 0.88, 0.68, 0.13), false, 2.0)

		draw_rect(Rect2(Vector2.ZERO, room_size), Color(0.84, 0.7, 0.37, 0.26), false, 2.0)

func _create_collision() -> void:
	_add_wall_rect(Rect2(0, 0, room_size.x, wall_thickness))
	_add_wall_rect(Rect2(0, room_size.y - wall_thickness, room_size.x, wall_thickness))
	_add_wall_rect(Rect2(0, 0, wall_thickness, room_size.y))
	_add_wall_rect(Rect2(room_size.x - wall_thickness, 0, wall_thickness, room_size.y))

	for rect in obstacle_rects:
		_add_wall_rect(rect)


func _add_wall_rect(rect: Rect2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Wall"
	body.position = rect.position + rect.size * 0.5
	add_child(body)

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = rect.size
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)


func _spawn_obstacles() -> void:
	if obstacle_texture == null:
		return

	var obstacle_total: int = obstacle_positions.size()
	placed_obstacle_indices.clear()
	obstacle_variant_indices.clear()
	for index in range(obstacle_total):
		obstacle_variant_indices.append(index % maxi(1, obstacle_regions.size()))
	obstacle_variant_indices.shuffle()
	if obstacle_total >= 12:
		obstacle_variant_indices[10] = 0
		obstacle_variant_indices[11] = 1
	for index in range(obstacle_total):
		if _place_obstacle_position(index):
			_add_obstacle(index)
			placed_obstacle_indices.append(index)


func _add_obstacle(index: int) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "DungeonObstacle"
	body.add_to_group("obstacles")
	body.global_position = obstacle_positions[index]
	add_child(body)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = obstacle_texture
	sprite.region_enabled = true
	sprite.region_rect = _obstacle_region(index)
	sprite.scale = Vector2(obstacle_visual_scale, obstacle_visual_scale)
	body.add_child(sprite)

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = _obstacle_collision_size(index)
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.position = _obstacle_collision_offset(index)
	collision.shape = shape
	body.add_child(collision)


func _obstacle_collision_offset(index: int) -> Vector2:
	if not obstacle_collision_offsets.is_empty():
		var variant_index: int = _obstacle_variant_index(index)
		return obstacle_collision_offsets[variant_index % obstacle_collision_offsets.size()]
	return Vector2.ZERO


func _obstacle_region(index: int) -> Rect2:
	if not obstacle_regions.is_empty():
		return obstacle_regions[_obstacle_variant_index(index) % obstacle_regions.size()]
	return Rect2()


func _obstacle_collision_size(index: int) -> Vector2:
	if not obstacle_collision_sizes.is_empty():
		var variant_index: int = _obstacle_variant_index(index)
		return obstacle_collision_sizes[variant_index % obstacle_collision_sizes.size()]
	return Vector2(72, 72)


func _obstacle_variant_index(index: int) -> int:
	if index >= 0 and index < obstacle_variant_indices.size():
		return obstacle_variant_indices[index]
	return index


func _place_obstacle_position(index: int) -> bool:
	for candidate in _obstacle_candidate_positions(index):
		obstacle_positions[index] = candidate
		if _obstacle_position_is_safe(index):
			return true
	return false


func _obstacle_candidate_positions(index: int) -> Array[Vector2]:
	match index:
		0:
			return [Vector2(258, 238), Vector2(322, 310), Vector2(232, 342)]
		1:
			return [Vector2(520, 292), Vector2(470, 398), Vector2(604, 250)]
		2:
			return [Vector2(888, 252), Vector2(824, 350), Vector2(966, 306)]
		3:
			return [Vector2(1184, 302), Vector2(1108, 410), Vector2(1240, 404)]
		4:
			return [Vector2(292, 520), Vector2(376, 590), Vector2(260, 650)]
		5:
			return [Vector2(1128, 522), Vector2(1040, 590), Vector2(1216, 636)]
		6:
			return [Vector2(424, 788), Vector2(338, 744), Vector2(520, 836)]
		7:
			return [Vector2(704, 856), Vector2(634, 770), Vector2(776, 804)]
		8:
			return [Vector2(996, 786), Vector2(914, 846), Vector2(1082, 744)]
		9:
			return [Vector2(760, 420), Vector2(692, 476), Vector2(828, 492)]
		10:
			return [Vector2(548, 548), Vector2(492, 486), Vector2(584, 640)]
		11:
			return [Vector2(902, 606), Vector2(956, 532), Vector2(846, 674)]
		_:
			if index >= 0 and index < obstacle_positions.size():
				return [obstacle_positions[index]]
			return []


func _obstacle_position_is_safe(index: int) -> bool:
	var rect: Rect2 = _obstacle_collision_rect(index).grow(56.0)
	if rect.position.x < wall_thickness or rect.end.x > room_size.x - wall_thickness:
		return false
	if rect.position.y < wall_thickness or rect.end.y > room_size.y - wall_thickness:
		return false

	for spawn_point in _obstacle_protected_points():
		if rect.grow(36.0).has_point(spawn_point):
			return false

	for placed_index in placed_obstacle_indices:
		if rect.intersects(_obstacle_collision_rect(placed_index).grow(72.0)):
			return false
	return true


func _obstacle_collision_rect(index: int) -> Rect2:
	var collision_size: Vector2 = _obstacle_collision_size(index)
	var rect: Rect2 = Rect2(obstacle_positions[index] - collision_size * 0.5, collision_size)
	rect.position += _obstacle_collision_offset(index)
	return rect


func _protected_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = [player_spawn, boss_spawn]
	points.append_array(enemy_spawn_points)
	return points


func _obstacle_protected_points() -> Array[Vector2]:
	var points: Array[Vector2] = _protected_spawn_points()
	points.append_array(health_pickup_points)
	points.append_array(torch_points)
	return points


func _spawn_hazards() -> void:
	for point in torch_points:
		var safe_point: Vector2 = _find_safe_position(point, 34.0)
		if safe_point == Vector2.INF:
			continue
		var torch: Node2D = torch_scene.instantiate() as Node2D
		torch.set("burn_dps", torch_burn_dps)
		torch.global_position = safe_point
		add_child(torch)
		_reserve_point(safe_point, 44.0)


func _spawn_pickups() -> void:
	for point in health_pickup_points:
		var safe_point: Vector2 = _find_safe_position(point, 30.0)
		if safe_point == Vector2.INF:
			continue
		var pickup: Node2D = pickup_scene.instantiate() as Node2D
		pickup.call("configure_health", health_pickup_heal, health_pickup_max_bonus)
		add_child(pickup)
		pickup.global_position = safe_point
		_reserve_point(safe_point, 42.0)


func _spawn_player() -> void:
	player = player_scene.instantiate() as Node2D
	add_child(player)
	player.global_position = _find_safe_position(player_spawn, 44.0, true)
	if player.global_position == Vector2.INF:
		player.global_position = player_spawn
	_reserve_point(player.global_position, 72.0)
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(room_size.x)
		camera.limit_bottom = int(room_size.y)


func _spawn_boss() -> void:
	boss = boss_scene.instantiate() as Node2D
	add_child(boss)
	boss.global_position = _find_safe_position(boss_spawn, 92.0, true)
	if boss.global_position == Vector2.INF:
		boss.global_position = boss_spawn
	_reserve_point(boss.global_position, 108.0)
	if boss.has_signal("defeated"):
		boss.connect("defeated", Callable(self, "_on_boss_defeated"))
	boss.set("room_min", Vector2(wall_thickness, wall_thickness))
	boss.set("room_max", room_size - Vector2(wall_thickness, wall_thickness))


func _spawn_enemy(point: Vector2) -> void:
	var safe_point: Vector2 = _find_safe_position(point, 42.0, true)
	if safe_point == Vector2.INF:
		return
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	add_child(enemy)
	enemy.global_position = safe_point
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	live_enemies.append(enemy)
	enemy.set_meta("spawn_reserved_point", safe_point)
	_reserve_point(safe_point, 52.0)


func _on_enemy_died(enemy: Node) -> void:
	var enemy_node: Node2D = enemy as Node2D
	var drop_position: Vector2 = enemy_node.global_position if enemy_node != null else player_spawn
	if enemy.has_meta("spawn_reserved_point"):
		var reserved_point: Variant = enemy.get_meta("spawn_reserved_point")
		if reserved_point is Vector2:
			_release_point(reserved_point as Vector2)
	live_enemies.erase(enemy)
	defeated_enemy_count += 1
	regular_goblin_kill_count += 1
	if regular_goblin_kill_count == bluntbow_drop_kill_count and not bluntbow_dropped:
		_spawn_bluntbow_pickup(drop_position)
	if not boss_defeated and _current_enemy_count() < enemy_count:
		_queue_enemy_respawn()
	enemy_defeated_count_changed.emit(defeated_enemy_count)


func _on_boss_defeated() -> void:
	boss_defeated = true
	defeated_enemy_count += 1
	enemy_defeated_count_changed.emit(defeated_enemy_count)


func _current_enemy_count() -> int:
	live_enemies = live_enemies.filter(func(enemy: Node) -> bool: return is_instance_valid(enemy))
	return live_enemies.size()


func _queue_enemy_respawn() -> void:
	await get_tree().create_timer(enemy_respawn_delay, false).timeout
	if not is_inside_tree() or boss_defeated:
		return
	if _current_enemy_count() < enemy_count:
		_spawn_enemy(_best_spawn_point())


func _spawn_bluntbow_pickup(point: Vector2) -> void:
	bluntbow_dropped = true
	var safe_point: Vector2 = _nearest_walkable_pickup_point(point)
	if safe_point == Vector2.INF:
		return
	var pickup: Node2D = pickup_scene.instantiate() as Node2D
	pickup.call("configure_weapon", &"crossbow")
	add_child(pickup)
	pickup.global_position = safe_point
	_reserve_point(safe_point, 42.0)


func _nearest_walkable_pickup_point(point: Vector2) -> Vector2:
	var offsets: Array[Vector2] = [
		Vector2(42, 0),
		Vector2(-42, 0),
		Vector2(0, 42),
		Vector2(0, -42),
		Vector2(52, 52),
	]
	for offset in offsets:
		var candidate: Vector2 = point + offset
		if _point_is_walkable(candidate, 30.0) and not _position_is_reserved(candidate, 38.0):
			return candidate
	return _find_safe_position(point, 30.0)


func _point_is_walkable(point: Vector2, clearance := 0.0) -> bool:
	if point.x < wall_thickness + clearance or point.x > room_size.x - wall_thickness - clearance:
		return false
	if point.y < wall_thickness + clearance or point.y > room_size.y - wall_thickness - clearance:
		return false
	for obstacle in obstacle_rects:
		if obstacle.grow(32.0 + clearance).has_point(point):
			return false
	for index in placed_obstacle_indices:
		if _obstacle_collision_rect(index).grow(32.0 + clearance).has_point(point):
			return false
	return true


func _find_safe_position(preferred_point: Vector2, radius: float, allow_protected_spawn := false) -> Vector2:
	if _placement_is_safe(preferred_point, radius, allow_protected_spawn):
		return preferred_point

	var offsets: Array[Vector2] = [
		Vector2(72, 0),
		Vector2(-72, 0),
		Vector2(0, 72),
		Vector2(0, -72),
		Vector2(96, 72),
		Vector2(-96, 72),
		Vector2(96, -72),
		Vector2(-96, -72),
		Vector2(144, 0),
		Vector2(-144, 0),
	]
	var retry_total: int = mini(placement_retry_count, offsets.size())
	for index in range(retry_total):
		var candidate: Vector2 = preferred_point + offsets[index]
		if _placement_is_safe(candidate, radius, allow_protected_spawn):
			return candidate
	return Vector2.INF


func _placement_is_safe(point: Vector2, radius: float, allow_protected_spawn := false) -> bool:
	if not _point_is_walkable(point, radius):
		return false
	if not allow_protected_spawn and _near_protected_spawn(point, radius):
		return false
	return not _position_is_reserved(point, radius)


func _reserve_point(point: Vector2, radius: float) -> void:
	reserved_points.append(point)
	reserved_radii.append(radius)


func _release_point(point: Vector2) -> void:
	for index in range(reserved_points.size() - 1, -1, -1):
		if reserved_points[index].is_equal_approx(point):
			reserved_points.remove_at(index)
			reserved_radii.remove_at(index)
			return


func _position_is_reserved(point: Vector2, radius: float) -> bool:
	for index in range(reserved_points.size()):
		var reserved_radius: float = reserved_radii[index] if index < reserved_radii.size() else 0.0
		if point.distance_to(reserved_points[index]) < radius + reserved_radius:
			return true
	return false


func _near_protected_spawn(point: Vector2, radius: float) -> bool:
	for spawn_point in _protected_spawn_points():
		if point.distance_to(spawn_point) < radius + 48.0:
			return true
	return false


func _best_spawn_point() -> Vector2:
	var best_point: Vector2 = player_spawn
	if not enemy_spawn_points.is_empty():
		best_point = enemy_spawn_points[0]
	var best_distance := -1.0
	var reference_position: Vector2 = player.global_position if is_instance_valid(player) else player_spawn
	for point in enemy_spawn_points:
		var distance_to_player: float = point.distance_to(reference_position)
		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_point = point
	return best_point
