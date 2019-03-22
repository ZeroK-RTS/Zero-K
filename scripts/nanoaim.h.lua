-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--
-- Author: jK @ 2010
--
-- How to use:
--
-- 1. Add to the start of your script:								 include "nanoaim.h.lua"
-- 2. After you define your pieces tell which you want to smoke e.g.: local nanoPieces = { piece "nano_aim" }
-- 3. In your 'function script:Create()' add:						 StartThread(UpdateNanoDirectionThread, nanoPieces [, updateInterval = 1000 [, turnSpeed = 0.75*math.pi [, turnSpeedVert = turnSpeed ]]])
-- 4. In your 'function script.StartBuilding()' add:					UpdateNanoDirection(nanoPieces [, turnSpeed = 0.75*math.pi [, turnSpeedVert = turnSpeed ]])
-- 5. Don't forget to set COB.INBUILDSTANCE:=1 & COB.INBUILDSTANCE:=0 in StartBuilding/StopBuilding
--
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

if GG.NanoAim then
	return
end
GG.NanoAim = {}

function GG.NanoAim.UpdateNanoDirection(unitID, nanopieces,turnSpeed,turnSpeedVert)
	if not Spring.ValidUnitID(unitID) then
		return
	end
	local type, target, isFeature = Spring.Utilities.GetUnitNanoTarget(unitID)

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

		local length = math.sqrt(dx*dx + dy*dy + dz*dz)
		local norm_dy = (length > 0 and dy / length) or 0
		local tp = math.asin(norm_dy)
		local p = math.asin(select(2,Spring.GetUnitDirection(unitID)))
		local pitch = p - tp

		turnSpeed	 = turnSpeed or (0.75*math.pi)
		turnSpeedVert = turnSpeedVert or turnSpeed

		local turned = false
		for i = 1,#nanopieces do
			local nano = nanopieces[i]
			local cur_head,cur_pitch = Spring.UnitScript.GetPieceRotation(nano)
			if (cur_head ~= heading)or(cur_pitch ~= pitch) then
				Turn(nano, y_axis, heading, turnSpeed)
				Turn(nano, x_axis, pitch, turnSpeedVert)
				turned = true
			end
		end

		if (turned) then
			WaitForTurn(nanopieces[1], y_axis)
		end
	end
end


function GG.NanoAim.UpdateNanoDirectionThread(unitID, nanopieces, updateInterval, turnSpeed,turnSpeedVert)
	updateInterval = updateInterval or 1000
	while true and Spring.ValidUnitID(unitID) do
		GG.NanoAim.UpdateNanoDirection(unitID, nanopieces,turnSpeed,turnSpeedVert)
		Sleep(updateInterval)
	end
end

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
