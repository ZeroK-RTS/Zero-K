--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Center Offset",
      desc      = "Offsets aimpoints",
      author    = "KingRaptor (L.J. Lim) and GoogleFrog",
      date      = "12.7.2012",
      license   = "Public Domain",
      layer     = 0,
      enabled   = false
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--SYNCED
if gadgetHandler:IsSyncedCode() then

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not Spring.SetUnitMidAndAimPos then
	return
end

local offsets = {}
local modelRadii = {}

local function UnpackInt3(str)
	local index = 0
	local ret = {}
	for i=1,3 do
		ret[i] = str:match("[-]*%d+", index)
		index = (select(2, str:find(ret[i], index)) or 0) + 1
	end
	return ret
end

for i=1,#UnitDefs do
	local midPosOffset = UnitDefs[i].customParams.midposoffset
	local aimPosOffset = UnitDefs[i].customParams.aimposoffset
	local modelRadius = UnitDefs[i].customParams.modelradius
	if midPosOffset or aimPosOffset then
		local mid = (midPosOffset and UnpackInt3(midPosOffset)) or {0,0,0}
		local aim = (aimPosOffset and UnpackInt3(aimPosOffset)) or mid
		offsets[i] = {
			mid = mid,
			aim = aim,
		}
	end
	if modelRadius then
		modelRadii[i] = tonumber(modelRadius)
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	---[[
	if offsets[unitDefID] then
		mid = offsets[unitDefID].mid
		aim = offsets[unitDefID].aim
		local _,_,_, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
		local mx, my, mz = mid[1] + ux, mid[2] + uy, mid[3] + uz
		local ax, ay, az = aim[1] + ux, aim[2] + uy, aim[3] + uz
		Spring.SetUnitMidAndAimPos(unitID, mx, my, mz, ax, ay, az)
	end
	if modelRadii[unitDefID] then
		Spring.SetUnitRadiusAndHeight(unitID,modelRadii[unitDefID])
	end
	--]]
	--[[
	local _,_,_, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
	Spring.SetUnitMidAndAimPos(unitID, ux, uy-10, uz, ux, uy, uz)
	Spring.SetUnitRadiusAndHeight(unitID,42)
	--]]
end

--[[
function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end
--]]

------------------------------------------------------

end