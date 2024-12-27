local function fetch_mount_ancillaries()
    local cco_return = cco("CcoCampaignRoot", ""):Call("DefaultDatabaseRecord('CcoAncillaryRecord')"):Call(
        "RecordList.Filter(CategoryContext.Key=='mount')"
    )
    local tbl = {}
    for _, v in pairs(cco_return) do
        local key = v:Call("Key")
        tbl[key] = true
    end
    return tbl
end

local function fetch_unit_purchasable_effects_resource_data(unit_purchasable_effect_key)
    local cco_root = cco("CcoCampaignRoot", "")
    local cco_unit_pe = cco_root:Call("DefaultDatabaseRecord('CcoUnitPurchasableEffectRecord')")
    local v = cco_unit_pe:Call("RecordList.FirstContext(Key==\"" .. unit_purchasable_effect_key .. "\")")

    -- local key = v:Call("Key") or "nil"
    -- local resource_name = v:Call("ResourceName")
    -- local cost_id = v:Call("CostContext.Id")
    local cost_amt = v:Call("ResourceCost") or 0
    local treasury_cost = v:Call("CostContext.TreasuryCost") or 0
    local resource_key = v:Call("CostContext.PooledResourceCostsList[0].ResourceKey")

    local factor = "other" -- CCO does not provide the keys for the pooled_resource_factors

    return resource_key, factor, cost_amt, treasury_cost

end

return {
    fetch_mount_ancillaries = fetch_mount_ancillaries,
    fetch_unit_purchasable_effects_resource_data = fetch_unit_purchasable_effects_resource_data
}
