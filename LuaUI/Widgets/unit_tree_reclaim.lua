function widget:GetInfo() return {
	name = "Area-reclaim trees",
	desc = "Area-reclaim will also eat trees if the order is centered on a tree",
	layer = -1337, -- before insert
	enabled = true,
} end

function widget:CommandNotify(id, params, options)
	if id ~= CMD.RECLAIM or #params ~= 4 then return end

	local targetType, targetID = Spring.TraceScreenRay(Spring.WorldToScreenCoords(params[1], params[2], params[3]))

	if (targetType ~= "feature") then return end
	local fd = FeatureDefs[Spring.GetFeatureDefID(targetID)]
	if not fd.reclaimable or fd.autoreclaim then return end

	options.ctrl = true
	if not WG.CommandInsert or not WG.CommandInsert(id, params, options) then
		Spring.GiveOrder(id, params, options)
	end
	return true
end
