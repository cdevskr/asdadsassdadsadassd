-- ============================================================
--  CLIENT INTERACTION
--  Three door-interaction modes; pick via Config.Interaction.mode.
--    marker  -> floating marker + [E]
--    target  -> ox_target / qb-target zone
--    command -> /property on the nearest door
-- ============================================================

local targetHandles = {}   -- propertyId -> handle (target mode)

-- find nearest door within range
local function nearestDoor(maxDist)
    local pc = GetEntityCoords(PlayerPedId())
    local bestId, bestDist
    for id, p in pairs(State.doors) do
        if p.door then
            local d = #(pc - vector3(p.door.x, p.door.y, p.door.z))
            if d < (maxDist or Config.Interaction.drawDist) and (not bestDist or d < bestDist) then
                bestId, bestDist = id, d
            end
        end
    end
    return bestId, bestDist
end

-- open the right menu for a door (handled in menu.lua)
function InteractDoor(propertyId)
    if State.inside then return end
    OpenPropertyMenu(propertyId)
end

-- ============================================================
--  MARKER MODE
-- ============================================================
local function markerLoop()
    while true do
        local sleep = 500
        if Config.Interaction.mode == 'marker' and not State.inside and not NUI.open then
            local pc = GetEntityCoords(PlayerPedId())
            for id, p in pairs(State.doors) do
                if p.door then
                    local dc = vector3(p.door.x, p.door.y, p.door.z)
                    local d = #(pc - dc)
                    if d < Config.Interaction.drawDist then
                        sleep = 0
                        local c = Config.Interaction.markerColor
                        DrawMarker(Config.Interaction.markerType, dc.x, dc.y, dc.z,
                            0,0,0, 0,0,0,
                            Config.Interaction.markerSize.x, Config.Interaction.markerSize.y, Config.Interaction.markerSize.z,
                            c.r, c.g, c.b, c.a, false, true, 2, nil, nil, false)
                        if d < Config.Interaction.interactDist then
                            local label = p.locked and _U('press_interact') or _U('press_interact')
                            BeginTextCommandDisplayHelp('STRING')
                            AddTextComponentSubstringPlayerName(label)
                            EndTextCommandDisplayHelp(0, false, true, -1)
                            if IsControlJustReleased(0, Config.Interaction.interactKey) then
                                InteractDoor(id)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end

-- ============================================================
--  TARGET MODE
-- ============================================================
local function rebuildTargets()
    if Config.Interaction.mode ~= 'target' or not Bridge.target then return end
    for id, h in pairs(targetHandles) do
        Bridge.RemoveDoorTarget(h, id)
    end
    targetHandles = {}
    for id, p in pairs(State.doors) do
        if p.door then
            targetHandles[id] = Bridge.AddDoorTarget(id, p.door, function() InteractDoor(id) end)
        end
    end
end

-- ============================================================
--  COMMAND MODE
-- ============================================================
RegisterCommand(Config.Interaction.command, function()
    if Config.Interaction.mode ~= 'command' then return end
    if State.inside then ExitProperty(); return end
    local id, d = nearestDoor(Config.Interaction.interactDist + 1.0)
    if id then InteractDoor(id) else ShowNotify(_U('press_interact'), 'info') end
end, false)

-- ============================================================
--  IN-PROPERTY MENU  (works in every interaction mode)
--  Inside  -> management menu for the property you're in.
--  Outside -> nearest door menu.
-- ============================================================
RegisterCommand(Config.Interaction.menuCommand, function()
    if NUI.open then return end
    if State.inside then
        local pid = State.inside
        QueryAccess(pid, function(acc)
            OpenManageMenu(pid, acc)
        end)
    else
        local id = nearestDoor(Config.Interaction.interactDist + 1.5)
        if id then InteractDoor(id) else ShowNotify(_U('press_interact'), 'info') end
    end
end, false)

-- let players rebind the key in GTA Settings > Key Bindings > FiveM
RegisterKeyMapping(Config.Interaction.menuCommand, 'Mülk menüsü', 'keyboard', Config.Interaction.menuKey)

-- ============================================================
--  BOOT
-- ============================================================
CreateThread(function()
    Wait(2000)
    if Config.Interaction.mode == 'marker' then
        markerLoop()
    end
end)

AddEventHandler('lr_properties:doorsUpdated', function()
    if Config.Interaction.mode == 'target' then
        rebuildTargets()
    end
end)

-- target resource detected (possibly after doors already synced) -> build now
AddEventHandler('lr_properties:targetReady', function()
    if Config.Interaction.mode == 'target' then
        rebuildTargets()
    end
end)
