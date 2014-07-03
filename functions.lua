--CaveRealms functions.lua

--FUNCTIONS--

local H_LAG = caverealms.config.h_lag --15 --max height for stalagmites
local H_LAC = caverealms.config.h_lac --20 --...stalactites
local H_CRY = caverealms.config.h_cry --9 --max height of glow crystals
local H_CLAC = caverealms.config.h_clac --13 --max height of glow crystal stalactites

function caverealms:above_solid(x,y,z,area,data)
	local c_air = minetest.get_content_id("air")
	local ai = area:index(x,y+1,z-3)
	if data[ai] == c_air then
		return false
	else
		return true
	end
end
function caverealms:below_solid(x,y,z,area,data)
	local c_air = minetest.get_content_id("air")
	local ai = area:index(x,y-1,z-3)
	if data[ai] == c_air then
		return false
	else
		return true
	end
end

--stalagmite spawner
function caverealms:stalagmite(x,y,z, area, data)

	if not caverealms:below_solid(x,y,z,area,data) then
		return
	end
	
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

	if not caverealms:above_solid(x,y,z,area,data) then
		return
	end

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
function caverealms:crystal_stalagmite(x,y,z, area, data, biome)

	if not caverealms:below_solid(x,y,z,area,data) then
		return
	end
	
	--contest ids
	local c_stone = minetest.get_content_id("default:stone")
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_crystore = minetest.get_content_id("caverealms:glow_ore")
	local c_emerald = minetest.get_content_id("caverealms:glow_emerald")
	local c_emore = minetest.get_content_id("caverealms:glow_emerald_ore")
	local c_mesecry = minetest.get_content_id("caverealms:glow_mese")
	local c_meseore = minetest.get_content_id("default:stone_with_mese")
	local c_ice = minetest.get_content_id("default:ice")
	local c_thinice = minetest.get_content_id("caverealms:thin_ice")

	--for randomness
	local mode = 1
	if math.random(15) == 1 then
		mode = 2
	end
	if biome == 3 then
		if math.random(25) == 1 then
			mode = 2
		else
			mode = 1
		end
	end
	if biome == 4 or biome == 5 then
		if math.random(3) == 1 then
			mode = 2
		end
	end

	local stalids = {
 		{ {c_crystore, c_crystal}, {c_emore, c_emerald} },
 		{ {c_emore, c_emerald}, {c_crystore, c_crystal} },
 		{ {c_emore, c_emerald}, {c_meseore, c_mesecry} },
 		{ {c_ice, c_thinice}, {c_crystore, c_crystal}}
 	}

 	local nid_a
 	local nid_b
	local nid_s = c_stone --stone base, will be rewritten to ice in certain biomes

 	if biome > 3 then
 		if mode == 1 then
 			nid_a = c_ice
			nid_b = c_thinice
			nid_s = c_ice
 		else
 			nid_a = c_crystore
			nid_b = c_crystal
 		end
 	elseif mode == 1 then
 		nid_a = stalids[biome][1][1]
 		nid_b = stalids[biome][1][2]
 	else
 		nid_a = stalids[biome][2][1]
 		nid_b = stalids[biome][2][2]
 	end

	local top = math.random(5,H_CRY) --grab a random height for the stalagmite
	for j = 0, top do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j == 0 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_s
					end
				elseif j <= top/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_a
					end
				elseif j <= top/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_b
					end
				else
					local vi = area:index(x, y+j, z-3)
					data[vi] = nid_b
				end
			end
		end
	end
end

--crystal stalactite spawner
function caverealms:crystal_stalactite(x,y,z, area, data, biome)

	if not caverealms:above_solid(x,y,z,area,data) then
		return
	end

	--contest ids
	local c_stone = minetest.get_content_id("default:stone")
	local c_crystore = minetest.get_content_id("caverealms:glow_ore")
	local c_crystal = minetest.get_content_id("caverealms:glow_crystal")
	local c_emerald = minetest.get_content_id("caverealms:glow_emerald")
	local c_emore = minetest.get_content_id("caverealms:glow_emerald_ore")
	local c_mesecry = minetest.get_content_id("caverealms:glow_mese")
	local c_meseore = minetest.get_content_id("default:stone_with_mese")
	local c_ice = minetest.get_content_id("default:ice")
	local c_thinice = minetest.get_content_id("caverealms:hanging_thin_ice")

	--for randomness
	local mode = 1
	if math.random(15) == 1 then
		mode = 2
	end
	if biome == 3 then
		if math.random(25) == 1 then
			mode = 2
		else
			mode = 1
		end
	end
	if biome == 4 or biome == 5 then
		if math.random(3) == 1 then
			mode = 2
		end
	end

	local stalids = {
 		{ {c_crystore, c_crystal}, {c_emore, c_emerald} },
 		{ {c_emore, c_emerald}, {c_crystore, c_crystal} },
 		{ {c_emore, c_emerald}, {c_meseore, c_mesecry} },
 		{ {c_ice, c_thinice}, {c_crystore, c_crystal}}
 	}

 	local nid_a
 	local nid_b
	local nid_s = c_stone --stone base, will be rewritten to ice in certain biomes

 	if biome > 3 then
 		if mode == 1 then
 			nid_a = c_ice
			nid_b = c_thinice
			nid_s = c_ice
 		else
 			nid_a = c_crystore
			nid_b = c_crystal
 		end
 	elseif mode == 1 then
 		nid_a = stalids[biome][1][1]
 		nid_b = stalids[biome][1][2]
 	else
 		nid_a = stalids[biome][2][1]
 		nid_b = stalids[biome][2][2]
 	end

	local bot = math.random(-H_CLAC, -6) --grab a random height for the stalagmite
	for j = bot, 0 do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j >= -1 then
					if k*k + l*l <= 9 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_s
					end
				elseif j >= bot/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_a
					end
				elseif j >= bot/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_b
					end
				else
					local vi = area:index(x, y+j, z-3)
					data[vi] = nid_b
				end
			end
		end
	end
end

--function to create giant 'shrooms
function caverealms:giant_shroom(x, y, z, area, data)

	if not caverealms:below_solid(x,y,z,area,data) then
		return
	end

	--as usual, grab the content ID's
	local c_stem = minetest.get_content_id("caverealms:mushroom_stem")
	local c_cap = minetest.get_content_id("caverealms:mushroom_cap")
	local c_gills = minetest.get_content_id("caverealms:mushroom_gills")

	z = z - 5
	--cap
	for k = -5, 5 do
	for l = -5, 5 do
		if k*k + l*l <= 25 then
			local vi = area:index(x+k, y+5, z+l)
			data[vi] = c_cap
		end
		if k*k + l*l <= 16 then
			local vi = area:index(x+k, y+6, z+l)
			data[vi] = c_cap
			vi = area:index(x+k, y+5, z+l)
			data[vi] = c_gills
		end
		if k*k + l*l <= 9 then
			local vi = area:index(x+k, y+7, z+l)
			data[vi] = c_cap
		end
		if k*k + l*l <= 4 then
			local vi = area:index(x+k, y+8, z+l)
			data[vi] = c_cap
		end
	end
	end
	--stem
	for j = 0, 5 do
		for k = -1,1 do
			local vi = area:index(x+k, y+j, z)
			data[vi] = c_stem
			if k == 0 then
				local ai = area:index(x, y+j, z+1)
				data[ai] = c_stem
				ai = area:index(x, y+j, z-1)
				data[ai] = c_stem
			end
		end
	end
end

function caverealms:legacy_giant_shroom(x, y, z, area, data) --leftovers :P
	--as usual, grab the content ID's
	local c_stem = minetest.get_content_id("caverealms:mushroom_stem")
	local c_cap = minetest.get_content_id("caverealms:mushroom_cap")
	
	z = z - 4
	--cap
	for k = -4, 4 do
	for l = -4, 4 do
		if k*k + l*l <= 16 then
			local vi = area:index(x+k, y+5, z+l)
			data[vi] = c_cap
		end
		if k*k + l*l <= 9 then
			local vi = area:index(x+k, y+4, z+l)
			data[vi] = c_cap
			vi = area:index(x+k, y+6, z+l)
			data[vi] = c_cap
		end
		if k*k + l*l <= 4 then
			local vi = area:index(x+k, y+7, z+l)
			data[vi] = c_cap
		end
	end
	end
	--stem
	for j = 0, 4 do
		for k = -1,1 do
			local vi = area:index(x+k, y+j, z)
			data[vi] = c_stem
			if k == 0 then
				local ai = area:index(x, y+j, z+1)
				data[ai] = c_stem
				ai = area:index(x, y+j, z-1)
				data[ai] = c_stem
			end
		end
	end
end