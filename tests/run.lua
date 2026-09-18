--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-INTERACT — Offline tests: option gates, key assignment, zones, locale parity
     Requires a sibling checkout of lxr-core (../lxr-core).
     Usage (from the lxr-interact folder):  lua tests/run.lua [--mock out.js en|ka]
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local CORE = os.getenv('LXR_CORE_PATH') or '../lxr-core'
package.path = CORE .. '/?.lua;' .. package.path
local ok = pcall(function() require('tests.lib.fxshim') end)
if not ok then print('lxr-core shim not found at ' .. CORE .. ' (set LXR_CORE_PATH)') os.exit(2) end
local Shim = require('tests.lib.fxshim')

Shim.load(CORE .. '/shared/main.lua')
Config = nil
Locale = nil
Shim.load('shared/locale.lua')
Shim.load('locales/en.lua')
Shim.load('locales/ka.lua')
Shim.load('config.lua')
Shim.load('shared/rules.lua')
local R = LXRInteract

local passed, failed = 0, 0
local function test(name, fn)
    local okT, err = xpcall(fn, debug.traceback)
    if okT then passed = passed + 1 print('  ^ ok   ' .. name) else failed = failed + 1 print('  x FAIL ' .. name .. '\n' .. err) end
end
local function eq(a, b, msg) if a ~= b then error((msg or 'eq') .. ': expected ' .. tostring(b) .. ' got ' .. tostring(a), 2) end end

print('lxr-interact offline tests')

test('role gates: string, list, min grade', function()
    assert(R.RoleOk(nil, nil))
    assert(R.RoleOk('vallaw', { name = 'vallaw', grade = 0 }))
    assert(not R.RoleOk('vallaw', { name = 'doctor', grade = 3 }))
    assert(R.RoleOk({ 'vallaw', 'blackwaterlaw' }, { name = 'blackwaterlaw', grade = 1 }))
    assert(R.RoleOk({ vallaw = 2 }, { name = 'vallaw', grade = 2 }))
    assert(not R.RoleOk({ vallaw = 2 }, { name = 'vallaw', grade = 1 }))
    assert(not R.RoleOk('vallaw', nil))
end)

test('item gates: name, list, counts', function()
    local inv = { lockpick = 1, rope = 3 }
    local count = function(n) return inv[n] or 0 end
    assert(R.ItemOk(nil, count))
    assert(R.ItemOk('lockpick', count))
    assert(not R.ItemOk('dynamite', count))
    assert(R.ItemOk({ 'lockpick', 'rope' }, count))
    assert(R.ItemOk({ rope = 3 }, count))
    assert(not R.ItemOk({ rope = 4 }, count))
end)

test('visible options get distinct keys; named keys are respected; canInteract filters', function()
    local opts = {
        { label = 'Search', job = 'vallaw' },
        { label = 'Rob', item = 'rope', key = 'G' },
        { label = 'Talk' },
        { label = 'Never', canInteract = function() return false end },
        { label = 'Err', canInteract = function() error('boom') end },
    }
    local seen = R.Visible(opts, { job = { name = 'vallaw', grade = 0 }, count = function(n) return n == 'rope' and 1 or 0 end })
    eq(#seen, 3)
    local keys = {}
    for _, o in ipairs(seen) do assert(o.key and o.key.hash, o.label .. ' has no key') assert(not keys[o.key.hash], 'duplicate key') keys[o.key.hash] = true end
    eq(seen[2].key.label, 'G')
    eq(seen[1].key.label, 'J')
    eq(seen[3].key.label, 'E')
    local none = R.Visible(opts, { count = function() return 0 end })
    eq(#none, 1) eq(none[1].label, 'Talk')
end)

test('maxOptions caps the card', function()
    local opts = {}
    for i = 1, 12 do opts[i] = { label = 'o' .. i } end
    eq(#R.Visible(opts, { count = function() return 0 end }), Config.Display.maxOptions)
    eq(#Config.Keys, Config.Display.maxOptions, 'one key per row')
end)

test('zones: sphere, rotated box', function()
    local s = { shape = 'sphere', coords = vector3(0, 0, 0), radius = 2 }
    assert(R.InZone(s, vector3(1, 1, 0)))
    assert(not R.InZone(s, vector3(2, 2, 0)))
    local b = { shape = 'box', coords = vector3(10, 10, 0), size = vector3(4, 2, 2), heading = 90 }
    assert(R.InZone(b, vector3(10, 11.9, 0)), 'inside along the rotated length')
    assert(not R.InZone(b, vector3(11.9, 10, 0)), 'outside across the rotated width')
    assert(not R.InZone(b, vector3(10, 10, 1.5)), 'above')
end)

test('model sets', function()
    local set = R.ModelSet({ 'p_chair01x', 12345 })
    assert(set[joaat('p_chair01x')] and set[12345])
    assert(R.ModelSet('a_c_horse_arabian_white')[joaat('a_c_horse_arabian_white')])
end)

test('locale parity + kinds labelled', function()
    local en, ka = Locale.Bundles.en, Locale.Bundles.ka
    local missing = {}
    for k in pairs(en) do if ka[k] == nil then missing[#missing + 1] = k end end
    eq(#missing, 0, 'ka missing: ' .. table.concat(missing, ', '))
    for kind in pairs(Config.Kinds) do assert(en['kind.' .. kind], 'kind label ' .. kind) end
end)

print(('%d passed, %d failed'):format(passed, failed))

if arg and arg[1] == '--mock' and arg[2] then
    Config.Lang = arg[3] or 'en'
    local msgs = {
        { action = 'init', brand = { name = 'The Land of Wolves', theme = 'night' }, lang = Config.Lang, locale = Lang.bundle() },
        { action = 'show', label = 'Sheriff\'s Office Door', anchor = 'right', hold = 0, options = { { label = 'Open the door', key = 'J' }, { label = 'Lock', key = 'E' }, { label = 'Pick the lock', key = 'G' }, { label = 'Knock', key = 'R' } } },
    }
    local f = assert(io.open(arg[2], 'w'))
    f:write('window.__LXR_MOCK__ = ' .. json.encode(msgs) .. ';\n')
    f:close()
    print('mock written to ' .. arg[2])
end
os.exit(failed == 0 and 0 or 1)
