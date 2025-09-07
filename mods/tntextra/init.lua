
-- Explosion function with entity damage
local function explode(pos, radius)
    -- Play explosion sound
    minetest.sound_play("tnt_explode", {pos = pos, gain = 1.0, max_hear_distance = 64})
    
    -- Spawn smoke particles
    minetest.add_particlespawner({
        amount = 64,
        time = 0.1,
        minpos = {x = pos.x - radius, y = pos.y - radius, z = pos.z - radius},
        maxpos = {x = pos.x + radius, y = pos.y + radius, z = pos.z + radius},
        minvel = {x = -10, y = -10, z = -10},
        maxvel = {x = 10, y = 10, z = 10},
        minacc = {x = 0, y = 0, z = 0},
        maxacc = {x = 0, y = 0, z = 0},
        minexptime = 0.5,
        maxexptime = 1.5,
        minsize = 8,
        maxsize = 16,
        texture = "tnt_smoke.png",
    })
    
    -- Remove nodes in a sphere
    for x = -radius, radius do
        for y = -radius, radius do
            for z = -radius, radius do
                if x*x + y*y + z*z <= radius * radius then
                    local npos = {x = pos.x + x, y = pos.y + y, z = pos.z + z}
                    local node = minetest.get_node(npos)
                    if node.name ~= "air" and not minetest.is_protected(npos, "") then
                        minetest.remove_node(npos)
                    end
                end
            end
        end
    end
    
    -- Damage entities within a larger radius (similar to default TNT)
    local damage_radius = radius * 2
    local objects = minetest.get_objects_inside_radius(pos, damage_radius)
    for _, obj in ipairs(objects) do
        if obj:is_player() or (obj:get_luaentity() and obj:get_luaentity().name ~= "__builtin:item") then
            local obj_pos = obj:get_pos()
            local dist = vector.distance(pos, obj_pos)
            if dist <= damage_radius then
                -- Calculate damage based on distance (max 8 hearts at center, decreasing linearly)
                local damage = math.floor(16 * (1 - dist / damage_radius))
                if damage > 0 then
                    obj:set_hp(obj:get_hp() - damage)
                end
            end
        end
    end
end

-- Define colored TNT variations
local tnts = {
    {name = "green", color = "#008000", radius = 6},  -- Highest radius
    {name = "blue", color = "#0000FF", radius = 2},    -- Lowest radius
    {name = "orange", color = "#FFA500", radius = 4}   -- Medium radius
}

-- Register each colored TNT as a node
for _, t in ipairs(tnts) do
    minetest.register_node("tntextra:tnt_" .. t.name, {
        description = t.name:gsub("^%l", string.upper) .. " TNT",
        tiles = {
            "tnt_top.png^[multiply:" .. t.color,
            "tnt_bottom.png^[multiply:" .. t.color,
            "tnt_side.png^[multiply:" .. t.color
        },
        is_ground_content = false,
        groups = {dig_immediate = 2, flammable = 5},
        on_punch = function(pos, node, puncher, pointed_thing)
            if puncher:get_wielded_item():get_name() == "fire:flint_and_steel" then
                minetest.sound_play("tnt_ignite", {pos = pos, gain = 1.0, max_hear_distance = 32})
                minetest.set_node(pos, {name = "tntextra:burning_tnt_" .. t.name})
            end
        end,
    })

    -- Register burning TNT node
    minetest.register_node("tntextra:burning_tnt_" .. t.name, {
        description = t.name:gsub("^%l", string.upper) .. " Burning TNT",
        tiles = {
            {
                name = "tnt_top_burning.png^[multiply:" .. t.color,
                animation = {type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1}
            },
            "tnt_bottom.png^[multiply:" .. t.color,
            "tnt_side.png^[multiply:" .. t.color
        },
        light_source = 5,
        drop = "",
        groups = {dig_immediate = 2},
        on_construct = function(pos)
            minetest.get_node_timer(pos):start(2)
        end,
        on_timer = function(pos)
            local radius = t.radius
            minetest.remove_node(pos)
            explode(pos, radius)
        end,
    })

    -- Add craft recipe: default clay + corresponding dye
    minetest.register_craft({
        output = "tntextra:tnt_" .. t.name,
        type = "shapeless",
        recipe = {"default:clay", "dye:" .. t.name}
    })
end
