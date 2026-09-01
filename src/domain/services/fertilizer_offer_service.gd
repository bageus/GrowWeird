class_name FertilizerOfferService
extends RefCounted

static func initialize_rng(offer: FertilizerOfferState, seed_value: int) -> void:
	if offer == null or offer.rng_state != 0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	offer.rng_state = rng.state

static func advance(
	offer: FertilizerOfferState,
	delta: float,
	fertilizers: Array[FertilizerDefinition],
	rules: GameRules
) -> bool:
	if offer == null or offer.is_active():
		return false
	offer.seconds_until_offer = maxf(0.0, offer.seconds_until_offer - delta)
	if offer.seconds_until_offer > 0.0:
		return false
	return _generate(offer, fertilizers, rules.fertilizer_offer_count)

static func schedule_initial(offer: FertilizerOfferState, rules: GameRules) -> void:
	if offer != null and not offer.is_active():
		offer.seconds_until_offer = rules.initial_offer_delay_seconds

static func ensure_active(
	offer: FertilizerOfferState,
	fertilizers: Array[FertilizerDefinition],
	rules: GameRules
) -> bool:
	if offer == null or offer.is_active():
		return false
	offer.seconds_until_offer = 0.0
	return _generate(offer, fertilizers, rules.fertilizer_offer_count)

static func can_choose(offer: FertilizerOfferState, fertilizer_id: StringName) -> bool:
	return offer != null and offer.offered_ids.has(fertilizer_id)

static func resolve_choice(
	offer: FertilizerOfferState,
	fertilizer_id: StringName,
	rules: GameRules
) -> bool:
	if not can_choose(offer, fertilizer_id):
		return false
	offer.clear()
	offer.skip_count = 0
	offer.seconds_until_offer = rules.fertilizer_offer_interval_seconds
	return true

static func skip_price(offer: FertilizerOfferState, rules: GameRules) -> int:
	return rules.fertilizer_skip_base_price if offer != null and offer.is_active() else 0

static func resolve_skip(offer: FertilizerOfferState, rules: GameRules) -> bool:
	if offer == null or not offer.is_active():
		return false
	offer.clear()
	offer.skip_count += 1
	offer.seconds_until_offer = rules.fertilizer_offer_interval_seconds
	return true

static func refresh_offer(
	offer: FertilizerOfferState,
	fertilizers: Array[FertilizerDefinition],
	rules: GameRules
) -> bool:
	if offer == null:
		return false
	offer.clear()
	return _generate(offer, fertilizers, rules.fertilizer_offer_count)

static func _generate(
	offer: FertilizerOfferState,
	fertilizers: Array[FertilizerDefinition],
	count: int
) -> bool:
	var pool: Array[FertilizerDefinition] = []
	for definition in fertilizers:
		if definition != null and definition.offer_weight > 0.0:
			pool.append(definition)
	if pool.is_empty():
		return false

	var rng := _rng_for(offer)
	var target_count := mini(count, pool.size())
	for _index in range(target_count):
		var chosen := _weighted_pick(pool, rng)
		if chosen == null:
			break
		offer.offered_ids.append(chosen.id)
		pool.erase(chosen)
	offer.rng_state = rng.state
	return offer.is_active()

static func _weighted_pick(
	pool: Array[FertilizerDefinition],
	rng: RandomNumberGenerator
) -> FertilizerDefinition:
	var total: float = 0.0
	for definition in pool:
		total += maxf(0.0, definition.offer_weight)
	if total <= 0.0:
		return null
	var roll := rng.randf_range(0.0, total)
	var cursor: float = 0.0
	for definition in pool:
		cursor += maxf(0.0, definition.offer_weight)
		if roll <= cursor:
			return definition
	return pool.back()

static func _rng_for(offer: FertilizerOfferState) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	if offer.rng_state == 0:
		rng.seed = 4674135
	else:
		rng.state = offer.rng_state
	return rng
