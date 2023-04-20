function gadget:GetInfo()
	return {
		name      = "Map Lava Gadget 2.4",
		desc      = "lava",
		author    = "knorke, Beherith, The_Yak, Anarchid, Kloot, Gajop, ivand, Damgam, GoogleFrog",
		date      = "Feb 2011, Nov 2013, 2022!",
		license   = "Lua: GNU GPL, v2 or later, GLSL: (c) Beherith (mysterme@gmail.com)",
		layer     = -3,
		enabled   = true
	}
end

local MAPSIDE_LAVACONF = "mapconfig/lava_config.lua"
local GAMESIDE_LAVACONF = "LuaRules/Configs/LavaConf/" .. (Game.mapName or "") .. ".lua"

local WATER_DAMAGE_WEAPONDEFID = -5
local FRAME_LENGTH = 1/30
local isHoverCache = {}

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Loading

local function ColorToVecStr(color)
	return "vec3(" .. math.floor(color[1]*10000)/10000 .. ", " .. math.floor(color[2]*10000)/10000 .. ", " .. math.floor(color[3]*10000)/10000 .. ")"
end

local function ProcessLavalConf(lavaDef)
	if not lavaDef then
		return false
	end
	lavaDef.diffuseEmitTex = lavaDef.diffuseEmitTex or "LuaRules/Images/lava/lavaDiffuse.dds"
	lavaDef.normalHeightTex = lavaDef.normalHeightTex or "LuaUI/images/lava/lavaNormal.dds"

	-- TODO, add these
	lavaDef.doBursts = (lavaDef.doBursts ~= false)
	lavaDef.burstCeg = lavaDef.burstCeg or "lavaburst_generic"
	lavaDef.burstPeriod = lavaDef.burstPeriod or 0.2
	lavaDef.damageCeg = lavaDef.damageCeg or false
	lavaDef.burstSoundList = lavaDef.burstSoundList or false -- List of sounds, picked at random when a burst occurs
	lavaDef.backgroundSound = lavaDef.backgroundSound or false

	lavaDef.level = lavaDef.level or 1 -- pre-game lava level
	lavaDef.grow = lavaDef.grow or 0.25 -- initial lavaGrow speed
	lavaDef.damage = lavaDef.damage or 100 -- damage per second
	lavaDef.terraformRequired = (lavaDef.terraformRequired ~= false) and (lavaDef.level ~= 1) -- Terraform so that the water is at the desired water level.
	local realLevel = (lavaDef.terraformRequired and 1) or lavaDef.level
	
	lavaDef.uVscale = lavaDef.uVscale or 3.0 -- How many times to tile the lava texture across the entire map
	lavaDef.colorCorrection = lavaDef.colorCorrection or {1.0, 1.0, 1.0} -- final colorcorrection on all lava + shore coloring
	lavaDef.planeLightMult = lavaDef.planeLightMult or 4 -- Multiplier for the brightness of the lava plane.
	lavaDef.outsideMapInLos = lavaDef.outsideMapInLos or false
	
	lavaDef.lOSdarkness = lavaDef.lOSdarkness or 0.5 -- how much to darken the out-of-los areas of the lava plane
	lavaDef.swirlFreq = lavaDef.swirlFreq or 0.025 -- How fast the main lava texture swirls around default 0.025
	lavaDef.swirlAmp = lavaDef.swirlAmp or 0.003 -- How much the main lava texture is swirled around default 0.003
	lavaDef.specularExp = lavaDef.specularExp or 64.0 -- the specular exponent of the lava plane
	lavaDef.shadowStrength = lavaDef.shadowStrength or 0.4 -- how much light a shadowed fragment can recieve
	lavaDef.coastWidth = lavaDef.coastWidth or 20.0 -- how wide the coast of the lava should be
	lavaDef.coastColor = lavaDef.coastColor or {2.0, 0.5, 0.0} -- the color of the lava coast
	lavaDef.coastLightBoost = lavaDef.coastLightBoost or 0.4 -- Exponent for brightness of cost
	lavaDef.coastLightMult = lavaDef.coastLightMult or 1 -- Multiplier for brightness of cost

	lavaDef.parallaxDepth = lavaDef.parallaxDepth or 16.0 -- set to >0 to enable, how deep the parallax effect is
	lavaDef.parallaxOffset = lavaDef.parallaxOffset or 0.5 -- center of the parallax plane, from 0.0 (up) to 1.0 (down)

	lavaDef.fogColor = lavaDef.fogColor or {2.0, 0.5, 0.0} -- the color of the fog light
	lavaDef.fogFactor = lavaDef.fogFactor or 0.06 -- how dense the fog is
	lavaDef.fogHeight = lavaDef.fogHeight or 15 -- how high the fog is above the lava plane
	lavaDef.fogAbove = lavaDef.fogAbove or 1.0 -- the multiplier for how much fog should be above lava fragments, ~0.2 means the lava itself gets hardly any fog, while 2.0 would mean the lava gets a lot of extra fog
	lavaDef.fogEnabled = (lavaDef.fogEnabled ~= false) --if fog above lava adds light / is enabled
	lavaDef.fogDistortion = lavaDef.fogDistortion or 4.0 -- lower numbers are higher distortion amounts

	lavaDef.tideamplitude = lavaDef.tideamplitude or 2 -- how much lava should rise up-down on static level
	lavaDef.tideperiod = lavaDef.tideperiod or 200 -- how much time between live rise up-down
	
	lavaDef.tideRhym = lavaDef.tideRhym or {{target = realLevel - 1, speed = 0.3, period = 5*6000}} -- overlapping set of tide rythms. Each entry is a list {level = X, speed = Y, remainTime = Z}
	
	-- End config, start post-processing
	if lavaDef.barCompat then
		if lavaDef.uVscale < 3 then
			lavaDef.uVscale = lavaDef.uVscale*1.5
		end
	else
		-- Don't make mappers write "vec3"
		lavaDef.colorCorrection = ColorToVecStr(lavaDef.colorCorrection)
		lavaDef.coastColor = ColorToVecStr(lavaDef.coastColor)
		lavaDef.fogColor = ColorToVecStr(lavaDef.fogColor)
	end
	
	lavaDef.burstFrequency = 1 / lavaDef.burstPeriod
	for i = 1, #lavaDef.tideRhym do
		lavaDef.tideRhym[i].target = lavaDef.tideRhym[i].target or (realLevel - 1)
	end
	return lavaDef
end

local function LoadLavaConf()
	local gameConfig = VFS.FileExists(GAMESIDE_LAVACONF) and VFS.Include(GAMESIDE_LAVACONF) or false
	local mapConfig = VFS.FileExists(MAPSIDE_LAVACONF) and VFS.Include(MAPSIDE_LAVACONF) or false
	return ProcessLavalConf(gameConfig or mapConfig)
end

local lavaDef = LoadLavaConf()
if not lavaDef then
	return
end

-----------------------------------------------------------------------------------------
if gadgetHandler:IsSyncedCode() then -- SYNCED
-----------------------------------------------------------------------------------------

local lavaLevel = 1
local lavaGrow = 0
local burstProgress = 0
local tideIndex = 1
local tideContinueFrame = 0
local currentFrame = 0

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Helpers

local function clamp(low, x, high)
	return math.min(math.max(x, low), high)
end

local function IsHover(unitDefID)
	-- Accessing UnitDefs is very slow
	if not isHoverCache[unitDefID] then
		local unitDef = UnitDefs[unitDefID]
		local moveDef = unitDef.moveDef
		isHoverCache[unitDefID] = (moveDef ~= nil and moveDef.family == "hover") and 1 or 0
	end
	return (isHoverCache[unitDefID] == 1)
end

local function LavaSoundUpdate(f)
	if f % 5 == 0 then
		for i = 1,10 do
			local x = math.random(1, Game.mapX*512)
			local z = math.random(1, Game.mapY*512)
			local y = Spring.GetGroundHeight(x, z)
			if math.random(1,3) == 1 and y < lavaLevel then
				local r = math.random(1,5)
				if r == 1 then
					Spring.PlaySoundFile("lavabubbleshort1", math.random(25,65)/100, x, y, z, 'sfx')
				elseif r == 2 then
					Spring.PlaySoundFile("lavabubbleshort2", math.random(25,65)/100, x, y, z, 'sfx')
				elseif r == 3 then
					Spring.PlaySoundFile("lavarumbleshort1", math.random(20,40)/100, x, y, z, 'sfx')
				elseif r == 4 then
					Spring.PlaySoundFile("lavarumbleshort2", math.random(20,40)/100, x, y, z, 'sfx')
				elseif r == 5 then
					Spring.PlaySoundFile("lavarumbleshort3", math.random(20,40)/100, x, y, z, 'sfx')
				end
				break
			end
		end
	end
end

local function LavaBurstUpdate(lavaDef)
	burstProgress = burstProgress + FRAME_LENGTH * lavaDef.burstFrequency * (0.9 + (math.random() * 0.2))
	if burstProgress < 1 then
		return
	end
	burstProgress = burstProgress - 1
	local x = math.random() * Game.mapX * 512
	local z = math.random() * Game.mapY * 512
	local y = Spring.GetGroundHeight(x,z)
	if y < lavaLevel then
		--This should be in config file to customize effects on lava plane
		Spring.SpawnCEG(lavaDef.burstCeg, x, lavaLevel+5, z)
		if lavaDef.burstSound then
			local r = math.random(1, #lavaDef.burstSoundList)
			if lavaDef.burstSoundList[r] then
				Spring.PlaySoundFile(lavaDef.burstSoundList[r], math.random(80,100)/100, x, y, z, 'sfx')
			end
		end
	end
end

function UpdateLava()
	if not (lavaDef.tideRhym and #lavaDef.tideRhym > 0) then
		return
	end
	if (lavaGrow < 0 and lavaLevel < lavaDef.tideRhym[tideIndex].target)
		or (lavaGrow > 0 and lavaLevel > lavaDef.tideRhym[tideIndex].target) then
		tideContinueFrame = currentFrame + lavaDef.tideRhym[tideIndex].period*30
		lavaGrow = 0
		--Spring.Echo ("Next LAVA LEVEL change in " .. (tideContinueFrame-currentFrame)/30 .. " seconds")
	end

	if currentFrame == tideContinueFrame then
		tideIndex = tideIndex + 1
		if tideIndex > table.getn(lavaDef.tideRhym) then
			tideIndex = 1
		end
		--Spring.Echo ("tideIndex=" .. tideIndex .. " target=" ..lavaDef.tideRhym[tideIndex].target )
		if lavaLevel < lavaDef.tideRhym[tideIndex].target then
			lavaGrow = lavaDef.tideRhym[tideIndex].speed
		else
			lavaGrow = -lavaDef.tideRhym[tideIndex].speed
		end
	end
	_G.lavaGrow = lavaGrow
end

local function lavaDeathCheck()
	local all_units = Spring.GetAllUnits()
	for i in pairs(all_units) do
		local UnitDefID = Spring.GetUnitDefID(all_units[i])
		if not UnitDefs[UnitDefID].canFly then
			local x, y, z = Spring.GetUnitBasePosition(all_units[i])
			if y ~= nil then
				if y and y < lavaLevel then
					--This should be in config file to change damage + effects/cegs
					-- local health, maxhealth = Spring.GetUnitHealth(all_units[i])
					-- Spring.AddUnitDamage (all_units[i], health - maxhealth*0.033, 0, Spring.GetGaiaTeamID(), 1)
					Spring.AddUnitDamage (all_units[i], lavaDef.damage/3, 0, Spring.GetGaiaTeamID(), 1)
					--Spring.DestroyUnit (all_units[i], true, false, Spring.GetGaiaTeamID())
					
					if lavaDef.damageCeg then
						Spring.SpawnCEG(lavaDef.damageCeg, x, y+5, z)
					end
				end
			end
		end
	end
	-- Below is custom reclaim/damage module for wrecks/features
	-- local all_features = Spring.GetAllFeatures()
	-- for i in pairs(all_features) do
	-- 	local FeatureDefID = Spring.GetFeatureDefID(all_features[i])
	-- 	if not FeatureDefs[FeatureDefID].geoThermal then
	-- 		x,y,z = Spring.GetFeaturePosition(all_features[i])
	-- 		if (y ~= nil) then
	-- 			if (y and y < lavaLevel) then
	-- 				local reclaimLeft = select(5, Spring.GetFeatureResources (all_features[i]))
	-- 				if reclaimLeft <= 0 then
	-- 					Spring.DestroyFeature(all_features[i])
	-- 					Spring.SpawnCEG("lavadamage", x, y+5, z)
	-- 				else
	-- 					local newReclaimLeft = reclaimLeft - 0.033
	-- 					Spring.SetFeatureReclaim (all_features[i], newReclaimLeft)
	-- 					Spring.SpawnCEG("lavadamage", x, y+5, z)
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end
end


-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Callins

function gadget:GameFrame(f)
	currentFrame = f
	_G.lavaLevel = lavaLevel+math.sin(f/30)*0.5
	_G.frame = f

	if f % 10 == 0 then
		lavaDeathCheck()
	end

	UpdateLava()
	lavaLevel = lavaLevel+lavaGrow
	Spring.SetGameRulesParam("lavaLevel", lavaLevel)

	if lavaDef.doBursts then
		LavaBurstUpdate(lavaDef)
	end
	
	if lavaDef.backgroundSound then
		LavaSoundUpdate(f) -- Why is this in synced? Can synced even play sounds?
	end
end

function gadget:UnitPreDamaged(unitID, unitDefID, unitTeam, damage, paralyzer, weaponDefID, projectileID)
	if weaponDefID ~= WATER_DAMAGE_WEAPONDEFID then
		return damage
	end
	if not IsHover(unitDefID) then
		return damage
	end
	return 0
end

function gadget:Initialize()
	if not lavaDef then
		gadgetHandler:RemoveGadget(self)
		return
	end
	currentFrame = Spring.GetGameFrame()
	if lavaDef.terraformRequired then
		if not Spring.GetGameRulesParam("lavaRaisedWater") then
			GG.Terraform_RaiseWater(lavaDef.level - 1)
			Spring.SetGameRulesParam("lavaRaisedWater", lavaDef.level - 1)
		end
		lavaLevel = 1
	else
		lavaLevel = lavaDef.level
	end
	lavaGrow = lavaDef.grow
	_G.frame = 0
	_G.lavaLevel = lavaLevel
	_G.lavaGrow = lavaGrow
	Spring.SetGameRulesParam("lavaLevel", -99999)
end

-----------------------------------------------------------------------------------------
else  -- UNSYCNED
-----------------------------------------------------------------------------------------

local texturesamplingmode = '' -- ':l:' causes MASSIVE load on zoom out and downsampling textures!
local lavaDiffuseEmit = texturesamplingmode .. lavaDef.diffuseEmitTex -- pack emissiveness into alpha channel (this is also used as heat for distortion)
local lavaNormalHeight = texturesamplingmode .. lavaDef.normalHeightTex -- pack height into normals alpha
local lavaDistortion = texturesamplingmode .. "LuaRules/Images/lava/lavaDistort.dds"

local lavaShader
local lavaPlaneVAO

local foglightShader
local foglightVAO
local numfoglightVerts

local foglightenabled = lavaDef.fogEnabled
local fogheightabovelava = lavaDef.fogHeight
local allowDeferredMapRendering =  (Spring.GetConfigInt("AllowDeferredMapRendering") == 1) -- map depth buffer is required for the foglight shader pass

local tideamplitude = lavaDef.tideamplitude
local tideperiod = lavaDef.tideperiod
local lavatidelevel = (lavaDef.terraformRequired and 1) or lavaDef.level 

local heatdistortx = 0
local heatdistortz = 0

local elmosPerSquare = 256 -- The resolution of the lava

local luaShaderDir = "LuaUI/Widgets/Include/"
local LuaShader = VFS.Include(luaShaderDir .. "LuaShader.lua")
VFS.Include(luaShaderDir .. "instancevbotable.lua") -- we are only gonna use the plane maker func of this


local unifiedShaderConfig = {
	-- for lavaplane
	HEIGHTOFFSET = 2.0,  -- how many elmos above the 'actual' lava height we should render, to avoid ROAM clipping artifacts
	COASTWIDTH = lavaDef.coastWidth, -- how wide the coast of the lava should be
	WORLDUVSCALE = lavaDef.uVscale, -- How many times to tile the lava texture across the entire map
	COASTCOLOR = lavaDef.coastColor, -- the color of the lava coast
	SPECULAREXPONENT = lavaDef.specularExp,  -- the specular exponent of the lava plane
	SPECULARSTRENGTH = 1.0, -- The peak brightness of specular highlights
	BRIGHTNESS = lavaDef.planeLightMult, -- Diffuse multiplier??
	LOSDARKNESS = lavaDef.lOSdarkness, -- how much to darken the out-of-los areas of the lava plane
	SHADOWSTRENGTH = lavaDef.shadowStrength, -- how much light a shadowed fragment can recieve
	OUTOFMAPHEIGHT = -100, -- what value to use when we are sampling the heightmap outside of the true bounds
	SWIRLFREQUENCY = lavaDef.swirlFreq, -- How fast the main lava texture swirls around default 0.025
	SWIRLAMPLITUDE = lavaDef.swirlAmp, -- How much the main lava texture is swirled around default 0.003
	PARALLAXDEPTH = lavaDef.parallaxDepth, -- set to >0 to enable
	PARALLAXOFFSET = lavaDef.parallaxOffset, -- center of the parallax plane, from 0.0 (up) to 1.0 (down)
	GLOBALROTATEFREQUENCY = 0.0001, -- how fast the whole lava plane shifts around
	GLOBALROTATEAMPLIDUE = 0.05, -- how big the radius of the circle we rotate around is
	OUTSIDE_MAP_LOS_STATE = (lavaDef.outsideMapInLos and 1 or 0),

	-- for foglight:
	FOGHEIGHTABOVELAVA = lavaDef.fogHeight, -- how much higher above the lava the fog light plane is
	FOGCOLOR = lavaDef.fogColor, -- the color of the fog light
	FOGFACTOR = lavaDef.fogFactor, -- how dense the fog is
	EXTRALIGHTCOAST = lavaDef.coastLightBoost, -- how much extra brightness should coastal areas get
	COASTLIGHTMULT = lavaDef.coastLightMult, -- how much extra brightness should coastal areas get
	FOGLIGHTDISTORTION = lavaDef.fogDistortion, -- lower numbers are higher distortion amounts
	FOGABOVELAVA = lavaDef.fogAbove, -- the multiplier for how much fog should be above lava fragments, ~0.2 means the lava itself gets hardly any fog, while 2.0 would mean the lava gets a lot of extra fog

	-- for both:
	SWIZZLECOLORS = 'fragColor.rgb = (fragColor.rgb * '..lavaDef.colorCorrection..').rgb;', -- yes you can swap around and weight color channels, right after final color, default is 'rgb'
}


local lavaVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#line 10000
layout (location = 0) in vec2 planePos;

uniform float lavaHeight;

out DataVS {
	vec4 worldPos;
	vec4 worldUV;
	float inboundsness;
	vec4 randpervertex;
};
//__DEFINES__
//__ENGINEUNIFORMBUFFERDEFS__

#line 11000

vec2 inverseMapSize = 1.0 / mapSize.xy;

float rand(vec2 co){ // a pretty crappy random function
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
	// mapSize.xy is the actual map size,
	//place the vertices into the world:
	worldPos.y = lavaHeight;
	worldPos.w = 1.0;
	worldPos.xz =  (1.5 * planePos +0.5) * mapSize.xy;

	// pass the world-space UVs out
	float mapratio = mapSize.y / mapSize.x;
	worldUV.xy = (1.5 * planePos +0.5);
	worldUV.y *= mapratio;

	float gametime = (timeInfo.x + timeInfo.w) * SWIRLFREQUENCY;

	randpervertex = vec4(rand(worldPos.xz), rand(worldPos.xz * vec2(17.876234, 9.283)), rand(worldPos.xz + gametime + 2.0), rand(worldPos.xz + gametime + 3.0));
	worldUV.zw = sin(randpervertex.xy + gametime * (0.5 + randpervertex.xy));

	// global rotatemove, has 2 params, globalrotateamplitude, globalrotatefrequency
	// Spin the whole texture around slowly
	float worldRotTime = (timeInfo.x + timeInfo.w) ;
	worldUV.xy += vec2( sin(worldRotTime * GLOBALROTATEFREQUENCY), cos(worldRotTime * GLOBALROTATEFREQUENCY)) * GLOBALROTATEAMPLIDUE;

	// -- MAP OUT OF BOUNDS
	vec2 mymin = min(worldPos.xz, mapSize.xy  - worldPos.xz) * inverseMapSize;
	inboundsness = min(mymin.x, mymin.y);

	// Assign world position:
	gl_Position = cameraViewProj * worldPos;
}
]]

local lavaFSSrc =  [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 20000

uniform float lavaHeight;
uniform float heatdistortx;
uniform float heatdistortz;

uniform sampler2D heightmapTex;
uniform sampler2D lavaDiffuseEmit;
uniform sampler2D lavaNormalHeight;
uniform sampler2D lavaDistortion;
uniform sampler2DShadow shadowTex;
uniform sampler2D infoTex;

in DataVS {
	vec4 worldPos;
	vec4 worldUV;
	float inboundsness;
	vec4 randpervertex;
};

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

vec2 inverseMapSize = 1.0 / mapSize.xy;

float heightAtWorldPos(vec2 w){
	// Some texel magic to make the heightmap tex perfectly align:
	const vec2 heightmaptexel = vec2(8.0, 8.0);
	w +=  vec2(-8.0, -8.0) * (w * inverseMapSize) + vec2(4.0, 4.0) ;

	vec2 uvhm = clamp(w, heightmaptexel, mapSize.xy - heightmaptexel);
	uvhm = uvhm	* inverseMapSize;

	return texture(heightmapTex, uvhm, 0.0).x;
}

out vec4 fragColor;

#line 22000


void main() {

	vec4 camPos = cameraViewInv[3];
	vec3 worldtocam = camPos.xyz - worldPos.xyz;

	// Sample emissive as heat indicator here for later displacement
	vec4 nodiffuseEmit =  texture(lavaDiffuseEmit, worldUV.xy * WORLDUVSCALE );

	vec2 rotatearoundvertices = worldUV.zw * SWIRLAMPLITUDE;

	float localheight = OUTOFMAPHEIGHT ;
	if (inboundsness > 0)
		localheight = heightAtWorldPos(worldPos.xz);

	if (localheight > lavaHeight - HEIGHTOFFSET ) discard;

	// Calculate how far the fragment is from the coast
	float coastfactor = clamp((localheight-lavaHeight + COASTWIDTH + HEIGHTOFFSET) * (1.0 / COASTWIDTH),  0.0, 1.0);

	// this is ramp function that ramps up for 90% of the coast, then ramps down at the last 10% of coastwidth
	if (coastfactor > 0.90)
	{coastfactor = 9*( 1.0 - coastfactor);
		coastfactor = pow(coastfactor/0.9, 1.0);
	}else{
		coastfactor = pow(coastfactor/0.9, 3.0);
	}

	// Sample shadow map for shadow factor:
	vec4 shadowVertexPos = shadowView * vec4(worldPos.xyz,1.0);
	shadowVertexPos.xy += vec2(0.5);
	float shadow = clamp(textureProj(shadowTex, shadowVertexPos), 0.0, 1.0);

	// Sample LOS texture for LOS, and scale it into a sane range
	vec2 losUV = clamp(worldPos.xz, vec2(0.0), mapSize.xy ) / mapSize.zw;
	float losTexSample = dot(vec3(0.33), texture(infoTex, losUV).rgb) ; // lostex is PO2
	if (inboundsness < 0.0) losTexSample = OUTSIDE_MAP_LOS_STATE;
	losTexSample = clamp(losTexSample * 4.0 - 1.0, LOSDARKNESS, 1.0);

	// We shift the distortion texture camera-upwards according to the uniforms that got passed in
	vec2 camshift =  vec2(heatdistortx, heatdistortz) * 0.001;
	vec4 distortionTexture = texture(lavaDistortion, (worldUV.xy + camshift) * 45.2) ;

	vec2 distortion = distortionTexture.xy * 0.2 * 0.02;
	distortion.xy *= clamp(nodiffuseEmit.a * 0.5 + coastfactor, 0.2, 2.0);

	vec2 diffuseNormalUVs =  worldUV.xy * WORLDUVSCALE + distortion.xy + rotatearoundvertices;
	vec4 normalHeight =  texture(lavaNormalHeight, diffuseNormalUVs);

	// Perform optional parallax mapping
	#if (PARALLAXDEPTH > 0 )
		vec3 viewvec = normalize(worldtocam * -1.0);
		float pdepth = PARALLAXDEPTH * (PARALLAXOFFSET - normalHeight.a ) * (1.0 - coastfactor);
		diffuseNormalUVs += pdepth * viewvec.xz * 0.002;
		normalHeight =  texture(lavaNormalHeight, diffuseNormalUVs);
	#endif

	vec4 diffuseEmit =   texture(lavaDiffuseEmit , diffuseNormalUVs);

	fragColor.rgba = diffuseEmit;

	// Calculate lighting based on normal map
	vec3 fragNormal = (normalHeight.xzy * 2.0 -1.0);
	fragNormal.z = -1 * fragNormal.z; // for some goddamned reason Z(G) is inverted again
	fragNormal = normalize(fragNormal);
	float lightamount = clamp(dot(sunDir.xyz, fragNormal), 0.2, 1.0) * max(0.5, shadow);
	fragColor.rgb *= lightamount * BRIGHTNESS;

	fragColor.rgb += COASTCOLOR * coastfactor * losTexSample;

	// Specular Color
	vec3 reflvect = reflect(normalize(-1.0 * sunDir.xyz), normalize(fragNormal));
	float specular = clamp(pow(dot(normalize(worldtocam), normalize(reflvect)), SPECULAREXPONENT), 0.0, SPECULARSTRENGTH) * shadow;
	fragColor.rgb += fragColor.rgb * specular;

	fragColor.rgb += fragColor.rgb * (diffuseEmit.a * distortion.y * 700.0);

	fragColor.rgb *= losTexSample;

	// some debugging stuff:
	//fragColor.rgb = fragNormal.xzy;
	//fragColor.rgb = vec3(losTexSample);
	//fragColor.rgb = vec3(shadow);
	//fragColor.rgb = distortionTexture.rgb ;
	//fragColor.rg = worldUV.zw  ;
	//fragColor.rgba *= vec4(fract(hmap*0.05));
	//fragColor.rgb = vec3(randpervertex.w * 0.5 + 0.5);
	//fragColor.rgb = fract(4*vec3(coastfactor));
	fragColor.a = 1.0;
	fragColor.a = clamp(  inboundsness * 2.0 +2.0, 0.0, 1.0);
	SWIZZLECOLORS
}
]]


local fogLightVSSrc = [[
#version 420
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shader_storage_buffer_object : require
#extension GL_ARB_shading_language_420pack: require
#line 10000
layout (location = 0) in vec2 planePos;

uniform float lavaHeight;

out DataVS {
	vec4 worldPos;
	vec4 worldUV;
	float inboundsness;
	noperspective vec2 v_screenUV;
};
//__DEFINES__
//__ENGINEUNIFORMBUFFERDEFS__

#line 11000

#define SNORM2NORM(value) (value * 0.5 + 0.5)

vec2 inverseMapSize = 1.0 / mapSize.xy;

float rand(vec2 co){ // a pretty crappy random function
	return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

void main() {
	// mapSize.xy is the actual map size,
	//place the vertices into the world:
	worldPos.y = lavaHeight;
	worldPos.w = 1.0;
	worldPos.xz =  (1.5 * planePos +0.5) * mapSize.xy;

	// pass the world-space UVs out
	float mapratio = mapSize.y / mapSize.x;
	worldUV.xy = (1.5 * planePos +0.5);
	worldUV.y *= mapratio;

	float gametime = (timeInfo.x + timeInfo.w) * 0.006666;

	vec4 randpervertex = vec4(rand(worldPos.xz), rand(worldPos.xz * vec2(17.876234, 9.283)), rand(worldPos.xz + gametime + 2.0), rand(worldPos.xz + gametime + 3.0));
	worldUV.zw = sin(randpervertex.xy + gametime * (0.5 + randpervertex.xy));

	// -- MAP OUT OF BOUNDS
	vec2 mymin = min(worldPos.xz, mapSize.xy  - worldPos.xz) * inverseMapSize;
	inboundsness = min(mymin.x, mymin.y);

	// Assign world position:
	gl_Position = cameraViewProj * worldPos;
	v_screenUV = SNORM2NORM(gl_Position.xy / gl_Position.w);
}
]]

local foglightFSSrc =  [[
#version 330
#extension GL_ARB_uniform_buffer_object : require
#extension GL_ARB_shading_language_420pack: require

#line 20000

uniform float lavaHeight;
uniform float heatdistortx;
uniform float heatdistortz;

uniform sampler2D mapDepths;
uniform sampler2D modelDepths;
uniform sampler2D lavaDistortion;
//uniform sampler2D mapNormals;
//uniform sampler2D modelNormals;

in DataVS {
	vec4 worldPos;
	vec4 worldUV;
	float inboundsness;
	noperspective vec2 v_screenUV;
};

//__ENGINEUNIFORMBUFFERDEFS__
//__DEFINES__

vec2 inverseMapSize = 1.0 / mapSize.xy;

out vec4 fragColor;

#line 22000
void main() {

	vec4 camPos = cameraViewInv[3];

	// We shift the distortion texture camera-upwards according to the uniforms that got passed in
	vec2 camshift =  vec2(heatdistortx, heatdistortz) * 0.01;

	//Get the fragment depth
	// note that WE CANT GO LOWER THAN THE ACTUAL LAVA LEVEL!

	// Sample the depth buffers, and choose whichever is closer to the screen
	float mapdepth = texture(mapDepths, v_screenUV).x;
	float modeldepth = texture(modelDepths, v_screenUV).x;
	mapdepth = min(mapdepth, modeldepth);

	// the W weight factor here is incorrect, as it comes from the depth buffers, and not the fragments own depth.

	// Convert to normalized device coordinates, and calculate inverse view projection
	vec4 mapWorldPos =  vec4(  vec3(v_screenUV.xy * 2.0 - 1.0, mapdepth),  1.0);
	mapWorldPos = cameraViewProjInv * mapWorldPos;
	mapWorldPos.xyz = mapWorldPos.xyz/ mapWorldPos.w; // YAAAY this works!
	float trueFragmentHeight = mapWorldPos.y;

	float fogAboveLava = 1.0;

	// clip mapWorldPos according to true lava height
	if (mapWorldPos.y< lavaHeight - FOGHEIGHTABOVELAVA - HEIGHTOFFSET) {
		// we need to make a vector from cam to fogplane position
		vec3 camtofogplane = mapWorldPos.xyz - camPos.xyz;

		// and scale it to make it
		camtofogplane = FOGHEIGHTABOVELAVA * camtofogplane /abs(camtofogplane.y);
		mapWorldPos.xyz = worldPos.xyz + camtofogplane;
		fogAboveLava = FOGABOVELAVA;
	}

	// Calculate how long the vector from top of foglightplane to lava or world pos actually is
	float actualfogdepth = length(mapWorldPos.xyz - worldPos.xyz) ;
	float fogAmount = 1.0 - exp2(- FOGFACTOR * FOGFACTOR * actualfogdepth  * 0.5);
	fogAmount *= fogAboveLava;

	// sample the distortiontexture according to camera shift and scale it down
	vec4 distortionTexture = texture(lavaDistortion, (worldUV.xy * 22.0  + camshift)) ;
	float fogdistort = (FOGLIGHTDISTORTION + distortionTexture.x + distortionTexture.y)/ FOGLIGHTDISTORTION ;


	// apply some distortion to the fog
	fogAmount *= fogdistort;


	// lets add some extra brigtness near the coasts, by finding the distance of the lavaplane to the coast
	float disttocoast = abs(trueFragmentHeight- (lavaHeight - FOGHEIGHTABOVELAVA - HEIGHTOFFSET));

	float extralightcoast =  clamp(1.0 - disttocoast * (1.0 / COASTWIDTH), 0.0, 1.0);
	extralightcoast = pow(extralightcoast, 3.0) * EXTRALIGHTCOAST * COASTLIGHTMULT;

	fogAmount += extralightcoast;

	fragColor.rgb = FOGCOLOR;
	fragColor.a = fogAmount;

	// fade out the foglightplane if it is far out of bounds
	fragColor.a *= clamp(  inboundsness * 2.0 +2.0, 0.0, 1.0);
	SWIZZLECOLORS
}
]]


local myPlayerID = tostring(Spring.GetMyPlayerID())
function gadget:GameFrame(f)
	if SYNCED.lavaLevel then
		lavatidelevel = math.sin(Spring.GetGameFrame() / tideperiod) * tideamplitude + SYNCED.lavaLevel
	end
	if SYNCED.lavaGrow then
		local lavaGrow = SYNCED.lavaGrow
		if lavaGrow then
			if lavaGrow > 0 and not lavaRisingNotificationPlayed then
				lavaRisingNotificationPlayed = true
				if Script.LuaUI("EventBroadcast") then
					Script.LuaUI.EventBroadcast("SoundEvents LavaRising "..myPlayerID)
				end
			elseif lavaGrow < 0 and not lavaDroppingNotificationPlayed then
				lavaDroppingNotificationPlayed = true
				if Script.LuaUI("EventBroadcast") then
					Script.LuaUI.EventBroadcast("SoundEvents LavaDropping "..myPlayerID)
				end
			elseif lavaGrow == 0 and (lavaRisingNotificationPlayed or lavaDroppingNotificationPlayed) then
				lavaRisingNotificationPlayed = false
				lavaDroppingNotificationPlayed = false
			end
		end
	end
end

function gadget:Initialize()
	--local lavaDef = LoadLavaConf() -- Loaded at the top of unsynced.
	if not lavaDef then
		gadgetHandler:RemoveGadget(self)
		return
	end
	if not gl.CreateShader then -- no shader support, so just remove the widget itself, especially for headless
		gadgetHandler:RemoveGadget()
		return
	end

	Spring.SetDrawWater(false)

	-- Now for all intents and purposes, we kinda need to make a lava plane that is 3x the rez of our map
	-- If, e.g our map size is 16x16, we will have 1024 heightmap. If we make a 128 size vbo, then what?
	-- numverts = 128 * 384 * 384 *2 tris then we will get 280k tris ....
	local xsquares = 3 * Game.mapSizeX / elmosPerSquare
	local zsquares = 3 * Game.mapSizeZ / elmosPerSquare
	local vertexBuffer, vertexBufferSize = makePlaneVBO(1, 1,  xsquares, zsquares)
	local indexBuffer, indexBufferSize = makePlaneIndexVBO(xsquares, zsquares)
	lavaPlaneVAO = gl.GetVAO()
	lavaPlaneVAO:AttachVertexBuffer(vertexBuffer)
	lavaPlaneVAO:AttachIndexBuffer(indexBuffer)


	local engineUniformBufferDefs = LuaShader.GetEngineUniformBufferDefs()
	lavaVSSrc = lavaVSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	lavaFSSrc = lavaFSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)

	lavaShader = LuaShader({
		vertex = lavaVSSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(unifiedShaderConfig)),
		fragment = lavaFSSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(unifiedShaderConfig)),
		uniformInt = {
			heightmapTex = 0,
			lavaDiffuseEmit = 1,
			lavaNormalHeight = 2,
			lavaDistortion = 3,
			shadowTex = 4,
			infoTex = 5,
		},
		uniformFloat = {
			lavaHeight = 1,
			heatdistortx = 1,
			heatdistortz = 1,
		  },
	}, "Lava Shader")


	fogLightVSSrc = fogLightVSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	foglightFSSrc = foglightFSSrc:gsub("//__ENGINEUNIFORMBUFFERDEFS__", engineUniformBufferDefs)
	foglightShader = LuaShader({
		vertex = fogLightVSSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(unifiedShaderConfig)),
		fragment = foglightFSSrc:gsub("//__DEFINES__", LuaShader.CreateShaderDefinesString(unifiedShaderConfig)),
		uniformInt = {
			mapDepths = 0,
			modelDepths = 1,
			lavaDistortion = 2,
		},
		uniformFloat = {
			lavaHeight = 1,
			heatdistortx = 1,
			heatdistortz = 1,
		  },
	}, "FogLight shader ")
	local shaderCompiled = lavaShader:Initialize()
	if not shaderCompiled then
		Spring.Echo("Failed to compile Lava Shader")
		gadgetHandler:RemoveGadget()
		return
	end

	shaderCompiled = foglightShader:Initialize()
	if not shaderCompiled then
		Spring.Echo("Failed to compile foglightShader")
		gadgetHandler:RemoveGadget()
		return
	end
end

function gadget:DrawWorldPreUnit()
	if lavatidelevel then
		local _, gameSpeed, isPaused = Spring.GetGameSpeed()
		if not isPaused then
			local camX, camY, camZ = Spring.GetCameraDirection()
			local camvlength = math.sqrt(camX*camX + camZ *camZ + 0.01)
			local fps = math.max(Spring.GetFPS(), 15)
			heatdistortx = heatdistortx - camX / (camvlength * fps)
			heatdistortz = heatdistortz - camZ / (camvlength * fps)
		end
		--Spring.Echo(camX, camZ, heatdistortx, heatdistortz,gameSpeed, isPaused)

		lavaShader:Activate()
		lavaShader:SetUniform("lavaHeight",lavatidelevel)
		lavaShader:SetUniform("heatdistortx",heatdistortx)
		lavaShader:SetUniform("heatdistortz",heatdistortz)

		gl.Texture(0, "$heightmap")-- Texture file
		gl.Texture(1, lavaDiffuseEmit)-- Texture file
		gl.Texture(2, lavaNormalHeight)-- Texture file
		gl.Texture(3, lavaDistortion)-- Texture file
		gl.Texture(4, "$shadow")-- Texture file
		gl.Texture(5, "$info")-- Texture file

		gl.DepthTest(GL.LEQUAL) -- dont draw fragments below terrain
		gl.DepthMask(true) -- actually write to the depth buffer, because otherwise units below lava will fully render over this

		lavaPlaneVAO:DrawElements(GL.TRIANGLES)
		lavaShader:Deactivate()

		gl.DepthTest(false)
		gl.DepthMask(false)

		gl.Texture(0, false)-- Texture file
		gl.Texture(1, false)-- Texture file
		gl.Texture(2, false)-- Texture file
		gl.Texture(3, false)-- Texture file
		gl.Texture(4, false)-- Texture file
		gl.Texture(5, false)-- Texture file
	end
end

function gadget:DrawWorld()
	if lavatidelevel and foglightenabled and allowDeferredMapRendering then
			--Now to draw the fog light a good 32 elmos above it :)
		foglightShader:Activate()
		foglightShader:SetUniform("lavaHeight",lavatidelevel + fogheightabovelava)
		foglightShader:SetUniform("heatdistortx",heatdistortx)
		foglightShader:SetUniform("heatdistortz",heatdistortz)

		gl.Texture(0, "$map_gbuffer_zvaltex")-- Texture file
		gl.Texture(1, "$model_gbuffer_zvaltex")-- Texture file
		gl.Texture(2, lavaDistortion)-- Texture file

		gl.Blending(GL.SRC_ALPHA, GL.ONE) -- this will additively blend the foglight above everything
		gl.DepthTest(GL.LEQUAL) -- dont draw fragments below the foglightlevel
		gl.DepthMask(false) -- dont write to the depth buffer

		lavaPlaneVAO:DrawElements(GL.TRIANGLES)
		foglightShader:Deactivate()

		gl.DepthTest(false)
		gl.DepthMask(false)

		gl.Texture(0, false)-- Texture file
		gl.Texture(1, false)-- Texture file
		gl.Texture(2, false)-- Texture file

		gl.Blending(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA)
	end
end

function gadget:Shutdown()
	Spring.SetDrawWater(true)
end

-----------------------------------------------------------------------------------------
end -- END UNSYNCED
-----------------------------------------------------------------------------------------
