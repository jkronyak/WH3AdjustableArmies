
local function my_func(context)
    local char = context:character()
    local mf = char:embedded_in_military_force()
    local faction_name = char:faction():name()

    -- Teleport the hero out of the army
    local x_pos = char:logical_position_x()
    local y_pos = char:logical_position_y()

    local x, y = cm:find_valid_spawn_location_for_character_from_position(
        faction_name,
        x_pos,
        y_pos,
        true,
        0
    )
    cm:teleport_to(
        cm:char_lookup_str(char),
        x, 
        y
    )
    -- Copy units
    local units_to_re_add = {} 
    local ul = mf:unit_list()

    for i=0,ul:num_items() - 1 do 
        local cur = ul:item_at(i)
        if cur:unit_class() ~= 'com' then
            table.insert(units_to_re_add, {
                cqi = cur:command_queue_index(),
                key = cur:unit_key(),
                experience_level = cur:experience_level(),
                strength =  cur:percentage_proportion_of_full_strength()
            })
            cm:remove_unit_from_character(
                cm:char_lookup_str(mf:general_character()),
                cur:unit_key()
            )
        end
    end

    -- Embed the hero now that the army has space
    cm:embed_agent_in_force(char, mf)
    -- Re-add the units to the army, and give them the appriorate experience/health
    local num_units = mf:unit_list():num_items()

    for i, unit in ipairs(units_to_re_add) do
        cm:grant_unit_to_character(
            cm:char_lookup_str(mf:general_character()),
            unit.key
        )
        if(unit.experience_level ~= 0) then
            local u = mf:unit_list():item_at(i + num_units - 1)
            cm:add_experience_to_unit(u, unit.experience_level)
            cm:set_unit_hp_to_unary_of_maximum(u, unit.strength / 100)
        end
    end

end

core:add_listener(
    "CharacterAncillaryGained_listner",
    "CharacterAncillaryGained",
    function(context)
        return context:character():faction():is_human()
    end,
    my_func,
    true
);

