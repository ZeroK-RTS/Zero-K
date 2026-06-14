local included = VFS.Include("units/dynstrike1.lua")
local unitDef = included.dynstrike1
unitDef.buildPic = [[cremcom.png]]
unitDef.objectName = [[cremcom.s3o]]
unitDef.script  = [[dynknight.lua]]
unitDef.speed       = 40.5
unitDef.radarDistanceJam = 0 -- needless complexity

unitDef.customParams.commtype = "6"
unitDef.customParams.statsname = "dynknight1"
unitDef.customParams.shield_emit_height = "30"
unitDef.customParams.normaltex = [[unittextures/cremcom_normals.dds]]

unitDef.reclaimable = false -- No reclaiming campaign commander.

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

return { dynknight1 = unitDef }
