-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
-- Shared geometry for composed multi-region maps.
local config = "mapconfig/portal_worlds.lua"
if not VFS.FileExists(config, VFS.MAP) then
	return nil
end

local world = VFS.Include(config, nil, VFS.MAP)
assert(world.schema == 1, "Unsupported portal map metadata schema")
assert(#world.regions > 0 and (not world.profiles or #world.profiles == #world.regions), "Invalid portal region definitions")

local DEFAULT_OBJECT_MARGIN = 1024

local identifiers = {}
for _, r in ipairs(world.regions) do
	assert(type(r.id) == "string" and not identifiers[r.id], "Portal region identifiers must be unique")
	identifiers[r.id] = true
	assert(
		r.x0 >= 0
			and r.z0 >= 0
			and r.x1 <= world.size[1]
			and r.z1 <= world.size[2]
			and r.width == r.x1 - r.x0
			and r.height == r.z1 - r.z0
			and r.width > 0
			and r.height > 0,
		"Invalid portal region rectangle"
	)
end

-- Verify physical separation between regions.
world.minimumGap = math.huge
for i, a in ipairs(world.regions) do
	for j = 1, i - 1 do
		local b = world.regions[j]
		local dx = math.max(0, a.x0 - b.x1, b.x0 - a.x1)
		local dz = math.max(0, a.z0 - b.z1, b.z0 - a.z1)
		local gap = math.sqrt(dx * dx + dz * dz)
		assert(gap > 0, "Portal regions must have a separating strip")
		world.minimumGap = math.min(world.minimumGap, gap)
	end
end

-- Give flying objects room to turn or overshoot without exposing another world.
-- Half the separating distance on the widest axis keeps even diagonal envelopes
-- disjoint. Defaults to 1024 elmos unless overridden by the map manifest.
world.objectBounds = {}
for i, r in ipairs(world.regions) do
	local margin = r.margin or world.margin or DEFAULT_OBJECT_MARGIN
	for j, other in ipairs(world.regions) do
		if i ~= j then
			local dx = math.max(0, r.x0 - other.x1, other.x0 - r.x1)
			local dz = math.max(0, r.z0 - other.z1, other.z0 - r.z1)
			margin = math.min(margin, math.max(dx, dz) / 2)
		end
	end
	if not (Engine and Engine.FeatureSupport and Engine.FeatureSupport.objectDrawBounds) then
		margin = 0
	end
	world.objectBounds[i] = {
		x0 = r.x0 - margin,
		z0 = r.z0 - margin,
		x1 = r.x1 + margin,
		z1 = r.z1 + margin,
		margin = margin,
	}
end

function world.ContainsObject(region, x, z)
	local r = world.objectBounds[region]
	return r ~= nil and x ~= nil and z ~= nil
		and x >= r.x0 and x < r.x1 and z >= r.z0 and z < r.z1
end

function world.ObjectRegion(x, z)
	for i in ipairs(world.regions) do
		if world.ContainsObject(i, x, z) then
			return i
		end
	end
end

function world.Region(x, z)
	if not x or not z then
		return
	end
	for i, r in ipairs(world.regions) do
		if x >= r.x0 and x < r.x1 and z >= r.z0 and z < r.z1 then
			return i
		end
	end
end

function world.TeamHome(team)
	for _, entry in ipairs(world.teams or {}) do
		if entry.team == team then
			return entry.region
		end
	end
end

return world
