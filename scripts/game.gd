extends Node2D

@export var level_scene: PackedScene

@onready var hud: Node = $HUD

var level: Node
var player: Node
var boss: Node
var run_finished := false


func _ready() -> void:
	level = $DungeonLevel
	hud.connect("again_requested", Callable(self, "reset_run"))
	hud.connect("restart_requested", Callable(self, "reset_run"))
	hud.connect("bye_requested", Callable(self, "_on_bye_requested"))
	await get_tree().process_frame
	_wire_current_level()


func reset_run() -> void:
	run_finished = false
	hud.call("show_gameplay")
	if is_instance_valid(level):
		level.queue_free()
		await get_tree().process_frame

	level = level_scene.instantiate() as Node
	level.name = "DungeonLevel"
	add_child(level)
	move_child(level, 0)
	await get_tree().process_frame
	_wire_current_level()


func _wire_current_level() -> void:
	player = get_tree().get_first_node_in_group("player") as Node
	boss = get_tree().get_first_node_in_group("boss") as Node

	if player:
		player.connect("health_changed", Callable(hud, "set_player_health"))
		player.connect("weapon_changed", Callable(hud, "set_weapon"))
		player.connect("died", Callable(self, "_on_player_died"))
		hud.call("set_player_health", player.get("current_health"), player.get("max_health"))
		hud.call("set_weapon", player.get("weapon_id"))

	if boss:
		boss.connect("health_changed", Callable(hud, "set_boss_health"))
		boss.connect("defeated", Callable(self, "_on_boss_defeated"))
		hud.call("set_boss_health", boss.get("current_health"), boss.get("max_health"))

	hud.call("set_enemy_defeated_count", 0)
	if level and level.has_signal("enemy_defeated_count_changed"):
		level.connect("enemy_defeated_count_changed", Callable(hud, "set_enemy_defeated_count"))


func _on_player_died(source: StringName = &"") -> void:
	if run_finished:
		return
	run_finished = true
	hud.call("show_defeat", source)


func _on_boss_defeated() -> void:
	if run_finished:
		return
	run_finished = true
	hud.call("show_victory")


func _on_bye_requested() -> void:
	get_tree().quit()
