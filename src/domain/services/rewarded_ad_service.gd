class_name RewardedAdService
extends RefCounted

const REWARD_COINS := 10
const MAX_CLAIMS := 4
const WINDOW_SECONDS := 8 * 60 * 60

static func claim(state: GameState, now_unix: int) -> bool:
	if state == null:
		return false
	state.rewarded_ad_claims = recent_claims(state, now_unix)
	if state.rewarded_ad_claims.size() >= MAX_CLAIMS:
		return false
	state.rewarded_ad_claims.append(now_unix)
	EconomyService.credit(state, REWARD_COINS)
	return true

static func remaining_claims(state: GameState, now_unix: int) -> int:
	return maxi(0, MAX_CLAIMS - recent_claims(state, now_unix).size()) if state != null else 0

static func seconds_until_next(state: GameState, now_unix: int) -> int:
	var claims := recent_claims(state, now_unix)
	if claims.size() < MAX_CLAIMS:
		return 0
	return maxi(0, int(claims[0]) + WINDOW_SECONDS - now_unix)

static func recent_claims(state: GameState, now_unix: int) -> Array[int]:
	var result: Array[int] = []
	if state == null:
		return result
	var cutoff := now_unix - WINDOW_SECONDS
	for claim_time in state.rewarded_ad_claims:
		if claim_time > cutoff and claim_time <= now_unix:
			result.append(claim_time)
	result.sort()
	return result
