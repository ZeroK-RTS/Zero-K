--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Reduced Quality Units",
    desc      = "Units changing control (such as share, capture, rez) get reduced stats. If new owner is of the same faction then stats are reverted after 3 minutes.", 
    author    = "CarRepairer",
    date      = "2009-09-20",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = false  --  loaded by default?
  }
end

if not ( Spring.GetModOptions() and tobool(Spring.GetModOptions().reducedquality) ) then
	return
end


local echo = Spring.Echo

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then
  
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
  
local spGetGameFrame 		= Spring.GetGameFrame
local spSetUnitTooltip 		= Spring.SetUnitTooltip
local spSetUnitMaxHealth 	= Spring.SetUnitMaxHealth
local spSetUnitWeaponState 	= Spring.SetUnitWeaponState
local spGetUnitDefID 		= Spring.GetUnitDefID
  
local factions = {}

local dysfunctimes = {}
local dysfuncfactions = {}

local timerange_frames = 32*3*60
--local timerange_frames = 32*20

local getfactions = true
local gotfactions = false
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function GetFaction(udid)
	local udef_factions = UnitDefs[udid].factions or {}
	return ((#udef_factions~=1) and 'unknown') or udef_factions[1]
end


function gadget:UnitCreated(unitID, unitDefID, unitTeam)

	local ud = UnitDefs[unitDefID]
	if not ud then return end
	
	if not gotfactions then
		local unitName = ud.name
		if unitName == 'armcom' then
			factions[unitTeam] = 'arm'
		elseif unitName == 'corcom' then
			factions[unitTeam] = 'core'
		elseif unitName == 'chickenbroodqueen' then
			factions[unitTeam] = 'chicken'
		end
		return
	end
	
	local unitfaction = GetFaction(unitDefID)
	local teamfaction = factions[unitTeam]
	if unitfaction ~= teamfaction then
		gadget:UnitGiven(unitID, unitDefID, unitTeam)
	end
end

function gadget:UnitGiven(unitID, unitDefID, newTeamID)
	local ud = UnitDefs[unitDefID]
	if not ud then return end
	
	spSetUnitTooltip(unitID,ud.humanName .. " - " .. ud.tooltip .. ' (faulty)' )
	spSetUnitMaxHealth(unitID, ud.health * 0.9)
	if ud.weapons then
		for i,w in ipairs(ud.weapons) do
			local origReload = WeaponDefs[w.weaponDef].reload
			local origAcc = WeaponDefs[w.weaponDef].accuracy
			spSetUnitWeaponState(unitID, i-1, {reloadTime = origReload*1.5, accuracy = origAcc*5} )
		end
	end
	
	local unitfaction = GetFaction(unitDefID)
	local teamfaction = factions[newTeamID]
	
	if unitfaction == teamfaction then
		dysfunctimes[unitID] = spGetGameFrame()
		dysfuncfactions[unitID] = GetFaction(unitDefID)
	end
	
	SendToUnsynced("add_dysfunc_unit", unitID)
end


function gadget:GameFrame(n)
	local frame64 = n%64
	if frame64 == 0 then
		for unitID, frame in pairs(dysfunctimes) do
			if n > frame + timerange_frames then
				local udid = spGetUnitDefID(unitID)
				if udid then
					local ud = UnitDefs[udid]
					if ud then
						spSetUnitTooltip(unitID,ud.humanName .. " - " .. ud.tooltip  )
						spSetUnitMaxHealth(unitID, ud.health)
						if ud.weapons then
							for i,w in ipairs(ud.weapons) do
								local origReload = WeaponDefs[w.weaponDef].reload
								local origAcc = WeaponDefs[w.weaponDef].accuracy
								spSetUnitWeaponState(unitID, i-1, {reloadTime = origReload, accuracy = origAcc} )
							end
						end
					end
					SendToUnsynced("rem_dysfunc_unit", unitID)
				end
				dysfunctimes[unitID] = nil
				dysfuncfactions[unitID] = nil
			end
		end
	end
	
	if getfactions and Spring.GetGameSeconds() > 3 then
		gadget:Initialize()
		gotfactions = true
		getfactions = false
	end
end

function gadget:Initialize() 
	for _,unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		local unitTeam = Spring.GetUnitTeam(unitID)
		if unitDefID and unitTeam then
			gadget:UnitCreated(unitID, unitDefID, unitTeam)
		end

	end
end

--------------------------------------------------------------------
-- unsynced code
--------------------------------------------------------------------
else

include("LuaUI/Configs/lupsFXs.lua")

local UnitEffects = {}
local Lups  -- Lua Particle System
local LupsAddFX
local particleIDs = {}
local initialized = false --// if LUPS isn't started yet, we try it once a gameframe later
local tryloading  = 1     --// try to activate lups if it isn't found

local initialized=false

Lups = GG['Lups']
local effects

--------------------------------------------------------------------
	

local function AddFxs(unitID,fxID)
	if (not particleIDs[unitID]) then
		particleIDs[unitID] = {}
	end
	local unitFXs = particleIDs[unitID]
	unitFXs[#unitFXs+1] = fxID
end
local function MergeTable(table2,table1)

  local result = {}
  for i,v in pairs(table2) do 
    if (type(v)=='table') then
      result[i] = MergeTable(v,{})
    else
      result[i] = v
    end
  end
  for i,v in pairs(table1) do 
    if (result[i]==nil) then
      if (type(v)=='table') then
        if (type(result[i])~='table') then result[i] = {} end
        result[i] = MergeTable(v,result[i])
      else
        result[i] = v
      end
    end
  end
  return result
end

--------------------------------------------------------------------


local function add_dysfunc_unit(_, unitID)
  if not initialized then return end
  local val = math.random()*60+1
	effects = {
		{class='SimpleParticles2',options=MergeTable({piece="head", delay=val, life = val,lifeSpread = val, },sparks1)},
		{class='SimpleParticles2',options=MergeTable({piece="barrel", delay=val,  life = val,lifeSpread = val,  },sparks1)},
		{class='SimpleParticles2',options=MergeTable({piece="body", delay=val,  life = val,lifeSpread = val,  },sparks1)},
		{class='SimpleParticles2',options=MergeTable({piece="base", delay=val,  life = val,lifeSpread = val,  },sparks1)},
		{class='Sound',options={repeatEffect=true, file="Sparks", blockfor=4.8*30, length=5.1*30}},
	}  
    for _,fx in ipairs(effects) do
		fx.options.unit = unitID
		AddFxs( unitID,LupsAddFX(fx.class,fx.options) )
		fx.options.unit = nil
    end
end


local function rem_dysfunc_unit(_, unitID)
  if not initialized then return end
	if (particleIDs[unitID]) then
		for _,fxID in ipairs(particleIDs[unitID]) do
			Lups.RemoveParticles(fxID)
		end
		particleIDs[unitID] = nil
	end
end


function gadget:Initialize() 
	gadgetHandler:AddSyncAction("add_dysfunc_unit", add_dysfunc_unit)
	gadgetHandler:AddSyncAction("rem_dysfunc_unit", rem_dysfunc_unit)
end

function gadget:Update()
  Lups = GG['Lups']
    if (Lups) then
		LupsAddFX = Lups.AddParticles
		if not initialized then
			initialized=true
		end
	
	else
		return
	end	
end

--------------------------------------------------------------------
-- end unsynced code
--------------------------------------------------------------------
end
