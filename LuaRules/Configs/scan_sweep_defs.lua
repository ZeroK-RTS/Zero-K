return {
	--[[
	[UnitDefNames["comsat_station"].id] = {
		cooldownTime = 60,
		scanRadius = 500, -- LoS/Radar range
		selfRevealTime = 10,
		ceg = "scan_sweep",
		revealRadius = 500, -- range to apply a cloak revealing debuff (see below)
		scanTime = 5, -- how long the vision and the debuff stay
	},
	]]--

	-- Revealing debuff is applied to all units in radius immediately
	-- and sticks to them for the duration,
	-- revealing them to your allyTeam (without decloaking for other teams!)
}