-- ============================================================
--  SERVER - BUSINESS LOGIC
--  Hire/fire + grades, entry-fee setting, cash safe, payroll.
-- ============================================================

-- ----- HIRE -----
RegisterNetEvent('lr_properties:hire', function(propertyId, targetSrc, grade, salary)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canManageStaff') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    targetSrc = tonumber(targetSrc)
    if not targetSrc or not GetPlayerName(targetSrc) then return end

    local count = 0
    for _ in pairs(p.employees) do count = count + 1 end
    if count >= Config.Business.maxEmployees then
        Notify(src, _U('no_permission'), 'error'); return
    end

    grade  = math.max(0, math.min(tonumber(grade) or 0, #Config.Business.grades))
    salary = math.max(0, math.floor(tonumber(salary) or 0))
    local ident = Bridge.GetIdentifier(targetSrc)
    local name  = Bridge.GetName(targetSrc)

    DB_AddEmployee(propertyId, ident, name, grade, salary)
    Notify(src, _U('employee_hired', name), 'success')
    Notify(targetSrc, _U('hired_you', p.label), 'success')
end)

-- ----- FIRE -----
RegisterNetEvent('lr_properties:fire', function(propertyId, ident)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canManageStaff') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    local emp = p.employees[ident]; if not emp then return end
    DB_RemoveEmployee(propertyId, ident)
    Notify(src, _U('employee_fired', emp.name or ident), 'success')
    local tsrc = Bridge.GetSrcByIdentifier(ident)
    if tsrc then Notify(tsrc, _U('fired_you', p.label), 'error') end
end)

-- return the employee list to the manager UI
RegisterNetEvent('lr_properties:requestEmployees', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canManageStaff') and not IsOwner(src, p) then return end
    local list = {}
    for ident, e in pairs(p.employees) do
        list[#list + 1] = { identifier = ident, name = e.name, grade = e.grade, salary = e.salary }
    end
    TriggerClientEvent('lr_properties:employeeList', src, propertyId, list)
end)

-- ----- ENTRY FEE -----
RegisterNetEvent('lr_properties:setEntryFee', function(propertyId, fee)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if p.type ~= 'business' then return end
    if not CanManage(src, p, 'canManageStaff') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    fee = math.max(0, math.min(tonumber(fee) or 0, Config.Business.entryFeeMax))
    DB_UpdateProperty(propertyId, { entry_fee = fee })
    SyncProperty(propertyId)
    Notify(src, _U('entry_fee_set', Utils.money(fee)), 'success')
end)

-- ============================================================
--  CASH SAFE  (separate from ox_inventory item stash)
-- ============================================================
RegisterNetEvent('lr_properties:safeDeposit', function(propertyId, amount)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canManageStash') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if Bridge.GetCash(src) < amount then
        Notify(src, _U('not_enough_cash', Utils.money(amount)), 'error'); return
    end
    Bridge.RemoveCash(src, amount)
    DB_UpdateProperty(propertyId, { safe_balance = p.safe_balance + amount })
    Notify(src, _U('safe_deposit', Utils.money(amount)), 'success')
    TriggerClientEvent('lr_properties:safeBalance', src, propertyId, p.safe_balance)
end)

RegisterNetEvent('lr_properties:safeWithdraw', function(propertyId, amount)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    -- only owner / partners can withdraw
    if not CanManage(src, p, 'canManageStaff') and not IsOwner(src, p) then
        Notify(src, _U('no_permission'), 'error'); return
    end
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 then return end
    if p.safe_balance < amount then
        Notify(src, _U('safe_empty'), 'error'); return
    end
    DB_UpdateProperty(propertyId, { safe_balance = p.safe_balance - amount })
    Bridge.AddCash(src, amount)
    Notify(src, _U('safe_withdraw', Utils.money(amount)), 'success')
    TriggerClientEvent('lr_properties:safeBalance', src, propertyId, p.safe_balance)
end)

RegisterNetEvent('lr_properties:requestSafe', function(propertyId)
    local src = source
    local p = Properties[propertyId]; if not p then return end
    if not CanManage(src, p, 'canManageStash') and not IsOwner(src, p) then return end
    TriggerClientEvent('lr_properties:safeBalance', src, propertyId, p.safe_balance)
end)

-- ============================================================
--  PAYROLL  (automatic, paid from the cash safe)
-- ============================================================
function RunPayroll(propertyId)
    local p = Properties[propertyId]; if not p or p.type ~= 'business' then return end
    local total = 0
    for _, e in pairs(p.employees) do total = total + (e.salary or 0) end
    if total <= 0 then return end

    if p.safe_balance < total then
        -- can't cover payroll - warn the owner if online
        local osrc = p.owner and Bridge.GetSrcByIdentifier(p.owner)
        if osrc then Notify(osrc, _U('payroll_fail'), 'error') end
        return
    end

    DB_UpdateProperty(propertyId, { safe_balance = p.safe_balance - total })
    for ident, e in pairs(p.employees) do
        if (e.salary or 0) > 0 then
            local tsrc = Bridge.GetSrcByIdentifier(ident)
            if tsrc then
                Bridge.AddCash(tsrc, e.salary)
                Notify(tsrc, _U('payroll_paid', Utils.money(e.salary)), 'success')
            end
        end
    end
end

-- payroll loop
CreateThread(function()
    while true do
        Wait(Config.Business.payrollInterval * 1000)
        for id, p in pairs(Properties) do
            if p.type == 'business' and p.owner then RunPayroll(id) end
        end
    end
end)
