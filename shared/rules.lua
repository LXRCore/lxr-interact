--[[ ═══════════════════════════════════════════════════════════════════════════
     LXR-INTERACT — Shared rules: option gates, keys, zones
     ═══════════════════════════════════════════════════════════════════════════
     Pure functions, no natives: the client filters and lays out with them,
     the offline tests exercise them.

     An option:
       { label, key?, hold?, icon?, job?, gang?, grade?, item?, canInteract?,
         onSelect? | event? | serverEvent?, args? }
       job  = 'vallaw' | { 'vallaw', 'blackwaterlaw' } | { vallaw = 2 } (min grade)
       gang = same shape;  item = 'lockpick' | { 'a', 'b' } | { a = 2 }
     ═══════════════════════════════════════════════════════════════════════════
     © 2026 iBoss21 / LXRCore — All Rights Reserved
     ═══════════════════════════════════════════════════════════════════════════ ]]

LXRInteract = LXRInteract or {}
local R = LXRInteract

---Does the player's role satisfy an option's `job` / `gang` gate.
---@param need string|table|nil
---@param have table|nil { name, grade }
function R.RoleOk(need, have)
    if need == nil then return true end
    if not have or not have.name then return false end
    local grade = tonumber(have.grade) or 0
    if type(need) == 'string' then return need == have.name end
    if type(need) ~= 'table' then return false end
    if need[have.name] ~= nil and type(need[have.name]) == 'number' then return grade >= need[have.name] end
    for k, v in pairs(need) do
        if type(k) == 'number' and v == have.name then return true end
    end
    return false
end

---Does the satchel satisfy an option's `item` gate. `count(name)` is supplied by the caller.
function R.ItemOk(need, count)
    if need == nil then return true end
    if type(need) == 'string' then return (count(need) or 0) >= 1 end
    if type(need) ~= 'table' then return false end
    for k, v in pairs(need) do
        if type(k) == 'string' then if (count(k) or 0) < (tonumber(v) or 1) then return false end
        elseif (count(v) or 0) < 1 then return false end
    end
    return true
end

---Options a player may see for a target, with keys assigned.
---@param options table[]
---@param ctx table { job, gang, count = fn(name), canInteract = fn(option) → bool|nil, target }
---@return table[] visible (copies with .key resolved to { hash, label })
function R.Visible(options, ctx)
    local out, used = {}, {}
    for _, o in ipairs(options or {}) do
        if R.RoleOk(o.job, ctx.job) and R.RoleOk(o.gang, ctx.gang) and R.ItemOk(o.item, ctx.count or function() return 0 end) then
            local ok = true
            if type(o.canInteract) == 'function' then
                local fine, res = pcall(o.canInteract, ctx.target, ctx.distance, o)
                ok = fine and res ~= false
            end
            if ok then
                local c = {}
                for k, v in pairs(o) do c[k] = v end
                out[#out + 1] = c
            end
        end
        if #out >= (Config.Display.maxOptions or 8) then break end
    end
    -- keys: named ones first, then the free list in order
    for _, o in ipairs(out) do
        if type(o.key) == 'table' and o.key.hash then used[o.key.hash] = true
        elseif type(o.key) == 'number' then
            local label = '?'
            for _, k in ipairs(Config.Keys) do if k.hash == o.key then label = k.label end end
            o.key = { hash = o.key, label = label } used[o.key.hash] = true
        elseif type(o.key) == 'string' then
            local want, found = o.key:upper(), nil
            for _, k in ipairs(Config.Keys) do if k.label == want then found = { hash = k.hash, label = k.label } end end
            o.key = found
            if found then used[found.hash] = true end
        end
    end
    local i = 1
    for _, o in ipairs(out) do
        if not o.key then
            while Config.Keys[i] and used[Config.Keys[i].hash] do i = i + 1 end
            local k = Config.Keys[i]
            if k then o.key = { hash = k.hash, label = k.label } used[k.hash] = true i = i + 1 end
        end
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- 📐 ZONES
-- ═══════════════════════════════════════════════════════════════════════════════
---@param zone table { shape = 'sphere', coords, radius } | { shape = 'box', coords, size = vector3(l, w, h), heading }
---@param p vector3
function R.InZone(zone, p)
    local c = zone.coords
    if zone.shape == 'sphere' or zone.radius then
        return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z)) <= (zone.radius or 1.0)
    end
    local size = zone.size or vector3(2.0, 2.0, 2.0)
    local dx, dy, dz = p.x - c.x, p.y - c.y, p.z - c.z
    if math.abs(dz) > size.z / 2 then return false end
    local h = math.rad(zone.heading or 0)
    local cs, sn = math.cos(h), math.sin(h)
    local lx = dx * cs + dy * sn
    local ly = -dx * sn + dy * cs
    return math.abs(lx) <= size.x / 2 and math.abs(ly) <= size.y / 2
end

---Distance from a point to a zone's centre (for ranking).
function R.ZoneDistance(zone, p) local c = zone.coords return #(vector3(p.x, p.y, p.z) - vector3(c.x, c.y, c.z)) end

---Normalise a model list into a set of hashes.
function R.ModelSet(models)
    local set = {}
    if type(models) ~= 'table' then models = { models } end
    for _, m in ipairs(models) do
        if type(m) == 'string' then set[joaat(m)] = true elseif type(m) == 'number' then set[m] = true end
    end
    return set
end
