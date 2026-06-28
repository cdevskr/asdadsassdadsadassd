-- ============================================================
--  SERVER MAIN
--  Client sync of property data + permission helpers + notify.
-- ============================================================

-- ----- notify helper (custom NUI on client) -----
function Notify(src, msg, kind)
    TriggerClientEvent('lr_properties:notify', src, msg, kind or 'info')
end

-- ----- send a single property's public data to a client -----
local function publicData(p)
    return {
        id = p.id, label = p.label, type = p.type, owner = p.owner, owner_name = p.owner_name,
        door = p.door, interior = { id = p.interior and p.interior.id }, exit = p.exit, price = p.price, rent_price = p.rent_price,
        locked = p.locked, for_sale = p.for_sale, entry_fee = p.entry_fee, tenure = p.tenure,
        access = p.access,
    }
end

-- full snapshot of doors (no objects until the player actually enters)
RegisterNetEvent('lr_properties:requestSync', function()
    local src = source
    local list = {}
    for _, p in pairs(Properties) do list[#list + 1] = publicData(p) end
    TriggerClientEvent('lr_properties:sync', src, list)
end)

-- push a single property update to everyone
function SyncProperty(id)
    local p = Properties[id]; if not p then return end
    TriggerClientEvent('lr_properties:updateOne', -1, publicData(p))
end

function RemoveProperty(id)
    TriggerClientEvent('lr_properties:removeOne', -1, id)
end

-- ============================================================
--  ACCESS / PERMISSION
-- ============================================================
function IsOwner(src, p)
    if not p or not p.owner then return false end
    return Bridge.GetIdentifier(src) == p.owner
end

function HasKey(src, p)
    if not p then return false end
    local id = Bridge.GetIdentifier(src)
    if id == p.owner then return true end
    return p.keys[id] ~= nil
end

function IsEmployee(src, p)
    if not p then return false end
    return p.employees[Bridge.GetIdentifier(src)] ~= nil
end

function EmployeeGrade(src, p)
    if not p then return nil end
    if IsOwner(src, p) then return math.huge end
    local e = p.employees[Bridge.GetIdentifier(src)]
    return e and e.grade or nil
end

-- can this player open the management menu?
function CanManage(src, p, right)
    if IsOwner(src, p) then return true end
    local grade = EmployeeGrade(src, p)
    if not grade then return false end
    if grade == math.huge then return true end
    return Utils.gradeRight(grade, right)
end

function IsRealtor(src)
    return Realtors[Bridge.GetIdentifier(src)] ~= nil
end

function IsAdmin(src)
    return IsPlayerAceAllowed(src, Config.AdminAce)
end

-- expose a server callback so the client can ask "what can I do here?"
lib_callbacks = {}  -- minimal request/response over events

RegisterNetEvent('lr_properties:queryAccess', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    TriggerClientEvent('lr_properties:accessResult', src, propertyId, {
        owner    = IsOwner(src, p),
        key      = HasKey(src, p),
        employee = IsEmployee(src, p),
        grade    = EmployeeGrade(src, p),
        realtor  = IsRealtor(src),
        manage   = CanManage(src, p, 'canManageStash'),
        lock     = IsOwner(src, p) or CanManage(src, p, 'canLock'),
        decorate = IsOwner(src, p) or CanManage(src, p, 'canDecorate'),
        staff    = IsOwner(src, p) or CanManage(src, p, 'canManageStaff'),
    })
end)

-- ============================================================
--  INSTANCING (routing buckets) + RESPAWN-INSIDE persistence
-- ============================================================
InsideOf = {}   -- [src] = propertyId (live, this session)

function PropertyBucket(p)
    return Config.Bucket.base + p.id
end

-- put a player into a property's private instance
function EnterBucket(src, p)
    InsideOf[src] = p.id
    if Config.Bucket.enabled then
        local b = PropertyBucket(p)
        SetPlayerRoutingBucket(src, b)
        SetRoutingBucketEntityLockdownMode(b, Config.Bucket.lockdown or 'strict')
        SetRoutingBucketPopulationEnabled(b, Config.Bucket.populationEnabled and true or false)
    end
    DB_SetInside(Bridge.GetIdentifier(src), p.id)
end

-- send a player back to the open world (bucket 0)
function LeaveBucket(src, keepRecord)
    InsideOf[src] = nil
    if Config.Bucket.enabled then SetPlayerRoutingBucket(src, 0) end
    if not keepRecord then DB_ClearInside(Bridge.GetIdentifier(src)) end
end

-- client reports it has fully exited the interior
RegisterNetEvent('lr_properties:exited', function()
    local src = source
    LeaveBucket(src, false)
end)

-- client booted & synced -> if it was inside a property at logout, send it back in
RegisterNetEvent('lr_properties:playerReady', function()
    local src = source
    local ident = Bridge.GetIdentifier(src)
    local pid = ident and InsideSaved[ident]
    if not pid then return end
    local p = Properties[pid]
    if not p then DB_ClearInside(ident); return end  -- property gone, drop the record
    EnterBucket(src, p)
    -- small delay so the client has processed the property sync first
    SetTimeout(800, function()
        if GetPlayerName(src) then
            TriggerClientEvent('lr_properties:enterApproved', src, pid)
        end
    end)
end)

-- player disconnected: clear live state but KEEP the DB record so they
-- respawn inside next time. (bucket resets automatically on disconnect.)
AddEventHandler('playerDropped', function()
    local src = source
    InsideOf[src] = nil
end)
