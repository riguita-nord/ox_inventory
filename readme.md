# ox_inventory Bridge for Nord Inventory

[![FiveM](https://img.shields.io/badge/FiveM-Cfx.re-blue)](https://fivem.net/)
[![Lua](https://img.shields.io/badge/Lua-5.4-purple)](https://www.lua.org/manual/5.4/)

A bridge between third-party scripts that use the `ox_inventory` API and **Nord Inventory**.

> This resource is **not** a standalone inventory or the original ox_inventory. It depends on `nord_inventory` and forwards mapped exports to that resource, so scripts can continue calling `exports.ox_inventory:*`.

## Contents

- [Why use it](#why-use-it)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Supported exports](#supported-exports)
- [Quick test](#quick-test)
- [Stashes](#stashes)
- [Bridge behavior](#bridge-behavior)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [License](#license)

## Why use it

Use this bridge when:

- Nord Inventory is the real inventory provider;
- third-party scripts call ox_inventory exports;
- no second inventory database or NUI should run;
- export compatibility must be explicit and controlled.

`nord_inventory` is a required dependency and the actual inventory provider. All inventory state and behavior come from Nord; this bridge only adapts calls between resource APIs. It does not create a separate inventory, database, or UI.

## How it works

```text
Third-party script
        |
        | exports.ox_inventory:...
        v
ox_inventory bridge
        |
        | exports.nord_inventory:...
        v
nord_inventory
        |
        v
Persistent inventory data
```

- Mapped exports are forwarded to `nord_inventory`.
- Inventory data and behavior are provided by Nord, not this bridge.
- The bridge does not install or run a second inventory system.

## Requirements

Before installing, confirm that you have:

- A FiveM server with Lua 5.4 support;
- `nord_inventory` installed and running (required);
- Nord items registered for every item you plan to test;
- `oxmysql` and `ox_lib`, if required by third-party resources;
- A complete server and database backup;
- A staging server for compatibility testing.

> Never start the original ox_inventory alongside this bridge.

## Installation

1. Make a complete server and database backup.
2. Keep the existing Nord Inventory installation intact.
3. Place this directory in `resources/[nord]/ox_inventory`.
4. Confirm that the provider resource is named exactly `nord_inventory`.
5. Add the resources to `server.cfg`:

```cfg
ensure oxmysql
ensure ox_lib
ensure nord_inventory
ensure ox_inventory

# Third-party resources that use ox_inventory exports
ensure your_resource
```

6. Restart the staging server.
7. Look for this provider confirmation in the console:

```text
[ox_inventory compat] provider=nord_inventory
```

8. Test with disposable items and test players before production use.

## Configuration

The bridge is configured in [config.lua](config.lua):

```lua
Config = {
    Debug = false,
    -- APIs without a safe mapping fail instead of receiving a false implementation.
    WarnUnsupported = true,
    -- Player inventory remains managed by nord_inventory.
    Provider = 'nord_inventory'
}
```

| Option | Type | Default | Description |
|---|---:|---:|---|
| `Debug` | `boolean` | `false` | Enables additional client-side debugging output. |
| `WarnUnsupported` | `boolean` | `true` | Emits server warnings for unsupported or unavailable APIs. |
| `Provider` | `string` | `nord_inventory` | Provider resource name. This must not be changed. |

## Supported exports

### Server

| Export | Status |
|---|---|
| `AddItem` | Supported |
| `RemoveItem` | Supported |
| `CanCarryItem` | Supported |
| `CanCarryWeight` | Supported |
| `CanCarryAmount` | Supported |
| `CanSwapItem` | Supported |
| `GetInventory` | Supported with light slot normalization |
| `GetInventoryItems` | Supported with light slot normalization |
| `GetItemCount` | Supported |
| `GetItem` | Supported |
| `Search` | Supported |
| `GetSlot` | Supported with light slot normalization |
| `GetSlotWithItem` | Supported |
| `GetSlotsWithItem` | Supported |
| `GetSlotIdWithItem` | Supported |
| `GetSlotIdsWithItem` | Supported |
| `GetEmptySlot` | Supported |
| `GetSlotForItem` | Supported |
| `Items` | Supported |
| `SetMetadata` | Supported |
| `GetMetadata` | Supported |
| `SetMaxWeight` | Supported |
| `SetSlotCount` | Supported |
| `ClearInventory` | Supported |
| `RemoveInventory` | Supported |
| `RegisterStash` | Supported |
| `openInventory` | Forwarded to the provider |
| `forceOpenInventory` | Forwarded to Nord's authorized open path |

Inventory weight and slot values are derived from provider inventory data:

- `GetInventoryWeight`
- `GetInventoryMaxWeight`
- `GetInventorySlots`

### Client

The following client exports are read-only:

- `Search`
- `GetPlayerItems`
- `GetPlayerWeight`
- `GetPlayerMaxWeight`
- `GetItemCount`
- `GetSlotWithItem`
- `GetSlotsWithItem`
- `GetSlotIdWithItem`
- `GetSlotIdsWithItem`

The bridge does not create a second UI or copy inventory state on the client.

## Quick test

Run this only in a server-side test resource with a connected player and a registered Nord item:

```lua
local playerId = 1
local itemName = 'water'

local count = exports.ox_inventory:GetItemCount(playerId, itemName)
local canCarry = exports.ox_inventory:CanCarryItem(playerId, itemName, 1)
local ok, result = exports.ox_inventory:AddItem(playerId, itemName, 1)

print(('Count: %s'):format(count))
print(('Can carry: %s'):format(canCarry))
print(('AddItem: %s, %s'):format(tostring(ok), tostring(result)))
```

### Expected behavior

- `count` must be zero or greater;
- `canCarry` must reflect player capacity;
- `AddItem` must succeed only if the item exists and can be delivered;
- the item must be registered in Nord Inventory.

> `source` must be the ID of a connected player. Do not use the server console ID.

## Stashes

`RegisterStash` is forwarded to Nord:

```lua
exports.ox_inventory:RegisterStash(
    'example_stash',
    'Storage',
    50,
    100000,
    false,
    nil,
    vector3(1.0, 2.0, 3.0)
)
```

The `slots`, `weight`, `owner`, `groups`, and `coords` arguments may use contracts that differ from the original ox_inventory. Test each stash on the staging server before production use.

## Bridge behavior

This resource is an API bridge, not a replacement inventory. Its behavior depends on the installed and running `nord_inventory` provider. Only the exports listed above are mapped by this bridge; third-party scripts may need additional integration if they rely on other ox_inventory APIs or internal behavior.

The client-facing exports listed above provide inventory reads. Opening or manipulating inventories must follow Nord's own authorized flow; this bridge does not add client-side privileged events.

### Hooks and internal behavior

ox_inventory hooks, payloads, filters, callbacks, UI, and internal events are not translated by this bridge. Nord has its own API and behavior, so scripts that depend on ox_inventory internals may require a dedicated integration.

Any script that uses hooks for item integrity, permissions, logging, or anti-duplication must be reviewed before deployment.

### Data and schemas

- Items and inventories follow Nord Inventory's data format.
- Slot normalization is intentionally lightweight.
- This bridge does not migrate tables, metadata, legacy inventories, or item definitions.
- Third-party scripts may depend on fields that exist only in the original ox_inventory.

## Troubleshooting

### Resource does not start

Confirm that Nord starts before the bridge:

```cfg
ensure nord_inventory
ensure ox_inventory
```

The manifest requires `nord_inventory`, and the provider name cannot be changed.

### Export returns false or empty

Check:

1. Whether the item is registered in Nord;
2. Whether `source` is a connected player ID;
3. Whether the export exists in the installed provider;
4. Whether the console reports an unavailable export;
5. Whether the script uses an ox_inventory-only API.

### Provider unavailable

```text
Nord Inventory is not started
```

Start or restart `nord_inventory`, then restart the bridge.

### Script cannot open the inventory

The script may call `openInventory`, `useItem`, or `setStashTarget` on the client. These are not safe, privileged client actions in this bridge.

Use a server-authorized integration or Nord's native API.

### Inventory metadata is missing

The bridge applies basic normalization:

- `metadata` falls back to `info` when that field is returned by the provider;
- `count` falls back to `amount`;
- the final shape still depends on the provider and consumer script.

### Unsupported export warning

The export was intentionally rejected. Do not replace the warning with a fake implementation; review the third-party script and provide a dedicated, secure integration for that behavior.

## Security

- Do not deploy the bridge in production without testing third-party scripts.
- Do not expose privileged exports directly to the client.
- Validate inventory opening, item use, and stash operations server-side.
- Back up inventory and item data before changing weight, slots, or persistent records.
- Review scripts that use hooks, internal events, or callbacks.
- Test only with disposable items on a staging server.
- The bridge does not assume that an ox_inventory call has identical behavior in Nord.

## License

Consult the project owner before redistributing or integrating this bridge into another product.
