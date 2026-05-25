extends Control

const GAME_SCENE_PATH := "res://scenes/Main.tscn"
const MENU_SIZE := Vector2(1920.0, 1080.0)
const BUTTON_SIZE := Vector2(430.0, 146.0)
const LOGO_SIZE := Vector2(650.0, 166.0)
const PAWN_SIZE := Vector2(132.0, 120.0)
const BUTTON_TEXT_SCALE := 0.58995
const EXIT_TEXT_SCALE := 0.621
const HEADER_SIZE := Vector2(720.0, 156.0)
const CREDITS_HEADER_TEXT_SIZE := Vector2(431.2, 101.64)
const BACK_BUTTON_SIZE := Vector2(192.0, 144.0)
const BACK_BUTTON_HEADER_GAP := 18.0
const VENODEN_SIZE := Vector2(792.0, 274.0)
const OVERLAY_COLOR := Color(0.05, 0.06, 0.07, 0.68)

const BACKGROUND_TEXTURE := preload("res://pawnfall/menu/main_menu_background_1920x1080.png")
const LOGO_TEXTURE := preload("res://pawnfall/menu/logo.png")
const STONE_BUTTON_TEXTURE := preload("res://pawnfall/menu/stone_button.png")
const STONE_BUTTON_EXIT_TEXTURE := preload("res://pawnfall/menu/stone_button_exit.png")
const PLAY_TEXT_TEXTURE := preload("res://pawnfall/menu/play_button_text.png")
const CREDITS_TEXT_TEXTURE := preload("res://pawnfall/menu/credits_button_text.png")
const SETTINGS_TEXT_TEXTURE := preload("res://pawnfall/menu/settings_button_text.png")
const EXIT_TEXT_TEXTURE := preload("res://pawnfall/menu/exit_button_text.png")
const ARROW_TEXTURE := preload("res://pawnfall/menu/arrow.png")
const VENODEN_TEXTURE := preload("res://pawnfall/menu/venoden.png")
const PAWN_TEXTURE := preload("res://pawnfall/menu/main_pawn.png")

const LOGO_REGION := Rect2(375, 353, 787, 201)
const STONE_BUTTON_REGION := Rect2(236, 324, 1064, 360)
const STONE_BUTTON_EXIT_REGION := Rect2(237, 309, 1061, 366)
const PLAY_TEXT_REGION := Rect2(524, 325, 510, 277)
const CREDITS_TEXT_REGION := Rect2(0, 0, 800, 280)
const SETTINGS_TEXT_REGION := Rect2(392, 352, 764, 238)
const EXIT_TEXT_REGION := Rect2(409, 365, 748, 171)
const PAWN_REGION := Rect2(68, 96, 888, 806)

var menu_root: Control
var main_screen: Control
var credits_screen: Control
var submenu_overlay: ColorRect


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_build_menu()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_menu_root()


func _build_menu() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.045, 0.05, 0.055)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var background := TextureRect.new()
	background.texture = BACKGROUND_TEXTURE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	submenu_overlay = ColorRect.new()
	submenu_overlay.name = "SubmenuOverlayShade"
	submenu_overlay.color = OVERLAY_COLOR
	submenu_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	submenu_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	submenu_overlay.visible = false
	add_child(submenu_overlay)

	menu_root = Control.new()
	menu_root.name = "MenuCanvas"
	menu_root.size = MENU_SIZE
	add_child(menu_root)
	_layout_menu_root()

	main_screen = Control.new()
	main_screen.name = "MainScreen"
	main_screen.position = Vector2.ZERO
	main_screen.size = MENU_SIZE
	menu_root.add_child(main_screen)

	_add_texture(main_screen, LOGO_TEXTURE, LOGO_REGION, LOGO_SIZE, Vector2((MENU_SIZE.x - LOGO_SIZE.x) * 0.5, 68.0))

	_add_menu_button(
		main_screen,
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 285.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		PLAY_TEXT_TEXTURE,
		PLAY_TEXT_REGION,
		Callable(self, "_on_play_pressed")
	)
	_add_menu_button(
		main_screen,
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 435.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		CREDITS_TEXT_TEXTURE,
		CREDITS_TEXT_REGION,
		Callable(self, "_show_credits")
	)
	_add_menu_button(
		main_screen,
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 585.0),
		STONE_BUTTON_TEXTURE,
		STONE_BUTTON_REGION,
		SETTINGS_TEXT_TEXTURE,
		SETTINGS_TEXT_REGION,
		Callable()
	)

	_add_texture(main_screen, PAWN_TEXTURE, PAWN_REGION, PAWN_SIZE, Vector2((MENU_SIZE.x - PAWN_SIZE.x) * 0.5, 735.0))

	_add_menu_button(
		main_screen,
		Vector2((MENU_SIZE.x - BUTTON_SIZE.x) * 0.5, 875.0),
		STONE_BUTTON_EXIT_TEXTURE,
		STONE_BUTTON_EXIT_REGION,
		EXIT_TEXT_TEXTURE,
		EXIT_TEXT_REGION,
		Callable(self, "_on_exit_pressed"),
		EXIT_TEXT_SCALE
	)

	_build_credits_screen()


func _layout_menu_root() -> void:
	if menu_root == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor: float = minf(viewport_size.x / MENU_SIZE.x, viewport_size.y / MENU_SIZE.y)
	menu_root.scale = Vector2.ONE * scale_factor
	menu_root.position = (viewport_size - (MENU_SIZE * scale_factor)) * 0.5


func _build_credits_screen() -> void:
	credits_screen = Control.new()
	credits_screen.name = "CreditsScreen"
	credits_screen.position = Vector2.ZERO
	credits_screen.size = MENU_SIZE
	credits_screen.visible = false
	menu_root.add_child(credits_screen)

	var header_position := Vector2((MENU_SIZE.x - HEADER_SIZE.x) * 0.5, 86.0)
	_add_texture(credits_screen, STONE_BUTTON_TEXTURE, STONE_BUTTON_REGION, HEADER_SIZE, header_position)

	_add_texture(
		credits_screen,
		CREDITS_TEXT_TEXTURE,
		CREDITS_TEXT_REGION,
		CREDITS_HEADER_TEXT_SIZE,
		header_position + ((HEADER_SIZE - CREDITS_HEADER_TEXT_SIZE) * 0.5)
	)

	var back_button := TextureButton.new()
	back_button.name = "BackButton"
	back_button.position = header_position + Vector2(
		-(BACK_BUTTON_SIZE.x + BACK_BUTTON_HEADER_GAP),
		(HEADER_SIZE.y - BACK_BUTTON_SIZE.y) * 0.5
	)
	back_button.size = BACK_BUTTON_SIZE
	back_button.ignore_texture_size = true
	back_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back_button.texture_normal = ARROW_TEXTURE
	back_button.texture_hover = ARROW_TEXTURE
	back_button.texture_pressed = ARROW_TEXTURE
	back_button.pressed.connect(_show_main_menu)
	credits_screen.add_child(back_button)

	_add_full_texture(
		credits_screen,
		VENODEN_TEXTURE,
		VENODEN_SIZE,
		Vector2((MENU_SIZE.x - VENODEN_SIZE.x) * 0.5, 268.0)
	)


func _add_texture(parent: Node, source_texture: Texture2D, region: Rect2, size: Vector2, position: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = _atlas_texture(source_texture, region)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.position = position
	texture_rect.size = size
	parent.add_child(texture_rect)
	return texture_rect


func _add_full_texture(parent: Node, source_texture: Texture2D, size: Vector2, position: Vector2) -> TextureRect:
	var texture_rect := TextureRect.new()
	texture_rect.texture = source_texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.position = position
	texture_rect.size = size
	parent.add_child(texture_rect)
	return texture_rect


func _add_menu_button(
	parent: Node,
	position: Vector2,
	button_texture: Texture2D,
	button_region: Rect2,
	text_texture: Texture2D,
	text_region: Rect2,
	callback: Callable,
	text_scale := BUTTON_TEXT_SCALE
) -> TextureButton:
	var button := TextureButton.new()
	button.position = position
	button.size = BUTTON_SIZE
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.texture_normal = _atlas_texture(button_texture, button_region)
	button.texture_hover = _atlas_texture(button_texture, button_region)
	button.texture_pressed = _atlas_texture(button_texture, button_region)
	parent.add_child(button)

	var text_rect := TextureRect.new()
	text_rect.texture = _atlas_texture(text_texture, text_region)
	text_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	text_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	text_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text_size: Vector2 = BUTTON_SIZE * text_scale
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


func _show_credits() -> void:
	main_screen.visible = false
	credits_screen.visible = true
	submenu_overlay.visible = true


func _show_main_menu() -> void:
	credits_screen.visible = false
	main_screen.visible = true
	submenu_overlay.visible = false


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture
