--Тут так же 2 таких скрипта поэтому я напишу их оба
-- https://lua.expert

local t1 = {}

local function getEmitters(p1) -- line: 3
    if typeof(p1) == "table" then
        return p1
    end

    local t2 = {}

    if p1:IsA("ParticleEmitter") then
        table.insert(t2, p1)
    elseif p1:IsA("Beam") then
        table.insert(t2, p1)
    elseif p1:IsA("Trail") then
        table.insert(t2, p1)
    end

    local Descendants = p1:GetDescendants()

    if #Descendants > 0 then
        for _, v1 in pairs(Descendants) do
            if v1:IsA("ParticleEmitter") then
                table.insert(t2, v1)
            end
        end
    end

    return t2
end

local t3 = {}

function t1.scaleEmitter(_, p3, p4, p5) -- line: 28
    -- upvalues: getEmitters (copy), t3 (copy)
    local v2 = getEmitters(p3)
    local t4 = {
        ParticleEmitter = {
            Size = "Size",
            Speed = "Speed",
            Acceleration = "Acceleration"
        },
        Beam = {
            Width0 = "Width0",
            Width1 = "Width1",
            CurveSize0 = "CurveSize0",
            CurveSize1 = "CurveSize1"
        },
        Trail = {}
    }
    local t5 = {
        NumberSequence = function(p6, p7) -- line: 54
            local t6 = {}

            for v3, v4 in p6.Keypoints do
                t6[v3] = NumberSequenceKeypoint.new(v4.Time, v4.Value * p7, v4.Envelope * p7)
            end

            return NumberSequence.new(t6)
        end,
        NumberRange = function(p8, p9) -- line: 67
            return NumberRange.new(p8.Min * p9, p8.Max * p9)
        end,
        number = function(p10, p11) -- line: 71
            return p10 * p11
        end,
        Vector3 = function(p12, p13) -- line: 75
            return (Vector3.new(p12.X * p13, p12.Y * p13, p12.Z * p13))
        end
    }

    for _, v8 in pairs(v2) do
        local v9 = t4[v8.ClassName]

        if p5 and not t3[v8] then
            t3[v8] = {}

            for v10, _ in pairs(v9) do
                t3[v8][v10] = v8[v10]
            end
        end

        for v11, _ in pairs(v9) do
            local v12 = v8[v11]
            local v13 = t5[typeof(v12)]

            if p5 then
                v12 = t3[v8][v11]
            end

            local v14 = v13(v12, p4)

            if v14 then
                v8[v11] = v14
            end
        end
    end
end

function t1.retimeEmitter(_, p15, p16) -- line: 103
    -- upvalues: getEmitters (copy)
    local v15 = getEmitters(p15)
    local t7 = {
        ParticleEmitter = {
            Lifetime = "Lifetime",
            Speed = "Speed",
            Drag = "Drag",
            Acceleration = "Acceleration",
            Rate = "Rate",
            FlipbookFramerate = "FlipbookFramerate",
            RotSpeed = "RotSpeed"
        },
        Beam = {
            Lifetime = "TextureSpeed"
        },
        Trail = {
            Lifetime = "Lifetime"
        }
    }
    local t9 = { "Lifetime", "Rate", "Acceleration" }
    local t8 = {
        NumberRange = function(p17, p18, p19) -- line: 129
            -- upvalues: t9 (copy)
            local v16 = if table.find(t9, p19) then 1 / p18 else p18

            return NumberRange.new(p17.Min * v16, p17.Max * v16)
        end,
        number = function(p20, p21) -- line: 137
            return p20 * p21
        end,
        Vector3 = function(p22, p23) -- line: 141
            return (Vector3.new(p22.X * p23, p22.Y * p23, p22.Z * p23))
        end
    }

    for _, v20 in pairs(v15) do
        local v21 = t7[v20.ClassName]

        for _, v22 in pairs(v21) do
            local v23 = v20[v22]

            if not t8[typeof(v23)] then
                warn(typeof(v23), "missing in re-time, please report this to the Developers.")
            end

            local v24 = t8[typeof(v23)](v23, p16, v22)

            if v20[v22] then
                v20[v22] = v24
            else
                warn(v22, "missing in re-time, please report this to the Devlopers.")
            end
        end

        local EmitDelay = v20:GetAttribute("EmitDelay")

        if EmitDelay then
            v20:SetAttribute("EmitDelay", EmitDelay * (1 / p16))
        end
    end
end

function t1.toggleEmitter(p24, p25) -- line: 168
    -- upvalues: getEmitters (copy)
    local v25 = getEmitters(p24)

    for _, v26 in pairs(v25) do
        v26.Enabled = p25
    end
end

local function sampleNumberSequence(p26, p27) -- line: 176
    local Keypoints = p26.Keypoints

    for i = 1, #Keypoints - 1 do
        local v27 = Keypoints[i]
        local v28 = Keypoints[i + 1]

        if v27.Time <= p27 and p27 <= v28.Time then
            local v29 = (p27 - v27.Time) / (v28.Time - v27.Time)

            return v27.Value + (v28.Value - v27.Value) * v29
        end
    end

    return Keypoints[#Keypoints].Value
end

local function sampleColorSequence(p28, p29) -- line: 190
    local Keypoints = p28.Keypoints

    for i = 1, #Keypoints - 1 do
        local v30 = Keypoints[i]
        local v31 = Keypoints[i + 1]

        if v30.Time <= p29 and p29 <= v31.Time then
            local v32 = (p29 - v30.Time) / (v31.Time - v30.Time)

            return v30.Value:Lerp(v31.Value, v32)
        end
    end

    return Keypoints[#Keypoints].Value
end

function t1.averageNumberSequence(p30, p31, p32) -- line: 208
    -- upvalues: sampleNumberSequence (copy)
    local t10 = {}
    local t11 = {}

    for _, v33 in p30.Keypoints do
        if not t11[v33.Time] then
            t11[v33.Time] = true
            table.insert(t10, v33.Time)
        end
    end

    for _, v34 in p31.Keypoints do
        if not t11[v34.Time] then
            t11[v34.Time] = true
            table.insert(t10, v34.Time)
        end
    end

    table.sort(t10)

    if #t10 > 20 then
        t10 = {}
        t10[1] = 0
        t10[2] = 0.05263157894736842
        t10[3] = 0.10526315789473684
        t10[4] = 0.15789473684210525
        t10[5] = 0.21052631578947367
        t10[6] = 0.2631578947368421
        t10[7] = 0.3157894736842105
        t10[8] = 0.3684210526315789
        t10[9] = 0.42105263157894735
        t10[10] = 0.47368421052631576
        t10[11] = 0.5263157894736842
        t10[12] = 0.5789473684210527
        t10[13] = 0.631578947368421
        t10[14] = 0.6842105263157895
        t10[15] = 0.7368421052631579
        t10[16] = 0.7894736842105263
        t10[17] = 0.8421052631578947
        t10[18] = 0.8947368421052632
        t10[19] = 0.9473684210526315
        t10[20] = 1
    end

    if t10[1] ~= 0 then
        table.insert(t10, 1, 0)
    end

    if t10[#t10] ~= 1 then
        table.insert(t10, 1)
    end

    if #t10 > 20 then
        while #t10 > 20 do
            table.remove(t10, (math.ceil(#t10 / 2)))
        end
    end

    local t12 = {}

    for _, v36 in t10 do
        local v37 = sampleNumberSequence(p30, v36)
        local v38 = sampleNumberSequence(p31, v36)

        t12[#t12 + 1] = NumberSequenceKeypoint.new(v36, v37 + (v38 - v37) * p32, 0)
    end

    return NumberSequence.new(t12)
end

function t1.averageColorSequence(p33, p34, p35) -- line: 262
    -- upvalues: sampleColorSequence (copy)
    local t13 = {}
    local t14 = {}

    for _, v39 in p33.Keypoints do
        if not t14[v39.Time] then
            t14[v39.Time] = true
            table.insert(t13, v39.Time)
        end
    end

    for _, v40 in p34.Keypoints do
        if not t14[v40.Time] then
            t14[v40.Time] = true
            table.insert(t13, v40.Time)
        end
    end

    table.sort(t13)

    if #t13 > 20 then
        t13 = {}
        t13[1] = 0
        t13[2] = 0.05263157894736842
        t13[3] = 0.10526315789473684
        t13[4] = 0.15789473684210525
        t13[5] = 0.21052631578947367
        t13[6] = 0.2631578947368421
        t13[7] = 0.3157894736842105
        t13[8] = 0.3684210526315789
        t13[9] = 0.42105263157894735
        t13[10] = 0.47368421052631576
        t13[11] = 0.5263157894736842
        t13[12] = 0.5789473684210527
        t13[13] = 0.631578947368421
        t13[14] = 0.6842105263157895
        t13[15] = 0.7368421052631579
        t13[16] = 0.7894736842105263
        t13[17] = 0.8421052631578947
        t13[18] = 0.8947368421052632
        t13[19] = 0.9473684210526315
        t13[20] = 1
    end

    if t13[1] ~= 0 then
        table.insert(t13, 1, 0)
    end

    if t13[#t13] ~= 1 then
        table.insert(t13, 1)
    end

    if #t13 > 20 then
        while #t13 > 20 do
            table.remove(t13, (math.ceil(#t13 / 2)))
        end
    end

    local t15 = {}

    for _, v42 in t13 do
        local v43 = sampleColorSequence(p33, v42)
        local v44 = sampleColorSequence(p34, v42)

        t15[#t15 + 1] = ColorSequenceKeypoint.new(v42, v43:Lerp(v44, p35))
    end

    return ColorSequence.new(t15)
end

return t1
--И второй
  -- https://lua.expert

local t1 = {}

local function getEmitters(p1) -- line: 3
    if typeof(p1) == "table" then
        return p1
    end

    local t2 = {}

    if p1:IsA("ParticleEmitter") then
        table.insert(t2, p1)
    elseif p1:IsA("Beam") then
        table.insert(t2, p1)
    elseif p1:IsA("Trail") then
        table.insert(t2, p1)
    end

    local Descendants = p1:GetDescendants()

    if #Descendants > 0 then
        for _, v1 in pairs(Descendants) do
            if v1:IsA("ParticleEmitter") then
                table.insert(t2, v1)
            end
        end
    end

    return t2
end

local t3 = {}

function t1.scaleEmitter(_, p3, p4, p5) -- line: 28
    -- upvalues: getEmitters (copy), t3 (copy)
    local v2 = getEmitters(p3)
    local t4 = {
        ParticleEmitter = {
            Size = "Size",
            Speed = "Speed",
            Acceleration = "Acceleration"
        },
        Beam = {
            Width0 = "Width0",
            Width1 = "Width1",
            CurveSize0 = "CurveSize0",
            CurveSize1 = "CurveSize1"
        },
        Trail = {}
    }
    local t5 = {
        NumberSequence = function(p6, p7) -- line: 54
            local t6 = {}

            for v3, v4 in p6.Keypoints do
                t6[v3] = NumberSequenceKeypoint.new(v4.Time, v4.Value * p7, v4.Envelope * p7)
            end

            return NumberSequence.new(t6)
        end,
        NumberRange = function(p8, p9) -- line: 67
            return NumberRange.new(p8.Min * p9, p8.Max * p9)
        end,
        number = function(p10, p11) -- line: 71
            return p10 * p11
        end,
        Vector3 = function(p12, p13) -- line: 75
            return (Vector3.new(p12.X * p13, p12.Y * p13, p12.Z * p13))
        end
    }

    for _, v8 in pairs(v2) do
        local v9 = t4[v8.ClassName]

        if p5 and not t3[v8] then
            t3[v8] = {}

            for v10, _ in pairs(v9) do
                t3[v8][v10] = v8[v10]
            end
        end

        for v11, _ in pairs(v9) do
            local v12 = v8[v11]
            local v13 = t5[typeof(v12)]

            if p5 then
                v12 = t3[v8][v11]
            end

            local v14 = v13(v12, p4)

            if v14 then
                v8[v11] = v14
            end
        end
    end
end

function t1.retimeEmitter(_, p15, p16) -- line: 103
    -- upvalues: getEmitters (copy)
    local v15 = getEmitters(p15)
    local t7 = {
        ParticleEmitter = {
            Lifetime = "Lifetime",
            Speed = "Speed",
            Drag = "Drag",
            Acceleration = "Acceleration",
            Rate = "Rate",
            FlipbookFramerate = "FlipbookFramerate",
            RotSpeed = "RotSpeed"
        },
        Beam = {
            Lifetime = "TextureSpeed"
        },
        Trail = {
            Lifetime = "Lifetime"
        }
    }
    local t9 = { "Lifetime", "Rate", "Acceleration" }
    local t8 = {
        NumberRange = function(p17, p18, p19) -- line: 129
            -- upvalues: t9 (copy)
            local v16 = if table.find(t9, p19) then 1 / p18 else p18

            return NumberRange.new(p17.Min * v16, p17.Max * v16)
        end,
        number = function(p20, p21) -- line: 137
            return p20 * p21
        end,
        Vector3 = function(p22, p23) -- line: 141
            return (Vector3.new(p22.X * p23, p22.Y * p23, p22.Z * p23))
        end
    }

    for _, v20 in pairs(v15) do
        local v21 = t7[v20.ClassName]

        for _, v22 in pairs(v21) do
            local v23 = v20[v22]

            if not t8[typeof(v23)] then
                warn(typeof(v23), "missing in re-time, please report this to the Developers.")
            end

            local v24 = t8[typeof(v23)](v23, p16, v22)

            if v20[v22] then
                v20[v22] = v24
            else
                warn(v22, "missing in re-time, please report this to the Devlopers.")
            end
        end

        local EmitDelay = v20:GetAttribute("EmitDelay")

        if EmitDelay then
            v20:SetAttribute("EmitDelay", EmitDelay * (1 / p16))
        end
    end
end

function t1.toggleEmitter(p24, p25) -- line: 168
    -- upvalues: getEmitters (copy)
    local v25 = getEmitters(p24)

    for _, v26 in pairs(v25) do
        v26.Enabled = p25
    end
end

return t1
