
local settings = { 
    army_size = 40,
    dev_logging = false,
    force_siege_assault = true,
    force_siege_assault_turns = 3
}

local mr = assert(_G.memreader)
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

------------- [Army Size] -------------
local address_mapping = {
    -- UI / Player limits
    player_limit_1        = { address = 0x0221984F, offset = -1 },
    ai_limit              = { address = 0x02219860, offset = 0 },
    player_limit_2        = { address = 0x0221988F, offset = -1 },
    player_limit_3        = { address = 0x022198A0, offset = 0 },
    ui_variant_1          = { address = 0x02AD46A9, offset = 1},
    ui_variant_2          = { address = 0x02AD46B5, offset = 1 },

    -- Not sure
    byte_patch            = { address = 0x0198C09F, offset = -1 },

    exc_panel_1           = { address = 0x01B49DB4, offset = 0 },
    exc_panel_2           = { address = 0x01B49DC5, offset = 1},

    -- Loading
    loading_1             = { address = 0x02212622, offset = 2 },
    loading_2             = { address = 0x0221262E, offset = -2 },
    loading_3             = { address = 0x027E5A23, offset = -1 },
    loading_4             = { address = 0x027E5A2F, offset = -1 },

    -- Stability
    stability_1           = { address = 0x0220A48C, offset = 0 },
    stability_2           = { address = 0x0220A498, offset = 0 },
    stability_3           = { address = 0x0220ACCB, offset = -1 },
    stability_4           = { address = 0x0220ACD7, offset = -1 },
    stability_5           = { address = 0x02229E0D, offset = 1 },
    stability_6           = { address = 0x02229E19, offset = 1 },
    stability_7           = { address = 0x024C9FBB, offset = -1 },
    stability_8           = { address = 0x024C9FC7, offset = -1 },
    stability_9           = { address = 0x029256C7, offset = -1 },
    stability_10          = { address = 0x029256D3, offset = -1 },
    stability_11          = { address = 0x02A8F670, offset = 0 },
    stability_12          = { address = 0x02A8F67C, offset = 0},
    stability_13          = { address = 0x02ADD220, offset = 0 },
    stability_14          = { address = 0x02ADD22C, offset = 0 },
    stability_15          = { address = 0x02843308, offset = 0 },
    stability_16          = { address = 0x02843314, offset = 0 },
    stability_17          = { address = 0x02399041, offset = 1 },
    stability_18          = { address = 0x0239904D, offset = 1 },
    stability_19          = { address = 0x01C04506, offset = 0},
    stability_20          = { address = 0x01C04512, offset = 0 },

    -- Recruit
    recruit_chaos_realm   = { address = 0x02ADE45A, offset = 2 },
    recruit_immortal_emp  = { address = 0x02ADE0D3, offset = -1 }
}

function set_addresses()
    local base = mr.base -- ex: 0x0000000140000000
    local size = settings.army_size
    for name, addr in pairs(address_mapping) do
        Log(string.format("Updating %s (0x%x %d) to %d", name, addr.address, addr.offset, size))
        mr.write(mr.add(base, addr.address), addr.offset, mr.uint32(size))
    end
end

cm:add_loading_game_callback(
    function()
        Log("[CLBK] add_loading_game_callback")
        set_addresses()
    end
)

------------- [Infinite Siege Fix] -------------
local function handle_char_besieges(region)
    Log("[FUNC] handle_char_besieges", region:name())
    local besieging_char = region:garrison_residence():besieging_character()
    local cur_siege_tbl = cm:get_saved_value('jar_siege_tbl')

    local f = besieging_char:faction():name()
    local turn_num = cm:turn_number()
    local besieger_cqi = besieging_char:cqi()

    -- If cur_siege_tbl is not set, then simply add the faction and the siege entry
    -- Case 1: table does not exist, so add the faction and siege entry
    if cur_siege_tbl == nil then
        Log("cur_siege_tbl is nil")
        local tbl = { [f] = { [besieger_cqi] = { ["turn_started"] = turn_num, ["target_region"] = region:name() } } }
        cm:set_saved_value('jar_siege_tbl', tbl)

    -- Case 2: table exists and faction is in it, so add/overwrite the siege entry
    elseif cur_siege_tbl[f] ~= nil then
        Log(f, "is already in cur_siege_tbl")
        cur_siege_tbl[f][besieger_cqi] = { ["turn_started"] = turn_num, ["target_region"] = region:name() }
        cm:set_saved_value('jar_siege_tbl', cur_siege_tbl)
    -- Case 3: table exists and faction is not in it, so add the faction and siege entry
    else
        Log(f, "is not in cur_siege_tbl")
        cur_siege_tbl[f] = { [besieger_cqi] = { ["turn_started"] = turn_num, ["target_region"] = region:name() } }
        cm:set_saved_value('jar_siege_tbl', cur_siege_tbl)
    end
end

local function handle_faction_force_siege(faction)
    Log("[FUNC] handle_faction_force_siege", faction:name())
    local f = faction:name()
    local cur_turn = cm:turn_number()
    local n = settings.force_siege_assault_turns
    local siege_tbl = cm:get_saved_value('jar_siege_tbl')
    local f_entry = siege_tbl[f]
    if faction:is_dead() then
        Log("faction is dead, removing entry")
        f_entry = nil
    end
    for key, value in pairs(f_entry) do
        local besieger_char = cm:get_character_by_cqi(key)
        if (not besieger_char) or (besieger_char == nil) or (is_null(besieger_char)) or (not besieger_char:is_besieging()) then
            Log("character with cqi", key, "is no longer besieging", value.target_region)
            f_entry[key] = nil
            if is_empty_table(f_entry) then
                f_entry = nil
            end
        elseif (cur_turn - value.turn_started) >= n then
            Log("siege length has met threshold:", cur_turn - value.turn_started, ">=", n)
            local besieger_lookup_str = cm:char_lookup_str(key)
            local r = value.target_region
            local reg = cm:get_region(r)
            Log("healing garrison")
            cm:heal_garrison(reg:cqi())
            local g_cmd = cm:get_garrison_commander_of_region(reg)
            if g_cmd == nil or g_cmd:is_null_interface() then
                Log("garrison commander is still nil, cannot force attack")
            else
                local g_cmd_lookup_str = cm:char_lookup_str(g_cmd)
                Log("forcing siege assault")
                cm:attack(besieger_lookup_str, g_cmd_lookup_str, false, true)
            end
        end
    end
    cm:set_saved_value('jar_siege_tbl', siege_tbl)
end

core:add_listener(
    "JarAdjArmiesCharBesieges",
    "CharacterBesiegesSettlement",
    function(context)
        return (
            not context:region():garrison_residence():besieging_character():faction():is_human()
            and settings.force_siege_assault
        )
    end,
    function(context)
        Log("[LSTR] JarAdjArmiesCharBesieges")
        local r = context:region()
        handle_char_besieges(r)
    end,
    true
)

core:add_listener(
    "JarAdjArmiesFactionTurnNormal",
    "FactionBeginTurnPhaseNormal",
    function(context)
        local f = context:faction():name()
        local siege_tbl = cm:get_saved_value('jar_siege_tbl')
        return (
            (siege_tbl ~= nil)
            and (siege_tbl[f] ~= nil)
            and (not is_empty_table(siege_tbl[f]))
            and (settings.force_siege_assault)
        )
    end,
    function(context)
        Log("[LSTR] JarAdjArmiesFactionTurnNormal")
        local f = context:faction()
        handle_faction_force_siege(f)
    end,
    true
)

------------- [MCT] -------------
core:add_listener(
    "JarAdjArmiesMctInitialized", "MctInitialized", true, function(context)
        Log("[LSTR] JarAdjArmiesMctInitialized")
        local mct = context:mct()
        local my_mod = mct:get_mod_by_key("jar_adjustable_armies")
        settings.army_size = my_mod:get_option_by_key("army_size"):get_finalized_setting()
        settings.dev_logging = my_mod:get_option_by_key("dev_logging"):get_finalized_setting()
        settings.force_siege_assault = my_mod:get_option_by_key("force_siege_assault"):get_finalized_setting()
        settings.force_siege_assault_turns = my_mod:get_option_by_key("force_siege_assault_turns"):get_finalized_setting()
    end, true
)

core:add_listener(
    "JarAdjArmiesMctOptFinalized", "MctOptionSettingFinalized", true, function(context)
        Log("[LSTR] JarAdjArmiesMctOptFinalized")
        settings[context:option():get_key()] = context:setting()
    end, true
)