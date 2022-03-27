function widget:GetInfo()
  return {
    name      = "Unhandled Commands",
    desc      = "handles unhandled commands.",
    author    = "Amnykon",
    date      = "March 22, 2022",
    license   = "GNU GPL, v2 or later",
    layer     = math.huge,
    handler   = true,
    enabled   = true -- loaded by default?
  }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(id, params, options)
	local units = widgetHandler:GetSelectedUnits(id, params, options)
	for i=1,#units do
    widgetHandler:UnitCommandNotify(units[i], id, params, options)
  end
	return true
end

function widget:UnitCommandNotify(unitID, id, params, options)
	Spring.GiveOrderToUnit (unitID, id, params, options)
	return true
end
