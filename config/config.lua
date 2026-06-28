Config = {}

-- ============================================================
--  GENERAL
-- ============================================================
Config.Locale          = 'tr'          -- 'tr' | 'en' (see locales/)
Config.Debug           = false
Config.MaxObjects      = 300           -- placed objects per property (performance cap)
Config.RenderDistance  = 80.0          -- distance objects/markers stream in (meters)
Config.Currency        = 'cash'        -- money type. Only cash is used in this system.
Config.CommandRealtor  = 'realtor'     -- /realtor open the realtor placement menu (must be granted)
Config.AdminAce        = 'lr.admin'    -- ace permission for admin commands (txAdmin/principals)

-- ============================================================
--  INSTANCING (routing buckets)
--  Each property interior runs in its OWN routing bucket, so players
--  inside different properties never see each other even if their
--  shells share the same world coordinates. This is real instancing.
-- ============================================================
Config.Bucket = {
    enabled  = true,
    base     = 5000,        -- bucket id = base + property.id  (keep clear of other resources)
    lockdown = 'strict',    -- routing bucket entity lockdown mode
    populationEnabled = false, -- no ambient population inside instances
}

-- A single shared staging coordinate for all SHELL interiors.
-- Because every property is in its own bucket, they can all stack here.
-- Pick a quiet, empty spot; adjust if it clips your map.
Config.ShellBase = vector3(-1700.0, -1150.0, 100.0)

-- If a shell's model isn't streamed on the client (e.g. you didn't add the
-- shell asset files), the script falls back to this base-game model so the
-- interior still loads instead of breaking. (Import/Export DLC, always present.)
Config.ShellFallbackModel = 'imp_prop_impexp_intintnceil'

-- ============================================================
--  PROP THUMBNAILS  (decoration catalog images)
--  Tries, in order: local image pack -> optional CDN -> SVG icon.
--  qb-interior/Forge images are keyed by internal id (not model name),
--  so they can't be auto-built. Two reliable options:
--    1) Drop PNGs named "<model>.png" into html/img/catalog/  (image pack)
--    2) Point `cdn` at any source whose URL is built from the model/hash.
--  Placeholders in `cdn`: {model} {hash} (unsigned joaat) .
-- ============================================================
Config.Thumbnails = {
    enabled = true,          -- false = always use the built-in SVG icons
    localPack = true,        -- look for html/img/catalog/<model>.(png|jpg|webp)
    cdn = '',                -- e.g. 'https://my.cdn/props/{model}.png'  (empty = off)
}

-- ============================================================
--  ACCESS POINTS  (placeable storage / wardrobe / safe markers)
--  You place these inside your property; walking up + [E] opens them.
-- ============================================================
Config.AccessPoint = {
    ghostModel = 'prop_cs_cardbox_01',  -- ghost shown while placing
    openKey    = 38,                    -- E
    drawDist   = 6.0,
    interactDist = 1.6,
    -- target zone dimensions (used when Interaction.mode = 'target')
    targetZoneSize = vector3(1.2, 1.2, 2.0),
    targetZoneDistExtra = 0.4,          -- added on top of interactDist for target range
    markers = {
        storage  = { label = 'Depo',   color = { r = 255, g = 159, b = 10  } },
        wardrobe = { label = 'Dolap',  color = { r = 90,  g = 200, b = 250 } },
        safe     = { label = 'Kasa',   color = { r = 120, g = 220, b = 140 } },
    },
}

-- ============================================================
--  DECORATION EDITOR  (freecam + mouse, beginner-friendly)
-- ============================================================
Config.Editor = {
    camSpeed      = 0.35,    -- base freecam move speed per frame
    camSpeedFast  = 1.1,     -- while holding SHIFT
    camSpeedSlow  = 0.12,    -- while holding ALT (precision)
    lookSens      = 6.0,     -- mouse look sensitivity
    rotateStep    = 2.0,     -- scroll-wheel rotate degrees
    rotateStepFast= 15.0,    -- SHIFT + scroll
    surfaceSnap   = true,    -- objects sit on whatever you point at (easy default)
    gridSize      = 0.1,     -- grid snap cell size
    placeDistance = 6.0,     -- fallback ghost distance when not hitting a surface
    keys = {
        cursor   = 37,   -- TAB   : show/hide the cursor (use the panel vs build)
        forward  = 32,   -- W
        back     = 33,   -- S
        left     = 34,   -- A
        right    = 35,   -- D
        up       = 22,   -- SPACE
        down     = 36,   -- LCTRL
        fast     = 21,   -- LSHIFT
        slow     = 19,   -- LALT
        place    = 24,   -- LMB   : place / confirm
        grab     = 47,   -- G... (we use NUI buttons too)  -> actually unused, NUI driven
        look     = 25,   -- RMB   : hold is not required; look is always on while cursor hidden
        rotLeft  = 14,   -- scroll down
        rotRight = 15,   -- scroll up
        cancel   = 177,  -- BACKSPACE / cancel current ghost
        remove   = 178,  -- DELETE : delete the object under the crosshair
    },
}

-- ============================================================
--  INTERACTION  (how the door / property menu opens)
--  Pick the mode that matches what you run. All three are implemented.
-- ============================================================
Config.Interaction = {
    mode        = 'target',            -- 'marker' | 'target' | 'command'
    -- marker mode:
    markerType  = 36,
    markerSize  = vector3(0.3, 0.3, 0.3),
    markerColor = { r = 120, g = 170, b = 255, a = 180 },
    drawDist    = 8.0,                 -- start drawing marker
    interactDist= 1.6,                 -- distance to press the key
    interactKey = 38,                  -- E
    -- command mode:
    command     = 'property',          -- /property interacts with nearest door
    -- target mode (auto-detects ox_target / qb-target):
    targetLabel = 'Mülk',
    targetIcon  = 'fas fa-house',
    -- in-property menu: opens the management menu while you're INSIDE
    -- (also opens the nearest door menu when you're outside).
    -- works in every mode. Players can rebind the key in Settings > Key Bindings.
    menuCommand = 'propmenu',
    menuKey     = 'F6',
}

-- ============================================================
--  OWNERSHIP / ECONOMY
-- ============================================================
Config.Ownership = {
    allowBuy        = true,
    allowRent       = true,
    rentInterval    = 7 * 24 * 60 * 60,   -- seconds between rent charges (7 days)
    rentGraceMisses = 1,                  -- missed rent cycles before eviction (after this -> repossess)
}

Config.Commission = {
    enabled     = true,                   -- realtor earns a cut of each sale
    percent     = 5.0,                    -- % of sale price
    fromBuyer   = false,                  -- false = paid by the system on top, true = added to buyer's price
}

-- ============================================================
--  TAX / MAINTENANCE
--  Unpaid -> property is repossessed (returned to "for sale").
-- ============================================================
Config.Tax = {
    enabled     = true,
    interval    = 7 * 24 * 60 * 60,       -- seconds between tax charges
    houseRate   = 0.01,                   -- tax = price * rate, per interval
    businessRate= 0.02,
    minTax      = 100,
    graceMisses = 2,                      -- missed cycles before repossession
}

-- ============================================================
--  BUSINESS
-- ============================================================
Config.Business = {
    entryFeeMax     = 5000,               -- cap for owner-set entry fee
    payrollInterval = 7 * 24 * 60 * 60,   -- seconds between automatic payroll runs
    maxEmployees    = 15,
    grades = {                            -- permission grades, edit freely
        [0] = { label = 'Çalışan',  canManageStash = true,  canLock = false, canDecorate = false, canManageStaff = false },
        [1] = { label = 'Müdür',    canManageStash = true,  canLock = true,  canDecorate = true,  canManageStaff = false },
        [2] = { label = 'Ortak',    canManageStash = true,  canLock = true,  canDecorate = true,  canManageStaff = true  },
    },
}

-- ============================================================
--  KEYS / ACCESS
-- ============================================================
Config.Keys = {
    maxHolders  = 20,
    doorbell    = true,                   -- visitors can ring the bell / knock
    knockKey    = 38,                     -- E to knock when locked & outside
}

-- ============================================================
--  STORAGE (ox_inventory)
-- ============================================================
Config.Storage = {
    -- house stash
    house = { slots = 50,  weight = 100000 },   -- weight in grams
    -- business safe stash
    business = { slots = 80, weight = 200000 },
    -- money safe is separate (cash box) and handled by the business safe_balance column
}

-- ============================================================
--  WARDROBE
--  You said you'll write the outfit event yourself.
--  This system only triggers the events below. Wire them up on your side.
-- ============================================================
Config.Wardrobe = {
    openEvent    = 'lr_properties:client:openWardrobe',  -- triggered when player uses the wardrobe
    -- payload sent: { propertyId = id, owner = bool }
}

-- ============================================================
--  GIZMO / PLACEMENT
-- ============================================================
Config.Gizmo = {
    moveStep     = 0.01,      -- meters per tick (fine)
    moveStepFast = 0.10,      -- with SHIFT held
    rotStep      = 1.0,       -- degrees per tick
    rotStepFast  = 15.0,
    gridSize     = 0.25,      -- snap-to-grid cell size
    raycastDist  = 10.0,      -- surface snap raycast length
    keys = {
        confirm   = 191,   -- ENTER
        cancel    = 194,   -- BACKSPACE
        toggleMode= 19,    -- LEFT ALT  (translate <-> rotate)
        snapGrid  = 47,    -- G         (toggle grid snap)
        snapSurf  = 29,    -- B         (toggle surface snap)
        undo      = 20,    -- Z
        redo      = 21,    -- (held with) -> we use SHIFT+Z, key 21 is SHIFT
        copy      = 55,    -- SPACE     (duplicate current object)
        fast      = 21,    -- LEFT SHIFT (fast modifier)
        -- axis keys (translate): arrows + pgup/pgdn
        xPlus = 174, xMinus = 175,   -- LEFT / RIGHT arrows -> X
        yPlus = 172, yMinus = 173,   -- UP / DOWN arrows    -> Y
        zPlus = 10,  zMinus = 11,    -- PAGEUP / PAGEDOWN    -> Z
    },
}

-- ============================================================
--  NOTIFICATIONS  (custom NUI - zero dependency)
-- ============================================================
Config.Notify = {
    duration = 4500,         -- ms
    position = 'top-right',  -- top-right | top-left | bottom-right | bottom-left | top-center
}
