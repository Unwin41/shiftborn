extends SceneTree
## Builds SpriteFrames resources from the 0x72 DungeonTileset II frames.
## Usage: godot --headless -s res://tools/build_sprite_frames.gd
## Run `godot --headless --import` first so the PNGs are imported.
##
## Frame files are named <sprite>_<anim>_anim_f<N>.png (or
## <sprite>_anim_f<N>.png for sprites with a single animation).

const FRAMES_DIR := "res://assets/0x72_dungeon/frames"
const OUTPUT_DIR := "res://assets/sprite_frames"
const ANIMATION_FPS := {&"idle": 6.0, &"run": 10.0, &"hit": 1.0}

## Output name -> sprite prefix in the pack.
const CHARACTERS := {
	"knight": "dwarf_m",
	"wizard": "wizzard_m",
	"goblin": "goblin",
	"imp": "imp",
	"skeleton": "skelet",
	"orc_warrior": "orc_warrior",
	"chort": "chort",
	"big_demon": "big_demon",
}


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var failed := false
	for output_name in CHARACTERS:
		if not _build(output_name, CHARACTERS[output_name]):
			failed = true
	quit(1 if failed else 0)


func _build(output_name: String, prefix: String) -> bool:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation: StringName in ANIMATION_FPS:
		var textures := _load_frames("%s_%s_anim_f" % [prefix, animation])
		if textures.is_empty():
			continue
		frames.add_animation(animation)
		frames.set_animation_speed(animation, ANIMATION_FPS[animation])
		frames.set_animation_loop(animation, animation != &"hit")
		for texture in textures:
			frames.add_frame(animation, texture)
	if not frames.has_animation(&"run"):
		push_error("%s: no run frames for prefix %s" % [output_name, prefix])
		return false
	if not frames.has_animation(&"idle"):
		_copy_animation(frames, &"run", &"idle")
	var path := OUTPUT_DIR.path_join(output_name + ".tres")
	var error := ResourceSaver.save(frames, path)
	if error != OK:
		push_error("%s: save failed (%s)" % [path, error_string(error)])
		return false
	print("built %s (%s)" % [path, ", ".join(frames.get_animation_names())])
	return true


func _load_frames(stem: String) -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	var index := 0
	while true:
		var path := FRAMES_DIR.path_join("%s%d.png" % [stem, index])
		if not ResourceLoader.exists(path):
			break
		textures.append(load(path))
		index += 1
	return textures


func _copy_animation(frames: SpriteFrames, from: StringName, to: StringName) -> void:
	frames.add_animation(to)
	frames.set_animation_speed(to, ANIMATION_FPS[to])
	for i in frames.get_frame_count(from):
		frames.add_frame(to, frames.get_frame_texture(from, i))
