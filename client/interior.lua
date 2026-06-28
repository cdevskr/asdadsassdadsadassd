-- ============================================================
--  CLIENT INTERIOR
--  Loads the three interior kinds and teleports the player.
--    ipl    -> RequestIpl + teleport to spawn
--    shell  -> spawn shell object at a hidden instance point + teleport
--    custom -> teleport to an empty void; player builds everything
-- ============================================================

local function loadModel(model)
    local hash = type(model) == 'number' and model or GetHashKey(model)
    RequestModel(hash)
    local t = GetGameTimer()
    while not HasModelLoaded(hash) and GetGameTimer() - t < 8000 do Wait(10) end
    return hash
end

local function fadeOut()  DoScreenFadeOut(400); while not IsScreenFadedOut() do Wait(0) end end
local function fadeIn()   DoScreenFadeIn(500) end

-- ---------- ENTER ----------
-- returns a runtime table describing what we created (for cleanup on exit)
function LoadInterior(p)
    local def = p.interior
    if not def or not def.id then return nil end
    local meta = Config.InteriorById[def.id]
    if not meta then return nil end

    local runtime = { kind = meta.kind, shell = nil, exit = nil, spawn = nil }

    fadeOut()

    if meta.kind == 'ipl' then
        for _, ipl in ipairs(meta.ipl or {}) do
            if not IsIplActive(ipl) then RequestIpl(ipl) end
        end
        runtime.spawn = meta.spawn
        runtime.exit  = meta.exit

    elseif meta.kind == 'shell' then
        -- with routing buckets every instance is isolated, so all shells can
        -- share one origin. (fallback to a spread when buckets are disabled.)
        local base = (Config.Bucket and Config.Bucket.enabled) and Config.ShellBase or meta.instance
        local off  = (Config.Bucket and Config.Bucket.enabled) and 0.0 or (p.id % 50) * 8.0
        local origin = vector3(base.x + off, base.y, base.z)
        -- native shell creation (this is the whole qb-interior "shell" logic):
        -- spawn the shell prop, freeze it. If the configured model isn't
        -- streamed, gracefully fall back so the interior never breaks.
        local hash = loadModel(meta.model)
        if not HasModelLoaded(hash) then hash = loadModel(Config.ShellFallbackModel) end
        local shell = CreateObject(hash, origin.x, origin.y, origin.z, false, false, false)
        SetEntityCoordsNoOffset(shell, origin.x, origin.y, origin.z, false, false, false)
        FreezeEntityPosition(shell, true)
        SetModelAsNoLongerNeeded(hash)
        runtime.shell = shell
        local so = meta.spawnOffset
        runtime.spawn = vector4(origin.x + so.x, origin.y + so.y, origin.z + so.z, so.w)
        local eo = meta.exitOffset
        runtime.exit  = vector3(origin.x + eo.x, origin.y + eo.y, origin.z + eo.z)

    elseif meta.kind == 'custom' then
        -- empty void; buckets isolate, so a shared canvas point is fine
        local s = meta.spawn
        local off = (Config.Bucket and Config.Bucket.enabled) and 0.0 or (p.id % 50) * 12.0
        runtime.spawn = vector4(s.x + off, s.y, s.z, s.w)
        runtime.exit  = vector3(s.x + off + meta.exit.x, s.y + meta.exit.y, s.z + (meta.exit.z - s.z))
    end

    -- per-property saved exit overrides the config exit (placed by the owner)
    if p.exit and p.exit.x then
        runtime.exit = vector3(p.exit.x + 0.0, p.exit.y + 0.0, p.exit.z + 0.0)
        -- also use the saved exit as the spawn point so players always land there
        local heading = runtime.spawn and runtime.spawn.w or 0.0
        runtime.spawn = vector4(p.exit.x + 0.0, p.exit.y + 0.0, p.exit.z + 0.0, heading)
    end

    -- teleport in
    local sp = runtime.spawn
    local ped = PlayerPedId()
    SetEntityCoords(ped, sp.x, sp.y, sp.z, false, false, false, false)
    SetEntityHeading(ped, sp.w or 0.0)
    Wait(400)
    fadeIn()
    return runtime
end

-- ---------- EXIT ----------
function UnloadInterior(p, runtime, returnCoords)
    fadeOut()
    if runtime then
        if runtime.kind == 'ipl' then
            local meta = Config.InteriorById[p.interior.id]
            for _, ipl in ipairs(meta and meta.ipl or {}) do
                if IsIplActive(ipl) then RemoveIpl(ipl) end
            end
        elseif runtime.shell then
            -- shell may be a single entity or a table of entities (qb-interior)
            if type(runtime.shell) == 'table' then
                for _, ent in pairs(runtime.shell) do
                    if type(ent) == 'number' and DoesEntityExist(ent) then DeleteEntity(ent) end
                end
            elseif DoesEntityExist(runtime.shell) then
                DeleteEntity(runtime.shell)
            end
        end
    end
    local ped = PlayerPedId()
    local d = p.door
    SetEntityCoords(ped, d.x, d.y, d.z, false, false, false, false)
    SetEntityHeading(ped, d.h or 0.0)
    Wait(400)
    fadeIn()
end
