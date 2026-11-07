class_name Enemy
extends Area2D
## Basic chaser. Walks toward [member target] and deals contact damage
## per second while touching it. [HordeSpawner] sets the target.
## Needs an AnimatedSprite2D child named "Sprite" with a "run" animation.

signal died(enemy: Enemy)

const PLAYER_RADIUS := 7.0
const HIT_FLASH_TIME := 0.08
## Values above 1 push sprite pixels toward white for the hit flash.
const HIT_FLASH_MODULATE := Color(8.0, 8.0, 8.0)

@export var move_speed: float = 45.0
@export var max_health: float = 3.0
@export var contact_dps: float = 2.0
@export var body_radius: float = 6.0

var target: Node2D
var health: float

var _hit_flash: float = 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	health = max_health
	_sprite.play(&"run")
	# Desync animations so a crowd does not bob in lockstep.
	_sprite.frame = randi() % maxi(_sprite.sprite_frames.get_frame_count(&"run"), 1)


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if not is_zero_approx(offset.x):
		_sprite.flip_h = offset.x < 0.0
	if distance > body_radius + PLAYER_RADIUS:
		global_position += offset / distance * move_speed * delta
	elif target.has_method("take_damage"):
		target.take_damage(contact_dps * delta)


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	_hit_flash = HIT_FLASH_TIME
	_sprite.modulate = HIT_FLASH_MODULATE
	if health <= 0.0:
		died.emit(self)
		queue_free()


func _update_hit_flash(delta: float) -> void:
	if _hit_flash <= 0.0:
		return
	_hit_flash -= delta
	if _hit_flash <= 0.0:
		_sprite.modulate = Color.WHITE
