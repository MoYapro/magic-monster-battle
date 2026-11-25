class_name MonsterReactions
extends RefCounted
## Which monsters to animate after a state change, from their HP before and after (id -> hp).


static func hit(before: Dictionary, after: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in after:
		if before.has(id) and int(after[id]) < int(before[id]):
			out.append(id)
	return out


static func died(before: Dictionary, after: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for id: String in before:
		if not after.has(id):
			out.append(id)
	return out
