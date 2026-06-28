fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lr_properties'
author 'built for you'
version '1.0.0'
description 'Standalone properties + business system (custom gizmo, NUI catalog, ox_inventory storage). Zero UI dependencies.'

-- Required external resources:
--   oxmysql       (database)
--   ox_inventory  (storage / safe / wardrobe stash)
-- Optional (auto-detected by the money + target bridges):
--   es_extended | qb-core | ox_core   (money / framework)
--   ox_target | qb-target             (target interaction mode)

shared_scripts {
    'config/config.lua',
    'config/interiors.lua',
    'config/catalog.lua',
    'locales/init.lua',
    'locales/en.lua',
    'locales/tr.lua',
    'shared/utils.lua',
}

client_scripts {
    'client/bridge.lua',
    'client/nui.lua',
    'client/main.lua',
    'client/interior.lua',
    'client/property.lua',
    'client/interaction.lua',
    'client/doorbell.lua',
    'client/editor.lua',
    'client/menu.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/bridge.lua',
    'server/database.lua',
    'server/main.lua',
    'server/property.lua',
    'server/business.lua',
    'server/keys.lua',
    'server/storage.lua',
    'server/tax.lua',
    'server/commands.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
    'html/img/catalog/*.png',
    'html/img/catalog/*.jpg',
    'html/img/catalog/*.jpeg',
    'html/img/catalog/*.webp',
    'html/img/interiors/*.png',
    'html/img/interiors/*.jpg',
    'html/img/interiors/*.jpeg',
    'html/img/interiors/*.webp',
}

dependencies {
    'oxmysql',
    -- optional: 'qb-interior'  (required to stream qb-* shell models)
    -- optional: 'ox_target' or 'qb-target'  (required for target interaction mode)
}
