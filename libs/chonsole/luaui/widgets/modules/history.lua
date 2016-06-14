local historyFilePath = ".console_history"
local historyFile
local history = {}

local currentHistory = 0
local filteredHistory = {}

function LoadHistory()
	-- read history
	pcall(function()
		for line in io.lines(historyFilePath) do 
			table.insert(history, line)
		end
	end)
	historyFile = io.open(historyFilePath, "a")
end

function CloseHistory()
	if historyFile then
		historyFile:close()
	end
end

function FilterHistory(txt)
	filteredHistory = {}
	for _, historyItem in pairs(history) do
		if historyItem:starts(txt) then
			table.insert(filteredHistory, historyItem)
		end
	end
end

function AddHistory(str)
	if #history > 0 and history[#history] == str then
		return
	end
	table.insert(history, str)
	if historyFile then
		historyFile:write(str .. "\n")
	end
end

function GetCurrentHistory()
	return currentHistory
end

function GetCurrentHistoryItem()
	if currentHistory == 0 then
		return ""
	end
	local historyItem = filteredHistory[#filteredHistory - currentHistory + 1]
	return historyItem or ""
end

function ResetCurrentHistory()
	currentHistory = 0
end

function NextHistoryItem()
	if #filteredHistory > currentHistory then
		--and not (currentHistory == 0 and ebConsole.text ~= "") 
		currentHistory = currentHistory + 1
		ShowHistoryItem()
		ShowSuggestions()
	end
end

function PrevHistoryItem()
	currentHistory = currentHistory - 1
	ShowHistoryItem()
	ShowSuggestions()
end
