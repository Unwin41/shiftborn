class_name Bolt
extends Area2D
## Mage projectile. Flies straight, hits the first enemy it touches.

const COLOR := Color("e2c4ff")
const RADIUS := 3.0

@export var speed: float = 320.0
@export var lifetime: float = 1.2

var direction: Vector2 = Vector2.RIGHT
var damage: float = 1.0

var _spent: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent or not area.has_method("take_damage"):
		return
	_spent = true
	area.take_damage(damage)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
