-- ============================================================
--  CLIENT PROPERTY
--  Enter flow (asks server -> approved -> load interior + objects),
--  object streaming inside, and the exit prompt.
-- ============================================================

local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(10) end
    return hash
end

-- spawn a single decoration object and track it
local function spawnObject(o)
    if State.placedObjects[o.id] and DoesEntityExist(State.placedObjects[o.id]) then return end
    local hash = loadModel(o.model)
    local ent = CreateObject(hash, o.pos.x, o.pos.y, o.pos.z, false, false, false)
    SetEntityCoordsNoOffset(ent, o.pos.x, o.pos.y, o.pos.z, false, false, false)
    SetEntityRotation(ent, o.rot.x, o.rot.y, o.rot.z, 2, true)
    FreezeEntityPosition(ent, true)
    SetEntityCollision(ent, true, true)
    SetModelAsNoLongerNeeded(hash)
    State.placedObjects[o.id] = ent

    -- attach light if catalog entry says so & it's toggled on
    local cat = Config.CatalogByModel[o.model]
    if cat and cat.light then
        State.objectMeta = State.objectMeta or {}
        State.objectMeta[o.id] = { cat = cat, on = true }
    end
end

local function clearObjects()
    for id, ent in pairs(State.placedObjects) do
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    State.placedObjects = {}
    State.objectMeta = {}
end

-- ----- ENTER -----
function EnterProperty(propertyId)
    if State.inside then return end
    TriggerServerEvent('lr_properties:tryEnter', propertyId)
end

-- Register target zones for all access points in the current property (target mode).
-- Called on enter and whenever door data updates while inside.
local function rebuildAccessTargets()
    if Config.Interaction.mode ~= 'target' or not Bridge.target then return end
    Bridge.RemoveAllAccessTargets()
    local propertyId = State.inside
    if not propertyId then return end
    local p = State.doors[propertyId]
    if not p or not p.access then return end
    for id, ap in pairs(p.access) do
        if ap.pos then
            local capturedId, capturedAp = id, ap
            Bridge.AddAccessTarget(propertyId, capturedId, capturedAp.pos, capturedAp.type, function()
                if capturedAp.type == 'storage' then
                    TriggerServerEvent('lr_properties:openStash', propertyId)
                elseif capturedAp.type == 'wardrobe' then
                    TriggerServerEvent('lr_properties:openWardrobe', propertyId)
                elseif capturedAp.type == 'safe' then
                    OpenSafeMenu(propertyId)
                end
            end)
        end
    end
end

-- Rebuild access targets when door data updates (e.g. new access point placed)
AddEventHandler('lr_properties:doorsUpdated', function()
    if State.inside then rebuildAccessTargets() end
end)

RegisterNetEvent('lr_properties:enterApproved', function(propertyId)
    local p = State.doors[propertyId]; if not p then return end
    local runtime = LoadInterior(p)
    if not runtime then ShowNotify('Interior yüklenemedi', 'error'); return end
    State.inside     = propertyId
    State.insideData = runtime
    -- ask for the object list and spawn them
    TriggerServerEvent('lr_properties:requestObjects', propertyId)
    -- register target zones for any already-known access points
    rebuildAccessTargets()

    -- first entry & no custom exit set yet: let an authorized person place it.
    -- (config exit stays as a fallback, so nobody is ever trapped.)
    local acc = State.access[propertyId]
    local authorized = acc and (acc.owner or acc.realtor or acc.decorate)
    if not p.exit and authorized then
        SetTimeout(900, function()
            if State.inside == propertyId then
                ShowNotify(_U('exit_not_set'), 'info')
                PlaceExitPoint(propertyId)
            end
        end)
    end
end)

-- place / re-place the interior exit point with a movable marker.
function PlaceExitPoint(propertyId)
    if State.inside ~= propertyId then return end
    State.decorate = true  -- pause the auto exit-prompt loop while placing
    CreateThread(function()
        local placing = true
        while placing and State.inside == propertyId do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 1.0
            DrawMarker(36, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.4,0.4,0.4, 90,200,120,200, false,false,2,nil,nil,false)
            SetTextFont(4); SetTextScale(0.4,0.4); SetTextColour(255,255,255,220); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(_U('place_exit'))
            EndTextCommandDisplayText(0.5, 0.85)
            if IsControlJustReleased(0, Config.Gizmo.keys.confirm) then       -- ENTER
                placing = false
                TriggerServerEvent('lr_properties:setExit', propertyId, { x = pos.x, y = pos.y, z = pos.z })
                State.insideData.exit = vector3(pos.x, pos.y, pos.z)          -- live update for this session
            elseif IsControlJustReleased(0, Config.Gizmo.keys.cancel) then    -- BACKSPACE
                placing = false
                ShowNotify(_U('cancelled'), 'info')
            end
        end
        State.decorate = false
    end)
end


RegisterNetEvent('lr_properties:objectList', function(propertyId, list)
    if State.inside ~= propertyId then return end
    clearObjects()
    for _, o in ipairs(list) do spawnObject(o) end
end)

-- ----- live object events (decoration sync) -----
RegisterNetEvent('lr_properties:objectPlaced', function(propertyId, id, model, pos, rot)
    if State.inside ~= propertyId then return end
    spawnObject({ id = id, model = model, pos = pos, rot = rot })
end)

RegisterNetEvent('lr_properties:objectMoved', function(propertyId, objId, pos, rot)
    if State.inside ~= propertyId then return end
    local ent = State.placedObjects[objId]
    if ent and DoesEntityExist(ent) then
        SetEntityCoordsNoOffset(ent, pos.x, pos.y, pos.z, false, false, false)
        SetEntityRotation(ent, rot.x, rot.y, rot.z, 2, true)
    end
end)

RegisterNetEvent('lr_properties:objectRemoved', function(propertyId, objId)
    if State.inside ~= propertyId then return end
    local ent = State.placedObjects[objId]
    if ent and DoesEntityExist(ent) then DeleteEntity(ent) end
    State.placedObjects[objId] = nil
    if State.objectMeta then State.objectMeta[objId] = nil end
end)

-- ----- EXIT -----
function ExitProperty()
    local propertyId = State.inside
    if not propertyId then return end
    local p = State.doors[propertyId]
    clearObjects()
    Bridge.RemoveAllAccessTargets()
    UnloadInterior(p, State.insideData)
    State.inside = nil
    State.insideData = nil
    State.decorate = false
    TriggerServerEvent('lr_properties:exited')   -- leave the routing bucket
end

-- exit prompt + light rendering loop while inside
CreateThread(function()
    while true do
        if State.inside and not State.decorate then
            local rt = State.insideData
            local ped = PlayerPedId()
            local pc  = GetEntityCoords(ped)
            -- exit zone
            if rt and rt.exit then
                local d = #(pc - vector3(rt.exit.x, rt.exit.y, rt.exit.z))
                if d < 2.5 then
                    DrawMarker(Config.Interaction.markerType, rt.exit.x, rt.exit.y, rt.exit.z - 0.95,
                        0,0,0, 0,0,0, 0.3,0.3,0.3, 120,170,255,140, false,false,2,nil,nil,false)
                    if d < 1.4 then
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(_U('btn_exit') .. ' ~INPUT_CONTEXT~')
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, 38) then ExitProperty() end
                    end
                end
            end
            -- render toggled lights
            if State.objectMeta then
                for id, meta in pairs(State.objectMeta) do
                    if meta.on and meta.cat.light then
                        local ent = State.placedObjects[id]
                        if ent and DoesEntityExist(ent) then
                            local lc = GetEntityCoords(ent)
                            local o  = meta.cat.lightOffset or vector3(0,0,0)
                            local col= meta.cat.lightColor or {255,244,214}
                            DrawLightWithRange(lc.x + o.x, lc.y + o.y, lc.z + o.z,
                                col[1], col[2], col[3],
                                meta.cat.lightRange or 5.0, meta.cat.lightIntensity or 2.0)
                        end
                    end
                end
            end
            Wait(0)
        else
            Wait(300)
        end
    end
end)

-- toggle a placed light on/off (called from a future radial; here via menu)
function ToggleObjectLight(objId)
    if not State.objectMeta or not State.objectMeta[objId] then return end
    State.objectMeta[objId].on = not State.objectMeta[objId].on
    ShowNotify(State.objectMeta[objId].on and _U('light_on') or _U('light_off'), 'info')
end

-- dashboard light switch (does not close the dashboard)
RegisterNUICallback('lightToggle', function(data, cb)
    local id = data and data.objId
    if id ~= nil then
        id = tonumber(id) or id
        if State.objectMeta and State.objectMeta[id] then
            State.objectMeta[id].on = not State.objectMeta[id].on
        end
    end
    cb('ok')
end)

-- place a storage/wardrobe/safe access point exactly like the exit point:
-- a marker floats in front of you, walk to aim, ENTER confirm / BACKSPACE cancel.
function PlaceAccessPoint(propertyId, kind)
    if State.inside ~= propertyId then ShowNotify(_U('enter_first'), 'error'); return end
    if not (kind == 'storage' or kind == 'wardrobe' or kind == 'safe') then return end
    local m = (Config.AccessPoint.markers and Config.AccessPoint.markers[kind]) or { label = kind, color = { r = 255, g = 159, b = 10 } }
    local c = m.color
    State.decorate = true  -- pause auto exit-prompt loop while placing
    CreateThread(function()
        local placing = true
        while placing and State.inside == propertyId do
            Wait(0)
            local ped = PlayerPedId()
            local pos = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 1.0
            DrawMarker(36, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.4,0.4,0.4, c.r, c.g, c.b, 200, false,false,2,nil,nil,false)
            SetTextFont(4); SetTextScale(0.4,0.4); SetTextColour(255,255,255,220); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(_U('place_access', m.label or kind))
            EndTextCommandDisplayText(0.5, 0.85)
            if IsControlJustReleased(0, Config.Gizmo.keys.confirm) then       -- ENTER
                placing = false
                TriggerServerEvent('lr_properties:addAccessPoint', propertyId, kind, { x = pos.x, y = pos.y, z = pos.z })
                ShowNotify(_U('access_placed'), 'success')
            elseif IsControlJustReleased(0, Config.Gizmo.keys.cancel) then    -- BACKSPACE
                placing = false
                ShowNotify(_U('cancelled'), 'info')
            end
        end
        State.decorate = false
    end)
end

-- ============================================================
--  ACCESS POINT markers (storage / wardrobe / safe placed in-world)
--  Walk up + [E] to open. Owner can hold [DEL] to remove.
-- ============================================================
CreateThread(function()
    while true do
        local sleep = 500
        if State.inside and not State.decorate and not NUI.open then
            local p = State.doors[State.inside]
            if p and p.access then
                local pc = GetEntityCoords(PlayerPedId())
                local acc = State.access[State.inside] or {}
                for id, ap in pairs(p.access) do
                    if ap.pos then
                        local d = #(pc - vector3(ap.pos.x, ap.pos.y, ap.pos.z))
                        if d < Config.AccessPoint.drawDist then
                            sleep = 0
                            local m = Config.AccessPoint.markers[ap.type] or { color = { r = 255, g = 159, b = 10 } }
                            local c = m.color
                            DrawMarker(36, ap.pos.x, ap.pos.y, ap.pos.z + 0.05, 0,0,0, 0,0,0,
                                0.35,0.35,0.35, c.r, c.g, c.b, 200, false, false, 2, nil, nil, false)
                            if d < Config.AccessPoint.interactDist then
                                local hint = '[E] ' .. (m.label or '')
                                if acc.owner then hint = hint .. '  •  [DEL] sil' end
                                BeginTextCommandDisplayHelp('STRING')
                                AddTextComponentSubstringPlayerName(hint)
                                EndTextCommandDisplayHelp(0, false, true, -1)
                                if IsDisabledControlJustReleased(0, Config.AccessPoint.openKey) then
                                    if ap.type == 'storage' then
                                        TriggerServerEvent('lr_properties:openStash', State.inside)
                                    elseif ap.type == 'wardrobe' then
                                        TriggerServerEvent('lr_properties:openWardrobe', State.inside)
                                    elseif ap.type == 'safe' then
                                        OpenSafeMenu(State.inside)
                                    end
                                elseif acc.owner and IsControlJustReleased(0, 178) then
                                    TriggerServerEvent('lr_properties:removeAccessPoint', State.inside, id)
                                    ShowNotify(_U('removed'), 'success')
                                end
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
