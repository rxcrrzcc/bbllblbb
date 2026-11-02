-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local FixedStep = require(script.FixedStep)
local NoYield = require(ReplicatedStorage.Shared.Modules.NoYield)
local Profiler = require(script.Profiler)
local t1 = {
    customSchedule = require(script.CustomSchedule),
    disabledSystems = {},
    profiles = Profiler.profiles,
    _connections = {},
    _callbacks = {},
    _callbackNames = {},
    noYieldChecksEnabled = false
}
local t2 = {}

local function getSignalName(p1) -- line: 37
    -- upvalues: t2 (copy)
    if t2[p1] then
        return t2[p1]
    end

    local v1 = tostring(p1):match("^Signal%s(.+)$")

    assert(v1, "Unable to get signal name")
    t2[p1] = v1

    return v1
end

local n1 = 0

local function getId() -- line: 50
    -- upvalues: n1 (ref)
    n1 += 1

    return string.format("%02x", n1)
end

function t1._execute(p2, ...) -- line: 57
    -- upvalues: t1 (copy)
    local v2 = t1._callbacks[p2]

    if v2 then
        local disabledSystems = t1.disabledSystems

        for v3, v4 in v2 do
            if not disabledSystems[v4] then
                local traceback = debug.traceback
                local v5, v6 = xpcall(v3, traceback, ...)

                if not v5 then
                    warn(v6)
                end
            end
        end
    end
end

function t1._addContext(p3) -- line: 76
    -- upvalues: Profiler (copy), t1 (copy), t2 (copy)
    if t1._connections[p3] then
        return false
    end

    local v7

    if t2[p3] then
        v7 = t2[p3]
    else
        v7 = tostring(p3):match("^Signal%s(.+)$")
        assert(v7, "Unable to get signal name")
        t2[p3] = v7
    end

    if not Profiler.profiles[v7] then
        Profiler.profiles[v7] = {}
    end

    t1._connections[p3] = p3:Connect(function(...) -- line: 86
        -- upvalues: p3 (copy), t1 (copy)
        t1._execute(p3, ...)
    end)

    return true
end

function t1.getProfile(p4, p5) -- line: 93
    -- upvalues: Profiler (copy)
    return Profiler.getProfile(p5, p4)
end

function t1.profileCallback(p6, p7, ...) -- line: 97
    -- upvalues: Profiler (copy)
    local elapsed = os.clock()

    p7(...)
    Profiler.updateProfile(p6, "Custom", os.clock() - elapsed)
end

function t1.customProfile(p8, p9) -- line: 103
    -- upvalues: Profiler (copy)
    Profiler.updateProfile(p8, "Custom", p9)
end

function t1.profile(p10, p11, p12) -- line: 107
    -- upvalues: Profiler (copy)
    Profiler.updateProfile(p10, p11, p12)
end

function t1.setNoYieldChecksEnabled(p13) -- line: 111
    -- upvalues: t1 (copy)
    t1.noYieldChecksEnabled = p13
end

local function runCallback(p14, ...) -- line: 115
    -- upvalues: NoYield (copy), t1 (copy)
    if t1.noYieldChecksEnabled then
        return NoYield(p14, ...)
    end

    return p14(...)
end

local function runProfiledCallback(p15, p16, p17, ...) -- line: 123
    -- upvalues: Profiler (copy), runCallback (copy)
    local elapsed = os.clock()
    local traceback = debug.traceback
    local v8, v9 = xpcall(runCallback, traceback, p17, ...)

    Profiler.updateProfile(p15, p16, os.clock() - elapsed)

    if not v8 then
        error(v9, 0)
    end
end

function t1.add(p18, p19, p20) -- line: 133
    -- upvalues: Profiler (copy), t1 (copy), t2 (copy), runProfiledCallback (copy)
    t1._addContext(p19)

    if not t1._callbacks[p19] then
        t1._callbacks[p19] = {}
    end

    if not t1._callbackNames[p19] then
        t1._callbackNames[p19] = {}
    end

    local v10

    if t2[p19] then
        v10 = t2[p19]
    else
        v10 = tostring(p19):match("^Signal%s(.+)$")
        assert(v10, "Unable to get signal name")
        t2[p19] = v10
    end

    local function profiledCallback(...) -- line: 146
        -- upvalues: p18 (copy), p20 (copy), v10 (ref), runProfiledCallback (copy)
        runProfiledCallback(p18, v10, p20, ...)
    end

    local v11 = t1._callbackNames[p19][p18]

    if v11 then
        t1._callbacks[p19][v11] = nil
        Profiler.removeProfile(p18, v10)
    end

    t1._callbacks[p19][profiledCallback] = p18
    t1._callbackNames[p19][p18] = profiledCallback

    return function() -- line: 159
        -- upvalues: p18 (copy), p19 (copy), v10 (ref), profiledCallback (copy), Profiler (copy), t1 (copy)
        if t1._callbackNames[p19] and t1._callbackNames[p19][p18] == profiledCallback then
            t1._callbackNames[p19][p18] = nil
        end

        if t1._callbacks[p19] and t1._callbacks[p19][profiledCallback] == p18 then
            t1._callbacks[p19][profiledCallback] = nil
            Profiler.removeProfile(p18, v10)
        end
    end
end

function t1.addDynamic(p21, p22, p23) -- line: 177
    -- upvalues: t1 (copy), n1 (ref)
    local add = t1.add

    n1 += 1

    return add(("%*_%*"):format(p21, (string.format("%02x", n1))), p22, p23)
end

local t3 = {
    [Enum.StepFrequency.Hz1] = 1,
    [Enum.StepFrequency.Hz5] = 0.2,
    [Enum.StepFrequency.Hz10] = 0.1,
    [Enum.StepFrequency.Hz15] = 0.06666666666666667,
    [Enum.StepFrequency.Hz30] = 0.03333333333333333,
    [Enum.StepFrequency.Hz60] = 0.016666666666666666
}

function t1.bindToSimulation(p24, p25, p26, _) -- line: 195
    -- upvalues: RunService (copy), FixedStep (copy), Profiler (copy), t1 (copy), runProfiledCallback (copy), t3 (copy)
    if not Profiler.profiles.Simulation then
        Profiler.profiles.Simulation = {}
    end

    local function profiledCallback(p28) -- line: 205
        -- upvalues: p24 (copy), p25 (copy), t1 (copy), runProfiledCallback (copy)
        if not t1.disabledSystems[p24] then
            runProfiledCallback(p24, "Simulation", p25, p28)
        end
    end

    local v13, v14 = FixedStep(t3[p26 or Enum.StepFrequency.Hz30] or 0.03333333333333333, profiledCallback)
    local connection = RunService.Heartbeat:Connect(v13)

    return function() -- line: 217
        -- upvalues: p24 (copy), v14 (copy), connection (copy), Profiler (copy)
        v14()
        connection:Disconnect()
        Profiler.removeProfile(p24, "Simulation")
    end
end

function t1.bindToSimulationDynamic(p29, p30, p31, p32) -- line: 224
    -- upvalues: t1 (copy), n1 (ref)
    local bindToSimulation = t1.bindToSimulation

    n1 += 1

    return bindToSimulation(("%*_%*"):format(p29, (string.format("%02x", n1))), p30, p31, p32)
end

function t1.stop() -- line: 233
    -- upvalues: t1 (copy)
    for _, v15 in t1._connections do
        v15:Disconnect()
    end

    t1._connections = {}
    t1._callbacks = {}
    t1._callbackNames = {}
end

function t1.clear(_) -- line: 243
    -- upvalues: t1 (copy)
    t1.stop()
    t1.profiler = {}
end

return t1
