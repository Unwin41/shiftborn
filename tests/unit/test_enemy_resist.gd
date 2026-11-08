extends TestCase


func test_wrong_form_deals_a_quarter() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Player.Form.MAGE), 4.0 * Enemy.RESISTED_DAMAGE)


func test_right_form_deals_full_damage() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Player.Form.KNIGHT), 4.0)


func test_neutral_source_and_neutral_enemy_ignore_resistance() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Enemy.NO_FORM), 4.0)
	assert_almost_eq(Enemy.damage_after_resist(4.0, Enemy.NO_FORM, Player.Form.MAGE), 4.0)


func test_resistant_scenes_resist_the_expected_form() -> void:
	var skeleton := preload("res://scenes/enemy_skeleton.tscn").instantiate() as Enemy
	var imp := preload("res://scenes/enemy_runner.tscn").instantiate() as Enemy
	var goblin := preload("res://scenes/enemy.tscn").instantiate() as Enemy
	assert_eq(skeleton.resisted_form, Player.Form.MAGE, "skeleton should shrug off bolts")
	assert_eq(imp.resisted_form, Player.Form.KNIGHT, "imp should shrug off the axe")
	assert_eq(goblin.resisted_form, Enemy.NO_FORM, "goblin should be neutral")
	skeleton.free()
	imp.free()
	goblin.free()
