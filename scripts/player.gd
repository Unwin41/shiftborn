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
const BODY_RADIUS := 7.0
const SWING_FLASH_TIME := 0.12
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


func _ready() -> void:
	health = max_health
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_shift_timer = maxf(_shift_timer - delta, 0.0)
	_swing_flash = maxf(_swing_flash - delta, 0.0)
	if Input.is_action_just_pressed(&"shift_form") and _shift_timer == 0.0:
		shift()
	var direction := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	position += direction * move_speed * _speed_multiplier() * delta
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = _attack_interval()
		_attack()
	queue_redraw()


func shift() -> void:
	form = Form.MAGE if form == Form.KNIGHT else Form.KNIGHT
	_shift_timer = shift_cooldown
	_attack_timer = SHIFT_ATTACK_DELAY
	form_changed.emit(form)


func take_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health == 0.0:
		is_dead = true
		died.emit()


func form_name() -> String:
	return "Knight" if form == Form.KNIGHT else "Mage"


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
	var color := KNIGHT_COLOR if form == Form.KNIGHT else MAGE_COLOR
	draw_circle(Vector2.ZERO, BODY_RADIUS, color)
	if form == Form.KNIGHT and _swing_flash > 0.0:
		var alpha := _swing_flash / SWING_FLASH_TIME
		draw_arc(Vector2.ZERO, knight_radius, 0.0, TAU, 40, Color(color, alpha), 2.0)
