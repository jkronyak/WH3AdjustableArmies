local mct = get_mct()

local mct_mod = mct:register_mod("jar_adjustable_armies")

mct_mod:set_title("40 Unit Armies", false)
mct_mod:set_description("Allows you to customize the maximum amount of units per army for the player and AI.", false)

local mct_section = mct_mod:get_section_by_key("default")
mct_section:set_localised_text("Options", false)
mct_section:set_option_sort_function("index_sort")

local option_army_size = mct_mod:add_new_option("army_size", "slider")
option_army_size:set_text("Army Size")
option_army_size:set_tooltip_text("Warning: Changing this setting for an on-going campaign may cause stability issues or crashes. Lowering this setting for an on-going campaign may cause you to lose units. Requires reload to take effect.\n\nEach step modifies the maximum army size by 1.\nRange: [20,40]")
option_army_size:slider_set_min_max(20, 40)
option_army_size:slider_set_step_size(1)
option_army_size:set_default_value(40)

local option_auto_refresh = mct_mod:add_new_option("auto_refresh", "checkbox")
option_auto_refresh:set_text("Auto Refresh Army")
option_auto_refresh:set_tooltip_text("Automatically 'refreshes' an army when one of its heroes gains a new mount. This will fix the issue where a hero does not appear in battle after gaining a mount.\n\nSee workshop page for limitations.")
option_auto_refresh:set_default_value(true)

local option_dev_logging = mct_mod:add_new_option("dev_logging", "checkbox")
option_dev_logging:set_text("Developer Logging")
option_dev_logging:set_tooltip_text("Enables custom logging to jar_adjustable_armies.txt in the data folder.")
option_dev_logging:set_default_value(false)