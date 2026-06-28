-- ============================================================
--  CLIENT DOORBELL / KNOCK
--  When outside a locked door without access, [E] knocks.
--  Owner / key holders get a notification + a marker showing which door.
-- ============================================================

local knockHint = nil   -- propertyId being shown a knock marker

-- knock at the nearest locked door we don't have access to
local function tryKnock()
    if not Config.Keys.doorbell then return end
    local pc = GetEntityCoords(PlayerPedId())
    for id, p in pairs(State.doors) do
        if p.door and p.locked then
            local d = #(pc - vector3(p.door.x, p.door.y, p.door.z))
            if d < 1.6 then
                TriggerServerEvent('lr_properties:knock', id)
                return
            end
        end
    end
end

-- show a knock prompt when standing at a locked door (marker mode reuses E,
-- so only show the knock help when the property menu wouldn't normally open
-- for us — i.e. we have no access). The server still validates everything.
CreateThread(function()
    while true do
        local sleep = 600
        if Config.Keys.doorbell and not State.inside and not NUI.open then
            local pc = GetEntityCoords(PlayerPedId())
            for id, p in pairs(State.doors) do
                if p.door and p.locked then
                    local d = #(pc - vector3(p.door.x, p.door.y, p.door.z))
                    if d < 1.6 then
                        sleep = 0
                        BeginTextCommandDisplayHelp('STRING')
                        AddTextComponentSubstringPlayerName(_U('press_knock'))
                        EndTextCommandDisplayHelp(0, false, true, -1)
                        if IsControlJustReleased(0, Config.Keys.knockKey) then
                            -- only knock if menu interaction isn't the primary (it opens anyway);
                            -- a small debounce avoids double-trigger with the marker E
                            tryKnock()
                            Wait(800)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- owner / key holder receives the knock: flash a marker over the door for 8s
RegisterNetEvent('lr_properties:knockReceived', function(propertyId)
    knockHint = propertyId
    SetTimeout(8000, function()
        if knockHint == propertyId then knockHint = nil end
    end)
end)

CreateThread(function()
    while true do
        if knockHint then
            local p = State.doors[knockHint]
            if p and p.door then
                DrawMarker(2, p.door.x, p.door.y, p.door.z + 1.2, 0,0,0, 180.0,0,0,
                    0.4,0.4,0.4, 255,210,90,200, true,false,2,nil,nil,false)
            end
            Wait(0)
        else
            Wait(400)
        end
    end
end)
