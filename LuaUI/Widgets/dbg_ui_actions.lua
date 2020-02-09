function widget:GetInfo()
	return {
		name      = "UI Actions",
		desc      = "Takes UI actions for benchmarking.",
		author    = "GoogleFrog",
		date      = "9 Feb 2020",
		layer     = 0,
		enabled   = true,  --  loaded by default
	}
end

local ACTIVE = true

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local SELECTION_GAP = 0.1*30
local nextFrame = 5*30
local haveSelected = false
local allUnits

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Logging

function widget:Update(dt)
	if not ACTIVE then
		return
	end

	local frame = Spring.GetGameFrame() 
	if (frame > nextFrame) then
		nextFrame = frame + SELECTION_GAP
		allUnits = allUnits or Spring.GetAllUnits()
		
		if haveSelected then
			Spring.SelectUnitArray({})
		else
			local toSelect = {}
			for i = 1, #allUnits do
				if math.random() > 0.5 then
					toSelect[#toSelect + 1] = allUnits[i]
				end
			end
			Spring.SelectUnitArray(toSelect)
		end
		haveSelected = not haveSelected
	end
end

