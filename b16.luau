--Таких скриптов там 2 а в общем 4 но 2 из них формата .spec в конце
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LinearPath = require(ReplicatedStorage.Shared.Modules.LinearPath)
local t1 = {
    DEBUG = false
}

function t1.Get(_, p2, p3, p4) -- line: 39
    -- upvalues: t1 (copy)
    local t2 = {}

    if t1.DEBUG then
        for i = 1, #p2 do
            local Part = Instance.new("Part")

            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(0.1, 0.7, 0.1)
            Part.Name = i
            Part.Position = p2[i]
            Part.Color = Color3.new(0, 1, 0)
            Part.Parent = workspace
        end
    end

    for i = 1, #p2 - 2, p4 do
        local v1 = math.floor(i)
        local v2 = i - v1
        local v3 = p2[v1]
        local v4 = p2[v1 + 1] or v3
        local v5 = p2[v1 + 2] or v4
        local v6 = p2[v1 + 3] or v5
        local v7 = (1 - p3) * (v6 - v4)
        local v8 = (1 - p3) * (v5 - v3)
        local v9 = v2 * v2
        local v10 = v9 * v2
        local v11 = v10 * 2 - v9 * 3 + 1
        local v12 = v10 - v9 * 2 + v2
        local v13 = v10 * -2 + v9 * 3
        local v14 = v10 - v9
        local v15 = v11 * v4 + v12 * v8 + v13 * v5 + v14 * v7

        if t1.DEBUG then
            local Part = Instance.new("Part")

            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(0.2, 0.5, 0.2)
            Part.Color = Color3.new(1, 0, 0)
            Part.Position = v15
            Part.Parent = workspace
        end

        table.insert(t2, v15)
    end

    return t2
end

function t1.ToLinearPath(_, p6, p7, p8) -- line: 98
    -- upvalues: LinearPath (copy), t1 (copy)
    return LinearPath.new(t1:Get(p6, p7, p8), true)
end

return t1
--И второй
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LinearPath = require(ReplicatedStorage.Resources.Universal.LinearPath)
local t1 = {
    DEBUG = false
}

function t1.Get(_, p2, p3, p4) -- line: 39
    -- upvalues: t1 (copy)
    local t2 = {}

    if t1.DEBUG then
        for i = 1, #p2 do
            local Part = Instance.new("Part")

            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(0.1, 0.7, 0.1)
            Part.Name = i
            Part.Position = p2[i]
            Part.Color = Color3.new(0, 1, 0)
            Part.Parent = workspace
        end
    end

    for i = 1, #p2 - 2, p4 do
        local v1 = math.floor(i)
        local v2 = i - v1
        local v3 = p2[v1]
        local v4 = p2[v1 + 1] or v3
        local v5 = p2[v1 + 2] or v4
        local v6 = p2[v1 + 3] or v5
        local v7 = (1 - p3) * (v6 - v4)
        local v8 = (1 - p3) * (v5 - v3)
        local v9 = v2 * v2
        local v10 = v9 * v2
        local v11 = v10 * 2 - v9 * 3 + 1
        local v12 = v10 - v9 * 2 + v2
        local v13 = v10 * -2 + v9 * 3
        local v14 = v10 - v9
        local v15 = v11 * v4 + v12 * v8 + v13 * v5 + v14 * v7

        if t1.DEBUG then
            local Part = Instance.new("Part")

            Part.Anchored = true
            Part.CanCollide = false
            Part.Size = Vector3.new(0.2, 0.5, 0.2)
            Part.Color = Color3.new(1, 0, 0)
            Part.Position = v15
            Part.Parent = workspace
        end

        table.insert(t2, v15)
    end

    return t2
end

function t1.ToLinearPath(_, p6, p7, p8) -- line: 98
    -- upvalues: LinearPath (copy), t1 (copy)
    return LinearPath.new(t1:Get(p6, p7, p8), true)
end

return t1
--Я кстати не могу терпеть и хочу сказать что я могу прямо сейчас удалить все содержимое ReplicatedStorage с целью чтобы загрузился плейс и с одним специальным методом я могу просмотреть СЕРВЕРНЫЕ СКРИПТЫ ПРЯМО В СТУДИИ
