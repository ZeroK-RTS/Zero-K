function GetSelectedUnits(id, params, options)
	local selected = Spring.GetSelectedUnits()
	if WG.CmdDisableAttack then
		selected = WG.CmdDisableAttack.FilterSelectedUnits(selected, id, params, options)
	end
	return selected
end

