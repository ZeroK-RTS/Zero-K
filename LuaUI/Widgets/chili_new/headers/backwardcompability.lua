--//=============================================================================
--// 

local function CheckNoneNil(x, fallback)
	if (x ~= nil) then
		return x
	else
		return fallback
	end
end


function BackwardCompa(obj)
	obj.font = obj.font or {}
	obj.font.outline = CheckNoneNil(obj.font.outline, obj.fontOutline)
	obj.font.color = CheckNoneNil(obj.font.color, obj.captionColor)
	obj.font.color = CheckNoneNil(obj.font.color, obj.textColor)
	obj.font.size = CheckNoneNil(obj.font.size, obj.fontSize)
	obj.font.size = CheckNoneNil(obj.font.size, obj.fontsize)
	obj.font.shadow = CheckNoneNil(obj.font.shadow, obj.fontShadow)
	obj.bolderColor = CheckNoneNil(obj.borderColor, obj.borderColor1)
	obj.fontOutline = nil
	obj.textColor = nil
	obj.captionColor = nil
	obj.fontSize = nil
	obj.fontsize = nil
	obj.fontShadow = nil
end
