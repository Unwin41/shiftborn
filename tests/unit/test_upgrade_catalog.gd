extends TestCase


func _count_tagged(upgrades: Array[Upgrade], tag: String) -> int:
	var count := 0
	for upgrade in upgrades:
		if tag in upgrade.tags:
			count += 1
	return count


func test_six_upgrades_per_form_and_four_shared() -> void:
	var upgrades := UpgradeCatalog.build()
	assert_eq(_count_tagged(upgrades, UpgradeCatalog.KNIGHT_TAG), 6, "knight")
	assert_eq(_count_tagged(upgrades, UpgradeCatalog.MAGE_TAG), 6, "mage")
	var shared := 0
	for upgrade in upgrades:
		if upgrade.tags.is_empty():
			shared += 1
	assert_eq(shared, 4, "shared")


func test_ids_are_unique_and_entries_complete() -> void:
	var ids := {}
	for upgrade in UpgradeCatalog.build():
		assert_false(ids.has(upgrade.id), "duplicate id %s" % upgrade.id)
		ids[upgrade.id] = true
		assert_true(upgrade.title != "", "%s has no title" % upgrade.id)
		assert_true(upgrade.description != "", "%s has no description" % upgrade.id)
		assert_true(upgrade.icon != null, "%s has no icon" % upgrade.id)
		assert_true(upgrade.max_level >= 1, "%s max level" % upgrade.id)


func test_every_upgrade_has_an_effect() -> void:
	for upgrade in UpgradeCatalog.build():
		assert_true(upgrade.id in UpgradeEffects.KNOWN_IDS, "%s has no effect" % upgrade.id)


func test_knight_offers_never_include_mage_upgrades() -> void:
	var pool := UpgradePool.new(UpgradeCatalog.build())
	var rng := RandomNumberGenerator.new()
	var tags := UpgradeCatalog.tags_for_form(Player.Form.KNIGHT)
	for i in 100:
		for upgrade in pool.offer(3, rng, tags):
			assert_false(UpgradeCatalog.MAGE_TAG in upgrade.tags, "mage upgrade %s offered to knight" % upgrade.id)


func test_mage_offers_never_include_knight_upgrades() -> void:
	var pool := UpgradePool.new(UpgradeCatalog.build())
	var rng := RandomNumberGenerator.new()
	var tags := UpgradeCatalog.tags_for_form(Player.Form.MAGE)
	for i in 100:
		for upgrade in pool.offer(3, rng, tags):
			assert_false(UpgradeCatalog.KNIGHT_TAG in upgrade.tags, "knight upgrade %s offered to mage" % upgrade.id)
