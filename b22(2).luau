--TimeDilation
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t1 = {
    EFFECT_NAME = require(ReplicatedStorage.Shared.Modules.Enum).StatusEffect.TimeDilation,
    sanitizeScale = function(p1) -- sanitizeScale | line: 18
        if type(p1) == "number" and p1 == p1 and not (p1 <= 0) and p1 ~= 1e999 then
            return p1
        end

        return 1
    end
}

function t1.scaleCooldown(p2, p3) -- line: 28
    -- upvalues: t1 (copy)
    return p2 / t1.sanitizeScale(p3)
end

function t1.scaleSpeed(p4, p5) -- line: 32
    -- upvalues: t1 (copy)
    return p4 * t1.sanitizeScale(p5)
end

function t1.rescaleCooldown(p6, p7, p8, p9, p10) -- line: 37
    -- upvalues: t1 (copy)
    return p6 + math.max(p7 - p6, 0) * (t1.sanitizeScale(p9) / t1.sanitizeScale(p10)), t1.scaleCooldown(p8, p10)
end

function t1.rescaleLifetime(p11, p12, p13, p14, p15) -- line: 51
    -- upvalues: t1 (copy)
    local v2 = t1.sanitizeScale(p14) / t1.sanitizeScale(p15)

    if v2 ~= 1 and type(p13) == "number" and p13 > 0 and not (p13 <= p11 - p12) then
        return p11 - (p11 - p12) * v2, p13 * v2
    end

    return p12, p13
end

function t1.queueAnchor(p16, p17, p18) -- line: 66
    -- upvalues: t1 (copy)
    return p16 - t1.scaleCooldown(p17, p18)
end

local function beats(p19, p20) -- line: 70
    if p19.level ~= p20.level then
        return p19.level > p20.level
    end

    if p19.placedAt ~= p20.placedAt then
        return p19.placedAt < p20.placedAt
    end

    return tostring(p19.id) < tostring(p20.id)
end

function t1.pickWinner(p21) -- line: 80
    local v4

    for _, v5 in p21 do
        if v4 ~= nil then
            local v6 = if v5.level ~= v4.level then v5.level > v4.level elseif v5.placedAt == v4.placedAt then tostring(v5.id) < tostring(v4.id) else v5.placedAt < v4.placedAt

            if v6 then
                v4 = v5
            end
        else
            v4 = v5
        end
    end

    return v4
end

return t1
