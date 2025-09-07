-- House Sapling Mod for Minetest
-- Allows registration of multiple sapling types, each growing into different house schematics

local houses = {
    {
        name = "wooden_house",
        description = "Wooden house Sapling\nInstantly grows into House 1 when placed",
        schematic = "house1.mts",
        size = {x = 0, y = 1, z = 0},
        texture = "default_tree.png"  -- You can change this to "house1_sapling.png" if you have a custom texture
    },
    {
        name = "brick_house",
        description = "Brick house Sapling\nInstantly grows into House 1 when placed",
        schematic = "house2.mts",
        size = {x = 0, y = 1, z = 0},
        texture = "default_brick.png"  -- You can change this to "house1_sapling.png" if you have a custom texture
    },
    -- Add more houses here, for example:
    -- {
    --     name = "house2",
    --     description = "House 2 Sapling\nInstantly grows into House 2 when placed",
    --     schematic = "house2.mts",
    --     size = {x = 7, y = 6, z = 7},
    --     texture = "house2_sapling.png"
    -- },
    -- {
    --     name = "house3",
    --     description = "House 3 Sapling\nInstantly grows into House 3 when placed",
    --     schematic = "house3.mts",
    --     size = {x = 9, y = 7, z = 9},
    --     texture = "house3_sapling.png"
    -- },
    -- Add as many as you want!
}

-- Function to create the on_place callback for each sapling
local function make_on_place(schematic_path, size)
    return function(itemstack, placer, pointed_thing)
        if not pointed_thing.type == "node" then
            return itemstack
        end
        local pos = pointed_thing.above
        local player_name = placer:get_player_name()
        -- Calculate offsets for centering
        local offset_x = math.floor((size.x - 1) / 2)
        local offset_z = math.floor((size.z - 1) / 2)
        -- Define the area for space check
        local pos1 = {x = pos.x - offset_x, y = pos.y, z = pos.z - offset_z}
        local pos2 = {x = pos.x + (size.x - 1 - offset_x), y = pos.y + size.y - 1, z = pos.z + (size.z - 1 - offset_z)}
        local volume = size.x * size.y * size.z
        local nodes = minetest.find_nodes_in_area(pos1, pos2, {"air", "group:flower", "group:plant", "group:leaves"})
        if #nodes < volume then
            minetest.chat_send_player(player_name, "Not enough space to grow the house! Need a " .. size.x .. "x" .. size.y .. "x" .. size.z .. " clear area.")
            return itemstack
        end
        -- Get the mod path
        local modpath = minetest.get_modpath("modme")
        if not modpath then
            minetest.chat_send_player(player_name, "Error: Mod path not found. Please check mod installation.")
            return itemstack
        end
        -- Full schematic path (already passed as argument)
        -- Check if schematic file exists
        local file = io.open(schematic_path, "r")
        if not file then
            minetest.chat_send_player(player_name, "Error: Schematic file '" .. schematic_path:match("([^/]+)$") .. "' not found in modme/schematics/")
            return itemstack
        end
        file:close()
        -- Place the house schematic
        minetest.place_schematic(pos1, schematic_path, "place_center_x,place_center_z", nil, true, {force_placement = false})
        if not minetest.is_creative_enabled(player_name) then
            itemstack:take_item()
        end
        minetest.chat_send_player(player_name, "House grown successfully!")
        return itemstack
    end
end

-- Register each sapling
for _, house in ipairs(houses) do
    local modpath = minetest.get_modpath("modme")
    local schematic_path = modpath .. "/schematics/" .. house.schematic
    minetest.register_node("modme:" .. house.name .. "_sapling", {
        description = house.description,
        tiles = {house.texture},
        inventory_image = house.texture,
        wield_image = house.texture,
        paramtype = "light",
        sunlight_propagates = true,
        walkable = false,
        selection_box = {
            type = "fixed",
            fixed = {-0.3, -0.5, -0.3, 0.3, 0.35, 0.3}
        },
        groups = {snappy = 2, dig_immediate = 3, flammable = 2, attached_node = 1, sapling = 1},
        on_place = make_on_place(schematic_path, house.size)
    })
end

-- Register craft recipe for the first sapling (house1)
minetest.register_craft({
    output = "modme:brick_house_sapling",
    recipe = {
        {"default:sapling", "default:brick", "default:sapling"},
        {"default:brick", "default:coal_lump", "default:brick"},
        {"default:sapling", "default:brick", "default:sapling"}
    }
})

-- To add craft recipes for additional saplings, add similar crafts here, e.g.:
 minetest.register_craft({
     output = "modme:wooden_house_sapling",
    recipe = {
         {"default:sapling", "default:wood", "default:sapling"},
         {"default:wood", "default:coal_lump", "default:wood"},  -- Use a different ingot/item for variety
         {"default:sapling", "default:wood", "default:sapling"}
     }
 })
-- Repeat for each additional house.
