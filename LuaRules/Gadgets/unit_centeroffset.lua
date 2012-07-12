--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function gadget:GetInfo()
   return {
      name      = "Center Offset",
      desc      = "Offsets aimpoints",
      author    = "KingRaptor (L.J. Lim)",
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--local aimPosOffsets = {}
local midPosOffsets = {}

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
   if midPosOffset then
      Spring.Echo(UnitDefs[i].name)
      midPosOffsets[i] = UnpackInt3(midPosOffset)
   end
end

function gadget:UnitCreated(unitID, unitDefID, teamID)
   if midPosOffsets[unitDefID] then
      local px, py, pz = unpack(midPosOffsets[unitDefID])
      local _,_,_, ux, uy, uz = Spring.GetUnitPosition(unitID, true)
      px, py, pz = px + ux, py + uy, pz + uz
      Spring.Echo("bla")
	  Spring.SetUnitMidAndAimPos(unitID, px, py, pz, px, py, pz)
   end
end

------------------------------------------------------

end