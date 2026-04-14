extends Node

signal pull_completed(results: Array)
signal pity_updated(new_count: int)

const PITY_THRESHOLD: int = 80
const SOFT_PITY_START: int = 60

var pool: Dictionary = {
	HeroData.Rarity.COMMON:    [],
	HeroData.Rarity.RARE:      [],
	HeroData.Rarity.EPIC:      [],
	HeroData.Rarity.LEGENDARY: [],
}


func register_hero(hero_data: HeroData) -> void:
	pool[hero_data.rarity].append(hero_data)


func single_pull() -> HeroData:
	if RunState.gacha_tickets < 1:
		push_warning("Not enough tickets!")
		return null
	RunState.gacha_tickets -= 1
	var result = _do_pull()
	pull_completed.emit([result])
	return result


func ten_pull() -> Array:
	if RunState.gacha_tickets < 10:
		push_warning("Not enough tickets for 10-pull!")
		return []
	RunState.gacha_tickets -= 10
	var results = []
	var got_rare = false
	for i in range(10):
		var result = _do_pull(not got_rare and i == 9)
		results.append(result)
		if result.rarity >= HeroData.Rarity.RARE:
			got_rare = true
	pull_completed.emit(results)
	return results


func _do_pull(force_rare: bool = false) -> HeroData:
	var rarity = _roll_rarity(force_rare)
	var pool_for_rarity: Array = pool[rarity]
	if pool_for_rarity.is_empty():
		pool_for_rarity = pool[HeroData.Rarity.COMMON]
	var hero: HeroData = pool_for_rarity[randi() % pool_for_rarity.size()]
	if rarity == HeroData.Rarity.LEGENDARY:
		RunState.pity_counter = 0
	else:
		RunState.pity_counter += 1
	pity_updated.emit(RunState.pity_counter)
	return hero


func _roll_rarity(force_rare: bool = false) -> HeroData.Rarity:
	if RunState.pity_counter >= PITY_THRESHOLD:
		return HeroData.Rarity.LEGENDARY

	var legendary_rate = 15
	if RunState.pity_counter >= SOFT_PITY_START:
		legendary_rate += (RunState.pity_counter - SOFT_PITY_START) * 15

	var rates = {
		HeroData.Rarity.COMMON:    600,
		HeroData.Rarity.RARE:      300,
		HeroData.Rarity.EPIC:      85,
		HeroData.Rarity.LEGENDARY: legendary_rate,
	}
	if force_rare:
		rates[HeroData.Rarity.COMMON] = 0

	var total = 0
	for r in rates.values():
		total += r

	var roll = randi_range(0, total - 1)
	var cumulative = 0
	for rarity in [HeroData.Rarity.LEGENDARY, HeroData.Rarity.EPIC,
				   HeroData.Rarity.RARE, HeroData.Rarity.COMMON]:
		cumulative += rates[rarity]
		if roll < cumulative:
			return rarity

	return HeroData.Rarity.COMMON
