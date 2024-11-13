function gadget:GetInfo()
	return {
		name      = "Pregame Timer",
		desc      = "Listens to server pregame timekeeping messages",
		author    = "Sprung",
		date      = "2024",
		license   = "Public Domain",
		layer     = 0,
		enabled   = true,
	}
end

if gadgetHandler:IsSyncedCode() then

	function gadget:Initialize()
		if Spring.GetGameFrame() > 0 then
			gadgetHandler:RemoveGadget()
			return
		end
	end

	function gadget:GameStart()
		Spring.SetGameRulesParam("pregame_timer_seconds", nil)
		gadgetHandler:RemoveGadget()
	end

	function gadget:GotChatMsg (msg, senderID)
		if string.find(msg, "pregame_timer_seconds") ~= 1 then
			return
		end

		if senderID ~= 255 then -- autohost
			return
		end

		local secondsUntilStart = tonumber(string.sub(msg, 23))
		if not secondsUntilStart then
			return
		end

		Spring.SetGameRulesParam("pregame_timer_seconds", secondsUntilStart)
		SendToUnsynced("PreGameTimekeeping", secondsUntilStart)
	end

else -- unsynced

	function gadget:Initialize()
		if Spring.GetGameFrame() > 0 then
			gadgetHandler:RemoveGadget()
			return
		end

		gadgetHandler:AddSyncAction("PreGameTimekeeping", function (_, secondsUntilStart)
			if Script.LuaUI("PreGameTimekeeping") then
				Script.LuaUI.PreGameTimekeeping(secondsUntilStart)
			end
		end)
	end

	function gadget:GameStart()
		gadgetHandler:RemoveGadget()
	end

	function gadget:Shutdown()
		gadgetHandler:RemoveSyncAction("PreGameTimekeeping")
	end

end
