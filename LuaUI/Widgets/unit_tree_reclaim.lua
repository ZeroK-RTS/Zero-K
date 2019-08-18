function widget:GetInfo()
	return {
		name = "Area-reclaim trees",
		desc = "Area-reclaim will also eat trees if the order is centered on a tree",
		layer = -1337, -- before insert
		enabled = true,
	}
end

--------------------------------------------------------------------------------
-- Epic Menu Options
--------------------------------------------------------------------------------

options_path = 'Settings/Unit Behaviour'
options = {
	defaultAvoidTrees = {
		name = "Area reclaim avoids energy",
		type = "bool",
		value = false,
		desc = "Enabling causes area reclaim orders to avoid reclaiming trees and other energy-only features. Reclaim trees by issuing the order centred on a tree or by holding Ctrl.\n\nThe behaviour is reversed when disabled, causing orders given with Ctrl held to avoid reclaiming trees.",
		noHotkey = true,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:CommandNotify(cmdID, cmdParams, cmdOptions)
	if cmdID ~= CMD.RECLAIM or #cmdParams ~= 4 then
		return
	end

	if options.defaultAvoidTrees.value then
		local targetType, targetID = Spring.TraceScreenRay(Spring.WorldToScreenCoords(cmdParams[1], cmdParams[2], cmdParams[3]))

		if (targetType ~= "feature") then
			return
		end
		local fd = FeatureDefs[Spring.GetFeatureDefID(targetID)]
		if not fd.reclaimable or fd.autoreclaim then
			return
		end

		if not cmdOptions.ctrl then
			cmdOptions.ctrl = true
			cmdOptions.coded = cmdOptions.coded + CMD.OPT_CTRL
		end
		WG.CommandInsert(cmdID, cmdParams, cmdOptions)
	else
		if not cmdOptions.ctrl then
			cmdOptions.ctrl = true
			cmdOptions.coded = cmdOptions.coded + CMD.OPT_CTRL
		else
			cmdOptions.ctrl = false
			cmdOptions.coded = cmdOptions.coded - CMD.OPT_CTRL
		end
		WG.CommandInsert(cmdID, cmdParams, cmdOptions)
	end
	return true
end
