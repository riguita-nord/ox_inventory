-- ox_inventory API facade -> Nord Inventory (server).
-- Intentionally does not run an inventory database, NUI or independent item system.
local provider = 'nord_inventory'
local warned = {}

local function warn(id, detail)
    if not Config.WarnUnsupported or warned[id] then return end
    warned[id] = true
    print(('^3[ox_inventory -> nord_inventory]^7 %s'):format(detail))
end

local function invoke(method, ...)
    if GetResourceState(provider) ~= 'started' then
        warn('offline', 'Nord Inventory is not started')
        return false, 'nord_inventory_unavailable'
    end
    local args = table.pack(...)
    local ok, a, b, c = pcall(function()
        return exports[provider][method](exports[provider], table.unpack(args, 1, args.n))
    end)
    if not ok then
        warn(method, ('Export %s failed/unavailable: %s'):format(method, tostring(a)))
        return false, 'unsupported_export'
    end
    return true, a, b, c
end

local function read(method, ...)
    local ok, a, b, c = invoke(method, ...)
    if not ok then return nil end
    return a, b, c
end
local function mutation(method, ...)
    local ok, a, b = invoke(method, ...)
    if not ok then return false, b or a end
    return a, b
end
local function number(value) return math.max(0, tonumber(value) or 0) end
local function cleanSlot(item)
    if type(item) ~= 'table' then return item end
    local out = {}
    for k,v in pairs(item) do out[k] = v end
    out.metadata = out.metadata or out.info or {}
    out.count = tonumber(out.count or out.amount) or 0
    return out
end
local function cleanSlots(slots)
    if type(slots) ~= 'table' then return slots end
    local result = {}
    for k, item in pairs(slots) do result[k] = cleanSlot(item) end
    return result
end

exports('AddItem', function(inv, item, count, metadata, slot, cb)
    if type(slot) == 'function' and cb == nil then cb, slot = slot, nil end
    local ok, result = mutation('AddItem', inv, item, count or 1, metadata, slot)
    if type(cb) == 'function' then cb(ok, result); return end
    return ok, result
end)
exports('RemoveItem', function(inv, item, count, metadata, slot, ignoreTotal, strict)
    return mutation('RemoveItem', inv, item, count or 1, metadata, slot, ignoreTotal, strict)
end)
exports('CanCarryItem', function(inv, item, count, metadata)
    return read('CanCarryItem', inv, item, count or 1, metadata) == true
end)
exports('CanCarryWeight', function(inv, weight)
    local a, b = read('CanCarryWeight', inv, weight)
    return a == true, b or 0
end)
exports('CanCarryAmount', function(inv, item)
    return number(read('CanCarryAmount', inv, item))
end)
exports('CanSwapItem', function(inv, first, firstCount, second, secondCount)
    return read('CanSwapItem', inv, first, firstCount, second, secondCount) == true
end)
exports('GetInventory', function(inv, owner)
    local data = read('GetInventory', inv, owner)
    if type(data) == 'table' then data.items = cleanSlots(data.items) end
    return data
end)
exports('GetInventoryItems', function(inv, owner)
    return cleanSlots(read('GetInventoryItems', inv, owner))
end)
exports('GetItemCount', function(inv, item, metadata, strict)
    return number(read('GetItemCount', inv, item, metadata, strict))
end)
exports('GetItem', function(inv, item, metadata, returnsCount)
    return read('GetItem', inv, item, metadata, returnsCount)
end)
exports('Search', function(inv, mode, item, metadata)
    local value = read('Search', inv, mode, item, metadata)
    if value == nil then return (mode == 'count' or mode == 2) and 0 or {} end
    return value
end)
exports('GetSlot', function(inv, slot)
    return cleanSlot(read('GetSlot', inv, slot))
end)
exports('GetSlotWithItem', function(inv, item, metadata, strict)
    return cleanSlot(read('GetSlotWithItem', inv, item, metadata, strict))
end)
exports('GetSlotsWithItem', function(inv, item, metadata, strict)
    return cleanSlots(read('GetSlotsWithItem', inv, item, metadata, strict)) or {}
end)
exports('GetSlotIdWithItem', function(inv, item, metadata, strict)
    return read('GetSlotIdWithItem', inv, item, metadata, strict)
end)
exports('GetSlotIdsWithItem', function(inv, item, metadata, strict)
    return read('GetSlotIdsWithItem', inv, item, metadata, strict) or {}
end)
exports('GetEmptySlot', function(inv)
    return read('GetEmptySlot', inv)
end)
exports('GetSlotForItem', function(inv, item, metadata)
    return read('GetSlotForItem', inv, item, metadata)
end)
exports('Items', function(item)
    return read('Items', item)
end)
exports('SetMetadata', function(inv, slot, metadata)
    return mutation('SetMetadata', inv, slot, metadata)
end)
exports('GetMetadata', function(inv, slot)
    return read('GetMetadata', inv, slot)
end)
exports('SetMaxWeight', function(inv, weight)
    return mutation('SetMaxWeight', inv, weight)
end)
exports('SetSlotCount', function(inv, slots)
    return mutation('SetSlotCount', inv, slots)
end)
exports('ClearInventory', function(inv, keep)
    return mutation('ClearInventory', inv, keep)
end)
exports('RemoveInventory', function(inv)
    return mutation('RemoveInventory', inv)
end)
exports('RegisterStash', function(id, label, slots, weight, owner, groups, coords)
    return mutation('RegisterStash', id, label, slots, weight, owner, groups, coords)
end)
exports('openInventory', function(source, invType, data)
    return mutation('OpenInventory', source, invType, data)
end)
exports('forceOpenInventory', function(source, invType, data)
    -- Nord currently uses the same permission-aware open path for both exports.
    return mutation('forceOpenInventory', source, invType, data)
end)
exports('GetInventoryWeight', function(inv)
    local data = read('GetInventory', inv)
    return type(data) == 'table' and number(data.weight) or 0
end)
exports('GetInventoryMaxWeight', function(inv)
    local data = read('GetInventory', inv)
    return type(data) == 'table' and number(data.maxWeight) or 0
end)
exports('GetInventorySlots', function(inv)
    local data = read('GetInventory', inv)
    return type(data) == 'table' and number(data.slots) or 0
end)

-- IMPORTANT: Ox hooks use specific payloads, filters and hook IDs. Nord's
-- RegisterHook has a different contract and cannot be safely passed through.
-- Explicitly reject rather than returning a misleading success or bypassing
-- security / anti-duplication hooks.
exports('registerHook', function(event, callback, options)
    warn('hook_' .. tostring(event), ('ox hook "%s" needs a dedicated adapter; registration rejected'):format(tostring(event)))
    return nil
end)
exports('removeHooks', function(id)
    warn('removeHooks', 'removeHooks not supported because ox hooks are not registered')
    return false
end)

local function unsupported(name)
    exports(name, function(...)
        warn(name, ('ox export %s is not safely implemented; call rejected'):format(name))
        return false, 'unsupported_export'
    end)
end
for _, name in ipairs({
    'RegisterShop', 'CreateTemporaryStash', 'CustomDrop', 'CreateDropFromPlayer',
    'ConfiscateInventory', 'ReturnInventory', 'SetDurability',
    'SetItem', 'ConvertItems', 'GetCurrentWeapon', 'UpdateVehicle',
    'GetContainerFromSlot', 'SetContainerProperties', 'useItem'
}) do unsupported(name) end

exports('NordCompatibilityInfo', function()
    return { provider = provider, shim = true, version = '0.1.0', hooks = false,
        migration = 'manual export/import only; no automatic database migration' }
end)

CreateThread(function()
    Wait(1200)
    local ready = read('IsReady')
    print(('[ox_inventory compat] provider=%s ready=%s; no independent inventory data'):format(provider, tostring(ready)))
end)
