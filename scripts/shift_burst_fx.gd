class_name ShiftBurstFx
extends Node2D
## Expanding ring drawn once when the Shift Burst upgrade fires.

const DURATION := 0.25
const COLOR := Color(0.6, 0.85, 1.0)
const LINE_WIDTH := 2.0
const SEGMENTS := 48

var radius: float = 64.0

var _time: float = 0.0


static func create(burst_radius: float) -> ShiftBurstFx:
	var fx := ShiftBurstFx.new()
	fx.radius = burst_radius
	return fx


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := minf(_time / DURATION, 1.0)
	draw_arc(Vector2.ZERO, radius * t, 0.0, TAU, SEGMENTS, Color(COLOR, 1.0 - t), LINE_WIDTH)
