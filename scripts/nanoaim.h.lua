-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--
-- Author: jK @ 2010
--
-- How to use:
--
-- 1. Add to the start of your script:                                  include "nanoaim.h.lua"
-- 2. After you define your pieces tell which you want to smoke e.g.:   local nanoPieces = { piece "nano_aim" }
-- 3. In your 'function script:Create()' add:                           StartThread(UpdateNanoDirectionThread, nanoPieces [, updateInterval = 1000 [, turnSpeed = 0.75*math.pi [, turnSpeedVert = turnSpeed ]]])
-- 4. In your 'function script.StartBuilding()' add:                    UpdateNanoDirection(nanoPieces [, turnSpeed = 0.75*math.pi [, turnSpeedVert = turnSpeed ]])
-- 5. Don't forget to set COB.INBUILDSTANCE:=1 & COB.INBUILDSTANCE:=0 in StartBuilding/StopBuilding
--
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local Utils_GetUnitNanoTarget = Spring.Utilities.GetUnitNanoTarget
local SpringGetUnitRulesParam = Spring.GetUnitRulesParam

function UpdateNanoDirection(nanopieces,turnSpeed,turnSpeedVert)
	local type, target, isFeature = Utils_GetUnitNanoTarget(unitID)

	if (target) then
		local x,y,z
		if (type == "restore") then
			x,y,z = target[1],target[2],target[3]
		elseif (not isFeature) then
			x,y,z = Spring.GetUnitPosition(target)
		else
			x,y,z = Spring.GetFeaturePosition(target)
		end

		local ux,uy,uz = Spring.GetUnitPosition(unitID)
		local dx,dy,dz = x-ux,y-uy,z-uz
		local th = Spring.GetHeadingFromVector(dx,dz)
		local h = Spring.GetUnitHeading(unitID)
		local heading = (th - h) * math.pi / 32768

		local norm_dy = dy / math.sqrt(dx*dx + dy*dy + dz*dz)
		local tp = math.asin(norm_dy)
		local p  = math.asin(select(2,Spring.GetUnitDirection(unitID)))
		local pitch = p - tp

		local slowMult = (1-(SpringGetUnitRulesParam(unitID,"slowState") or 0))
		turnSpeed     = (turnSpeed or (0.75*math.pi)) * slowMult
		turnSpeedVert = (turnSpeedVert or turnSpeed)  * slowMult

		for i=1,#nanopieces do
			local nano = nanopieces[i]
			local cur_head,cur_pitch = Spring.UnitScript.GetPieceRotation(nano)
			if (cur_head ~= heading)or(cur_pitch ~= pitch) then
				Turn(nano, y_axis, heading, turnSpeed)
				Turn(nano, x_axis, pitch, turnSpeedVert)
			end
		end
	end
end

function UpdateNanoDirectionThread(nanopieces, updateInterval, turnSpeed,turnSpeedVert)
	updateInterval = updateInterval or 1000
	while true do
		if SpringGetUnitRulesParam(unitID,"disarmed") ~= 1 then
			UpdateNanoDirection(nanopieces,turnSpeed,turnSpeedVert)
		end
		Sleep(updateInterval)
	end
end
