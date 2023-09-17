function gadget:GetInfo()
	return {
		name    = "Unit tint API",
		desc    = "API for modders to tint units (kinda like in say WC3)",
		author  = "trepan (xray shader), Sprung (api)",
		license = "GNU GPL, v2 or later (xray), Public Domain (api)",
		date    = "2023-09-17",
		layer   = 0,
		enabled = true,
	}
end

local TINT_MAGIC = 'unit_tint'
if gadgetHandler:IsSyncedCode() then
	function GG.TintUnit(unitID, r_or_table, g, b, a)
		if not r_or_table then
			SendToUnsynced(TINT_MAGIC, unitID)
		elseif type(r_or_table) == 'table' then
			SendToUnsynced(TINT_MAGIC, unitID, r_or_table[1], r_or_table[2], r_or_table[3], r_or_table[4])
		else
			SendToUnsynced(TINT_MAGIC, unitID, r_or_table, g, b, a)
		end
	end

	return
end


local gl = gl
local glColor = gl.Color
local glUseShader = gl.UseShader
local glDepthTest = gl.DepthTest
local glPolygonOffset = gl.PolygonOffset

local shader
local tintedUnits = {}

function TintUnit(unitID, r_or_table, g, b, a)
	if not r_or_table then
		tintedUnits[unitID] = nil
	elseif type(r_or_table) == 'table' then
		tintedUnits[unitID] = r_or_table
	else
		tintedUnits[unitID] = {r_or_table, g, b, a}
	end
end

function gadget:UnitDestroyed(unitID)
	tintedUnits[unitID] = nil
end

function gadget:RecvFromSynced(magic, unitID, r, g, b, a)
	if magic ~= TINT_MAGIC then
		return
	end

	if r then
		tintedUnits[unitID] = {r, g, b, a}
	else
		tintedUnits[unitID] = nil
	end
end

function gadget:Initialize()

	if not gl.CreateShader then
		Spring.Log("Tint API (unit_tint.lua)", LOG.ERROR, "Potato with no shaders, exiting")
		GG.TintUnit = function() end
		gadgetHandler:RemoveGadget()
		return
	end

	shader = gl.CreateShader({
		vertex = [[
			varying vec3 normal;
			varying vec3 eyeVec;
			varying vec4 color;
			uniform mat4 camera;
			uniform mat4 caminv;

			void main() {
				vec4 P = gl_ModelViewMatrix * gl_Vertex;
				eyeVec = P.xyz;
				normal  = gl_NormalMatrix * gl_Normal;
				color = gl_Color.rgba;
				gl_Position = gl_ProjectionMatrix * P;
			}
		]],

		fragment = [[
			varying vec3 normal;
			varying vec3 eyeVec;
			varying vec4 color;

			void main() {
				float opac = dot(normalize(normal), normalize(eyeVec));
				opac = 1.0 - abs(opac);
				gl_FragColor.rgba = color;
				gl_FragColor.a = gl_FragColor.a * opac;
			}
		]],
	})

	if not shader then
		Spring.Log("Tint API (unit_tint.lua)", LOG.ERROR, "Xray shader compilation failed", gl.GetShaderLog())
		GG.TintUnit = function() end
		gadgetHandler:RemoveGadget()
		return
	end

	GG.TintUnit = TintUnit
end

local function DrawWorldFunc()
	gl.Color(1, 1, 1, 1)
	gl.UseShader(shader)
	gl.DepthTest(true)
	gl.PolygonOffset(-2, -2)

	for unitID, colour in pairs(tintedUnits) do
		gl.Color(colour[1], colour[2], colour[3], colour[4] or 1)
		gl.Unit(unitID, true)
	end

	gl.PolygonOffset(false)
	gl.DepthTest(false)
	gl.UseShader(0)
	gl.Color(1, 1, 1, 1)
end

-- FIXME: optimize to only run if something is actually tinted!
function gadget:DrawWorld()
	DrawWorldFunc()
end

function gadget:DrawWorldRefraction()
	DrawWorldFunc()
end

local tintUnitDefIDs = {}
for i = 1, #UnitDefs do
	local tint = UnitDefs[i].customParams.model_tint
	if tint then
		local rs, gs, bs, as = tint:match("(%S+)%s*(%S+)%s*(%S+)%s*(%S*)")
		local r, g, b, a = tonumber(rs), tonumber(gs), tonumber(bs), tonumber(as)
		if r and g and b then
			tintUnitDefIDs[i] = {r, g, b, a}
		end
	end
end

if next(tintUnitDefIDs) then
	function gadget:UnitCreated(unitID, unitDefID)
		local tint = tintUnitDefIDs[unitDefID]
		if not tint then
			return
		end

		TintUnit(unitID, tint)
	end
end
