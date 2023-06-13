
-- Scaling
-- hack window geometry

-- gl.GetViewSizes intentionally not overridden
Spring.Orig = Spring.Orig or {}
Spring.Orig.GetWindowGeometry = Spring.GetWindowGeometry
Spring.Orig.GetViewGeometry = Spring.GetViewGeometry
Spring.Orig.GetViewSizes = gl and gl.GetViewSizes

Spring.GetWindowGeometry = function()
	local vsx, vsy, vx, vy = Spring.Orig.GetWindowGeometry()
	return vsx/((WG and WG.uiScale) or 1), vsy/((WG and WG.uiScale) or 1), vx, vy
end

Spring.GetViewGeometry = function()
	local vsx, vsy, vx, vy = Spring.Orig.GetViewGeometry()
	return vsx/((WG and WG.uiScale) or 1), vsy/((WG and WG.uiScale) or 1), vx, vy
end

Spring.GetViewSizes = function()
	local vsx, vsy = Spring.Orig.GetViewSizes()
	return vsx/(WG.uiScale or 1), vsy/(WG.uiScale or 1), vx, vy
end

Spring.ScaledGetMouseState = function()
	local mx, my, left, right, mid, offscreen = Spring.GetMouseState()
	return mx/((WG and WG.uiScale) or 1), my/((WG and WG.uiScale) or 1), left, right, mid, offscreen
end
-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------

local oldGetGroundExtremes = Spring.GetGroundExtremes

Spring.GetGroundExtremes = function()
	local minOverride = Spring.GetGameRulesParam("ground_min_override")
	if minOverride then
		return minOverride, Spring.GetGameRulesParam("ground_max_override")
	end
	return oldGetGroundExtremes()
end

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Inspect callout behavour

if false and Spring.SetUnitPosition then -- only in gadget space
	Spring.Echo("FUNCTION_OVERRIDE_LOADING")
	local funcList = {
		--"SetUnitPosition",
		--"SetUnitVelocity",
		--"AddUnitImpulse",
		--"SetUnitPhysics",
		--"SetUnitRulesParam",
		"GiveOrderToUnit",
	}
	
	local unitWhitelist = {
		[18399] = true,
		--[26879] = true,
	}
	
	for i = 1, #funcList do
		local funcName = funcList[i]
		local origFunc = Spring[funcName]
		Spring[funcName] = function (unitID, ...)
			if unitID and unitWhitelist[unitID] and Spring.GetGameFrame() > 27630 then
				Spring.Echo(funcName, unitID)
				Spring.Utilities.TableEcho({...}, "table")
				Spring.Utilities.UnitEcho(unitID)
			end
			origFunc(unitID, ...)
		end
	end
	
	local moveBlackist = {
		["GetTag"] = true,
	}
	
	for funcName, origFunc in pairs(Spring.MoveCtrl) do
		if not moveBlackist[funcName] then
			Spring.Echo("FUNCTION_OVERRIDE_LOADING", funcName)
			Spring.MoveCtrl[funcName] = function (unitID, ...)
				if unitID and unitWhitelist[unitID] and Spring.GetGameFrame() > 27630 then
					Spring.Echo(funcName, unitID)
					Spring.Utilities.TableEcho({...}, "table")
					Spring.Utilities.UnitEcho(unitID)
				end
				origFunc(unitID, ...)
			end
		end
	end
end
