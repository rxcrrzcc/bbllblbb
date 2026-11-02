--Profiler находился буквально в Sheduler
-- https://lua.expert

local t1 = {}

local function getProfile(p1, p2) -- line: 17
    -- upvalues: t1 (copy)
    return t1[p2] and t1[p2][p1]
end

local function updateProfile(p3, p4, p5) -- line: 21
    -- upvalues: t1 (copy)
    local v1 = t1[p4]

    if not v1 then
        v1 = {}
        t1[p4] = v1
    end

    local v2 = v1[p3]

    if not v2 then
        v2 = {
            average = 0,
            count = 0,
            index = 1,
            sum = 0,
            deltas = {}
        }
        v1[p3] = v2
    end

    local index = v2.index
    local v3 = v2.deltas[index]

    if v3 then
        v2.sum -= v3
    else
        v2.count += 1
    end

    v2.deltas[index] = p5
    v2.sum += p5
    v2.index = index % 10 + 1
    v2.average = v2.sum / v2.count

    return v2
end

return {
    profiles = t1,
    getProfile = getProfile,
    updateProfile = updateProfile,
    removeProfile = function(p6, p7) -- removeProfile | line: 56
        -- upvalues: t1 (copy)
        local v4 = t1[p7]

        if v4 then
            v4[p6] = nil
        end
    end
}
