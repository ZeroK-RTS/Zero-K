
-----------------------------------------------------------------
-- Units
-----------------------------------------------------------------

local gameSpeed = Game.gameSpeed

local minReloadTime = 4 -- weapons reloading slower than this willget bars

unitBuildChannel = 1
unitParalyzeChannel = 2
unitDisarmChannel = 3
unitSlowChannel = 4
unitReloadChannel = 5
unitDgunChannel = 6
unitTeleportChannel = 7
unitHeatChannel = 7
unitSpeedChannel = 7
unitReammoChannel = 7
unitGooChannel = 7
unitJumpChannel = 7
unitCaptureReloadChannel = 7
unitAbilityChannel = 7
unitStockpileProgressChannel = 7
unitStockpileAmountChannel = 8
unitShieldChannel = 8
unitCaptureChannel = 9
unitMorphChannel = 10
unitHealthChannel = 11 -- if its =20, then its health/maxhealth

unitDefIgnore = {} -- commanders!
unitDefHasShield = {} -- value is shield max power
unitDefCanStockpile = {} -- 0/1?
unitDefPrimaryReload = {} -- value is max reload time
unitDefHeights = {} -- maps unitDefs to height
unitDefPrimaryWeapon = {} -- the index for reloadable weapon on unitdef weapons
unitDefHasAbility = {}
unitDefScriptReload = {}
unitDefDgun = {}
unitDefDgunReload = {}
unitDefHasGoo = {}
unitDefHasJump = {}
unitDefHasHeat = {}
unitDefHasSpeed = {}
unitDefHasReammo = {}
unitDefHasCaptureReload = {}
unitDefHasTeleport = {}

-- Walk through unitdefs for the stuff we need:
for udefID, unitDef in pairs(UnitDefs) do
        if unitDef.customParams and unitDef.customParams.nohealthbars then
                unitDefIgnore[udefID] = true
        end --ignore debug units

        -- SHIELDS
        local shieldDefID = unitDef.shieldWeaponDef
        local shieldPower = ((shieldDefID) and (WeaponDefs[shieldDefID].shieldPower)) or (-1)
        if shieldPower > 1 then unitDefHasShield[udefID] = shieldPower
                --Spring.Echo("HAS SHIELD")
        end

        local primaryReloadTime = minReloadTime

        local isDynamic = false

        if unitDef.customParams and unitDef.customParams.dynamic_comm then
                isDynamic = true
        end
        if not isDynamic then -- TODO if isDynamic then return end
                local weapons = unitDef.weapons

                for i = 1, #weapons do
                        local WeaponDef = WeaponDefs[weapons[i].weaponDef]

                        if not WeaponDef then

                        -- DGUN
                        elseif WeaponDef.manualFire then
                                unitDefDgun[udefID] = i
                                unitDefDgunReload[udefID] = WeaponDef.reload

                        -- CAPTURE RELOAD
                        elseif WeaponDef.customParams and WeaponDef.customParams.post_capture_reload then
                                unitDefHasCaptureReload[udefID] = tonumber(WeaponDef.customParams.post_capture_reload)

                        -- RELOAD
                        elseif WeaponDef.reload and WeaponDef.reload >= primaryReloadTime then
                                primaryReloadTime = WeaponDef.reload
                                unitDefPrimaryReload[udefID] = primaryReloadTime
                                unitDefPrimaryWeapon[udefID] = i
                        end
                end

                -- SPECIAL ABILITY
                if unitDef.customParams and unitDef.customParams.specialreloadtime then
                        unitDefHasAbility[udefID] = unitDef.customParams.specialreloadtime
                end

                -- SCRIPT RELOAD
                if unitDef.customParams and unitDef.customParams.script_reload then
                        unitDefScriptReload[udefID] = tonumber(unitDef.customParams.script_reload) * gameSpeed
                end
                -- GOO
                if unitDef.customParams and unitDef.customParams.grey_goo then
                        unitDefHasGoo[udefID] = 1
                end

                -- HEAT
                if unitDef.customParams and unitDef.customParams.heat_initial then
                        unitDefHasHeat[udefID] = 1
                end

                -- SPEED
                if unitDef.customParams and unitDef.customParams.speed_bar then
                        unitDefHasSpeed[udefID] = 1
                end

                -- REAMMO
                if unitDef.customParams and unitDef.customParams.reammoseconds then
                        unitDefHasReammo[udefID] = 1
                end

                -- STOCKPILE
                if unitDef.canStockpile then
                        unitDefCanStockpile[udefID] = unitDef.canStockpile
                end

                -- TELEPORT
                if unitDef.customParams and (unitDef.customParams.teleporter_throughput or unitDef.customParams.teleporter_is_beacon) then
                        unitDefHasTeleport[udefID] = 1
                end
        end

        -- JUMP
        if unitDef.customParams and unitDef.customParams.canjump then
                unitDefHasJump[udefID] = 1
        end
end
