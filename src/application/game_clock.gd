class_name GameClock
extends RefCounted

var _accumulator: float = 0.0

func consume(delta_seconds: float, step_seconds: float) -> int:
	if delta_seconds <= 0.0 or step_seconds <= 0.0:
		return 0
	_accumulator += delta_seconds
	var steps := int(floor(_accumulator / step_seconds))
	if steps > 0:
		_accumulator -= float(steps) * step_seconds
	return steps

func reset() -> void:
	_accumulator = 0.0
