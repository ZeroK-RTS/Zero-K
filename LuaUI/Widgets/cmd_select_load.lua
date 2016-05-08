--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Transport Load Double Tap",
    desc      = "Matches selected tranaports and units when load is double pressed.",
    author    = "GoogleFrog",
    date      = "8 May 2015",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

VFS.Include("LuaRules/Configs/customcmds.h.lua")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function DoSelectionLoad()
	-- Find the units which can transport and the units which are transports
	local selectedUnits = Spring.GetSelectedUnits()
	local lightTrans = {}
	local heavyTrans = {}
	local light = {}
	local heavy = {}
	
	for i = 1, #selectedUnits do
		local unitID = selectedUnits[i]
		local unitDefID = Spring.GetUnitDefID(unitID)
		local ud = unitDefID and UnitDefs[unitDefID]
		if ud then
			if (ud.canFly or ud.cantBeTransported) then
				if ud.isTransport then
					local transportUnits = Spring.GetUnitIsTransporting(unitID)
					if transportUnits and #transportUnits == 0 then
						if ud.transportMass > 330 then
							heavyTrans[#heavyTrans + 1] = unitID
						else
							lightTrans[#lightTrans + 1] = unitID
						end
					end
				end
			else
				if (ud.mass > 330) or (ud.xsize > 8) or (ud.zsize > 8) then
					heavy[#heavy + 1] = unitID
				else
					light[#light + 1] = unitID
				end
			end
		end
	end
	
	-- Assign transports to units
	local lightEnd = math.min(#light, #lightTrans)
	for i = 1, lightEnd do 
		Spring.GiveOrderToUnit(lightTrans[i], CMD.LOAD_UNITS, {light[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(light[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
	end
	
	local heavyEnd = math.min(#heavy, #heavyTrans)
	for i = 1, heavyEnd do 
		Spring.GiveOrderToUnit(heavyTrans[i], CMD.LOAD_UNITS, {heavy[i]}, CMD.OPT_RIGHT)
		Spring.GiveOrderToUnit(heavy[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
	end
	
	--Spring.Echo("light", #light)
	--Spring.Echo("heavy", #heavy)
	--Spring.Echo("lightTrans", #lightTrans)
	--Spring.Echo("heavyTrans", #heavyTrans)
	if #light > #lightTrans then
		local offset = #heavy - #lightTrans
		heavyEnd = math.min(#light, #heavyTrans + #lightTrans - #heavy)
		--Spring.Echo("offset", offset)
		for i = #lightTrans + 1, heavyEnd do 
			Spring.GiveOrderToUnit(heavyTrans[offset + i], CMD.LOAD_UNITS, {light[i]}, CMD.OPT_RIGHT)
			Spring.GiveOrderToUnit(light[i], CMD.WAIT, {}, CMD.OPT_RIGHT)
		end
	end
	Spring.SetActiveCommand(-1)
end

function widget:CommandNotify(cmdId)
	if cmdId == CMD_LOADUNITS_SELECTED then
		DoSelectionLoad()
		return true
	end
end