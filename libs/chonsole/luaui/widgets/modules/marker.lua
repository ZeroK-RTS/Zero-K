-- marker
local MARKER_KEY = Spring.GetKeyCode("`")
local markerPos
local lastPressTime = 0
local lastSentTime = 0
local ignoreNextChar = false

function MarkerMousePress(x, y, button)
	if not Spring.GetKeyState(MARKER_KEY) then
		return
	end
	_, markerPos = Spring.TraceScreenRay(x, y, true, false)
	if not markerPos then
		return
	end

	if button == 1 then
		local pressTime = os.clock()
		if not ebConsole.visible and pressTime - lastPressTime < 0.3 then
			ignoreNextChar = true
			ebConsole:Show()
			screen0:FocusControl(ebConsole)
			SetContext({ display = i18n("label_context", {default="Label:"}), name = "label", persist = true })
			ShowContext()
		end
		lastPressTime = pressTime
		return true
	elseif button == 3 then
		Spring.MarkerErasePosition(markerPos[1], markerPos[2], markerPos[3])
		return true
	end
end

function MarkerMouseMove(x, y, dx, dy, button)
	local newPos
	_, newPos = Spring.TraceScreenRay(x, y, true, false)
	if not newPos  then
		return
	end

	local time = os.clock()
	if time - lastSentTime > 0.06 then
		lastSentTime = time
	else
		return
	end

	if button == 1 then
		Spring.MarkerAddLine(markerPos[1], markerPos[2], markerPos[3], newPos[1], newPos[2], newPos[3])
		markerPos = newPos
	elseif button == 3 then
		Spring.MarkerErasePosition(newPos[1], newPos[2], newPos[3])
	end
end

function AddMarker(str)
	Spring.MarkerAddPoint(markerPos[1], markerPos[2], markerPos[3], str)
end

function StartMarker()
	Spring.SendCommands("unbindkeyset Any+` drawinmap")
	Spring.SendCommands("unbindkeyset Any+\ drawinmap")
	Spring.SendCommands("unbindkeyset Any+0xa7 drawinmap")
end

function CloseMarker()
	Spring.SendCommands("bindkeyset Any+` drawinmap")
	Spring.SendCommands("bindkeyset Any+\ drawinmap")
	Spring.SendCommands("bindkeyset Any+0xa7 drawinmap")
end

function MarkerParseText(utf8char)
	if ignoreNextChar then
		return true
	end
end

function MarkerParseKey(key, mods, isRepeat)
	if ignoreNextChar and not isRepeat then
		ignoreNextChar = false
	end
end
