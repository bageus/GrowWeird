class_name GrowingFruitState
extends RefCounted

var progress: float = 0.0
var hybrid: bool = false

func is_ready() -> bool:
	return progress >= 1.0
