-- caverealms 0.2.7 by HeroOfTheWinds
-- For latest stable Minetest and back to 0.4.8
-- Depends default
-- License: code WTFPL

caverealms = {}

local modpath = minetest.get_modpath(minetest.get_current_modname())

dofile(modpath.."/config.lua")
dofile(modpath.."/crafting.lua")
dofile(modpath.."/falling_ice.lua")

-- Parameters (see also config.lua)

local YMIN = caverealms.config.ymin -- Approximate realm limits.
local YMAX = caverealms.config.ymax
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
local H_CLAC = 13 --max height of glow crystal stalactites
local GEMCHA = 0.03 --chance of small glow gems
local MUSHCHA = 0.04 --chance of mushrooms
local MYCCHA = 0.03 --chance of mycena mushrooms
local WORMCHA = 0.03 --chance of glow worms
local GIANTCHA = 0.001 -- chance of giant mushrooms
local ICICHA = 0.035 -- chance of icicles

local FALLING_ICICLES = true --toggle to turn on or off falling icicles in glaciated biome
local FALLCHA = 0.33 --chance of causing the structure to fall


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

--glowing emerald
minetest.register_node("caverealms:glow_emerald", {
	description = "Glow Emerald",
	tiles = {"caverealms_glow_emerald.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
	light_source = 13,
	paramtype = "light",
	use_texture_alpha = true,
	drawtype = "glasslike",
	sunlight_propagates = true,
})

--glowing mese crystal blocks
minetest.register_node("caverealms:glow_mese", {
	description = "Mese Crystal Block",
	tiles = {"caverealms_glow_mese.png"},
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

--embedded emerald
minetest.register_node("caverealms:glow_emerald_ore", {
	description = "Glow Emerald Ore",
	tiles = {"caverealms_glow_emerald_ore.png"},
	is_ground_content = true,
	groups = {cracky=2},
	sounds = default.node_sound_glass_defaults(),
	light_source = 10,
	paramtype = "light",
})

--thin (transparent) ice
minetest.register_node("caverealms:thin_ice", {
	description = "Thin Ice",
	tiles = {"caverealms_thin_ice.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
	use_texture_alpha = true,
	drawtype = "glasslike",
	sunlight_propagates = true,
})

--alternate version for stalactites
minetest.register_node("caverealms:hanging_thin_ice", {
	description = "Thin Ice",
	tiles = {"caverealms_thin_ice.png"},
	is_ground_content = true,
	groups = {cracky=3},
	sounds = default.node_sound_glass_defaults(),
	use_texture_alpha = true,
	drawtype = "glasslike",
	sunlight_propagates = true,
	drop = "caverealms:thin_ice",
	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		if FALLING_ICICLES then
			if math.random() <= FALLCHA then
				obj = minetest.add_entity(pos, "caverealms:falling_ice")
				obj:get_luaentity():set_node(oldnode)
				for y = -13, 13 do
					for x = -3, 3 do
					for z = -3, 3 do
						local npos = {x=pos.x+x, y=pos.y+y, z=pos.z+z}
						if minetest.get_node(npos).name == "caverealms:hanging_thin_ice" then
							nobj = minetest.add_entity(npos, "caverealms:falling_ice")
							nobj:get_luaentity():set_node(oldnode)
							minetest.remove_node(npos)
						end
					end
					end
				end
				minetest.remove_node(pos)
			else
				return 1
			end
		else
			return 1
		end
	end,
})

--glowing crystal gem
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

--upward pointing icicle
minetest.register_node("caverealms:icicle_up", {
	description = "Icicle",
	tiles = {"caverealms_icicle_up.png"},
	inventory_image = "caverealms_icicle_up.png",
	wield_image = "caverealms_icicle_up.png",
	is_ground_content = true,
	groups = {cracky=3, oddly_breakable_by_hand=1},
	sounds = default.node_sound_glass_defaults(),
	light_source = 8,
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

--downward pointing icicle
minetest.register_node("caverealms:icicle_down", {
	description = "Icicle",
	tiles = {"caverealms_icicle_down.png"},
	inventory_image = "caverealms_icicle_down.png",
	wield_image = "caverealms_icicle_down.png",
	is_ground_content = true,
	groups = {cracky=3, oddly_breakable_by_hand=1},
	sounds = default.node_sound_glass_defaults(),
	light_source = 8,
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
	description = "Cave Stone with Moss",
	tiles = {"default_cobble.png^caverealms_moss.png", "default_cobble.png", "default_cobble.png^caverealms_moss_side.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	drop = 'default:cobble',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

--cave lichen-covered cobble - purple-ish
minetest.register_node("caverealms:stone_with_lichen", {
	description = "Cave Stone with Lichen",
	tiles = {"default_cobble.png^caverealms_lichen.png", "default_cobble.png", "default_cobble.png^caverealms_lichen_side.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	drop = 'default:cobble',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

--cave algae-covered cobble - yellow-ish
minetest.register_node("caverealms:stone_with_algae", {
	description = "Cave Stone with Algae",
	tiles = {"default_cobble.png^caverealms_algae.png", "default_cobble.png", "default_cobble.png^caverealms_algae_side.png"},
	is_ground_content = true,
	groups = {crumbly=3},
	drop = 'default:cobble',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.25},
	}),
})

--glow worms
minetest.register_node("caverealms:glow_worm", {
	description = "Glow Worms",
	tiles = {"caverealms_glow_worm.png"},
	inventory_image = "caverealms_glow_worm.png",
	wield_image = "caverealms_glow_worm.png",
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=3},
	light_source = 9,
	paramtype = "light",
	drawtype = "plantlike",
	walkable = false,
	buildable_to = true,
	visual_scale = 1.0,
	selection_box = {
		type = "fixed",
		fixed = {-0.5, -0.5, -0.5, 0.5, -0.5, 0.5},
	},
})

--cave plants go here

--glowing fungi
minetest.register_node("caverealms:fungus", {
	description = "Glowing Fungus",
	tiles = {"caverealms_fungi.png"},
	inventory_image = "caverealms_fungi.png",
	wield_image = "caverealms_fungi.png",
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=3},
	light_source = 5,
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

--mycena mushroom
minetest.register_node("caverealms:mycena", {
	description = "Mycena Mushroom",
	tiles = {"caverealms_mycena.png"},
	inventory_image = "caverealms_mycena.png",
	wield_image = "caverealms_mycena.png",
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=3},
	light_source = 6,
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

--giant mushroom
--stem
minetest.register_node("caverealms:mushroom_stem", {
	description = "Giant Mushroom Stem",
	tiles = {"caverealms_mushroom_stem.png"},
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=1},
})

--cap
minetest.register_node("caverealms:mushroom_cap", {
	description = "Giant Mushroom Cap",
	tiles = {"caverealms_mushroom_cap.png"},
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=1},
})

--gills
minetest.register_node("caverealms:mushroom_gills", {
	description = "Giant Mushroom Gills",
	tiles = {"caverealms_mushroom_gills.png"},
	is_ground_content = true,
	groups = {oddly_breakable_by_hand=1},
	drawtype = "plantlike",
})

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
function caverealms:crystal_stalagmite(x,y,z, area, data, biome)
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
		{ {c_emore, c_emerald},   {c_crystore, c_crystal} },
		{ {c_crystore, c_crystal},{c_emore, c_emerald} },
		{ {c_meseore, c_mesecry}, {c_emore, c_emerald} },
		{ {c_crystore, c_crystal},{c_ice, c_thinice} }
	}

	local nid_a
	local nid_b

	if biome > 3 then
		if mode == 1 then
			nid_a = c_ice
		else
			nid_a = c_stone
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
						data[vi] = nid_a
					end
				elseif j <= top/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						data[vi] = nid_b
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

	local bot = math.random(-H_CLAC, -6) --grab a random height for the stalagmite
	for j = bot, 0 do --y
		for k = -3, 3 do
			for l = -3, 3 do
				if j >= -1 then
					if k*k + l*l <= 9 then
						if (biome == 4 or biome == 5) and mode == 1 then
							local vi = area:index(x+k, y+j, z+l-3)
							data[vi] = c_ice
						else
							local vi = area:index(x+k, y+j, z+l-3)
							data[vi] = c_stone
						end
					end
				elseif j >= bot/5 then
					if k*k + l*l <= 4 then
						local vi = area:index(x+k, y+j, z+l-3)
						if biome == 1 then
							if mode == 2 then
								data[vi] = c_emore
							else
								data[vi] = c_crystore
							end
						elseif biome == 2 then
							if mode == 2 then
								data[vi] = c_crystore
							else
								data[vi] = c_emore
							end
						elseif biome == 3 then
							if mode == 2 then
								data[vi] = c_meseore
							else
								data[vi] = c_emore
							end
						elseif biome == 4 or biome == 5 then
							if mode == 2 then
								data[vi] = c_crystore
							else
								data[vi] = c_ice
							end
						end
					end
				elseif j >= bot/5 * 3 then
					if k*k + l*l <= 1 then
						local vi = area:index(x+k, y+j, z+l-3)
						if biome == 1 then
							if mode == 2 then
								data[vi] = c_emerald
							else
								data[vi] = c_crystal
							end
						elseif biome == 2 then
							if mode == 2 then
								data[vi] = c_crystal
							else
								data[vi] = c_emerald
							end
						elseif biome == 3 then
							if mode == 2 then
								data[vi] = c_mesecry
							else
								data[vi] = c_emerald
							end
						elseif biome == 4 or biome == 5 then
							if mode == 2 then
								data[vi] = c_crystal
							else
								data[vi] = c_thinice
							end
						end
					end
				else
					local vi = area:index(x, y+j, z-3)
					if biome == 1 then
						if mode == 2 then
							data[vi] = c_emerald
						else
							data[vi] = c_crystal
						end
					elseif biome == 2 then
						if mode == 2 then
							data[vi] = c_crystal
						else
							data[vi] = c_emerald
						end
					elseif biome == 3 then
						if mode == 2 then
							data[vi] = c_mesecry
						else
							data[vi] = c_emerald
						end
					elseif biome == 4 or biome == 5 then
						if mode == 2 then
							data[vi] = c_crystal
						else
							data[vi] = c_thinice
						end
					end
				end
			end
		end
	end
end

--function to create giant 'shrooms
function caverealms:giant_shroom(x, y, z, area, data)
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
	local nixyz2 = 1
	local nixz2 = 1
	local stable2 = {}

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
					--place dirt on floor, add plants
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
						--bi = area:index(x,y-2,z)
						--data[bi] = c_water
						--bi = area:index(x,y-3,z)
						--if math.random() <= GEMCHA then
							--data[bi] = c_gem
						--else
							--data[bi] = c_water
						--end
						--bi = area:index(x,y-4,z)
						--data[bi] = c_stone
						--bi = area:index(x,y-5,z)
						--data[bi] = c_stone
					elseif biome == 5 then
						data[vi] = c_ice
						local bi = area:index(x,y-1,z)
						data[bi] = c_ice
						--bi = area:index(x,y-2,z)
						--data[bi] = c_water
						--bi = area:index(x,y-3,z)
						--if math.random() <= GEMCHA then
							--data[bi] = c_gem
						--else
							--data[bi] = c_water
						--end
						--bi = area:index(x,y-4,z)
						--data[bi] = c_stone
						--bi = area:index(x,y-5,z)
						--data[bi] = c_stone
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
					if biome == 2 then
						if math.random() < MUSHCHA then
							local gi = area:index(x,y+1,z)
							data[gi] = c_fungus
						end
						if math.random() < MYCCHA then
							local gi = area:index(x,y+1,z)
							data[gi] = c_mycena
						end
						if math.random() < GIANTCHA then
							caverealms:giant_shroom(x, y, z, area, data)
						end
					end
					if math.random() < ICICHA and (biome == 4 or biome == 5) then
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
