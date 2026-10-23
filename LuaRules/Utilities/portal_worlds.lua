-- This file is part of the Spring engine (GPL v2 or later), see LICENSE.html
-- Shared geometry and graph operations. Map composition owns all coordinates.
local config = "mapconfig/portal_worlds.lua"
if not VFS.FileExists(config, VFS.MAP) then
	return nil
end
local world = VFS.Include(config, nil, VFS.MAP)
assert(world.schema == 1, "Unsupported portal map metadata schema")
assert(#world.regions > 0 and #world.profiles == #world.regions, "Portal regions require visual profiles")
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
-- Use the physical rectangles for crater safety rather than trusting the
-- manifest's nominal packing gap. Also reject touching/overlapping regions.
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
for _, edge in ipairs(world.connections) do
	assert(
		world.regions[edge[1]] and world.regions[edge[2]] and edge[1] ~= edge[2],
		"Invalid portal connection"
	)
end

-- Give flying objects room to turn or overshoot without exposing another world.
-- Half the separating distance on the widest axis keeps even diagonal envelopes
-- disjoint. Single-region maps use one sixteenth of their shorter side.
world.objectBounds = {}
for i, r in ipairs(world.regions) do
	local margin = math.min(r.width, r.height) / 16
	for j, other in ipairs(world.regions) do
		if i ~= j then
			local dx = math.max(0, r.x0 - other.x1, other.x0 - r.x1)
			local dz = math.max(0, r.z0 - other.z1, other.z0 - r.z1)
			margin = math.min(margin, math.max(dx, dz) / 2)
		end
	end
	-- Older preview engines retain their original strict-edge behavior.
	if not (Engine and Engine.FeatureSupport and Engine.FeatureSupport.objectDrawBounds) then
		margin = 0
	end
	world.objectBounds[i] = { x0 = r.x0 - margin, z0 = r.z0 - margin,
		x1 = r.x1 + margin, z1 = r.z1 + margin, margin = margin }
end
function world.ContainsObject(region, x, z)
	local r = world.objectBounds[region]
	return r ~= nil and x ~= nil and z ~= nil
		and x >= r.x0 and x < r.x1 and z >= r.z0 and z < r.z1
end

-- Presentation-only lookup; simulation provenance still uses Region/home.
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
	for _, entry in ipairs(world.teams) do
		if entry.team == team then
			return entry.region
		end
	end
end
function world.Other(edge, region)
	if edge[1] == region then
		return edge[2]
	end
	if edge[2] == region then
		return edge[1]
	end
end
-- Return the first edge of a shortest open route, plus its next region.
function world.Route(source, destination, isOpen)
	if source == destination then
		return
	end
	local queue, seen = { { source } }, { [source] = true }
	local cursor = 1
	while queue[cursor] do
		local step = queue[cursor]
		cursor = cursor + 1
		for i, edge in ipairs(world.connections) do
			local nextRegion = world.Other(edge, step[1])
			if nextRegion and not seen[nextRegion] and isOpen(i) then
				local firstEdge, firstRegion = step[2] or i, step[3] or nextRegion
				if nextRegion == destination then
					return firstEdge, firstRegion
				end
				seen[nextRegion] = true
				queue[#queue + 1] = { nextRegion, firstEdge, firstRegion }
			end
		end
	end
end
return world
