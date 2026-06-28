-- ============================================================
--  SERVER - TAX / RENT / REPOSSESSION
--  Periodic charges. Unpaid -> warnings -> repossess (back to market).
--  Missed-cycle counters are kept in memory (reset on restart, which is
--  fine since due timestamps are persisted and re-evaluated).
-- ============================================================

local taxMisses  = {}   -- propertyId -> count
local rentMisses = {}   -- propertyId -> count

-- charge owner if online; if offline, treat as "missed" this cycle
local function chargeOwner(p, amount)
    if not p.owner then return false end
    local src = Bridge.GetSrcByIdentifier(p.owner)
    if not src then return false end                 -- offline -> miss
    if Bridge.GetCash(src) < amount then return false, src end
    return Bridge.RemoveCash(src, amount), src
end

-- ----- RENT -----
local function processRent(id, p)
    if p.tenure ~= 'rent' or not p.rent_due then return end
    if Utils.now() < p.rent_due then return end

    local ok, src = chargeOwner(p, p.rent_price)
    if ok then
        rentMisses[id] = 0
        DB_UpdateProperty(id, { rent_due = Utils.now() + Config.Ownership.rentInterval })
        if src then Notify(src, _U('rent_charged', Utils.money(p.rent_price), p.label), 'info') end
    else
        rentMisses[id] = (rentMisses[id] or 0) + 1
        if src then Notify(src, _U('rent_failed', p.label), 'error') end
        -- push due date so we don't spam every loop
        DB_UpdateProperty(id, { rent_due = Utils.now() + 3600 })
        if rentMisses[id] > Config.Ownership.rentGraceMisses then
            local osrc = Bridge.GetSrcByIdentifier(p.owner)
            if osrc then Notify(osrc, _U('evicted', p.label), 'error') end
            ReleaseProperty(id)
            rentMisses[id] = nil
        end
    end
end

-- ----- TAX -----
local function processTax(id, p)
    if not Config.Tax.enabled or not p.owner or not p.tax_due then return end
    if Utils.now() < p.tax_due then return end

    local rate = p.type == 'business' and Config.Tax.businessRate or Config.Tax.houseRate
    local amount = math.max(Config.Tax.minTax, math.floor(p.price * rate))

    local ok, src = chargeOwner(p, amount)
    if ok then
        taxMisses[id] = 0
        DB_UpdateProperty(id, { tax_due = Utils.now() + Config.Tax.interval })
        if src then Notify(src, _U('tax_charged', Utils.money(amount), p.label), 'info') end
    else
        taxMisses[id] = (taxMisses[id] or 0) + 1
        if src then Notify(src, _U('tax_warning', p.label), 'error') end
        DB_UpdateProperty(id, { tax_due = Utils.now() + 3600 })
        if taxMisses[id] > Config.Tax.graceMisses then
            local osrc = Bridge.GetSrcByIdentifier(p.owner)
            if osrc then Notify(osrc, _U('repossessed', p.label), 'error') end
            ReleaseProperty(id)
            taxMisses[id] = nil
        end
    end
end

-- main loop - checks every 5 minutes
CreateThread(function()
    while true do
        Wait(5 * 60 * 1000)
        for id, p in pairs(Properties) do
            if p.owner then
                processRent(id, p)
                processTax(id, p)
            end
        end
    end
end)
