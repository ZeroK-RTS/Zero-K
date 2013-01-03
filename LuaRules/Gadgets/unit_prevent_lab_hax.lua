-- $Id: unit_terraform.lua 3524 2008-12-23 13:21:12Z google frog $
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
  return {
    name      = "Prevent Lab Hax",
    desc      = "Stops enemy units from entering labs. Blocks construction of structures in labs.",
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

local terraunitDefID = UnitDefNames["terraunit"].id

local EXCEPTION_LIST = {
  factoryplane = true,
  factorygunship = true,
  missilesilo = true,
  armasp = true,
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
	  
	    local ux, _, uz, _,_,_, _, aimY  = spGetUnitPosition(id, true, true)
		if aimY > -15 then
		  if (Lv.face == 1) then
		    local l = abs(ux-Lv.minx)
		    local r = abs(ux-Lv.maxx)
		    
		    if (l < r) then
		      spSetUnitPosition(id, Lv.minx, uz, true)
		    else
		      spSetUnitPosition(id, Lv.maxx, uz, true)
		    end
		  else
		    local t = abs(uz-Lv.minz)
		    local b = abs(uz-Lv.maxz)
		    
		    if (t < b) then
		      spSetUnitPosition(id, ux, Lv.minz, true)
		    else
		      spSetUnitPosition(id, ux, Lv.maxz, true)
		    end
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

-- http://springrts.com/mantis/view.php?id=2864
-- http://springrts.com/mantis/view.php?id=2870
local function AllowUnitCreation(unitDefID, builderID, builderTeam, ux, uy, uz, facing) -- engine one does not have facing

    local ud = UnitDefs[unitDefID]

    if unitDefID ~= terraunitDefID and ud and (ud.isBuilding or ud.speed == 0) then
    
        local xsize = ud.xsize*4
        local zsize = (ud.ysize or ud.zsize)*4
        
        local minx, maxx, minz, maxz
		
        if ((facing == 0) or (facing == 2))  then
            
			if xsize%16 == 0 then
				ux = math.floor((ux+8)/16)*16
			else
				ux = math.floor(ux/16)*16+8
			end

			if zsize%16 == 0 then
				uz = math.floor((uz+8)/16)*16
			else
				uz = math.floor(uz/16)*16+8
			end
			
			minx = ux-xsize
            minz = uz-zsize
            maxx = ux+xsize
            maxz = uz+zsize
		else
			if xsize%16 == 0 then
				uz = math.floor((uz+8)/16)*16
			else
				uz = math.floor(uz/16)*16+8
			end

			if zsize%16 == 0 then
				ux = math.floor((ux+8)/16)*16
			else
				ux = math.floor(ux/16)*16+8
			end
		
		    minx = ux-zsize
            minz = uz-xsize
            maxx = ux+zsize
            maxz = uz+xsize
        end        
		
       	--Spring.MarkerAddLine(minx,0,minz,maxx,0,minz)
		--Spring.MarkerAddLine(minx,0,minz,minx,0,maxz)
		--Spring.MarkerAddLine(maxx,0,maxz,maxx,0,minz)
		--Spring.MarkerAddLine(maxx,0,maxz,minx,0,maxz)
		
        for Lid,Lv in pairs(lab) do  
            -- intersection of 2 rectangles
            if Lv.minx < maxx and Lv.maxx > minx and Lv.minz < maxz and Lv.maxz > minz then
                return false
            end
        end
        
    end
    
    return true
end

function gadget:UnitCreated(unitID, unitDefID)
  
  -- http://springrts.com/mantis/view.php?id=2871
  local ux,_,uz,_, uy, _  = spGetUnitPosition(unitID, true)
  local facing = spGetUnitBuildFacing(unitID)
  if not AllowUnitCreation(unitDefID, nil, nil, ux, uy, uz, facing) then
    Spring.DestroyUnit(unitID, false, true)
    return
  end
  -- end 2871
  
  local ud = UnitDefs[unitDefID]
  local name = ud.name
  if (ud.isFactory == true) and not (EXCEPTION_LIST[name]) then
	local ux,_,uz,_, uy, _  = spGetUnitPosition(unitID, true)
	
	if uy > -22 then
		local face = spGetUnitBuildFacing(unitID)
		local xsize = (ud.xsize)*4
		local zsize = (ud.ysize or ud.zsize)*4
		local team = spGetUnitAllyTeam(unitID)

		if ((face == 0) or (face == 2))  then
			if xsize%16 == 0 then
				ux = math.floor((ux+8)/16)*16
			else
				ux = math.floor(ux/16)*16+8
			end

			if zsize%16 == 0 then
				uz = math.floor((uz+8)/16)*16
			else
				uz = math.floor(uz/16)*16+8
			end
		
			lab[unitID] = { team = team, face = 0,
				minx = ux-xsize+0.1, minz = uz-zsize+0.1, maxx = ux+xsize-0.1, maxz = uz+zsize-0.1}
		else
			if xsize%16 == 0 then
				uz = math.floor((uz+8)/16)*16
			else
				uz = math.floor(uz/16)*16+8
			end

			if zsize%16 == 0 then
				ux = math.floor((ux+8)/16)*16
			else
				ux = math.floor(ux/16)*16+8
			end
			
			lab[unitID] = { team = team, face = 1,
				minx = ux-zsize+0.1, minz = uz-xsize+0.1, maxx = ux+zsize-0.1, maxz = uz+xsize-0.1}
		end
	
		--Spring.Echo(xsize)
		--Spring.Echo(zsize)
		
		Spring.MarkerAddLine(lab[unitID].minx,0,lab[unitID].minz,lab[unitID].maxx,0,lab[unitID].minz)
		Spring.MarkerAddLine(lab[unitID].minx,0,lab[unitID].minz,lab[unitID].minx,0,lab[unitID].maxz)
		Spring.MarkerAddLine(lab[unitID].maxx,0,lab[unitID].maxz,lab[unitID].maxx,0,lab[unitID].minz)
		Spring.MarkerAddLine(lab[unitID].maxx,0,lab[unitID].maxz,lab[unitID].minx,0,lab[unitID].maxz)

		lab[unitID].miny = spGetGroundHeight(ux,uz)
		lab[unitID].maxy = lab[unitID].miny+100
		end
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