extends Node2D
## Run controller: wires player, spawner and HUD, turns kills into XP and
## level-up card picks, ends the run on death or when the timer reaches
## [constant RUN_LENGTH].

const RUN_LENGTH := 600.0
const OFFER_COUNT := 3
const HURT_HITSTOP := 0.06
const DEATH_HITSTOP := 0.2

@onready var player: Player = $Player
@onready var spawner: HordeSpawner = $HordeSpawner
@onready var status_label: Label = %StatusLabel
@onready var center_label: Label = %CenterLabel
@onready var xp_bar: XpBar = %XpBar
@onready var energy_bars: EnergyBars = %EnergyBars
@onready var damage_numbers: DamageNumbers = $DamageNumbers
@onready var world_environment: WorldEnvironment = $WorldEnvironment

var kills: int = 0
var experience := Experience.new()
var upgrade_pool := UpgradePool.new(UpgradeCatalog.build())
var level_up_menu: LevelUpMenu
var _run_over: bool = false
var _rng := RandomNumberGenerator.new()
## Level-ups earned but not picked yet; several can arrive in one frame.
var _pending_level_ups: int = 0
var _level_up_active: bool = false
var _hitstop := Hitstop.new()


static func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]


func _ready() -> void:
	player.enemy_group = spawner.enemy_group
	player.died.connect(_on_player_died)
	player.hurt_feedback.connect(_hitstop.trigger.bind(HURT_HITSTOP))
	add_child(_hitstop)
	_apply_quality()
	AudioManager.play_music(AudioManager.RUN_MUSIC)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	center_label.hide()
	_rng.randomize()
	level_up_menu = LevelUpMenu.new()
	add_child(level_up_menu)
	level_up_menu.chosen.connect(_on_upgrade_chosen)
	level_up_menu.closed.connect(_open_level_up)


func _process(_delta: float) -> void:
	status_label.text = "%s   %s   HP %d/%d   Kills %d" % [
		format_time(spawner.elapsed),
		player.form_name(),
		ceili(player.health),
		int(player.max_health),
		kills,
	]
	xp_bar.set_progress(experience.level, experience.progress())
	energy_bars.show_levels(player.energy_level(Player.Form.KNIGHT), player.energy_level(Player.Form.MAGE), player.form)
	if not _run_over and spawner.elapsed >= RUN_LENGTH:
		AudioManager.play(&"run_win")
		_end_run("YOU SURVIVED")


func _unhandled_input(event: InputEvent) -> void:
	if _run_over and event.is_action_pressed(&"restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()


func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy is Enemy:
		enemy.died.connect(_on_enemy_died)
		enemy.damaged.connect(_on_enemy_damaged)


func _on_enemy_damaged(enemy: Enemy, amount: float, resisted: bool) -> void:
	damage_numbers.spawn(enemy.global_position, amount, resisted)


## HDR 2D and glow only on HIGH; see [Quality]. The scene ships with glow
## off so nothing glows on web before this runs.
func _apply_quality() -> void:
	var high := Quality.is_high()
	get_viewport().use_hdr_2d = high
	world_environment.environment.glow_enabled = high


func _on_enemy_died(enemy: Enemy) -> void:
	if _run_over:
		return
	kills += 1
	_pending_level_ups += experience.add(enemy.xp_value)
	if _pending_level_ups > 0 and not _level_up_active:
		_open_level_up()


## Shows the next pending level-up, skipping ones with nothing to offer.
## Pauses while the menu is open; unpauses once nothing is pending.
func _open_level_up() -> void:
	while _pending_level_ups > 0 and not _run_over:
		_pending_level_ups -= 1
		var offers := upgrade_pool.offer(OFFER_COUNT, _rng, UpgradeCatalog.tags_for_form(player.form))
		if offers.is_empty():
			continue
		var levels: Array[int] = []
		for upgrade in offers:
			levels.append(upgrade_pool.level_of(upgrade.id))
		_level_up_active = true
		get_tree().paused = true
		level_up_menu.open(offers, levels)
		AudioManager.play(&"level_up")
		return
	_level_up_active = false
	get_tree().paused = false


func _on_upgrade_chosen(upgrade: Upgrade) -> void:
	AudioManager.play(&"card_pick")
	if upgrade_pool.apply(upgrade.id) > 0:
		UpgradeEffects.apply(player, upgrade.id)


func _on_player_died() -> void:
	_hitstop.trigger(DEATH_HITSTOP)
	_end_run("YOU DIED")


func _end_run(title: String) -> void:
	AudioManager.stop_music(1.5)
	_run_over = true
	_pending_level_ups = 0
	_level_up_active = false
	level_up_menu.cancel()
	get_tree().paused = false
	spawner.stop()
	player.is_dead = true
	get_tree().call_group(spawner.enemy_group, &"set_physics_process", false)
	center_label.text = "%s\n%s  -  %d kills\n\nR / Start to retry" % [title, format_time(spawner.elapsed), kills]
	center_label.show()
