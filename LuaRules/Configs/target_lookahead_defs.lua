-- unitDefID -> lookahead
local unitArray = {}

for i=1,#UnitDefs do
	local cp = UnitDefs[i].customParams
	if cp and cp.lookahead then
		unitArray[i] = cp.lookahead
	end
end

return unitArray
