--//=============================================================================
--//

-- shift left
local function lsh(value,shift)
    return (value*(2^shift)) % 2^24
end
-- shift right
local function rsh(value,shift)
    return math.floor(value/2^shift) % 2^24
end


function UnicodeToUtf8(ch)
	if (ch == 0) then
		return nil
	end

	if     (ch < lsh(1,7)) then
		return string.char(ch)
	elseif (ch < lsh(1,11)) then
		return string.char(
			math.bit_or(0xC0, rsh(ch,6)),
			math.bit_or(0x80, math.bit_and(ch, 0x3F))
		)
	elseif (ch < lsh(1,16)) then
		return string.char(
			math.bit_or(0xE0, rsh(ch,12)),
			math.bit_or(0x80, math.bit_and(rsh(ch,6), 0x3F)),
			math.bit_or(0x80, math.bit_and(       ch, 0x3F))
		)
	elseif (ch < lsh(1,21)) then
		return string.char(
			math.bit_or(0xF0, rsh(ch,18)),
			math.bit_or(0x80, math.bit_and(rsh(ch,12), 0x3F)),
			math.bit_or(0x80, math.bit_and( rsh(ch,6), 0x3F)),
			math.bit_or(0x80, math.bit_and(        ch, 0x3F))
		)
	end

	return nil
end


local function count_leading_ones(num)
	return
	   ((math.bit_and(num, 0xF0) == 0xF0) and 4)
	or ((math.bit_and(num, 0xE0) == 0xE0) and 3)
	or ((math.bit_and(num, 0xC0) == 0xC0) and 2)
	or ((math.bit_and(num, 0x80) == 0x80) and 1)
	or 0
end


local function Utf8GetCharByteLength(text, pos)
	--// UTF8 looks like this
	--// 1Byte == ASCII:      0xxxxxxxxx
	--// 2Bytes encoded char: 110xxxxxxx 10xxxxxx
	--// 3Bytes encoded char: 1110xxxxxx 10xxxxxx 10xxxxxx
	--// 4Bytes encoded char: 11110xxxxx 10xxxxxx 10xxxxxx 10xxxxxx
	--// Originaly there were 5&6 byte versions too, but they were dropped in RFC 3629.
	--// So UTF8 maps to UTF16 range only

	local UTF8_CONT_MASK = 0xC0 --// 11xxxxxx
	local UTF8_CONT_OKAY = 0x80 --// 10xxxxxx

	if (pos <= 0) then
		return 0
	end

	--// read next 4bytes and check if it is an utf8 sequence
	local remainingChars = (text:len() + 1) - pos --FIXME
	if (remainingChars <= 0) then
		return 0
	end

	--// how many bytes are requested for our multi-byte utf8 sequence
	local clo = count_leading_ones(string.byte(text, pos, pos)) --FIXME
	if (clo>4) or (clo==0) then clo = 1 end --// ignore >=5 byte ones cause of RFC 3629

	--// how many healthy utf8 bytes are following
	local numValidUtf8Bytes = 1; --// first char is always valid
	if (math.bit_and(string.byte(text, pos + 1, pos + 1) or 0, UTF8_CONT_MASK) == UTF8_CONT_OKAY) then numValidUtf8Bytes = numValidUtf8Bytes + 1 end
	if (math.bit_and(string.byte(text, pos + 2, pos + 2) or 0, UTF8_CONT_MASK) == UTF8_CONT_OKAY) then numValidUtf8Bytes = numValidUtf8Bytes + 1 end
	if (math.bit_and(string.byte(text, pos + 3, pos + 3) or 0, UTF8_CONT_MASK) == UTF8_CONT_OKAY) then numValidUtf8Bytes = numValidUtf8Bytes + 1 end

	--// check if enough trailing utf8 bytes are healthy
	--// else ignore utf8 and parse it as 8bit Latin-1 char (extended ASCII)
	--// this adds backwardcompatibility with the old renderer
	--// which supported extended ASCII with umlauts etc.
	if (clo > numValidUtf8Bytes) then
		return 1
	end
	return clo
end


function Utf8PrevChar(s, startPos)
	local pos    = math.max(startPos - 4, 1)
	local oldPos = pos
	while (pos < startPos) do
		oldPos = pos
		pos    = pos + Utf8GetCharByteLength(s, pos)
	end
	return oldPos
end
function Utf8NextChar(s, pos)
	return pos + Utf8GetCharByteLength(s, pos)
end

function Utf8BackspaceAt(s, pos)
	if pos <= 1 then return s, pos end
	local p = Utf8PrevChar(s, pos)
	return Utf8DeleteAt(s, p), p
end
function Utf8DeleteAt(s, pos)
	local l = Utf8GetCharByteLength(s, pos)
	return s:sub(1, pos - 1) .. s:sub(pos + l)
end
