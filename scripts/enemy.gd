class_name Enemy
extends Area2D
## Basic chaser. Walks toward [member target] and deals contact damage
## per second while touching it. [HordeSpawner] sets the target.

signal died(enemy: Enemy)

const PLAYER_RADIUS := 7.0
const HIT_FLASH_TIME := 0.08
## Values above 1 push sprite pixels toward white for the hit flash.
const HIT_FLASH_MODULATE := Color(8.0, 8.0, 8.0)
const HIT_FLASH_COLOR := Color.WHITE

@export var move_speed: float = 45.0
@export var max_health: float = 3.0
@export var contact_dps: float = 2.0
@export var body_radius: float = 6.0
## Sprite. Without one, the enemy draws as a circle in [member color].
@export var texture: Texture2D
@export var color: Color = Color("d9534f")

var target: Node2D
var health: float

var _hit_flash: float = 0.0
var _facing_left: bool = false


func _ready() -> void:
	health = max_health


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	var facing_left := offset.x < 0.0
	if facing_left != _facing_left:
		_facing_left = facing_left
		queue_redraw()
	if distance > body_radius + PLAYER_RADIUS:
		global_position += offset / distance * move_speed * delta
	elif target.has_method("take_damage"):
		target.take_damage(contact_dps * delta)


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	_hit_flash = HIT_FLASH_TIME
	queue_redraw()
	if health <= 0.0:
		died.emit(self)
		queue_free()


func _update_hit_flash(delta: float) -> void:
	if _hit_flash <= 0.0:
		return
	_hit_flash -= delta
	if _hit_flash <= 0.0:
		queue_redraw()


func _draw() -> void:
	var flashing := _hit_flash > 0.0
	if texture == null:
		draw_circle(Vector2.ZERO, body_radius, HIT_FLASH_COLOR if flashing else color)
		return
	SpriteDraw.centered(self, texture, _facing_left, HIT_FLASH_MODULATE if flashing else Color.WHITE)
