-- ============================================================
--  SERVER - PROPERTY LOGIC
--  Buy / rent / sell / lock / decorate (object CRUD) / doorbell.
-- ============================================================

-- ----- BUY (one-time purchase) -----
RegisterNetEvent('lr_properties:buy', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not Config.Ownership.allowBuy then return end
    if not p.for_sale or p.owner then Notify(src, _U('not_for_sale'), 'error'); return end

    local price = p.price
    if Bridge.GetCash(src) < price then
        Notify(src, _U('not_enough_cash', Utils.money(price)), 'error'); return
    end
    if not Bridge.RemoveCash(src, price) then
        Notify(src, _U('not_enough_cash', Utils.money(price)), 'error'); return
    end

    local ident = Bridge.GetIdentifier(src)
    local name  = Bridge.GetName(src)
    DB_UpdateProperty(propertyId, {
        owner = ident, owner_name = name, tenure = 'buy', for_sale = false, locked = true,
        tax_due = Config.Tax.enabled and (Utils.now() + Config.Tax.interval) or DB_NULL,
        rent_due = DB_NULL,
    })
    SyncProperty(propertyId)
    Notify(src, _U('bought_property', p.label, Utils.money(price)), 'success')

    -- realtor commission
    PayCommission(p, price)
end)

-- ----- RENT (periodic) -----
RegisterNetEvent('lr_properties:rent', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not Config.Ownership.allowRent then return end
    if not p.for_sale or p.owner then Notify(src, _U('not_for_sale'), 'error'); return end

    local first = p.rent_price
    if Bridge.GetCash(src) < first then
        Notify(src, _U('not_enough_cash', Utils.money(first)), 'error'); return
    end
    if not Bridge.RemoveCash(src, first) then return end

    local ident = Bridge.GetIdentifier(src)
    DB_UpdateProperty(propertyId, {
        owner = ident, owner_name = Bridge.GetName(src), tenure = 'rent', for_sale = false, locked = true,
        rent_due = Utils.now() + Config.Ownership.rentInterval,
        tax_due  = Config.Tax.enabled and (Utils.now() + Config.Tax.interval) or DB_NULL,
    })
    SyncProperty(propertyId)
    Notify(src, _U('rented_property', p.label, Utils.money(first)), 'success')
    PayCommission(p, first)
end)

-- ----- SELL BACK / RELEASE -----
RegisterNetEvent('lr_properties:sell', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not IsOwner(src, p) then Notify(src, _U('no_permission'), 'error'); return end

    -- refund 50% of price on buy tenure
    if p.tenure == 'buy' then
        Bridge.AddCash(src, math.floor(p.price * 0.5))
    end
    ReleaseProperty(propertyId)
    Notify(src, _U('sold_property'), 'success')
end)

-- release ownership back to market (sell / evict / repossess)
function ReleaseProperty(propertyId)
    local p = Properties[propertyId]; if not p then return end
    -- wipe keys + employees, keep decoration objects (interior stays)
    for ident in pairs(p.keys) do DB_RemoveKey(propertyId, ident) end
    for ident in pairs(p.employees) do DB_RemoveEmployee(propertyId, ident) end
    DB_UpdateProperty(propertyId, {
        owner = DB_NULL, owner_name = DB_NULL, tenure = DB_NULL, for_sale = true, locked = true,
        rent_due = DB_NULL, tax_due = DB_NULL, entry_fee = p.type == 'business' and p.entry_fee or 0,
        safe_balance = 0,
    })
    SyncProperty(propertyId)
end

-- ============================================================
--  ACCESS POINTS  (placeable storage / wardrobe / safe)
-- ============================================================
RegisterNetEvent('lr_properties:addAccessPoint', function(propertyId, kind, pos)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not (IsOwner(src, p) or CanManage(src, p, 'canDecorate')) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    if not (kind == 'storage' or kind == 'wardrobe' or kind == 'safe') then return end
    if type(pos) ~= 'table' or not pos.x then return end
    DB_AddAccessPoint(propertyId, kind, { x = pos.x + 0.0, y = pos.y + 0.0, z = pos.z + 0.0 }, function(id)
        if id then SyncProperty(propertyId) end
    end)
end)

RegisterNetEvent('lr_properties:removeAccessPoint', function(propertyId, id)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not (IsOwner(src, p) or CanManage(src, p, 'canDecorate')) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    DB_RemoveAccessPoint(propertyId, id)
    SyncProperty(propertyId)
end)

-- ----- SET INTERIOR EXIT (placed on first entry / from manage menu) -----
RegisterNetEvent('lr_properties:setExit', function(propertyId, pos)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    -- owner, a realtor/admin, or someone with decorate rights may set it
    if not (IsOwner(src, p) or IsRealtor(src) or IsAdmin(src) or CanManage(src, p, 'canDecorate')) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    if type(pos) ~= 'table' or not pos.x then return end
    DB_UpdateProperty(propertyId, { exit = { x = pos.x + 0.0, y = pos.y + 0.0, z = pos.z + 0.0 } })
    SyncProperty(propertyId)
    Notify(src, _U('exit_set'), 'success')
end)

-- ----- LOCK / UNLOCK -----
RegisterNetEvent('lr_properties:toggleLock', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not (IsOwner(src, p) or CanManage(src, p, 'canLock') or HasKey(src, p)) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    DB_UpdateProperty(propertyId, { locked = not p.locked })
    SyncProperty(propertyId)
    Notify(src, p.locked and _U('property_locked_now') or _U('property_unlocked'), 'info')
end)

-- ============================================================
--  DECORATION - object CRUD (gizmo writes here)
-- ============================================================
RegisterNetEvent('lr_properties:placeObject', function(propertyId, model, pos, rot)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canDecorate') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    -- object cap
    local count = 0
    for _ in pairs(p.objects) do count = count + 1 end
    if count >= Config.MaxObjects then
        Notify(src, _U('object_limit', Config.MaxObjects), 'error'); return
    end
    DB_AddObject(propertyId, model, pos, rot, function(id)
        if id then
            TriggerClientEvent('lr_properties:objectPlaced', -1, propertyId, id, model, pos, rot)
        end
    end)
end)

RegisterNetEvent('lr_properties:moveObject', function(propertyId, objId, pos, rot)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canDecorate') and not IsOwner(src, p) then return end
    DB_UpdateObject(propertyId, objId, pos, rot)
    TriggerClientEvent('lr_properties:objectMoved', -1, propertyId, objId, pos, rot)
end)

RegisterNetEvent('lr_properties:removeObject', function(propertyId, objId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canDecorate') and not IsOwner(src, p) then return end
    DB_RemoveObject(propertyId, objId)
    TriggerClientEvent('lr_properties:objectRemoved', -1, propertyId, objId)
end)

-- client asks for the object list when entering
RegisterNetEvent('lr_properties:requestObjects', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    local list = {}
    for _, o in pairs(p.objects) do list[#list + 1] = o end
    TriggerClientEvent('lr_properties:objectList', src, propertyId, list)
end)

-- ============================================================
--  ENTRY (charges business entry fee here, server-authoritative)
-- ============================================================
RegisterNetEvent('lr_properties:tryEnter', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end

    -- locked? only people with access pass
    if p.locked and not HasKey(src, p) and not IsEmployee(src, p) then
        Notify(src, _U('property_locked'), 'error'); return
    end

    -- business entry fee (skip for owner / staff / key holders)
    if p.type == 'business' and p.entry_fee > 0
        and not IsOwner(src, p) and not IsEmployee(src, p) and not HasKey(src, p) then
        if Bridge.GetCash(src) < p.entry_fee then
            Notify(src, _U('not_enough_cash', Utils.money(p.entry_fee)), 'error'); return
        end
        Bridge.RemoveCash(src, p.entry_fee)
        -- the entry fee goes into the business cash safe
        DB_UpdateProperty(propertyId, { safe_balance = p.safe_balance + p.entry_fee })
        Notify(src, _U('entry_fee_charged', Utils.money(p.entry_fee)), 'info')
    end

    -- approved -> put them in the property's private instance, then teleport in
    EnterBucket(src, p)
    TriggerClientEvent('lr_properties:enterApproved', src, propertyId)
end)

-- ============================================================
--  DOORBELL / KNOCK
-- ============================================================
RegisterNetEvent('lr_properties:knock', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    local answered = false
    -- notify owner + key holders that are online
    local targets = { p.owner }
    for ident in pairs(p.keys) do targets[#targets + 1] = ident end
    for _, ident in ipairs(targets) do
        local tsrc = ident and Bridge.GetSrcByIdentifier(ident)
        if tsrc then
            Notify(tsrc, _U('someone_knocking'), 'info')
            TriggerClientEvent('lr_properties:knockReceived', tsrc, propertyId)
            answered = true
        end
    end
    if not answered then Notify(src, _U('no_one_home'), 'info') end
end)

-- ============================================================
--  COMMISSION
-- ============================================================
function PayCommission(p, amount)
    if not Config.Commission.enabled then return end
    -- the realtor who placed the property isn't tracked per-sale here;
    -- commission is paid to whoever placed it if you store a placer.
    -- We store the placer identifier inside the interior json under `_placer`.
    local placer = p.interior and p.interior._placer
    if not placer then return end
    local cut = math.floor(amount * (Config.Commission.percent / 100))
    if cut <= 0 then return end
    local rsrc = Bridge.GetSrcByIdentifier(placer)
    if rsrc then
        Bridge.AddCash(rsrc, cut)
        Notify(rsrc, _U('commission_earned', Utils.money(cut)), 'success')
    end
end
