class_name Player
extends Node2D
## Player that shifts between two forms.
## Knight: slower, melee pulse around the player.
## Mage: faster, auto-aimed bolts at the nearest enemy.

signal form_changed(form: Form)
signal health_changed(current: float, maximum: float)
signal died

enum Form { KNIGHT, MAGE }

const BOLT_SCENE := preload("res://scenes/bolt.tscn")
const KNIGHT_FRAMES := preload("res://assets/sprite_frames/knight.tres")
const MAGE_FRAMES := preload("res://assets/sprite_frames/wizard.tres")
const BODY_RADIUS := 7.0
const SWING_FLASH_TIME := 0.12
const HURT_FLASH_TIME := 0.1
const HURT_TINT := Color(1.0, 0.45, 0.45)
## Sprite scale right after a shift; it eases back to 1.
const SHIFT_POP_SCALE := 1.35
const SHIFT_POP_TIME := 0.18
## Small delay before the first attack after a shift, so shifting feels snappy.
const SHIFT_ATTACK_DELAY := 0.1
const KNIGHT_COLOR := Color("5fa8e8")
const MAGE_COLOR := Color("b77cf0")

@export var move_speed: float = 110.0
@export var max_health: float = 10.0
@export var shift_cooldown: float = 0.5
## Group the attacks search. Main syncs it with HordeSpawner.enemy_group.
@export var enemy_group: StringName = &"horde_enemy"

@export_group("Knight")
@export var knight_interval: float = 0.9
@export var knight_radius: float = 44.0
@export var knight_damage: float = 2.0
@export var knight_speed_multiplier: float = 0.9

@export_group("Mage")
@export var mage_interval: float = 0.45
@export var mage_damage: float = 1.0
@export var mage_range: float = 240.0
@export var mage_speed_multiplier: float = 1.15

var form: Form = Form.KNIGHT
var health: float
var is_dead: bool = false

var _attack_timer: float = 0.0
var _shift_timer: float = 0.0
var _swing_flash: float = 0.0
var _hurt_flash: float = 0.0

@onready var _sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)
	_apply_form_visuals()


func _physics_process(delta: float) -> void:
	if is_dead:
		_sprite.pause()
		return
	_shift_timer = maxf(_shift_timer - delta, 0.0)
	_swing_flash = maxf(_swing_flash - delta, 0.0)
	_update_hurt_flash(delta)
	if Input.is_action_just_pressed(&"shift_form") and _shift_timer == 0.0:
		shift()
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	position += direction * move_speed * _speed_multiplier() * delta
	_update_animation(direction)
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_interval()
		_attack()
	queue_redraw()


func shift() -> void:
	form = Form.MAGE if form == Form.KNIGHT else Form.KNIGHT
	_shift_timer = shift_cooldown
	_attack_timer = SHIFT_ATTACK_DELAY
	_apply_form_visuals()
	_sprite.scale = Vector2.ONE * SHIFT_POP_SCALE
	create_tween().tween_property(_sprite, "scale", Vector2.ONE, SHIFT_POP_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	form_changed.emit(form)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	_hurt_flash = HURT_FLASH_TIME
	_sprite.modulate = HURT_TINT
	health_changed.emit(health, max_health)
	if health == 0.0:
		is_dead = true
		died.emit()


func form_name() -> String:
	return "Knight" if form == Form.KNIGHT else "Mage"


func _apply_form_visuals() -> void:
	var animation := _sprite.animation
	_sprite.sprite_frames = KNIGHT_FRAMES if form == Form.KNIGHT else MAGE_FRAMES
	_sprite.play(animation if _sprite.sprite_frames.has_animation(animation) else &"idle")


func _update_animation(direction: Vector2) -> void:
	_sprite.play(&"idle" if direction.is_zero_approx() else &"run")
	if not is_zero_approx(direction.x):
		_sprite.flip_h = direction.x < 0.0


func _update_hurt_flash(delta: float) -> void:
	if _hurt_flash <= 0.0:
		return
	_hurt_flash -= delta
	if _hurt_flash <= 0.0:
		_sprite.modulate = Color.WHITE


func _speed_multiplier() -> float:
	return knight_speed_multiplier if form == Form.KNIGHT else mage_speed_multiplier


func _attack_interval() -> float:
	return knight_interval if form == Form.KNIGHT else mage_interval


func _attack() -> void:
	if form == Form.KNIGHT:
		_knight_pulse()
	else:
		_mage_bolt()


func _knight_pulse() -> void:
	_swing_flash = SWING_FLASH_TIME
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy == null or not enemy.has_method("take_damage"):
			continue
		if enemy.global_position.distance_to(global_position) <= knight_radius:
			enemy.take_damage(knight_damage)


func _mage_bolt() -> void:
	var target := _nearest_enemy(mage_range)
	if target == null:
		return
	var bolt := BOLT_SCENE.instantiate() as Bolt
	bolt.direction = global_position.direction_to(target.global_position)
	bolt.damage = mage_damage
	get_parent().add_child(bolt)
	bolt.global_position = global_position


func _nearest_enemy(max_distance: float) -> Node2D:
	var nearest: Node2D = null
	var best := max_distance * max_distance
	for node in get_tree().get_nodes_in_group(enemy_group):
		var enemy := node as Node2D
		if enemy == null:
			continue
		var distance := enemy.global_position.distance_squared_to(global_position)
		if distance < best:
			best = distance
			nearest = enemy
	return nearest


func _draw() -> void:
	if form == Form.KNIGHT and _swing_flash > 0.0:
		var alpha := _swing_flash / SWING_FLASH_TIME
		draw_arc(Vector2.ZERO, knight_radius, 0.0, TAU, 40, Color(KNIGHT_COLOR, alpha), 2.0)
