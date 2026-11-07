class_name SpriteDraw
extends RefCounted
## Helpers for drawing a single sprite from a CanvasItem's _draw().


## Draws [param texture] centered on the item's origin, mirrored
## horizontally when [param flip_h] is true.
static func centered(item: CanvasItem, texture: Texture2D, flip_h: bool = false, modulate: Color = Color.WHITE) -> void:
	var size := texture.get_size()
	if flip_h:
		item.draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0, 1.0))
	item.draw_texture(texture, -size * 0.5, modulate)
	if flip_h:
		item.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
