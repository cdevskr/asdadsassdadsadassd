-- ============================================================
--  DECORATION EDITOR  (freecam + mouse, beginner friendly)
--  - Free camera you fly with WASD + mouse look.
--  - A docked panel (top-left) stays open; pick a prop or type a name.
--  - The picked object follows your crosshair and sits on any surface.
--  - Left click places. Scroll rotates. Click an object to grab/move it.
--  - TAB toggles the cursor (panel  <->  build). DELETE removes.
--  Public API used by the menu: StartDecorate / StopDecorate /
--  StartRemoveMode / OpenCatalog.
-- ============================================================

Editor = { active = false }
local E = Config.Editor
local K = E.keys

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(10) end
    return hash
end

local function rad(d) return d * math.pi / 180.0 end
local function clamp(v, a, b) return math.max(a, math.min(b, v)) end

local function forwardFromRot(rx, rz)
    local z, x = rad(rz), rad(rx)
    local n = math.abs(math.cos(x))
    return vector3(-math.sin(z) * n, math.cos(z) * n, math.sin(x))
end

-- camera raycast (ignore the held ghost + the player ped)
local function camRay(camPos, fwd, ignore)
    local dest = camPos + fwd * 1000.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(camPos.x, camPos.y, camPos.z,
        dest.x, dest.y, dest.z, 1 + 16 + 256, ignore or 0, 7)
    local _, hit, coords, normal, entity = GetShapeTestResultIncludingMaterial(ray)
    return hit == 1, coords, normal, entity
end

local function snapGrid(v, s)
    return vector3(math.floor(v.x/s+0.5)*s, math.floor(v.y/s+0.5)*s, math.floor(v.z/s+0.5)*s)
end

-- ----- runtime state -----
local cam
local camPos, camRot
local holding   -- { kind='new'|'edit', ent, model, objId, origPos, origRot }
local yaw, pitch, roll = 0.0, 0.0, 0.0
local grid, surface = false, E.surfaceSnap

-- ============================================================
--  start / stop
-- ============================================================
function Editor.Start(propertyId)
    if Editor.active then return end
    if State.inside ~= propertyId then ShowNotify(_U('enter_first'), 'error'); return end
    Editor.active = true
    State.decorate = true
    Editor.propertyId = propertyId
    grid, surface = false, E.surfaceSnap

    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityVisible(ped, false, false)

    local p = GetEntityCoords(ped)
    camPos = vector3(p.x, p.y, p.z + 1.0)
    camRot = vector3(-10.0, 0.0, GetEntityHeading(ped))
    cam = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', camPos.x, camPos.y, camPos.z,
        camRot.x, camRot.y, camRot.z, 60.0, false, 2)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    Editor.openPanel()
    Editor.setCursor(true)
    Editor.loop()
    ShowNotify(_U('decorate_on'), 'success')
end

function Editor.Stop()
    if not Editor.active then return end
    Editor.active = false
    State.decorate = false
    Editor.dropGhost(true)
    RenderScriptCams(false, false, 0, true, false)
    if cam then DestroyCam(cam, false); cam = nil end
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'decoratorClose' })
    ShowNotify(_U('decorate_off'), 'info')
end

-- ============================================================
--  cursor (panel focus) toggle
-- ============================================================
function Editor.setCursor(on)
    Editor.cursor = on
    SetNuiFocus(on, on)
    SendNUIMessage({ action = 'decoratorState', cursor = on, grid = grid, surface = surface })
end

-- ============================================================
--  panel
-- ============================================================
function Editor.openPanel()
    if not State.config then TriggerServerEvent('lr_properties:requestConfig'); Wait(250) end
    SendNUIMessage({
        action = 'decorator',
        data = {
            categories = State.config and State.config.catalogCategories or Config.CatalogCategories,
            items      = State.config and State.config.catalog or Config.Catalog,
            functional = true,
            thumbs     = Config.Thumbnails,
        },
    })
end

-- ============================================================
--  ghost handling
-- ============================================================
local function makeGhost(model)
    local hash = loadModel(model)
    local ent = CreateObject(hash, camPos.x, camPos.y, camPos.z, false, false, false)
    SetEntityAlpha(ent, 170, false)
    SetEntityCollision(ent, false, false)
    FreezeEntityPosition(ent, true)
    SetModelAsNoLongerNeeded(hash)
    return ent
end

-- start placing a brand new object from the panel
function Editor.pick(model)
    Editor.dropGhost(true)
    yaw, pitch, roll = 0.0, 0.0, 0.0
    holding = { kind = 'new', ent = makeGhost(model), model = model }
    Editor.setCursor(false)
end

-- validate then pick a manually typed model
function Editor.pickManual(model)
    model = tostring(model):gsub('%s', '')
    if model == '' then return end
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        ShowNotify(_U('invalid_model', model), 'error'); return
    end
    Editor.pick(model)
end

-- grab an existing placed object (move it)
local function grabAt(entity)
    for objId, ent in pairs(State.placedObjects) do
        if ent == entity then
            local r = GetEntityRotation(ent, 2)
            yaw, pitch, roll = r.z, r.x, r.y
            SetEntityAlpha(ent, 170, false)
            SetEntityCollision(ent, false, false)
            holding = { kind = 'edit', ent = ent, objId = objId,
                        origPos = GetEntityCoords(ent), origRot = r }
            Editor.setCursor(false)
            return true
        end
    end
    return false
end

-- delete current ghost. restore=true cancels (restores edited object)
function Editor.dropGhost(restore)
    if not holding then return end
    if holding.kind == 'new' then
        if DoesEntityExist(holding.ent) then DeleteEntity(holding.ent) end
    elseif holding.kind == 'edit' and DoesEntityExist(holding.ent) then
        ResetEntityAlpha(holding.ent)
        SetEntityCollision(holding.ent, true, true)
        if restore then
            local o, r = holding.origPos, holding.origRot
            SetEntityCoordsNoOffset(holding.ent, o.x, o.y, o.z, false, false, false)
            SetEntityRotation(holding.ent, r.x, r.y, r.z, 2, true)
        end
    end
    holding = nil
end

-- commit the held object
local function commit()
    if not holding then return end
    local pos = GetEntityCoords(holding.ent)
    local rot = GetEntityRotation(holding.ent, 2)
    if holding.kind == 'new' then
        TriggerServerEvent('lr_properties:placeObject', Editor.propertyId, holding.model,
            { x = pos.x, y = pos.y, z = pos.z }, { x = rot.x, y = rot.y, z = rot.z })
        -- keep placing copies of the same prop for speed
        local model = holding.model
        if DoesEntityExist(holding.ent) then DeleteEntity(holding.ent) end
        holding = { kind = 'new', ent = makeGhost(model), model = model }
        ShowNotify(_U('placed'), 'success')
    else
        ResetEntityAlpha(holding.ent)
        SetEntityCollision(holding.ent, true, true)
        TriggerServerEvent('lr_properties:moveObject', Editor.propertyId, holding.objId,
            { x = pos.x, y = pos.y, z = pos.z }, { x = rot.x, y = rot.y, z = rot.z })
        holding = nil
        ShowNotify(_U('saved'), 'success')
        Editor.setCursor(true)
    end
end

-- ============================================================
--  control disabling (so the game doesn't fight us)
-- ============================================================
local function disableControls()
    DisableControlAction(0, 1, true)   DisableControlAction(0, 2, true)
    DisableControlAction(0, 24, true)  DisableControlAction(0, 25, true)
    DisableControlAction(0, 257, true) DisableControlAction(0, 263, true)
    DisableControlAction(0, 264, true) DisableControlAction(0, 140, true)
    DisableControlAction(0, 141, true) DisableControlAction(0, 142, true)
    DisableControlAction(0, 143, true) DisableControlAction(0, 22, true)
    DisableControlAction(0, 36, true)  DisableControlAction(0, 44, true)
    DisableControlAction(0, 14, true)  DisableControlAction(0, 15, true)
    DisableControlAction(0, 16, true)  DisableControlAction(0, 17, true)
end

-- ============================================================
--  main loop
-- ============================================================
function Editor.loop()
    CreateThread(function()
        while Editor.active do
            Wait(0)

            -- TAB toggles cursor/panel focus
            if IsDisabledControlJustPressed(0, K.cursor) or IsControlJustPressed(0, K.cursor) then
                if not Editor.cursor and holding then Editor.dropGhost(true) end
                Editor.setCursor(not Editor.cursor)
            end

            if Editor.cursor then
                -- panel mode: camera frozen, cursor active. nothing else.
                Wait(0)
            else
                disableControls()

                -- ---- mouse look ----
                local dx = GetDisabledControlNormal(0, 1)
                local dy = GetDisabledControlNormal(0, 2)
                camRot = vector3(
                    clamp(camRot.x - dy * E.lookSens, -89.0, 89.0),
                    0.0,
                    camRot.z - dx * E.lookSens)

                -- ---- freecam movement ----
                local fwd = forwardFromRot(camRot.x, camRot.z)
                local right = vector3(-math.sin(rad(camRot.z + 90.0)), math.cos(rad(camRot.z + 90.0)), 0.0)
                local spd = E.camSpeed
                if IsDisabledControlPressed(0, K.fast) then spd = E.camSpeedFast end
                if IsDisabledControlPressed(0, K.slow) then spd = E.camSpeedSlow end
                local move = vector3(0.0, 0.0, 0.0)
                if IsDisabledControlPressed(0, K.forward) then move = move + fwd end
                if IsDisabledControlPressed(0, K.back)    then move = move - fwd end
                if IsDisabledControlPressed(0, K.right)   then move = move + right end
                if IsDisabledControlPressed(0, K.left)    then move = move - right end
                if IsDisabledControlPressed(0, K.up)      then move = move + vector3(0,0,1) end
                if IsDisabledControlPressed(0, K.down)    then move = move - vector3(0,0,1) end
                camPos = camPos + move * spd

                SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
                SetCamRot(cam, camRot.x, camRot.y, camRot.z, 2)

                -- ---- aim ray ----
                local ignore = holding and holding.ent or PlayerPedId()
                local hit, coords, normal = camRay(camPos, fwd, ignore)

                -- ---- ghost follow ----
                if holding and DoesEntityExist(holding.ent) then
                    -- scroll rotate (yaw); SHIFT for big steps
                    local step = IsDisabledControlPressed(0, K.fast) and E.rotateStepFast or E.rotateStep
                    if IsDisabledControlJustPressed(0, K.rotRight) then yaw = (yaw + step) % 360.0 end
                    if IsDisabledControlJustPressed(0, K.rotLeft)  then yaw = (yaw - step) % 360.0 end

                    local target = hit and coords or (camPos + fwd * E.placeDistance)
                    if grid then target = snapGrid(target, E.gridSize) end
                    SetEntityCoordsNoOffset(holding.ent, target.x, target.y, target.z, false, false, false)

                    if surface and hit and normal then
                        local pP = math.deg(math.asin(clamp(normal.y, -1, 1)))
                        local rR = -math.deg(math.asin(clamp(normal.x, -1, 1)))
                        SetEntityRotation(holding.ent, pP, rR, yaw, 2, true)
                    else
                        SetEntityRotation(holding.ent, pitch, roll, yaw, 2, true)
                    end

                    -- place / cancel
                    if IsDisabledControlJustPressed(0, K.place) then commit() end
                    if IsDisabledControlJustPressed(0, K.cancel) then
                        Editor.dropGhost(true); Editor.setCursor(true)
                    end
                else
                    -- not holding: click to grab, DELETE to remove
                    if IsDisabledControlJustPressed(0, K.place) and hit then
                        local _, _, _, entity = camRay(camPos, fwd, PlayerPedId())
                        if entity and entity ~= 0 then grabAt(entity) end
                    end
                    if IsDisabledControlJustPressed(0, K.remove) and hit then
                        local _, _, _, entity = camRay(camPos, fwd, PlayerPedId())
                        if entity and entity ~= 0 then
                            for objId, ent in pairs(State.placedObjects) do
                                if ent == entity then
                                    TriggerServerEvent('lr_properties:removeObject', Editor.propertyId, objId)
                                    ShowNotify(_U('removed'), 'success')
                                    break
                                end
                            end
                        end
                    end
                    if IsDisabledControlJustPressed(0, K.cancel) then Editor.setCursor(true) end
                end

                Editor.drawCrosshair()
            end
        end
    end)
end

function Editor.drawCrosshair()
    DrawRect(0.5, 0.5, 0.004, 0.007, 255, 159, 10, 200)
    DrawRect(0.5, 0.5, 0.010, 0.003, 255, 159, 10, 200)
end

-- ============================================================
--  NUI callbacks from the decorator panel
-- ============================================================
RegisterNUICallback('decoratorPick', function(data, cb)
    if data and data.model then
        if data.manual then Editor.pickManual(data.model) else Editor.pick(data.model) end
    end
    cb('ok')
end)

RegisterNUICallback('decoratorTool', function(data, cb)
    local a = data and data.action
    if a == 'grid' then grid = not grid
    elseif a == 'surface' then surface = not surface
    elseif a == 'functional' then
        -- place a functional access point (storage / wardrobe / safe)
        Editor.placeAccessPoint(data.kind)
    elseif a == 'done' then Editor.Stop(); return cb('ok')
    end
    SendNUIMessage({ action = 'decoratorState', cursor = Editor.cursor, grid = grid, surface = surface })
    cb('ok')
end)

-- access point uses the same follow-and-click flow, but commits an access point
function Editor.placeAccessPoint(kind)
    if not (kind == 'storage' or kind == 'wardrobe' or kind == 'safe') then return end
    Editor.dropGhost(true)
    yaw, pitch, roll = 0.0, 0.0, 0.0
    local model = Config.AccessPoint and Config.AccessPoint.ghostModel or 'prop_mp_arrow_barrier_01'
    holding = { kind = 'access', accessKind = kind, ent = makeGhost(model), model = model }
    Editor.setCursor(false)
end

-- extend commit for access points
local _origCommit = commit
commit = function()
    if holding and holding.kind == 'access' then
        local pos = GetEntityCoords(holding.ent)
        TriggerServerEvent('lr_properties:addAccessPoint', Editor.propertyId, holding.accessKind,
            { x = pos.x, y = pos.y, z = pos.z })
        if DoesEntityExist(holding.ent) then DeleteEntity(holding.ent) end
        holding = nil
        ShowNotify(_U('access_placed'), 'success')
        Editor.setCursor(true)
        return
    end
    _origCommit()
end

-- ============================================================
--  public API (kept for menu.lua compatibility)
-- ============================================================
function StartDecorate(propertyId) Editor.Start(propertyId) end
function StopDecorate() Editor.Stop() end
function StartRemoveMode()
    Editor.Start(State.inside)
    ShowNotify(_U('remove_hint'), 'info')
end
function OpenCatalog() end  -- catalog is now the docked editor panel

-- start the editor and immediately begin placing an access point
function Editor.StartAndPlaceAccess(propertyId, kind)
    Editor.Start(propertyId)
    SetTimeout(300, function()
        if Editor.active then Editor.placeAccessPoint(kind) end
    end)
end

-- cleanup if the resource stops mid-edit
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and Editor.active then
        RenderScriptCams(false, false, 0, true, false)
        if cam then DestroyCam(cam, false) end
        local ped = PlayerPedId()
        FreezeEntityPosition(ped, false); SetEntityVisible(ped, true, false)
        SetNuiFocus(false, false)
    end
end)
