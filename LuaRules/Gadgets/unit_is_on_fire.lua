-- $Id: unit_is_on_fire.lua 3309 2008-11-28 04:25:20Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Units on fire",
    desc      = "Aaagh! It burns! It burns!",
    author    = "quantum",
    date      = "Mar, 2008",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local SAVE_FILE = "Gadgets/unit_is_on_fire.lua"
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------

--// customparams values
-- setunitsonfire:
--    iff a weapon has this tag set to anything it will set units on fire.
-- burntime:
--    burntime of weapon in frames. defaults to DEFAULT_BURN_TIME*firestarter/100
-- burntimerand:
--    adds randomness to burntime. Defaults to DEFAULT_BURN_TIME_RANDOMNESS
--    Constant random distribution over domain [burntime*(1-burnTimeRand),burntime].
-- burnchance:
--    Chance of a unit to be set on fire when hit. Defaults to firestarter/1000
-- burndamage:
--    Damage per frame of burning. Defaults to DEFAULT_BURN_DAMAGE

--//SETTINGS

local DEFAULT_BURN_TIME = 450
local DEFAULT_BURN_TIME_RANDOMNESS = 0.3
local DEFAULT_BURN_DAMAGE = 0.5
local MIN_IMMERSION_FOR_EXTINGUISH = 0.8

local CHECK_INTERVAL = 6

local LOS_ACCESS = {inlos = true}

local RESEND_DELAY = 150
local sendOnFireUnits = false
local sentOnFireTime = {}

--//VARS

local gameFrame = 0

--//LOCALS

local random = math.random
local Spring = Spring
local gadget = gadget
local AreTeamsAllied    = Spring.AreTeamsAllied
local AddUnitDamage     = Spring.AddUnitDamage
local SetUnitRulesParam = Spring.SetUnitRulesParam
local SetUnitCloak      = Spring.SetUnitCloak

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function cpv(value)
	return value and tonumber(value)
end

-- NOTE: fireStarter is divided by 100 somewhere in the engine between weapon defs and here.

local flamerWeaponDefs = {}
for i = 1, #WeaponDefs do
	local wcp = WeaponDefs[i].customParams or {}
	if (wcp.setunitsonfire) then -- stupid tdf
		--// (fireStarter-tag: 1.0->always flame trees, 2.0->always flame units/buildings too) -- citation needed
	
		flamerWeaponDefs[i] = {
			burnTime = cpv(wcp.burntime) or WeaponDefs[i].fireStarter*DEFAULT_BURN_TIME,
			burnTimeRand = cpv(wcp.burntimerand) or DEFAULT_BURN_TIME_RANDOMNESS,
			burnTimeBase = 1 - (cpv(wcp.burntimerand) or DEFAULT_BURN_TIME_RANDOMNESS),
			burnChance = cpv(wcp.burnchance) or WeaponDefs[i].fireStarter/10,
			burnDamage = cpv(wcp.burndamage) or DEFAULT_BURN_DAMAGE,
		}
		
		flamerWeaponDefs[i].maxDamage = flamerWeaponDefs[i].burnDamage*flamerWeaponDefs[i].burnTime
	end
end

local fireproof = {}
for i = 1, #UnitDefs do
	fireproof[i] = (UnitDefs[i].customParams.fireproof == "1")
end

local unitsOnFire = {}
local inWater = {}
local inGameFrame = false

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local function CheckImmersion(unitID)
	local pos = select(2, Spring.GetUnitBasePosition(unitID))
	local height = Spring.GetUnitHeight(unitID)
	if pos < -(height * MIN_IMMERSION_FOR_EXTINGUISH) then
		return true
	end
	return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function SetFireGameRulesParamQueue(unitID)
	local gameFrame = false
	if unitsOnFire[unitID] then
		gameFrame = Spring.GetGameFrame()
		if (sentOnFireTime[unitID] or -2*RESEND_DELAY) + RESEND_DELAY >= gameFrame then
			return
		end
	end
	sendOnFireUnits = sendOnFireUnits or {}
	sendOnFireUnits[#sendOnFireUnits + 1] = unitID
	sentOnFireTime[unitID] = gameFrame or Spring.GetGameFrame()
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:UnitEnteredWater(unitID, unitDefID, unitTeam)
	inWater[unitID] = true
end

function gadget:UnitLeftWater(unitID, unitDefID, unitTeam)
	inWater[unitID] = nil
end

function gadget:UnitDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponID,
                            attackerID, attackerDefID, attackerTeam)
	if inGameFrame then
		-- ignore own AddUnitDamage calls
		-- FIXME: just toggle the callin in GameFrame
		return
	end

	local fwd = flamerWeaponDefs[weaponID]
	if not fwd then
		return
	end

	if fireproof[unitDefID] then
		return
	end

	if random() > fwd.burnChance then
		return
	end

	local burnLength = fwd.burnTime*(random()*fwd.burnTimeRand + fwd.burnTimeBase)
	if unitsOnFire[unitID] and unitsOnFire[unitID].damageLeft > (burnLength*fwd.burnDamage) then
		return
	end

	SetFireGameRulesParamQueue(unitID)

	unitsOnFire[unitID] = {
		endFrame    = gameFrame + burnLength,
		damageLeft  = burnLength*fwd.burnDamage,
		fireDmg     = fwd.burnDamage,
		attackerID  = attackerID,
		--attackerDefID = attackerDefID,
		weaponID    = weaponID,
	}
	SetUnitRulesParam(unitID, "on_fire", 1, LOS_ACCESS)
	GG.UpdateUnitAttributes(unitID)
end

function gadget:UnitDestroyed(unitID)
	inWater[unitID] = nil
	if (unitsOnFire[unitID]) then
		unitsOnFire[unitID] = nil
	end
end

function gadget:GameFrame(n)
	gameFrame = n
	if (n%CHECK_INTERVAL < 1) and (next(unitsOnFire)) then
		local cnt = 1
		inGameFrame = true
		for unitID, t in pairs(unitsOnFire) do
			if (n > t.endFrame) or (inWater[unitID] and CheckImmersion(unitID)) then
				SetUnitRulesParam(unitID, "on_fire", 0)
				GG.UpdateUnitAttributes(unitID)
				unitsOnFire[unitID] = nil
			else
				t.damageLeft = t.damageLeft - t.fireDmg*CHECK_INTERVAL
				AddUnitDamage(unitID,t.fireDmg*CHECK_INTERVAL,0,t.attackerID, t.weaponID )
				cnt=cnt+1
			end
		end
		inGameFrame = false
	end
	if sendOnFireUnits then
		if #sendOnFireUnits == 0 then
			Spring.SetGameRulesParam("unitOnFireUpdateUnitID", nil)
			sendOnFireUnits = false
		else
			Spring.SetGameRulesParam("unitOnFireUpdateUnitID", sendOnFireUnits[#sendOnFireUnits])
			sendOnFireUnits[#sendOnFireUnits] = nil
		end
	end
end

function gadget:Initialize()
	Spring.SetGameRulesParam("unitsOnFire",1)
	local allUnits = Spring.GetAllUnits()
	for i=1,#allUnits do
		local unitID = allUnits[i]
		local x,y,z = Spring.GetUnitPosition(unitID)
		if y < 0 then
			gadget:UnitEnteredWater(unitID)
		end
	end
end

end
