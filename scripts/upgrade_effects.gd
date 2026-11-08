class_name UpgradeEffects
extends RefCounted
## Applies one level of an [UpgradeCatalog] upgrade to a [Player].
## Keep the steps in sync with the catalog descriptions.

const KNIGHT_DAMAGE_STEP := 0.5
const KNIGHT_REACH_STEP := 6.0
const KNIGHT_HASTE_FACTOR := 0.9
const LIFESTEAL_STEP := 0.15
## Initial push speed in px/s; enemies slide about speed / 10 pixels.
const KNOCKBACK_STEP := 120.0
const MAGE_DAMAGE_STEP := 0.35
const MAGE_HASTE_FACTOR := 0.88
const MAGE_RANGE_STEP := 40.0
const VITALITY_STEP := 3.0
const SWIFTNESS_FACTOR := 1.08
const REGEN_STEP := 0.2
const SHIFT_BURST_DAMAGE_STEP := 2.0

const KNOWN_IDS: Array[StringName] = [
	&"knight_damage", &"knight_reach", &"knight_haste", &"knight_lifesteal",
	&"knight_twin_blade", &"knight_knockback",
	&"mage_damage", &"mage_haste", &"mage_range", &"mage_pierce",
	&"mage_multishot", &"mage_chain",
	&"vitality", &"swiftness", &"regen", &"shift_burst",
]


## Returns false for an unknown id.
static func apply(player: Player, id: StringName) -> bool:
	match id:
		&"knight_damage": player.knight_damage += KNIGHT_DAMAGE_STEP
		&"knight_reach": player.knight_radius += KNIGHT_REACH_STEP
		&"knight_haste": player.knight_interval *= KNIGHT_HASTE_FACTOR
		&"knight_lifesteal": player.lifesteal += LIFESTEAL_STEP
		&"knight_twin_blade": player.blade_count += 1
		&"knight_knockback": player.knockback += KNOCKBACK_STEP
		&"mage_damage": player.mage_damage += MAGE_DAMAGE_STEP
		&"mage_haste": player.mage_interval *= MAGE_HASTE_FACTOR
		&"mage_range": player.mage_range += MAGE_RANGE_STEP
		&"mage_pierce": player.bolt_pierce += 1
		&"mage_multishot": player.bolt_count += 1
		&"mage_chain": player.bolt_chain += 1
		&"vitality":
			player.max_health += VITALITY_STEP
			player.heal(VITALITY_STEP)
		&"swiftness": player.move_speed *= SWIFTNESS_FACTOR
		&"regen": player.regen_per_second += REGEN_STEP
		&"shift_burst": player.shift_burst_damage += SHIFT_BURST_DAMAGE_STEP
		_:
			push_warning("UpgradeEffects: unknown upgrade %s" % id)
			return false
	player.refresh_stats()
	return true
