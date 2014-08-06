--grab schematics
local fortress = minetest.get_modpath("caverealms").."/schems/DMFort.mts"
local fountain = minetest.get_modpath("caverealms").."/schems/DMFountain.mts"

--place Dungeon Master Statue fountains
minetest.register_abm({
	nodenames = {"caverealms:s_fountain"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		minetest.place_schematic(pos, fountain, "random", {}, true)
	end,
})

--place Dungeon Master Fortresses
minetest.register_abm({
	nodenames = {"caverealms:s_fortress"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		npos = {x=pos.x,y=pos.y-7,z=pos.z}
		minetest.place_schematic(npos, fortress, "random", {}, true)
	end,
})

local MAX_ITEMS = 5 --maximum number of items to put in chests - do not set to less than 2
--table of itemstrings
local ITEMS = {
	"default:diamond",
	"default:obsidian 33",
	"default:mese",
	"default:pick_diamond",
	"default:stonebrick 50",
	"default:sandstone 75",
	"default:torch 99",
	"default:water_source 4",
}

--spawn and fill chests
minetest.register_abm({
	nodenames = {"caverealms:s_chest"},
	interval = 1.0,
	chance = 1,
	action = function(pos, node, active_object_count, active_object_count_wider)
		oldparam = minetest.get_node(pos).param2
		minetest.set_node(pos, {name="default:chest", param2=oldparam})
		minetest.after(1.0, function()
			local inv = minetest.get_inventory({type="node", pos=pos})
			local item_num = math.random(1, MAX_ITEMS)
			for i = 1, item_num do
				item_i = math.random(8) --if you add or subtract items from ITEMS, be sure to change this value to reflect it
				inv:add_item("main", ITEMS[item_i])
			end
		end)
	end,
})