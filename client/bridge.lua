-- ============================================================
--  CLIENT BRIDGE
--  Detects ox_target / qb-target for the 'target' interaction mode.
-- ============================================================
Bridge = { target = nil }

-- ox_target / qb-target may start AFTER us, so keep checking for a while
-- instead of a single one-shot check (that race made target mode silently fail).
CreateThread(function()
    local tries = 0
    while Bridge.target == nil and tries < 75 do
        if GetResourceState('ox_target') == 'started' then
            Bridge.target = 'ox'
        elseif GetResourceState('qb-target') == 'started' then
            Bridge.target = 'qb'
        end
        if Bridge.target then
            TriggerEvent('lr_properties:targetReady')   -- interaction.lua rebuilds zones
            if Config.Debug then print('^2[lr_properties]^7 target system: ' .. Bridge.target) end
            return
        end
        tries = tries + 1
        Wait(200)
    end
    if Config.Interaction.mode == 'target' and not Bridge.target then
        print('^1[lr_properties]^7 Interaction.mode = target ama ox_target/qb-target bulunamadı!')
    end
end)

-- add a boxzone target at a door (used by interaction.lua in target mode)
function Bridge.AddDoorTarget(propertyId, coords, onSelect)
    if Bridge.target == 'ox' then
        return exports.ox_target:addBoxZone({
            coords = vector3(coords.x, coords.y, coords.z),
            size   = vector3(1.5, 1.5, 2.5),
            rotation = coords.h or 0.0,
            options = {{
                name  = 'lr_prop_' .. propertyId,
                label = Config.Interaction.targetLabel,
                icon  = Config.Interaction.targetIcon,
                onSelect = function() onSelect() end,
                distance = 2.0,
            }},
        })
    elseif Bridge.target == 'qb' then
        local name = 'lr_prop_' .. propertyId
        exports['qb-target']:AddBoxZone(name, vector3(coords.x, coords.y, coords.z), 1.5, 1.5, {
            name = name, heading = coords.h or 0.0, minZ = coords.z - 1.5, maxZ = coords.z + 1.5,
        }, {
            options = {{ label = Config.Interaction.targetLabel, icon = Config.Interaction.targetIcon, action = function() onSelect() end }},
            distance = 2.0,
        })
        return name
    end
end

function Bridge.RemoveDoorTarget(handle, propertyId)
    if Bridge.target == 'ox' and handle then
        exports.ox_target:removeZone(handle)
    elseif Bridge.target == 'qb' then
        exports['qb-target']:RemoveZone('lr_prop_' .. propertyId)
    end
end
