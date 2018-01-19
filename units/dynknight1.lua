local included = VFS.Include("units/dynstrike1.lua")
local unitDef = included.dynstrike1
unitDef.unitname = "dynknight1"
unitDef.buildpic = [[cremcom.png]]
unitDef.objectname = [[cremcom.s3o]]
unitDef.script  = [[dynknight.lua]]

unitDef.customparams.commtype = "6"
unitDef.customparams.statsname = "dynknight1"
unitDef.customparams.shield_emit_height = "30"


unitDef.sfxtypes = {
	explosiongenerators = {
		[[custom:BEAMWEAPON_MUZZLE_BLUE]],
		[[custom:NONE]],
		[[custom:RAIDMUZZLE]],
		[[custom:NONE]],
		[[custom:VINDIBACK]],
		[[custom:FLASH64]],
	}
}

return lowerkeys({ dynknight1 = unitDef })