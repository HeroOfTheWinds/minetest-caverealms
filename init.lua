-- caverealms 0.2.8 by HeroOfTheWinds
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

caverealms = {} --create a container for functions and constants

--grab a shorthand for the filepath of the mod
local modpath = minetest.get_modpath(minetest.get_current_modname())

--load companion lua files
dofile(modpath.."/config.lua") --configuration file; holds various constants
dofile(modpath.."/crafting.lua") --crafting recipes
dofile(modpath.."/falling_ice.lua") --complicated function for falling icicles
dofile(modpath.."/nodes.lua") --node definitions
dofile(modpath.."/functions.lua") --function definitions

-- Parameters (see also config.lua)

local YMIN = caverealms.config.ymin -- Approximate realm limits.
local YMAX = caverealms.config.ymax
local XMIN = -33000
local XMAX = 33000
local ZMIN = -33000
local ZMAX = 33000

local CHUINT = caverealms.config.chuint -- Chunk interval for cave realms
local WAVAMP = 16 -- Structure wave amplitude
local HISCAL = 32 -- Upper structure vertical scale
local LOSCAL = 32 -- Lower structure vertical scale
local HIEXP = 0.5 -- Upper structure density gradient exponent
local LOEXP = 0.5 -- Lower structure density gradient exponent
local DIRTHR = 0.04 -- Dirt density threshold
local STOTHR = 0.08 -- Stone density threshold
local STABLE = 2 -- Minimum number of stacked stone nodes in column for dirt / sand on top

local STAGCHA = caverealms.config.stagcha --0.002 --chance of stalagmites
local STALCHA = caverealms.config.stalcha --0.003 --chance of stalactites
local CRYSTAL = caverealms.config.crystal --0.007 --chance of glow crystal formations
local GEMCHA = caverealms.config.gemcha --0.03 --chance of small glow gems
local MUSHCHA = caverealms.config.mushcha --0.04 --chance of mushrooms
local MYCCHA = caverealms.config.myccha --0.03 --chance of mycena mushrooms
local WORMCHA = caverealms.config.wormcha --0.03 --chance of glow worms
local GIANTCHA = caverealms.config.giantcha --0.001 -- chance of giant mushrooms
local ICICHA = caverealms.config.icicha --0.035 -- chance of icicles

local FALLING_ICICLES = caverealms.config.falling_icicles --true --toggle to turn on or off falling icicles in glaciated biome
local FALLCHA = caverealms.config.fallcha --0.33 --chance of causing the structure to fall



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

-- 2D noise for biome

local np_biome = {
	offset = 0,
	scale = 1,
	spread = {x=250, y=250, z=250},
	seed = 9130,
	octaves = 3,
	persist = 0.5
}

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
	local c_stone = minetest.get_content_id("default:stone")
	local c_water = minetest.get_content_id("default:water_source")
	local c_lava = minetest.get_content_id("default:lava_source")
	local c_ice = minetest.get_content_id("default:ice")
	local c_thinice = minetest.get_content_id("caverealms:thin_ice")
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_gem = minetest.get_content_id("caverealms:glow_gem")
	local c_moss = minetest.get_content_id("caverealms:stone_with_moss")
	local c_lichen = minetest.get_content_id("caverealms:stone_with_lichen")
	local c_algae = minetest.get_content_id("caverealms:stone_with_algae")
	local c_fungus = minetest.get_content_id("caverealms:fungus")
	local c_mycena = minetest.get_content_id("caverealms:mycena")
	local c_worm = minetest.get_content_id("caverealms:glow_worm")	
	local c_iciu = minetest.get_content_id("caverealms:icicle_up")
	local c_icid = minetest.get_content_id("caverealms:icicle_down")	

	--some mandatory values
	local sidelen = x1 - x0 + 1 --usually equals 80 with default mapgen values. Always a multiple of 16.
	local chulens = {x=sidelen, y=sidelen, z=sidelen} --position table to pass to get3dMap_flat
	local minposxyz = {x=x0, y=y0, z=z0}
	local minposxz = {x=x0, y=z0}

	--generate the all important perlin that makes nice terrains
	local nvals_cave = minetest.get_perlin_map(np_cave, chulens):get3dMap_flat(minposxyz) --obviously for caves
	local nvals_cluster = minetest.get_perlin_map(np_cluster, chulens):get3dMap_flat(minposxyz) --how large of clusters of caverns?

	local nvals_wave = minetest.get_perlin_map(np_wave, chulens):get2dMap_flat(minposxz) --wavy structure of cavern ceilings and floors
	local nvals_biome = minetest.get_perlin_map(np_biome, chulens):get2dMap_flat({x=x0+150, y=z0+50}) --2D noise for biomes (will be 3D humidity/temp later)

	--more values
	local nixyz = 1 --short for node index xyz
	local nixz = 1 --node index xz
	local stable = {} --stability for ground
	local dirt = {} --table for ground surface
	local chumid = y0 + sidelen / 2 --middle of the current chunk
	local roof = {}
	local nixyz2 = 1 --second 3d index for incrementation
	local nixz2 = 1 --second 2d index
	local stable2 = {} --second stability table

	for z = z0, z1 do --for each xy plane progressing northwards
		for x = x0, x1 do
			local si = x - x0 + 1 --stability index
			dirt[si] = 0 --no dirt here... yet
			roof[si] = 0
			local nodeid = area:index(x, y0-1, z) --grab the ID of the node just below
			if nodeid == c_air
			or nodeid == c_water
			or nodeid == c_lava then --if a cave or any kind of lake
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
					--local nodename = minetest.get_node({x=x,y=y,z=z}).name --grab the name of the node
					data[vi] = c_air --make emptiness
					if density < STOTHR and stable[si] <= STABLE then
						dirt[si] = dirt[si] + 1
					else
						stable[si] = stable[si] + 1
					end

				elseif dirt[si] >= 1 then -- node above surface
					--determine biome
					local biome = false --preliminary declaration
					n_biome = nvals_biome[nixz] --make an easier reference to the noise
					--compare noise values to determine a biome
					if n_biome >= 0 and n_biome < 0.5 then
						biome = 1 --moss
					elseif n_biome <= -0.5 then
						biome = 2 --fungal
					elseif n_biome >= 0.5 then
						if n_biome >= 0.7 then
							biome = 5 --deep glaciated
						else
							biome = 4 --glaciated
						end
					else
						biome = 3 --algae
					end
					--place floor material, add plants/decorations
					if biome == 1 then
						data[vi] = c_moss
					elseif biome == 2 then
						data[vi] = c_lichen
					elseif biome == 3 then
						data[vi] = c_algae
					elseif biome == 4 then
						data[vi] = c_thinice
						local bi = area:index(x,y-1,z)
						data[bi] = c_thinice					
					elseif biome == 5 then
						data[vi] = c_ice
						local bi = area:index(x,y-1,z)
						data[bi] = c_ice
					end
					--on random chance, place glow crystal formations
					if math.random() <= CRYSTAL then
						caverealms:crystal_stalagmite(x, y, z, area, data, biome)
					end
					--randomly place stalagmites
					if math.random() <= STAGCHA then
						caverealms:stalagmite(x, y, z, area, data, biome)
					end
					--randomly place glow gems
					if math.random() < GEMCHA and biome == 1 then
						local gi = area:index(x,y+1,z)
						data[gi] = c_gem
					end
					if biome == 2 then --if fungus biome
						if math.random() < MUSHCHA then --mushrooms
							local gi = area:index(x,y+1,z)
							data[gi] = c_fungus
						end
						if math.random() < MYCCHA then --mycena mushrooms
							local gi = area:index(x,y+1,z)
							data[gi] = c_mycena
						end
						if math.random() < GIANTCHA then --giant mushrooms
							caverealms:giant_shroom(x, y, z, area, data)
						end
					end
					if math.random() < ICICHA and (biome == 4 or biome == 5) then --if glaciated, place icicles
						local gi = area:index(x,y+1,z)
						data[gi] = c_iciu
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

				elseif roof[si] >= 1 then --and stable2[si] >= 2 then -- node at roof
					--determine biome
					local biome = false --preliminary declaration
					n_biome = nvals_biome[nixz2] --make an easier reference to the noise
					if n_biome >= 0 and n_biome < 0.5 then
						biome = 1 --moss
					elseif n_biome <= -0.5 then
						biome = 2 --fungal
					elseif n_biome >= 0.5 then
						if n_biome >= 0.7 then
							biome = 5
						else
							biome = 4 --glaciated
						end
					else
						biome = 3 --algae
					end
					--glow worm
					if math.random() <= WORMCHA then
						local ai = area:index(x,y+1,z)--index of node above
						if data[ai] ~= c_air then
							data[vi] = c_worm
							local bi = area:index(x,y-1,z) --below index 1
							data[bi] = c_worm
							if math.random(2) == 1 then
								local ci = area:index(x,y-2,z)
								data[ci] = c_worm
								if math.random(2) == 1 then
									local di = area:index(x,y-3,z)
									data[di] = c_worm
									if math.random(2) == 1 then
										local ei = area:index(x,y-4,z)
										data[ei] = c_worm
									end
								end
							end
						end
					end
					--self documenting...
					if math.random() < ICICHA and (biome == 4 or biome == 5) then
						local ai = area:index(x,y+1,z)--index of node above
						if data[ai] ~= c_air then
							local gi = area:index(x,y-1,z)
							data[gi] = c_icid
						end
					end
					if math.random() <= STALCHA then
						local ai = area:index(x,y+1,z)
						if data[ai] ~= c_air then
							caverealms:stalactite(x, y, z, area, data, biome)
						end
					end
					if math.random() <= CRYSTAL then
						local ai = area:index(x,y+1,z)
						if data[ai] ~= c_air then
							caverealms:crystal_stalactite(x,y,z, area, data, biome)
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
			nixz2 = nixz2 - sidelen --reverse the index a bit
		end
		nixz2 = nixz2 + sidelen --increment the index
	end


	--write these changes to the world
	vm:set_data(data)
	vm:set_lighting({day=0, night=0})
	vm:calc_lighting()
	vm:write_to_map(data)
	local chugent = math.ceil((os.clock() - t1) * 1000) --grab how long this took
	print ("[caverealms] "..chugent.." ms") --tell people how long it took
end)
