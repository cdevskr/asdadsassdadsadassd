-- ============================================================
--  DATABASE LAYER
--  In-memory cache of all properties, synced to MySQL.
--  Properties[id] = { ...row, objects = {}, keys = {}, employees = {} }
-- ============================================================
Properties = {}
Realtors   = {}   -- identifier -> name

local function hydrate(row)
    row.door     = Utils.dec(row.door)
    row.interior = Utils.dec(row.interior)
    row.exit     = row.exit and Utils.dec(row.exit) or nil
    row.objects   = {}
    row.keys      = {}
    row.employees = {}
    row.access    = {}
    row.locked   = row.locked == 1
    row.for_sale = row.for_sale == 1
    Properties[row.id] = row
end

-- ----- initial load -----
CreateThread(function()
    while GetResourceState('oxmysql') ~= 'started' do Wait(100) end

    local props = MySQL.query.await('SELECT * FROM lr_properties') or {}
    for _, row in ipairs(props) do hydrate(row) end

    local objs = MySQL.query.await('SELECT * FROM lr_property_objects') or {}
    for _, o in ipairs(objs) do
        local p = Properties[o.property_id]
        if p then
            p.objects[o.id] = { id = o.id, model = o.model, pos = Utils.dec(o.pos), rot = Utils.dec(o.rot) }
        end
    end

    local keys = MySQL.query.await('SELECT * FROM lr_property_keys') or {}
    for _, k in ipairs(keys) do
        local p = Properties[k.property_id]
        if p then p.keys[k.identifier] = k.holder_name or true end
    end

    local emps = MySQL.query.await('SELECT * FROM lr_property_employees') or {}
    for _, e in ipairs(emps) do
        local p = Properties[e.property_id]
        if p then p.employees[e.identifier] = { name = e.name, grade = e.grade, salary = e.salary } end
    end

    local rls = MySQL.query.await('SELECT * FROM lr_realtors') or {}
    for _, r in ipairs(rls) do Realtors[r.identifier] = r.name or true end

    -- who was inside a property at last shutdown (for respawn-inside-on-relog)
    InsideSaved = {}
    local ins = MySQL.query.await('SELECT * FROM lr_inside') or {}
    for _, row in ipairs(ins) do InsideSaved[row.identifier] = row.property_id end

    -- placeable access points (storage / wardrobe / safe)
    local aps = MySQL.query.await('SELECT * FROM lr_access_points') or {}
    for _, a in ipairs(aps) do
        local p = Properties[a.property_id]
        if p then p.access[a.id] = { id = a.id, type = a.type, pos = Utils.dec(a.pos) } end
    end

    print(('^2[lr_properties]^7 loaded %s properties, %s realtors'):format(#props, #rls))
    TriggerEvent('lr_properties:loaded')
end)

-- ============================================================
--  DB - property
-- ============================================================
function DB_CreateProperty(data, cb)
    MySQL.insert('INSERT INTO lr_properties (label, type, door, interior, price, rent_price, entry_fee, for_sale, locked) VALUES (?, ?, ?, ?, ?, ?, ?, 1, 1)',
        { data.label, data.type, Utils.enc(data.door), Utils.enc(data.interior), data.price or 0, data.rent_price or 0, data.entry_fee or 0 },
        function(id)
            if id then
                local row = {
                    id = id, label = data.label, type = data.type, owner = nil, owner_name = nil,
                    tenure = nil, rent_due = nil, tax_due = nil, door = data.door, interior = data.interior,
                    price = data.price or 0, rent_price = data.rent_price or 0, locked = true, for_sale = true,
                    entry_fee = data.entry_fee or 0, safe_balance = 0, objects = {}, keys = {}, employees = {},
                }
                Properties[id] = row
            end
            if cb then cb(id) end
        end)
end

-- explicit "set this column to SQL NULL" sentinel.
-- (passing Lua nil in a table constructor just omits the key, so we
--  need a real value to signal an intentional clear.)
DB_NULL = setmetatable({}, { __tostring = function() return 'NULL' end })

function DB_UpdateProperty(id, fields)
    local p = Properties[id]; if not p then return end
    local sets, vals = {}, {}
    for k, v in pairs(fields) do
        if v == DB_NULL then
            p[k] = nil
            -- column names here are code constants, safe to inline
            sets[#sets + 1] = ('`%s` = NULL'):format(k)
        else
            p[k] = v
            sets[#sets + 1] = ('`%s` = ?'):format(k)
            if k == 'door' or k == 'interior' or k == 'exit' then v = Utils.enc(v)
            elseif type(v) == 'boolean' then v = v and 1 or 0 end
            vals[#vals + 1] = v
        end
    end
    vals[#vals + 1] = id
    MySQL.update(('UPDATE lr_properties SET %s WHERE id = ?'):format(table.concat(sets, ', ')), vals)
end

function DB_DeleteProperty(id)
    Properties[id] = nil
    MySQL.update('DELETE FROM lr_properties WHERE id = ?', { id })
    MySQL.update('DELETE FROM lr_property_objects WHERE property_id = ?', { id })
    MySQL.update('DELETE FROM lr_property_keys WHERE property_id = ?', { id })
    MySQL.update('DELETE FROM lr_property_employees WHERE property_id = ?', { id })
end

-- ============================================================
--  DB - objects (decoration)
-- ============================================================
function DB_AddObject(propertyId, model, pos, rot, cb)
    MySQL.insert('INSERT INTO lr_property_objects (property_id, model, pos, rot) VALUES (?, ?, ?, ?)',
        { propertyId, model, Utils.enc(pos), Utils.enc(rot) },
        function(id)
            local p = Properties[propertyId]
            if p and id then p.objects[id] = { id = id, model = model, pos = pos, rot = rot } end
            if cb then cb(id) end
        end)
end

function DB_UpdateObject(propertyId, objId, pos, rot)
    local p = Properties[propertyId]; if not p or not p.objects[objId] then return end
    p.objects[objId].pos = pos
    p.objects[objId].rot = rot
    MySQL.update('UPDATE lr_property_objects SET pos = ?, rot = ? WHERE id = ?',
        { Utils.enc(pos), Utils.enc(rot), objId })
end

function DB_RemoveObject(propertyId, objId)
    local p = Properties[propertyId]; if not p then return end
    p.objects[objId] = nil
    MySQL.update('DELETE FROM lr_property_objects WHERE id = ?', { objId })
end

-- ============================================================
--  DB - keys
-- ============================================================
function DB_AddKey(propertyId, ident, name)
    local p = Properties[propertyId]; if not p then return end
    p.keys[ident] = name or true
    MySQL.insert('INSERT INTO lr_property_keys (property_id, identifier, holder_name) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE holder_name = VALUES(holder_name)',
        { propertyId, ident, name })
end

function DB_RemoveKey(propertyId, ident)
    local p = Properties[propertyId]; if not p then return end
    p.keys[ident] = nil
    MySQL.update('DELETE FROM lr_property_keys WHERE property_id = ? AND identifier = ?', { propertyId, ident })
end

-- ============================================================
--  DB - employees
-- ============================================================
function DB_AddEmployee(propertyId, ident, name, grade, salary)
    local p = Properties[propertyId]; if not p then return end
    p.employees[ident] = { name = name, grade = grade, salary = salary }
    MySQL.insert('INSERT INTO lr_property_employees (property_id, identifier, name, grade, salary) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE grade = VALUES(grade), salary = VALUES(salary)',
        { propertyId, ident, name, grade, salary })
end

function DB_RemoveEmployee(propertyId, ident)
    local p = Properties[propertyId]; if not p then return end
    p.employees[ident] = nil
    MySQL.update('DELETE FROM lr_property_employees WHERE property_id = ? AND identifier = ?', { propertyId, ident })
end

-- ============================================================
--  DB - realtors
-- ============================================================
function DB_AddRealtor(ident, name)
    Realtors[ident] = name or true
    MySQL.insert('INSERT INTO lr_realtors (identifier, name) VALUES (?, ?) ON DUPLICATE KEY UPDATE name = VALUES(name)',
        { ident, name })
end

function DB_RemoveRealtor(ident)
    Realtors[ident] = nil
    MySQL.update('DELETE FROM lr_realtors WHERE identifier = ?', { ident })
end

-- ============================================================
--  DB - inside state (respawn inside on relog)
-- ============================================================
InsideSaved = InsideSaved or {}

function DB_SetInside(ident, propertyId)
    if not ident then return end
    InsideSaved[ident] = propertyId
    MySQL.insert('INSERT INTO lr_inside (identifier, property_id) VALUES (?, ?) ON DUPLICATE KEY UPDATE property_id = VALUES(property_id)',
        { ident, propertyId })
end

function DB_ClearInside(ident)
    if not ident then return end
    InsideSaved[ident] = nil
    MySQL.update('DELETE FROM lr_inside WHERE identifier = ?', { ident })
end

-- ============================================================
--  DB - access points
-- ============================================================
function DB_AddAccessPoint(propertyId, kind, pos, cb)
    local p = Properties[propertyId]; if not p then return end
    MySQL.insert('INSERT INTO lr_access_points (property_id, type, pos) VALUES (?, ?, ?)',
        { propertyId, kind, Utils.enc(pos) }, function(id)
        if id then p.access[id] = { id = id, type = kind, pos = pos } end
        if cb then cb(id) end
    end)
end

function DB_RemoveAccessPoint(propertyId, id)
    local p = Properties[propertyId]; if not p then return end
    p.access[id] = nil
    MySQL.update('DELETE FROM lr_access_points WHERE id = ?', { id })
end
