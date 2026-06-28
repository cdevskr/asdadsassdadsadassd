-- ============================================================
--  LOCALE LOADER
--  Locale tables registered by locales/<lang>.lua via Locales[...]
--  _U(key, ...) returns the formatted string for Config.Locale.
-- ============================================================

Locales = Locales or {}

function _U(key, ...)
    local lang = Locales[Config.Locale] or Locales['en'] or {}
    local str  = lang[key]
    if not str then
        -- fall back to english, then to the raw key
        str = (Locales['en'] and Locales['en'][key]) or key
    end
    if select('#', ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        if ok then return res end
    end
    return str
end

-- expose to NUI side (client builds a translations payload from this)
function GetLocaleTable()
    return Locales[Config.Locale] or Locales['en'] or {}
end
