local mct = get_mct()

local mct_mod = mct:register_mod("jar_adjustable_armies")

mct_mod:set_title("40 Unit Armies", false)
mct_mod:set_description("Allows you to customize the maximum amount of units per army for the player and AI.", false)

local mct_section = mct_mod:get_section_by_key("default")
mct_section:set_localised_text("Options", false)
mct_section:set_option_sort_function("index_sort")

local option_army_size = mct_mod:add_new_option("army_size", "slider")
option_army_size:set_text("Player Army Size")
option_army_size:set_tooltip_text("Warning: Changing this setting for an on-going campaign may cause stability issues or crashes. Lowering this setting for an on-going campaign may cause you to lose units. Requires reload to take effect.\n\nEach step modifies the maximum army size by 1.\nRange: [20,40]")
option_army_size:slider_set_min_max(20, 40)
option_army_size:slider_set_step_size(1)
option_army_size:set_default_value(40)

local option_ai_army_size = mct_mod:add_new_option("ai_army_size", "slider")
option_ai_army_size:set_text("AI Army Size")
option_ai_army_size:set_tooltip_text("Warning: Using a different army size for the player and AI is experimental, and may not work in all cases. Use at your own discretion. Each step modifies the maximum army size by 1.\nRange: [20,40]")
option_ai_army_size:slider_set_min_max(20, 40)
option_ai_army_size:slider_set_step_size(1)
option_ai_army_size:set_default_value(40)

local option_dev_logging = mct_mod:add_new_option("dev_logging", "checkbox")
option_dev_logging:set_text("Developer Logging")
option_dev_logging:set_tooltip_text("Enables custom logging to jar_adjustable_armies.txt in the data folder.")
option_dev_logging:set_default_value(false)

local option_force_siege_assault = mct_mod:add_new_option("force_siege_assault", "checkbox")
option_force_siege_assault:set_text("Force Siege Assault")
option_force_siege_assault:set_tooltip_text("Forces besieging AI armies to assault the settlment after the set number of turns. This will fix the issue where an the AI will get stuck besieging a settlement indefinitely.")
option_force_siege_assault:set_default_value(true)

local option_force_siege_assault_turns = mct_mod:add_new_option("force_siege_assault_turns", "slider")
option_force_siege_assault_turns:set_text("Force Siege Assault Min Turns")
option_force_siege_assault_turns:set_tooltip_text("This setting configures the number of turns an army must be besieging a settlement before the assault will be forced. Note: If a faction has multiple ongoing sieges, sometimes only one will trigger per turn. The remaining sieges will then trigger on the following turn(s).")
option_force_siege_assault_turns:slider_set_min_max(1, 99)
option_force_siege_assault_turns:slider_set_step_size(1)
option_force_siege_assault_turns:set_default_value(3)