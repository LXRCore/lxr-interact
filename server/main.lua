--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-INTERACT — Server: the relay
     ═══════════════════════════════════════════════════════════════════════════
     Options with `serverEvent` reach their resource through here, so the
     target's distance is checked once, in one place, before any resource
     hears about it. The receiving resource still validates its own state.
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

local LXRCore = exports['lxr-core']:GetCoreObject()
local buckets = {}

local function limited(src)
    local b = buckets[src]
    local now = GetGameTimer()
    if not b or now - b.at > Config.Security.rateLimit.windowMs then b = { at = now, n = 0 } buckets[src] = b end
    b.n = b.n + 1
    return b.n > Config.Security.rateLimit.burst
end

RegisterNetEvent('lxr-interact:server:relay', function(event, netId, coords, args)
    local src = source
    if limited(src) or type(event) ~= 'string' or event:find('^lxr%-interact') then return end
    local ped = GetPlayerPed(src)
    if ped == 0 then return end
    local at = GetEntityCoords(ped)
    local entity = netId and NetworkGetEntityFromNetworkId(netId) or 0
    local where = entity ~= 0 and GetEntityCoords(entity) or (coords and vector3(coords.x, coords.y, coords.z)) or nil
    if not where or #(at - where) > Config.Security.maxRelayDistance then
        return LXRCore.Log.exploit('interact', 'relay out of range', { source = src, event = event, netId = netId })
    end
    TriggerEvent(event, src, { entity = entity ~= 0 and entity or nil, netId = netId, coords = where, args = args })
end)

AddEventHandler('playerDropped', function() buckets[source] = nil end)
