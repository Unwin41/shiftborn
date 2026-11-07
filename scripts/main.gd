extends Node2D
## Run controller: wires player, spawner and HUD, ends the run on death
## or when the timer reaches [constant RUN_LENGTH].

const RUN_LENGTH := 600.0

@onready var player: Player = $Player
@onready var spawner: HordeSpawner = $HordeSpawner
@onready var status_label: Label = %StatusLabel
@onready var center_label: Label = %CenterLabel

var kills: int = 0
var _run_over: bool = false


static func format_time(seconds: float) -> String:
	var whole := int(seconds)
	return "%02d:%02d" % [whole / 60, whole % 60]


func _ready() -> void:
	player.enemy_group = spawner.enemy_group
	player.died.connect(_on_player_died)
	spawner.enemy_spawned.connect(_on_enemy_spawned)
	center_label.hide()


func _process(_delta: float) -> void:
	status_label.text = "%s   %s   HP %d/%d   Kills %d" % [
		format_time(spawner.elapsed),
		player.form_name(),
		ceili(player.health),
		int(player.max_health),
		kills,
	]
	if not _run_over and spawner.elapsed >= RUN_LENGTH:
		_end_run("YOU SURVIVED")


func _unhandled_input(event: InputEvent) -> void:
	if _run_over and event.is_action_pressed(&"restart"):
		get_tree().reload_current_scene()


func _on_enemy_spawned(enemy: Node2D) -> void:
	if enemy is Enemy:
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Enemy) -> void:
	if _run_over:
		return
	kills += 1


func _on_player_died() -> void:
	_end_run("YOU DIED")


func _end_run(title: String) -> void:
	_run_over = true
	spawner.stop()
	player.is_dead = true
	get_tree().call_group(spawner.enemy_group, &"set_physics_process", false)
	center_label.text = "%s\n%s  -  %d kills\n\nR / Start to retry" % [title, format_time(spawner.elapsed), kills]
	center_label.show()
