-- ============================================================
--  INTERIORS
--  Three kinds, exactly as you described:
--    ipl    -> prebuilt GTA interiors (Eclipse / office / garage...)
--    shell  -> portable object shell, spawned anywhere, infinitely cloneable
--    custom -> empty point in the world; buyer builds everything with the gizmo
--
--  The realtor menu reads Config.InteriorCatalog to show the picture grid.
--  `thumb` is an image inside html/img/ (drop your own pictures there,
--   filename must match). Missing images fall back to a placeholder.
-- ============================================================

Config.InteriorCatalog = {

    -- ---------- IPL apartments / interiors ----------
    {
        id    = 'eclipse_1',
        kind  = 'ipl',
        label = 'Eclipse Towers - Tip 1',
        cat   = 'apartment',
        thumb = 'eclipse_1.png',
        ipl   = { 'apa_v_mp_h_01_a' },        -- ipl(s) to request
        -- spawn point INSIDE the interior (where the player is teleported)
        spawn = vector4(-773.07, 341.49, 213.39, 175.0),
        -- exit door anchor inside (used for the leave prompt)
        exit  = vector3(-773.5, 332.4, 213.0),
    },
    {
        id    = 'office_1',
        kind  = 'ipl',
        label = 'Yönetici Ofisi',
        cat   = 'office',
        thumb = 'office_1.png',
        ipl   = { 'ex_dt1_02_office_01a' },
        spawn = vector4(-141.23, -620.74, 168.82, 95.0),
        exit  = vector3(-138.0, -621.0, 168.8),
    },
    {
        id    = 'garage_m',
        kind  = 'ipl',
        label = 'Orta Garaj',
        cat   = 'garage',
        thumb = 'garage_m.png',
        ipl   = { 'imp_dt1_02_cargarage_a' },
        spawn = vector4(-126.5, -636.0, 168.5, 90.0),
        exit  = vector3(-123.0, -636.0, 168.5),
    },


    -- ---------- Added IPL interiors (curated from user list) ----------
    {
        id    = 'eclipse_2',
        kind  = 'ipl',
        label = 'Eclipse Towers - Tip 2',
        cat   = 'apartment',
        thumb = 'eclipse_2.png',
        ipl   = { 'apa_v_mp_h_01_c' },
        spawn = vector4(-786.87, 315.75, 217.64, 180.0),
        exit  = vector3(-786.9, 315.6, 216.0),
    },
    {
        id    = 'eclipse_3',
        kind  = 'ipl',
        label = 'Eclipse Towers - Tip 3',
        cat   = 'apartment',
        thumb = 'eclipse_3.png',
        ipl   = { 'apa_v_mp_h_02_a' },
        spawn = vector4(-781.41, 334.32, 207.63, 270.0),
        exit  = vector3(-783.5, 334.3, 206.5),
    },
    {
        id    = 'tinsel_1',
        kind  = 'ipl',
        label = 'Tinsel Towers',
        cat   = 'apartment',
        thumb = 'tinsel_1.png',
        ipl   = { 'apa_v_mp_h_08_a' },
        spawn = vector4(-614.86, 40.65, 97.6, 0.0),
        exit  = vector3(-614.8, 39.5, 96.5),
    },
    {
        id    = 'stilt_apartment',
        kind  = 'ipl',
        label = 'Vinewood Villa (Kazik Ev)',
        cat   = 'apartment',
        thumb = 'stilt_apartment.png',
        ipl   = { 'apa_v_mp_h_04_c' },
        spawn = vector4(-174.19, 497.62, 137.66, 115.0),
        exit  = vector3(-173.0, 496.0, 136.5),
    },
    {
        id    = 'office_maze',
        kind  = 'ipl',
        label = 'Maze Bank Ofisi',
        cat   = 'office',
        thumb = 'office_maze.png',
        ipl   = { 'ex_dt1_11_office_01a' },
        spawn = vector4(-75.85, -826.95, 243.39, 0.0),
        exit  = vector3(-75.8, -825.0, 242.0),
    },
    {
        id    = 'office_lomback',
        kind  = 'ipl',
        label = 'Lombank Ofisi',
        cat   = 'office',
        thumb = 'office_lomback.png',
        ipl   = { 'ex_sm_13_office_01a' },
        spawn = vector4(-1579.76, -565.07, 108.52, 90.0),
        exit  = vector3(-1579.0, -565.0, 107.5),
    },
    {
        id    = 'office_arcadius',
        kind  = 'ipl',
        label = 'Arcadius Business Center',
        cat   = 'office',
        thumb = 'office_arcadius.png',
        ipl   = { 'ex_dt1_02_office_02b' },
        spawn = vector4(-139.24, -593.11, 168.81, 100.0),
        exit  = vector3(-138.0, -591.0, 167.5),
    },
    {
        id    = 'lifeinvader',
        kind  = 'ipl',
        label = 'Lifeinvader Ofisi',
        cat   = 'office',
        thumb = 'lifeinvader.png',
        ipl   = { 'facelobby' },
        spawn = vector4(-1082.9, -251.27, 37.76, 30.0),
        exit  = vector3(-1085.0, -249.0, 36.5),
    },
    {
        id    = 'biker_club',
        kind  = 'ipl',
        label = 'Motosiklet Kulubu (MC)',
        cat   = 'clubhouse',
        thumb = 'biker_club.png',
        ipl   = { 'bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo_' },
        spawn = vector4(1107.04, -3157.4, -37.52, 0.0),
        exit  = vector3(1107.0, -3156.0, -38.5),
    },
    {
        id    = 'cocaine_lockup',
        kind  = 'ipl',
        label = 'Kokain Deposu',
        cat   = 'illegal',
        thumb = 'cocaine_lockup.png',
        ipl   = { 'bkr_biker_interior_placement_interior_1_biker_dlc_int_02_milo_' },
        spawn = vector4(1093.5, -3194.88, -38.99, 180.0),
        exit  = vector3(1088.7, -3187.5, -39.9),
    },
    {
        id    = 'meth_lab',
        kind  = 'ipl',
        label = 'Meth Laboratuvari',
        cat   = 'illegal',
        thumb = 'meth_lab.png',
        ipl   = { 'bkr_biker_interior_placement_interior_2_biker_dlc_int_03_milo_' },
        spawn = vector4(1005.65, -3200.36, -38.51, 180.0),
        exit  = vector3(997.0, -3200.7, -39.0),
    },
    {
        id    = 'weed_farm',
        kind  = 'ipl',
        label = 'Esrar Serasi',
        cat   = 'illegal',
        thumb = 'weed_farm.png',
        ipl   = { 'bkr_biker_interior_placement_interior_3_biker_dlc_int_04_milo_' },
        spawn = vector4(1051.49, -3196.53, -39.14, 90.0),
        exit  = vector3(1066.0, -3183.4, -40.0),
    },
    {
        id    = 'counterfeit_cash',
        kind  = 'ipl',
        label = 'Sahte Para Matbaasi',
        cat   = 'illegal',
        thumb = 'counterfeit_cash.png',
        ipl   = { 'bkr_biker_interior_placement_interior_4_biker_dlc_int_05_milo_' },
        spawn = vector4(1121.2, -3194.52, -40.39, 270.0),
        exit  = vector3(1114.3, -3193.3, -41.0),
    },
    {
        id    = 'document_forgery',
        kind  = 'ipl',
        label = 'Sahte Evrak Ofisi',
        cat   = 'illegal',
        thumb = 'document_forgery.png',
        ipl   = { 'bkr_biker_interior_placement_interior_5_biker_dlc_int_06_milo_' },
        spawn = vector4(1163.84, -3192.83, -39.01, 0.0),
        exit  = vector3(1167.3, -3190.0, -40.0),
    },
    {
        id    = 'bunker',
        kind  = 'ipl',
        label = 'Yeralti Siginagi (Bunker)',
        cat   = 'illegal',
        thumb = 'bunker.png',
        ipl   = { 'gr_case6_bunker_interior_placement_bunker_interior_0_gr_bunker_milo_' },
        spawn = vector4(892.63, -3245.86, -98.26, 0.0),
        exit  = vector3(889.0, -3244.0, -99.0),
    },
    {
        id    = 'facility_doomsday',
        kind  = 'ipl',
        label = 'Doomsday Tesisi',
        cat   = 'illegal',
        thumb = 'facility_doomsday.png',
        ipl   = { 'xm_bunker_interior_placement_interior_0_xm_bunker_milo_' },
        spawn = vector4(483.51, -3200.04, -98.85, 180.0),
        exit  = vector3(484.0, -3190.0, -100.0),
    },
    {
        id    = 'nightclub',
        kind  = 'ipl',
        label = 'Gece Kulubu',
        cat   = 'entertainment',
        thumb = 'nightclub.png',
        ipl   = { 'ba_case1_nightclub_interior_placement_interior_0_dlc_int_01_milo_' },
        spawn = vector4(-1604.66, -3012.58, -78.0, 0.0),
        exit  = vector3(-1601.0, -3010.0, -79.0),
    },
    {
        id    = 'arcade',
        kind  = 'ipl',
        label = 'Atari Salonu (Arcade)',
        cat   = 'entertainment',
        thumb = 'arcade.png',
        ipl   = { 'ch_chint01_ba_milo_' },
        spawn = vector4(2730.0, -373.0, -48.0, 4.0),
        exit  = vector3(2727.0, -365.0, -49.0),
    },
    {
        id    = 'strip_club',
        kind  = 'ipl',
        label = 'Vanilla Unicorn',
        cat   = 'entertainment',
        thumb = 'strip_club.png',
        ipl   = { 'v_stripclub' },
        spawn = vector4(108.31, -1289.47, 29.25, 290.0),
        exit  = vector3(106.0, -1294.0, 28.0),
    },
    {
        id    = 'comedy_club',
        kind  = 'ipl',
        label = 'Split Sides Comedy Club',
        cat   = 'entertainment',
        thumb = 'comedy_club.png',
        ipl   = { 'v_comedy' },
        spawn = vector4(-430.0, 261.0, 83.0, 0.0),
        exit  = vector3(-428.0, 263.0, 82.0),
    },
    {
        id    = 'vehicle_warehouse',
        kind  = 'ipl',
        label = 'Arac Ithalat/Ihracat Deposu',
        cat   = 'warehouse',
        thumb = 'vehicle_warehouse.png',
        ipl   = { 'imp_impexp_interior_placement_interior_1_impexp_int_02_milo_' },
        spawn = vector4(994.59, -3002.59, -39.64, 270.0),
        exit  = vector3(971.0, -2990.0, -40.0),
    },
    {
        id    = 'arena_workshop',
        kind  = 'ipl',
        label = 'Arena Workshop',
        cat   = 'workshop',
        thumb = 'arena_workshop.png',
        ipl   = { 'xs_arena_interior_vip' },
        spawn = vector4(-281.76, -2028.98, 29.15, 0.0),
        exit  = vector3(-282.0, -2025.0, 28.0),
    },
    {
        id    = 'autoshop_tuners',
        kind  = 'ipl',
        label = 'LS Tuners - Auto Shop',
        cat   = 'workshop',
        thumb = 'autoshop_tuners.png',
        ipl   = { 'tr_tuner_shop_interior_placement_interior_0_tr_tuner_shop_milo_' },
        spawn = vector4(2690.0, -370.0, -55.0, 0.0),
        exit  = vector3(2700.0, -360.0, -56.0),
    },

    -- ---------- Portable shells (infinite copies, placed anywhere) ----------
    {
        id    = 'shell_modern',
        kind  = 'shell',
        label = 'Modern Shell',
        cat   = 'shell',
        thumb = 'shell_modern.png',
        model = 'imp_prop_impexp_intintnceil',   -- replace with your shell prop model
        -- offset from shell origin where the player spawns inside
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -3.5, 1.0),
        -- where in the world the shell is instanced (hidden, far away & high up)
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'shell_loft',
        kind  = 'shell',
        label = 'Loft Shell',
        cat   = 'shell',
        thumb = 'shell_loft.png',
        model = 'imp_prop_impexp_intintnwall',
        spawnOffset = vector4(0.0, 1.0, 1.0, 180.0),
        exitOffset  = vector3(0.0, -4.0, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },

    -- ---------- Custom (truly empty - buyer makes EVERYTHING) ----------
    -- The realtor just drops the property; on entry the buyer is teleported
    -- to a flat empty void and builds walls/floor/everything via the gizmo.
    {
        id    = 'custom_void',
        kind  = 'custom',
        label = 'Custom (Boş - Her şeyi sen yap)',
        cat   = 'custom',
        thumb = 'custom_void.png',
        -- a quiet empty spot high in the sky used as the build canvas
        spawn = vector4(0.0, 0.0, 195.0, 0.0),
        exit  = vector3(0.0, -3.0, 195.0),
    },

    -- ---------- Prefab shells (native CreateObject; NO qb-interior needed) ----------
    -- Each spawns a frozen shell prop at the shared staging point. Set `model`
    -- to your own shell prop (drop the asset files into this resource's stream/
    -- folder). If the model isn't streamed it falls back to Config.ShellFallbackModel.
    {
        id    = 'qb_michael', kind = 'shell', cat = 'shell',
        label = 'Michael Evi',
        thumb = 'qb_michael.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_franklin_aunt', kind = 'shell', cat = 'shell',
        label = 'Franklin Teyze Evi',
        thumb = 'qb_franklin_aunt.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_ranch', kind = 'shell', cat = 'shell',
        label = 'Çiftlik (Ranch)',
        thumb = 'qb_ranch.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_tier1', kind = 'shell', cat = 'shell',
        label = 'Tier 1 Ev',
        thumb = 'qb_tier1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_apartment', kind = 'shell', cat = 'shell',
        label = 'Apartman Dairesi',
        thumb = 'qb_apartment.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_lester', kind = 'shell', cat = 'shell',
        label = 'Lester Evi',
        thumb = 'qb_lester.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_trevor', kind = 'shell', cat = 'shell',
        label = 'Trevor Karavanı',
        thumb = 'qb_trevor.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_caravan', kind = 'shell', cat = 'shell',
        label = 'Karavan',
        thumb = 'qb_caravan.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_container', kind = 'shell', cat = 'shell',
        label = 'Konteyner',
        thumb = 'qb_container.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_furni_mid', kind = 'shell', cat = 'shell',
        label = 'Orta Mobilyalı',
        thumb = 'qb_furni_mid.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_motel_modern', kind = 'shell', cat = 'shell',
        label = 'Modern Motel',
        thumb = 'qb_motel_modern.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_garage_med', kind = 'shell', cat = 'shell',
        label = 'Orta Garaj',
        thumb = 'qb_garage_med.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_office1', kind = 'shell', cat = 'shell',
        label = 'Ofis 1',
        thumb = 'qb_office1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_store1', kind = 'shell', cat = 'shell',
        label = 'Market / Dükkan 1',
        thumb = 'qb_store1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_warehouse1', kind = 'shell', cat = 'shell',
        label = 'Depo 1',
        thumb = 'qb_warehouse1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_apartment2', kind = 'shell', cat = 'shell',
        label = 'Apartman Dairesi 2',
        thumb = 'qb_apartment2.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_furnshell1', kind = 'shell', cat = 'shell',
        label = 'Mobilyalı Shell 1',
        thumb = 'qb_furnshell1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_furnshell2', kind = 'shell', cat = 'shell',
        label = 'Mobilyalı Shell 2',
        thumb = 'qb_furnshell2.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_furnshell3', kind = 'shell', cat = 'shell',
        label = 'Mobilyalı Shell 3',
        thumb = 'qb_furnshell3.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_unfurnshell1', kind = 'shell', cat = 'shell',
        label = 'Boş Shell 1',
        thumb = 'qb_unfurnshell1.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_unfurnshell2', kind = 'shell', cat = 'shell',
        label = 'Boş Shell 2',
        thumb = 'qb_unfurnshell2.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
    {
        id    = 'qb_unfurnshell3', kind = 'shell', cat = 'shell',
        label = 'Boş Shell 3',
        thumb = 'qb_unfurnshell3.png',
        model = Config.ShellFallbackModel,  -- <- kendi shell prop modelini yaz
        spawnOffset = vector4(0.0, 0.0, 1.0, 0.0),
        exitOffset  = vector3(0.0, -2.5, 1.0),
        instance    = vector3(0.0, 0.0, 200.0),
    },
}

-- index for quick lookup
Config.InteriorById = {}
for _, it in ipairs(Config.InteriorCatalog) do
    Config.InteriorById[it.id] = it
end

-- categories shown as tabs in the realtor interior picker
Config.InteriorCategories = {
    { id = 'apartment', label = 'Daireler' },
    { id = 'office',    label = 'Ofisler'  },
    { id = 'garage',    label = 'Garajlar' },
    { id = 'clubhouse', label = 'Kulüpler' },
    { id = 'illegal',   label = 'Yasadışı' },
    { id = 'entertainment', label = 'Eğlence' },
    { id = 'warehouse', label = 'Depolar' },
    { id = 'workshop',  label = 'Atölyeler' },
    { id = 'shell',     label = 'Shell\'ler' },
    { id = 'custom',    label = 'Custom'   },
}
