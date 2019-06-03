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
	obj.fontOutline = nil
	obj.textColor = nil
	obj.captionColor = nil
	obj.fontSize = nil
	obj.fontsize = nil
	obj.fontShadow = nil

	local minimumSize = obj.minimumSize or {}
	obj.minWidth  = obj.minWidth or minimumSize[1]
	obj.minHeight = obj.minHeight or minimumSize[2]
end
