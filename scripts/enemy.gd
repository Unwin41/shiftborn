class_name Enemy
extends Area2D
## Basic chaser. Walks toward [member target] and deals contact damage
## per second while touching it. [HordeSpawner] sets the target.
## Needs an AnimatedSprite2D child named "Sprite" with a "run" animation.

signal died(enemy: Enemy)
## [param resisted] is true when the hit came from the form it resists.
signal damaged(enemy: Enemy, amount: float, resisted: bool)

const PLAYER_RADIUS := 7.0
const HIT_FLASH_TIME := 0.08
## Values above 1 push sprite pixels toward white for the hit flash.
const HIT_FLASH_MODULATE := Color(8.0, 8.0, 8.0)
## Knockback speed decays by this rate per second (exponential), so an
## impulse of speed v slides the enemy about v / rate pixels.
const KNOCKBACK_DECAY := 10.0
## Death pop: flash, squash and fade before the node is freed.
const DEATH_TIME := 0.2
const DEATH_SCALE := Vector2(1.5, 0.3)
## "No form": a neutral damage source, or an enemy that resists nothing.
const NO_FORM := -1
## Share of damage taken from the resisted form.
const RESISTED_DAMAGE := 0.25
const WEAKNESS_MARK_OFFSET := Vector2(0.0, -12.0)

@export var move_speed: float = 45.0
@export var max_health: float = 3.0
@export var contact_dps: float = 2.0
@export var body_radius: float = 6.0
## XP granted to the player on death.
@export var xp_value: int = 1
## Form whose attacks deal only [constant RESISTED_DAMAGE] of their damage.
@export_enum("None:-1", "Warrior:0", "Mage:1") var resisted_form: int = NO_FORM

var target: Node2D
var health: float

var _hit_flash: float = 0.0
var _weakness_mark: WeaknessMark
var _knockback_velocity: Vector2 = Vector2.ZERO

@onready var _sprite: AnimatedSprite2D = $Sprite


static func damage_after_resist(amount: float, resisted: int, source_form: int) -> float:
	if resisted != NO_FORM and source_form == resisted:
		return amount * RESISTED_DAMAGE
	return amount


func resists(source_form: int) -> bool:
	return resisted_form != NO_FORM and source_form == resisted_form


func _ready() -> void:
	health = max_health
	if resisted_form != NO_FORM:
		var weak_to := Player.Form.MAGE if resisted_form == Player.Form.KNIGHT else Player.Form.KNIGHT
		_weakness_mark = WeaknessMark.create(weak_to, WEAKNESS_MARK_OFFSET)
		add_child(_weakness_mark)
	_sprite.play(&"run")
	# Desync animations so a crowd does not bob in lockstep.
	_sprite.frame = randi() % maxi(_sprite.sprite_frames.get_frame_count(&"run"), 1)


func _physics_process(delta: float) -> void:
	_update_hit_flash(delta)
	_update_knockback(delta)
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


## [param source_form] is the attacking form, or [constant NO_FORM] for
## damage that ignores resistance (Shift Burst).
func take_damage(amount: float, source_form: int = NO_FORM) -> void:
	if health <= 0.0:
		return
	var resisted := resists(source_form)
	var final_amount := damage_after_resist(amount, resisted_form, source_form)
	var dealt := minf(final_amount, health)
	health -= final_amount
	damaged.emit(self, dealt, resisted)
	_hit_flash = HIT_FLASH_TIME
	_sprite.modulate = HIT_FLASH_MODULATE
	if health <= 0.0:
		_die()


## Leaves every gameplay group and stops colliding at once, so targeting,
## bolts and the alive count ignore the corpse while the death pop plays.
func _die() -> void:
	died.emit(self)
	AudioManager.play(&"enemy_death")
	for group in get_groups():
		if not String(group).begins_with("_"):
			remove_from_group(group)
	set_deferred(&"monitorable", false)
	set_physics_process(false)
	if _weakness_mark != null:
		_weakness_mark.hide()
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, ^"scale", DEATH_SCALE, DEATH_TIME).set_ease(Tween.EASE_OUT)
	tween.tween_property(_sprite, ^"modulate", Color(HIT_FLASH_MODULATE, 0.0), DEATH_TIME)
	tween.chain().tween_callback(queue_free)


## Pushes the enemy with [param impulse] (px/s), fading out quickly.
func knockback(impulse: Vector2) -> void:
	_knockback_velocity += impulse


func _update_knockback(delta: float) -> void:
	if _knockback_velocity.is_zero_approx():
		return
	global_position += _knockback_velocity * delta
	_knockback_velocity *= exp(-KNOCKBACK_DECAY * delta)
	if _knockback_velocity.length_squared() < 1.0:
		_knockback_velocity = Vector2.ZERO


func _update_hit_flash(delta: float) -> void:
	if _hit_flash <= 0.0:
		return
	_hit_flash -= delta
	if _hit_flash <= 0.0:
		_sprite.modulate = Color.WHITE
