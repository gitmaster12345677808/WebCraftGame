

-- Defining color variations for the bricks
local brick_colors = {
    {name = "purple", color = "#800080"},
    {name = "green", color = "#008000"},
    {name = "blue", color = "#0000FF"},
    {name = "orange", color = "#FFA500"},
    {name = "yellow", color = "#FFFF00"}
}

-- Registering new brick nodes with tinted textures
for _, brick in ipairs(brick_colors) do
    minetest.register_node(":colored_bricks:brick_" .. brick.name, {
        description = brick.name:gsub("^%l", string.upper) .. " Brick",
        tiles = {"brick.png^[multiply:" .. brick.color},
        is_ground_content = false,
        groups = {cracky = 3},
        sounds = default.node_sound_stone_defaults(),
    })
    
    -- Adding craft recipe for each colored brick
    minetest.register_craft({
        output = "colored_bricks:brick_" .. brick.name .. " 4",
        recipe = {
            {"default:brick", "default:brick", "dye:" .. brick.name},
            {"default:brick", "default:brick", ""}
        }
    })
end
