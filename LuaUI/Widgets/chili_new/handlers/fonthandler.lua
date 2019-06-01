--//=============================================================================
--// FontSystem

FontHandler = {}


--//=============================================================================
--// cache loaded fonts

local loadedFonts = {}
local refCounts = {}

--//  maximum fontsize difference
--// when we don't find the wanted font rendered with the wanted fontsize
--// (in respect to this threshold) then recreate a new one
local fontsize_threshold = 2

--//=============================================================================
--// Destroy

FontHandler._scream = Script.CreateScream()
FontHandler._scream.func = function()
  for i=1,#loadedFonts do
    gl.DeleteFont(loadedFonts[i])
  end
  loadedFonts = {}
end


local n = 0
function FontHandler.Update()
	n = n + 1
	if (n <= 100) then
		return
	end
	n = 0

	local last_idx = #loadedFonts
	for i=last_idx, 1, -1 do
		if (refCounts[i] <= 0) then
			--// the font isn't in use anymore, free it
			gl.DeleteFont(loadedFonts[i])
			loadedFonts[i] = loadedFonts[last_idx]
			loadedFonts[last_idx] = nil
			refCounts[i] = refCounts[last_idx]
			refCounts[last_idx] = nil
			last_idx = last_idx - 1
		end
	end
end

--//=============================================================================
--// API

function FontHandler.UnloadFont(font)
  for i=1,#loadedFonts do
    local font2 = loadedFonts[i]
    if (font == font2) then
      refCounts[i] = refCounts[i] - 1
      return
    end
  end
end

function FontHandler.LoadFont(fontname,size,outwidth,outweight)
  for i=1,#loadedFonts do
    local font = loadedFonts[i]
    if
      ((font.path == fontname)or(font.path == 'fonts/'..fontname))
      and(font.size - size >= 0) and (font.size - size <= fontsize_threshold)
      and((not outwidth)or(font.outlinewidth == outwidth))
      and((not outweight)or(font.outlineweight == outweight))
    then
      refCounts[i] = refCounts[i] + 1
      return font
    end
  end

  local idx = #loadedFonts+1
  local font = gl.LoadFont(fontname,size,outwidth,outweight)
  loadedFonts[idx] = font
  refCounts[idx] = 1
  return font
end