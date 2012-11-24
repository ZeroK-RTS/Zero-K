--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Garbage Collector Control",
    desc      = "Add aggresiveness control for LUAUI Garbage Collector, and allow user to configure periodic \"Collect Garbage\" call to free memory usage. Configure at: Settings/Misc/Garbage Collector Control ",
    author    = "msafwan",
    version   = "0.98",
    date      = "30 August 2012",
    license   = "none",
    layer     = math.huge,
    enabled   = false  --  loaded by default?
  }
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--local autoOrderCG_1 = true ----//variable. A switch to enable auto "Collect Garbage"
local memoryThreshold = 102400 --//variable. An amount of memory usage (kilobyte) before LUAUI auto reload
local minimumInterval = 1200 --//variable. A minimum interval of second before ordering "Collect Garbage"
local pauseValue = nil
local stepmulValue = nil
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Misc/Garbage Collector Control'
options_order = {'gcStrenght','reloadMemThreshold','reloadInterval','collectGarbage'}
options = {
	gcStrenght = {
		name = 'GC aggresiveness (off-slow-fast):',
		type = 'number',
		value = 10,
		desc = "Set how fast LuaUI's Garbage Collector (GC) run in the background. Higher value will make LUAUI use less memory but theoretically will make LUAUI use more CPU.\nDefault: pause 200, stepMultiplier 200", --ref:http://www.lua.org/manual/5.2/manual.html#2.5
		advanced = true,
		min=0,max=19,step=1,
		OnChange = function(self) 
					if (self.value == 0) then --slider is at the left end
						--if collectgarbage("isrunning") then --stop GC if started. LUA 5.2 only. Ref: http://www.lua.org/manual/5.2/manual.html#6.1 , http://www.lua.org/manual/5.2/manual.html#2.5
						if not pauseValue or not stepmulValue then
							pauseValue = 400-(1)*20 --output a {380,360,... 40,20} when self.value is {1,2,3,...17,18,19}
							stepmulValue = (1)*20 --output a {20,40, ... 360,380} when self.value is {1,2,3,...17,18,19}
							collectgarbage("setpause",pauseValue) 
							collectgarbage("setstepmul",stepmulValue)
						end
						collectgarbage("stop")
						Spring.Echo("Garbage Collector: Pause "..pauseValue..", StepMultiplier "..stepmulValue .. " (Stopped)")
					elseif (self.value >= 1) then --slider is on the right
						--if not collectgarbage("isrunning") then --start GC if stopped. LUA 5.2 only. 
						pauseValue = 400-(self.value)*20 --output a {380,360,... 40,20} when self.value is {1,2,3,...17,18,19}
						stepmulValue = (self.value)*20 --output a {20,40, ... 360,380} when self.value is {1,2,3,...17,18,19}
						collectgarbage("setpause",pauseValue) 
						collectgarbage("setstepmul",stepmulValue)
						collectgarbage("restart")
						Spring.Echo("Garbage Collector: Pause "..pauseValue..", StepMultiplier "..stepmulValue)
					end
				end,
	},
	--[[
	gcMode = {
        name = "Experimental GC mode", --LUA 5.2 only. Current Spring use LUA 5.1
		type = 'bool',
		value = true,
		desc = "Changes the LuaUI's Garbage Collector (GC) to generational mode. This is an experimental feature. A generational collector assumes that most objects die young, and therefore it traverses only young (recently created) objects. (source: LUA 5.2 Reference Manual).\nDefault: true",
		advanced = true,
		OnChange = function(self)
					if self.value then
						collectgarbage("generational")
						Spring.Echo("Garbage Collector: Generational mode")
					else
						collectgarbage("incremental")
						Spring.Echo("Garbage Collector: Incremental mode")
					end
				end,
	},
	--]]
	reloadMemThreshold = {
		name = 'Memory Usage Threshold (25-100 MB):',
		type = 'number',
		value = 100,
		desc = "Automatically order a \"Collect Garbage\" after reaching this amount of memory usage (for LuaUI).\nDefault: 100 MB",
		advanced = true,
		min=25,max=100,step=1,
		OnChange = function(self) 
					memoryThreshold = self.value*1024
					Spring.Echo("Maximum Memory: ".. self.value.." Megabyte")
				end,
	},	
	reloadInterval = {
		name = 'Minimum Interval (1-20 minutes):',
		type = 'number',
		value = 20,
		desc = "Wait for the following minutes before automatically order another \"Collect Garbage\" again.\nDefault: 20 Minute",
		advanced = true,
		min=1,max=20,step=1,
		OnChange = function(self) 
					minimumInterval = self.value*60
					Spring.Echo("Minimum Interval: ".. self.value.." minute")
				end,
	},
	collectGarbage = {
		name = 'Collect Garbage now',
		type = 'button',
		desc = "Collect Garbage now. Use dbg_widgetProfiler.lua to check current memory usage",
		OnChange = function()
			collectgarbage("collect")
		end,
	},
}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
local elapsedSecond = 0 --amount of second since last "collect garbage".

function widget:Update(dt)
	elapsedSecond = elapsedSecond + dt
	if (elapsedSecond >= minimumInterval) then --if minimum interval reached:
		elapsedSecond = minimumInterval --(optimization: cap elapsedSecond to a ceiling value)

		local memusage = collectgarbage("count") --get total amount of memory usage for LUAUI
		if (memusage > memoryThreshold) then
			local memString = ('%.1f'):format(memusage/1024) .. " MB" --display current memory usage to player
			Spring.Echo(memString)
			collectgarbage("collect") --collect garbage
			elapsedSecond = 0
		end
	end
end
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------