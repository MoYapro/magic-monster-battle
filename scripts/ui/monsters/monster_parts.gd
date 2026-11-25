class_name MonsterParts
extends RefCounted
## Finds the joints that play a role in the animations (head, weapon, ground) by joint name.

const HEAD_NAMES: Array[String] = ["head", "skull", "helm", "hood", "face", "cephalothorax", "crown"]
const WEAPON_WORDS: Array[String] = ["sword", "knife", "axe", "club", "staff", "blade", "stick", "stinger", "claw_near", "shield"]
const STATIC_NAMES: Array[String] = ["ground", "base", "ground_shadow"]


static func head(joint_names: Array[String]) -> String:
	for n in HEAD_NAMES:
		if joint_names.has(n):
			return n
	return ""


## Weapon-like joints that swing in the attack; at most two, nearest to the viewer last.
static func weapons(joint_names: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for n in joint_names:
		for w in WEAPON_WORDS:
			if n.contains(w) and not out.has(n):
				out.append(n)
	return out.slice(maxi(0, out.size() - 2))


static func is_static(joint_name: String) -> bool:
	return STATIC_NAMES.has(joint_name)
