local spGetUnitPosition = Spring.GetUnitPosition
local spRequestPath = Spring.RequestPath
local spGetUnitDefID = Spring.GetUnitDefID

--This function process result of Spring.PathRequest() to say whether target is reachable or not
local function IsTargetReachable (moveID, ox,oy,oz,tx,ty,tz,radius)
	local returnValue1,returnValue2, returnValue3
	local path = spRequestPath( moveID,ox,oy,oz,tx,ty,tz, radius)
	if path then
		local waypoint = path:GetPathWayPoints() --get crude waypoint (low chance to hit a 10x10 box). NOTE; if waypoint don't hit the 'dot' is make reachable build queue look like really far away to the GetWorkFor() function.
		local finalCoord = waypoint[#waypoint]
		if finalCoord then --unknown why sometimes NIL
			local dx, dz = finalCoord[1]-tx, finalCoord[3]-tz
			local dist = math.sqrt(dx*dx + dz*dz)
			if dist <= radius+10 then --is within radius?
				returnValue1 = "reach"
				returnValue2 = finalCoord
				returnValue3 = waypoint
			else
				returnValue1 = "outofreach"
				returnValue2 = finalCoord
				returnValue3 = waypoint
			end
		end
	else
		returnValue1 = "noreturn"
		returnValue2 = nil
		returnValue3 = nil
	end
	return returnValue1,returnValue2, returnValue3
end

function IsTargetReallyReachable(unitID, x,y,z,ux, uy, uz)
	local udid = spGetUnitDefID(unitID)
	local moveID = UnitDefs[udid].moveDef.id
	local reach = true --Note: first assume unit is flying and/or target always reachable
	if moveID then --Note: crane/air-constructor do not have moveID!
		if not ux then
			ux, uy, uz = spGetUnitPosition(unitID)	-- unit location
		end
		local result,finCoord = IsTargetReachable(moveID, ux,uy,uz,x,y,z,128)
		if result == "outofreach" then --if result not reachable (and we'll have the closest coordinate), then:
			result = IsTargetReachable(moveID, finCoord[1],finCoord[2],finCoord[3],x,y,z,8) --refine pathing
			if result ~= "reach" then --if result still not reach, then:
				reach = false --target is unreachable
			end
		else -- Spring.PathRequest() must be non-functional
		end
		--Technical note: Spring.PathRequest() will return NIL(noreturn) if either origin is too close to target or when pathing is not functional (this is valid for Spring91, may change in different version)
	end
	return reach
end