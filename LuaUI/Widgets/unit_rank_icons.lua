-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Rank Icons 2",
    desc      = "Adds a rank icon depending on experience next to units (needs Unit Icons)",
    author    = "trepan (idea quantum,jK), CarRepairer tweak",
    date      = "Feb 2008, Oct 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 5,
    enabled   = true,  -- loaded by default?
	handler	 = true, --allow widget to use special widgetHandler's function
  }
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

-- speed-ups
local GetUnitDefID         = Spring.GetUnitDefID
local GetUnitExperience    = Spring.GetUnitExperience
local GetAllUnits          = Spring.GetAllUnits
local IsUnitAllied         = Spring.IsUnitAllied
local GetSpectatingState   = Spring.GetSpectatingState

local min   = math.min
local floor = math.floor

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

local PWranks = { [0] = {}, [1] = {}, [2] = {}, [3] = {}, [4] = {} }

local PWUnits = {}

local myAllyTeamID = 666


local rankTexBase = 'LuaUI/Images/Ranks/'
local rankTextures = {
  [0] = nil,
  [1] = rankTexBase .. 'rank1.png',
  [2] = rankTexBase .. 'rank2.png',
  [3] = rankTexBase .. 'rank3.png',
  [4] = rankTexBase .. 'star.png',
}
local PWrankTextures = {
  [0] = rankTexBase .. 'PWrank0.png',
  [1] = rankTexBase .. 'PWrank1.png',
  [2] = rankTexBase .. 'PWrank2.png',
  [3] = rankTexBase .. 'PWrank3.png',
  [4] = rankTexBase .. 'PWstar.png',
}

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function PWCreate(unitID)
  PWUnits[unitID] = true
  SetUnitRank(unitID)
end

function widget:Initialize()
	if (not WG.icons) or (#WG.icons==0) then --if "Unit Icons" not enabled, then enable it.
		widgetHandler:EnableWidget("Unit Icons")
	end

	widgetHandler:RegisterGlobal("PWCreate", PWCreate)
	WG.icons.SetOrder( 'rank', 1 )

	for udid, ud in pairs(UnitDefs) do
		-- 0.15+2/(1.2+math.exp(Unit.power/1000))
		ud.power_xp_coeffient  = ((ud.power / 1000) ^ -0.2) / 6  -- dark magic
	end

	for _,unitID in pairs( GetAllUnits() ) do
		SetUnitRank(unitID)
	end
end

function widget:Shutdown()
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function SetUnitRank(unitID)
  local ud = UnitDefs[GetUnitDefID(unitID)]
  if (ud == nil) then
    return
  end

  local xp = GetUnitExperience(unitID)
  if (not xp) then
    return
  end
  xp = min(floor(xp / ud.power_xp_coeffient),4)

  if not PWUnits[unitID] then
    if (xp>0) then
	  WG.icons.SetUnitIcon( unitID, {name='rank', texture=rankTextures[xp] } )
    end
  else
    PWranks[xp][unitID] = true
  end
end



-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function widget:UnitExperience(unitID,unitDefID,unitTeam, xp, oldXP)
  local ud = UnitDefs[unitDefID]
  if (ud == nil) then
    return
  end
  if xp < 0 then xp = 0 end
  if oldXP < 0 then oldXP = 0 end
  
  local rank    = min(floor(xp / ud.power_xp_coeffient),4)
  local oldRank = min(floor(oldXP / ud.power_xp_coeffient),4)

  if (rank~=oldRank) then
  if not PWUnits[unitID] then
      WG.icons.SetUnitIcon( unitID, {name='rank', texture=rankTextures[rank]} )
    else
      for i=0,rank-1 do PWranks[i][unitID] = nil end
      PWranks[rank][unitID] = true
    end
  end
end

function widget:UnitCreated(unitID, unitDefID, unitTeam)
  if (IsUnitAllied(unitID)or(GetSpectatingState())) then
    SetUnitRank(unitID)
  end
end


function widget:UnitDestroyed(unitID, unitDefID, unitTeam)
  WG.icons.SetUnitIcon( unitID, {name='rank', texture=nil} )
  PWUnits[unitID] = nil
end


function widget:UnitGiven(unitID, unitDefID, oldTeam, newTeam)
  if (not IsUnitAllied(unitID))and(not GetSpectatingState())  then
    WG.icons.SetUnitIcon( unitID, {name='rank', texture=nil} )
  end
end

--[[
--needed if icon widget gets disabled/enabled after this one. find a better way?
function widget:GameFrame(f)
  if f%(32*5) == 0 then --5 seconds
	for _,unitID in pairs( GetAllUnits() ) do
	  SetUnitRank(unitID)
	end
  end
end
--]]
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
