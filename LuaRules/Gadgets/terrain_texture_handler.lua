
function gadget:GetInfo()
  return {
    name      = "Terrain Texture Handler",
    desc      = "Handles requested changes to terrain texture. Only updates for players which can see terrain (according to UHM).",
    author    = "Google Frog",
    date      = "25 June 2012",
    license   = "GNU GPL, v2 or later",
    layer     = 0,
    enabled   = true  --  loaded by default?
  }
end

if (gadgetHandler:IsSyncedCode()) then

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- SYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

function gadget:Initialize()
	_G.SentBlockList = {}
end

function GG.Terrain_Texture_changeBlockList(blockList)
	_G.SentBlockList = blockList
	SendToUnsynced("changeBlockList")
end

function gadget:Shutdown()
	SendToUnsynced("Shutdown")
end

else
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UNSYNCED
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

local MAP_WIDTH = Game.mapSizeX
local MAP_HEIGHT = Game.mapSizeZ
local SQUARE_SIZE = 1024
local SQUARES_X = MAP_WIDTH/SQUARE_SIZE
local SQUARES_Z = MAP_HEIGHT/SQUARE_SIZE
local UHM_X = 8
local UHM_Z = 8
local UHM_WIDTH = MAP_WIDTH/UHM_X
local UHM_HEIGHT = MAP_HEIGHT/UHM_Z
local BLOCK_SIZE = 8

local spSetMapSquareTexture = Spring.SetMapSquareTexture
local spGetMapSquareTexture = Spring.GetMapSquareTexture
local spGetMyTeamID         = Spring.GetMyTeamID
local spGetGroundHeight     = Spring.GetGroundHeight
local spGetGroundOrigHeight = Spring.GetGroundOrigHeight
local floor = math.floor

local glTexture = gl.Texture
local glCreateTexture = gl.CreateTexture
local glDeleteTexture = gl.DeleteTexture

local texturePool = {
	-- [0] == origional map texture
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

local tempTex
local mapTex = {} -- 2d array of textures

local blockStateMap = {} -- keeps track of drawn texture blocks.
local chunkMap = {} -- map of UHM chunk that stores pending changes.
local chunkUpdateList = {count = 0, data = {}} -- list of chuncks to update
local chunkUpdateMap = {} -- map of chunks which are in list

local callinChunkMap = {} -- map of UHM updated callins with heights

local function ChangeTextureBlock(x, z, myTex)
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
		-- Nothing to do if there is no change to the seen map
		-- and if there is no pending change to this block.
		return
	else
		-- Add a new pending change.
		blockList.count = blockList.count + 1
		blockList.data[blockList.count] = {x = x, z = z, tex = myTex}
		blockMap[x] = blockList[x] or {}
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
	if type(SYNCED.SentBlockList) == "table" then
		for i, v in spairs(SYNCED.SentBlockList) do
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

function gadget:DrawWorld()

	if chunkUpdateList.count ~= 0 then
		
		-- Update map textures
		for c = 1, chunkUpdateList.count do
			local chunkUpdate = chunkUpdateList.data[c]
			local chunk = chunkMap[chunkUpdate.x][chunkUpdate.z]
			local blockList = chunk.blockList
			for i = 1, blockList.count do
				local block = blockList.data[i]
				local x = block.x
				local z = block.z
				local tex = texturePool[block.tex]
				local sx = floor(x/SQUARE_SIZE)
				local sz = floor(z/SQUARE_SIZE)
				if not mapTex[sx] then
					mapTex[sx] = {}
				end
				if not mapTex[sx][sz] then
					mapTex[sx][sz] = {
						cur = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
							wrap_s = GL.CLAMP_TO_EDGE, 
							wrap_t = GL.CLAMP_TO_EDGE,
							fbo = true,
						}),
						orig = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
							wrap_s = GL.CLAMP_TO_EDGE, 
							wrap_t = GL.CLAMP_TO_EDGE,
							fbo = true,
						}),
					}
					
					spGetMapSquareTexture(sx,sz, 0,tempTex)
					gl.Texture(tempTex)
					gl.RenderToTexture(mapTex[sx][sz].cur, drawCopySquare)
					gl.RenderToTexture(mapTex[sx][sz].orig, drawCopySquare)
				end
				if tex then
					blockStateMap[x] = blockStateMap[x] or {}
					blockStateMap[x][z] = tex
					local dx = (x/tex.size)%1
					local dz = (z/tex.size)%1
					gl.Texture(tex.texture)
					gl.RenderToTexture(mapTex[sx][sz].cur, drawTextureOnSquare, x-sx*SQUARE_SIZE,z-sz*SQUARE_SIZE, BLOCK_SIZE, dx, dz, tex.tile)
				else
					if blockStateMap[x] then
						blockStateMap[x][z] = nil
					end
					gl.Texture(mapTex[sx][sz].orig)
					local sourceX = (x-sx*SQUARE_SIZE)/SQUARE_SIZE
					local sourceZ = (z-sz*SQUARE_SIZE)/SQUARE_SIZE
					local sourceSize = BLOCK_SIZE/SQUARE_SIZE
					gl.RenderToTexture(mapTex[sx][sz].cur, drawTextureOnSquare, x-sx*SQUARE_SIZE,z-sz*SQUARE_SIZE, BLOCK_SIZE, sourceX, sourceZ, sourceSize)
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
				if not (updatedSquareMap[sx] and updatedSquareMap[sz]) then
					spSetMapSquareTexture(sx,sz, mapTex[sx][sz].cur)
					--Spring.MarkerAddPoint(sx*SQUARE_SIZE,0,sz*SQUARE_SIZE,"Square Updated")
					updatedSquareMap[sx] = updatedSquareMap[sx] or {}
					updatedSquareMap[sx][sz] = true
				end
			end
			
			-- Wipe updated chunks
			chunkMap[chunkUpdate.x][chunkUpdate.z] = nil
			chunkUpdateMap[chunkUpdate.x][chunkUpdate.z] = nil
		end
		
		chunkUpdateList = {count = 0, data = {}}
	end
end

function gadget:UnsyncedHeightMapUpdate(x1, z1, x2, z2)
	local x = floor((x1+1.5)*0.5)*16
	local z = floor((z1+1.5)*0.5)*16
	
	local cx = floor(x/UHM_WIDTH)
	local cz = floor(z/UHM_HEIGHT)
	
	if not (callinChunkMap[cx] and callinChunkMap[cx][cz]) then
		callinChunkMap[cx] = callinChunkMap[cx] or {}
		callinChunkMap[cx][cz] = {}
	end
	--local chunk = callinChunkMap[cx][cz]
	--if not (chunk[x] and chunk[x][z]) then
	--	chunk[x] = chunk[x] or {}
	--	chunk[x][z] = spGetGroundHeight(x,z)
	--end
	--Spring.MarkerAddPoint(x,0,z,"point")
	local height = spGetGroundHeight(x,z)
	--if height ~= chunk[x][z] then
		if chunkMap[cx] and chunkMap[cx][cz] and not (chunkUpdateMap[cx] and chunkUpdateMap[cx][cz]) then
			chunkUpdateMap[cx] = chunkUpdateMap[cx] or {}
			chunkUpdateMap[cx][cz] = true
			chunkUpdateList.count = chunkUpdateList.count + 1
			chunkUpdateList.data[chunkUpdateList.count] = {x = cx, z = cz}
			--Spring.MarkerAddPoint(x,0,z,"point triggered")
			--Spring.MarkerAddPoint(cx*UHM_WIDTH,0,cz*UHM_HEIGHT,"To update")
		end
	--end
end

local function Shutdown()
	gl.DeleteTextureFBO(tempTex)
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
	gadgetHandler.RemoveSyncAction("Shutdown")
end


function gadget:Initialize()
	
	gadgetHandler:AddSyncAction("changeBlockList", changeBlockList)
	gadgetHandler:AddSyncAction("Shutdown", Shutdown)
	
	--for i = 1, 7 do
	--	for j = 1, 7 do
	--		Spring.MarkerAddPoint(i*UHM_WIDTH,0,j*UHM_HEIGHT)
	--	end
	--end
	
	tempTex = glCreateTexture(SQUARE_SIZE, SQUARE_SIZE, {
		wrap_s = GL.CLAMP_TO_EDGE, 
		wrap_t = GL.CLAMP_TO_EDGE,
		fbo = true,
	})
end

end