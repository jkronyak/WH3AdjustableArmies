local mct = get_mct()

local mct_mod = mct:register_mod("custom_army_units_size")

mct_mod:set_title("40 Unit Armies", false)
mct_mod:set_description("Allows you to customize the maximum amount of units per army for the player and AI.", false)

local mct_section = mct_mod:get_section_by_key("default")
mct_section:set_localised_text("Options", false)
mct_section:set_option_sort_function("index_sort")

local option_army_size = mct_mod:add_new_option("army_units_size", "slider")
option_army_size:set_text("Army Size")
option_army_size:set_tooltip_text("Warning: Changing this setting for an on-going campaign may cause stability issues or crashes. Lowering this setting for an on-going campaign may cause you to lose units or crash.\n\nEach step modifies the maximum army size by 1.\nRange: [20,40]")
option_army_size:slider_set_min_max(20, 40)
option_army_size:slider_set_step_size(1)
option_army_size:set_default_value(40)

local option_refresh_on_anc_gained = mct_mod:add_new_option("refresh_on_anc_gained", "checkbox")
option_army_size:set_text("Auto Refresh Army")
option_army_size:set_tooltip_text("Automatically 'refreshes' an army when one of the heroes gains an ancillary.")
option_army_size:set_default_value(true)