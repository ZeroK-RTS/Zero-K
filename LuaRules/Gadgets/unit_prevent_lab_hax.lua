-- $Id: unit_terraform.lua 3524 2008-12-23 13:21:12Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Prevent Lab Hax",
    desc      = "Stops enemy units from entering labs",
    author    = "Google Frog",
    date      = "Jul 24, 2007",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if (gadgetHandler:IsSyncedCode()) then

--------------------------------------------------------------------------------
-- SYNCED
--------------------------------------------------------------------------------
  
-- Speedups
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetUnitBuildFacing  = Spring.GetUnitBuildFacing
local spGetUnitAllyTeam  = Spring.GetUnitAllyTeam
local spGetUnitsInBox  = Spring.GetUnitsInBox
local spSetUnitPosition  = Spring.SetUnitPosition
local spGetUnitDefID = Spring.GetUnitDefID
local spGetUnitPosition = Spring.GetUnitPosition

local abs = math.abs
local min = math.min

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local customSettings = {
	corsy = {xsize = 32, zsize = 8, dispFacing = 0, dispRAngle = 32, reorient = true}
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lab = {}
_G.lab = lab

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function checkLabs()
  for Lid,Lv in pairs(lab) do  
    local units = spGetUnitsInBox(Lv.minx, Lv.miny, Lv.minz, Lv.maxx, Lv.maxy, Lv.maxz)
	
    for i,id in ipairs(units) do 
	  local ud = spGetUnitDefID(id)
	  local fly = UnitDefs[ud].canFly
	  local team = spGetUnitAllyTeam(id)
	  if (team ~= Lv.team) and not fly then
	  
	    local ux, _, uz  = spGetUnitPosition(id)
		
		if (Lv.face == 1) then
		  local l = abs(ux-Lv.minx)
		  local r = abs(ux-Lv.maxx)
		  
		  if (l < r) then
		    spSetUnitPosition(id, Lv.minx, uz)
		  else
		    spSetUnitPosition(id, Lv.maxx, uz)
		  end
		else
		  local t = abs(uz-Lv.minz)
		  local b = abs(uz-Lv.maxz)
		  
		  if (t < b) then
		    spSetUnitPosition(id, ux, Lv.minz)
		  else
		    spSetUnitPosition(id, ux, Lv.maxz)
		  end
		end
		--[[
		local l = abs(ux-Lv.minx)
		local r = abs(ux-Lv.maxx)
		local t = abs(uz-Lv.minz)
		local b = abs(uz-Lv.maxz)
		
		local side = min(l,r,t,b)
		
		if (side == l) then
		  spSetUnitPosition(id, Lv.minx, uz)
		elseif (side == r) then
		  spSetUnitPosition(id, Lv.maxx, uz)
		elseif (side == t) then
		  spSetUnitPosition(id, ux, Lv.minz)
		else
		  spSetUnitPosition(id, ux, Lv.maxz)
		end
		--]]
	  end
	end
	
  end
end

function gadget:UnitCreated(unitID, unitDefID)
  local ud = UnitDefs[unitDefID]
  local name = ud.name
  if (ud.isFactory == true) and not (name == "factoryplane" or name == "factorygunship") then
	local customData = customSettings[name] or {}
	local ux, uy, uz  = spGetUnitPosition(unitID)
	local face = spGetUnitBuildFacing(unitID)
	local xsize = (customData.xsize or ud.xsize)*4
	local zsize = (customData.zsize or ud.ysize or ud.zsize)*4
	local team = spGetUnitAllyTeam(unitID)
	
	local dispF = (customData.dispFacing or 0)
	local dispR = (customData.dispRAngle or 0)
	if face == 0 then
		uz = uz + dispF
		ux = ux + dispR
	elseif face == 1 then
		uz = uz - dispR
		ux = ux - dispF
	elseif face == 2 then
		uz = uz - dispF
		ux = ux - dispR
	else
		uz = uz + dispR
		ux = ux + dispF
	end
	
	if ((face == 0) or (face == 2))  then
	  lab[unitID] = { team = team, face = 1 - (customData.reorient and 0 or 1),
	  minx = ux-zsize, minz = uz-xsize, maxx = ux+zsize, maxz = uz+xsize}
	else
	  lab[unitID] = { team = team, face = 1 - (customData.reorient and 1 or 0),
	  minx = ux-xsize, minz = uz-zsize, maxx = ux+xsize, maxz = uz+zsize}
	end
	
	lab[unitID].miny = spGetGroundHeight(ux,uz)
	lab[unitID].maxy = lab[unitID].miny+100
	
  end
  
end

function gadget:UnitDestroyed(unitID, unitDefID)
  if (lab[unitID]) then
    lab[unitID] = nil
  end
end

function gadget:UnitGiven(unitID, unitDefID)
  if (lab[unitID]) then
    lab[unitID].team = spGetUnitAllyTeam(unitID)
  end
end

function gadget:GameFrame(n)
 
  checkLabs()
  --[[
  if (n%20<1) then 
	checkLabs()
  end
  --]]
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end

else
--------------------------------------------------------------------------------
-- UNSYNCED
--------------------------------------------------------------------------------
local debugMode = false

local lab = SYNCED.lab

function gadget:DrawWorld()
	if not debugMode then return end
	gl.Color(1,0,0,0.75)
	for i,v in spairs(lab) do
		gl.DrawGroundQuad(v.minx, v.minz, v.maxx, v.maxz )
	end
	gl.Color(1,1,1,1)
end


end