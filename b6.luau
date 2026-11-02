-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ParticleLODController = require(ReplicatedStorage.Client.Modules.ParticleLODController)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local t1 = {}
local t2 = {}
local n1 = 0
local n2 = 0
local n3 = 0

local function getEffectPosition(p1) -- line: 31
    if p1:IsA("Model") then
        return p1:GetPivot().Position
    end

    if p1:IsA("BasePart") then
        return p1.Position
    end

    if p1:IsA("Attachment") then
        return p1.WorldPosition
    end

    local v1 = p1:FindFirstChildWhichIsA("Attachment", true)

    if v1 then
        return v1.WorldPosition
    end

    local v2 = p1:FindFirstChildWhichIsA("BasePart", true)

    if v2 then
        return v2.Position
    end

    return (Vector3.new(0, 0, 0))
end

local function sanitizeInstance(p2) -- line: 49
    if not p2:IsA("BasePart") then
        return
    end

    p2.CanCollide = false
    p2.CanTouch = false
    p2.CanQuery = false
    p2.CastShadow = false
end

function t1.sanitize(p3) -- line: 60
    if p3:IsA("BasePart") then
        p3.CanCollide = false
        p3.CanTouch = false
        p3.CanQuery = false
        p3.CastShadow = false
    end

    for _, descendant in p3:GetDescendants() do
        if descendant:IsA("BasePart") then
            descendant.CanCollide = false
            descendant.CanTouch = false
            descendant.CanQuery = false
            descendant.CastShadow = false
        end
    end
end

local function finishRecord(p4) -- line: 67
    -- upvalues: t2 (copy), n1 (ref), n3 (ref)
    if p4.destroyed then
        return
    end

    p4.destroyed = true
    t2[p4.root] = nil
    n1 = math.max(0, n1 - 1)
    n3 += 1

    if p4.destroyingConnection then
        p4.destroyingConnection:Disconnect()
        p4.destroyingConnection = nil
    end

    if p4.unregisterLOD then
        p4.unregisterLOD()
        p4.unregisterLOD = nil
    end
end

local function destroyRoot(p5) -- line: 88
    -- upvalues: t2 (copy), n1 (ref), n3 (ref)
    if p5.destroyed then
        return
    end

    p5.root:Destroy()

    if not p5.destroyed then
        if p5.destroyed then
            return
        end

        p5.destroyed = true
        t2[p5.root] = nil
        n1 = math.max(0, n1 - 1)
        n3 += 1

        if p5.destroyingConnection then
            p5.destroyingConnection:Disconnect()
            p5.destroyingConnection = nil
        end

        if p5.unregisterLOD then
            p5.unregisterLOD()
            p5.unregisterLOD = nil
        end
    end
end

function t1.track(p6, p7) -- line: 99
    -- upvalues: ParticleLODController (copy), t1 (copy), t2 (copy), n1 (ref), n2 (ref), n3 (ref), getEffectPosition (copy)
    p7 = p7 or {}
    t1.sanitize(p6)

    local v6 = t2[p6]

    if v6 then
        if p7.profileName then
            v6.profileName = p7.profileName
        end
    else
        v6 = {
            destroyed = false,
            destroyingConnection = nil,
            unregisterLOD = nil,
            root = p6,
            profileName = p7.profileName
        }
        t2[p6] = v6
        n1 += 1
        n2 += 1

        local connection = p6.Destroying:Once(function() -- line: 117
            -- upvalues: v6 (ref), t2 (copy), n1 (ref), n3 (ref)
            local v7 = v6

            if v7.destroyed then
                return
            end

            v7.destroyed = true
            t2[v7.root] = nil
            n1 = math.max(0, n1 - 1)
            n3 += 1

            if v7.destroyingConnection then
                v7.destroyingConnection:Disconnect()
                v7.destroyingConnection = nil
            end

            if v7.unregisterLOD then
                v7.unregisterLOD()
                v7.unregisterLOD = nil
            end
        end)

        v6.destroyingConnection = connection
    end

    if p7.registerLOD ~= false and not v6.unregisterLOD then
        local v9 = ParticleLODController.registerRoot(p6, function() -- line: 125
            -- upvalues: p6 (copy), getEffectPosition (copy)
            return (getEffectPosition(p6))
        end)

        v6.unregisterLOD = v9
    end

    if p7.ttl then
        local v10 = math.max(0, p7.ttl)

        task.delay(v10, function() -- line: 132
            -- upvalues: v6 (ref), t2 (copy), n1 (ref), n3 (ref)
            local v11 = v6

            if not v11.destroyed then
                v11.root:Destroy()

                if not v11.destroyed then
                    if v11.destroyed then
                        return
                    end

                    v11.destroyed = true
                    t2[v11.root] = nil
                    n1 = math.max(0, n1 - 1)
                    n3 += 1

                    if v11.destroyingConnection then
                        v11.destroyingConnection:Disconnect()
                        v11.destroyingConnection = nil
                    end

                    if v11.unregisterLOD then
                        v11.unregisterLOD()
                        v11.unregisterLOD = nil
                    end
                end
            end
        end)
    end

    return function() -- line: 137
        -- upvalues: v6 (ref), t2 (copy), n1 (ref), n3 (ref)
        local v13 = v6

        if not v13.destroyed then
            v13.root:Destroy()

            if not v13.destroyed then
                if v13.destroyed then
                    return
                end

                v13.destroyed = true
                t2[v13.root] = nil
                n1 = math.max(0, n1 - 1)
                n3 += 1

                if v13.destroyingConnection then
                    v13.destroyingConnection:Disconnect()
                    v13.destroyingConnection = nil
                end

                if v13.unregisterLOD then
                    v13.unregisterLOD()
                    v13.unregisterLOD = nil
                end
            end
        end
    end
end

function t1.getDebugStats() -- line: 142
    -- upvalues: n1 (ref), n2 (ref), n3 (ref)
    return {
        active = n1,
        created = n2,
        destroyed = n3
    }
end

local function countContainer(p8) -- line: 150
    if not p8 then
        return 0, 0, 0, 0
    end

    local v15 = #p8:GetChildren()
    local n4 = 0
    local n5 = 0
    local n6 = 0

    for _, descendant in p8:GetDescendants() do
        if descendant:IsA("BasePart") then
            n4 += 1

            if descendant.CastShadow then
                n5 += 1
            end
        elseif descendant:IsA("ParticleEmitter") then
            n6 += 1
        end
    end

    return v15, n4, n5, n6
end

local function countTrackedTerrainRoots() -- line: 174
    -- upvalues: t2 (copy)
    local Terrain = workspace:FindFirstChildOfClass("Terrain")

    if not Terrain then
        return 0
    end

    local n7 = 0

    for v16 in t2 do
        if v16:IsDescendantOf(Terrain) then
            n7 += 1
        end
    end

    return n7
end

local n8 = 0

Scheduler.add("TransientVFXDiagnostics", RunService.Heartbeat, function(p9) -- line: 191
    -- upvalues: Scheduler (copy), n1 (ref), n2 (ref), n3 (ref), countContainer (copy), countTrackedTerrainRoots (copy), n8 (ref)
    n8 += p9

    if n8 < 2 then
        return
    end

    n8 = 0

    local v17, v18, v19, v20 = countContainer(workspace:FindFirstChild("Trash"))
    local _, v21, _, v22 = countContainer(workspace.CurrentCamera)

    Scheduler.customProfile("PerfDiag_TrashChildren", v17)
    Scheduler.customProfile("PerfDiag_TrashBaseParts", v18)
    Scheduler.customProfile("PerfDiag_TrashShadowCasters", v19)
    Scheduler.customProfile("PerfDiag_TrashParticles", v20)
    Scheduler.customProfile("PerfDiag_CameraBaseParts", v21)
    Scheduler.customProfile("PerfDiag_CameraParticles", v22)
    Scheduler.customProfile("PerfDiag_TerrainTransientRoots", (countTrackedTerrainRoots()))
    Scheduler.customProfile("PerfDiag_TransientVFXActive", n1)
    Scheduler.customProfile("PerfDiag_TransientVFXCreated", n2)
    Scheduler.customProfile("PerfDiag_TransientVFXDestroyed", n3)
end)

return t1
