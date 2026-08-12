class_name IdFactory
extends RefCounted

static func make(prefix: String) -> String:
	return "%s-%d-%d" % [prefix, Time.get_ticks_usec(), randi()]
