--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
	return {
		name      = "Prevent Lab Hax",
		desc      = "Stops enemy units from entering labs.",
		author    = "Google Frog",
		date      = "Jul 24, 2007", --May 11, 2013
		license   = "GNU GPL, v2 or later",
		layer     = 0,
		enabled   = not (Game.version:find('91.0') == 1)  --  loaded by default?
	}
end

-- Speedups
local spGetGroundHeight        = Spring.GetGroundHeight
local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spGetUnitAllyTeam        = Spring.GetUnitAllyTeam
local spGetUnitsInRectangle    = Spring.GetUnitsInRectangle
local spSetUnitPosition        = Spring.SetUnitPosition
local spGetUnitDefID           = Spring.GetUnitDefID
local spGetUnitPosition        = Spring.GetUnitPosition
local spGetUnitDirection       = Spring.GetUnitDirection
local spGetUnitVelocity        = Spring.GetUnitVelocity
local spSetUnitVelocity        = Spring.SetUnitVelocity
local spGiveOrderToUnit        = Spring.GiveOrderToUnit
local spGetUnitTeam            = Spring.GetUnitTeam
local spGetUnitIsStunned       = Spring.GetUnitIsStunned
local spGetFeaturesInRectangle = Spring.GetFeaturesInRectangle
local spGetFeaturePosition     = Spring.GetFeaturePosition
local spSetFeaturePosition     = Spring.SetFeaturePosition
local spSetFeatureVelocity     = Spring.SetFeatureVelocity
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

local labs = {}
local labList = {count = 0, data = {}}

local function removeLab(unitID)
	labs[labList.data[labList.count] ] = labs[unitID]
	labList.data[labs[unitID]] = labList.data[labList.count]
	labList.data[labList.count] = nil
	labs[unitID] = nil
	labList.count = labList.count - 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function checkLabs(checkFeatures)
	local labData = labList.data
	local data, units, features
	for i = 1, labList.count do
		data = labData[i]
		units = spGetUnitsInRectangle(data.minx-8, data.minz-8, data.maxx+8, data.maxz+8)
		features = spGetFeaturesInRectangle(data.minx, data.minz, data.maxx, data.maxz)

		for i=1,#units do
			local unitID = units[i]
			local unitDefID = spGetUnitDefID(unitID)
			local ud = UnitDefs[unitDefID]
			local movetype = Spring.Utilities.getMovetype(ud)
			local fly = ud.canFly
			local ally = spGetUnitAllyTeam(unitID)
			local team = spGetUnitTeam(unitID)
			if not fly and spMoveCtrlGetTag(unitID) == nil then
				if (ally ~= data.ally) then --teleport unit away
					local ux, _, uz, _,_,_, _, aimY  = spGetUnitPosition(unitID, true, true)
					local vx, vy, vz = spGetUnitVelocity(unitID)

					if aimY > -12 and aimY >= data.miny and aimY <= data.maxy then
						local l = abs(ux-data.minx)
						local r = abs(ux-data.maxx)
						local t = abs(uz-data.minz)
						local b = abs(uz-data.maxz)

						local side = min(l,r,t,b)

						if (side == l) then
							spSetUnitPosition(unitID, data.minx-8, uz, true)
							spSetUnitVelocity(unitID, 0, vy, vz)
						elseif (side == r) then
							spSetUnitPosition(unitID, data.maxx+8, uz, true)
							spSetUnitVelocity(unitID, vx, vy, 0)
						elseif (side == t) then
							spSetUnitPosition(unitID, ux, data.minz-8, true)
							spSetUnitVelocity(unitID, 0, vy, vz)
						else
							spSetUnitPosition(unitID, ux, data.maxz+8, true)
							spSetUnitVelocity(unitID, vx, vy, 0)
						end

					end		
				elseif (team ~= data.team) and movetype then --order unit blocking ally factory to move away (only if it is not a structure)
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
		if checkFeatures then
			for i=1,#features do
				local featureID = features[i]
				local fx, fy, fz = spGetFeaturePosition(featureID)
				if fy > data.miny and fy < data.maxy then
					local l = abs(fx-data.minx)
					local r = abs(fx-data.maxx)
					local t = abs(fz-data.minz)
					local b = abs(fz-data.maxz)

					local side = min(l,r,t,b)
					if (side == l) then
						spSetFeaturePosition(featureID, data.minx, fy, fz, true)
					elseif (side == r) then
						spSetFeaturePosition(featureID, data.maxx, fy, fz, true)
					elseif (side == t) then
						spSetFeaturePosition(featureID, fx, fy, data.minz, true)
					else
						spSetFeaturePosition(featureID, fx, fy, data.maxz, true)
					end
					spSetFeatureVelocity(featureID, 0, 0, 0)
				end
			end
		end
	end
end

function gadget:UnitCreated(unitID, unitDefID,teamID)
	local ud = UnitDefs[unitDefID]
	if (ud.isFactory == true) and not (EXCEPTION_LIST[ud.name]) then
		local ux,_,uz,_, uy, _  = spGetUnitPosition(unitID, true)
		if uy > -22 then
			local face = spGetUnitBuildFacing(unitID)
			local xsize = (ud.xsize)*4
			local zsize = (ud.ysize or ud.zsize)*4
			local ally = spGetUnitAllyTeam(unitID)
			local minx, minz, maxx, maxz

			local _,sizeY,_,_,offsetY = Spring.GetUnitCollisionVolumeData(unitID)
			local miny = uy + offsetY - sizeY/2 --set the box bottom
			local maxy = uy + offsetY + 150 --set the box height +200 elmo above the factory midpoint
			
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
				
				minx = ux-xsize+0.1
				minz = uz-zsize+0.1
				maxx = ux+xsize-0.1
                maxz = uz+zsize-0.1
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

				minx = ux-zsize+0.1
				minz = uz-xsize+0.1
				maxx = ux+zsize-0.1
				maxz = uz+xsize-0.1
			end
			
			labList.count = labList.count + 1
			labList.data[labList.count] = { 
				ally = ally, 
				team=teamID, 
				face = 0,
				minx = minx,
				miny = miny,
				minz = minz,
				maxx = maxx,
				maxy = maxy,
				maxz = maxz,
			}
			labs[unitID] = labList.count

			--Spring.Echo(xsize)
			--Spring.Echo(zsize)

			--Spring.MarkerAddLine(minx,0,minz,maxx,0,minz)
			--Spring.MarkerAddLine(minx,0,minz,minx,0,maxz)
			--Spring.MarkerAddLine(maxx,0,maxz,maxx,0,minz)
			--Spring.MarkerAddLine(maxx,0,maxz,minx,0,maxz)
		end
	end

end

function gadget:UnitDestroyed(unitID, unitDefID)
	if (labs[unitID]) then
		removeLab(unitID)
	end
end

function gadget:UnitGiven(unitID, unitDefID,unitTeam)
	if (labs[unitID]) then
		labList.data[lab[unitID]].ally = spGetUnitAllyTeam(unitID)
		labList.data[lab[unitID]].team = unitTeam
	end
end

function gadget:GameFrame(n)
	if n%5 == 0 then
		checkLabs(n%60 == 0)
	end
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i=1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end