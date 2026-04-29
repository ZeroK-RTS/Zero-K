--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "Claude Bridge",
		desc      = "TCP bridge for external tooling: exec lua, run Spring console commands, stream Spring.Echo. Listens on 127.0.0.1:8200.",
		author    = "Licho + Claude",
		date      = "2026-04-29",
		license   = "GPLv2",
		layer     = 0,
		enabled   = true,
	}
end

--------------------------------------------------------------------------------
-- Pre-flight: LuaSocket must be enabled in springsettings.cfg.
--------------------------------------------------------------------------------

if not (Spring.GetConfigInt("LuaSocketEnabled", 0) == 1) then
	Spring.Echo("[ClaudeBridge] LuaSocketEnabled=0 - widget inactive. Add 'LuaSocketEnabled = 1' and 'TCPAllowListen = 127.0.0.1:8200' to springsettings.cfg.")
	return false
end

local socket = socket
if not socket then
	Spring.Echo("[ClaudeBridge] socket library not available")
	return false
end

--------------------------------------------------------------------------------
-- Minimal JSON (inline; LuaRules/Utilities/json.lua relies on _G which the
-- LuaUI widget sandbox does not expose).
--------------------------------------------------------------------------------

local _byte, _sub, _format, _gsub, _char = string.byte, string.sub, string.format, string.gsub, string.char

local function encStr(s)
	s = _gsub(s, "\\", "\\\\")
	s = _gsub(s, "\"", "\\\"")
	s = _gsub(s, "\n", "\\n")
	s = _gsub(s, "\r", "\\r")
	s = _gsub(s, "\t", "\\t")
	s = _gsub(s, "[%z\1-\31\127]", function(c) return _format("\\u%04x", _byte(c)) end)
	return "\"" .. s .. "\""
end

local jsonEncode
jsonEncode = function(v)
	local t = type(v)
	if v == nil then return "null" end
	if t == "boolean" then return v and "true" or "false" end
	if t == "number" then
		if v ~= v or v == math.huge or v == -math.huge then return "null" end
		return tostring(v)
	end
	if t == "string" then return encStr(v) end
	if t == "table" then
		local n = #v
		local cnt = 0
		for _ in pairs(v) do cnt = cnt + 1 end
		local isArr = (n > 0 and cnt == n)
		if isArr then
			local parts = {}
			for i = 1, n do parts[i] = jsonEncode(v[i]) end
			return "[" .. table.concat(parts, ",") .. "]"
		end
		if cnt == 0 then return "{}" end
		local parts = {}
		for k, val in pairs(v) do
			parts[#parts + 1] = encStr(tostring(k)) .. ":" .. jsonEncode(val)
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end

local jsonDecodeValue

local function skipWs(s, i)
	while true do
		local c = _byte(s, i)
		if c == 32 or c == 9 or c == 10 or c == 13 then i = i + 1
		else return i end
	end
end

local function decodeStr(s, i)
	i = i + 1
	local out = {}
	while true do
		local c = _byte(s, i)
		if not c then error("unterminated string") end
		if c == 34 then return table.concat(out), i + 1 end
		if c == 92 then
			local n = _byte(s, i + 1)
			if     n == 110 then out[#out + 1] = "\n"
			elseif n == 114 then out[#out + 1] = "\r"
			elseif n == 116 then out[#out + 1] = "\t"
			elseif n == 98  then out[#out + 1] = "\b"
			elseif n == 102 then out[#out + 1] = "\f"
			elseif n == 34  then out[#out + 1] = "\""
			elseif n == 47  then out[#out + 1] = "/"
			elseif n == 92  then out[#out + 1] = "\\"
			elseif n == 117 then
				local code = tonumber(_sub(s, i + 2, i + 5), 16)
				if code and code < 128 then out[#out + 1] = _char(code)
				else                        out[#out + 1] = "?" end
				i = i + 4
			else error("bad escape") end
			i = i + 2
		else
			out[#out + 1] = _sub(s, i, i)
			i = i + 1
		end
	end
end

local function decodeNum(s, i)
	local j = i
	while true do
		local c = _byte(s, j)
		if c and ((c >= 48 and c <= 57) or c == 45 or c == 43 or c == 46 or c == 101 or c == 69) then
			j = j + 1
		else break end
	end
	return tonumber(_sub(s, i, j - 1)), j
end

local function decodeArr(s, i)
	i = skipWs(s, i + 1)
	local out = {}
	if _byte(s, i) == 93 then return out, i + 1 end
	while true do
		local v
		v, i = jsonDecodeValue(s, i)
		out[#out + 1] = v
		i = skipWs(s, i)
		local c = _byte(s, i)
		if     c == 44 then i = skipWs(s, i + 1)
		elseif c == 93 then return out, i + 1
		else   error("expected , or ]") end
	end
end

local function decodeObj(s, i)
	i = skipWs(s, i + 1)
	local out = {}
	if _byte(s, i) == 125 then return out, i + 1 end
	while true do
		if _byte(s, i) ~= 34 then error("expected key string") end
		local k
		k, i = decodeStr(s, i)
		i = skipWs(s, i)
		if _byte(s, i) ~= 58 then error("expected :") end
		i = skipWs(s, i + 1)
		local v
		v, i = jsonDecodeValue(s, i)
		out[k] = v
		i = skipWs(s, i)
		local c = _byte(s, i)
		if     c == 44 then i = skipWs(s, i + 1)
		elseif c == 125 then return out, i + 1
		else   error("expected , or }") end
	end
end

jsonDecodeValue = function(s, i)
	i = skipWs(s, i)
	local c = _byte(s, i)
	if c == 34  then return decodeStr(s, i) end
	if c == 123 then return decodeObj(s, i) end
	if c == 91  then return decodeArr(s, i) end
	if c == 116 and _sub(s, i, i + 3) == "true"  then return true,  i + 4 end
	if c == 102 and _sub(s, i, i + 4) == "false" then return false, i + 5 end
	if c == 110 and _sub(s, i, i + 3) == "null"  then return nil,   i + 4 end
	if c == 45 or (c and c >= 48 and c <= 57) then return decodeNum(s, i) end
	error("unexpected char at " .. tostring(i) .. ": " .. tostring(c))
end

local function jsonDecode(s)
	local v = jsonDecodeValue(s, 1)
	return v
end

local json = { encode = jsonEncode, decode = jsonDecode }

--------------------------------------------------------------------------------
-- Config
--------------------------------------------------------------------------------

local HOST            = "127.0.0.1"
local PORT            = 8200
local MAX_OUT_BUF     = 1024 * 1024     -- 1 MB before we drop the client
local MAX_RESULT_LEN  = 64 * 1024       -- truncate huge result strings
local MAX_TABLE_KEYS  = 200

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local server                 -- listening socket
local clients = {}           -- numeric list of sockets, used as set for socket.select
local stateBy = {}           -- sock -> { sock, inBuf, outBuf, streamLogs, peer }

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local function writeFrame(c, frame)
	local ok, encoded = pcall(json.encode, frame)
	if not ok then return end
	c.outBuf = c.outBuf .. encoded .. "\n"
	if #c.outBuf > MAX_OUT_BUF then
		c.overflowed = true
	end
end

local function prettyValue(v, depth, lenAcc)
	depth = depth or 0
	if depth > 5 then return "<...>" end
	local t = type(v)
	if t == "string" then
		if #v > MAX_RESULT_LEN then
			return v:sub(1, MAX_RESULT_LEN) .. "...<truncated " .. (#v - MAX_RESULT_LEN) .. " bytes>"
		end
		return v
	end
	if t == "nil" then return "nil" end
	if t == "number" or t == "boolean" then return tostring(v) end
	if t == "function" or t == "userdata" or t == "thread" then return "<" .. t .. ">" end
	if t == "table" then
		local parts = { "{" }
		local pad = string.rep("  ", depth + 1)
		local count = 0
		for k, val in pairs(v) do
			count = count + 1
			if count > MAX_TABLE_KEYS then
				parts[#parts + 1] = pad .. "...(" .. count .. "+ entries)"
				break
			end
			local keyStr = (type(k) == "string" and ("[" .. string.format("%q", k) .. "]")) or ("[" .. tostring(k) .. "]")
			parts[#parts + 1] = pad .. keyStr .. " = " .. prettyValue(val, depth + 1) .. ","
		end
		parts[#parts + 1] = string.rep("  ", depth) .. "}"
		return table.concat(parts, "\n")
	end
	return tostring(v)
end

local execEnv  -- shared sandbox for repeated EXEC frames so locals persist

local function getExecEnv()
	if not execEnv then
		execEnv = setmetatable({}, { __index = getfenv(1) })
	end
	return execEnv
end

local function runLua(code, asExpression)
	local fn, err
	if asExpression then
		fn = loadstring("return " .. code, "claude_bridge")
	end
	if not fn then
		fn, err = loadstring(code, "claude_bridge")
	end
	if not fn then return false, err end
	setfenv(fn, getExecEnv())
	local results = { pcall(fn) }
	local ok = table.remove(results, 1)
	if not ok then return false, results[1] end
	if #results == 0 then return true, nil end
	if #results == 1 then return true, results[1] end
	return true, results
end

--------------------------------------------------------------------------------
-- Frame dispatch
--------------------------------------------------------------------------------

local function handleFrame(c, frame)
	local id = frame.id
	local kind = frame.kind

	if kind == "ping" then
		writeFrame(c, { id = id, kind = "result", ok = true, value = "pong" })

	elseif kind == "exec" then
		-- Run as statement (no auto-return). Captures the explicit return value.
		local ok, ret = runLua(frame.code or "", false)
		if ok then
			writeFrame(c, { id = id, kind = "result", ok = true, value = prettyValue(ret) })
		else
			writeFrame(c, { id = id, kind = "result", ok = false, error = tostring(ret) })
		end

	elseif kind == "eval" then
		-- Try as expression first (so 'eval Spring.GetGameFrame()' works), then statement.
		local ok, ret = runLua(frame.code or "", true)
		if ok then
			writeFrame(c, { id = id, kind = "result", ok = true, value = prettyValue(ret) })
		else
			writeFrame(c, { id = id, kind = "result", ok = false, error = tostring(ret) })
		end

	elseif kind == "cmd" then
		local cmd = frame.code or frame.cmd or ""
		Spring.SendCommands(cmd)
		writeFrame(c, { id = id, kind = "result", ok = true, value = "" })

	elseif kind == "log_subscribe" then
		c.streamLogs = true
		writeFrame(c, { id = id, kind = "result", ok = true, value = "log streaming on" })

	elseif kind == "log_unsubscribe" then
		c.streamLogs = false
		writeFrame(c, { id = id, kind = "result", ok = true, value = "log streaming off" })

	elseif kind == "screenshot" then
		Spring.SendCommands("screenshot " .. (frame.format or "png"))
		writeFrame(c, { id = id, kind = "result", ok = true, value = "screenshot triggered" })

	elseif kind == "info" then
		writeFrame(c, { id = id, kind = "result", ok = true, value = {
			gameFrame   = Spring.GetGameFrame(),
			gameSeconds = Spring.GetGameSeconds(),
			myTeamID    = Spring.GetMyTeamID(),
			myPlayerID  = Spring.GetMyPlayerID(),
			isReplay    = Spring.IsReplay(),
		} })

	else
		writeFrame(c, { id = id, kind = "result", ok = false, error = "unknown kind: " .. tostring(kind) })
	end
end

local function processIncoming(c)
	while true do
		local nl = c.inBuf:find("\n", 1, true)
		if not nl then break end
		local line = c.inBuf:sub(1, nl - 1)
		c.inBuf = c.inBuf:sub(nl + 1)
		if line ~= "" and line ~= "\r" then
			if line:sub(-1) == "\r" then line = line:sub(1, -2) end
			local ok, frame = pcall(json.decode, line)
			if ok and type(frame) == "table" then
				local handlerOk, handlerErr = pcall(handleFrame, c, frame)
				if not handlerOk then
					writeFrame(c, { id = frame.id, kind = "result", ok = false, error = "handler crashed: " .. tostring(handlerErr) })
				end
			else
				writeFrame(c, { kind = "error", error = "bad json: " .. line:sub(1, 120) })
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Client lifecycle
--------------------------------------------------------------------------------

local function closeClient(sock, why)
	local c = stateBy[sock]
	if not c then return end
	pcall(function() sock:close() end)
	stateBy[sock] = nil
	for i = #clients, 1, -1 do
		if clients[i] == sock then table.remove(clients, i) end
	end
	Spring.Echo(string.format("[ClaudeBridge] client %s disconnected (%s)", c.peer or "?", why or "closed"))
end

local function acceptOne()
	if not server then return end
	local newSock = server:accept()
	if not newSock then return end
	newSock:settimeout(0)
	local ip, port = newSock:getpeername()
	local peer = string.format("%s:%s", tostring(ip), tostring(port))
	local c = { sock = newSock, inBuf = "", outBuf = "", streamLogs = false, peer = peer }
	stateBy[newSock] = c
	clients[#clients + 1] = newSock
	Spring.Echo(string.format("[ClaudeBridge] client %s connected", peer))
	writeFrame(c, { kind = "hello", value = "claude-bridge ready", gameFrame = Spring.GetGameFrame() })
end

--------------------------------------------------------------------------------
-- Widget callins
--------------------------------------------------------------------------------

function widget:Initialize()
	server = socket.bind(HOST, PORT)
	if not server then
		Spring.Echo(string.format("[ClaudeBridge] cannot bind %s:%d - check TCPAllowListen in springsettings.cfg", HOST, PORT))
		widgetHandler:RemoveWidget()
		return
	end
	server:settimeout(0)
	Spring.Echo(string.format("[ClaudeBridge] listening on %s:%d", HOST, PORT))
end

function widget:Shutdown()
	if server then pcall(function() server:close() end); server = nil end
	for sock, _ in pairs(stateBy) do pcall(function() sock:close() end) end
	stateBy = {}
	clients = {}
end

function widget:AddConsoleLine(line, priority)
	if not line or line == "" then return end
	-- Skip our own bridge chatter to avoid feedback loops in the streaming output.
	if line:find("[ClaudeBridge]", 1, true) then return end
	for _, sock in ipairs(clients) do
		local c = stateBy[sock]
		if c and c.streamLogs and not c.overflowed then
			writeFrame(c, { kind = "log", msg = line, priority = priority })
		end
	end
end

function widget:Update()
	if not server then return end
	acceptOne()

	if #clients == 0 then return end

	local readable, writable, err = socket.select(clients, clients, 0)
	if err and err ~= "timeout" then
		Spring.Echo("[ClaudeBridge] select error: " .. tostring(err))
		return
	end

	for _, sock in ipairs(readable or {}) do
		local data, status, partial = sock:receive("*a")
		if status == "closed" then
			closeClient(sock, "remote closed")
		else
			local chunk = data or partial
			if chunk and chunk ~= "" then
				local c = stateBy[sock]
				if c then
					c.inBuf = c.inBuf .. chunk
					processIncoming(c)
				end
			end
		end
	end

	for _, sock in ipairs(writable or {}) do
		local c = stateBy[sock]
		if c then
			if c.overflowed then
				closeClient(sock, "outbuf overflow")
			elseif c.outBuf ~= "" then
				local n, sendErr, partial2 = sock:send(c.outBuf)
				if not n and sendErr == "closed" then
					closeClient(sock, "send closed")
				elseif n then
					c.outBuf = c.outBuf:sub(n + 1)
				elseif partial2 then
					c.outBuf = c.outBuf:sub(partial2 + 1)
				end
			end
		end
	end
end
