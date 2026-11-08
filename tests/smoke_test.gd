extends SceneTree
## Integration smoke test: runs the real main scene with no input.
## Usage: godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd
## Checks that enemies spawn, reach the idle player, both forms kill and
## level-ups open the card menu (always picking the first card).

const MAIN_SCENE := preload("res://scenes/main.tscn")
const SECONDS_PER_PHASE := 15

var _errors: PackedStringArray = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	var player: Player = main.get_node("Player")
	var spawner: HordeSpawner = main.get_node("HordeSpawner")
	# An idle player dies in ~15s by design; keep it alive to test both forms.
	player.max_health = 1000.0
	player.health = player.max_health
	var kills_as_knight := await _kills_during(main, SECONDS_PER_PHASE)
	_check(spawner.alive_count() > 0, "no enemies alive after %ds" % SECONDS_PER_PHASE)
	_check(kills_as_knight > 0, "knight killed nothing")
	_check(player.health < player.max_health, "player took no contact damage")
	player.shift()
	_check(player.form == Player.Form.MAGE, "shift did not switch to mage")
	var kills_as_mage := await _kills_during(main, SECONDS_PER_PHASE)
	_check(kills_as_mage > 0, "mage killed nothing")
	_check(main.experience.level > 1, "never leveled up")
	_check(not paused, "tree still paused after the run")
	print("smoke: elapsed %.1fs, alive %d, knight kills %d, mage kills %d, hp %.1f, level %d" % [
		spawner.elapsed, spawner.alive_count(), kills_as_knight, kills_as_mage, player.health,
		main.experience.level])
	for error in _errors:
		printerr("SMOKE FAIL: ", error)
	await AudioManager.shutdown()
	quit(1 if not _errors.is_empty() else 0)


func _kills_during(main: Node, seconds: int) -> int:
	var before: int = main.kills
	var menu: LevelUpMenu = main.level_up_menu
	for frame in seconds * 60:
		if menu.visible:
			menu.choose(0)
		await physics_frame
	return int(main.kills) - before


func _check(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)
