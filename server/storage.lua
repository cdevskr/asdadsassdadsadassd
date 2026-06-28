-- ============================================================
--  SERVER - STORAGE (ox_inventory)
--  Registers per-property stashes and opens them with access checks.
--  Stash ids:  house_<id> / business_<id>
--  Wardrobe is NOT a stash - we only trigger your event.
-- ============================================================

local function stashId(p)
    return ('%s_%s'):format(p.type, p.id)
end

-- register a stash with ox_inventory (idempotent)
local function ensureStash(p)
    local cfg = p.type == 'business' and Config.Storage.business or Config.Storage.house
    exports.ox_inventory:RegisterStash(stashId(p), p.label .. ' Depo', cfg.slots, cfg.weight, false)
end

AddEventHandler('lr_properties:loaded', function()
    if GetResourceState('ox_inventory') ~= 'started' then
        print('^1[lr_properties]^7 ox_inventory not started - storage disabled.')
        return
    end
    for _, p in pairs(Properties) do ensureStash(p) end
end)

-- open the stash (server validates access, then tells client to open)
RegisterNetEvent('lr_properties:openStash', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if GetResourceState('ox_inventory') ~= 'started' then return end

    -- house: owner + key holders. business: owner + staff with canManageStash
    local allowed
    if p.type == 'business' then
        allowed = IsOwner(src, p) or CanManage(src, p, 'canManageStash')
    else
        allowed = IsOwner(src, p) or HasKey(src, p)
    end
    if not allowed then Notify(src, _U('no_permission'), 'error'); return end

    ensureStash(p)
    TriggerClientEvent('lr_properties:forceOpenStash', src, stashId(p))
end)

-- ============================================================
--  WARDROBE  (you wire up the outfit logic; we just trigger)
-- ============================================================
RegisterNetEvent('lr_properties:openWardrobe', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    -- house: owner + key holders. business: staff/owner
    local allowed
    if p.type == 'business' then
        allowed = IsOwner(src, p) or IsEmployee(src, p)
    else
        allowed = IsOwner(src, p) or HasKey(src, p)
    end
    if not allowed then Notify(src, _U('no_permission'), 'error'); return end

    -- fire YOUR client event with a clean payload
    TriggerClientEvent(Config.Wardrobe.openEvent, src, {
        propertyId = propertyId,
        owner      = IsOwner(src, p),
        type       = p.type,
    })
end)
