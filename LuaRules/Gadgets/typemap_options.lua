if (not gadgetHandler:IsSyncedCode()) then
	return
end

function gadget:GetInfo()
  return {
    name      = "Typemap Options",
    desc      = "Edit's the map's typemap at the start of the game.",
    author    = "Google Frog",
    date      = "Feb, 2010",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

function gadget:Initialize()
	if (Spring.GetModOptions().typemapsetting == "1") then
		for i = 0, 255 do
			Spring.SetTerrainTypeData(i, 1,1,1,1)
		end
	else
		for i = 0, 255 do
			local _, _, t, k, h, s = Spring.GetTerrainTypeData(i)
			if not (t == k and k == h and h == s and t ~= 0) then
				Spring.SetTerrainTypeData(i, 1,1,1,1)
			end
		end
	end
end
