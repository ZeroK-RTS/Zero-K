--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "GC at >300MB",
    desc      = "Workaround for abnormal memory usage while rejoining game in Spring 97."
				.."Usual ingame usage never exceed 100MB.",
    author    = "xponen",
    version   = "1",
    date      = "4 June 2014",
    license   = "none",
    layer     = math.huge,
	alwaysStart = true,
    enabled   = true  --  loaded by default?
  }
end
--Note: cannot use widget:GameProgress() to check for rejoining status because its broken in Spring 97 (the callin didn't tell rejoiner the actual current frame)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
function widget:Initialize()
	if (Spring.Utilities.GetEngineVersion():find('91.0') == 1) or true then
		Spring.Echo("Removed 'GC at >100MB': disabled.")
		widgetHandler:RemoveWidget()
	end
end

local sec = 0 --amount of second since last "collect garbage".
local interval = 20 -- interval of 20 seconds
local memThreshold = 102400 --amount of memory usage (kilobyte) before calling LUA GC
function widget:Update(dt)
	sec = sec + dt
	if (sec >= interval) then --if minimum interval reached:
		sec = 0
		local memusage = collectgarbage("count") --get total amount of memory usage for LUAUI
		if (memusage > memThreshold) then
			local memString = "Calling Garbage Collector on excessive LuaUI memory usage: " .. ('%.1f'):format(memusage/1024) .. " MB" --display current memory usage to player
			Spring.Echo(memString)
			collectgarbage("collect") --collect garbage
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
