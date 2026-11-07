extends Node2D
## Endless floor grid so movement reads even with placeholder art.
## Only the cells around the camera are drawn.

const CELL_SIZE := 32.0

@export var line_color: Color = Color(1.0, 1.0, 1.0, 0.05)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2.ZERO
	var half := get_viewport_rect().size
	var left := floorf((center.x - half.x) / CELL_SIZE) * CELL_SIZE
	var top := floorf((center.y - half.y) / CELL_SIZE) * CELL_SIZE
	var right := center.x + half.x
	var bottom := center.y + half.y
	var x := left
	while x <= right:
		draw_line(Vector2(x, top), Vector2(x, bottom), line_color)
		x += CELL_SIZE
	var y := top
	while y <= bottom:
		draw_line(Vector2(left, y), Vector2(right, y), line_color)
		y += CELL_SIZE
