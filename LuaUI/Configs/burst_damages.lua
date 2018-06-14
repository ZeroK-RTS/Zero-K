
-- Tag things with unreliable if they often deal less damage against targets for which burst makes sense to measure.
-- For example Rogue is perfectly reliable at hitting statics and burst does not make sense against mobiles.
-- Skuttle always deals less than full damage against mobiles but burst is a useful thing to track against mobiles.

local NORMAL = 1
local AA = 2
local EMP_OR_DISARM = 3

local damages = {
	cloaksnipe = {
		damage = 1500,
		class = NORMAL,
	},
	hoverskirm = {
		damage = 620,
		class = NORMAL,
	},
	bomberprec = {
		damage = 800,
		class = NORMAL,
	},
	bomberheavy = {
		damage = 2000,
		unreliable = true,
		class = NORMAL,
	},
	spiderantiheavy = {
		damage = 8000,
		class = EMP_OR_DISARM,
	},
	hoverarty = {
		damage = 3000,
		class = NORMAL,
	},
	striderbantha = {
		damage = 3000,
		class = NORMAL,
	},
	turretantiheavy = {
		damage = 4000,
		class = NORMAL,
	},
	jumpskirm = {
		damage = 500,
		class = NORMAL,
	},
	shieldskirm = {
		damage = 350,
		class = NORMAL,
	},
	cloakskirm = {
		damage = 180,
		class = NORMAL,
	},
	shieldarty = {
		damage = 2500,
		class = EMP_OR_DISARM,
	},
	vehheavyarty = {
		damage = 800,
		class = NORMAL,
	},
	turretaaclose = {
		damage = 1200,
		class = AA,
	},
	spideraa = {
		damage = 220,
		class = AA,
	},
	shieldaa = {
		damage = 72,
		class = AA,
	},
	amphaa = {
		damage = 600,
		class = AA,
	},
	vehaa = {
		damage = 290,
		class = AA,
	},
	tankarty = {
		damage = 600,
		class = NORMAL,
	},
	tankheavyassault = {
		damage = 1000,
		class = NORMAL,
	},
	tankriot = {
		damage = 440,
		class = NORMAL,
	},
	tankheavyraid = {
		damage = 180,
		class = NORMAL,
	},
	hoverraid = {
		damage = 100,
		class = NORMAL,
	},
	amphraid = {
		damage = 230,
		class = NORMAL,
	},
	jumpbomb = {
		damage = 8000,
		unreliable = true,
		class = NORMAL,
	},
	jumpscout = {
		damage = 410,
		class = NORMAL,
	},
	turretmissile = {
		damage = 310,
		class = NORMAL,
	},
	turretheavylaser = {
		damage = 850,
		unreliable = true,
		class = NORMAL,
	},
	amphassault = {
		damage = 1500,
		unreliable = true,
		class = NORMAL,
	},
	tacnuke = {
		damage = 3500,
		class = NORMAL,
	},
	empmissile = {
		damage = 30000,
		class = EMP_OR_DISARM,
	},
	shiparty = {
		damage = 600,
		class = NORMAL,
	},
	shiptorpraider = {
		damage = 200,
		class = NORMAL,
	},
	subraider = {
		damage = 250,
		class = NORMAL,
	},
	turretgauss = {
		damage = 200,
		class = NORMAL,
	},
	hoverdepthcharge = {
		damage = 900,
		unreliable = true,
		class = NORMAL,
	},
	gunshipskirm = {
		damage = 200,
		class = NORMAL,
	},
	gunshipassault = {
		damage = 1760,
		unreliable = true,
		class = NORMAL,
	},
	planefighter = {
		damage = 135,
		class = AA,
	},
	gunshipaa = {
		damage = 200,
		class = AA,
	},
	hoveraa = {
		damage = 375,
		class = AA,
	},
	amphfloater = {
		damage = 150,
		class = NORMAL,
	},
	shipcarrier = {
		damage = 15000,
		class = EMP_OR_DISARM,
	},
	subtacmissile = {
		damage = 3500,
		class = NORMAL,
	},
	cloakbomb = {
		damage = 2500,
		unreliable = true,
		class = EMP_OR_DISARM,
	},
	shieldbomb = {
		damage = 1200,
		unreliable = true,
		class = NORMAL,
	},
}

local damageDefs = {}
for name, data in pairs(damages) do
	local ud = UnitDefNames[name]
	if ud and ud.id then
		damageDefs[ud.id] = data
	end
end

return damageDefs
