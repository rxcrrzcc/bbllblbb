--ProjectilePool
-- https://lua.expert

local function getStorageParent() -- line: 15
    return workspace.CurrentCamera or workspace
end

local t1 = {}

t1.__index = t1

local t2 = {}

local function applyProjectilePartDefaults(p1) -- line: 48
    p1.Anchored = true
    p1.CanCollide = false
    p1.CanQuery = false
    p1.CanTouch = false
    p1.CastShadow = false
end

local function prepareClone(p2) -- line: 57
    local clone = p2:Clone()

    clone.Anchored = true
    clone.CanCollide = false
    clone.CanQuery = false
    clone.CanTouch = false
    clone.CastShadow = false

    local t3 = {
        parts = {
            {
                part = clone,
                transparency = clone.Transparency
            }
        },
        trails = {},
        effects = {}
    }

    for _, descendant in clone:GetDescendants() do
        if descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
            descendant:Destroy()
        elseif descendant:IsA("BasePart") then
            descendant.Anchored = true
            descendant.CanCollide = false
            descendant.CanQuery = false
            descendant.CanTouch = false
            descendant.CastShadow = false
            table.insert(t3.parts, {
                part = descendant,
                transparency = descendant.Transparency
            })
        elseif descendant:IsA("Trail") then
            descendant.Enabled = false
            table.insert(t3.trails, descendant)
            table.insert(t3.effects, descendant)
        elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
            descendant.Enabled = false
            table.insert(t3.effects, descendant)
        end
    end

    return clone, t3
end

local function setEffectsEnabled(p3, p4) -- line: 87
    for _, v1 in p3.effects do
        v1.Enabled = p4
    end
end

local function showPart(p5) -- line: 93
    for _, v2 in p5.parts do
        v2.part.Transparency = v2.transparency
    end
end

local function hidePart(p6) -- line: 99
    for _, v3 in p6.effects do
        v3.Enabled = false
    end

    for _, v4 in p6.parts do
        v4.part.Transparency = 1
    end
end

function t1.take(p7) -- line: 106
    -- upvalues: prepareClone (copy)
    local v5

    if #p7._available > 0 then
        v5 = table.remove(p7._available)
    else
        local v6

        v5, v6 = prepareClone(p7._template)
        p7._data[v5] = v6
    end

    local v7 = p7._data[v5]

    for _, v8 in v7.parts do
        v8.part.Transparency = v8.transparency
    end

    v5.Parent = workspace.CurrentCamera or workspace

    for _, v9 in v7.trails do
        v9.Enabled = true
    end

    return v5
end

function t1.enableEffects(p8, p9) -- line: 128
    local v10 = p8._data[p9]

    if v10 then
        for _, v11 in v10.effects do
            v11.Enabled = true
        end
    end
end

function t1.hide(p10, p11) -- line: 137
    local v12 = p10._data[p11]

    if not v12 then
        p11.Transparency = 1

        return
    end

    for _, v13 in v12.effects do
        v13.Enabled = false
    end

    for _, v14 in v12.parts do
        v14.part.Transparency = 1
    end
end

function t1.release(p12, p13) -- line: 147
    p12:hide(p13)
    p13.Parent = nil
    table.insert(p12._available, p13)
end

return {
    get = function(p14, p15) -- get | line: 157
        -- upvalues: t1 (copy), t2 (copy), prepareClone (copy)
        if t2[p14] then
            return t2[p14]
        end

        local v15 = setmetatable({
            _size = 0,
            _template = p14,
            _available = {},
            _data = {}
        }, t1)

        p15 = p15 or 4

        for _ = 1, p15 do
            local v17, v18 = prepareClone(p14)

            v15._data[v17] = v18

            for _, v19 in v18.effects do
                v19.Enabled = false
            end

            for _, v20 in v18.parts do
                v20.part.Transparency = 1
            end

            v17.Parent = nil
            table.insert(v15._available, v17)
        end

        v15._size = p15
        t2[p14] = v15

        return v15
    end
}
