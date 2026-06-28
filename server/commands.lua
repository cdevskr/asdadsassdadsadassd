-- ============================================================
--  SERVER - COMMANDS
--  Realtor is granted by COMMAND (no job), as requested.
-- ============================================================

-- /grantrealtor [id]   (admin)  -> make a player a realtor
RegisterCommand('grantrealtor', function(src, args)
    if src ~= 0 and not IsAdmin(src) then
        if src > 0 then Notify(src, _U('no_permission'), 'error') end
        return
    end
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        print('usage: grantrealtor [serverId]'); return
    end
    local ident = Bridge.GetIdentifier(target)
    local name  = Bridge.GetName(target)
    DB_AddRealtor(ident, name)
    Notify(target, _U('realtor_granted', name), 'success')
    if src > 0 then Notify(src, _U('realtor_granted', name), 'info') end
end, false)

-- /revokerealtor [id]  (admin)
RegisterCommand('revokerealtor', function(src, args)
    if src ~= 0 and not IsAdmin(src) then
        if src > 0 then Notify(src, _U('no_permission'), 'error') end
        return
    end
    local target = tonumber(args[1])
    if not target or not GetPlayerName(target) then
        print('usage: revokerealtor [serverId]'); return
    end
    local ident = Bridge.GetIdentifier(target)
    DB_RemoveRealtor(ident)
    Notify(target, _U('realtor_revoked', Bridge.GetName(target)), 'info')
    if src > 0 then Notify(src, _U('realtor_revoked', Bridge.GetName(target)), 'info') end
end, false)

-- the /realtor command (granted realtors only) -> opens the placement menu
RegisterCommand(Config.CommandRealtor, function(src)
    if not IsRealtor(src) then Notify(src, _U('realtor_only'), 'error'); return end
    TriggerClientEvent('lr_properties:openRealtorMenu', src)
end, false)

-- ============================================================
--  CREATE PROPERTY  (called by the realtor client after picking
--  an interior + a door location)
-- ============================================================
RegisterNetEvent('lr_properties:createProperty', function(payload)
    local src = source
    if not IsRealtor(src) then Notify(src, _U('realtor_only'), 'error'); return end

    -- payload: { label, type, price, rent_price, entry_fee, door{x,y,z,h}, interior{...} }
    if type(payload) ~= 'table' or not payload.door or not payload.interior then return end

    -- stamp the placer so commission can be paid later
    payload.interior._placer = Bridge.GetIdentifier(src)

    local data = {
        label      = tostring(payload.label or 'Mülk'):sub(1, 60),
        type       = payload.type == 'business' and 'business' or 'house',
        price      = math.max(0, math.floor(tonumber(payload.price) or 0)),
        rent_price = math.max(0, math.floor(tonumber(payload.rent_price) or 0)),
        entry_fee  = math.max(0, math.floor(tonumber(payload.entry_fee) or 0)),
        door       = payload.door,
        interior   = payload.interior,
    }

    DB_CreateProperty(data, function(id)
        if not id then return end
        local p = Properties[id]
        -- register stash for the new property
        if GetResourceState('ox_inventory') == 'started' then
            local cfg = p.type == 'business' and Config.Storage.business or Config.Storage.house
            exports.ox_inventory:RegisterStash(('%s_%s'):format(p.type, id), p.label .. ' Depo', cfg.slots, cfg.weight, false)
        end
        SyncProperty(id)
        Notify(src, _U('property_created', p.label), 'success')
    end)
end)

-- realtor deletes a property they can see (admin or realtor)
RegisterNetEvent('lr_properties:deleteProperty', function(propertyId)
    local src = source
    if not IsRealtor(src) and not IsAdmin(src) then Notify(src, _U('no_permission'), 'error'); return end
    if not Properties[propertyId] then return end
    DB_DeleteProperty(propertyId)
    RemoveProperty(propertyId)
    Notify(src, _U('saved'), 'success')
end)

-- send catalog/interior/locale config to clients on request (keeps NUI in sync)
RegisterNetEvent('lr_properties:requestConfig', function()
    local src = source
    TriggerClientEvent('lr_properties:configData', src, {
        catalog            = Config.Catalog,
        catalogCategories  = Config.CatalogCategories,
        interiors          = Config.InteriorCatalog,
        interiorCategories = Config.InteriorCategories,
        locale             = GetLocaleTable(),
        commission         = Config.Commission,
    })
end)
