--pieces
local base = piece "Base"
local spheres = piece "Spheres"


--optimizations
local spImpulse = Spring.AddUnitImpulse
local spGetUDID = Spring.GetUnitDefID
local spGetVel = Spring.GetUnitVelocity
local spAddDmg = Spring.AddUnitDamage

function script.Create()
--for k,v in pairs(Spring.GetUnitPieceMap(unitID)) do Spring.Echo(k) end
Spring.UnitScript.Spin (spheres,y_axis,2.4,0.017)
end

function script.Killed()

local x, y, z = Spring.GetUnitPosition(unitID)
local units = Spring.GetUnitsInSphere(x,y,z,140)
local vx,vy,vz
local unit
for i=1,#units do
unit = units[i]
vx,vy,vz = spGetVel(unit)

if not UnitDefs[spGetUDID(unit)]["isCommander"] then
if UnitDefs[spGetUDID(unit)]["name"] ~= UnitDefs[spGetUDID(unitID)]["name"] then
if  UnitDefs[spGetUDID(unit)]["mass"] < 6500 then
spImpulse(unit,0,(6-vy)*0.7,0)
--Spring.Echo(vy)
else
--it's heavy
spAddDmg(unit,420)
end
end
else
--it's comm
spAddDmg(unit,220)
end

end

	
	Explode( base, SFX.SHATTER )
	Explode( spheres, SFX.SHATTER )
	
end
