function gadget:GetInfo()
  return {
    name      = "lavarise",
    desc      = "gayly hot",
    author    = "Adapted from knorke's gadget by jseah",
    date      = "Feb 2011, 2011; May 2012",
    license   = "weeeeeee iam on horse",
    layer     = -3,
    enabled   = true
  }
end



if (gadgetHandler:IsSyncedCode()) then
tideRhym = {}
tideIndex = 1
tideContinueFrame = 0
local minheight, maxheight = Spring.GetGroundExtremes()
lavaLevel = minheight - lavarise - 20
lavaGrow = 0.25
lavarise = (maxheight - minheight) / 6
_G.Game.mapSizeX = Game.mapSizeX
_G.Game.mapSizeY = Game.mapSizeY
gameframe = 0

function gadget:Initialize()
    if(Spring.GetModOptions().zkmode ~= "lavarise") then
	    gadgetHandler:RemoveGadget()
	end
	addTideRhym (lavaLevel + lavarise, 0.25, 300)
	
	--addTideRhym (-21, 0.25, 5)
	--addTideRhym (150, 0.25, 3)
	--addTideRhym (-20, 0.25, 5)
	--addTideRhym (150, 0.25, 5)
	--addTideRhym (-20, 1, 5)
	--addTideRhym (180, 0.5, 60)
	--addTideRhym (240, 0.2, 10)
end


function addTideRhym (targetLevel, speed, remainTime)
	local newTide = {}
	newTide.targetLevel = targetLevel
	newTide.speed = speed
	newTide.remainTime = remainTime
	table.insert (tideRhym, newTide)
end


function updateLava ()
	if (lavaGrow < 0 and lavaLevel < tideRhym[tideIndex].targetLevel) 
		or (lavaGrow > 0 and lavaLevel > tideRhym[tideIndex].targetLevel) then
		tideContinueFrame = gameframe + tideRhym[tideIndex].remainTime*30
		lavaGrow = 0
		Spring.Echo ("Next LAVA LEVEL change in " .. (tideContinueFrame-gameframe)/30 .. " seconds", "Lava Height now " .. tideRhym[tideIndex].targetLevel, "Next Lava Height " .. tideRhym[tideIndex].targetLevel + lavarise + 0.25)
	end
	
	if (gameframe == tideContinueFrame) then
		addTideRhym (lavaLevel + lavarise, 0.25, 300)
		tideIndex = tideIndex + 1
		--Spring.Echo ("tideIndex=" .. tideIndex .. " target=" ..tideRhym[tideIndex].targetLevel )		
		if  (lavaLevel < tideRhym[tideIndex].targetLevel) then 
			lavaGrow = tideRhym[tideIndex].speed
		else
			lavaGrow = -tideRhym[tideIndex].speed
		end
	end
end


function gadget:GameFrame (f)
	gameframe = f
	_G.lavaLevel = lavaLevel+math.sin(f/30)*2
	_G.frame = f
	if (f%10==0) then
		lavaDeathCheck()
	end

	--if (f%2==0) then
		updateLava ()
		lavaLevel = lavaLevel+lavaGrow
		
		--if (lavaLevel == 160) then lavaGrow=-0.5 end
		--if (lavaLevel == -10) then lavaGrow=0.25 end
	--end
	
	--if (f%10==0) then		
		local x = math.random(1,Game.mapX*512)
		local z = math.random(1,Game.mapY*512)
		local y = Spring.GetGroundHeight(x,z)
		if y  < lavaLevel then
			--Spring.SpawnCEG("tpsmokecloud", x, lavaLevel, z)
		end
	--end
	
end

function lavaDeathCheck ()
local all_units = Spring.GetAllUnits ()
	for i in pairs(all_units) do
		x,y,z = Spring.GetUnitBasePosition   (all_units[i])
		if (y ~= nil) then
			if (y and y < lavaLevel) then 
				--Spring.AddUnitDamage (all_units[i],1000) 
				Spring.DestroyUnit (all_units[i])
				--Spring.SpawnCEG("tpsmokecloud", x, y, z)
			end
		end
	end
end


else --- UNSYCNED:

function gadget:DrawWorld ()  
    if (SYNCED.lavaLevel) then
		r = 0.8
		DrawWorldTimer=DrawWorldTimer or Spring.GetTimer()		
		
         --gl.Color(1-cm1,1-cm1-cm2,0.5,1)
		
		--DrawGroundHuggingSquare(1-cm1,1-cm1-cm2,0.5,1,  0, 0, Game.mapX*512, Game.mapY*512 ,SYNCED.lavaLevel) --***map.width bla
		DrawGroundHuggingSquare(1,1,1,1,  0, 0, Game.mapX*512, Game.mapY*512 ,SYNCED.lavaLevel) --***map.width bla
		--DrawGroundHuggingSquare(0,0.5,0.8,0.8,  0, 0, Game.mapX*512, Game.mapY*512 ,SYNCED.lavaLevel) --***map.width bla
	end
end

function DrawGroundHuggingSquare(red,green,blue,alpha,  x1,z1,x2,z2,   HoverHeight)
	gl.PushAttrib(GL.ALL_ATTRIB_BITS)
	gl.DepthTest(true)
	gl.DepthMask(true)	
	gl.Texture(":a:bitmaps\\lava2.jpg")-- Texture file	
	gl.Color(red,green,blue,alpha)	
	gl.BeginEnd(GL.QUADS,DrawGroundHuggingSquareVertices,  x1,z1, x2,z2,  HoverHeight)
	gl.Texture(false)
	gl.DepthMask(false)
	gl.DepthTest(false)	
	gl.PopAttrib()
end


function DrawGroundHuggingSquareVertices(x1,z1, x2,z2,   HoverHeight)
  local y=HoverHeight--+Spring.GetGroundHeight(x,z)  
  local s = 2+math.sin (SYNCED.frame/50)/10
  gl.TexCoord(-s,-s)
  gl.Vertex(x1 ,y, z1)
  
  gl.TexCoord(-s,s) 
  gl.Vertex(x1,y,z2)
  
  gl.TexCoord(s,s)
  gl.Vertex(x2,y,z2)
  
  gl.TexCoord(s,-s)
  gl.Vertex(x2,y,z1)
end

end--ende unsync