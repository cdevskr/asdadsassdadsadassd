-- ============================================================
--  SERVER - KEYS
--  Owner gives / removes keys. Key holders can enter & lock/unlock.
-- ============================================================

RegisterNetEvent('lr_properties:giveKey', function(propertyId, targetSrc)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not IsOwner(src, p) and not CanManage(src, p, 'canManageStaff') then
        Notify(src, _U('no_permission'), 'error'); return
    end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(targetSrc) then return end

    local count = 0
    for _ in pairs(p.keys) do count = count + 1 end
    if count >= Config.Keys.maxHolders then return end

    local ident = Bridge.GetIdentifier(targetSrc)
    local name  = Bridge.GetName(targetSrc)
    if ident == p.owner then return end

    DB_AddKey(propertyId, ident, name)
    Notify(src, _U('key_given', name), 'success')
    Notify(targetSrc, _U('got_key', p.label), 'success')
end)

RegisterNetEvent('lr_properties:removeKey', function(propertyId, ident)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not IsOwner(src, p) and not CanManage(src, p, 'canManageStaff') then
        Notify(src, _U('no_permission'), 'error'); return
    end
    local name = p.keys[ident]
    DB_RemoveKey(propertyId, ident)
    Notify(src, _U('key_removed', type(name) == 'string' and name or ident), 'success')
    local tsrc = Bridge.GetSrcByIdentifier(ident)
    if tsrc then Notify(tsrc, _U('lost_key', p.label), 'error') end
end)

RegisterNetEvent('lr_properties:requestKeys', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not IsOwner(src, p) and not CanManage(src, p, 'canManageStaff') then return end
    local list = {}
    for ident, name in pairs(p.keys) do
        list[#list + 1] = { identifier = ident, name = type(name) == 'string' and name or ident }
    end
    TriggerClientEvent('lr_properties:keyList', src, propertyId, list)
end)

-- get nearby players for the "give key / hire" pickers
RegisterNetEvent('lr_properties:requestNearby', function(myCoords)
    local src = source
    local list = {}
    for _, pid in ipairs(GetPlayers()) do
        pid = tonumber(pid)
        if pid ~= src then
            local ped = GetPlayerPed(pid)
            local c   = GetEntityCoords(ped)
            if #(vector3(myCoords.x, myCoords.y, myCoords.z) - c) < 6.0 then
                list[#list + 1] = { src = pid, name = Bridge.GetName(pid) }
            end
        end
    end
    TriggerClientEvent('lr_properties:nearbyList', src, list)
end)
