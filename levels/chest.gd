extends Area2D

signal bluntbow_collected
signal unlock_requested

@export var closed_texture: Texture2D = preload("res://sprites/closed_chest.png")
@export var open_texture: Texture2D = preload("res://sprites/open_chest.png")
@export var bluntbow_texture: Texture2D = preload("res://sprites/bluntbow.png")
@export var bluntbow_region := Rect2(170, 330, 590, 360)
@export var weapon_id: StringName = &"crossbow"
@export var bob_height := 3.0
@export var bob_speed := 3.2

@onready var chest_sprite: Sprite2D = $ChestSprite
@onready var bluntbow_pickup: Sprite2D = $BluntbowPickup

var unlocked := false
var collected := false
var bob_time := 0.0
var bluntbow_base_position := Vector2.ZERO


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	bluntbow_base_position = bluntbow_pickup.position
	chest_sprite.texture = closed_texture
	bluntbow_pickup.texture = _atlas_texture(bluntbow_texture, bluntbow_region)
	bluntbow_pickup.visible = false


func _process(delta: float) -> void:
	if not unlocked or collected:
		return
	bob_time += delta * bob_speed
	bluntbow_pickup.position = bluntbow_base_position + Vector2(0.0, sin(bob_time) * bob_height)


func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	chest_sprite.texture = open_texture
	bluntbow_pickup.visible = true
	bob_time = 0.0


func _on_body_entered(body: Node) -> void:
	if collected:
		return
	if not body.is_in_group("player") or not body.has_method("set_weapon"):
		return
	if not unlocked:
		unlock_requested.emit()
		return

	collected = true
	bluntbow_pickup.visible = false
	body.call("set_weapon", weapon_id)
	bluntbow_collected.emit()
	queue_free()


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture
