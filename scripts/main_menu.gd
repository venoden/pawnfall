extends Control

const GAME_SCENE_PATH := "res://scenes/Main.tscn"
const MENU_SIZE := Vector2(1920.0, 1080.0)
const BUTTON_SIZE := Vector2(430.0, 146.0)
const LOGO_SIZE := Vector2(650.0, 166.0)
const PAWN_SIZE := Vector2(132.0, 120.0)
const BUTTON_TEXT_SCALE := 0.86

const BACKGROUND_TEXTURE := preload("res://sprites/menu/dungeon_bg_lg.png")
const LOGO_TEXTURE := preload("res://sprites/menu/logo.png")
const STONE_BUTTON_TEXTURE := preload("res://sprites/menu/stone_button.png")
const STONE_BUTTON_EXIT_TEXTURE := preload("res://sprites/menu/stone_button_exit.png")
const PLAY_TEXT_TEXTURE := preload("res://sprites/menu/play_button_text.png")
const CREDITS_TEXT_TEXTURE := preload("res://sprites/menu/credits_button_text.png")
const SETTINGS_TEXT_TEXTURE := preload("res://sprites/menu/settings_button_text.png")
const EXIT_TEXT_TEXTURE := preload("res://sprites/menu/exit_button_text.png")
const PAWN_TEXTURE := preload("res://sprites/main_pawn.png")

const LOGO_REGION := Rect2(375, 353, 787, 201)
const STONE_BUTTON_REGION := Rect2(236, 324, 1064, 360)
const STONE_BUTTON_EXIT_REGION := Rect2(237, 309, 1061, 366)
const PLAY_TEXT_REGION := Rect2(524, 325, 510, 277)
const CREDITS_TEXT_REGION := Rect2(384, 345, 749, 224)
const SETTINGS_TEXT_REGION := Rect2(392, 352, 764, 238)
const EXIT_TEXT_REGION := Rect2(409, 365, 748, 171)
const PAWN_REGION := Rect2(68, 96, 888, 806)


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_menu()


func _build_menu() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.045, 0.05, 0.055)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var background := TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	_add_texture(LOGO_TEXTURE, LOGO_REGION, LOGO_SIZE, Vector2((MENU_SIZE.x - LOGO_SIZE.x) * 0.5, 68.0))

	_add_menu_button(
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 285.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		PLAY_TEXT_TEXTURE,
		PLAY_TEXT_REGION,
		Callable(self, "_on_play_pressed")
	)
	_add_menu_button(
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 435.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		CREDITS_TEXT_TEXTURE,
		CREDITS_TEXT_REGION,
		Callable()
	)
	_add_menu_button(
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 585.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		SETTINGS_TEXT_TEXTURE,
		SETTINGS_TEXT_REGION,
		Callable()
	)

	_add_texture(PAWN_TEXTURE, PAWN_REGION, PAWN_SIZE, Vector2((MENU_SIZE.x - PAWN_SIZE.x) * 0.5, 735.0))

	_add_menu_button(
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 875.0),
		STONE_BUTTON_EXIT_TEXTURE,
		STONE_BUTTON_EXIT_REGION,
		EXIT_TEXT_TEXTURE,
		EXIT_TEXT_REGION,
		Callable(self, "_on_exit_pressed")
	)


func _add_texture(source_texture: Texture2D, region: Rect2, size: Vector2, position: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = _atlas_texture(source_texture, region)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.position = position
	texture_rect.size = size
	add_child(texture_rect)
	return texture_rect


func _add_menu_button(
	position: Vector2,
	button_texture: Texture2D,
	button_region: Rect2,
	text_texture: Texture2D,
	text_region: Rect2,
	callback: Callable
) -> TextureButton:
	var button := TextureButton.new()
	button.position = position
	button.size = BUTTON_SIZE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = _atlas_texture(button_texture, button_region)
	button.texture_hover = _atlas_texture(button_texture, button_region)
	button.texture_pressed = _atlas_texture(button_texture, button_region)
	add_child(button)

	var text_rect := TextureRect.new()
	text_rect.texture = _atlas_texture(text_texture, text_region)
	text_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	text_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_size: Vector2 = BUTTON_SIZE * BUTTON_TEXT_SCALE
	text_rect.position = (BUTTON_SIZE - text_size) * 0.5
	text_rect.size = text_size
	button.add_child(text_rect)

	if callback.is_valid():
		button.pressed.connect(callback)
	return button


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture
