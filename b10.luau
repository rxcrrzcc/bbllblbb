--Снова 2 скрипта
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)
local TypedPromise = require(ReplicatedStorage.Shared.Modules.TypedPromise)
local t1 = {}
local v1 = RunService:IsServer()
local self = setmetatable({}, {
    __mode = "kv"
})
local self2 = setmetatable({}, {
    __mode = "kv"
})

local function currentTimeScale() -- line: 15
    -- upvalues: GameState (copy), v1 (copy)
    if v1 then
        return GameState.TimeScale or 1
    end

    local State = GameState.State

    return State and State.TimeScale or GameState.TimeScale or 1
end

function t1._registerNPCThread(p1, p2) -- line: 23
    -- upvalues: self (copy)
    if p1 then
        self[p1] = p2
    end
end

function t1._registerNPCSubThread(p3, p4) -- line: 29
    -- upvalues: self2 (copy)
    if p3 then
        self2[p3] = p4
    end
end

function t1.Wait(p5) -- line: 35
    -- upvalues: GameState (copy), v1 (copy), self (copy), self2 (copy)
    p5 = p5 or 0.016666666666666666

    local thread = coroutine.running()
    local v5 = self[thread]

    if v5 then
        v5._threadDelayRemaining = (v5._threadDelayRemaining or 0) + p5

        return coroutine.yield()
    end

    local v6 = self2[thread]
    local v7 = p5

    while v7 > 0 do
        local v8 = task.wait()
        local n1 = 1

        if not v6 or v6.TimeScaled then
            if v1 then
                n1 = GameState.TimeScale or 1
            else
                local State = GameState.State
                local TimeScale = if State then State.TimeScale else nil

                n1 = if not State or not TimeScale then GameState.TimeScale or 1 else TimeScale
            end
        end

        v7 -= v8 * n1
    end

    return p5
end

function t1.Delay(p6, p7) -- line: 66
    -- upvalues: t1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v9 = self[thread] or self2[thread]
    local v10 = task.spawn(function() -- line: 70
        -- upvalues: p6 (copy), p7 (copy), t1 (copy)
        t1.Wait(p6)
        p7()
    end)

    if v9 then
        t1._registerNPCSubThread(v10, v9)
    end

    return v10
end

function t1.DelayPromise(p8) -- line: 82
    -- upvalues: TypedPromise (copy), t1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v11 = self[thread] or self2[thread]

    return TypedPromise.new(function(p9, _, p11) -- line: 86
        -- upvalues: p8 (copy), v11 (copy), t1 (copy)
        local v12 = task.spawn(function() -- line: 87
            -- upvalues: p9 (copy), p8 (copy), t1 (copy)
            t1.Wait(p8)
            p9()
        end)

        p11(function() -- line: 92
            -- upvalues: v12 (copy)
            task.cancel(v12)
        end)

        if v11 then
            t1._registerNPCSubThread(v12, v11)
        end
    end)
end

function t1.ConditionalDelay(p12, p13, p14) -- line: 102
    -- upvalues: GameState (copy), t1 (copy), v1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v13 = self[thread] or self2[thread]
    local v14 = task.spawn(function() -- line: 112
        -- upvalues: p12 (ref), p13 (copy), p14 (copy), GameState (copy), v1 (copy)
        while true do
            if p12 > 0 then
                if not p13() then
                    break
                end

                local v15 = p12
                local v16 = task.wait()
                local TimeScale

                if v1 then
                    TimeScale = GameState.TimeScale or 1
                else
                    local State = GameState.State

                    TimeScale = State and State.TimeScale or GameState.TimeScale or 1
                end

                p12 = v15 - v16 * TimeScale
                continue
            end

            p14()

            return
        end
    end)

    if v13 then
        t1._registerNPCSubThread(v14, v13)
    end

    return v14
end

function t1.GetScaledTime(p15) -- line: 129
    -- upvalues: GameState (copy)
    return p15 / GameState.TimeScale
end

function t1.CleanUp(p16, p17, p18) -- line: 133
    -- upvalues: t1 (copy)
    p17 = p17 or 0
    t1.Delay(p17, function() -- line: 136
        -- upvalues: p16 (copy), p18 (copy)
        p16:Destroy()

        if p18 then
            p18()
        end
    end)
end

return t1
--И второй
    -- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameState = require(ReplicatedStorage.Resources.Universal.GameState)
local TypedPromise = require(ReplicatedStorage.Resources.Common.TypedPromise)
local t1 = {}
local v1 = RunService:IsServer()
local self = setmetatable({}, {
    __mode = "k"
})
local self2 = setmetatable({}, {
    __mode = "k"
})

local function currentTimeScale() -- line: 15
    -- upvalues: GameState (copy), v1 (copy)
    if v1 then
        return GameState.TimeScale or 1
    end

    local State = GameState.State

    return State and State.TimeScale or GameState.TimeScale or 1
end

function t1._registerNPCThread(p1, p2) -- line: 23
    -- upvalues: self (copy)
    if p1 then
        self[p1] = p2
    end
end

function t1._registerNPCSubThread(p3, p4) -- line: 29
    -- upvalues: self2 (copy)
    if p3 then
        self2[p3] = p4
    end
end

function t1.Wait(p5) -- line: 35
    -- upvalues: GameState (copy), v1 (copy), self (copy), self2 (copy)
    p5 = p5 or 0.016666666666666666

    local thread = coroutine.running()
    local v5 = self[thread]

    if v5 then
        if not v5._threadDelayRemaining or v5._threadDelayRemaining < p5 then
            v5._threadDelayRemaining = p5
        end

        return coroutine.yield()
    end

    local v6 = self2[thread]
    local v7 = p5

    while v7 > 0 do
        local v8 = task.wait()
        local n1 = 1

        if not v6 or v6.TimeScaled then
            if v1 then
                n1 = GameState.TimeScale or 1
            else
                local State = GameState.State
                local TimeScale = if State then State.TimeScale else nil

                n1 = if not State or not TimeScale then GameState.TimeScale or 1 else TimeScale
            end
        end

        v7 -= v8 * n1
    end

    return p5
end

function t1.Delay(p6, p7) -- line: 66
    -- upvalues: t1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v9 = self[thread] or self2[thread]
    local v10 = task.spawn(function() -- line: 70
        -- upvalues: p6 (copy), p7 (copy), t1 (copy)
        t1.Wait(p6)
        p7()
    end)

    if v9 then
        t1._registerNPCSubThread(v10, v9)
    end

    return v10
end

function t1.DelayPromise(p8) -- line: 82
    -- upvalues: TypedPromise (copy), t1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v11 = self[thread] or self2[thread]

    return TypedPromise.new(function(p9, _, p11) -- line: 86
        -- upvalues: p8 (copy), v11 (copy), t1 (copy)
        local v12 = task.spawn(function() -- line: 87
            -- upvalues: p9 (copy), p8 (copy), t1 (copy)
            t1.Wait(p8)
            p9()
        end)

        p11(function() -- line: 92
            -- upvalues: v12 (copy)
            task.cancel(v12)
        end)

        if v11 then
            t1._registerNPCSubThread(v12, v11)
        end
    end)
end

function t1.ConditionalDelay(p12, p13, p14) -- line: 102
    -- upvalues: GameState (copy), t1 (copy), v1 (copy), self (copy), self2 (copy)
    local thread = coroutine.running()
    local v13 = self[thread] or self2[thread]
    local v14 = task.spawn(function() -- line: 112
        -- upvalues: p12 (ref), p13 (copy), p14 (copy), GameState (copy), v1 (copy)
        while true do
            if p12 > 0 then
                if not p13() then
                    break
                end

                local v15 = p12
                local v16 = task.wait()
                local TimeScale

                if v1 then
                    TimeScale = GameState.TimeScale or 1
                else
                    local State = GameState.State

                    TimeScale = State and State.TimeScale or GameState.TimeScale or 1
                end

                p12 = v15 - v16 * TimeScale
                continue
            end

            p14()

            return
        end
    end)

    if v13 then
        t1._registerNPCSubThread(v14, v13)
    end

    return v14
end

function t1.GetScaledTime(p15) -- line: 129
    -- upvalues: GameState (copy)
    return p15 / GameState.TimeScale
end

function t1.CleanUp(p16, p17, p18) -- line: 133
    -- upvalues: t1 (copy)
    p17 = p17 or 0
    t1.Delay(p17, function() -- line: 136
        -- upvalues: p16 (copy), p18 (copy)
        p16:Destroy()

        if p18 then
            p18()
        end
    end)
end

return t1
