--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-INTERACT — Client: registry, scan, card, input
     ═══════════════════════════════════════════════════════════════════════════
     Resources register targets through exports; this file finds the one the
     player is looking at or standing in, gates the options, shows the card
     and runs the chosen option. Registrations die with the resource that
     made them.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
-- LXRCore crosses the export as a copy: its PlayerData would stay what it was at load. The core broadcasts every
-- change (money, job, metadata) — keep ours current.
RegisterNetEvent('lxr:client:data', function(d) if type(d) == 'table' then LXRCore.PlayerData = d end end)
RegisterNetEvent('lxr:client:unloaded', function() LXRCore.PlayerData = {} end)
local R = LXRInteract

local points, zones, models, entities, globals = {}, {}, {}, {}, { player = {}, ped = {}, horse = {}, vehicle = {}, object = {} }
local owner = {}          -- id → resource that registered it
local disabled = false
local current = nil       -- { key, label, options, entity, coords, kind }

local function ped() return PlayerPedId() end
local function me() return LXRCore.PlayerData or {} end
local function role(kind)
    local r = me()[kind]
    if type(r) ~= 'table' then return nil end
    return { name = r.name, grade = type(r.grade) == 'table' and r.grade.level or r.grade }
end
local function count(name)
    local n = 0
    for _, it in pairs(me().items or {}) do if it and it.name == name then n = n + (it.amount or 0) end end
    return n
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📇 REGISTRY
-- ═══════════════════════════════════════════════════════════════════════════════
local function reg(store, id, def)
    if not id or type(def) ~= 'table' or type(def.options) ~= 'table' then return false end
    def.id = id
    store[id] = def
    owner[id] = GetInvokingResource() or GetCurrentResourceName()
    return true
end

local function remove(id)
    points[id] = nil zones[id] = nil models[id] = nil entities[id] = nil
    for _, g in pairs(globals) do g[id] = nil end
    owner[id] = nil
end

exports('AddPoint', function(id, coords, opts)
    opts = opts or {}
    return reg(points, id, { coords = vector3(coords.x, coords.y, coords.z), distance = opts.distance or Config.Scan.pointDistance, label = opts.label, options = opts.options, marker = opts.marker })
end)
exports('AddZone', function(id, zone, opts)
    opts = opts or {}
    zone.coords = vector3(zone.coords.x, zone.coords.y, zone.coords.z)
    return reg(zones, id, { zone = zone, label = opts.label, options = opts.options })
end)
exports('AddModel', function(id, list, opts)
    opts = opts or {}
    return reg(models, id, { set = R.ModelSet(list), distance = opts.distance or Config.Scan.lookDistance, label = opts.label, options = opts.options })
end)
exports('AddEntity', function(id, entity, opts)
    opts = opts or {}
    local netId = opts.net and entity or (NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or nil)
    return reg(entities, id, { entity = (not opts.net) and entity or nil, netId = netId, distance = opts.distance or Config.Scan.lookDistance, label = opts.label, options = opts.options })
end)
exports('AddGlobal', function(id, kind, opts)
    opts = opts or {}
    if not globals[kind] then return false end
    return reg(globals[kind], id, { distance = opts.distance or Config.Scan.lookDistance, label = opts.label or (Config.Kinds[kind] or {}).label, options = opts.options })
end)
exports('Remove', remove)
exports('Disable', function(on) disabled = on == true end)
exports('IsActive', function() return current ~= nil end)

AddEventHandler('onResourceStop', function(res)
    for id, r in pairs(owner) do if r == res then remove(id) end end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🔭 SCAN
-- ═══════════════════════════════════════════════════════════════════════════════
local function forward()
    local rot = GetGameplayCamRot(2)
    local rz, rx = math.rad(rot.z), math.rad(rot.x)
    return vector3(-math.sin(rz) * math.abs(math.cos(rx)), math.cos(rz) * math.abs(math.cos(rx)), math.sin(rx))
end

local function lookAt(maxDist)
    local from = GetGameplayCamCoord()
    local to = from + forward() * (maxDist + 4.0)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, Config.Scan.rayFlags, ped(), 4)
    local _, hit, endCoords, _, entity = GetShapeTestResult(handle)
    if hit and entity and entity ~= 0 then return entity, endCoords end
    return nil
end

local function kindOf(entity)
    if IsEntityAPed(entity) then
        if IsPedAPlayer(entity) then return 'player' end
        if IsPedHuman(entity) then return 'ped' end
        if IsThisModelAHorse(GetEntityModel(entity)) then return 'horse' end
        return 'ped'
    elseif IsEntityAVehicle(entity) then return 'vehicle'
    elseif IsEntityAnObject(entity) then return 'object' end
    return nil
end

local function optionsFor(entity, dist)
    local list, label = {}, nil
    local model = GetEntityModel(entity)
    local netId = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity) or nil
    for _, e in pairs(entities) do
        if ((e.entity and e.entity == entity) or (e.netId and netId and e.netId == netId)) and dist <= e.distance then
            label = label or e.label
            for _, o in ipairs(e.options) do list[#list + 1] = o end
        end
    end
    for _, m in pairs(models) do
        if m.set[model] and dist <= m.distance then
            label = label or m.label
            for _, o in ipairs(m.options) do list[#list + 1] = o end
        end
    end
    local kind = kindOf(entity)
    if kind then
        for _, g in pairs(globals[kind]) do
            if dist <= g.distance then
                label = label or g.label
                for _, o in ipairs(g.options) do list[#list + 1] = o end
            end
        end
    end
    return list, label, kind
end

local function scan()
    local p = ped()
    local pos = GetEntityCoords(p)
    local md = me().metadata or {}
    if disabled or (md.isdead and not Config.Scan.whileDead) or (md.ishandcuffed and not Config.Scan.whileCuffed) then return nil end
    if Config.Scan.aimOnly and not IsPlayerFreeAiming(PlayerId()) then return nil end
    -- 1. the thing in the crosshair
    local best
    local maxLook = Config.Scan.lookDistance
    for _, m in pairs(models) do if m.distance > maxLook then maxLook = m.distance end end
    local entity = lookAt(maxLook)
    if entity and entity ~= p then
        local dist = #(pos - GetEntityCoords(entity))
        local list, label, kind = optionsFor(entity, dist)
        if #list > 0 then
            best = { key = 'e:' .. entity, entity = entity, kind = kind, label = label, raw = list, distance = dist, coords = GetEntityCoords(entity) }
            if Config.Scan.preferLookAt then return best end
        end
    end
    -- 2. the nearest point or zone
    local nearest, nd = nil, math.huge
    for id, pt in pairs(points) do
        local d = #(pos - pt.coords)
        if d <= pt.distance and d < nd then nearest, nd = { key = 'p:' .. id, label = pt.label, raw = pt.options, distance = d, coords = pt.coords, marker = pt.marker }, d end
    end
    for id, z in pairs(zones) do
        if R.InZone(z.zone, pos) then
            local d = R.ZoneDistance(z.zone, pos)
            if d < nd then nearest, nd = { key = 'z:' .. id, label = z.label, raw = z.options, distance = d, coords = z.zone.coords }, d end
        end
    end
    return best or nearest
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 🃏 CARD + INPUT
-- ═══════════════════════════════════════════════════════════════════════════════
-- prompts mode: the game's own prompt group instead of the card
local group = nil   -- { id, handles = {} }
local function promptsOff()
    if not group then return end
    for _, h in ipairs(group.handles) do PromptDelete(h) end
    group = nil
end
local function promptsOn(t)
    promptsOff()
    group = { id = GetRandomIntInRange(0, 0xffffff), handles = {} }
    for _, o in ipairs(t.options) do
        if o.key then
            local h = PromptRegisterBegin()
            PromptSetControlAction(h, o.key.hash)
            PromptSetText(h, CreateVarString(10, 'LITERAL_STRING', o.label))
            if Config.Display.holdMs > 0 then PromptSetStandardizedHoldMode(h, Config.Display.holdMs) else PromptSetStandardMode(h, true) end
            PromptSetGroup(h, group.id, 0)
            PromptSetEnabled(h, true) PromptSetVisible(h, true)
            PromptRegisterEnd(h)
            group.handles[#group.handles + 1] = h
        end
    end
end

local function hide()
    if not current then return end
    current = nil
    if Config.Display.mode == 'card' then SendNUIMessage({ action = 'hide' }) else promptsOff() end
end

local function show(t)
    local visible = R.Visible(t.raw, { job = role('job'), gang = role('gang'), count = count, target = t.entity or t.coords, distance = t.distance })
    if #visible == 0 then hide() return end
    t.options = visible
    local same = current and current.key == t.key
    current = t
    if Config.Display.mode == 'card' then
        local rows = {}
        for i, o in ipairs(visible) do rows[i] = { label = o.label, key = o.key and o.key.label or '', icon = o.icon } end
        SendNUIMessage({ action = same and 'update' or 'show', label = t.label or (Config.Kinds[t.kind or ''] or {}).label or '', options = rows, anchor = Config.Display.anchor, hold = Config.Display.holdMs, brand = LXRCore.Brand })
    elseif not same then promptsOn(t) end
end

local function run(o)
    local t = current
    if not t then return end
    local data = { entity = t.entity, netId = t.entity and NetworkGetEntityIsNetworked(t.entity) and NetworkGetNetworkIdFromEntity(t.entity) or nil, coords = t.coords, kind = t.kind, distance = t.distance, args = o.args, label = o.label }
    hide()
    if type(o.onSelect) == 'function' then
        -- the option belongs to another resource: its own thread, so it may yield (an RPC, a progress bar)
        CreateThread(function()
            local ok, err = pcall(o.onSelect, data)
            if not ok then print(('^1[lxr-interact]^7 option "%s" failed: %s'):format(tostring(o.label), type(err) == 'table' and json.encode(err) or tostring(err))) end
        end)
    elseif o.event then TriggerEvent(o.event, data)
    elseif o.serverEvent then TriggerServerEvent('lxr-interact:server:relay', o.serverEvent, data.netId, data.coords, o.args)
    end
end

local eye = { on = false, target = nil, menu = false }   -- the eye's state (below); the card scan pauses while it is up

CreateThread(function()
    local holdStart, holdKey = nil, nil
    while true do
        if not LocalPlayer.state.isLoggedIn then Wait(1000) else
            local t = (not eye.on) and scan() or nil
            if t then show(t) else hide() end
            if not current then Wait(Config.Scan.idleMs) else
                local until_ = GetGameTimer() + Config.Scan.activeMs
                while current and GetGameTimer() < until_ do
                    if Config.Display.marker and current.coords and not current.entity then
                        DrawMarker(0x94FDAE17, current.coords.x, current.coords.y, current.coords.z - 0.95, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.2, 244, 242, 238, 90, false, false, 2, false, nil, nil, false)
                    end
                    if group then PromptSetActiveGroupThisFrame(group.id, CreateVarString(10, 'LITERAL_STRING', current.label or '')) end
                    for _, o in ipairs(current.options) do
                        if o.key then
                            if Config.Display.holdMs > 0 then
                                if IsControlPressed(0, o.key.hash) then
                                    if holdKey ~= o.key.hash then holdKey, holdStart = o.key.hash, GetGameTimer() end
                                    local f = (GetGameTimer() - holdStart) / Config.Display.holdMs
                                    SendNUIMessage({ action = 'hold', key = o.key.label, f = math.min(1, f) })
                                    if f >= 1 then holdKey = nil run(o) break end
                                elseif holdKey == o.key.hash then holdKey = nil SendNUIMessage({ action = 'hold', key = o.key.label, f = 0 }) end
                            elseif IsControlJustReleased(0, o.key.hash) then run(o) break end
                        end
                    end
                    Wait(0)
                end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- 👁️ THE EYE — hold the key, a cursor, point, click, pick
-- ═══════════════════════════════════════════════════════════════════════════════
-- the world ray under the cursor: camera position + the direction through that pixel
local function cursorRay(reach)
    local cx, cy = GetNuiCursorPosition()
    local w, h = Citizen.InvokeNative(0x66773C92835D0909, Citizen.PointerValueInt(), Citizen.PointerValueInt())   -- GET_SCREEN_RESOLUTION (RDR3; there is no GetActiveScreenResolution)
    if not w or w == 0 or not h or h == 0 then return nil end
    local nx, ny = (cx / w - 0.5) * 2.0, (0.5 - cy / h) * 2.0
    local rot = GetGameplayCamRot(2)
    local rz, rx = math.rad(rot.z), math.rad(rot.x)
    local fwd = vector3(-math.sin(rz) * math.cos(rx), math.cos(rz) * math.cos(rx), math.sin(rx))
    local right = vector3(math.cos(rz), math.sin(rz), 0.0)
    local up = vector3(math.sin(rz) * math.sin(rx), -math.cos(rz) * math.sin(rx), math.cos(rx))
    local tanV = math.tan(math.rad(GetGameplayCamFov()) / 2.0)
    local dir = fwd + right * (nx * tanV * (w / h)) + up * (ny * tanV)
    dir = dir / #dir
    local from = GetGameplayCamCoord()
    return from, from + dir * reach
end

local function eyeScan()
    local p = ped()
    local from, to = cursorRay(Config.Eye.reach)
    if not from then return nil end
    local handle = StartExpensiveSynchronousShapeTestLosProbe(from.x, from.y, from.z, to.x, to.y, to.z, Config.Scan.rayFlags, p, 4)
    local _, hit, at, _, entity = GetShapeTestResult(handle)
    local pos = GetEntityCoords(p)
    if hit and entity and entity ~= 0 and entity ~= p then
        local dist = #(pos - GetEntityCoords(entity))
        local list, label, kind = optionsFor(entity, dist)
        if #list > 0 then return { key = 'e:' .. entity, entity = entity, kind = kind, label = label, raw = list, distance = dist, coords = GetEntityCoords(entity) } end
    end
    -- a point near where the ray landed (or, with nothing hit, near its end)
    local landed = hit and at or to
    local nearest, nd = nil, math.huge
    for id, pt in pairs(points) do
        local d = #(landed - pt.coords)
        if d <= Config.Eye.pointHit and #(pos - pt.coords) <= math.max(pt.distance, Config.Eye.reach) and d < nd then
            nearest, nd = { key = 'p:' .. id, label = pt.label, raw = pt.options, distance = #(pos - pt.coords), coords = pt.coords }, d
        end
    end
    return nearest
end

local function eyeOff()
    if not eye.on then return end
    eye.on, eye.target, eye.menu = false, nil, false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'eye', on = false })
end

local function eyeOn()
    if eye.on or not Config.Eye.enabled or not LocalPlayer.state.isLoggedIn or IsNuiFocused() or IsPauseMenuActive() then return end
    local md = me().metadata or {}
    if disabled or (md.isdead and not Config.Scan.whileDead) or (md.ishandcuffed and not Config.Scan.whileCuffed) then return end
    eye.on = true
    hide()
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(true)
    SendNUIMessage({ action = 'eye', on = true })
    CreateThread(function()
        while eye.on do
            DisableControlAction(0, 0xA987235F, true) DisableControlAction(0, 0xD2047988, true)   -- look
            DisableControlAction(0, 0x07CE1E61, true) DisableControlAction(0, 0xF84FA74F, true)   -- attack / aim
            DisableControlAction(0, 0x156F7119, true)                                              -- frontend cancel
            if not eye.menu then
                local t = eyeScan()
                if t then
                    local visible = R.Visible(t.raw, { job = role('job'), gang = role('gang'), count = count, target = t.entity or t.coords, distance = t.distance })
                    t.options = #visible > 0 and visible or nil
                end
                local key = t and t.options and t.key or nil
                if key ~= (eye.target and eye.target.key) then
                    eye.target = t and t.options and t or nil
                    SendNUIMessage({ action = 'eyeTarget', on = eye.target ~= nil, label = eye.target and (eye.target.label or (Config.Kinds[eye.target.kind or ''] or {}).label) or '' })
                end
                if eye.target and IsDisabledControlJustReleased(0, 0x07CE1E61) then
                    eye.menu = true
                    local rows = {}
                    for i, o in ipairs(eye.target.options) do rows[i] = { label = o.label, icon = o.icon, key = o.key and o.key.label or '' } end
                    SendNUIMessage({ action = 'menu', label = eye.target.label or (Config.Kinds[eye.target.kind or ''] or {}).label or '', options = rows })
                end
            end
            Wait(0)
        end
    end)
end

RegisterCommand('+lxr_eye', function() eyeOn() end, false)
RegisterCommand('-lxr_eye', function() eyeOff() end, false)
if Config.Eye.enabled then RegisterKeyMapping('+lxr_eye', 'Interact — the eye', 'keyboard', Config.Eye.key) end

RegisterNUICallback('eye:pick', function(d, cb)
    cb('ok')
    local t = eye.target
    local o = t and t.options and t.options[tonumber(d and d.index) or 0]
    eyeOff()
    if not o then return end
    current = t
    run(o)
end)
RegisterNUICallback('eye:close', function(_, cb) cb('ok') if eye.on then eye.menu = false SendNUIMessage({ action = 'menu', options = nil }) end end)

RegisterNetEvent('lxr:client:unloaded', function() hide() eyeOff() end)
AddEventHandler('onResourceStop', function(res) if res == GetCurrentResourceName() then hide() eyeOff() end end)

-- the core's Brand carries the theme; tell the page once it is known
CreateThread(function()
    Wait(500)
    SendNUIMessage({ action = 'init', brand = LXRCore.Brand, lang = Config.Lang, locale = Lang.bundle() })
end)

if Config.Debug.printBanner then
    CreateThread(function() Wait(1000) print(('^1[lxr-interact]^7 v%s — %s mode, scan %d ms'):format(GetResourceMetadata(GetCurrentResourceName(), 'version', 0), Config.Display.mode, Config.Scan.idleMs)) end)
end
