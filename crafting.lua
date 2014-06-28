--CaveRealms crafting.lua

--CRAFT ITEMS--

--mycena essence
minetest.register_craftitem("caverealms:mycena_essence", {
	description = "Mycena Essence",
	inventory_image = "caverealms_mycena_essence.png",
})

--CRAFT RECIPES--

--mycena essence
minetest.register_craft({
	output = "caverealms:mycena_essence",
	type = "shapeless",
	recipe = {"caverealms:mycena"}
})


--glow mese block
minetest.register_craft({
	output = "caverealms:glow_mese",
	recipe = {
		{"default:mese_crystal_fragment","default:mese_crystal_fragment","default:mese_crystal_fragment"},
		{"default:mese_crystal_fragment","caverealms:mycena_essence","default:mese_crystal_fragment"},
		{"default:mese_crystal_fragment","default:mese_crystal_fragment","default:mese_crystal_fragment"}
	}
})

--reverse craft for glow mese
minetest.register_craft({
	output = "default:mese_crystal_fragment 8",
	type = "shapeless",
	recipe = {"caverealms:glow_mese"}
})

--thin ice to water
minetest.register_craft({
	output = "default:water_source",
	type = "shapeless",
	recipe = {"caverealms:thin_ice"}
})