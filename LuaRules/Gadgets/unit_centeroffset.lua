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
      enabled   = true
   }
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--SYNCED
if gadgetHandler:IsSyncedCode() then


local spGetUnitBuildFacing = Spring.GetUnitBuildFacing

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

if not Spring.SetUnitMidAndAimPos then
	return
end

local armwarDefID = UnitDefNames["armwar"].id

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
	local ud = UnitDefs[unitDefID]
	if offsets[unitDefID] and ud then
		local mid = offsets[unitDefID].mid
		local aim = offsets[unitDefID].aim
		Spring.SetUnitMidAndAimPos(unitID, 
			mid[1] + ud.midx, mid[2] + ud.midy, mid[3] + ud.midz, 
			aim[1] + ud.midx, aim[2] + ud.midy, aim[3] + ud.midz, true)
	end
	if modelRadii[unitDefID] then
		Spring.SetUnitRadiusAndHeight(unitID,modelRadii[unitDefID])
	end
end


function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end


------------------------------------------------------

end