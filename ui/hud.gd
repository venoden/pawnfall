extends CanvasLayer

signal again_requested
signal bye_requested
signal menu_requested
signal restart_requested
signal resume_requested

var player_bar: ProgressBar
var player_value: Label
var boss_bar: ProgressBar
var boss_value: Label
var weapon_icon: TextureRect
var enemy_value: Label
var overlay: Control
var overlay_menu_root: Control
var overlay_title: Label
var overlay_title_sprite: TextureRect
var boss_kill_pose: TextureRect
var victory_pose: TextureRect
var resume_button: TextureButton
var menu_button: TextureButton
var settings_button: TextureButton
var bye_button: TextureButton

const BOSS_KILL_POSE_TEXTURE := preload("res://sprites/goblin_boss1.png")
const VICTORY_POSE_TEXTURE := preload("res://sprites/celerbatory_pawn.png")
const MACE_TEXTURE := preload("res://sprites/mace.png")
const BLUNTBOW_TEXTURE := preload("res://sprites/bluntbow.png")
const STONE_BUTTON_TEXTURE := preload("res://pawnfall/menu/stone_button.png")
const STONE_BUTTON_EXIT_TEXTURE := preload("res://pawnfall/menu/stone_button_exit.png")
const RESUME_TEXT_TEXTURE := preload("res://pawnfall/menu/resume_text.png")
const MENU_TEXT_TEXTURE := preload("res://pawnfall/menu/menu_button_text.png")
const SETTINGS_TEXT_TEXTURE := preload("res://pawnfall/menu/settings_button_text.png")
const EXIT_TEXT_TEXTURE := preload("res://pawnfall/menu/exit_button_text.png")
const PAUSED_TEXT_TEXTURE := preload("res://pawnfall/menu/paused_text.png")
const VICTORY_TEXT_TEXTURE := preload("res://pawnfall/menu/victory_text.png")
const DEFEAT_TEXT_TEXTURE := preload("res://pawnfall/menu/defeat_text.png")

const OVERLAY_MENU_SIZE := Vector2(1920.0, 1080.0)
const OVERLAY_BUTTON_SIZE := Vector2(430.0, 146.0)
const OVERLAY_BUTTON_TEXT_SCALE := 0.58995
const OVERLAY_EXIT_TEXT_SCALE := 0.621
const OVERLAY_BUTTON_GAP := 18.0
const OVERLAY_EXIT_BUTTON_EXTRA_GAP := 42.0
const PAUSE_TITLE_SIZE := Vector2(650.0, 216.0)
const END_TITLE_SIZE := Vector2(700.0, 248.0)
const END_POSE_SIZE := Vector2(300.0, 300.0)
const MACE_REGION := Rect2(638, 370, 272, 238)
const BLUNTBOW_REGION := Rect2(170, 330, 590, 360)
const STONE_BUTTON_REGION := Rect2(236, 324, 1064, 360)
const STONE_BUTTON_EXIT_REGION := Rect2(237, 309, 1061, 366)
const RESUME_TEXT_REGION := Rect2(406, 355, 726, 217)
const MENU_TEXT_REGION := Rect2(392, 324, 764, 266)
const SETTINGS_TEXT_REGION := Rect2(392, 352, 764, 238)
const EXIT_TEXT_REGION := Rect2(409, 365, 748, 171)
const PAUSED_TEXT_REGION := Rect2(420, 350, 690, 229)
const VICTORY_TEXT_REGION := Rect2(384, 349, 740, 256)
const DEFEAT_TEXT_REGION := Rect2(394, 332, 739, 355)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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
	overlay_title_sprite.visible = false
	resume_button.visible = false
	boss_kill_pose.visible = false
	victory_pose.visible = false


func show_victory() -> void:
	overlay.visible = true
	overlay_title.visible = false
	overlay_title_sprite.visible = true
	overlay_title_sprite.texture = _atlas_texture(VICTORY_TEXT_TEXTURE, VICTORY_TEXT_REGION)
	resume_button.visible = false
	boss_kill_pose.visible = false
	victory_pose.visible = true
	_layout_end_overlay_content()


func show_defeat(source: StringName = &"") -> void:
	overlay.visible = true
	overlay_title.visible = false
	overlay_title_sprite.visible = true
	overlay_title_sprite.texture = _atlas_texture(DEFEAT_TEXT_TEXTURE, DEFEAT_TEXT_REGION)
	resume_button.visible = false
	boss_kill_pose.visible = true
	victory_pose.visible = false
	_layout_end_overlay_content()


func show_pause() -> void:
	overlay.visible = true
	overlay_title.visible = false
	overlay_title_sprite.visible = true
	overlay_title_sprite.texture = _atlas_texture(PAUSED_TEXT_TEXTURE, PAUSED_TEXT_REGION)
	resume_button.visible = true
	boss_kill_pose.visible = false
	victory_pose.visible = false
	_layout_pause_overlay_content()


func _build_hud() -> void:
	var root := Control.new()
	root.name = "Root"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.resized.connect(_layout_overlay_menu_root)

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
	_create_meter(row, "Gobboss", false)

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
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.06, 0.07, 0.68)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)

	overlay_menu_root = Control.new()
	overlay_menu_root.name = "OverlayMenuCanvas"
	overlay_menu_root.size = OVERLAY_MENU_SIZE
	overlay.add_child(overlay_menu_root)
	_layout_overlay_menu_root()

	overlay_title = Label.new()
	overlay_title.position = Vector2(0.0, 210.0)
	overlay_title.size = Vector2(OVERLAY_MENU_SIZE.x, 82.0)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overlay_title.add_theme_font_size_override("font_size", 60)
	overlay_menu_root.add_child(overlay_title)

	overlay_title_sprite = TextureRect.new()
	overlay_title_sprite.position = Vector2((OVERLAY_MENU_SIZE.x - END_TITLE_SIZE.x) * 0.5, 82.0)
	overlay_title_sprite.size = END_TITLE_SIZE
	overlay_title_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	overlay_title_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	overlay_title_sprite.visible = false
	overlay_menu_root.add_child(overlay_title_sprite)

	boss_kill_pose = TextureRect.new()
	boss_kill_pose.texture = BOSS_KILL_POSE_TEXTURE
	boss_kill_pose.position = Vector2(1234.0, 344.0)
	boss_kill_pose.size = END_POSE_SIZE
	boss_kill_pose.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	boss_kill_pose.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	boss_kill_pose.visible = false
	overlay_menu_root.add_child(boss_kill_pose)

	victory_pose = TextureRect.new()
	victory_pose.texture = VICTORY_POSE_TEXTURE
	victory_pose.position = Vector2(1234.0, 344.0)
	victory_pose.size = END_POSE_SIZE
	victory_pose.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	victory_pose.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	victory_pose.visible = false
	overlay_menu_root.add_child(victory_pose)

	var button_x := (OVERLAY_MENU_SIZE.x - OVERLAY_BUTTON_SIZE.x) * 0.5
	resume_button = _make_overlay_button(
		Vector2(button_x, 392.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		RESUME_TEXT_TEXTURE,
		RESUME_TEXT_REGION
	)
	menu_button = _make_overlay_button(
		Vector2(button_x, 392.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		MENU_TEXT_TEXTURE,
		MENU_TEXT_REGION
	)
	settings_button = _make_overlay_button(
		Vector2(button_x, 392.0 + OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		SETTINGS_TEXT_TEXTURE,
		SETTINGS_TEXT_REGION
	)
	bye_button = _make_overlay_button(
		Vector2(button_x, 392.0 + ((OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP) * 2.0)),
		STONE_BUTTON_EXIT_TEXTURE,
		STONE_BUTTON_EXIT_REGION,
		EXIT_TEXT_TEXTURE,
		EXIT_TEXT_REGION,
		OVERLAY_EXIT_TEXT_SCALE
	)
	overlay_menu_root.add_child(resume_button)
	overlay_menu_root.add_child(menu_button)
	overlay_menu_root.add_child(settings_button)
	overlay_menu_root.add_child(bye_button)

	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	settings_button.pressed.connect(func() -> void: print("Settings placeholder"))
	bye_button.pressed.connect(func() -> void: bye_requested.emit())


func _layout_overlay_menu_root() -> void:
	if overlay_menu_root == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := minf(viewport_size.x / OVERLAY_MENU_SIZE.x, viewport_size.y / OVERLAY_MENU_SIZE.y)
	overlay_menu_root.scale = Vector2.ONE * scale_factor
	overlay_menu_root.position = (viewport_size - (OVERLAY_MENU_SIZE * scale_factor)) * 0.5


func _layout_pause_overlay_content() -> void:
	var button_x := (OVERLAY_MENU_SIZE.x - OVERLAY_BUTTON_SIZE.x) * 0.5
	var first_button_y := 280.0
	overlay_title_sprite.size = PAUSE_TITLE_SIZE
	overlay_title_sprite.position = Vector2((OVERLAY_MENU_SIZE.x - PAUSE_TITLE_SIZE.x) * 0.5, 54.0)
	resume_button.position = Vector2(button_x, first_button_y)
	menu_button.position = Vector2(button_x, first_button_y + OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP)
	settings_button.position = Vector2(button_x, first_button_y + ((OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP) * 2.0))
	bye_button.position = Vector2(button_x, first_button_y + ((OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP) * 3.0) + OVERLAY_EXIT_BUTTON_EXTRA_GAP)


func _layout_end_overlay_content() -> void:
	var button_x := (OVERLAY_MENU_SIZE.x - OVERLAY_BUTTON_SIZE.x) * 0.5
	var first_button_y := 356.0
	overlay_title_sprite.size = END_TITLE_SIZE
	overlay_title_sprite.position = Vector2((OVERLAY_MENU_SIZE.x - END_TITLE_SIZE.x) * 0.5, 72.0)
	boss_kill_pose.position = Vector2(1234.0, 344.0)
	victory_pose.position = Vector2(1234.0, 344.0)
	menu_button.position = Vector2(button_x, first_button_y)
	settings_button.position = Vector2(button_x, first_button_y + OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP)
	bye_button.position = Vector2(button_x, first_button_y + ((OVERLAY_BUTTON_SIZE.y + OVERLAY_BUTTON_GAP) * 2.0) + OVERLAY_EXIT_BUTTON_EXTRA_GAP)


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


func _make_overlay_button(
	position: Vector2,
	button_texture: Texture2D,
	button_region: Rect2,
	text_texture: Texture2D,
	text_region: Rect2,
	text_scale := OVERLAY_BUTTON_TEXT_SCALE
) -> TextureButton:
	var button := TextureButton.new()
	button.position = position
	button.size = OVERLAY_BUTTON_SIZE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = _atlas_texture(button_texture, button_region)
	button.texture_hover = _atlas_texture(button_texture, button_region)
	button.texture_pressed = _atlas_texture(button_texture, button_region)

	var text_rect := TextureRect.new()
	text_rect.texture = _atlas_texture(text_texture, text_region)
	text_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	text_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_size := OVERLAY_BUTTON_SIZE * text_scale
	text_rect.position = (OVERLAY_BUTTON_SIZE - text_size) * 0.5
	text_rect.size = text_size
	button.add_child(text_rect)
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
