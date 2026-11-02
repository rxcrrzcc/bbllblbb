--TimeField
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TimeDilation = require(ReplicatedStorage.Shared.Modules.TimeDilation)
local v1 = RunService:IsClient()
local t1 = {}
local t2 = {}
local t3 = {}
local self = setmetatable({}, {
    __mode = "k"
})
local n1 = 0
local connection, v3

local function runRefreshers() -- line: 41
    -- upvalues: t3 (copy)
    for _, v4 in t3 do
        task.spawn(v4)
    end
end

local function syncRefreshLoop() -- line: 47
    -- upvalues: RunService (copy), v1 (copy), t3 (copy), n1 (ref), connection (ref)
    if n1 > 0 then
        if connection == nil and v1 and #t3 > 0 then
            local n2 = 0

            connection = RunService.Heartbeat:Connect(function(p1) -- line: 51
                -- upvalues: n2 (ref), t3 (copy)
                n2 += p1

                if n2 >= 0.15 then
                    n2 = 0

                    for _, v5 in t3 do
                        task.spawn(v5)
                    end
                end
            end)
        end
    elseif connection then
        connection:Disconnect()
        connection = nil

        for _, v6 in t3 do
            task.spawn(v6)
        end
    end
end

function t1.setField(p2, p3) -- line: 67
    -- upvalues: t2 (copy), n1 (ref), syncRefreshLoop (copy)
    local v7 = t2[p2] ~= nil

    t2[p2] = p3

    if p3 == nil or v7 then
        if p3 == nil and v7 then
            n1 -= 1
            syncRefreshLoop()
        end
    else
        n1 += 1
        syncRefreshLoop()
    end
end

function t1.hasFields() -- line: 79
    -- upvalues: n1 (ref)
    return n1 > 0
end

function t1.clear() -- line: 83
    -- upvalues: t2 (copy), n1 (ref), syncRefreshLoop (copy)
    table.clear(t2)
    n1 = 0
    syncRefreshLoop()
end

function t1.onRefresh(p4) -- line: 90
    -- upvalues: t3 (copy), syncRefreshLoop (copy)
    table.insert(t3, p4)
    syncRefreshLoop()
end

function t1.setImmunityCheck(p5) -- line: 96
    -- upvalues: self (copy), v3 (ref)
    v3 = p5
    table.clear(self)
end

local function isImmune(p6) -- line: 102
    -- upvalues: self (copy), v3 (ref)
    local v8 = v3

    if v8 == nil then
        return false
    end

    local v9 = if p6:IsA("Model") then p6 else p6:FindFirstAncestorOfClass("Model")

    while true do
        if v9 == nil then
            return false
        end

        if self[v9] or v8(v9) then
            break
        end

        v9 = v9:FindFirstAncestorOfClass("Model")
    end

    self[v9] = true

    return true
end

local function toCandidate(p7, p8) -- line: 121
    return {
        affectsAbilities = false,
        affectsUnitCooldowns = true,
        level = p8.level,
        placedAt = p8.placedAt,
        scale = p8.scale,
        id = p7
    }
end

function t1.scaleAt(p9) -- line: 133
    -- upvalues: TimeDilation (copy), t2 (copy), n1 (ref)
    if n1 == 0 then
        return 1
    end

    local v10, v11, t6

    for v12, v13 in t2 do
        local v14 = p9.X - v13.position.X
        local v15 = p9.Z - v13.position.Z

        if math.sqrt(v14 * v14 + v15 * v15) <= v13.range and math.abs(p9.Y - v13.position.Y) <= v13.height then
            if v11 ~= nil then
                if t6 == nil then
                    t6 = {
                        {
                            affectsAbilities = false,
                            affectsUnitCooldowns = true,
                            level = v11.level,
                            placedAt = v11.placedAt,
                            scale = v11.scale,
                            id = v10
                        }
                    }
                end

                table.insert(t6, {
                    affectsAbilities = false,
                    affectsUnitCooldowns = true,
                    level = v13.level,
                    placedAt = v13.placedAt,
                    scale = v13.scale,
                    id = v12
                })
            else
                v11 = v13
                v10 = v12
            end
        end
    end

    if t6 == nil then
        if v11 == nil then
            return 1
        end

        return TimeDilation.sanitizeScale(v11.scale)
    end

    local v18 = TimeDilation.pickWinner(t6)

    if v18 == nil then
        return 1
    end

    return TimeDilation.sanitizeScale(v18.scale)
end

function t1.consumableScaleAt(p10) -- line: 174
    -- upvalues: TimeDilation (copy), t2 (copy), n1 (ref)
    if n1 == 0 then
        return 1
    end

    local t8

    for v19, v20 in t2 do
        if v20.affectsConsumables == true then
            local v21 = p10.X - v20.position.X
            local v22 = p10.Z - v20.position.Z

            if math.sqrt(v21 * v21 + v22 * v22) <= v20.range and math.abs(p10.Y - v20.position.Y) <= v20.height then
                if t8 == nil then
                    t8 = {}
                end

                table.insert(t8, {
                    affectsAbilities = false,
                    affectsUnitCooldowns = true,
                    level = v20.level,
                    placedAt = v20.placedAt,
                    scale = v20.scale,
                    id = v19
                })
            end
        end
    end

    if t8 == nil then
        return 1
    end

    local v25 = TimeDilation.pickWinner(t8)

    if v25 == nil then
        return 1
    end

    return TimeDilation.sanitizeScale(v25.scale)
end

function t1.shiftCountdown(p11, p12, p13, p14, p15) -- line: 211
    -- upvalues: TimeDilation (copy)
    if p11.endTime ~= p12 then
        p11.endTime = p12
        p11.pending = 0
        p11.elapsed = 0
    end

    p11.pending += p14 * (1 - TimeDilation.sanitizeScale(p15))
    p11.elapsed += p14

    local v26 = p12 + p11.pending

    if not (v26 <= p13) and not (p11.elapsed < 0.25) and not (math.abs(p11.pending) < 0.05) then
        p11.endTime = v26
        p11.pending = 0
        p11.elapsed = 0

        return v26, true
    end

    return v26, false
end

function t1.scaleFor(p16) -- line: 239
    -- upvalues: t1 (copy), n1 (ref), isImmune (copy)
    if n1 == 0 or p16 == nil then
        return 1
    end

    local v27

    if p16:IsA("BasePart") then
        v27 = p16.Position
    elseif p16:IsA("Attachment") then
        v27 = p16.WorldPosition
    else
        if not p16:IsA("Model") then
            return 1
        end

        local PrimaryPart = p16.PrimaryPart

        v27 = if PrimaryPart then PrimaryPart.Position else p16:GetPivot().Position
    end

    local v28 = t1.scaleAt(v27)

    if v28 == 1 or not isImmune(p16) then
        return v28
    end

    return 1
end

local function sampleCount(p17, p18) -- line: 263
    return (math.clamp(math.max(p18 or 32, (math.ceil(p17 / 0.05))), 1, 256))
end

function t1.dilatedDuration(p19, p20, p21) -- line: 272
    -- upvalues: t1 (copy), n1 (ref)
    if n1 == 0 or p19 ~= p19 or p19 <= 0 then
        return p19
    end

    local v37 = math.clamp(math.max(p21 or 32, (math.ceil(p19 / 0.05))), 1, 256)
    local n3 = 0

    for i = 1, v37 do
        n3 += 1 / t1.scaleAt(p20((i - 0.5) / v37))
    end

    return p19 * n3 / v37
end

function t1.timeMap(p22, p23, p24) -- line: 291
    -- upvalues: t1 (copy), n1 (ref)
    if n1 == 0 or p22 ~= p22 or p22 <= 0 then
        return nil
    end

    local v42 = math.clamp(math.max(p24 or 32, (math.ceil(p22 / 0.05))), 1, 256)
    local v43 = table.create(v42 + 1, 0)
    local n4 = 0
    local v44 = false

    for i = 1, v42 do
        local v45 = t1.scaleAt(p23((i - 0.5) / v42))

        if v45 ~= 1 then
            v44 = true
        end

        n4 += 1 / v45
        v43[i + 1] = n4
    end

    if not v44 then
        return nil
    end

    local v46 = p22 / v42

    return function(p25) -- line: 318
        -- upvalues: v42 (copy), v43 (copy), v46 (copy)
        local v48 = math.clamp(p25 / v46, 0, v42)
        local v51 = math.min(math.floor(v48), v42 - 1)
        local v52 = v43[v51 + 1]

        return v46 * (v52 + (v43[v51 + 2] - v52) * (v48 - v51))
    end
end

return t1
