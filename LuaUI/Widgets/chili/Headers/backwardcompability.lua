--//=============================================================================
--// 

function BackwardCompa(obj)
	obj.font = obj.font or {}
	obj.font.outline = obj.font.outline or obj.fontOutline
	obj.font.color = obj.font.color or obj.captionColor
	obj.font.color = obj.font.color or obj.textColor
	obj.font.size = obj.font.size or obj.fontSize
	obj.font.size = obj.font.size or obj.fontsize
	obj.font.shadow = obj.font.shadow or obj.fontShadow
	obj.bolderColor = obj.borderColor or obj.borderColor1
	obj.fontOutline = nil
	obj.textColor = nil
	obj.captionColor = nil
	obj.fontSize = nil
	obj.fontsize = nil
	obj.fontShadow = nil
end