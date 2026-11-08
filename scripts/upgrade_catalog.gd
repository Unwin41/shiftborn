class_name UpgradeCatalog
extends RefCounted
## Every upgrade in Shiftborn. Level-up offers come from the active form's
## tag plus the untagged (shared) upgrades. [UpgradeEffects] applies them.
## Numbers in descriptions must match the steps in [UpgradeEffects].

const KNIGHT_TAG := "knight"
const MAGE_TAG := "mage"
const ICON_DIR := "res://assets/0x72_dungeon/frames/"

const ENTRIES: Array[Dictionary] = [
	# Knight: four stats, two behaviours.
	{id = &"knight_damage", title = "Honed Edge", text = "Sword damage +0.5", icon = "weapon_golden_sword", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_reach", title = "Long Blade", text = "Sword reach +6", icon = "weapon_spear", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_haste", title = "Quick Spin", text = "Spin 10% more often", icon = "weapon_katana", max = 5, tag = KNIGHT_TAG},
	{id = &"knight_lifesteal", title = "Vampiric Edge", text = "Heal 0.15 HP per sword hit", icon = "weapon_red_gem_sword", max = 3, tag = KNIGHT_TAG},
	{id = &"knight_twin_blade", title = "Twin Blade", text = "One more blade per spin", icon = "weapon_duel_sword", max = 2, tag = KNIGHT_TAG},
	{id = &"knight_knockback", title = "Heavy Swing", text = "Sword hits knock enemies back", icon = "weapon_big_hammer", max = 3, tag = KNIGHT_TAG},
	# Mage: four stats, two behaviours.
	{id = &"mage_damage", title = "Arcane Power", text = "Bolt damage +0.35", icon = "weapon_red_magic_staff", max = 5, tag = MAGE_TAG},
	{id = &"mage_haste", title = "Swift Casting", text = "Cast 12% more often", icon = "weapon_green_magic_staff", max = 5, tag = MAGE_TAG},
	{id = &"mage_range", title = "Far Sight", text = "Targeting range +40", icon = "weapon_bow", max = 3, tag = MAGE_TAG},
	{id = &"mage_pierce", title = "Piercing Bolt", text = "Bolts pass through +1 enemy", icon = "weapon_arrow", max = 3, tag = MAGE_TAG},
	{id = &"mage_multishot", title = "Split Bolt", text = "Cast one more bolt", icon = "weapon_bow_2", max = 3, tag = MAGE_TAG},
	{id = &"mage_chain", title = "Chain Spark", text = "Bolts jump to +1 nearby enemy", icon = "flask_big_yellow", max = 3, tag = MAGE_TAG},
	# Shared.
	{id = &"vitality", title = "Vitality", text = "Max HP +3 and heal 3", icon = "ui_heart_full", max = 5, tag = ""},
	{id = &"swiftness", title = "Swiftness", text = "Move speed +8%", icon = "flask_big_green", max = 5, tag = ""},
	{id = &"regen", title = "Regeneration", text = "Recover 0.2 HP per second", icon = "flask_big_red", max = 3, tag = ""},
	{id = &"shift_burst", title = "Shift Burst", text = "Shifting blasts nearby enemies for 2 damage (every 2s)", icon = "flask_big_blue", max = 3, tag = ""},
]


static func build() -> Array[Upgrade]:
	var upgrades: Array[Upgrade] = []
	for entry in ENTRIES:
		var upgrade := Upgrade.new()
		upgrade.id = entry.id
		upgrade.title = entry.title
		upgrade.description = entry.text
		upgrade.icon = load(ICON_DIR + entry.icon + ".png")
		upgrade.max_level = entry.max
		if entry.tag != "":
			upgrade.tags = PackedStringArray([entry.tag])
		upgrades.append(upgrade)
	return upgrades


## Tag filter for [method UpgradePool.offer] while in [param form].
static func tags_for_form(form: Player.Form) -> PackedStringArray:
	return PackedStringArray([KNIGHT_TAG if form == Player.Form.KNIGHT else MAGE_TAG])
