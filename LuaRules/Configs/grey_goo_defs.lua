local unitArray = {}
local UPDATE_FREQUNECY = 30

for i=1,#UnitDefs do
	local cp = UnitDefs[i].customParams
	if cp.grey_goo then
		unitArray[i] = {
			drain = tonumber (cp.grey_goo_drain)*UPDATE_FREQUNECY/30,
			cost = tonumber (cp.grey_goo_cost),
			range = tonumber (cp.grey_goo_range),
			spawns = cp.grey_goo_spawn,
		}
	end
end

return UPDATE_FREQUNECY, unitArray
