extends Node2D
## Endless dungeon floor. Only the tiles around the camera are drawn.
## Each cell picks its tile from a hash of its coordinates, so the floor
## looks varied but stays the same when you walk back.

const TILE_SIZE := 16.0
const FLOOR_DIR := "res://assets/0x72_dungeon/frames/"
const PLAIN_TILE := preload(FLOOR_DIR + "floor_1.png")
const DETAIL_TILES: Array[Texture2D] = [
	preload(FLOOR_DIR + "floor_2.png"),
	preload(FLOOR_DIR + "floor_3.png"),
	preload(FLOOR_DIR + "floor_4.png"),
	preload(FLOOR_DIR + "floor_5.png"),
	preload(FLOOR_DIR + "floor_6.png"),
	preload(FLOOR_DIR + "floor_7.png"),
	preload(FLOOR_DIR + "floor_8.png"),
]
## Roughly one in this many cells gets a detail tile.
const DETAIL_ONE_IN := 6
## Darkens the floor so characters and enemies stand out.
const FLOOR_TINT := Color(0.55, 0.53, 0.6)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2.ZERO
	var half := get_viewport_rect().size * 0.5 + Vector2.ONE * TILE_SIZE
	var first := ((center - half) / TILE_SIZE).floor()
	var last := ((center + half) / TILE_SIZE).ceil()
	for cell_y in range(int(first.y), int(last.y)):
		for cell_x in range(int(first.x), int(last.x)):
			draw_texture(_tile_for(cell_x, cell_y), Vector2(cell_x, cell_y) * TILE_SIZE, FLOOR_TINT)


## Integer hash with good spread for neighbouring cells.
static func cell_hash(cell_x: int, cell_y: int) -> int:
	var h := (cell_x * 73856093) ^ (cell_y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return absi(h)


func _tile_for(cell_x: int, cell_y: int) -> Texture2D:
	var hash_value := cell_hash(cell_x, cell_y)
	if hash_value % DETAIL_ONE_IN != 0:
		return PLAIN_TILE
	return DETAIL_TILES[(hash_value / DETAIL_ONE_IN) % DETAIL_TILES.size()]
