---@class custom_army_units_size
local army_size = 40

local custom_army_units_size = {
    mr = assert(_G.memreader),
}

function custom_army_units_size:init()

    self.new_army_limit = self.mr.uint32(army_size)
     -- 14 00 00 00 3B C1 0F 47 C1 48 83 C4 20 5B C3 B8 14 00 00 00 48 83 C4 20 5B C3 CC CC CC CC CC CC CC CC CC CC
    self.player_army_size_offset = 0x1F5973C
    self.ai_army_size_offset = self.player_army_size_offset + 0x10
    self.exchange_panel_ui_offset = 0x1F1AB0C -- same signature as above, why?
    self.unknown_20_offset = self.exchange_panel_ui_offset + 0x10
end

function custom_army_units_size:set()
    local base_ptr = self.mr.base -- ex: 0x0000000140000000
    self.mr.write(base_ptr, self.player_army_size_offset, self.new_army_limit)
    self.mr.write(base_ptr, self.ai_army_size_offset, self.new_army_limit)
    self.mr.write(base_ptr, self.exchange_panel_ui_offset, self.new_army_limit)
    -- self.mr.write(base_ptr, self.unknown_20_offset, self.new_army_limit)
end

-- Executes on MCT initialization (before campaign load)
core:add_listener(
    "custom_army_units_size_mct",
    "MctInitialized",
    true,
    function(context)
        local mct = context:mct()
        local my_mod = mct:get_mod_by_key("custom_army_units_size")
        army_size = my_mod:get_option_by_key("army_units_size"):get_finalized_setting()
    end,
    true
)

-- Executes on the first tick of each campaign load
cm:add_loading_game_callback(function()
    custom_army_units_size:init()
    custom_army_units_size:set()
end)
