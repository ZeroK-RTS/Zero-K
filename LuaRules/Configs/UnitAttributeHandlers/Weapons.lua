local floor=math.floor
local spGetUnitWeaponState=Spring.GetUnitWeaponState
local spSetUnitWeaponState=Spring.SetUnitWeaponState
local spSetUnitWeaponDamages=Spring.SetUnitWeaponDamages
local INLOS_ACCESS = {inlos = true}
local spSetUnitRulesParam=Spring.SetUnitRulesParam

local HALF_FRAME = 1 / (2 * Game.gameSpeed)

local function defaultWeaponSpecificMod()
    return {
        reloadMult = 1,
        rangeMult = 1,
        projSpeedMult = 1,
        projectilesMult = 1,
        burstMult=1,
        burstRateMult=1,
        sprayAngleAdd=0,
        damageMult=1,
    }
end

local origUnitWeapons={}

local UnitReloadPause=GG.UnitReloadPause


local projectileSpeedLock = {}
local rangeUpdater = {}


local function ApplyWeaponMods(unitId,state,weaponMods,gameFrame,minSpray)
    local rangeUpdateRequired=true -- dk how to 
    local weaponModDef=weaponMods.def
    local
    reloadSpeedFactor, rangeFactor, projSpeedFactor, projectilesFactor,burstFactor,burstRateFactor,sprayAngleAdd,damageFactor=
    weaponModDef.reloadMult,
    weaponModDef.rangeMult,
    weaponModDef.projSpeedMult,
    weaponModDef.projectilesMult,
    weaponModDef.burstMult,
    weaponModDef.burstRateMult,
    weaponModDef.sprayAngleAdd,
    weaponModDef.damageMult

    
    if damageFactor ~= 1 and not GG.ATT_ENABLE_DAMAGE then
        Spring.Utilities.UnitEcho(unitId, "damage attribute requires GG.ATT_ENABLE_DAMAGE")
    end
    local maxRangeModified = state.maxWeaponRange*rangeFactor

    for wpnNum = 1, state.weaponCount do
        local w = state.weapon[wpnNum]
        local reloadState = spGetUnitWeaponState(unitId, wpnNum , 'reloadState')
        local reloadTime  = spGetUnitWeaponState(unitId, wpnNum , 'reloadTime')
        local wmod=weaponMods[wpnNum]

        
		local moddedReloadSpeedFactor = reloadSpeedFactor
		

		local moddedRange = w.range*rangeFactor
		local moddedProjectiles = w.projectiles*projectilesFactor
		
		local moddedSprayAngle = w.sprayAngle+sprayAngleAdd
		local moddedBurst=w.burst and w.burst*burstFactor
        
		local moddedBurstRateFactor=burstRateFactor

        local moddedProjSpeedFactor=projSpeedFactor

        if wmod then
			moddedReloadSpeedFactor = moddedReloadSpeedFactor * (wmod.reloadMult or 1)
			
			moddedRange = moddedRange * (wmod.rangeMult or 1)
			
			moddedProjectiles = moddedProjectiles*(wmod.projectilesMult or 1)
            
			moddedSprayAngle = moddedSprayAngle+(wmod.sprayAngleAdd or 0)

			moddedBurst=moddedBurst and moddedBurst * (wmod.burstMult or 1)
			moddedBurstRateFactor = moddedBurstRateFactor * ( wmod.burstRateMult or 1 )
            moddedProjSpeedFactor = moddedProjSpeedFactor * (wmod.projSpeedMult)
		end

        moddedBurstRateFactor=moddedBurstRateFactor / moddedReloadSpeedFactor
        
        local moddedBurstRate = w.burstRate and w.burstRate * moddedBurstRateFactor
        
		moddedSprayAngle = math.max(moddedSprayAngle, minSpray)

        if moddedBurstRate then
			spSetUnitWeaponState(unitId,wpnNum,"burstRate",moddedBurstRate + HALF_FRAME)
		end

        if moddedReloadSpeedFactor <= 0 then
            UnitReloadPause.UnitReloadPause(unitId,wpnNum,reloadState,reloadTime,gameFrame)
        else
            UnitReloadPause.UnitReloadUnpause(unitId,wpnNum)
            local newReload = w.reload/moddedReloadSpeedFactor
            local nextReload = gameFrame+(reloadState-gameFrame)*newReload/reloadTime
            -- Add HALF_FRAME to round reloadTime to the closest discrete frame (multiple of 1/30), since the the engine rounds DOWN
            if moddedBurstRate then
                spSetUnitWeaponState(unitId, wpnNum, {reloadTime = newReload + HALF_FRAME, reloadState = nextReload + 0.5, burstRate = moddedBurstRate + HALF_FRAME})
            else
                spSetUnitWeaponState(unitId, wpnNum, {reloadTime = newReload + HALF_FRAME, reloadState = nextReload + 0.5})
            end
        end
        
        local sprayAngle = math.max(w.sprayAngle, minSpray)
        spSetUnitWeaponState(unitId, wpnNum, "sprayAngle", sprayAngle)
        
        spSetUnitWeaponState(unitId, wpnNum, "projectiles", moddedProjectiles)

		if moddedBurst then
			spSetUnitWeaponState(unitId,wpnNum,"burst",moddedBurst)
		end
        

        if rangeUpdateRequired then
			if w.projectileSpeed and not projectileSpeedLock[unitId] then
				-- Changing projectile speed without subsequently setting range causes some weapons to go to zero range. Eg Scorcher
				local moddedProjSpeed = w.projectileSpeed*moddedProjSpeedFactor
				spSetUnitWeaponState(unitId, wpnNum, "projectileSpeed", moddedProjSpeed)
			end
			if not rangeUpdater[unitId] then
				spSetUnitWeaponState(unitId, wpnNum, "range", moddedRange)
				spSetUnitWeaponDamages(unitId, wpnNum, "dynDamageRange", moddedRange)
				if maxRangeModified < moddedRange then
					maxRangeModified = moddedRange
				end
			end
		end
        if GG.ATT_ENABLE_DAMAGE then
            local did = 0
            local data = state.weapon[wpnNum].damages
            local toSet = {}
            while data[did] do
                toSet[did] = data[did] * damageFactor
                did = did + 1
            end
            spSetUnitWeaponDamages(unitId, wpnNum, toSet)
        end
    end
    if rangeUpdateRequired then
		if rangeUpdater[unitId] and rangeUpdater[unitId] ~= true then
			local mods = {}
			for i = 1, state.weaponCount do
				mods[i] = weaponMods and weaponMods[i] and weaponMods[i].rangeMult or 1
			end
			rangeUpdater[unitId](rangeFactor, mods)
		else
			Spring.SetUnitMaxRange(unitId, maxRangeModified)
		end
	end
end

local function LoadState(unitDefID)
    local ud = UnitDefs[unitDefID]
    local state = {
        weapon = {},
        weaponCount = #ud.weapons,
        maxWeaponRange = ud.maxWeaponRange,
    }

    origUnitWeapons[unitDefID] = state

    for i = 1, state.weaponCount do
        local wd = WeaponDefs[ud.weapons[i].weaponDef]
        local reload = wd.reload
        state.weapon[i] = {
            reload = reload,
            projectiles = wd.projectiles or 1,
            oldReloadFrames = floor(reload*Game.gameSpeed),
            range = wd.range,
            sprayAngle = wd.sprayAngle or 0,
            burst=wd.salvoSize or 1,
            burstRate = (wd.salvoDelay or (1/30)),
            damages = GG.ATT_ENABLE_DAMAGE and {},
        }
        if GG.ATT_ENABLE_DAMAGE then
            local armorType = 0
            local data = state.weapon[i].damages
            while wd.damages[armorType] do
                data[armorType] = wd.damages[armorType]
                armorType = armorType + 1
            end
        end
        if wd.type == "LaserCannon" or wd.type == "Cannon" then
            -- Barely works for missiles, and might break their burnblow and prediction
            state.weapon[i].projectileSpeed = wd.projectilespeed
        end
        if wd.type == "BeamLaser" then
            -- beamlasers go screwy if you mess with their burst length
            state.weapon[i].burstRate = false
            state.weapon[i].burst=false
        end
    end
    return state
end

local function list_to_set(list,value)
    if value==nil then
        value=true
    end
    local set={}
    for _, k in pairs(list) do
        set[k]=value
    end
    return set
end



GG.att_ProjSpeed = {}
GG.att_ProjMult = {}
GG.att_DamageMult = {}
GG.att_ReloadChange = {}
GG.att_RangeChange={}
return{
    ---@type AttributesHandlerFactory
    Weapons={
        handledAttributeNames=list_to_set({
            "weaponNum",
            "reload",
            "range",
            "projSpeed",
            "projectiles",
            "damage",
            "burst",
            "burstRate",
            "sprayAngle",
            "minSpray",
        }),
        new=function (unitID, unitDefID)
            local state = origUnitWeapons[unitDefID]

            if not state then
                state=LoadState(unitDefID)
            end

            ---@type AttributesHandler
            return{
                newDataHandler=function (gameFrame)
                    
                    local weaponMods = {
                        def=defaultWeaponSpecificMod()
                    }
                    local minSpray=0
                    ---@type AttributesDataHandler
                    return{
                        fold=function (data)
                            local wepNum=data.weaponNum or "def"
                            local wepData=weaponMods[wepNum]
                            if wepData==nil then
                                wepData=defaultWeaponSpecificMod()
                                weaponMods[wepNum]=wepData
                            end
                            wepData.reloadMult = wepData.reloadMult*(data.reload or 1)
                            wepData.rangeMult = wepData.rangeMult*(data.range or 1)
                            wepData.projSpeedMult = wepData.projSpeedMult*(data.projSpeed or 1)
                            wepData.projectilesMult = wepData.projectilesMult*(data.projectiles or 1)
                            wepData.damageMult=wepData.damageMult*(data.damage or 1)

                            wepData.burstMult=wepData.burstMult*(data.burst or 1)
                            wepData.burstRateMult=wepData.burstRateMult*(data.burstRate or 1)
                            wepData.sprayAngleAdd=wepData.sprayAngleAdd+(data.sprayAngle or 0)
			                minSpray = math.max(minSpray, data.minSpray or 0)

                        end,
                        apply=function ()
                            local wmdef=weaponMods.def
                            spSetUnitRulesParam(unitID, "projectilesMult", wmdef.projectilesMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "projectileSpeedMult", wmdef.projSpeedMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "damageMult", wmdef.damageMult, INLOS_ACCESS)
                            spSetUnitRulesParam(unitID, "rangeMult", wmdef.rangeMult, INLOS_ACCESS)
	                        spSetUnitRulesParam(unitID, "totalReloadSpeedChange", wmdef.reloadMult, INLOS_ACCESS)
                            GG.att_ProjSpeed[unitID] = wmdef.projSpeedMult -- Ignores weapon mods
                            GG.att_ProjMult[unitID] = wmdef.projectilesMult
	                        GG.att_DamageMult[unitID] = wmdef.damageMult
                            GG.att_ReloadChange[unitID] = wmdef.reloadMult
                            GG.att_RangeChange[unitID]=wmdef.rangeMult
                            ApplyWeaponMods(unitID,state,weaponMods,gameFrame,minSpray
                                
                            )
                            
                        end
                    }
                end,
                clear=function ()
                    projectileSpeedLock[unitID]=nil
	                rangeUpdater[unitID] = nil
                    GG.att_ProjSpeed[unitID] = nil -- Ignores weapon mods
                    GG.att_ProjMult[unitID] = nil
                    GG.att_DamageMult[unitID] = nil
                end
            }
        end,
        
        initialize=function ()
            UnitReloadPause=UnitReloadPause or GG.UnitReloadPause
            local Attributes=GG.Attributes
            
            function Attributes.SetProjectileSpeedLock(unitID, lockState)
                projectileSpeedLock[unitID] = lockState
            end

            function Attributes.SetRangeUpdater(unitID, updateFunc)
                rangeUpdater[unitID] = updateFunc
            end
        end,
    }
}