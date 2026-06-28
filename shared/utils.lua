-- ============================================================
--  SHARED UTILS
-- ============================================================
Utils = {}

function Utils.round(n, d)
    d = d or 0
    local m = 10 ^ d
    return math.floor(n * m + 0.5) / m
end

-- format money with thousands separators
function Utils.money(n)
    n = math.floor(tonumber(n) or 0)
    local s = tostring(n)
    local out = s:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    return (out:gsub('^,', ''))
end

function Utils.dist(a, b)
    return #(vector3(a.x, a.y, a.z) - vector3(b.x, b.y, b.z))
end

-- safe json encode/decode wrappers
function Utils.enc(t) return json.encode(t) end
function Utils.dec(s)
    if type(s) == 'table' then return s end
    local ok, r = pcall(json.decode, s)
    return ok and r or nil
end

function Utils.now()
    return os.time()
end

-- debug print
function Utils.dbg(...)
    if Config.Debug then
        print(('^3[lr_properties]^7 %s'):format(table.concat({ ... }, ' ')))
    end
end

-- grade helper
function Utils.gradeRight(grade, right)
    local g = Config.Business.grades[grade] or Config.Business.grades[0]
    return g and g[right] == true
end
