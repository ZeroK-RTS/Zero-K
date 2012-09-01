--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
  return {
    name      = "Garbage Collector Control",
    desc      = "Periodically call \"Collect Garbage\" to free memory usage (for LuaUI). Configure at: Settings/Misc/Garbage Collector Control ",
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

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
options_path = 'Settings/Misc/Garbage Collector Control'
options_order = {'gcStrenght','reloadMemThreshold','reloadInterval','collectGarbage'}
options = {
	gcStrenght = {
		name = 'GC aggresiveness (off-slow-fast):',
		type = 'number',
		value = 6,
		desc = "Set how fast LuaUI's Garbage Collector (GC) run in the background. Higher value should work faster but will use more CPU.\nDefault: tick no.7 (200,200)", --ref:http://www.lua.org/manual/5.2/manual.html#2.5
		advanced = true,
		min=0,max=11,step=1,
		OnChange = function(self) 
					if (self.value == 0) then
						--if collectgarbage("isrunning") then --stop GC if started. LUA 5.2 only. Ref: http://www.lua.org/manual/5.2/manual.html#6.1 , http://www.lua.org/manual/5.2/manual.html#2.5
							--collectgarbage("stop")
						--end
						collectgarbage("stop")
						Spring.Echo("Garbage Collector: Stopped")
					elseif (self.value >= 1) then
						--if not collectgarbage("isrunning") then --start GC if stopped. LUA 5.2 only. 
							--collectgarbage("restart")
						--end
						collectgarbage("restart")
						local pauseValue = 300-(self.value-1)*20 --output a {300,280,260,... 140,120,100} when self.value is {1,2,3,...9,10,11}
						local stepmulValue = (self.value-1)*20 +100 --output a {100,120,140, ... 260,280,300} when self.value is {1,2,3,...9,10,11}
						Spring.Echo("Garbage Collector: Pause "..pauseValue..", StepMultiplier "..stepmulValue)
						collectgarbage("setpause",pauseValue) 
						collectgarbage("setstepmul",stepmulValue)
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
	autoOrderCG = {
        name = "Enable auto \"Collect Garbage\"", --a switch.
		type = 'bool',
		value = true,
		desc = "Enable widget to automatically issue a \"Collect Garbage\" to free memory usage (for LuaUI).\nDefault: true",
		advanced = true,
		OnChange = function(self)
					autoOrderCG_1 = self.value
					if self.value then 
						Spring.Echo("Collect garbage: True") 
					else 
						Spring.Echo("Collect garbage: False")
					end
				end,
	}, --]]
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

function widget:Initialize()
	--collectgarbage("setpause",arg1) 
	--collectgarbage("setstepmul",arg2)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------