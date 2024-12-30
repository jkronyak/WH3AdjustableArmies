
-- -- -- 40
-- -- -- 1012

-- -- local cqi_1 = 40
-- -- local cqi_2 = 1012

-- -- cm:seek_exchange(cm:char_lookup_str(cqi_1), cm:char_lookup_str(cqi_2), false)

-- core:remove_listener("JarAdjArmiesExchangePanelOpened")

-- core:add_listener(
--     "JarAdjArmiesExchangePanelOpened",
--     "PanelOpenedCampaign",
--     function(context) 
--         return context.string == 'unit_exchange'
--     end,
--     function(context)
--         console_print("First")

--         local p2_cco = cco("CcoComponent", "main_units_panel_2")

--         local result = p2_cco:Call(string.format([=[
--             (
--                 unit_list = ChildList.FirstContext(Id == 'units').ChildList
--                 .Transform(ContextsList).Filter( (x) => IsOfType(x, 'CcoCampaignUnit'))

--             )
--             =>
--             unit_list

        
--         ]=]))

--         for _, v in pairs(result) do
--             console_print(tostring(v:Call("UniqueUiId")))
--         end
--     end,
--     true
-- )

core:remove_listener("JarAdjArmiesExchangeBtnClicked")

core:add_listener(
    "JarAdjArmiesExchangeBtnClicked", 
    "ComponentLClickUp",
    function(context) return context.string == "jar_exchange_btn" end,
    function() 
        -- Log("[LSTR] JarAdjArmiesExchangeBtnClicked")
        console_print("aaaah")
        local p2_cco = cco("CcoComponent", "main_units_panel_2")
        local result = p2_cco:Call(string.format([=[
            (
                unit_list = ChildList.FirstContext(Id == 'units').ChildList
                .Filter( (x) => x.IsSelected == true)
                .Transform(ContextsList).Filter( (x) => IsOfType(x, 'CcoCampaignUnit'))

            )
            =>
            unit_list

        
        ]=]))
        console_print(tostring(result))
        for _, v in pairs(result) do
            local cqi = v:Call("UniqueUiId")
            local key = v:Call("UnitRecordContext.Key")
            local experience_level = v:Call("ExperienceLevel")
            local strength = v:Call("HealthPercent")
            local purchased_effects = v:Call("PurchasedEffectsList")
            local purchased_effects_key_list = { }
            console_print(tostring(cqi))
            console_print(tostring(key))
            console_print(tostring(experience_level))
            console_print(tostring(strength))
            console_print(tostring(#purchased_effects))
            for _, v2 in pairs(purchased_effects) do
                console_print(tostring(v2:Call("Key")))
                table.insert(purchased_effects_key_list, v2:call("Key"))
            end

        end
    end,
    true
)

local cco_unit = cco("CcoCampaignUnit", 632)
console_print(cco_unit:Call("UnitRecordContext.Key"))