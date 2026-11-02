--Самый маленький модуль
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TagObserver = require(ReplicatedStorage.Shared.Modules.TagObserver)
local Assets = ReplicatedStorage:WaitForChild("Assets")

for v1, v2 in {
        Tower = "Troops",
        Unit = "Units",
        Enemy = "NewEnemies",
        LegacyEnemy = "Enemies"
    } do
    local v3 = Assets:FindFirstChild(v2)
    local v4 = v3
    local v5 = v1 == "Enemy" or v1 == "LegacyEnemy"

    if not v3 then
        local Folder = Instance.new("Folder")

        v4 = Folder
        Folder.Name = v2
        Folder.Parent = Assets
    end

    TagObserver(("%*_STREAM"):format((string.upper(v1))), function(p1) -- line: 24
        -- upvalues: v4 (ref), v5 (copy)
        if v5 then
            p1.Name = p1.Parent.Parent.Name
        end

        p1.Parent = v4

        return function() -- line: 30
        end
    end)
end

return nil
