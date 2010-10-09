-- Author: Tobi Vollebregt
--[[
How to use this in your animation script:
1.  Add to the start of your script: 					include "smokeunit.lua"
2.  After you define your pieces tell which you want to smoke e.g.: 	local smokePieces = { piece "base" }
3.  In your 'function script:Create()' add: 				StartThread(SmokeUnit, smokePieces)
]]

-- effects
local SMOKEPUFF = 258

-- localize
local random = math.random


function SmokeUnit(smokePieces)
	local n = #smokePieces
	while (GetUnitValue(COB.BUILD_PERCENT_LEFT) ~= 0) do
		Sleep(1000)
	end
	while true do
		local health = GetUnitValue(COB.HEALTH)
		if (health <= 66) then -- only smoke if less then 2/3rd health left
			EmitSfx(smokePieces[random(1,n)], SMOKEPUFF)
		end
		Sleep(9*health + random(100,200))
	end
end
