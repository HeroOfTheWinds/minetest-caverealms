-- caverealms 0.2 by HeroOfTheWinds
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

local STAGCHA = 0.002 --chance of stalagmites
local STALCHA = 0.003 --chance of stalactites
local H_LAG = 15 --max height for stalagmites
local H_LAC = 20 --...stalactites
local CRYSTAL = 0.007 --chance of glow crystal formations
local H_CRY = 9 --max height of glow crystals
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
	sounds = default.node_sound_glass_defaults(),
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
	sounds = default.node_sound_glass_defaults(),
	light_source = 10,
	paramtype = "light",
})

--glowing crystal
minetest.register_node("caverealms:glow_gem", {
	description = "Glow Gem",
	tiles = {"caverealms_glow_gem.png"},
	inventory_image = "caverealms_glow_gem.png",
	wield_image = "caverealms_glow_gem.png",
	is_ground_content = true,
	groups = {cracky=3, oddly_breakable_by_hand=1},
	sounds = default.node_sound_glass_defaults(),
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
--cave mossy cobble - bluish?
minetest.register_node("caverealms:stone_with_moss", {
	description = "Cave Dirt with Grass",
	tiles = {"default_cobble.png^caverealms_moss.png", "default_cobble.png", "default_cobble.png^caverealms_moss_side.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

--cave plants go here


--FUNCTIONS--

--stalagmite spawner
function caverealms:stalagmite(x,y,z, area, data)
	--contest ids
	local c_stone = minetest.get_content_id("default:stone")
	
	local top = math.random(6,H_LAG) --grab a random height for the stalagmite
	for j = 0, top do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j == 0 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				elseif j <= top/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				elseif j <= top/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				else
					local vi = area:index(x, y+j, z-3)
					data[vi] = c_stone
				end
			end
		end
	end
end

--stalactite spawner
function caverealms:stalactite(x,y,z, area, data)
	--contest ids
	local c_stone = minetest.get_content_id("default:stone")--("caverealms:limestone")
	
	local bot = math.random(-H_LAC, -6) --grab a random height for the stalagmite
	for j = bot, 0 do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j >= -1 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				elseif j >= bot/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				elseif j >= bot/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				else
					local vi = area:index(x, y+j, z-3)
					data[vi] = c_stone
				end
			end
		end
	end
end

--glowing crystal stalagmite spawner
function caverealms:crystal_stalagmite(x,y,z, area, data)
	--contest ids
	local c_stone = minetest.get_content_id("default:stone")
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_crystore = minetest.get_content_id("caverealms:glow_ore")
	
	local top = math.random(5,H_CRY) --grab a random height for the stalagmite
	for j = 0, top do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j == 0 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_stone
					end
				elseif j <= top/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_crystore
					end
				elseif j <= top/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = c_crystal
					end
				else
					local vi = area:index(x, y+j, z-3)
					data[vi] = c_crystal
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
	local c_moss = minetest.get_content_id("caverealms:stone_with_moss")
	
	--some mandatory values
	local sidelen = x1 - x0 + 1 --usually equals 80 with default mapgen values. Always a multiple of 16.
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
	local dirt = {} --table for ground surface
	local chumid = y0 + sidelen / 2 --middle of the current chunk
	local roof = {}
	local nixyz2 = 1
	local nixz2 = 1
	local stable2 = {}
	
	for z = z0, z1 do --for each xy plane progressing northwards
		for x = x0, x1 do 
			local si = x - x0 + 1 --stability index
			dirt[si] = 0 --no dirt here... yet
			roof[si] = 0
			local nodename = minetest.get_node({x=x,y=y0-1,z=z}).name --grab the name of the node just below
			if nodename == "air"
			or nodename == "default:water_source"
			or nodename == "default:lava_source" then --if a cave or any kind of lake
				stable[si] = 0 --this is not stable for plants or falling nodes above
				stable2[si] = 0
			else -- all else including ignore in ungenerated chunks
				stable[si] = STABLE --stuff can safely go above
				stable2[si] = STABLE
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
					local nodename = minetest.get_node({x=x,y=y,z=z}).name --grab the name of the node
					data[vi] = c_air --make emptiness
					if density < STOTHR and stable[si] <= STABLE then
						dirt[si] = dirt[si] + 1
					else
						stable[si] = stable[si] + 1
					end
					
				elseif dirt[si] >= 1 then -- node above surface
					--place dirt on floor, add plants
					data[vi] = c_moss
					--on random chance, place glow crystal formations
					if math.random() <= CRYSTAL then
						caverealms:crystal_stalagmite(x, y, z, area, data)
					end
					--randomly place stalagmites
					if math.random() <= STAGCHA then
						caverealms:stalagmite(x, y, z, area, data)
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
			nixz = nixz - sidelen --shift the 2D index down a layer
		end
		nixz = nixz + sidelen --shift the 2D index up a layer
		
		--second loop to obtain ceiling
		for y = y0, y1 do -- for each x row progressing downwards
			local vi = area:index(x0, y, z) --grab the index of the node to edit
			for x = x0, x1 do -- for each node do
				--here's the good part
				local si = x - x0 + 1 --stability index
				local cavemid = chumid + nvals_wave[nixz2] * WAVAMP --grab the middle of the cave's amplitude
				local grad
				if y > cavemid then
					grad = ((y - cavemid) / HISCAL) ^ HIEXP --for the ceiling
				else
					grad = ((cavemid - y) / LOSCAL) ^ LOEXP --for the floor
				end
				local density = nvals_cave[nixyz2] - grad --how dense is the emptiness?
				if density < 0 and density > -0.7 then -- if cavern "shell"
					if density < STOTHR and stable2[si] <= STABLE then
						roof[si] = roof[si] + 1
					else
						stable2[si] = stable2[si] + 1
					end
				
				elseif roof[si] >= 1 then --and stable2[si] >= 2 then -- node above surface
					if math.random() <= STALCHA then
						local ai = area:index(x,y+1,z)
						if data[ai] ~= c_air then
							caverealms:stalactite(x, y, z, area, data)
						end
					end
					roof[si] = 0
				else -- solid rock
					stable2[si] = 0
				end
				nixyz2 = nixyz2 + 1 --increment the 3D index
				nixz2 = nixz2 + 1 --increment the 2D index
				vi = vi + 1 --increment the area index
			end
			nixz2 = nixz2 - sidelen
		end
		nixz2 = nixz2 + sidelen
	end
	
	
	--write these changes to the world
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long this took
	print ("[caverealms] "..chugent.." ms") --tell people how long it took
end)