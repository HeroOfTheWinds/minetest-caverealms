-- caverealms 0.1.0 by HeroOfTheWinds
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

-- Parameters

local YMIN = -33000 -- Approximate realm limits.
local YMAX = -700
local XMIN = -33000
local XMAX = 33000
local ZMIN = -33000
local ZMAX = 33000

local CHUINT = 2 -- Chunk interval for cave realms
local WAVAMP = 16 -- Structure wave amplitude
local HISCAL = 32 -- Upper structure vertical scale
local LOSCAL = 32 -- Lower structure vertical scale
local HIEXP = 0.5 -- Upper structure density gradient exponent
local LOEXP = 0.5 -- Lower structure density gradient exponent
local DIRTHR = 0.04 -- Dirt density threshold
local STOTHR = 0.08 -- Stone density threshold
local STABLE = 2 -- Minimum number of stacked stone nodes in column for dirt / sand on top

local STALAG = 0.02 --chance of stalagmites
local STALAC = 0.04 --chance of stalactites
local H_LAG = 15 --max height for stalagmites
local H_LAC = 20 --...stalactites
local CRYSTAL = 0.01 --chance of glow crystal formations
local H_CRY = 6 --max height of glow crystals
local GEMCHA = 0.03 --chance of small glow gems


-- 3D noise for caverns

local np_cave = {
	offset = 0,
	scale = 1,
	spread = {x=512, y=256, z=512},
	seed = 277777979,
	octaves = 6,
	persist = 0.6
}

-- 3D noise for large scale cavern size/density variation

local np_cluster = {
	offset = 0,
	scale = 1,
	spread = {x=2048, y=2048, z=2048},
	seed = 23,
	octaves = 1,
	persist = 0.5
}

-- 2D noise for wave

local np_wave = {
	offset = 0,
	scale = 1,
	spread = {x=256, y=256, z=256},
	seed = -400000000089,
	octaves = 3,
	persist = 0.5
}

-- Stuff

caverealms = {}

-- Nodes

--glowing crystal
minetest.register_node("caverealms:glow_crystal", {
	description = "Glow Crystal",
	tiles = {"caverealms_glow_crystal.png"},
	is_ground_content = true,
	groups = {cracky=3},
	--sounds = "default_break_glass.1.ogg", --broken
	light_source = 13,
	paramtype = "light",
	use_texture_alpha = true,
	drawtype = "glasslike",
	sunlight_propagates = true,
})

--embedded crystal
minetest.register_node("caverealms:glow_ore", {
	description = "Glow Crystal Ore",
	tiles = {"caverealms_glow_ore.png"},
	is_ground_content = true,
	groups = {cracky=2},
	--sounds = "default_break_glass.1.ogg", --broken
	light_source = 10,
	paramtype = "light",
	--use_texture_alpha = true,
	--drawtype = "allfaces_optional",
})

--glowing crystal
minetest.register_node("caverealms:glow_gem", {
	description = "Glow Gem",
	tiles = {"caverealms_glow_gem.png"},
	inventory_image = "caverealms_glow_gem.png",
	wield_image = "caverealms_glow_gem.png",
	is_ground_content = true,
	groups = {cracky=3, oddly_breakable_by_hand=1},
	--sounds = "default_break_glass.1.ogg", --broken
	light_source = 11,
	paramtype = "light",
	drawtype = "plantlike",
	walkable = false,
	buildable_to = true,
	visual_scale = 1.0,
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -5/16, 0.5},
	},
})
--cave dirt_with_grass - bluish?
minetest.register_node("caverealms:dirt_with_grass", {
	description = "Cave Dirt with Grass",
	tiles = {"caverealms_grass.png", "default_dirt.png", "default_dirt.png^caverealms_grass_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,soil=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})
--cave plants

--glowing crystal stalagmite spawner
function caverealms:crystal_stalagmite(x, y, z, area, data)
	--content IDs
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_crystore = minetest.get_content_id("caverealms:glow_ore")
	
	for j = 0, H_CRY do --y
		for k = -2, 2 do --x
			for l = -2, 2 do --z
				if j <= math.ceil(H_CRY / 4) then --base
					if k*k + l*l <= 4 then --make a circle
						local vi = area:index(x+k, y+j, z+l)
						if math.random(3) == 1 then
							data[vi] = c_crystal
						else
							data[vi] = c_crystore
						end
					end
				else --top
					if k >= -1 and k <= 1 then
					if l >= -1 and l <= 1 then 
						if j <= H_CRY - 2 then
							local vi = area:index(x+k, y+j, z+l)
							if math.random(3) <= 2 then
								data[vi] = c_crystal
							else
								data[vi] = c_crystore
							end
						else
							local vi = area:index(x, y+j, z)
							data[vi] = c_crystal
						end
					end
					end
				end
			end
		end
	end
end

-- On generated function

minetest.register_on_generated(function(minp, maxp, seed)
	--only continue if within the bounds for creating cave realms
	if minp.x < XMIN or maxp.x > XMAX
	or minp.y < YMIN or maxp.y > YMAX
	or minp.z < ZMIN or maxp.z > ZMAX then
		return
	end
	
	--determine if there's enough spacing between layers to start a realm
	local chulay = math.floor((minp.y + 32) / 80) -- chunk layer number, 0 = surface chunk
	if math.fmod(chulay, CHUINT) ~= 0 then -- if chulay / CHUINT has a remainder
		return
	end
	
	--easy to reference variables for limits and time
	local t1 = os.clock()
	local x1 = maxp.x
	local y1 = maxp.y
	local z1 = maxp.z
	local x0 = minp.x
	local y0 = minp.y
	local z0 = minp.z
	
	--let people know you're generating a realm
	print ("[caverealms] chunk minp ("..x0.." "..y0.." "..z0..")")
	
	--fire up the LVM
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}
	local data = vm:get_data()
	
	--grab content IDs
	local c_air = minetest.get_content_id("air")
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_gem = minetest.get_content_id("caverealms:glow_gem")
	local c_grass = minetest.get_content_id("caverealms:dirt_with_grass")
	
	--some mandatory values
	local sidelen = x1 - x0 + 1 --usually equals 80
	local chulens = {x=sidelen, y=sidelen, z=sidelen} --position table to pass to get3dMap_flat
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}

	--generate the all important perlin that makes nice terrains
	local nvals_cave = minetest.get_perlin_map(np_cave, chulens):get3dMap_flat(minposxyz)
	local nvals_cluster = minetest.get_perlin_map(np_cluster, chulens):get3dMap_flat(minposxyz)

	local nvals_wave = minetest.get_perlin_map(np_wave, chulens):get2dMap_flat(minposxz)
	
	--more values
	local nixyz = 1 --short for node index xyz
	local nixz = 1 --node index xz
	local stable = {} --stability for ground
	local dirt = {} --table for dirt
	local chumid = y0 + sidelen / 2 --middle of the current chunk
	
	for z = z0, z1 do --for each xy plane progressing northwards
		for x = x0, x1 do 
			local si = x - x0 + 1 --stability index
			dirt[si] = 0 --no dirt here... yet
			local nodename = minetest.get_node({x=x,y=y0-1,z=z}).name --grab the name of the node just below
			if nodename == "air"
			or nodename == "default:water_source"
			or nodename == "default:lava_source" then --if a cave or any kind of lake
				stable[si] = 0 --this is not stable for plants or falling nodes above
			else -- all else including ignore in ungenerated chunks
				stable[si] = STABLE --stuff can safely go above
			end
		end
		for y = y1, y0, -1 do -- for each x row progressing downwards
			local vi = area:index(x0, y, z) --grab the index of the node to edit
			for x = x0, x1 do -- for each node do
				--here's the good part
				local si = x - x0 + 1 --stability index
				local cavemid = chumid + nvals_wave[nixz] * WAVAMP --grab the middle of the cave's amplitude
				local grad
				if y > cavemid then
					grad = ((y - cavemid) / HISCAL) ^ HIEXP --for the ceiling
				else
					grad = ((cavemid - y) / LOSCAL) ^ LOEXP --for the floor
				end
				local density = nvals_cave[nixyz] - grad --how dense is the emptiness?
				if density < 0 and density > -0.7 then -- if cavern "shell"
					data[vi] = c_air --make emptiness
					if y < cavemid and density < STOTHR and stable[si] <= STABLE then
						dirt[si] = dirt[si] + 1
					else
						stable[si] = stable[si] + 1
					end
					
				elseif y < cavemid and dirt[si] >= 1 then -- node above surface
					--place dirt on floor, add plants
					data[vi] = c_grass
					--on random chance, place glow crystal formations
					if math.random() <= CRYSTAL then
						caverealms:crystal_stalagmite(x, y, z, area, data)
					end
					--randomly place glow gems
					if math.random() < GEMCHA then
						local gi = area:index(x,y+1,z)
						data[gi] = c_gem
					end
					dirt[si] = 0
				else -- solid rock
					stable[si] = 0
				end
				nixyz = nixyz + 1 --increment the 3D index
				nixz = nixz + 1 --increment the 2D index
				vi = vi + 1 --increment the area index
			end
			nixz = nixz - 80 --shift the 2D index down a layer
		end
		nixz = nixz + 80 --shift the 2D index up a layer
	end
	
	--write these changes to the world
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long this took
	print ("[caverealms] "..chugent.." ms") --tell people how long it took
end)