--Chat preprocessor. Provide preprocessed chat message for Chili Chat widget

local myName = Spring.GetPlayerInfo(Spring.GetMyPlayerID())
local transmitMagic = "> ["..myName.."]!transmit" -- Lobby is sending to LuaUI
local voiceMagic = "> ["..myName.."]!transmit voice" -- Lobby is sending a voice command to LuaUI
local transmitLobbyMagic = "!transmitlobby" -- LuaUI is sending to lobby

function StringStarts(s, start)
   return string.sub(s, 1, string.len(start)) == start
end

local function Deserialize(text)
  local f, err = loadstring(text)
  if not f then
    Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Error while deserializing  table (compiling): "..tostring(err))
    return
  end
  setfenv(f, {}) -- sandbox
  local success, arg = pcall(f)
  if not success then
    Spring.Log(HANDLER_BASENAME, LOG.ERROR, "Error while deserializing table (calling): "..tostring(arg))
    return
  end
  return arg
end


local MessageProcessor = {}

local PLAYERNAME_PATTERN = '([%w%[%]_]+)' -- to make message patterns easier to read/update

-- message definitions
--[[
pattern syntax:
	see http://www.lua.org/manual/5.1/manual.html#5.4.1
	pattern must contain at least 1 capture group; its content will end up in msg.argument after parseMessage()
	PLAYERNAME will match anything that looks like a playername (see code for definition of PLAYERNAME_PATTERN); it is a capture group
	if message does not contain a PLAYERNAME, add 'noplayername = true' to definition
	it should be possible to add definitions to help debug widgets or whatever... (no guarantee)
--]]
MessageProcessor.MESSAGE_DEFINITIONS = {
	{ msgtype = 'player_to_allies', pattern = '^<PLAYERNAME> Allies: (.*)' },
	{ msgtype = 'player_to_player_received', pattern = '^<PLAYERNAME> Private: (.*)' }, -- TODO test!
	{ msgtype = 'player_to_player_sent', pattern = '^You whispered PLAYERNAME: (.*)' }, -- TODO test!
	{ msgtype = 'player_to_specs', pattern = '^<PLAYERNAME> Spectators: (.*)' },
	{ msgtype = 'player_to_everyone', pattern = '^<PLAYERNAME> (.*)' },

	{ msgtype = 'spec_to_specs', pattern = '^%[PLAYERNAME%] Spectators: (.*)' },
	{ msgtype = 'spec_to_allies', pattern = '^%[PLAYERNAME%] Allies: (.*)' }, -- TODO is there a reason to differentiate spec_to_specs and spec_to_allies??
	{ msgtype = 'spec_to_everyone', pattern = '^%[PLAYERNAME%] (.*)' },

	-- shameful copy-paste -- TODO rewrite pattern matcher to remove this duplication
	{ msgtype = 'replay_spec_to_specs', pattern = '^%[PLAYERNAME %(replay%)%] Spectators: (.*)' },
	{ msgtype = 'replay_spec_to_allies', pattern = '^%[PLAYERNAME %(replay%)%] Allies: (.*)' }, -- TODO is there a reason to differentiate spec_to_specs and spec_to_allies??
	{ msgtype = 'replay_spec_to_everyone', pattern = '^%[PLAYERNAME %(replay%)%] (.*)'},

	{ msgtype = 'label', pattern = '^PLAYERNAME added point: (.+)', discard = true }, -- NOTE : these messages are discarded -- points and labels are provided through MapDrawCmd() callin
	{ msgtype = 'point', pattern = '^PLAYERNAME added point: ', discard = true },
	{ msgtype = 'autohost', pattern = '^> (.+)', noplayername = true },
	{ msgtype = 'other' } -- no pattern... will match anything else
}

local function escapePatternReplacementChars(s)
  return string.gsub(s, "%%", "%%%%")
end

function MessageProcessor:Initialize()
	local escapedPlayernamePattern = escapePatternReplacementChars(PLAYERNAME_PATTERN)
	for _,def in ipairs(self.MESSAGE_DEFINITIONS) do
		if def.pattern then
			def.pattern = def.pattern:gsub('PLAYERNAME', escapedPlayernamePattern) -- patch definition pattern so it is an actual lua pattern string
		end
	end
end

local players = {}

local function SetupPlayers()
	local playerroster = Spring.GetPlayerList()
	
	for i, id in ipairs(playerroster) do
		local name, _, spec, teamId, allyTeamId, _,_,_,_,customkeys = Spring.GetPlayerInfo(id)
		players[name] = { id = id, spec = spec, allyTeamId = allyTeamId, muted = (customkeys and customkeys.muted == 1) }
	end
end

local function getSource(spec, allyTeamId)
	return (spec and 'spec')
		or ((Spring.GetMyTeamID() == allyTeamId) and 'ally')
		or 'enemy'
end

-- update msg members msgtype, argument, source and playername (when relevant)
function MessageProcessor:ParseMessage(msg)
  for _, candidate in ipairs(self.MESSAGE_DEFINITIONS) do
    if candidate.pattern == nil then -- for fallback/other messages
      msg.msgtype = candidate.msgtype
      msg.argument = msg.text
	  msg.source = 'other'
      return
    end
    local capture1, capture2 = msg.text:match(candidate.pattern)
    if capture1 then
      msg.msgtype = candidate.msgtype
      if candidate.noplayername then
        msg.argument = capture1
	msg.source = 'other'
	return
      else
        local playername = capture1
        if players[playername] then
	local player = players[playername]
	  msg.player = player
	  msg.source = getSource(player.spec, player.allyTeamId)
	  msg.playername = playername
	  msg.argument = capture2
	  return
        end
      end
    end
  end
end

function MessageProcessor:ProcessConsoleLine(msg)
	self:ParseMessage(msg)
end

function MessageProcessor:ProcessConsoleBuffer(count)
	local bufferMessages = Spring.GetConsoleBuffer(count)
	for i = 1,#bufferMessages do
		self:ProcessConsoleLine(bufferMessages[i])
	end
	return bufferMessages
end

SetupPlayers()
MessageProcessor:Initialize()
return myName, transmitMagic, voiceMagic, transmitLobbyMagic, MessageProcessor