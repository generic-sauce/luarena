local types_mod = {}

types_mod.CLASSES = {
	skill = {},
	move = {},
	walk = {"move"},
	dash = {"move"},
	silence = {},
	root = {},
	stun = {"root", "silence"},
	spawn_protection = {"untouchable"},

	archer_s1 = {"skill"},
	archer_s2 = {"skill"},
	archer_s3 = {"skill", "dash"},

	riven_s1 = {"skill"},
	riven_s1_dash = {"skill", "dash"},
	riven_s2 = {"skill"},
	riven_s2_stun = {"stun"},
	riven_s3 = {"skill", "dash"},

	u1_s1 = {"skill", "untouchable"},
	u1_s2 = {"skill"},
	u1_s3 = {"skill", "dash"},
	u1_s4 = {"skill"},

	invulnerable = {}, -- prevents damage
	untouchable = {"invulnerable"}, -- prevents negative effects and damage

	dead = {}
}

types_mod.RELATIONS = {
	{old = {"walk"}, new = {"dash", "stun"}, relation = "cancel"},
	{old = {"dash", "stun"}, new = {"walk"}, relation = "prevent"},
	{old = {"stun"}, new = {"skill"}, relation = "delay"},
	{old = {"dash"}, new = {"dash"}, relation = "delay"},
	{old = {"untouchable"}, new = {"stun"}, relation = "prevent"}
}

return types_mod
