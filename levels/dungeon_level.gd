extends Node2D

signal enemy_defeated_count_changed(count: int)

@export_category("Scenes")
@export var player_scene: PackedScene = preload("res://player/Player.tscn")
@export var enemy_scene: PackedScene = preload("res://enemies/Enemy.tscn")
@export var boss_scene: PackedScene = preload("res://enemies/Boss.tscn")
@export var pickup_scene: PackedScene = preload("res://scenes/Pickup.tscn")
@export var torch_scene: PackedScene = preload("res://levels/Torch.tscn")

@export_category("Room")
@export var background_texture: Texture2D = preload("res://sprites/dungeon_background.png")
@export var room_size := Vector2(1536, 1024)
@export var tile_size := 72
@export var wall_thickness := 96.0
@export var obstacle_rects: Array[Rect2] = [
	Rect2(388, 24, 70, 112),
	Rect2(1062, 24, 70, 112),
	Rect2(388, 896, 70, 104),
	Rect2(1062, 896, 70, 104),
	Rect2(24, 442, 94, 118),
	Rect2(1418, 442, 94, 118),
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
	Vector2(300, 304),
	Vector2(590, 742),
	Vector2(860, 300),
	Vector2(1160, 742),
	Vector2(1072, 500),
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
@export var player_spawn := Vector2(160, 512)
@export var boss_spawn := Vector2(1380, 512)
@export var enemy_count := 5
@export var enemy_spawn_points: Array[Vector2] = [
	Vector2(420, 240),
	Vector2(520, 820),
	Vector2(760, 512),
	Vector2(1040, 270),
	Vector2(1180, 760),
	Vector2(1280, 380),
	Vector2(1280, 650),
]

@export_category("Pickups")
@export var health_pickup_points: Array[Vector2] = [
	Vector2(326, 742),
	Vector2(760, 274),
	Vector2(1168, 636),
]
@export var health_pickup_heal := 15.0
@export var health_pickup_max_bonus := 15.0

@export_category("Hazards")
@export var torch_burn_dps := 3.0
@export var torch_points: Array[Vector2] = [
	Vector2(210, 168),
	Vector2(210, 850),
	Vector2(668, 508),
	Vector2(974, 846),
	Vector2(1316, 210),
	Vector2(1316, 812),
]
@export var enemy_respawn_delay := 5.0
@export var bluntbow_drop_kill_count := 5

var player: Node2D
var boss: Node2D
var live_enemies: Array[Node] = []
var defeated_enemy_count := 0
var regular_goblin_kill_count := 0
var bluntbow_dropped := false
var boss_defeated := false


func _ready() -> void:
	randomize()
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

	var obstacle_total: int = mini(mini(obstacle_regions.size(), obstacle_positions.size()), obstacle_collision_sizes.size())
	for index in range(obstacle_total):
		_add_obstacle(index)


func _add_obstacle(index: int) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "DungeonObstacle"
	body.add_to_group("obstacles")
	body.global_position = obstacle_positions[index]
	add_child(body)

	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = obstacle_texture
	sprite.region_enabled = true
	sprite.region_rect = obstacle_regions[index]
	sprite.scale = Vector2(obstacle_visual_scale, obstacle_visual_scale)
	body.add_child(sprite)

	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = obstacle_collision_sizes[index]
	var collision: CollisionShape2D = CollisionShape2D.new()
	collision.position = _obstacle_collision_offset(index)
	collision.shape = shape
	body.add_child(collision)


func _obstacle_collision_offset(index: int) -> Vector2:
	if index < obstacle_collision_offsets.size():
		return obstacle_collision_offsets[index]
	return Vector2.ZERO


func _spawn_hazards() -> void:
	for point in torch_points:
		var torch: Node2D = torch_scene.instantiate() as Node2D
		torch.set("burn_dps", torch_burn_dps)
		torch.global_position = point
		add_child(torch)


func _spawn_pickups() -> void:
	for point in health_pickup_points:
		var pickup: Node2D = pickup_scene.instantiate() as Node2D
		pickup.call("configure_health", health_pickup_heal, health_pickup_max_bonus)
		add_child(pickup)
		pickup.global_position = point


func _spawn_player() -> void:
	player = player_scene.instantiate() as Node2D
	add_child(player)
	player.global_position = player_spawn
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(room_size.x)
		camera.limit_bottom = int(room_size.y)


func _spawn_boss() -> void:
	boss = boss_scene.instantiate() as Node2D
	add_child(boss)
	boss.global_position = boss_spawn
	if boss.has_signal("defeated"):
		boss.connect("defeated", Callable(self, "_on_boss_defeated"))


func _spawn_enemy(point: Vector2) -> void:
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	add_child(enemy)
	enemy.global_position = point
	if enemy.has_signal("died"):
		enemy.connect("died", Callable(self, "_on_enemy_died"))
	live_enemies.append(enemy)


func _on_enemy_died(enemy: Node) -> void:
	var enemy_node: Node2D = enemy as Node2D
	var drop_position: Vector2 = enemy_node.global_position if enemy_node != null else player_spawn
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
	var pickup: Node2D = pickup_scene.instantiate() as Node2D
	pickup.call("configure_weapon", &"crossbow")
	add_child(pickup)
	pickup.global_position = _nearest_walkable_pickup_point(point)


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
		if _point_is_walkable(candidate):
			return candidate
	return point


func _point_is_walkable(point: Vector2) -> bool:
	if point.x < wall_thickness or point.x > room_size.x - wall_thickness:
		return false
	if point.y < wall_thickness or point.y > room_size.y - wall_thickness:
		return false
	for obstacle in obstacle_rects:
		if obstacle.grow(32.0).has_point(point):
			return false
	for index in range(obstacle_positions.size()):
		var rect: Rect2 = Rect2(obstacle_positions[index] - obstacle_collision_sizes[index] * 0.5, obstacle_collision_sizes[index])
		rect.position += _obstacle_collision_offset(index)
		if rect.grow(32.0).has_point(point):
			return false
	return true


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
