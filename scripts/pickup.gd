extends Area2D

@export_enum("health", "weapon") var pickup_kind := "health"
@export var heal_amount := 15.0
@export var max_health_bonus := 15.0
@export var weapon_id: StringName = &"crossbow"
@export var bob_height := 3.0
@export var bob_speed := 3.2

@onready var sprite: Sprite2D = $Sprite2D

const HEALTH_TEXTURE := preload("res://sprites/health.png")
const BLUNTBOW_TEXTURE := preload("res://sprites/bluntbow.png")
const BLUNTBOW_REGION := Rect2(170, 330, 590, 360)

var base_sprite_position := Vector2.ZERO
var bob_time := 0.0


func _ready() -> void:
	base_sprite_position = sprite.position
	body_entered.connect(_on_body_entered)
	_refresh_sprite()


func _process(delta: float) -> void:
	if pickup_kind != "health":
		return
	bob_time += delta * bob_speed
	sprite.position = base_sprite_position + Vector2(0.0, sin(bob_time) * bob_height)


func configure_health(new_heal_amount: float, new_max_health_bonus: float) -> void:
	pickup_kind = "health"
	heal_amount = new_heal_amount
	max_health_bonus = new_max_health_bonus
	if is_node_ready():
		_refresh_sprite()


func configure_weapon(new_weapon_id: StringName) -> void:
	pickup_kind = "weapon"
	weapon_id = new_weapon_id
	if is_node_ready():
		_refresh_sprite()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return

	if pickup_kind == "health" and body.has_method("apply_health_pickup"):
		body.call("apply_health_pickup", heal_amount, max_health_bonus)
	elif pickup_kind == "weapon" and body.has_method("set_weapon"):
		body.call("set_weapon", weapon_id)

	queue_free()


func _refresh_sprite() -> void:
	if pickup_kind == "weapon":
		sprite.texture = _atlas_texture(BLUNTBOW_TEXTURE, BLUNTBOW_REGION)
		sprite.scale = Vector2(0.16, 0.16)
	else:
		sprite.texture = HEALTH_TEXTURE
		sprite.scale = Vector2(0.08, 0.08)
		sprite.position = base_sprite_position


func _atlas_texture(source_texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas_texture: AtlasTexture = AtlasTexture.new()
	atlas_texture.atlas = source_texture
	atlas_texture.region = region
	return atlas_texture
