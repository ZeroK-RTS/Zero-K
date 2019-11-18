
function gadget:GetInfo()
  return {
    name      = "Terrain Texture Handler",
    desc      = "Handles requested changes to terrain texture by unit_terraform.lua gadget. Only updates for players which can see terrain (according to UHM).",
    author    = "Google Frog",
    date      = "25 June 2012", --24 August 2013
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local SQUARE_SIZE = 1024
local SQUARES_X = MAP_WIDTH/SQUARE_SIZE
local SQUARES_Z = MAP_HEIGHT/SQUARE_SIZE
local UHM_WIDTH = 64
local UHM_HEIGHT = 64
local UHM_X = UHM_WIDTH/MAP_WIDTH
local UHM_Z = UHM_HEIGHT/MAP_HEIGHT
local BLOCK_SIZE = 8

local spSetMapSquareTexture = Spring.SetMapSquareTexture
local spGetMapSquareTexture = Spring.GetMapSquareTexture
local spGetMyTeamID         = Spring.GetMyTeamID
local floor = math.floor

local SAVE_FILE = "Gadgets/terrain_texture_handler.lua"

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local TerrainTextureFunctions = {}

function TerrainTextureFunctions.UpdateAll()
	SendToUnsynced("UpdateAll")
end

function gadget:Initialize()
	_G.SentBlockList = {}
	GG.TerrainTexture = TerrainTextureFunctions
end

function GG.Terrain_Texture_changeBlockList(blockList)
	_G.SentBlockList = blockList
	SendToUnsynced("changeBlockList")
end

function gadget:Load(zip)
	if not (GG.SaveLoad and GG.SaveLoad.ReadFile) then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end

	local loadData = GG.SaveLoad.ReadFile(zip, "Terrain Texture", SAVE_FILE) or {}
	if loadData and #loadData > 0 then
		GG.Terrain_Texture_changeBlockList(loadData)
	end
	SendToUnsynced("UpdateAll")
end

function gadget:Shutdown()
	if Spring.IsCheatingEnabled() then
		SendToUnsynced("Shutdown")
	end
end

else
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local glTexture = gl.Texture
local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture

local TEXTURE_COUNT = 3
local texturePool = {
	-- [0] == original map texture
	[1] = {
		texture = "LuaRules/Images/terraform/stripe1.png",
		size = 64,
		tile = BLOCK_SIZE/64,
	},
	[2] = {
		texture = "LuaRules/Images/terraform/stripe2.png",
		size = 64,
		tile = BLOCK_SIZE/64,
	},
	[3] = {
		texture = "LuaRules/Images/terraform/stripe3.png",
		size = 64,
		tile = BLOCK_SIZE/64,
	},
}

-- Terminology:
-- Block  - Smallest element of texture drawn on map.
-- Square - Squares of map texture which are replaced at once with spSetMapSquareTexture.
-- Chunk  - Piece of the UHM.

local mapTex = {} -- 2d array of textures

local blockStateMap = {} -- keeps track of drawn texture blocks.
local chunkMap = {} -- map of UHM chunk that stores pending changes.
local chunkUpdateList = {count = 0, data = {}} -- list of chuncks to update
local chunkUpdateMap = {} -- map of chunks which are in list. Prevent duplicate entry if UHMU is called twice

local syncedHeights = {} -- list of synced heightmap point values

local UMHU_updatequeue = {} -- send update data from gadget:UnsyncedHeightMapUpdate() to gadget:DrawWorld()

local function ChangeTextureBlock(x, z, myTex)
	-- Ensure they snap to grid
	x = math.floor(x/8)*8
	z = math.floor(z/8)*8
	
	-- UHM chunk location of x,z
	local cx = floor(x/UHM_WIDTH)
	local cz = floor(z/UHM_HEIGHT)
	-- Drawing square location of x,z
	local sx = floor(x/SQUARE_SIZE)
	local sz = floor(z/SQUARE_SIZE)

	-- Ensure the existence of this UHM chunk
	if not (chunkMap[cx] and chunkMap[cx][cz]) then
		chunkMap[cx] = chunkMap[cx] or {}
		chunkMap[cx][cz] = {
			squareMap = {},
			squareList = {count = 0, data = {}},
			blockMap = {},
			blockList = {count = 0, data = {}},
		}
	end
	
	local chunk = chunkMap[cx][cz]
	
	-- Update Block map and list
	local blockMap = chunk.blockMap
	local blockList = chunk.blockList
	if blockMap[x] and blockMap[x][z] then
		-- There is already a pending change for this block
		local otherIndex = blockMap[x][z]
		local otherTex = blockList.data[otherIndex].tex
		if blockStateMap[x] and blockStateMap[x][z] == myTex then
			-- Remove pending change
			local endX = blockList.data[blockList.count].x
			local endZ = blockList.data[blockList.count].z
			blockList.data[otherIndex] = blockList.data[blockList.count]
			blockMap[endX][endZ] = otherIndex
			blockMap[x][z] = nil
			blockList.data[blockList.count] = nil
			blockList.count = blockList.count - 1
		elseif myTex == otherTex then
			-- There is nothing to do, changes are the same.
		else
			-- Replace pending change
			blockList.data[otherIndex].tex = myTex
		end
		return -- Always return, square is sure to be already marked.
	elseif not (blockStateMap[x] and blockStateMap[x][z]) and myTex == 0 then
		-- adding no new texture to unchanged block
		return
	elseif blockStateMap[x] and blockStateMap[x][z] == myTex then
		-- Nothing to do if there is no change to the seen map`
		-- and if there is no pending change to this block.
		return
	else
		-- Add a new pending change.
		blockList.count = blockList.count + 1
		blockList.data[blockList.count] = {x = x, z = z, tex = myTex}
		blockMap[x] = blockMap[x] or {}
		blockMap[x][z] = blockList.count
	end
	
	-- Mark the square as changed.
	local squareMap = chunk.squareMap
	local squareList = chunk.squareList
	
	if not (squareMap[sx] and squareMap[sx][sz]) then
		squareMap[sx] = squareMap[sx] or {}
		squareMap[sx][sz] = true
		squareList.count = squareList.count + 1
		squareList.data[squareList.count] = {x = sx, z = sz}
	end
end

local function changeBlockList()
	local blockList = SYNCED.SentBlockList
	if type(blockList) == "table" then
		for i, v in spairs(blockList) do
			ChangeTextureBlock(v.x, v.z, v.tex)
		end
	end
end

local function drawTextureOnSquare(x,z,size,sx,sz,sourceSize)
	local x1 = 2*x/SQUARE_SIZE - 1
	local z1 = 2*z/SQUARE_SIZE - 1
	local x2 = 2*(x+size)/SQUARE_SIZE - 1
	local z2 = 2*(z+size)/SQUARE_SIZE - 1
	gl.TexRect(x1,z1,x2,z2,sx,sz,sx+sourceSize,sz+sourceSize)
end

local function drawCopySquare()
	gl.TexRect(-1,1,1,-1)
end

function gadget:DrawGenesis()
	--Process gadget:UnsyncedHeightMapUpdate() data--
	local updateCount = 1
	local maxUpdateCount = 20 --how much texture update for each gadget:DrawWorld() frame
	while (#UMHU_updatequeue>0) do
		local x1, z1, x2, z2 = UMHU_updatequeue[1][1],UMHU_updatequeue[1][2],UMHU_updatequeue[1][3],UMHU_updatequeue[1][4]
		local cz = floor(z1*8/UHM_HEIGHT)
		local cx1 = floor(x1*8/UHM_WIDTH)
		local cx2 = floor(x2*8/UHM_WIDTH-0.001)
		--Spring.MarkerAddPoint(x1*8,0,z1*8,"p1")
		--Spring.MarkerAddPoint(x2*8,0,z2*8,"p2")
		-- For some reason multiple chunks can be covered in one update but only in a row along the x direction.
		for cx = cx1, cx2 do
			if chunkMap[cx] and chunkMap[cx][cz] and not (chunkUpdateMap[cx] and chunkUpdateMap[cx][cz]) then --only process chunk that has been added by ChangeTextureBlock()
				chunkUpdateMap[cx] = chunkUpdateMap[cx] or {}
                chunkUpdateMap[cx][cz] = true
				chunkUpdateList.count = chunkUpdateList.count + 1
				chunkUpdateList.data[chunkUpdateList.count] = {x = cx, z = cz}
				--Spring.MarkerAddPoint(x,0,z,"point triggered")
				--Spring.MarkerAddPoint(cx*UHM_WIDTH,0,cz*UHM_HEIGHT,"To update")
				updateCount = updateCount +1
			end
		end
		table.remove(UMHU_updatequeue,1)
		if updateCount >= maxUpdateCount then
			break;
		end
	end

	--Apply the required texture updates
	if chunkUpdateList.count ~= 0 then
		
		--gl.DepthMask(false)
		--gl.DepthTest(false)
		--gl.Color(1,1,1,1)
		--gl.AlphaTest(false)
		
		gl.ResetState()
		gl.ResetMatrices()
		
		-- Find and sort the required texture updates
		local toRestore = {count = 0, data = {}}
		local restoreMap = {}
		local toTexture = {}
		for c = 1, chunkUpdateList.count do
			local chunkUpdate = chunkUpdateList.data[c]
			local chunk = chunkMap[chunkUpdate.x][chunkUpdate.z]
			local blockList = chunk.blockList
			for i = 1, blockList.count do
				local block = blockList.data[i]
				local x = block.x
				local z = block.z
				local tex = block.tex
				local sx = floor(x/SQUARE_SIZE)
				local sz = floor(z/SQUARE_SIZE)
				
				if not mapTex[sx] then
					mapTex[sx] = {}
				end
				
				if not mapTex[sx][sz] then
					if GG.mapgen_squareTexture and GG.mapgen_squareTexture[sx] and GG.mapgen_squareTexture[sx][sz]
							and GG.mapgen_currentTexture and GG.mapgen_currentTexture[sx] and GG.mapgen_currentTexture[sx][sz] then
						mapTex[sx][sz] = {
							orig = GG.mapgen_squareTexture[sx][sz],
							cur  = GG.mapgen_currentTexture[sx][sz],
						}
					else
						mapTex[sx][sz] = {
							cur = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
								wrap_s = GL.CLAMP_TO_EDGE,
								wrap_t = GL.CLAMP_TO_EDGE,
								fbo = true,
								min_filter = GL.LINEAR_MIPMAP_NEAREST,
							}),
							orig = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
								wrap_s = GL.CLAMP_TO_EDGE,
								wrap_t = GL.CLAMP_TO_EDGE,
								fbo = true,
							}),
						}
						if mapTex[sx][sz].orig and mapTex[sx][sz].cur then
							spGetMapSquareTexture(sx, sz, 0, mapTex[sx][sz].orig)
							gl.Texture(mapTex[sx][sz].orig)
							gl.RenderToTexture(mapTex[sx][sz].cur, drawCopySquare)
						else
							if mapTex[sx][sz].cur then
								gl.DeleteTextureFBO(mapTex[sx][sz].cur)
							end
							if mapTex[sx][sz].orig then
								gl.DeleteTextureFBO(mapTex[sx][sz].orig)
							end
							mapTex[sx][sz] = nil
						end
					end
				end
				
				if texturePool[tex] then --if texture (tex: 1,2,3) have been set to this chunk
					-- Set Texture
					blockStateMap[x] = blockStateMap[x] or {}
					blockStateMap[x][z] = tex
					
					if not toTexture[tex] then
						toTexture[tex] = {
							count = 0,
							data = {}
						}
					end
					
					local toTex = toTexture[tex]
					toTex.count = toTex.count + 1
					toTex.data[toTex.count] = {x = x, z = z, sx = sx, sz = sz}
				else
					-- Restore Texture
					if blockStateMap[x] then
						blockStateMap[x][z] = nil
					end
					
					if not (restoreMap[sx] and restoreMap[sx][sz]) then
						toRestore.count = toRestore.count + 1
						toRestore.data[toRestore.count] = {
							sx = sx,
							sz = sz,
							count = 0,
							data = {}
						}
						restoreMap[sx] = restoreMap[sx] or {}
						restoreMap[sx][sz] = toRestore.count
					end
					
					local square = toRestore.data[restoreMap[sx][sz]]
					square.count = square.count + 1
					square.data[square.count] = {x = x, z = z}
				end
			end
		end

		-- Restore texture to original
		for i = 1, toRestore.count do
			local square = toRestore.data[i]
			local sx = square.sx
			local sz = square.sz
			if mapTex[sx][sz] then
				gl.Texture(mapTex[sx][sz].orig)
				for j = 1, square.count do
					local x = square.data[j].x
					local z = square.data[j].z
					local sourceX = (x-sx*SQUARE_SIZE)/SQUARE_SIZE
					local sourceZ = (z-sz*SQUARE_SIZE)/SQUARE_SIZE
					local sourceSize = BLOCK_SIZE/SQUARE_SIZE
					gl.RenderToTexture(mapTex[sx][sz].cur, drawTextureOnSquare, x-sx*SQUARE_SIZE,z-sz*SQUARE_SIZE, BLOCK_SIZE, sourceX, sourceZ, sourceSize)
				end
			end
		end
		
		-- Apply Map Texture
		for t = 1, TEXTURE_COUNT do
			if toTexture[t] then
				local toTex = toTexture[t]
				local tex = texturePool[t]
				gl.Texture(tex.texture)
				for i = 1, toTex.count do
					local block = toTex.data[i]
					local x = block.x
					local z = block.z
					local sx = block.sx
					local sz = block.sz
					local dx = (x/tex.size)%1
					local dz = (z/tex.size)%1
					if mapTex[sx][sz] then
						gl.RenderToTexture(mapTex[sx][sz].cur, drawTextureOnSquare, x-sx*SQUARE_SIZE,z-sz*SQUARE_SIZE, BLOCK_SIZE, dx, dz, tex.tile)
					end
				end
			end
		end
		
		-- Set modified squares (no more than once each)
		local updatedSquareMap = {} -- map of squares which have already been updated
		for c = 1, chunkUpdateList.count do
			local chunkUpdate = chunkUpdateList.data[c]
			local chunk = chunkMap[chunkUpdate.x][chunkUpdate.z]

			local squareList = chunk.squareList
			for i = 1, squareList.count do
				local square = squareList.data[i]
				local sx = square.x
				local sz = square.z
				if mapTex[sx][sz] and not (updatedSquareMap[sx] and updatedSquareMap[sx][sz]) then
					gl.GenerateMipmap(mapTex[sx][sz].cur)
					spSetMapSquareTexture(sx,sz, mapTex[sx][sz].cur)
					--Spring.MarkerAddPoint(sx*SQUARE_SIZE,0,sz*SQUARE_SIZE,Spring.GetGameFrame())
					updatedSquareMap[sx] = updatedSquareMap[sx] or {}
					updatedSquareMap[sx][sz] = true
				end
			end
			
			-- Wipe updated chunks
			chunkMap[chunkUpdate.x][chunkUpdate.z] = nil
			chunkUpdateMap[chunkUpdate.x][chunkUpdate.z] = nil
		end
		
		chunkUpdateList = {count = 0, data = {}}
		
		glTexture(false)
	end
end

function gadget:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
	--Spring.Echo("UHMU" .. " " .. Spring.GetGameFrame())
	UMHU_updatequeue[#UMHU_updatequeue+1] ={x1, z1, x2, z2} --sent to gadget:DrawWorld()
end

local function UpdateAll()
	for z = 0, MAP_HEIGHT/8 - 8, 8 do
		UMHU_updatequeue[#UMHU_updatequeue+1] = {0, z, MAP_WIDTH/8 - 8, z + 8}
	end
end

function gadget:Save(zip)
	if not GG.SaveLoad then
		Spring.Log(gadget:GetInfo().name, LOG.ERROR, "Failed to access save/load API")
		return
	end
	
	local blockList = {}
	-- Save the current texture
	for x, rest in pairs(blockStateMap) do
		for z, tex in pairs(rest) do
			table.insert(blockList, {x = x, z = z, tex = tex})
		end
	end
	
	-- Save the pending changes
	for _, chunkCols in pairs(chunkMap) do
		for _, chunk in pairs(chunkCols) do
			local chunkBlocks = chunk.blockList
			for i = 1, chunkBlocks.count do
				local b = chunkBlocks.data[i]
				table.insert(blockList, {x = b.x, z = b.z, tex = b.tex})
			end
		end
	end

	GG.SaveLoad.WriteSaveData(zip, SAVE_FILE, Spring.Utilities.MakeRealTable(blockList, "Terrain Texture"))
end

local function Shutdown()
	-- Iterating over a map here but it's so rare that I don't care!
	for x = 0, SQUARES_X-1 do
		if mapTex[x] then
			for z = 0, SQUARES_Z-1 do
				if mapTex[x][z] then
					spSetMapSquareTexture(x,z, "")
					gl.DeleteTextureFBO(mapTex[x][z].cur)
					gl.DeleteTextureFBO(mapTex[x][z].orig)
				end
			end
		end
	end
	
	gadgetHandler.RemoveSyncAction("changeBlockList")
	gadgetHandler.RemoveSyncAction("UpdateAll")
	gadgetHandler.RemoveSyncAction("Shutdown")
end

function gadget:Initialize()
	if (not gl.RenderToTexture) then --super bad graphic driver
		return
	end

	--for x = 0, Game.mapSizeX-8, 8 do
	--	for z = 0, Game.mapSizeZ-8, 8 do
	--		ChangeTextureBlock(x,z,math.ceil(math.random(3)))
	--	end
	--end
	
	
	gadgetHandler:AddSyncAction("changeBlockList", changeBlockList)
	gadgetHandler:AddSyncAction("UpdateAll", UpdateAll)
	gadgetHandler:AddSyncAction("Shutdown", Shutdown)
end

end
