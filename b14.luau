--2 Таких скрипта
-- https://lua.expert

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LinearValue = require(ReplicatedStorage.Client.Interfaces.Hooks.Utility.LinearValue)
local t1 = {}
local t3 = {
    _guids = {}
}
local t2 = {}

t2._identifiers = {
    "UDim2",
    "UDim",
    "Vector2",
    "Vector3",
    "Color3",
    "ColorSequenceKeypoint",
    "NumberSequenceKeypoint",
    "NumberRange",
    "PhysicalProperties",
    "BrickColor",
    "CFrame"
}
t2._types = {
    UDim2 = UDim2.new,
    UDim = UDim.new,
    Vector2 = Vector2.new,
    Vector3 = Vector3.new,
    Color3 = Color3.new,
    ColorSequenceKeypoint = ColorSequenceKeypoint.new,
    NumberSequenceKeypoint = NumberSequenceKeypoint.new,
    NumberRange = NumberRange.new,
    PhysicalProperties = PhysicalProperties.new,
    BrickColor = BrickColor.new,
    CFrame = CFrame.new
}

function t3.CreateRef(p1) -- line: 41
    -- upvalues: HttpService (copy), RunService (copy), t3 (copy)
    if t3._guids[p1] then
        return t3._guids[p1]
    end

    if RunService:IsClient() then
        return nil
    end

    local v1 = ("%*"):format((HttpService:GenerateGUID(false)))

    t3._guids[p1] = v1
    p1:AddTag(v1)
    p1.Destroying:Connect(function() -- line: 54
        -- upvalues: p1 (copy), t3 (copy)
        t3._guids[p1] = nil
    end)

    return v1
end

function t3.ResolveRef(p2, p3) -- line: 61
    -- upvalues: CollectionService (copy), t3 (copy)
    local v2 = CollectionService:GetTagged(p2)[1]
    local v3 = v2

    if not v2 and p3 ~= false then
        local v4

        v4 = task.delay(10, function() -- line: 66
            -- upvalues: p2 (copy), v4 (ref)
            warn((("Potential infinite yield on ResolveRef: %*"):format(p2)))
            v4 = nil
        end)
        v2 = CollectionService:GetInstanceAddedSignal(p2):Wait()
        v3 = v2

        if v4 then
            task.cancel(v4)
        end
    end

    if v2 then
        t3._guids[v2] = p2
        v2.Destroying:Connect(function() -- line: 81
            -- upvalues: v3 (ref), t3 (copy)
            t3._guids[v3] = nil
        end)
    end

    return v3
end

function t2.Serialize(p4) -- line: 89
    -- upvalues: LinearValue (copy), t2 (copy), t3 (copy)
    local t4 = {}

    for v6, v7 in p4 do
        local v8 = typeof(v7)

        if v8 == "Instance" then
            t4[v6] = "\002" .. t3.CreateRef(v7)
        elseif t2._types[v8] then
            local t5 = {}
            local v9 = table.find(t2._identifiers, v8)

            for _, v10 in LinearValue.fromValue(v7)._value do
                table.insert(t5, (tostring(v10)))
            end

            t4[v6] = "\003" .. string.char(v9) .. table.concat(t5, ",")
        elseif v8 == "table" then
            t4[v6] = t2.Serialize(v7)
        else
            t4[v6] = v7
        end
    end

    return t4
end

function t2.Deserialize(p5) -- line: 116
    -- upvalues: t2 (copy), t3 (copy)
    for v12, v13 in p5 do
        local v14 = typeof(v13)

        if v14 == "table" then
            t2.Deserialize(v13)
        elseif v14 == "string" then
            local v15 = string.byte(v13, 1)
            local v16 = string.sub(v13, 2)

            if v15 == 2 then
                p5[v12] = t3.ResolveRef(v16, false)
            elseif v15 == 3 then
                local v17 = string.sub(v13, 3)
                local v18 = t2._identifiers[string.byte(v13, 2)]
                local v19 = t2._types[v18]
                local t6 = {}

                for _, v20 in string.split(v17, ",") do
                    table.insert(t6, (tonumber(v20)))
                end

                p5[v12] = v19(unpack(t6))
            end
        end
    end

    return p5
end

function t1.Sanitize(p6) -- line: 147
    local t7 = {}

    for _, v22 in utf8.codes(p6) do
        local v23 = utf8.char(v22)

        if v22 < 128 and v23:match("^[%w_%.%-]$") then
            table.insert(t7, v23)
        else
            table.insert(t7, "_")
        end
    end

    return table.concat(t7)
end

function t1.Serialize(p7) -- line: 162
    -- upvalues: HttpService (copy), t2 (copy), t3 (copy)
    local v24 = typeof(p7)

    if v24 == "table" then
        return "\001" .. HttpService:JSONEncode((t2.Serialize(p7)))
    end

    if v24 ~= "Instance" then
        return p7
    end

    local v26 = t3.CreateRef(p7)

    if v26 then
        return "\002" .. v26
    end
end

function t1.Deserialize(p8) -- line: 179
    -- upvalues: HttpService (copy), t2 (copy), t3 (copy)
    if typeof(p8) ~= "string" then
        return p8
    end

    local v27 = p8:sub(1, 1)
    local v28 = p8:sub(2)

    if v27 == "\001" then
        local v29 = HttpService:JSONDecode(v28)

        return (t2.Deserialize(v29))
    end

    if v27 == "\002" then
        return t3.ResolveRef(v28, false)
    end

    return p8
end

return t1
--И
-- https://lua.expert

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LinearValue = require(ReplicatedStorage.Client.Interfaces.Hooks.Utility.LinearValue)
local t1 = {}
local t3 = {
    _guids = {}
}
local t2 = {}

t2._identifiers = {
    "UDim2",
    "UDim",
    "Vector2",
    "Vector3",
    "Color3",
    "ColorSequenceKeypoint",
    "NumberSequenceKeypoint",
    "NumberRange",
    "PhysicalProperties",
    "BrickColor",
    "CFrame"
}
t2._types = {
    UDim2 = UDim2.new,
    UDim = UDim.new,
    Vector2 = Vector2.new,
    Vector3 = Vector3.new,
    Color3 = Color3.new,
    ColorSequenceKeypoint = ColorSequenceKeypoint.new,
    NumberSequenceKeypoint = NumberSequenceKeypoint.new,
    NumberRange = NumberRange.new,
    PhysicalProperties = PhysicalProperties.new,
    BrickColor = BrickColor.new,
    CFrame = CFrame.new
}

function t3.CreateRef(p1) -- line: 41
    -- upvalues: HttpService (copy), RunService (copy), t3 (copy)
    if t3._guids[p1] then
        return t3._guids[p1]
    end

    if RunService:IsClient() then
        return nil
    end

    local v1 = ("%*"):format((HttpService:GenerateGUID(false)))

    t3._guids[p1] = v1
    p1:AddTag(v1)
    p1.Destroying:Connect(function() -- line: 54
        -- upvalues: p1 (copy), t3 (copy)
        t3._guids[p1] = nil
    end)

    return v1
end

function t3.ResolveRef(p2, p3) -- line: 61
    -- upvalues: CollectionService (copy), t3 (copy)
    local v2 = CollectionService:GetTagged(p2)[1]
    local v3 = v2

    if not v2 and p3 ~= false then
        local v4

        v4 = task.delay(10, function() -- line: 66
            -- upvalues: p2 (copy), v4 (ref)
            warn((("Potential infinite yield on ResolveRef: %*"):format(p2)))
            v4 = nil
        end)
        v2 = CollectionService:GetInstanceAddedSignal(p2):Wait()
        v3 = v2

        if v4 then
            task.cancel(v4)
        end
    end

    if v2 then
        t3._guids[v2] = p2
        v2.Destroying:Connect(function() -- line: 81
            -- upvalues: v3 (ref), t3 (copy)
            t3._guids[v3] = nil
        end)
    end

    return v3
end

function t2.Serialize(p4) -- line: 89
    -- upvalues: LinearValue (copy), t2 (copy), t3 (copy)
    local t4 = {}

    for v6, v7 in p4 do
        local v8 = typeof(v7)

        if v8 == "Instance" then
            t4[v6] = "\002" .. t3.CreateRef(v7)
        elseif t2._types[v8] then
            local t5 = {}
            local v9 = table.find(t2._identifiers, v8)

            for _, v10 in LinearValue.fromValue(v7)._value do
                table.insert(t5, (tostring(v10)))
            end

            t4[v6] = "\003" .. string.char(v9) .. table.concat(t5, ",")
        elseif v8 == "table" then
            t4[v6] = t2.Serialize(v7)
        else
            t4[v6] = v7
        end
    end

    return t4
end

function t2.Deserialize(p5) -- line: 116
    -- upvalues: t2 (copy), t3 (copy)
    for v12, v13 in p5 do
        local v14 = typeof(v13)

        if v14 == "table" then
            t2.Deserialize(v13)
        elseif v14 == "string" then
            local v15 = string.byte(v13, 1)
            local v16 = string.sub(v13, 2)

            if v15 == 2 then
                p5[v12] = t3.ResolveRef(v16, false)
            elseif v15 == 3 then
                local v17 = string.sub(v13, 3)
                local v18 = t2._identifiers[string.byte(v13, 2)]
                local v19 = t2._types[v18]
                local t6 = {}

                for _, v20 in string.split(v17, ",") do
                    table.insert(t6, (tonumber(v20)))
                end

                p5[v12] = v19(unpack(t6))
            end
        end
    end

    return p5
end

function t1.Sanetize(p6) -- line: 147
    return (p6:gsub("[^%w_]", "_"))
end

function t1.Serialize(p7) -- line: 152
    -- upvalues: HttpService (copy), t2 (copy), t3 (copy)
    local v22 = typeof(p7)

    if v22 == "table" then
        return "\001" .. HttpService:JSONEncode((t2.Serialize(p7)))
    end

    if v22 ~= "Instance" then
        return p7
    end

    local v24 = t3.CreateRef(p7)

    if v24 then
        return "\002" .. v24
    end
end

function t1.Deserialize(p8) -- line: 169
    -- upvalues: HttpService (copy), t2 (copy), t3 (copy)
    if typeof(p8) ~= "string" then
        return p8
    end

    local v25 = p8:sub(1, 1)
    local v26 = p8:sub(2)

    if v25 == "\001" then
        local v27 = HttpService:JSONDecode(v26)

        return (t2.Deserialize(v27))
    end

    if v25 == "\002" then
        return t3.ResolveRef(v26, false)
    end

    return p8
end

return t1
