class_name EnemyData

var id: String
var display_name: String
var max_hp: int
var current_hp: int
var grid_size: Vector2i        # width x height in grid cells
var color: Color               # placeholder until art exists
var difficulty_rating: int = 10  # 1–100; used in encounter budget
var main_role: MonsterRole.Type = MonsterRole.Type.NONE
var off_role: MonsterRole.Type = MonsterRole.Type.NONE
var drop_pool: Array[SpellData] = []
var action_pool: Array[MonsterActionData] = []
var traits: Array[MonsterTraitData] = []


func _init(
	p_id: String,
	p_name: String,
	p_hp: int,
	p_size: Vector2i,
	p_color: Color
) -> void:
	id = p_id
	display_name = p_name
	max_hp = p_hp
	current_hp = p_hp
	grid_size = p_size
	color = p_color
