--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
if not gadgetHandler:IsSyncedCode() then
	return
end
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



local spGetUnitBuildFacing     = Spring.GetUnitBuildFacing
local spSetUnitMidAndAimPos    = Spring.SetUnitMidAndAimPos
local spSetUnitRadiusAndHeight = Spring.SetUnitRadiusAndHeight

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
	local ud = UnitDefs[i]
	local midPosOffset = ud.customParams.midposoffset
	local aimPosOffset = ud.customParams.aimposoffset
	local modelRadius  = ud.customParams.modelradius
	local modelHeight  = ud.customParams.modelheight
	if midPosOffset or aimPosOffset then
		local mid = (midPosOffset and UnpackInt3(midPosOffset)) or {0,0,0}
		local aim = (aimPosOffset and UnpackInt3(aimPosOffset)) or mid
		offsets[i] = {
			mid = mid,
			aim = aim,
		}
	end
	if modelRadius or modelHeight then
		modelRadii[i] = {
			radius = ( modelRadius and tonumber(modelRadius) or ud.radius ),
			height = ( modelHeight and tonumber(modelHeight) or ud.height ),
		}
	end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
	local ud = UnitDefs[unitDefID]
	if offsets[unitDefID] and ud then
		local mid = offsets[unitDefID].mid
		local aim = offsets[unitDefID].aim
		spSetUnitMidAndAimPos(unitID, 
			mid[1] + ud.midx, mid[2] + ud.midy, mid[3] + ud.midz, 
			aim[1] + ud.midx, aim[2] + ud.midy, aim[3] + ud.midz, true)
	end
	if modelRadii[unitDefID] then
		spSetUnitRadiusAndHeight(unitID, modelRadii[unitDefID].radius, modelRadii[unitDefID].height)
	end
end


function gadget:Initialize()
	for _, unitID in ipairs(Spring.GetAllUnits()) do
		local unitDefID = Spring.GetUnitDefID(unitID)
		gadget:UnitCreated(unitID, unitDefID)
	end
end