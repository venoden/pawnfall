extends Node2D

@export var level_scene: PackedScene

@onready var hud: Node = $HUD

var level: Node
var player: Node
var boss: Node
var run_finished := false
var paused_by_menu := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	level = $DungeonLevel
	_set_gameplay_branch_pausable()
	hud.connect("again_requested", Callable(self, "reset_run"))
	hud.connect("restart_requested", Callable(self, "reset_run"))
	hud.connect("bye_requested", Callable(self, "_on_bye_requested"))
	hud.connect("resume_requested", Callable(self, "_on_resume_requested"))
	await get_tree().process_frame
	_wire_current_level()


func _unhandled_input(event: InputEvent) -> void:
	if run_finished:
		return
	if event.is_action_pressed("pause"):
		if paused_by_menu:
			_resume_gameplay()
		else:
			_pause_gameplay()
		get_viewport().set_input_as_handled()


func reset_run() -> void:
	get_tree().paused = false
	paused_by_menu = false
	run_finished = false
	hud.call("show_gameplay")
	if is_instance_valid(level):
		level.queue_free()
		await get_tree().process_frame

	level = level_scene.instantiate() as Node
	level.name = "DungeonLevel"
	level.process_mode = Node.PROCESS_MODE_PAUSABLE
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
	paused_by_menu = false
	get_tree().paused = true
	hud.call("show_defeat", source)


func _on_boss_defeated() -> void:
	if run_finished:
		return
	run_finished = true
	paused_by_menu = false
	get_tree().paused = true
	hud.call("show_victory")


func _pause_gameplay() -> void:
	paused_by_menu = true
	_set_gameplay_branch_pausable()
	get_tree().paused = true
	hud.call("show_pause")


func _resume_gameplay() -> void:
	get_tree().paused = false
	paused_by_menu = false
	hud.call("show_gameplay")


func _on_resume_requested() -> void:
	if paused_by_menu:
		_resume_gameplay()


func _on_bye_requested() -> void:
	get_tree().paused = false
	get_tree().quit()


func _set_gameplay_branch_pausable() -> void:
	if is_instance_valid(level):
		level.process_mode = Node.PROCESS_MODE_PAUSABLE
