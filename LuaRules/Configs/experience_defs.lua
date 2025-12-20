
local defs = {
	jumpsumo = {
		{
			level = 1,
			tex2 = "unittextures/m-9_tex2-alt1.dds",
		},
		{
			level = 2,
			tex2 = "unittextures/m-9_tex2-alt2.dds",
		},
		{
			level = 3,
			tex2 = "unittextures/m-9_tex2-alt3.dds",
		},
		{
			level = 4,
			tex2 = "unittextures/m-9_tex2-alt4.dds",
		},
	}
}

local realDefs = {}
for name, data in pairs(defs) do
	local ud = UnitDefNames[name]
	if ud and ud.id then
		realDefs[ud.id] = data
	end
end

return realDefs
