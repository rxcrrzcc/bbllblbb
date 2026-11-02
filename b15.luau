--PathReplicator
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")

game:GetService("UserInputService")

local t1 = {}
local NPCReplicator = require(script.Parent.NPCReplicator)
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)

require(ReplicatedStorage.Shared.Modules.SharedGameFunctions)
require(ReplicatedStorage.Client.Modules.TagReplicator)

local HermiteCardinalSpline = require(ReplicatedStorage.Shared.Modules.HermiteCardinalSpline)

require(ReplicatedStorage.Shared.Modules.LinearPath)

local MapManager = require(ReplicatedStorage.Shared.Modules.MapManager)
local Network = require(ReplicatedStorage.Shared.Modules.Network)

require(ReplicatedStorage.Client.Controllers.Shared.SettingsController)

local StatePaths = Network.Channel("StatePaths")

local function update(p1) -- line: 60
    -- upvalues: NPCReplicator (copy), GameState (copy), HermiteCardinalSpline (copy)
    local v1 = GameState.Paths or {}

    GameState.Paths = {}

    for v2, v3 in p1 do
        GameState.Paths[v2] = {}

        for v4, v5 in v3 do
            local v6 = HermiteCardinalSpline:ToLinearPath(v5, 0.5, 0.2)

            GameState.Paths[v2][tonumber(v4) or v4] = v6
        end
    end

    for v7, v8 in v1 do
        local v9 = GameState.Paths[v7]

        if v9 then
            for v10, v11 in v8 do
                local v12 = v9[v10]

                if v12 and v12 ~= v11 then
                    NPCReplicator.RefreshAllNPCsByPath(v11, nil, true)
                end
            end
        end
    end
end

local function refresh() -- line: 87
    -- upvalues: StatePaths (copy), update (copy)
    local RequestPaths = StatePaths:InvokeServer("RequestPaths")
    local t2 = {}

    for v13, v14 in RequestPaths do
        t2[tonumber(v13) or v13] = v14
    end

    update(RequestPaths)
end

local function refreshAsync() -- line: 99
    -- upvalues: refresh (copy)
    task.spawn(function() -- line: 100
        -- upvalues: refresh (copy)
        local ok, result = pcall(refresh)

        if not ok then
            warn((("Failed to refresh paths: %*"):format(result)))
        end
    end)
end

MapManager.MapChanged:Connect(refreshAsync)
StatePaths:On("UpdatePaths", update)
StatePaths:On("UpdatePath", function(p2, p3, p4, p5) -- line: 116
    -- upvalues: NPCReplicator (copy), GameState (copy), HermiteCardinalSpline (copy)
    if not GameState.Paths[p2] then
        GameState.Paths[p2] = {}
    end

    local v15 = GameState.Paths[p2][tonumber(p3) or p3]
    local v16 = HermiteCardinalSpline:ToLinearPath(p4, 0.5, 0.2)

    GameState.Paths[p2][tonumber(p3) or p3] = v16
    NPCReplicator.RefreshAllNPCsByPath(v15, p5)
end)

if MapManager.GetLoadedMapRaw() then
    task.spawn(function() -- line: 100
        -- upvalues: refresh (copy)
        local ok, result = pcall(refresh)

        if not ok then
            warn((("Failed to refresh paths: %*"):format(result)))
        end
    end)
end

return t1
