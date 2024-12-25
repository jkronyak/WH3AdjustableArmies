--[[

]] --
local enable_logging = true
local function Log(obj)
    if enable_logging then
        local t = os.date('%H:%M:%S')
        local file = io.open("jar_wh3.txt", "a")
        file:write("[" .. t .. "] ")
        if type(obj) == 'string' then
            file:write(obj)
        else
            file:write(tostring(obj))
        end
        file:write("\n")
        file:close()
    end
end

local tables = require('data.table_data')

local unit_purchasable_effect_mapping_grn =
        tables.unit_purchasable_effect_mapping_grn
local unit_purchasable_effect_mapping_wef =
        tables.unit_purchasable_effect_mapping_wef
local unit_purchasable_effect_mapping_throt_aug =
        tables.unit_purchasable_effect_mapping_throt_aug
local unit_purchasable_effect_mapping_throt_ins =
        tables.unit_purchasable_effect_mapping_throt_ins

local hero_to_embed_cqi = nil

local function get_or_create_btn()
    local ui_button_parent = find_uicomponent(core:get_ui_root(),
        "hud_campaign",
        "info_panel_holder",
        "primary_info_panel_holder",
        "info_panel_background",
        "CharacterInfoPopup",
        "character_info_parent",
        "porthole_top")
    if not is_uicomponent(ui_button_parent) then
        Log("Get or create button was called, but we couldn't find the parent!")
        return
    end
    local button_name = "jar_test_button"
    local existing_button = find_uicomponent(ui_button_parent, button_name)
    if is_uicomponent(existing_button) then
        return existing_button
    else
        local new_button = UIComponent(ui_button_parent:CreateComponent(
            button_name,
            "ui/templates/dev_button_small.twui.xml"))
        return new_button
    end
end

local function populate_btn(btn)
    if not is_uicomponent(btn) then
        Log("The button passed to populate_my_button is not a valid UIC! We're probably calling these functions at the wrong time")
        return
    end
    local char_cqi = cm:get_campaign_ui_manager():get_char_selected_cqi()
    if not char_cqi or char_cqi == -1 then
        Log("No character is selected")
        return
    end
    local char = cm:get_character_by_cqi(char_cqi)
    if not (char:is_embedded_in_military_force() or char:has_military_force()) then
        btn:SetState("active")
        btn:SetVisible(true)
        btn:SetTooltipText("Select this hero to embed.", true)
    else
        btn:SetState("inactive")
        btn:SetVisible(false)
        btn:SetTooltipText("Do not click me!", true)
    end
end

-- Stores the currently selected non-lord character into a variable
local function handle_hero_selected()
    local char = cm:get_character_by_cqi(
        cm:get_campaign_ui_manager():get_char_selected_cqi())
    -- Only set hero_to_embed_cqi if the character is not embedded, and is not a lord
    if not (char:is_embedded_in_military_force() or char:has_military_force() or
                char:is_wounded()) then
        Log("Char is not embedded, and is not a general.")
        hero_to_embed_cqi = char:cqi()
    end
end

-- Embeds hero_to_embed into the selected army by performing a 'refresh' of the units
local function handle_selected_army(context)
    local lord = context:character()
    local faction = lord:faction()
    local hero_to_embed = cm:get_character_by_cqi(hero_to_embed_cqi)
    -- If there is no hero_to_embed_cqi, return.
    if not hero_to_embed or hero_to_embed:is_null_interface() then
        Log("handle_selected_army:hero_to_embed is nil")
        return
    end

    -- Copy data all non-lord/non-hero units in the army and remove them
    local mf = lord:military_force()
    local units_to_re_add = {}
    local ul = mf:unit_list()

    for i = 0, ul:num_items() - 1 do
        local cur = ul:item_at(i)
        if cur:unit_class() ~= 'com' then
            table.insert(units_to_re_add, {
                cqi = cur:command_queue_index(),
                key = cur:unit_key(),
                experience_level = cur:experience_level(),
                strength = cur:percentage_proportion_of_full_strength(),
                purchased_effects = cur:get_unit_purchased_effects()
            })

            cm:remove_unit_from_character(
                cm:char_lookup_str(mf:general_character()), cur:unit_key())
        end
    end

    -- Embed hero_to_embed into the army
    cm:embed_agent_in_force(hero_to_embed, mf)

    -- Add the units back into the army, and set their experience and HP at each step
    local num_units = mf:unit_list():num_items()
    for i, og_unit in ipairs(units_to_re_add) do
        cm:grant_unit_to_character(cm:char_lookup_str(mf:general_character()),
            og_unit.key)
        local new_unit = mf:unit_list():item_at(i + num_units - 1)
        if og_unit.strength ~= 100 then
            cm:set_unit_hp_to_unary_of_maximum(new_unit, og_unit.strength / 100)
        end
        if og_unit.experience_level ~= 0 then
            cm:add_experience_to_unit(new_unit, og_unit.experience_level)
        end

        if og_unit.purchased_effects:num_items() > 0 then
            -- console_print("**"..og_unit.key)

            for j = 0, og_unit.purchased_effects:num_items() - 1 do
                local cur = og_unit.purchased_effects:item_at(j)
                local cur_key = cur:record_key()

                -- If the unit_purchasable_effect is a green skin scrap upgrade
                if unit_purchasable_effect_mapping_grn[cur_key] then
                    local mapping = unit_purchasable_effect_mapping_grn
                    local factor = mapping[cur_key].pooled_resource_factor
                    local amount = -tonumber(mapping[cur_key]
                                .pooled_resource_amount) +
                            (30 * j) -- Each scrap upgrade adds +30 to the cost
                    local resource = mapping[cur_key].pooled_resource
                    -- console_print("**"..j.."| "..cur_key.."| "..factor.."| "..amount.."| "..resource)

                    local spent_b, gained_b =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local before_amount = gained_b - spent_b
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, amount)
                    cm:faction_purchase_unit_effect(faction, new_unit, cur)

                    local spent_a, gained_a =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local after_amount = gained_a - spent_a
                    local correction_amount = -(after_amount - before_amount)
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, correction_amount)
                elseif unit_purchasable_effect_mapping_throt_aug[cur_key] then
                    local mapping = unit_purchasable_effect_mapping_throt_aug
                    local factor = mapping[cur_key].pooled_resource_factor
                    local amount = -tonumber(mapping[cur_key]
                        .pooled_resource_amount)
                    local resource = mapping[cur_key].pooled_resource
                    -- console_print("**"..j.."| "..cur_key.."| "..factor.."| "..amount.."| "..resource)

                    local spent_b, gained_b =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local before_amount = gained_b - spent_b
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, amount)
                    cm:faction_purchase_unit_effect(faction, new_unit, cur)

                    local spent_a, gained_a =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local after_amount = gained_a - spent_a
                    local correction_amount = -(after_amount - before_amount)
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, correction_amount)
                elseif unit_purchasable_effect_mapping_wef[cur_key] then
                    local amount = -tonumber(
                        unit_purchasable_effect_mapping_wef[cur_key]
                        .treasury_amount)
                    cm:treasury_mod(faction:name(), amount)
                    cm:faction_purchase_unit_effect(faction, new_unit, cur)
                end
            end

            -- Iterate the purchased_effects again, this time only checking for Throt's instabilities
            -- They must be added last, otherwise they increase the chance of further instability for every augment added.
            for j = 0, og_unit.purchased_effects:num_items() - 1 do
                local cur = og_unit.purchased_effects:item_at(j)
                local cur_key = cur:record_key()
                if unit_purchasable_effect_mapping_throt_ins[cur_key] then
                    local mapping = unit_purchasable_effect_mapping_throt_ins
                    local factor = mapping[cur_key].pooled_resource_factor
                    local amount = -tonumber(mapping[cur_key]
                        .pooled_resource_amount)
                    local resource = mapping[cur_key].pooled_resource
                    -- console_print("**"..j.."| "..cur_key.."| "..factor.."| "..amount.."| "..resource)

                    local spent_b, gained_b =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local before_amount = gained_b - spent_b
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, amount)
                    cm:faction_purchase_unit_effect(faction, new_unit, cur)

                    local spent_a, gained_a =
                            cm:get_total_pooled_resource_changed_for_faction(
                                faction:name(), resource, factor)
                    local after_amount = gained_a - spent_a
                    local correction_amount = -(after_amount - before_amount)
                    cm:faction_add_pooled_resource(faction:name(), resource,
                        factor, correction_amount)
                end
            end
        end
    end

    -- 'Deselect' the hero_to_embed_cqi
    hero_to_embed_cqi = nil
end

core:add_listener("JarAdjArmiesCharSelected", "CharacterSelected",
    function(context)
        Log("JarAdjArmiesCharSelected:" .. tostring(context))

        return context:character():faction():is_human()
    end, function() populate_btn(get_or_create_btn()) end, true)

core:add_listener("JarAdjArmiesArmySelected", "CharacterSelected",
    function(context)
        Log("JarAdjArmiesArmySelected:" .. tostring(context))
        local char = context:character()
        return char:faction():is_human() and char:has_military_force()
    end, handle_selected_army, true)

core:add_listener("JarAdjArmiesBtnClicked", "ComponentLClickUp", function(
            context)
        return context.string == "jar_test_button"
    end,
    handle_hero_selected, true)

cm:add_first_tick_callback(function()
    local human_faction_keys = cm:get_human_factions()
    for _, key in ipairs(human_faction_keys) do
        if cm:are_pooled_resources_tracked_for_faction(key) then return end
        cm:start_pooled_resource_tracker_for_faction(key)
    end
end)
