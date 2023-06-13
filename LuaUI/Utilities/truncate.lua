
Spring.Utilities = Spring.Utilities or {}

function Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	if (not maxLength) then
		return myString
	end
	local length = string.len(myString)
	while myFont:GetTextWidth(myString) > maxLength do
		length = length - 1
		myString = string.sub(myString, 0, length)
		if length < 1 then
			return ""
		end
	end
	return myString
end

function Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return myString
	end
	local truncation = Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
	local dotDotWidth = myFont:GetTextWidth("..")
	truncation = Spring.Utilities.GetTruncatedString(truncation, myFont, maxLength - dotDotWidth)
	return truncation .. ".."
end

function Spring.Utilities.TruncateStringIfRequired(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedString(myString, myFont, maxLength)
end

function Spring.Utilities.TruncateStringIfRequiredAndDotDot(myString, myFont, maxLength)
	if (not maxLength) or (myFont:GetTextWidth(myString) <= maxLength) then
		return false
	end
	return Spring.Utilities.GetTruncatedStringWithDotDot(myString, myFont, maxLength)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
