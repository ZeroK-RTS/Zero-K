-- unitDefID -> lookahead
local unitArray = {}

for i=1,#UnitDefs do
	unitArray[i] = UnitDefs[i].customParams.lookahead
end

return unitArray
