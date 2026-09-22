function widget:GetInfo()
	return {
		name    = "Forcestart Warning",
		author  = "Sprung",
		date    = "2026-04-11",
		license = "Public Domain",
		layer   = 0,
		enabled = true,
	}
end

local warn_at = {
    [120] = true,
    [ 60] = true,
    [ 30] = true,
    [ 20] = true,
    [ 10] = true,
    [  5] = true,
    [  4] = true,
    [  3] = true,
    [  2] = true,
    [  1] = true,
}

local function Warn(seconds)
	-- ideally this would involve more ambitious GUI than just a gray chat message, but oh well
	Spring.Echo("game_message: Game will forcestart in " .. seconds .. " seconds")
end

function widget:PreGameTimekeeping(secondsUntilStart)
    if warn_at[secondsUntilStart] then
        Warn(secondsUntilStart)
    end
end