-- ============================================================
--  SERVER BRIDGE
--  Detects ESX / QBCore / ox_core (or falls back to standalone).
--  Everything goes through GetIdentifier / GetCash / RemoveCash / AddCash.
--  Cash only, exactly as requested.
-- ============================================================
Bridge = { framework = 'standalone' }

local ESX, QB, OX

CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
        Bridge.framework = 'esx'
    elseif GetResourceState('qb-core') == 'started' then
        QB = exports['qb-core']:GetCoreObject()
        Bridge.framework = 'qb'
    elseif GetResourceState('ox_core') == 'started' then
        Bridge.framework = 'ox'
    end
    Utils.dbg('framework =', Bridge.framework)
end)

-- ----- identifier -----
function Bridge.GetIdentifier(src)
    if Bridge.framework == 'esx' then
        local xp = ESX.GetPlayerFromId(src); return xp and xp.identifier
    elseif Bridge.framework == 'qb' then
        local p = QB.Functions.GetPlayer(src); return p and p.PlayerData.citizenid
    elseif Bridge.framework == 'ox' then
        return exports.ox_core:GetPlayer(src) and exports.ox_core:GetPlayer(src).charId
    end
    -- standalone: license
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return ('src:%s'):format(src)
end

function Bridge.GetName(src)
    if Bridge.framework == 'esx' then
        local xp = ESX.GetPlayerFromId(src)
        if xp then return ('%s %s'):format(xp.get('firstName') or '', xp.get('lastName') or '') end
    elseif Bridge.framework == 'qb' then
        local p = QB.Functions.GetPlayer(src)
        if p then local c = p.PlayerData.charinfo; return ('%s %s'):format(c.firstname, c.lastname) end
    end
    return GetPlayerName(src) or 'Unknown'
end

-- src from identifier (online only)
function Bridge.GetSrcByIdentifier(ident)
    for _, src in ipairs(GetPlayers()) do
        src = tonumber(src)
        if Bridge.GetIdentifier(src) == ident then return src end
    end
    return nil
end

-- ----- cash -----
function Bridge.GetCash(src)
    if Bridge.framework == 'esx' then
        local xp = ESX.GetPlayerFromId(src); return xp and xp.getAccount('money') and xp.getAccount('money').money or 0
    elseif Bridge.framework == 'qb' then
        local p = QB.Functions.GetPlayer(src); return p and p.PlayerData.money.cash or 0
    elseif Bridge.framework == 'ox' then
        return exports.ox_inventory:GetItemCount(src, 'money') or 0
    end
    return 0  -- standalone has no economy; treat as free / override here
end

function Bridge.RemoveCash(src, amount)
    amount = math.floor(amount)
    if amount <= 0 then return true end
    if Bridge.GetCash(src) < amount then return false end
    if Bridge.framework == 'esx' then
        ESX.GetPlayerFromId(src).removeAccountMoney('money', amount); return true
    elseif Bridge.framework == 'qb' then
        return QB.Functions.GetPlayer(src).Functions.RemoveMoney('cash', amount, 'lr_properties')
    elseif Bridge.framework == 'ox' then
        return exports.ox_inventory:RemoveItem(src, 'money', amount)
    end
    return true
end

function Bridge.AddCash(src, amount)
    amount = math.floor(amount)
    if amount <= 0 then return true end
    if Bridge.framework == 'esx' then
        ESX.GetPlayerFromId(src).addAccountMoney('money', amount); return true
    elseif Bridge.framework == 'qb' then
        return QB.Functions.GetPlayer(src).Functions.AddMoney('cash', amount, 'lr_properties')
    elseif Bridge.framework == 'ox' then
        return exports.ox_inventory:AddItem(src, 'money', amount)
    end
    return true
end

-- offline payout helper (best effort): pays if online, otherwise drops it
function Bridge.PayIdentifier(ident, amount)
    local src = Bridge.GetSrcByIdentifier(ident)
    if src then return Bridge.AddCash(src, amount) end
    return false  -- offline; caller may store the debt/credit elsewhere
end
