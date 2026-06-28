-- ============================================================
--  CLIENT MENU
--  Door menu + owner/business management + keys + cash safe +
--  the realtor placement flow. All via the custom NUI.
-- ============================================================

-- small wrappers around the NUI views
local function buttonMenu(title, buttons, cb)
    NuiRequest({ view = 'menu', title = title, buttons = buttons }, function(v)
        CloseMenu()
        cb(v and v.id)
    end)
end

local function inputForm(title, fields, cb)
    NuiRequest({ view = 'input', title = title, fields = fields }, function(v)
        CloseMenu()
        cb(v)
    end)
end

local function selectList(title, items, cb)
    NuiRequest({ view = 'list', title = title, items = items }, function(v)
        CloseMenu()
        cb(v)
    end)
end

-- ------------------------------------------------------------
--  one-shot server-reply plumbing.
--  Each list event is registered ONCE here; the Open* helpers
--  just set a pending callback and fire the server request.
--  Prevents handler stacking from re-opening menus.
-- ------------------------------------------------------------
local pending = { nearby = nil, keys = nil, employees = nil, safe = nil }

RegisterNetEvent('lr_properties:nearbyList', function(list)
    local cb = pending.nearby; pending.nearby = nil
    if cb then cb(list) end
end)
RegisterNetEvent('lr_properties:keyList', function(_, list)
    local cb = pending.keys; pending.keys = nil
    if cb then cb(list) end
end)
RegisterNetEvent('lr_properties:employeeList', function(_, list)
    local cb = pending.employees; pending.employees = nil
    if cb then cb(list) end
end)
RegisterNetEvent('lr_properties:safeBalance', function(propertyId, balance)
    if State.doors[propertyId] then State.doors[propertyId].safe_balance = balance end
    local cb = pending.safe; pending.safe = nil
    if cb then cb(balance) end
end)

-- collect nearby players for pickers
local function withNearby(cb)
    pending.nearby = cb
    TriggerServerEvent('lr_properties:requestNearby', GetEntityCoords(PlayerPedId()))
end

-- ============================================================
--  DOOR MENU  (what shows when you interact with a door)
-- ============================================================
function OpenPropertyMenu(propertyId)
    local p = State.doors[propertyId]; if not p then return end

    QueryAccess(propertyId, function(acc)
        local buttons = {}

        -- not owned & for sale -> buy / rent
        if p.for_sale and not p.owner then
            if Config.Ownership.allowBuy then
                buttons[#buttons+1] = { id = 'buy',  label = _U('btn_buy')  .. ' ($' .. Utils.money(p.price) .. ')', icon = 'fa-money-bill' }
            end
            if Config.Ownership.allowRent and p.rent_price > 0 then
                buttons[#buttons+1] = { id = 'rent', label = _U('btn_rent') .. ' ($' .. Utils.money(p.rent_price) .. ')', icon = 'fa-calendar' }
            end
        end

        -- owner / key holder / employee -> enter
        if acc.owner or acc.key or acc.employee or (not p.locked) then
            buttons[#buttons+1] = { id = 'enter', label = _U('btn_enter'), icon = 'fa-door-open' }
        end

        -- lock toggle
        if acc.owner or acc.lock or acc.key then
            buttons[#buttons+1] = { id = 'lock', label = _U('btn_lock') .. (p.locked and ' (kilitli)' or ' (açık)'), icon = 'fa-lock' }
        end

        -- NOTE: management (decorate / storage / staff / safe / sell ...) is
        -- intentionally NOT on the door. It lives inside the property and is
        -- opened with the menu key (F6) / "menuCommand" once you're in.
        -- We only show a hint here so owners know where it went.
        local canManage = acc.owner or acc.staff or acc.decorate or acc.manage

        -- realtor delete (admin/realtor)
        if acc.realtor then
            buttons[#buttons+1] = { id = 'rdelete', label = 'Mülkü sil (emlakçı)', icon = 'fa-trash' }
        end

        if #buttons == 0 then
            ShowNotify(_U('property_locked'), 'error'); return
        end

        buttonMenu(p.label, buttons, function(id)
            if id == 'buy'    then TriggerServerEvent('lr_properties:buy', propertyId)
            elseif id == 'rent' then TriggerServerEvent('lr_properties:rent', propertyId)
            elseif id == 'enter' then
                EnterProperty(propertyId)
                if canManage then ShowNotify(_U('manage_hint', Config.Interaction.menuKey), 'info') end
            elseif id == 'lock'  then TriggerServerEvent('lr_properties:toggleLock', propertyId)
            elseif id == 'rdelete' then TriggerServerEvent('lr_properties:deleteProperty', propertyId)
            end
        end)
    end)
end

-- ============================================================
--  MANAGEMENT MENU  (owner / business)
-- ============================================================
function OpenManageMenu(propertyId, acc)
    local p = State.doors[propertyId]; if not p then return end
    acc = acc or State.access[propertyId] or {}

    local sections = {}
    local function sec(title, items) if #items > 0 then sections[#sections+1] = { title = title, items = items } end end

    -- QUICK ACCESS: placeable access points
    local qa = {}
    if acc.owner or acc.decorate then
        qa[#qa+1] = { id = 'place_storage',  label = _U('place_storage'),  desc = 'Depoyu dünyaya yerleştir',  kind = 'default', icon = 'box' }
        qa[#qa+1] = { id = 'place_wardrobe', label = _U('place_wardrobe'), desc = 'Dolabı dünyaya yerleştir',  kind = 'default', icon = 'shirt' }
    end
    if p.type == 'business' and (acc.owner or acc.manage) then
        qa[#qa+1] = { id = 'place_safe', label = _U('place_safe'), desc = 'Kasayı dünyaya yerleştir', kind = 'default', icon = 'safe' }
    end
    sec('HIZLI ERİŞİM', qa)

    -- PROPERTY MANAGEMENT
    local pm = {}
    if acc.owner or acc.decorate then
        pm[#pm+1] = { id = 'decorate', label = _U('btn_decorate'), desc = 'Eşyaları yerleştir / düzenle', kind = 'primary', icon = 'paint' }
        pm[#pm+1] = { id = 'setexit',  label = _U('btn_set_exit'), desc = 'Çıkış noktasını ayarla', kind = 'default', icon = 'door' }
    end
    if p.type == 'business' and (acc.owner or acc.staff) then
        pm[#pm+1] = { id = 'fee', label = _U('btn_set_fee'), desc = 'Giriş ücreti: $' .. Utils.money(p.entry_fee), kind = 'default', icon = 'ticket' }
    end
    if acc.owner then
        pm[#pm+1] = { id = 'sell', label = _U('btn_sell'), desc = 'Mülkü sat', kind = 'danger', icon = 'tag' }
    end
    sec('MÜLK YÖNETİMİ', pm)

    -- PEOPLE
    local pe = {}
    if acc.owner or acc.staff then
        pe[#pe+1] = { id = 'keys', label = _U('btn_keys'), desc = 'Anahtar sahipleri', kind = 'default', icon = 'key' }
    end
    if p.type == 'business' and (acc.owner or acc.staff) then
        pe[#pe+1] = { id = 'employees', label = _U('btn_employees'), desc = 'Çalışanlar & rütbeler', kind = 'default', icon = 'users' }
    end
    sec('KİŞİLER', pe)

    -- SECURITY
    local se = {}
    if acc.owner or acc.lock or acc.key then
        se[#se+1] = { id = 'lock',
            label = p.locked and 'Kapıyı Aç' or 'Kapıyı Kilitle',
            desc  = p.locked and 'Şu an kilitli' or 'Şu an açık',
            kind  = p.locked and 'danger' or 'success', icon = p.locked and 'lock' or 'unlock' }
    end
    sec('GÜVENLİK', se)

    if #sections == 0 then ShowNotify(_U('no_permission'), 'error'); return end

    -- lights (built from local state of placed light objects)
    local lights = {}
    if State.objectMeta then
        for objId, meta in pairs(State.objectMeta) do
            lights[#lights+1] = { objId = objId, label = (meta.cat and meta.cat.name) or 'Işık', on = meta.on and true or false }
        end
    end

    NuiRequest({
        view     = 'dashboard',
        title    = p.label,
        subtitle = p.type == 'business' and 'İŞLETME YÖNETİMİ' or 'EV YÖNETİMİ',
        locked   = p.locked,
        sections = sections,
        lights   = lights,
    }, function(sel)
        CloseMenu()
        local id = sel and sel.id
        if not id then return end
        if id == 'lock' then TriggerServerEvent('lr_properties:toggleLock', propertyId)
        elseif id == 'place_storage' then
            if State.inside == propertyId then PlaceAccessPoint(propertyId, 'storage') else ShowNotify(_U('enter_first'), 'error') end
        elseif id == 'place_wardrobe' then
            if State.inside == propertyId then PlaceAccessPoint(propertyId, 'wardrobe') else ShowNotify(_U('enter_first'), 'error') end
        elseif id == 'place_safe' then
            if State.inside == propertyId then PlaceAccessPoint(propertyId, 'safe') else ShowNotify(_U('enter_first'), 'error') end
        elseif id == 'decorate' then
            if State.inside == propertyId then StartDecorate(propertyId) else ShowNotify(_U('enter_first'), 'error') end
        elseif id == 'setexit' then
            if State.inside == propertyId then PlaceExitPoint(propertyId) else ShowNotify(_U('enter_first'), 'error') end
        elseif id == 'keys' then OpenKeysMenu(propertyId)
        elseif id == 'employees' then OpenEmployeesMenu(propertyId)
        elseif id == 'fee' then OpenFeeMenu(propertyId)
        elseif id == 'sell' then TriggerServerEvent('lr_properties:sell', propertyId)
        end
    end)
end

-- ============================================================
--  KEYS
-- ============================================================
function OpenKeysMenu(propertyId)
    pending.keys = function(list)
        local items = {}
        for _, k in ipairs(list) do
            items[#items+1] = { id = k.identifier, label = k.name, sub = 'Anahtar var', action = 'remove', actionLabel = 'Al' }
        end
        items[#items+1] = { id = '__give', label = '+ Yeni anahtar ver', action = 'add' }
        selectList(_U('btn_keys'), items, function(v)
            if not v then return end
            if v.action == 'remove' then
                TriggerServerEvent('lr_properties:removeKey', propertyId, v.id)
            elseif v.action == 'add' then
                withNearby(function(near)
                    local opts = {}
                    for _, n in ipairs(near) do opts[#opts+1] = { id = tostring(n.src), label = n.name } end
                    if #opts == 0 then ShowNotify('Yakında kimse yok.', 'error'); return end
                    selectList('Anahtar ver', opts, function(sel)
                        if sel then TriggerServerEvent('lr_properties:giveKey', propertyId, tonumber(sel.id)) end
                    end)
                end)
            end
        end)
    end
    TriggerServerEvent('lr_properties:requestKeys', propertyId)
end

-- ============================================================
--  EMPLOYEES
-- ============================================================
function OpenEmployeesMenu(propertyId)
    pending.employees = function(list)
        local items = {}
        for _, e in ipairs(list) do
            local gradeLabel = (Config.Business.grades[e.grade] and Config.Business.grades[e.grade].label) or ('Grade ' .. e.grade)
            items[#items+1] = { id = e.identifier, label = e.name, sub = gradeLabel .. ' • $' .. Utils.money(e.salary), action = 'fire', actionLabel = 'Çıkar' }
        end
        items[#items+1] = { id = '__hire', label = '+ Çalışan al', action = 'hire' }
        selectList(_U('btn_employees'), items, function(v)
            if not v then return end
            if v.action == 'fire' then
                TriggerServerEvent('lr_properties:fire', propertyId, v.id)
            elseif v.action == 'hire' then
                withNearby(function(near)
                    local opts = {}
                    for _, n in ipairs(near) do opts[#opts+1] = { id = tostring(n.src), label = n.name } end
                    if #opts == 0 then ShowNotify('Yakında kimse yok.', 'error'); return end
                    selectList('Kimi alalım?', opts, function(sel)
                        if not sel then return end
                        inputForm('İşe al', {
                            { id = 'grade',  label = 'Yetki (0-' .. #Config.Business.grades .. ')', type = 'number', default = '0' },
                            { id = 'salary', label = 'Maaş ($)', type = 'number', default = '0' },
                        }, function(form)
                            if form then
                                TriggerServerEvent('lr_properties:hire', propertyId, tonumber(sel.id),
                                    tonumber(form.grade) or 0, tonumber(form.salary) or 0)
                            end
                        end)
                    end)
                end)
            end
        end)
    end
    TriggerServerEvent('lr_properties:requestEmployees', propertyId)
end

-- ============================================================
--  ENTRY FEE
-- ============================================================
function OpenFeeMenu(propertyId)
    local p = State.doors[propertyId]
    inputForm(_U('btn_set_fee'), {
        { id = 'fee', label = 'Giriş ücreti ($, max ' .. Config.Business.entryFeeMax .. ')', type = 'number', default = tostring(p and p.entry_fee or 0) },
    }, function(form)
        if form then TriggerServerEvent('lr_properties:setEntryFee', propertyId, tonumber(form.fee) or 0) end
    end)
end

-- ============================================================
--  CASH SAFE
-- ============================================================
function OpenSafeMenu(propertyId)
    pending.safe = function(balance)
        buttonMenu(_U('btn_money_safe') .. ' — $' .. Utils.money(balance), {
            { id = 'dep', label = 'Para yatır', icon = 'fa-arrow-down' },
            { id = 'wd',  label = 'Para çek',  icon = 'fa-arrow-up' },
        }, function(id)
            if id == 'dep' then
                inputForm('Para yatır', { { id = 'amt', label = 'Miktar ($)', type = 'number' } }, function(f)
                    if f then TriggerServerEvent('lr_properties:safeDeposit', propertyId, tonumber(f.amt) or 0) end
                end)
            elseif id == 'wd' then
                inputForm('Para çek', { { id = 'amt', label = 'Miktar ($)', type = 'number' } }, function(f)
                    if f then TriggerServerEvent('lr_properties:safeWithdraw', propertyId, tonumber(f.amt) or 0) end
                end)
            end
        end)
    end
    TriggerServerEvent('lr_properties:requestSafe', propertyId)
end

-- (door-cache update for safe balance is handled in the single
--  lr_properties:safeBalance handler near the top of this file)

-- ============================================================
--  STASH (ox_inventory) - client receives the go-ahead
-- ============================================================
RegisterNetEvent('lr_properties:forceOpenStash', function(stashId)
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:openInventory('stash', stashId)
    end
end)

-- ============================================================
--  REALTOR FLOW  (place a new property)
-- ============================================================
RegisterNetEvent('lr_properties:openRealtorMenu', function()
    if not State.config then TriggerServerEvent('lr_properties:requestConfig'); Wait(300) end
    -- step 1: type
    buttonMenu('Emlakçı — Yeni Mülk', {
        { id = 'house',    label = 'Ev', icon = 'fa-house' },
        { id = 'business', label = 'İşletme', icon = 'fa-store' },
    }, function(ptype)
        if not ptype then return end
        -- step 2: interior picker (NUI grid)
        NuiRequest({
            view = 'interiors',
            title = 'Interior seç',
            categories = State.config and State.config.interiorCategories or Config.InteriorCategories,
            items = State.config and State.config.interiors or Config.InteriorCatalog,
            thumbs = Config.Thumbnails,
        }, function(pick)
            CloseMenu()
            if not pick or not pick.id then return end
            -- step 3: details
            inputForm('Mülk detayları', {
                { id = 'label', label = 'İsim', type = 'text', default = ptype == 'business' and 'Yeni İşletme' or 'Yeni Ev' },
                { id = 'price', label = 'Satış fiyatı ($)', type = 'number', default = '100000' },
                { id = 'rent',  label = 'Kira ($, dönemlik)', type = 'number', default = '5000' },
                { id = 'fee',   label = ptype == 'business' and 'Varsayılan giriş ücreti ($)' or '(ev için 0)', type = 'number', default = '0' },
            }, function(form)
                if not form then return end
                -- step 4: place the door with the gizmo-like marker at player position/aim
                PlaceDoorMarker(function(door)
                    if not door then return end
                    TriggerServerEvent('lr_properties:createProperty', {
                        label = form.label, type = ptype,
                        price = tonumber(form.price) or 0,
                        rent_price = tonumber(form.rent) or 0,
                        entry_fee = tonumber(form.fee) or 0,
                        door = door,
                        interior = { id = pick.id },
                    })
                end)
            end)
        end)
    end)
end)

-- place the door anchor: a movable marker the realtor confirms with ENTER
function PlaceDoorMarker(cb)
    ShowNotify(_U('placing_property'), 'info')
    CreateThread(function()
        local placing = true
        while placing do
            Wait(0)
            local ped = PlayerPedId()
            local pc  = GetEntityCoords(ped)
            local fwd = GetEntityForwardVector(ped)
            local pos = pc + fwd * 1.0
            DrawMarker(36, pos.x, pos.y, pos.z, 0,0,0, 0,0,0, 0.4,0.4,0.4, 90,200,120,200, false,false,2,nil,nil,false)
            -- HUD
            SetTextFont(4); SetTextScale(0.4,0.4); SetTextColour(255,255,255,220); SetTextOutline()
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName('Kapı yerini ayarla • ~g~ENTER~s~ onayla • ~r~BACKSPACE~s~ iptal')
            EndTextCommandDisplayText(0.5, 0.85)
            if IsControlJustReleased(0, Config.Gizmo.keys.confirm) then
                placing = false
                cb({ x = pos.x, y = pos.y, z = pos.z, h = GetEntityHeading(ped) })
            elseif IsControlJustReleased(0, Config.Gizmo.keys.cancel) then
                placing = false
                ShowNotify(_U('cancelled'), 'info')
                cb(nil)
            end
        end
    end)
end
