-- ============================================================
--  CLIENT MAIN
--  Holds the door table, current state, fetches config for the NUI.
-- ============================================================

State = {
    doors        = {},     -- propertyId -> public property data
    inside       = nil,    -- propertyId we're currently inside, or nil
    insideData   = nil,    -- the interior runtime (shell entity, etc.)
    placedObjects= {},     -- objId -> entity handle (for the property we're in)
    access       = {},     -- propertyId -> access result cache
    decorate     = false,  -- decoration mode active
    config       = nil,    -- pushed catalog/interior/locale config
}

-- ----- boot -----
CreateThread(function()
    while not NetworkIsSessionStarted() do Wait(200) end
    Wait(1500)
    TriggerServerEvent('lr_properties:requestSync')
    TriggerServerEvent('lr_properties:requestConfig')
    Wait(600)
    TriggerServerEvent('lr_properties:playerReady')   -- respawn-inside check
end)

RegisterNetEvent('lr_properties:sync', function(list)
    State.doors = {}
    for _, p in ipairs(list) do State.doors[p.id] = p end
    TriggerEvent('lr_properties:doorsUpdated')
end)

RegisterNetEvent('lr_properties:updateOne', function(p)
    State.doors[p.id] = p
    TriggerEvent('lr_properties:doorsUpdated')
end)

RegisterNetEvent('lr_properties:removeOne', function(id)
    State.doors[id] = nil
    TriggerEvent('lr_properties:doorsUpdated')
end)

RegisterNetEvent('lr_properties:configData', function(cfg)
    State.config = cfg
end)

-- ----- access query helper (promise-ish via callback) -----
local accessWaiters = {}
function QueryAccess(propertyId, cb)
    accessWaiters[propertyId] = accessWaiters[propertyId] or {}
    accessWaiters[propertyId][#accessWaiters[propertyId] + 1] = cb
    TriggerServerEvent('lr_properties:queryAccess', propertyId)
end

RegisterNetEvent('lr_properties:accessResult', function(propertyId, result)
    State.access[propertyId] = result
    local waiters = accessWaiters[propertyId]
    if waiters then
        accessWaiters[propertyId] = nil
        for _, cb in ipairs(waiters) do cb(result) end
    end
end)

-- ----- ESC closes any open menu -----
CreateThread(function()
    while true do
        Wait(0)
        if NUI.open then
            if IsControlJustReleased(0, 322) then  -- ESC
                CloseMenu()
            end
        else
            Wait(250)
        end
    end
end)

-- clean up on resource stop
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ent in pairs(State.placedObjects) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    if State.insideData and State.insideData.shell and DoesEntityExist(State.insideData.shell) then
        DeleteEntity(State.insideData.shell)
    end
    SetNuiFocus(false, false)
end)
