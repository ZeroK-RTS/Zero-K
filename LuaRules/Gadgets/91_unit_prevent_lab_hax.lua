--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Prevent Lab Hax_91",
		desc      = "Stops enemy units from entering labs. Blocks construction of structures in labs.",
		author    = "Google Frog",
		date      = "Jul 24, 2007", --May 11, 2013
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = (Game.version:find('91.0') == 1)  --  loaded by default?
	}
end

-- Speedups
local spGetGroundHeight        = Spring.GetGroundHeight
local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spGetUnitAllyTeam        = Spring.GetUnitAllyTeam
local spGetUnitsInBox          = Spring.GetUnitsInBox
local spSetUnitPosition        = Spring.SetUnitPosition
local spGetUnitDefID           = Spring.GetUnitDefID
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitDirection       = Spring.GetUnitDirection
local spGetUnitVelocity        = Spring.GetUnitVelocity
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spGetUnitTeam            = Spring.GetUnitTeam
local spGetUnitIsStunned       = Spring.GetUnitIsStunned
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spSetFeaturePosition     = Spring.SetFeaturePosition
local spMoveCtrlGetTag         = Spring.MoveCtrl.GetTag

local abs = math.abs
local min = math.min

local terraunitDefID = UnitDefNames["terraunit"].id

local EXCEPTION_LIST = {
	factorygunship = true,
	missilesilo = true,
	armasp = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local lab = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function checkLabs()
	for Lid,Lv in pairs(lab) do  
		local units = spGetUnitsInBox(Lv.minx-8, Lv.miny, Lv.minz-8, Lv.maxx+8, Lv.maxy, Lv.maxz+8)
		local features = spGetFeaturesInRectangle(Lv.minx, Lv.minz, Lv.maxx, Lv.maxz)

		for i=1,#units do
			local unitID = units[i]
			local unitDefID = spGetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			local movetype = Spring.Utilities.getMovetype(ud)
			local fly = ud.canFly
			local ally = spGetUnitAllyTeam(unitID)
			local team = spGetUnitTeam(unitID)
			if not fly and spMoveCtrlGetTag(unitID) == nil then
				if (ally ~= Lv.ally) then --teleport unit away
					local ux, _, uz, _,_,_, _, aimY  = spGetUnitPosition(unitID, true, true)

					if aimY > -12 then
						local l = abs(ux-Lv.minx)
						local r = abs(ux-Lv.maxx)
						local t = abs(uz-Lv.minz)
						local b = abs(uz-Lv.maxz)

						local side = min(l,r,t,b)

						if (side == l) then
							spSetUnitPosition(unitID, Lv.minx-8, uz, true)
						elseif (side == r) then
							spSetUnitPosition(unitID, Lv.maxx+8, uz, true)
						elseif (side == t) then
							spSetUnitPosition(unitID, ux, Lv.minz-8, true)
						else
							spSetUnitPosition(unitID, ux, Lv.maxz+8, true)
						end

					end		
				elseif (team ~= Lv.team) and movetype then --order unit blocking ally factory to move away (only if it is not a structure)
					local xVel,_,zVel = spGetUnitVelocity(unitID)
					local stunned_or_inbuild = spGetUnitIsStunned(unitID)
					if math.abs(xVel)<0.1 and math.abs(zVel)<0.1 and (not stunned_or_inbuild) then
						local ux, uy, uz  = spGetUnitPosition(unitID)
						local dx,_,dz = spGetUnitDirection(unitID)
						dx = dx*100
						dz = dz*100
						spGiveOrderToUnit(unitID, CMD.INSERT, {0, CMD.MOVE, CMD.OPT_INTERNAL, ux+dx,uy,uz+dz},{"alt"})
					end
				end
			end
		end
		for i=1,#features do
			local featureID = features[i]
			local fx, fy, fz = spGetFeaturePosition(featureID)
			if fy > Lv.miny and fy < Lv.maxy then
				local l = abs(fx-Lv.minx)
				local r = abs(fx-Lv.maxx)
				local t = abs(fz-Lv.minz)
				local b = abs(fz-Lv.maxz)

				local side = min(l,r,t,b)

				if (side == l) then
					spSetFeaturePosition(featureID, Lv.minx, fy, fz, true)
				elseif (side == r) then
					spSetFeaturePosition(featureID, Lv.maxx, fy, fz, true)
				elseif (side == t) then
					spSetFeaturePosition(featureID, fx, fy, Lv.minz, true)
				else
					spSetFeaturePosition(featureID, fx, fy, Lv.maxz, true)
				end
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

function gadget:UnitCreated(unitID, unitDefID,teamID)
  
	if reverseCompat then
		-- http://springrts.com/mantis/view.php?id=2871
		local ux,_,uz,_, uy, _  = spGetUnitPosition(unitID, true)
		local facing = spGetUnitBuildFacing(unitID)
		if not AllowUnitCreation(unitDefID, nil, nil, ux, uy, uz, facing) then
			Spring.DestroyUnit(unitID, false, true)
			return
		end
		-- end 2871
	end
  
	local ud = UnitDefs[unitDefID]
	local name = ud.name
	if (ud.isFactory == true) and not (EXCEPTION_LIST[name]) then
		local ux,_,uz,_, uy, _  = spGetUnitPosition(unitID, true)
		if uy > -22 then
			local face = spGetUnitBuildFacing(unitID)
			local xsize = (ud.xsize)*4
			local zsize = (ud.ysize or ud.zsize)*4
			local ally = spGetUnitAllyTeam(unitID)

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

				lab[unitID] = { ally = ally, team=teamID, face = 0,
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

				lab[unitID] = { ally = ally, team=teamID, face = 1,
				minx = ux-zsize+0.1, minz = uz-xsize+0.1, maxx = ux+zsize-0.1, maxz = uz+xsize-0.1}
			end

			--Spring.Echo(xsize)
			--Spring.Echo(zsize)

			--Spring.MarkerAddLine(lab[unitID].minx,0,lab[unitID].minz,lab[unitID].maxx,0,lab[unitID].minz)
			--Spring.MarkerAddLine(lab[unitID].minx,0,lab[unitID].minz,lab[unitID].minx,0,lab[unitID].maxz)
			--Spring.MarkerAddLine(lab[unitID].maxx,0,lab[unitID].maxz,lab[unitID].maxx,0,lab[unitID].minz)
			--Spring.MarkerAddLine(lab[unitID].maxx,0,lab[unitID].maxz,lab[unitID].minx,0,lab[unitID].maxz)

			local _,sizeY,_,_,offsetY = Spring.GetUnitCollisionVolumeData(unitID)
			lab[unitID].miny = uy + offsetY - sizeY/2 --set the box bottom
			lab[unitID].maxy = uy + offsetY + 150 --set the box height +200 elmo above the factory midpoint

		end
	end

end

function gadget:UnitDestroyed(unitID, unitDefID)
	if (lab[unitID]) then
		lab[unitID] = nil
	end
end

function gadget:UnitGiven(unitID, unitDefID,unitTeam)
	if (lab[unitID]) then
		lab[unitID].ally = spGetUnitAllyTeam(unitID)
		lab[unitID].team = unitTeam
	end
end

function gadget:GameFrame(n)
	checkLabs()
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end