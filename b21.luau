--TimeFieldParticles
-- https://lua.expert

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimeField = require(ReplicatedStorage.Shared.Modules.TimeField)
local t1 = {}
local t2 = {}
local self = setmetatable({}, {
    __mode = "k"
})
local v2 = false

local function apply(p1, p2, p3) -- line: 31
    -- upvalues: v2 (ref)
    local TimeScale = p1.TimeScale

    if p2.written ~= nil and TimeScale ~= p2.written then
        p2.base = TimeScale
    end

    v2 = true
    p1.TimeScale = math.clamp(p2.base * p3, 0, 1)
    v2 = false
    p2.written = p1.TimeScale
    p1:SetAttribute("TimeFieldBase", p2.base)
    p1:AddTag("TimeFieldScaled")
end

local function unmark(p4) -- line: 45
    p4:RemoveTag("TimeFieldScaled")
    p4:SetAttribute("TimeFieldBase", nil)
end

local function restore(p5, p6) -- line: 50
    -- upvalues: self (copy)
    if p6.connection then
        p6.connection:Disconnect()
        p6.connection = nil
    end

    if self[p5] == p6 then
        self[p5] = nil
    end

    p5:RemoveTag("TimeFieldScaled")
    p5:SetAttribute("TimeFieldBase", nil)

    if p6.written ~= nil and p5.TimeScale == p6.written then
        p5.TimeScale = p6.base
    end
end

local function release(p7) -- line: 64
    -- upvalues: self (copy)
    if p7.connections then
        for _, v4 in p7.connections do
            v4:Disconnect()
        end
    end

    if p7.emitters then
        for v5, v6 in p7.emitters do
            if v6.connection then
                v6.connection:Disconnect()
                v6.connection = nil
            end

            if self[v5] == v6 then
                self[v5] = nil
            end

            v5:RemoveTag("TimeFieldScaled")
            v5:SetAttribute("TimeFieldBase", nil)

            if v6.written ~= nil and v5.TimeScale == v6.written then
                v5.TimeScale = v6.base
            end
        end
    end

    p7.scale = nil
    p7.emitters = nil
    p7.connections = nil
end

local function watch(p8, p9) -- line: 80
    -- upvalues: self (copy), v2 (ref), apply (copy)
    local TimeScale = p8.TimeScale
    local TimeFieldBase = TimeScale

    if p8:HasTag("TimeFieldScaled") then
        TimeFieldBase = p8:GetAttribute("TimeFieldBase")

        if typeof(TimeFieldBase) ~= "number" then
            TimeFieldBase = TimeScale
        end
    end

    if p8:GetAttribute("TimeScale") == nil then
        p8:SetAttribute("TimeScale", TimeFieldBase)
    end

    local t5 = {
        base = TimeFieldBase
    }

    self[p8] = t5
    t5.connection = p8:GetPropertyChangedSignal("TimeScale"):Connect(function() -- line: 98
        -- upvalues: p8 (copy), p9 (copy), t5 (copy), v2 (ref), apply (copy)
        local scale = p9.scale

        if not v2 and scale ~= nil and t5.connection ~= nil and p8.TimeScale ~= t5.written then
            apply(p8, t5, scale)
        end
    end)

    return t5
end

local function isTemplate(p10, p11) -- line: 112
    local Parent = p10.Parent

    while true do
        if Parent == nil or Parent == p11 then
            return false
        end

        if Parent:GetAttribute("VFXTemplate") then
            break
        end

        Parent = Parent.Parent
    end

    return true
end

local function capture(p12, p13) -- line: 123
    -- upvalues: self (copy), apply (copy), watch (copy), isTemplate (copy)
    local t6 = {}

    for _, descendant in p12:GetDescendants() do
        if descendant:IsA("ParticleEmitter") and not isTemplate(descendant, p12) then
            t6[descendant] = watch(descendant, p13)
        end
    end

    p13.emitters = t6
    p13.connections = {
        p12.DescendantAdded:Connect(function(p14) -- line: 133
            -- upvalues: p12 (copy), p13 (copy), t6 (copy), apply (copy), watch (copy), isTemplate (copy)
            if p14:IsA("ParticleEmitter") and p13.scale ~= nil and not isTemplate(p14, p12) then
                local v7 = watch(p14, p13)

                t6[p14] = v7
                apply(p14, v7, p13.scale)
            end
        end),
        p12.DescendantRemoving:Connect(function(p15) -- line: 144
            -- upvalues: t6 (copy), self (copy)
            local v8 = t6[p15]

            if not v8 then
                return
            end

            t6[p15] = nil

            if v8.connection then
                v8.connection:Disconnect()
                v8.connection = nil
            end

            if self[p15] == v8 then
                self[p15] = nil
            end

            p15:RemoveTag("TimeFieldScaled")
            p15:SetAttribute("TimeFieldBase", nil)

            if v8.written ~= nil and p15.TimeScale == v8.written then
                p15.TimeScale = v8.base
            end
        end)
    }
end

CollectionService:GetInstanceAddedSignal("TimeFieldScaled"):Connect(function(p16) -- line: 155
    -- upvalues: self (copy)
    if p16:IsA("ParticleEmitter") and self[p16] == nil then
        local TimeFieldBase = p16:GetAttribute("TimeFieldBase")

        p16:RemoveTag("TimeFieldScaled")
        p16:SetAttribute("TimeFieldBase", nil)

        if typeof(TimeFieldBase) == "number" then
            p16.TimeScale = TimeFieldBase
        end
    end
end)
TimeField.onRefresh(function() -- line: 166
    -- upvalues: TimeField (copy), t2 (copy), apply (copy), release (copy), capture (copy)
    for v9, v10 in t2 do
        local v11 = TimeField.scaleFor(v9)

        if v11 == 1 then
            if v10.emitters ~= nil then
                release(v10)
            end
        else
            if v10.emitters == nil then
                capture(v9, v10)
            end

            local v12 = v11 ~= v10.scale

            v10.scale = v11

            for v13, v14 in v10.emitters do
                if v12 or v13.TimeScale ~= v14.written then
                    apply(v13, v14, v11)
                end
            end
        end
    end
end)

function t1.track(p17) -- line: 190
    -- upvalues: t2 (copy), release (copy)
    local t7 = {}

    t2[p17] = t7

    return function() -- line: 193
        -- upvalues: p17 (copy), t7 (copy), t2 (copy), release (copy)
        if t2[p17] == t7 then
            t2[p17] = nil
        end

        release(t7)
    end
end

return t1
