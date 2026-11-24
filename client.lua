-- Client-side ox_inventory facade. Read-only exports delegate to Nord's
-- own client snapshot. No second NUI or inventory state is created.
local function nord(method, ...)
    if GetResourceState('nord_inventory') ~= 'started' then return nil end
    local args = table.pack(...)
    local ok, value = pcall(function()
        return exports.nord_inventory[method](exports.nord_inventory, table.unpack(args, 1, args.n))
    end)
    if not ok then
        if Config.Debug then print(('[ox_inventory compat] client %s: %s'):format(method, tostring(value))) end
        return nil
    end
    return value
end
exports('Search', function(mode, item, metadata)
    local result = nord('Search', mode, item, metadata)
    return result ~= nil and result or ((mode == 'count' or mode == 2) and 0 or {})
end)
exports('GetPlayerItems', function() return nord('GetPlayerItems') or {} end)
exports('GetPlayerWeight', function() return nord('GetPlayerWeight') or 0 end)
exports('GetPlayerMaxWeight', function() return nord('GetPlayerMaxWeight') or 0 end)
exports('GetItemCount', function(item, metadata, strict)
    return nord('GetItemCount', item, metadata, strict) or 0
end)
exports('GetSlotWithItem', function(item, metadata, strict)
    return nord('GetSlotWithItem', item, metadata, strict)
end)
exports('GetSlotsWithItem', function(item, metadata, strict)
    return nord('GetSlotsWithItem', item, metadata, strict) or {}
end)
exports('GetSlotIdWithItem', function(item, metadata, strict)
    return nord('GetSlotIdWithItem', item, metadata, strict)
end)
exports('GetSlotIdsWithItem', function(item, metadata, strict)
    return nord('GetSlotIdsWithItem', item, metadata, strict) or {}
end)
-- Client openInventory/useItem are deliberately not remapped to an unauthenticated
-- event: Nord's server validates opening and use. Callers should use Nord native
-- flows or a server-side, permission-checked integration instead.
exports('openInventory', function()
    print('^3[ox_inventory compat]^7 client openInventory requires server-side authorized integration')
    return false
end)
exports('useItem', function() return false end)
exports('closeInventory', function() return false end)
exports('setStashTarget', function() return false end)
