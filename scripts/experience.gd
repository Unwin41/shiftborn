class_name Experience
extends RefCounted
## Run XP and level. Kills add XP directly (no pickups). Reaching level
## n + 1 from level n costs [method xp_for_level] of n; leftover XP carries.
## Tuned for roughly 25 level-ups in a 10 minute run.

signal leveled_up(new_level: int)

const BASE_XP := 5
## Each level costs this much more than the previous one.
const GROWTH := 1.15

var level: int = 1
var xp: int = 0


static func xp_for_level(from_level: int) -> int:
	return roundi(BASE_XP * pow(GROWTH, from_level - 1))


func xp_to_next() -> int:
	return xp_for_level(level)


## 0..1 progress toward the next level, for the HUD bar.
func progress() -> float:
	return float(xp) / xp_to_next()


## Adds XP and returns how many levels were gained.
func add(amount: int) -> int:
	if amount <= 0:
		return 0
	xp += amount
	var gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
		leveled_up.emit(level)
	return gained
