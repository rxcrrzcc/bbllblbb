-- https://lua.expert

local t1 = {}

t1.__index = t1
t1.LOW_QUALITY_MODE = false

local function round(p1, p2) -- line: 40
    local v1 = 10 ^ (p2 or 0)

    return math.floor(p1 * v1 + 0.5) / v1
end

function t1.new(p3, p4) -- line: 93
    -- upvalues: t1 (copy)
    local self = setmetatable({}, t1)

    self.ShouldCache = p4 or false
    self.PathCache = {}
    self.NormalCache = {}
    self.StartPointCache = {}
    self.EndPointCache = {}
    self:SetPoints(p3)

    return self
end

function t1:SetPoints(p6) -- line: 117
    assert(#p6 > 0, "LinearPath:SetPoints: No waypoints provided.")
    self.Points = p6
    self.Distances = table.create(#p6)
    self.FullDistances = table.create(#p6)
    self.Normals = table.create(#p6)
    self.PathDistance = 0
    self.PathCache = {}
    self.NormalCache = {}
    self.StartPointCache = {}
    self.EndPointCache = {}

    for i = 2, #p6 do
        local Magnitude = (p6[i] - p6[i - 1]).Magnitude

        self.Distances[i] = Magnitude
        self.PathDistance += Magnitude
        self.FullDistances[i] = self.PathDistance
    end

    for i = 1, #p6 do
        local v5 = p6[i]
        local v6 = i == #p6
        local v7 = if v6 then i - 1 else nil
        local v8 = (v5 - p6[if not v6 or not v7 then i + 1 else v7]).Unit:Cross((Vector3.new(0, 1, 0)))

        self.Normals[i] = v8
    end
end

function t1:_FindSegment(p8) -- line: 156
    if p8 <= 0 then
        return 2, 0
    end

    if self.PathDistance <= p8 then
        return #self.Points, 1
    end

    local v9 = 2
    local v10 = #self.Points

    while v9 <= v10 do
        local v12 = math.floor((v9 + v10) / 2)
        local v13 = self.FullDistances[v12]

        if v13 == nil then
            v13 = 0
        end

        if v13 < p8 then
            v9 = v12 + 1
        else
            v10 = v12 - 1
        end
    end

    local v15 = math.clamp(v9, 2, #self.Points)
    local v16 = self.FullDistances[v15 - 1] or 0
    local v17 = self.Distances[v15]

    return v15, (math.clamp(if v17 > 0 then (p8 - v16) / v17 else 0, 0, 1))
end

t1._FindSegment = t1._FindSegment

function t1:Get(p10) -- line: 208
    local v19 = math.clamp(p10, 0, 1)
    local ShouldCache = self.ShouldCache
    local v20, v21

    if ShouldCache then
        v20 = math.floor(v19 * 1000 + 0.5) / 1000
        v21 = self.PathCache[v20]
    end

    if ShouldCache and v21 then
        return self.PathCache[v20]
    end

    if not ShouldCache then
        v20 = v19
    end

    local v23 = v20 * #self.Points
    local v25 = math.floor(v23 - 1)

    if v23 <= 0 then
        return self.Points[1]
    end

    if #self.Points <= v23 then
        return self.Points[#self.Points]
    end

    local v29 = self.Points[v25 + 1]:Lerp(self.Points[math.clamp(v25 + 2, 1, #self.Points)], v23 - v25)

    if self.ShouldCache then
        self.PathCache[v20] = v29
    end

    return v29
end

function t1:GetDistanceToEnd(p12) -- line: 240
    return self.PathDistance - p12
end

function t1:GetScalar(p14, p15) -- line: 254
    -- upvalues: t1 (copy)
    p15 = p15 or 0

    local v31 = math.clamp(p14, 0, self.PathDistance)

    if v31 <= 0 then
        return self.Points[1] + self.Normals[1] * p15, false
    end

    if self.PathDistance <= v31 then
        return self.Points[#self.Points] + self.Normals[#self.Points] * p15, true
    end

    local v32

    if self.ShouldCache then
        local v33 = 10 ^ ((if t1.LOW_QUALITY_MODE then 1 else 3) or 0)
        local v35 = math.floor(v31 * v33 + 0.5) / v33
        local v36 = self.PathCache[v35]

        if v36 then
            local v37 = self.NormalCache[v35]
            local v38 = self.StartPointCache[v35]
            local v39 = self.EndPointCache[v35]

            return v36 + v37 * p15, self.PathDistance <= v35, v38, v39
        end

        v32 = v35
    end

    local v40, v41 = self:_FindSegment(v31)
    local v42 = v40 - 1
    local v43 = self.Points[v42]
    local v44 = self.Points[v40]
    local v45 = self.Normals[v42]:Lerp(self.Normals[v40], v41)
    local v46 = v43:Lerp(v44, v41)

    if self.ShouldCache and v32 ~= nil then
        self.PathCache[v32] = v46
        self.NormalCache[v32] = v45
        self.StartPointCache[v32] = v43
        self.EndPointCache[v32] = v44
    end

    return v46 + v45 * p15, false, v43, v44
end

function t1:GetClosestPoint(p17) -- line: 315
    local v47 = #self.Points - 1
    local n1 = 1e999
    local n2 = 1
    local v48

    for i = 1, v47 do
        local v49 = self.Points[i]
        local v50 = self.Points[i + 1]
        local Unit = (v50 - v49).Unit
        local v52 = math.clamp((v49 + Unit * (p17 - v49):Dot(Unit) - v49).Magnitude / (v50 - v49).Magnitude, 0, 1)
        local v53 = v49 + (v50 - v49) * v52
        local Magnitude = (p17 - v53).Magnitude

        if Magnitude < n1 then
            n2 = i
            v48 = v53
            n1 = Magnitude
        end
    end

    local v54 = n2 + 1
    local n3 = 0

    for i = 2, v54 do
        n3 += self.Distances[i]
    end

    return v48, self:GetDistanceToEnd(n3)
end

return t1
--И второй
        -- https://lua.expert

local t1 = {}

t1.__index = t1
t1.LOW_QUALITY_MODE = false

local function round(p1, p2) -- line: 40
    local v1 = 10 ^ (p2 or 0)

    return math.floor(p1 * v1 + 0.5) / v1
end

function t1.new(p3, p4) -- line: 93
    -- upvalues: t1 (copy)
    local self = setmetatable({}, t1)

    self.ShouldCache = p4 or false
    self.PathCache = {}
    self.NormalCache = {}
    self.StartPointCache = {}
    self.EndPointCache = {}
    self:SetPoints(p3)

    return self
end

function t1:SetPoints(p6) -- line: 117
    assert(#p6 > 0, "LinearPath:SetPoints: No waypoints provided.")
    self.Points = p6
    self.Distances = table.create(#p6)
    self.FullDistances = table.create(#p6)
    self.Normals = table.create(#p6)
    self.PathDistance = 0
    self.PathCache = {}
    self.NormalCache = {}
    self.StartPointCache = {}
    self.EndPointCache = {}

    for i = 2, #p6 do
        local Magnitude = (p6[i] - p6[i - 1]).Magnitude

        self.Distances[i] = Magnitude
        self.PathDistance += Magnitude
        self.FullDistances[i] = self.PathDistance
    end

    for i = 1, #p6 do
        local v5 = p6[i]
        local v6 = i == #p6
        local v7 = if v6 then i - 1 else nil
        local v8 = (v5 - p6[if not v6 or not v7 then i + 1 else v7]).Unit:Cross((Vector3.new(0, 1, 0)))

        self.Normals[i] = v8
    end
end

function t1:_FindSegment(p8) -- line: 155
    if p8 <= 0 then
        return 2, 0
    end

    if self.PathDistance <= p8 then
        return #self.Points, 1
    end

    local v9 = 2
    local v10 = #self.Points

    while v9 <= v10 do
        local v12 = math.floor((v9 + v10) / 2)
        local v13 = self.FullDistances[v12]

        if v13 == nil then
            v13 = 0
        end

        if v13 < p8 then
            v9 = v12 + 1
        else
            v10 = v12 - 1
        end
    end

    local v15 = math.clamp(v9, 2, #self.Points)
    local v16 = self.FullDistances[v15 - 1] or 0
    local v17 = self.Distances[v15]

    return v15, (math.clamp(if v17 > 0 then (p8 - v16) / v17 else 0, 0, 1))
end

t1._FindSegment = t1._FindSegment

function t1:Get(p10) -- line: 207
    local v19 = math.clamp(p10, 0, 1)
    local ShouldCache = self.ShouldCache
    local v20, v21

    if ShouldCache then
        v20 = math.floor(v19 * 1000 + 0.5) / 1000
        v21 = self.PathCache[v20]
    end

    if ShouldCache and v21 then
        return self.PathCache[v20]
    end

    if not ShouldCache then
        v20 = v19
    end

    local v23 = v20 * #self.Points
    local v25 = math.floor(v23 - 1)

    if v23 <= 0 then
        return self.Points[1]
    end

    if #self.Points <= v23 then
        return self.Points[#self.Points]
    end

    local v29 = self.Points[v25 + 1]:Lerp(self.Points[math.clamp(v25 + 2, 1, #self.Points)], v23 - v25)

    if self.ShouldCache then
        self.PathCache[v20] = v29
    end

    return v29
end

function t1:GetDistanceToEnd(p12) -- line: 239
    return self.PathDistance - p12
end

function t1:GetScalar(p14, p15) -- line: 253
    -- upvalues: t1 (copy)
    p15 = p15 or 0

    local v31 = math.clamp(p14, 0, self.PathDistance)

    if v31 <= 0 then
        return self.Points[1] + self.Normals[1] * p15, false
    end

    if self.PathDistance <= v31 then
        return self.Points[#self.Points] + self.Normals[#self.Points] * p15, true
    end

    local v32

    if self.ShouldCache then
        local v33 = 10 ^ ((if t1.LOW_QUALITY_MODE then 1 else 3) or 0)
        local v35 = math.floor(v31 * v33 + 0.5) / v33
        local v36 = self.PathCache[v35]

        if v36 then
            local v37 = self.NormalCache[v35]
            local v38 = self.StartPointCache[v35]
            local v39 = self.EndPointCache[v35]

            return v36 + v37 * p15, self.PathDistance <= v35, v38, v39
        end

        v32 = v35
    end

    local v40, v41 = self:_FindSegment(v31)
    local v42 = v40 - 1
    local v43 = self.Points[v42]
    local v44 = self.Points[v40]
    local v45 = self.Normals[v42]:Lerp(self.Normals[v40], v41)
    local v46 = v43:Lerp(v44, v41)

    if self.ShouldCache and v32 ~= nil then
        self.PathCache[v32] = v46
        self.NormalCache[v32] = v45
        self.StartPointCache[v32] = v43
        self.EndPointCache[v32] = v44
    end

    return v46 + v45 * p15, false, v43, v44
end

function t1:GetClosestPoint(p17) -- line: 314
    local v47 = #self.Points - 1
    local n1 = 1e999
    local n2 = 1
    local v48

    for i = 1, v47 do
        local v49 = self.Points[i]
        local v50 = self.Points[i + 1]
        local Unit = (v50 - v49).Unit
        local v52 = math.clamp((v49 + Unit * (p17 - v49):Dot(Unit) - v49).Magnitude / (v50 - v49).Magnitude, 0, 1)
        local v53 = v49 + (v50 - v49) * v52
        local Magnitude = (p17 - v53).Magnitude

        if Magnitude < n1 then
            n2 = i
            v48 = v53
            n1 = Magnitude
        end
    end

    local v54 = n2 + 1
    local n3 = 0

    for i = 2, v54 do
        n3 += self.Distances[i]
    end

    return v48, self:GetDistanceToEnd(n3)
end

return t1
