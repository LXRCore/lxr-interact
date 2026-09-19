--[[
    LXR Core - Interact

    Brand:       LXRCore — Lux Empire eXperience RedM Core
    Product:     wolves.land / The Land of Wolves
    Developer:   iBoss21 / LXRCore
    Website:     https://www.lxrcore.com
    Discord:     https://discord.gg/GAhk8cgXe9
    GitHub:      https://github.com/LXRCore

    Version: 1.0.0
    Performance Target: 0.00 ms idle

    Framework Support:
    - LXR Core v3 (Native — GetCoreObject / GetLXR)

    © 2026 iBoss21 / LXRCore | lxrcore.com | All Rights Reserved
]]

fx_version '3.0.0'
game 'rdr3'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
lua54 'yes'

name 'lxr-interact'
author 'iBoss21 / LXRCore'
description 'LXRCore v3 interaction layer: points, zones, models, entities and global targets with gated options on one kit card'
version '1.1.2'
repository 'https://github.com/LXRCore/lxr-interact'

shared_scripts {
    'shared/locale.lua',
    'locales/*.lua',
    'config.lua',
    'shared/rules.lua',
}

client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/lxr-ui.css',
    'html/style.css',
    'html/fonts/*.woff2',
    'html/app.js',
    'html/img/*.png',
}

dependencies { 'lxr-core' }
