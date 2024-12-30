--[[
Known Issues:
*   When a hero gets embedded via script, the army effect (ex. replenishment rate) only applies 
    on reload or next turn. This does not always occur. 
*   Units do not retain their progress to the next experience level
*   Unable to embed a hero into an army which is full of heroes (limitation of cm:embed_agent_in_force())
*   Unit upgrades will not be refunded and reapplied for custom upgrades. This would require storing the 
    unit_purchasable_effect, factor, resource, resource cost, and treasury cost for
    every modded upgrade. 

]] --
-- [Settings] --
local settings = {army_size = 40, auto_refresh = true, dev_logging = true}

-- [Logging] --
local log_override = false
local function Log(...)
    if settings.dev_logging or log_override then
        local arg = {...}
        local file = io.open("_adjustable_armies.jar.log", "a")
        if not file then
            out("Unable to create/open log file")
            return
        end
        local t = os.date("%H:%M:%S")
        file:write("[" .. t .. "] ")
        for _, v in pairs(arg) do
            if type(v) == "string" then
                file:write(v)
            else
                file:write(tostring(v))
            end
            file:write(" ")
        end
        file:write("\n")
        file:close()
    end
end

core:add_listener(
    "JarAdjArmiesMctInitialized", "MctInitialized", true, function(context)
        Log("[LSTR] JarAdjArmiesMctInitialized")
        local mct = context:mct()
        local my_mod = mct:get_mod_by_key("jar_adjustable_armies")
        settings.army_size = my_mod:get_option_by_key("army_size"):get_finalized_setting()
        settings.auto_refresh = my_mod:get_option_by_key("auto_refresh"):get_finalized_setting()
        settings.dev_logging = my_mod:get_option_by_key("dev_logging"):get_finalized_setting()
    end, true
)

core:add_listener(
    "JarAdjArmiesMctOptFinalized", "MctOptionSettingFinalized", true, function(context)
        Log("[LSTR] JarAdjArmiesMctOptFinalized")
        settings[context:option():get_key()] = context:setting()
    end, true
)

-- [Army Size] --
local mr = assert(_G.memreader)
local new_army_limit, player_army_size_offset, exchange_panel_ui_offset, ai_army_size_offset
-- local unknown_20_offset = nil

function init_addresses()
    Log("[FUNC] init_addresses")
    new_army_limit = mr.uint32(settings.army_size)
    player_army_size_offset = 0x1F5973C
    exchange_panel_ui_offset = 0x1F1AB0C
    ai_army_size_offset = player_army_size_offset + 0x10
    -- unknown_20_offset = exchange_panel_ui_offset + 0x10
end

function set_addresses()
    Log("[FUNC] set_addresses")
    local base_ptr = mr.base -- ex: 0x0000000140000000
    mr.write(base_ptr, player_army_size_offset, new_army_limit)
    mr.write(base_ptr, ai_army_size_offset, new_army_limit)
    mr.write(base_ptr, exchange_panel_ui_offset, new_army_limit)
    -- self.mr.write(base_ptr, self.unknown_20_offset, self.new_army_limit)
end

cm:add_loading_game_callback(
    function()
        Log("[CLBK] add_loading_game_callback")
        init_addresses()
        set_addresses()
    end
)

-- [User Interface] --
local function get_or_create_btn()
    Log("[FUNC] get_or_create_btn")
    local ui_button_parent = find_uicomponent(
        core:get_ui_root(), "hud_campaign", "info_panel_holder", "primary_info_panel_holder", "info_panel_background",
            "CharacterInfoPopup", "character_info_parent", "porthole_top"
    )
    if not is_uicomponent(ui_button_parent) then
        Log("Get or create button was called, but we couldn't find the parent!")
        return
    end
    local button_name = "jar_test_button"
    local existing_button = find_uicomponent(ui_button_parent, button_name)
    if is_uicomponent(existing_button) then
        return existing_button
    else
        local btn = UIComponent(
            ui_button_parent:CreateComponent(button_name, "ui/templates/square_medium_button.twui.xml")
        )
        btn:SetImagePath("ui/skins/default/button_basic_active_purple.png")
        btn:SetCanResizeCurrentStateImageHeight(0, true)
        btn:SetCanResizeCurrentStateImageWidth(0, true)
        btn:SetCanResizeHeight(true)
        btn:SetCanResizeWidth(true)
        btn:ResizeCurrentStateImage(0, 32, 32)
        btn:Resize(32, 32, true)
        return btn
    end
end

local function populate_btn(btn)
    Log("[FUNC] populate_btn")
    if not is_uicomponent(btn) then
        Log("btn is falsy")
        return
    end
    local char_cqi = cm:get_campaign_ui_manager():get_char_selected_cqi()
    if not char_cqi or char_cqi == -1 then
        Log("No character is selected")
        return
    end
    local char = cm:get_character_by_cqi(char_cqi)
    Log("char:forenamesurename" .. char:get_forename() .. char:get_surname())
    Log("char:is_embedded_in_military_force()" .. tostring(char:is_embedded_in_military_force()))
    Log("char:has_military_force()" .. tostring(char:has_military_force()))

    if not (char:is_embedded_in_military_force() or char:has_military_force()) then
        Log("setting as active")
        btn:SetState("active")
        btn:SetVisible(true)
        Log(hero_to_embed_cqi)
        if hero_to_embed_cqi == nil then
            Log("hero_to_embed_cqi == nil")
            btn:SetTooltipText(
                "Click to select this hero. The hero will be embedded in the next owned army that you left click on.",
                    true
            )
            btn:SetImagePath("ui/skins/default/button_basic_active_purple.png")
        elseif hero_to_embed_cqi == char_cqi then
            Log("hero_to_embed_cqi == char_cqi")
            btn:SetTooltipText("Click to deselect this hero.", true)
            btn:SetImagePath("ui/skins/default/button_basic_selected_purple.png")
        else
            Log("hero_to_embed_cqi ~= nil")
            btn:SetState("inactive")
            btn:SetTooltipText("Another hero is already selected.", true)
            btn:SetImagePath("ui/skins/default/button_basic_inactive_purple.png")
        end
    else
        Log("setting as inactive")
        btn:SetState("inactive")
        btn:SetVisible(false)
        btn:SetTooltipText("Do not click me!", true)
        btn:SetImagePath("ui/skins/default/button_basic_inactive_purple.png")
    end
end

-- [Data] --
local throt_instability_prefix = "wh2_dlc16_throt_flesh_lab_instability"
local db_data = require("./db_data")

local mount_ancillaries_tbl = {}
local fetch_unit_purchasable_effects_resource_data = db_data.fetch_unit_purchasable_effects_resource_data

cm:add_first_tick_callback(function() mount_ancillaries_tbl = db_data.fetch_mount_ancillaries() end)

-- [Logic] --
hero_to_embed_cqi = nil

-- Receives unit_purchasable_effect upgrade, faction faction, unit unit
-- Grants the required resource and treasury amounts to the faction and purchases the upgrade.
local function reapply_unit_upgrade(upgrade, faction, unit)
    local cur_key = upgrade:record_key()

    Log("handling upgrade", cur_key)
    local resource_key, factor, resource_cost, treasury_cost = fetch_unit_purchasable_effects_resource_data(cur_key)
    Log("resource_key", resource_key)
    Log("factor", factor)
    Log("resource_cost", resource_cost)
    Log("treasury_cost", treasury_cost)
    Log("unit num upgrades", unit:get_unit_purchased_effects():num_items())

    -- Add the necessary resource and treasury amounts and purchase the effect.
    if tonumber(treasury_cost) ~= 0 then cm:treasury_mod(faction:name(), -tonumber(treasury_cost)) end

    -- Get the pooled_resource total before buying the upgrades
    local before_amount = 0
    if resource_key and resource_cost ~= 0 then
        local spent_b, gained_b = cm:get_total_pooled_resource_changed_for_faction(faction:name(), resource_key)
        before_amount = gained_b - spent_b
        cm:faction_add_pooled_resource(faction:name(), resource_key, factor, -tonumber(resource_cost) + (30 * unit:get_unit_purchased_effects():num_items()))
    end
    Log("before_amount", before_amount)

    cm:faction_purchase_unit_effect(faction, unit, upgrade)

    -- Get the pooled_resource total before after buying the upgrades and adding the refund. 
    -- Adjust the amount to be the same as before.
    local after_amount = 0
    if resource_key and resource_cost ~= 0 then
        local spent_a, gained_a = cm:get_total_pooled_resource_changed_for_faction(faction:name(), resource_key)
        after_amount = gained_a - spent_a
    end
    Log("after_amount", after_amount)

    local correction_amount = -(after_amount - before_amount)
    Log("correction_amount", correction_amount)

    if correction_amount ~= 0 then
        cm:faction_add_pooled_resource(faction:name(), resource_key, factor, correction_amount)
    end

end

-- Receives Character lord_char and Character hero_char
-- Embeds or re-embeds the hero_char into the military_force of lord_char by:
-- 1.   Copying the data for non-lord and non-hero units
-- 2.   Disbanding all of the non-lord and non-hero units
-- 3.   Embedding the hero into the army (now that it has room)
-- 4.   Recruit all of the units back into the army, adding experience, health state, and vanilla
--      upgrades at each step.
local function refresh_army_with_hero(lord_char, hero_char)
    Log("[FUNC] refresh_army_with_hero")
    -- If there is no hero_char, return.
    if not hero_char or hero_char:is_null_interface() then
        Log("hero_char is falsy or is the null interface")
        return
    end

    local faction = lord_char:faction()
    local mf = lord_char:military_force()

    -- If the hero is embedded in the army, teleport them out first.
    -- Should be true if called from CharacterAncillaryGained_listener
    if hero_char:is_embedded_in_military_force() then
        Log("hero_char is embedded in a military force")
        local x, y = cm:find_valid_spawn_location_for_character_from_position(
            faction:name(), lord_char:logical_position_x(), lord_char:logical_position_y(), false, 0
        )
        Log("teleport x,y is " .. x .. "," .. y)
        cm:teleport_to(cm:char_lookup_str(lord_char), x, y)
    end

    if mf:unit_list():num_items() >= settings.army_size then
        Log("Selected army is full")
        hero_to_embed_cqi = nil
        return
    end

    -- Copy data all non-lord/non-hero units in the army and remove them
    local ul = mf:unit_list()
    local units_to_re_add = {}

    for i = 0, ul:num_items() - 1 do
        local cur = ul:item_at(i)
        if cur:unit_class() ~= "com" then
            table.insert(
                units_to_re_add, {
                    cqi = cur:command_queue_index(),
                    key = cur:unit_key(),
                    experience_level = cur:experience_level(),
                    strength = cur:percentage_proportion_of_full_strength(),
                    purchased_effects = cur:get_unit_purchased_effects()
                }
            )
            cm:remove_unit_from_character(cm:char_lookup_str(mf:general_character()), cur:unit_key())
        end
    end

    -- Embed hero_to_embed into the army
    cm:embed_agent_in_force(hero_char, mf)

    -- Add the units back into the army, and set their experience and HP at each step
    local num_units = mf:unit_list():num_items()
    for i, og_unit in ipairs(units_to_re_add) do
        cm:grant_unit_to_character(cm:char_lookup_str(mf:general_character()), og_unit.key)
        local new_unit = mf:unit_list():item_at(i + num_units - 1)
        if og_unit.strength ~= 100 then cm:set_unit_hp_to_unary_of_maximum(new_unit, og_unit.strength / 100) end
        if og_unit.experience_level ~= 0 then cm:add_experience_to_unit(new_unit, og_unit.experience_level) end

        local throt_instability_list = {}

        if og_unit.purchased_effects:num_items() > 0 then
            for j = 0, og_unit.purchased_effects:num_items() - 1 do
                local cur_upgrade = og_unit.purchased_effects:item_at(j)
                local cur_key = cur_upgrade:record_key()

                if string.find(cur_key, throt_instability_prefix) then
                    Log("Found throt instability unit_purchasable_effect, adding to list and skipping")
                    table.insert(throt_instability_list, cur_upgrade)
                else
                    reapply_unit_upgrade(cur_upgrade, faction, new_unit)
                end

            end
            for _, cur_upgrade in pairs(throt_instability_list) do
                reapply_unit_upgrade(cur_upgrade, faction, new_unit)

            end
        end

    end

    -- 'Deselect' the hero_to_embed_cqi
    hero_to_embed_cqi = nil
end

-- Sets/unsets the cqi variable for the hero to embed
local function handle_hero_selected()
    Log("[FUNC] handle_hero_selected")
    if hero_to_embed_cqi ~= nil then
        Log("hero_to_embed_cqi is not nil, deselecting")
        hero_to_embed_cqi = nil
        return
    end
    local char = cm:get_character_by_cqi(cm:get_campaign_ui_manager():get_char_selected_cqi())
    -- Only set hero_to_embed_cqi if the character is not embedded, and is not a lord
    if not (char:is_embedded_in_military_force() or char:has_military_force() or char:is_wounded()) then
        Log("setting hero_to_embed_cqi to " .. char:cqi())
        hero_to_embed_cqi = char:cqi()
    end
end

-- Embeds hero_to_embed into the selected army by performing a 'refresh' of the units
local function handle_army_selected(context)
    Log("[FUNC] handle_army_selected")
    if not hero_to_embed_cqi then
        Log("hero_to_embed_cqi is nil")
        return
    end
    local hero = cm:get_character_by_cqi(hero_to_embed_cqi)
    refresh_army_with_hero(context:character(), hero)
end

-- LuaFormatter off
core:add_listener(
    "JarAdjArmiesCharSelected",
    "CharacterSelected",
    function(context)
        return (context:character():faction():is_human())
    end,
    function()
        Log("[LSTR] JarAdjArmiesCharSelected")
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
    function(context)
        Log("[LSTR] JarAdjArmiesArmySelected")
        handle_army_selected(context)
    end,
    true
)

core:add_listener(
    "JarAdjArmiesBtnClicked",
    "ComponentLClickUp",
    function(context) return context.string == "jar_test_button" end,
    function()
        Log("[LSTR] JarAdjArmiesBtnClicked")
        handle_hero_selected()
        populate_btn(get_or_create_btn())
    end,
    true
)

core:add_listener(
    "JarAdjArmiesCharAncGained",
    "CharacterAncillaryGained",
    function(context)
        return (
            settings.auto_refresh and
            context:character():faction():is_human() and
            context:character():is_embedded_in_military_force() and
            mount_ancillaries_tbl[context:ancillary()])
    end,
    function(context)
        Log("[LSTR] JarAdjArmiesCharAncGained")
        local hero = context:character()
        refresh_army_with_hero(hero:embedded_in_military_force():general_character(), hero)
    end,
    true
)

cm:add_first_tick_callback(
    function()
        local human_faction_keys = cm:get_human_factions()
        for _, key in ipairs(human_faction_keys) do
            if cm:are_pooled_resources_tracked_for_faction(key) then return end
            cm:start_pooled_resource_tracker_for_faction(key)
        end
    end
)

-- LuaFormatter on
