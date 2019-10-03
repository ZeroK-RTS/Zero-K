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
		enabled   = true  --  loaded by default?
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

local FEATURE_ONLY = {
	factorygunship = true,
	staticmissilesilo = true,
	staticrearm = true,
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local labs = {}
local labList = {count = 0, data = {}}

local function RemoveLab(unitID)
	labs[labList.data[labList.count].unitID ] = labs[unitID]
	labList.data[labs[unitID] ] = labList.data[labList.count]
	labList.data[labList.count] = nil
	labs[unitID] = nil
	labList.count = labList.count - 1
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Periodic unit and feature check

local function CheckLabs(checkFeatures, onlyUnstick)
	local labData = labList.data
	local data, units, features
	for i = 1, labList.count do
		data = labData[i]
		
		if data.unstickHelp or (not onlyUnstick) then
			local clearUnits = data.unitExpulsionParameters
			if clearUnits then
				units = spGetUnitsInRectangle(clearUnits[1], clearUnits[2], clearUnits[3], clearUnits[4])
				for j = 1, #units do
					local unitID = units[j]
					local unitDefID = spGetUnitDefID(unitID)
					local ud = UnitDefs[unitDefID]
					local movetype = Spring.Utilities.getMovetype(ud)
					local ally = spGetUnitAllyTeam(unitID)
					local team = spGetUnitTeam(unitID)
					if (not ud.canFly) and (spMoveCtrlGetTag(unitID) == nil) then
						if (ally ~= data.ally) or (data.unstickHelp and not ud.isImmobile) then --teleport unit away
							local ux, _, uz, _,_,_, _, aimY  = spGetUnitPosition(unitID, true, true)
							local vx, vy, vz = spGetUnitVelocity(unitID)
							
							if aimY > -18 and aimY >= clearUnits[5] and aimY <= clearUnits[6] then
								local isAlly = ally == data.ally
								
								local l = abs(ux - clearUnits[1])
								local t = abs(uz - clearUnits[2])
								local r = abs(ux - clearUnits[3])
								local b = abs(uz - clearUnits[4])
								
								local pushDistance = (data.unstickHelp and 16) or 8

								local side = min(l,r,t,b)

								if not (isAlly and ux > data.minBuildX and ux < data.maxBuildX and uz > data.minBuildZ and uz < data.maxBuildZ) then
									if (side == l) then
										spSetUnitPosition(unitID, clearUnits[1] - pushDistance, uz, true)
										if data.unstickHelp then
											spSetUnitVelocity(unitID, vx, vy, vz/2)
										else
											spSetUnitVelocity(unitID, 0, vy, vz)
										end
									elseif (side == t) then
										spSetUnitPosition(unitID, ux, clearUnits[2] - pushDistance, true)
										if data.unstickHelp then
											spSetUnitVelocity(unitID, vx, vy, vz/2)
										else
											spSetUnitVelocity(unitID, vx, vy, 0)
										end
									elseif (side == r) then
										spSetUnitPosition(unitID, clearUnits[3] + pushDistance, uz, true)
										if data.unstickHelp then
											spSetUnitVelocity(unitID, vx, vy, vz/2)
										else
											spSetUnitVelocity(unitID, 0, vy, vz)
										end
									else
										spSetUnitPosition(unitID, ux, clearUnits[4] + pushDistance, true)
										if data.unstickHelp then
											spSetUnitVelocity(unitID, vx, vy, vz/2)
										else
											spSetUnitVelocity(unitID, vx, vy, 0)
										end
									end
								end
							end
						end
					end
				end
			end
			
			if checkFeatures then
				local clearFeatures = data.featureExpulsionParameters
				features = spGetFeaturesInRectangle(clearFeatures[1], clearFeatures[2], clearFeatures[3], clearFeatures[4])
				for j = 1, #features do
					local featureID = features[j]
					local fx, fy, fz = spGetFeaturePosition(featureID)
					if fy and fy > clearFeatures[5] and fy < clearFeatures[6] then
						local l = abs(fx - clearFeatures[1])
						local t = abs(fz - clearFeatures[2])
						local r = abs(fx - clearFeatures[3])
						local b = abs(fz - clearFeatures[4])

						local side = min(l,r,t,b)
						if (side == l) then
							spSetFeaturePosition(featureID, clearFeatures[1], fy, fz, true)
						elseif (side == t) then
							spSetFeaturePosition(featureID, fx, fy, clearFeatures[2], true)
						elseif (side == r) then
							spSetFeaturePosition(featureID, clearFeatures[3], fy, fz, true)
						else
							spSetFeaturePosition(featureID, fx, fy, clearFeatures[4], true)
						end
						spSetFeatureVelocity(featureID, 0, 0, 0)
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Unit Handling

function gadget:UnitCreated(unitID, unitDefID,teamID)
	local ud = UnitDefs[unitDefID]
	if not ud.isFactory == true then
		return
	end

	local ux,_,uz,_,uy,_ = spGetUnitPosition(unitID, true)
	if uy > -22 then
		local face = spGetUnitBuildFacing(unitID)
		local xsize = (ud.xsize)*4
		local zsize = (ud.ysize or ud.zsize)*4
		local ally = spGetUnitAllyTeam(unitID)
		local minx, minz, maxx, maxz
		
		local unstickHelp = ud.customParams.unstick_help

		local _,sizeY,_,_,offsetY = Spring.GetUnitCollisionVolumeData(unitID)
		local miny = uy + offsetY - sizeY/2 --set the box bottom
		local maxy = uy + offsetY + 150 --set the box height +200 elmo above the factory midpoint
		
		if ((face == 0) or (face == 2)) then
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
			
			minx = ux - xsize
			minz = uz - zsize
			maxx = ux + xsize
			maxz = uz + zsize
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

			minx = ux - zsize
			minz = uz - xsize
			maxx = ux + zsize
			maxz = uz + xsize
		end
		
		local solidFactoryLimit = ud.customParams.solid_factory and tonumber(ud.customParams.solid_factory)
		local unitExpulsionParameters
		if not FEATURE_ONLY[ud.name] then
			unitExpulsionParameters = {
				minx - 0.1,
				minz - 0.1,
				maxx + 0.1,
				maxz + 0.1,
				miny,
				maxy,
			}
			if solidFactoryLimit then
				local solidFactoryRotation = ud.customParams.solid_factory_rotation and tonumber(ud.customParams.solid_factory_rotation)
				local solidFace = face
				if solidFactoryRotation then
					solidFace = (solidFace + solidFactoryRotation)%4
				end
				if solidFace == 0 then -- South
					unitExpulsionParameters[4] = unitExpulsionParameters[2] + (solidFactoryLimit*16)
				elseif solidFace == 1 then -- East
					unitExpulsionParameters[3] = unitExpulsionParameters[1] + (solidFactoryLimit*16)
				elseif solidFace == 2 then -- North
					unitExpulsionParameters[2] = unitExpulsionParameters[4] - (solidFactoryLimit*16)
				elseif solidFace == 3 then -- West
					unitExpulsionParameters[1] = unitExpulsionParameters[3] - (solidFactoryLimit*16)
				end
			end
		end
		
		local featureExpulsionParameters = {
			minx - 0.1,
			minz - 0.1,
			maxx + 0.1,
			maxz + 0.1,
			miny,
			maxy,
		}
		
		labList.count = labList.count + 1
		labList.data[labList.count] = {
			unitID = unitID,
			ally = ally,
			team = teamID,
			face = 0,
			unitExpulsionParameters = unitExpulsionParameters,
			featureExpulsionParameters = featureExpulsionParameters,
			unstickHelp = unstickHelp,
			preventAllyHax = solidFactoryLimit and true,
		}
		
		labs[unitID] = labList.count
		
		if unstickHelp then
			local data = labList.data[labList.count]
			data.minBuildX = (((face == 3) and minx) or (minx*0.5 + ux*0.5))
			data.minBuildZ = (((face == 2) and minz) or (minz*0.5 + uz*0.5))
			data.maxBuildX = (((face == 1) and maxx) or (maxx*0.5 + ux*0.5))
			data.maxBuildZ = (((face == 0) and maxz) or (maxz*0.5 + uz*0.5))
			
			--Spring.MarkerAddLine(data.minBuildX,0,data.minBuildZ,data.maxBuildX,0,data.minBuildZ)
			--Spring.MarkerAddLine(data.minBuildX,0,data.minBuildZ,data.minBuildX,0,data.maxBuildZ)
			--Spring.MarkerAddLine(data.maxBuildX,0,data.maxBuildZ,data.maxBuildX,0,data.minBuildZ)
			--Spring.MarkerAddLine(data.maxBuildX,0,data.maxBuildZ,data.minBuildX,0,data.maxBuildZ)
		end

		--Spring.Echo(xsize)
		--Spring.Echo(zsize)
		
		--Spring.MarkerAddLine(unitExpulsionParameters[1],0,unitExpulsionParameters[2],unitExpulsionParameters[3],0,unitExpulsionParameters[2])
		--Spring.MarkerAddLine(unitExpulsionParameters[1],0,unitExpulsionParameters[2],unitExpulsionParameters[1],0,unitExpulsionParameters[4])
		--Spring.MarkerAddLine(unitExpulsionParameters[3],0,unitExpulsionParameters[4],unitExpulsionParameters[3],0,unitExpulsionParameters[2])
		--Spring.MarkerAddLine(unitExpulsionParameters[3],0,unitExpulsionParameters[4],unitExpulsionParameters[1],0,unitExpulsionParameters[4])
	end
end

function gadget:UnitDestroyed(unitID, unitDefID)
	if (labs[unitID]) then
		RemoveLab(unitID)
	end
end

function gadget:UnitGiven(unitID, unitDefID,unitTeam)
	if (labs[unitID]) then
		labList.data[labs[unitID] ].ally = spGetUnitAllyTeam(unitID)
		labList.data[labs[unitID] ].team = unitTeam
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Structure Construction Blocking

function gadget:AllowCommand(unitID, unitDefID, teamID, cmdID, cmdParams, cmdOptions)
	if cmdID >= 0 and cmdID ~= CMD.INSERT then
		return true
	end
	
	if UnitDefs[unitDefID].isFactory then
		return true
	end
	
	local buildDefID, x, z, face
	if cmdID == CMD.INSERT then
		if not cmdParams[2] then
			return true
		end
		if cmdParams[2] >= 0 then
			return true
		end
		buildDefID = -cmdParams[2]
		x = cmdParams[4]
		z = cmdParams[6]
		face = cmdParams[7]
	else
		buildDefID = -cmdID
		x = cmdParams[1]
		z = cmdParams[3]
		face = cmdParams[4]
	end
	
	if (not x) or (not z) then
		-- Sometimes factory construction orders reach here
		return true
	end
	
	local allyTeamID = Spring.GetUnitAllyTeam(unitID)
	local ud = UnitDefs[buildDefID]
	if not ud then
		return true
	end

	local xsize = (ud.xsize)*4 - 8
	local zsize = (ud.ysize or ud.zsize)*4 - 8
	
	if ((face == 1) or (face == 3)) then
		xsize, zsize = zsize, xsize
	end
	
	--Spring.MarkerAddLine(x - xsize,0,z - zsize,x + xsize,0,z - zsize)
	--Spring.MarkerAddLine(x + xsize,0,z - zsize,x + xsize,0,z + zsize)
	--Spring.MarkerAddLine(x + xsize,0,z + zsize,x - xsize,0,z + zsize)
	--Spring.MarkerAddLine(x - xsize,0,z + zsize,x - xsize,0,z - zsize)
	
	--if (not x) or (not z) then
	--	Spring.Echo("LUA_ERRRUN", "Prevent Lab Hax AllowCommand")
	--	Spring.Echo("cmdID", cmdID, "ud.name", ud and ud.name)
	--	Spring.Utilities.TableEcho(cmdParams, "cmdParams")
	--	Spring.Utilities.TableEcho(cmdOptions, "cmdOptions")
	--	Spring.Echo("x z xsize zsize", x, z, xsize, zsize)
	--	return true
	--end
	
	local labData = labList.data
	for i = 1, labList.count do
		local data = labData[i]
		if data.ally == allyTeamID then
			local clearFeatures = data.featureExpulsionParameters
			if clearFeatures[1] < x + xsize and clearFeatures[3] > x - xsize and
					clearFeatures[2] < z + zsize and clearFeatures[4] > z - zsize then
				return false
			end
		end
	end
	return true
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Gadget Interface

function gadget:GameFrame(n)
	CheckLabs(n%60 == 0, n%2 ~= 0)
end

function gadget:Initialize()
	local units = Spring.GetAllUnits()
	for i = 1, #units do
		local udid = Spring.GetUnitDefID(units[i])
		gadget:UnitCreated(units[i], udid)
	end
end
