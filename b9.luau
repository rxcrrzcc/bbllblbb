--Снова два таких же скрипта
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)

local function resumeThread(p1, p2) -- line: 14
    local v1, v2 = coroutine.resume(p2)

    if v1 then
        return
    end

    warn("[NPC] coroutine resume failed for", p1.Name, v2)
    p1._threadCo = nil
    p1._threadDelayRemaining = 0.1
end

local function stepThread(p3, p4) -- line: 23
    -- upvalues: TimescaleUtilities (copy)
    if p3.ThreadFunction then
        p3._threadDelayRemaining = (p3._threadDelayRemaining or 0) - p4

        local n1 = 16
        local v3 = false

        while (p3._threadDelayRemaining or 0) <= 0 and n1 > 0 do
            local v4 = n1 - 1
            local _threadCo = p3._threadCo
            local v5

            if (_threadCo and coroutine.status(_threadCo) or "dead") == "suspended" then
                v5 = v3

                local v6, v7 = coroutine.resume(_threadCo)

                if not v6 then
                    warn("[NPC] coroutine resume failed for", p3.Name, v7)
                    p3._threadCo = nil
                    p3._threadDelayRemaining = 0.1
                end
            elseif v3 then
                break
            else
                local v8 = coroutine.create(function() -- line: 53
                    -- upvalues: p3 (copy)
                    local ThreadFunction = p3.ThreadFunction
                    local traceback = debug.traceback
                    local v9, v10 = xpcall(ThreadFunction, traceback, p3)

                    if not v9 then
                        warn("[NPC] ThreadFunction error for", p3.Name, v10)
                    end
                end)

                p3._threadCo = v8
                TimescaleUtilities._registerNPCThread(v8, p3)

                local v11, v12 = coroutine.resume(v8)

                if not v11 then
                    warn("[NPC] coroutine resume failed for", p3.Name, v12)
                    p3._threadCo = nil
                    p3._threadDelayRemaining = 0.1
                end

                if coroutine.status(v8) == "dead" then
                    p3._threadDelayRemaining = 0
                end

                v5 = true
            end

            v3 = v5
            n1 = v4
        end
    end
end

local function configureModelBasePart(p5) -- line: 79
    p5.CanCollide = false

    if p5.Transparency < 0.99 then
        p5.CanQuery = true
    end
end

local function configureModelBaseParts(p6) -- line: 87
    for _, descendant in p6:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false

            if descendant.Transparency < 0.99 then
                descendant.CanQuery = true
            end
        end
    end
end

return {
    configureModelParts = function(p7) -- configureModelParts | line: 95
        -- upvalues: configureModelBaseParts (copy)
        configureModelBaseParts(p7)
        task.defer(function() -- line: 99
            -- upvalues: p7 (copy), configureModelBaseParts (copy)
            configureModelBaseParts(p7)
        end)
    end,
    getExtentsSize = function(p8, p9) -- getExtentsSize | line: 105
        if not p9 then
            return p8:GetExtentsSize()
        end

        local Pivot = p8:GetPivot()
        local v13 = Vector3.new(1, 1, 1) * 1e999
        local v14 = -v13

        for _, descendant in p8:GetDescendants() do
            if descendant:IsA("BasePart") and not table.find(p9, descendant.Name) then
                local Components, Components2, Components3, Components4, Components5, Components6, Components7, Components8, Components9, Components10, Components11, Components12 = Pivot:ToObjectSpace(descendant.CFrame):GetComponents()
                local v15 = descendant.Size / 2
                local v19 = Vector3.new(math.abs(Components4) * v15.X + math.abs(Components5) * v15.Y + math.abs(Components6) * v15.Z, math.abs(Components7) * v15.X + math.abs(Components8) * v15.Y + math.abs(Components9) * v15.Z, math.abs(Components10) * v15.X + math.abs(Components11) * v15.Y + math.abs(Components12) * v15.Z)
                local v20 = Vector3.new(Components, Components2, Components3)

                v13 = v13:Min(v20 - v19)
                v14 = v14:Max(v20 + v19)
            end
        end

        return v14 - v13
    end,
    stepThread = stepThread
}

-- И второй
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TimescaleUtilities = require(ReplicatedStorage.Resources.Common.TimescaleUtilities)

local function resumeThread(p1, p2) -- line: 12
    local v1, v2 = coroutine.resume(p2)

    if v1 then
        return
    end

    warn("[NPC] coroutine resume failed for", p1.Name, v2)
    p1._threadCo = nil
    p1._threadDelayRemaining = 0.1
end

return {
    stepThread = function(p3, p4) -- stepThread | line: 21
        -- upvalues: TimescaleUtilities (copy)
        if p3.ThreadFunction then
            local _threadCo, _threadDelayRemaining = p3._threadCo, p3._threadDelayRemaining

            if _threadDelayRemaining then
                if _threadDelayRemaining > 0 then
                    p3._threadDelayRemaining -= p4

                    return
                end

                if _threadCo and coroutine.status(_threadCo) == "suspended" then
                    local v3, v4 = coroutine.resume(_threadCo)

                    if not v3 then
                        warn("[NPC] coroutine resume failed for", p3.Name, v4)
                        p3._threadCo = nil
                        p3._threadDelayRemaining = 0.1
                    end
                end
            end

            if _threadCo and coroutine.status(_threadCo) ~= "dead" then
                return
            end

            local v5 = coroutine.create(function() -- line: 41
                -- upvalues: p3 (copy)
                local ThreadFunction = p3.ThreadFunction
                local ok, result = pcall(ThreadFunction, p3)

                if not ok then
                    warn("[NPC] ThreadFunction error for", p3.Name, result)
                end
            end)

            p3._threadCo = v5
            TimescaleUtilities._registerNPCThread(v5, p3)

            local v6, v7 = coroutine.resume(v5)

            if not v6 then
                warn("[NPC] coroutine resume failed for", p3.Name, v7)
                p3._threadCo = nil
                p3._threadDelayRemaining = 0.1
            end
        end
    end
}
