extends CanvasLayer

signal again_requested
signal bye_requested
signal restart_requested

var player_bar: ProgressBar
var player_value: Label
var boss_bar: ProgressBar
var boss_value: Label
var weapon_icon: TextureRect
var enemy_value: Label
var overlay: Control
var overlay_title: Label
var boss_kill_pose: TextureRect
var again_button: Button
var bye_button: Button
var restart_button: Button

const BOSS_KILL_POSE_TEXTURE := preload("res://sprites/goblin_boss1.png")
const MACE_TEXTURE := preload("res://sprites/mace.png")
const BLUNTBOW_TEXTURE := preload("res://sprites/bluntbow.png")
const MACE_REGION := Rect2(638, 370, 272, 238)
const BLUNTBOW_REGION := Rect2(170, 330, 590, 360)


func _ready() -> void:
	_build_hud()
	show_gameplay()


func set_player_health(current: float, maximum: float) -> void:
	player_bar.max_value = maximum
	player_bar.value = clampf(current, 0.0, maximum)
	player_value.text = "%d/%d" % [ceil(player_bar.value), int(maximum)]


func set_boss_health(current: float, maximum: float) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = clampf(current, 0.0, maximum)
	boss_value.text = "%d/%d" % [ceil(boss_bar.value), int(maximum)]


func set_weapon(weapon_id: StringName) -> void:
	if weapon_id == &"mace":
		weapon_icon.texture = _atlas_texture(MACE_TEXTURE, MACE_REGION)
	else:
		weapon_icon.texture = _atlas_texture(BLUNTBOW_TEXTURE, BLUNTBOW_REGION)


func set_enemy_defeated_count(count: int) -> void:
	enemy_value.text = str(count)


func show_gameplay() -> void:
	overlay.visible = false
	boss_kill_pose.visible = false


func show_victory() -> void:
	overlay_title.text = "Victory"
	overlay.visible = true
	boss_kill_pose.visible = false
	again_button.visible = true
	bye_button.visible = true
	restart_button.visible = false


func show_defeat(source: StringName = &"") -> void:
	overlay_title.text = "Defeated"
	overlay.visible = true
	boss_kill_pose.visible = source == &"boss_club"
	again_button.visible = false
	bye_button.visible = true
	restart_button.visible = true


func _build_hud() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top_panel := PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.anchor_left = 0.5
	top_panel.anchor_right = 0.5
	top_panel.offset_left = -330.0
	top_panel.offset_right = 330.0
	top_panel.offset_top = 12.0
	top_panel.offset_bottom = 60.0
	root.add_child(top_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	top_panel.add_child(row)

	_create_meter(row, "HP", true)
	_create_meter(row, "Boss", false)

	var weapon_panel := PanelContainer.new()
	weapon_panel.custom_minimum_size = Vector2(58, 32)
	row.add_child(weapon_panel)
	weapon_icon = _make_icon_rect(Vector2(42, 26))
	weapon_icon.texture = _atlas_texture(MACE_TEXTURE, MACE_REGION)
	weapon_panel.add_child(weapon_icon)

	var enemy_panel := PanelContainer.new()
	enemy_panel.custom_minimum_size = Vector2(58, 32)
	row.add_child(enemy_panel)
	enemy_value = Label.new()
	enemy_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_value.text = "0"
	enemy_panel.add_child(enemy_value)

	overlay = Control.new()
	overlay.name = "EndOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.06, 0.07, 0.68)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	var center := VBoxContainer.new()
	center.anchor_left = 0.5
	center.anchor_right = 0.5
	center.anchor_top = 0.5
	center.anchor_bottom = 0.5
	center.offset_left = -180.0
	center.offset_right = 180.0
	center.offset_top = -170.0
	center.offset_bottom = 170.0
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 14)
	overlay.add_child(center)

	overlay_title = Label.new()
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 42)
	center.add_child(overlay_title)

	boss_kill_pose = TextureRect.new()
	boss_kill_pose.texture = BOSS_KILL_POSE_TEXTURE
	boss_kill_pose.custom_minimum_size = Vector2(164, 164)
	boss_kill_pose.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	boss_kill_pose.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_kill_pose.visible = false
	center.add_child(boss_kill_pose)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	center.add_child(buttons)

	again_button = _make_button("AGAIN!")
	bye_button = _make_button("I quit.")
	restart_button = _make_button("AGAIN!")
	buttons.add_child(again_button)
	buttons.add_child(restart_button)
	buttons.add_child(bye_button)

	again_button.pressed.connect(func() -> void: again_requested.emit())
	bye_button.pressed.connect(func() -> void: bye_requested.emit())
	restart_button.pressed.connect(func() -> void: restart_requested.emit())


func _create_meter(parent: Control, title: String, is_player: bool) -> void:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(190, 32)
	parent.add_child(box)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	box.add_child(label)

	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(180, 18)
	bar.show_percentage = false
	box.add_child(bar)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.add_theme_font_size_override("font_size", 11)
	bar.add_child(value)
	value.set_anchors_preset(Control.PRESET_FULL_RECT)

	if is_player:
		player_bar = bar
		player_value = value
	else:
		boss_bar = bar
		boss_value = value


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(96, 40)
	return button


func _make_icon_rect(minimum_size: Vector2) -> TextureRect:
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = minimum_size
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return icon


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture
