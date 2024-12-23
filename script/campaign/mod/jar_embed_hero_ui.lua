--[[
TODO: 
* Add get_unit_purchased_effects, 
    cm:faction_purchase_unit_effect(faction faction, unit unit, unit_purchasable_effect purchasable effect)

CHECKS:
* ancillaries (i.e. banners, such as Da Immortulz)
    * Lord keeps the ancillary [GOOD]

]]--

local hero_to_embed = nil

local function get_or_create_btn()
    local ui_button_parent = find_uicomponent(
        core:get_ui_root(),
        "hud_campaign",
        "info_panel_holder",
        "primary_info_panel_holder",
        "info_panel_background",
        "CharacterInfoPopup",
        "character_info_parent",
        "porthole_top"
    )
    if not is_uicomponent(ui_button_parent) then
        out("Get or create button was called, but we couldn't find the parent!")
        return
    end
    local button_name = "jar_test_button"
    local existing_button = find_uicomponent(ui_button_parent, button_name)
    if is_uicomponent(existing_button) then
        return existing_button
    else
        local new_button = UIComponent(
            ui_button_parent:CreateComponent(
                button_name, 
                "ui/templates/dev_button_small.twui.xml"
            )
        )
        return new_button
    end
end

local function populate_btn(btn)
    if not is_uicomponent(btn) then
        out("The button passed to populate_my_button is not a valid UIC! We're probably calling these functions at the wrong time")
        return
    end
    local char_cqi = cm:get_campaign_ui_manager():get_char_selected_cqi()
    if not char_cqi or char_cqi == -1 then
        out("No character is selected")
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
    local char = cm:get_character_by_cqi(cm:get_campaign_ui_manager():get_char_selected_cqi())

    -- Only set hero_to_embed if the character is not embedded, and is not a lord
    if not (char:is_embedded_in_military_force() or char:has_military_force()) then
        out("Char is not embedded, and is not a general.")
        hero_to_embed = char
    end
end

-- Embeds hero_to_embed into the selected army by performing a 'refresh' of the units
local function handle_selected_army(context)
    local lord = context:character()
    -- If there is no hero_to_embed, return.
    if hero_to_embed == nil then
        return
    end

    -- Copy data all non-lord/non-hero units in the army and remove them
    local mf = lord:military_force()
    local units_to_re_add = {} 
    local ul = mf:unit_list()

    for i=0,ul:num_items() - 1 do 
        local cur = ul:item_at(i)
        if cur:unit_class() ~= 'com' then
            table.insert(units_to_re_add, {
                cqi = cur:command_queue_index(),
                key = cur:unit_key(),
                experience_level = cur:experience_level(),
                strength =  cur:percentage_proportion_of_full_strength(),
                purchased_effects = cur:get_unit_purchased_effects()
            })
            cm:remove_unit_from_character(
                cm:char_lookup_str(mf:general_character()),
                cur:unit_key()
            )
        end
    end

    -- Embed hero_to_embed into the army
    cm:embed_agent_in_force(hero_to_embed, mf)

    -- Add the units back into the army, and set their experience and HP at each step
    local num_units = mf:unit_list():num_items()
    for i, unit in ipairs(units_to_re_add) do
        cm:grant_unit_to_character(
            cm:char_lookup_str(mf:general_character()),
            unit.key
        )
        local u = mf:unit_list():item_at(i + num_units - 1)
        if(unit.experience_level ~= 0) then
            cm:add_experience_to_unit(u, unit.experience_level)
            cm:set_unit_hp_to_unary_of_maximum(u, unit.strength / 100)
        end
    end

    -- 'Deselect' the hero_to_embed
    hero_to_embed = nil

end

core:add_listener(
    "JarAdjArmiesCharSelected",
    "CharacterSelected",
    function(context)
        return context:character():faction():is_human()
    end,
    function()
        populate_btn(get_or_create_btn())
    end,
    true
)

core:add_listener(
    "JarAdjArmiesArmySelected",
    "CharacterSelected", 
    function(context)
        local char = context:character()
        return char:faction():is_human() and char:has_military_force()
    end,
    handle_selected_army,
    true
)

core:add_listener(
    "JarAdjArmiesBtnClicked",
    "ComponentLClickUp", 
    function(context)
        return context.string == "jar_test_button"
    end,
    handle_hero_selected,
    true
)
