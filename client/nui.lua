-- ============================================================
--  CLIENT NUI BRIDGE
--  Custom notifications + menu open/close + a tiny callback system
--  so Lua can await a value the player picks in the NUI.
--  Zero external UI dependencies.
-- ============================================================

NUI = { open = false, callbacks = {}, cbId = 0 }

-- ----- notification (custom NUI, zero dep) -----
function ShowNotify(msg, kind)
    SendNUIMessage({
        action = 'notify',
        message = msg,
        kind = kind or 'info',
        duration = Config.Notify.duration,
        position = Config.Notify.position,
    })
end

RegisterNetEvent('lr_properties:notify', function(msg, kind)
    ShowNotify(msg, kind)
end)

-- ----- open / close a NUI menu -----
function OpenMenu(payload)
    NUI.open = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = payload })
end

function CloseMenu()
    if not NUI.open then return end
    NUI.open = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterNUICallback('close', function(_, cb)
    CloseMenu()
    cb('ok')
end)

-- generic "the player picked / submitted something in the NUI"
-- the NUI posts { id = <callbackId>, value = <...> } to this endpoint.
RegisterNUICallback('submit', function(data, cb)
    local id = data.id
    local fn = NUI.callbacks[id]
    if fn then
        NUI.callbacks[id] = nil
        fn(data.value)
    end
    cb('ok')
end)

-- request a value from the NUI and run cb when it returns
function NuiRequest(payload, cb)
    NUI.cbId = NUI.cbId + 1
    local id = NUI.cbId
    NUI.callbacks[id] = cb
    payload.callbackId = id
    OpenMenu(payload)
end

-- live event passthrough (search filtering etc. handled client-side in JS,
-- but data like catalog / interiors is pushed at open time)
RegisterNUICallback('action', function(data, cb)
    TriggerEvent('lr_properties:nuiAction', data)
    cb('ok')
end)
