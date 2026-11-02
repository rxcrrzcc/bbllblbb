--Таких модулей 2 поэтому я вставлю 1 скрипт а после 2й. Единственно чем они отличаются так это содержанием и путем
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EasySound = require(ReplicatedStorage.Shared.Modules.EasySound)
local EmitterUtil = require(ReplicatedStorage.Shared.Modules.EmitterUtil)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)
local t1 = {}
local t2 = {}
local v1 = Random.new()
local v2 = true
local t3 = {
    Critical = true,
    GameplayCritical = true,
    Telegraph = true
}
local t4 = {
    FlashBang = true,
    Freeze = true,
    HandDie = true,
    HandKill = true,
    Nuke = true
}
local t5 = {
    "boss",
    "indicator",
    "range",
    "reticle",
    "stun",
    "target",
    "targeting",
    "telegraph",
    "warning"
}
local t6 = {
    emitRequests = 0,
    emitFired = 0,
    emitSkipped = 0,
    emitMerged = 0,
    emitCapped = 0,
    manualRequests = 0,
    manualSkipped = 0,
    manualParticlesRequested = 0,
    manualParticlesEmitted = 0,
    pendingPeak = 0
}
local v3 = table.clone(t6)

local function bumpStat(p1, p2) -- line: 90
    -- upvalues: t6 (copy)
    t6[p1] = (t6[p1] or 0) + (p2 or 1)
end

local function publishStats() -- line: 94
    -- upvalues: Scheduler (copy), t6 (copy), v3 (ref)
    v3 = table.clone(t6)
    Scheduler.customProfile("VFX Emit Requests", t6.emitRequests)
    Scheduler.customProfile("VFX Emit Fired", t6.emitFired)
    Scheduler.customProfile("VFX Emit Skipped", t6.emitSkipped)
    Scheduler.customProfile("VFX Cluster Merged", t6.emitMerged)
    Scheduler.customProfile("VFX Cluster Capped", t6.emitCapped)
    Scheduler.customProfile("VFX Manual Requests", t6.manualRequests)
    Scheduler.customProfile("VFX Manual Particles", t6.manualParticlesEmitted)
    Scheduler.customProfile("VFX Pending Peak", t6.pendingPeak)

    for v4 in t6 do
        t6[v4] = 0
    end
end

local n1 = 0

Scheduler.add("VFXEmitterStats", RunService.Heartbeat, function(p3) -- line: 112
    -- upvalues: publishStats (copy), n1 (ref)
    n1 += p3

    if not (n1 < 0.5) then
        n1 = 0
        publishStats()
    end
end)

function t1.getDebugStats() -- line: 122
    -- upvalues: v3 (ref)
    return table.clone(v3)
end

local v5, v6

function t1.setManualEmitFilter(p4) -- line: 132
    -- upvalues: v5 (ref)
    v5 = p4
end

function t1.setOneShotEmitFilter(p5) -- line: 136
    -- upvalues: v6 (ref)
    v6 = p5
end

local function getManualEmitMultiplier(p6) -- line: 140
    -- upvalues: v5 (ref)
    if v5 then
        return (v5(p6))
    end

    return 1
end

if not RunService:IsServer() then
    local SettingsController = require(ReplicatedStorage.Client.Controllers.Shared.SettingsController)

    v2 = SettingsController.Game:Get("HQ Effects")
    SettingsController.Game:On("HQ Effects", function(p7) -- line: 148
        -- upvalues: v2 (ref)
        v2 = p7
    end)
end

local function getEmitterWorldPos(p8) -- line: 154
    local Parent = p8.Parent

    if Parent then
        if Parent:IsA("Attachment") then
            return Parent.WorldPosition
        end

        if Parent:IsA("BasePart") then
            return Parent.Position
        end
    end

    return (Vector3.new(0, 0, 0))
end

local t7 = {}
local t8 = {
    ParticleEmitter = true,
    Beam = true,
    Trail = true,
    Sound = true
}

local function buildManualEmitData(p9) -- line: 183
    -- upvalues: t8 (copy)
    local t9 = {}

    for _, v7 in {
            p9,
            unpack(p9:GetDescendants())
        } do
        if t8[v7.ClassName] then
            table.insert(t9, {
                obj = v7,
                emitDelay = v7:GetAttribute(if v7:IsA("Sound") then "Delay" else "EmitDelay") or 0,
                emitCount = v7:GetAttribute("EmitCount") or 0,
                emitDuration = v7:GetAttribute("EmitDuration") or 0
            })
        end
    end

    return t9
end

local function getManualEmitData(p10) -- line: 200
    -- upvalues: t7 (copy), buildManualEmitData (copy)
    local v8 = t7[p10]

    if v8 then
        return v8.instances
    end

    local v9 = buildManualEmitData(p10)
    local t11 = {
        instances = v9,
        conns = {}
    }

    local function invalidate() -- line: 210
        -- upvalues: p10 (copy), t7 (copy)
        if t7[p10] then
            for _, v10 in t7[p10].conns do
                v10:Disconnect()
            end

            t7[p10] = nil
        end
    end

    table.insert(t11.conns, p10.Destroying:Once(invalidate))
    table.insert(t11.conns, p10.DescendantAdded:Connect(invalidate))
    table.insert(t11.conns, p10.DescendantRemoving:Connect(invalidate))
    t7[p10] = t11

    return v9
end

function t1.emitParticle(p11, p12, p13) -- line: 230
    -- upvalues: v2 (ref), t6 (copy), v5 (ref)
    t6.manualRequests = (t6.manualRequests or 0) + 1
    t6.manualParticlesRequested = (t6.manualParticlesRequested or 0) + (p12 or 1)

    if not v2 then
        t6.manualSkipped = (t6.manualSkipped or 0) + 1

        return
    end

    p13 = p13 or p11

    local v12 = if v5 then v5(p13) else 1

    if v12 <= 0 then
        t6.manualSkipped = (t6.manualSkipped or 0) + 1
    else
        local v14 = math.round(p12 * v12)

        t6.manualParticlesEmitted = (t6.manualParticlesEmitted or 0) + (v14 or 1)

        if v14 <= 0 then
            t6.manualSkipped = (t6.manualSkipped or 0) + 1
        else
            p11:Emit(v14)
        end
    end
end

function t1.manualEmit(p14, p15) -- line: 256
    -- upvalues: EasySound (copy), v1 (copy), v2 (ref), t6 (copy), v5 (ref), getManualEmitData (copy)
    t6.manualRequests = (t6.manualRequests or 0) + 1

    if not v2 then
        t6.manualSkipped = (t6.manualSkipped or 0) + 1

        return
    end

    local v15 = if v5 then v5(p14) else 1

    if v15 <= 0 then
        t6.manualSkipped = (t6.manualSkipped or 0) + 1
    else
        local v16 = getManualEmitData(p14)
        local t12 = {}

        local function emit(p16) -- line: 286
            -- upvalues: v15 (copy), EasySound (copy), v1 (copy), t6 (copy)
            local obj, emitDelay = p16.obj, p16.emitDelay
            local v18 = math.round(p16.emitCount * v15)
            local emitDuration, emitCount = p16.emitDuration, p16.emitCount

            t6.manualParticlesRequested = (t6.manualParticlesRequested or 0) + (emitCount or 1)
            t6.manualParticlesEmitted = (t6.manualParticlesEmitted or 0) + (v18 or 1)

            local function doEmit() -- line: 299
                -- upvalues: obj (copy), v18 (copy), emitDuration (copy), EasySound (copy), v1 (copy)
                if obj:IsA("ParticleEmitter") then
                    obj:Emit(v18)
                end

                if obj:IsA("Sound") then
                    EasySound.Play({
                        soundGroupName = "Towers",
                        destroyOnEnd = true,
                        id = obj.SoundId,
                        parent = obj.Parent,
                        volume = obj.Volume,
                        playbackSpeed = obj.PlaybackSpeed * v1:NextNumber(0.9, 1.1)
                    })
                elseif emitDuration > 0 then
                    task.defer(function() -- line: 315
                        -- upvalues: obj (copy), emitDuration (copy)
                        obj.Enabled = true
                        task.wait(emitDuration)
                        obj.Enabled = false
                    end)
                end
            end

            if emitDelay > 0 then
                task.delay(emitDelay, doEmit)
            else
                doEmit()
            end
        end

        for _, v19 in v16 do
            local obj = v19.obj

            if not p15 or obj:IsA(p15) then
                if obj:IsA("ParticleEmitter") then
                    local objParent = obj.Parent
                    local WorldPosition = if not objParent then Vector3.new(0, 0, 0)
                        elseif objParent:IsA("Attachment") then objParent.WorldPosition
                        elseif objParent:IsA("BasePart") then objParent.Position
                        else Vector3.new(0, 0, 0)
                    local Texture = obj.Texture
                    local v22 = false

                    for _, v23 in t12 do
                        if v23.texture == Texture and (v23.pos - WorldPosition).Magnitude < 3 then
                            v23.emitCount += v19.emitCount
                            v22 = true
                            break
                        end
                    end

                    if not v22 then
                        table.insert(t12, {
                            emitter = obj,
                            pos = WorldPosition,
                            texture = Texture,
                            emitCount = v19.emitCount,
                            emitDelay = v19.emitDelay,
                            emitDuration = v19.emitDuration
                        })
                    end
                else
                    emit(v19)
                end
            end
        end

        for _, v24 in t12 do
            local v26 = math.round(v24.emitCount * v15)
            local emitter, emitDelay, emitDuration, emitCount = v24.emitter, v24.emitDelay, v24.emitDuration, v24.emitCount

            t6.manualParticlesRequested = (t6.manualParticlesRequested or 0) + (emitCount or 1)
            t6.manualParticlesEmitted = (t6.manualParticlesEmitted or 0) + (v26 or 1)

            local function doGroupEmit() -- line: 376
                -- upvalues: v26 (copy), emitter (copy), emitDuration (copy)
                emitter:Emit(v26)

                if emitDuration > 0 then
                    task.defer(function() -- line: 379
                        -- upvalues: emitter (copy), emitDuration (copy)
                        emitter.Enabled = true
                        task.wait(emitDuration)
                        emitter.Enabled = false
                    end)
                end
            end

            if emitDelay > 0 then
                task.delay(emitDelay, doGroupEmit)
            else
                emitter:Emit(v26)

                if emitDuration > 0 then
                    task.defer(function() -- line: 379
                        -- upvalues: emitter (copy), emitDuration (copy)
                        emitter.Enabled = true
                        task.wait(emitDuration)
                        emitter.Enabled = false
                    end)
                end
            end
        end
    end
end

local function mergeEmitterProperties(p17, p18, p19) -- line: 397
    -- upvalues: EmitterUtil (copy)
    local v27 = 1 / p19

    local function blendNumberSequence(p20) -- line: 404
        -- upvalues: p17 (copy), p18 (copy), v27 (copy), EmitterUtil (copy)
        local v28 = p17[p20]
        local v29 = p18[p20]

        p17[p20] = EmitterUtil.averageNumberSequence(v28, v29, v27)
    end

    local function blendColorSequence(p21) -- line: 410
        -- upvalues: p17 (copy), p18 (copy), v27 (copy), EmitterUtil (copy)
        local v30 = p17[p21]
        local v31 = p18[p21]

        p17[p21] = EmitterUtil.averageColorSequence(v30, v31, v27)
    end

    local function blendNumberRange(p22) -- line: 416
        -- upvalues: p17 (copy), p18 (copy), v27 (copy)
        local v32 = p17[p22]
        local v33 = p18[p22]

        p17[p22] = NumberRange.new(v32.Min + (v33.Min - v32.Min) * v27, v32.Max + (v33.Max - v32.Max) * v27)
    end

    local function blendNumber(p23) -- line: 423
        -- upvalues: p17 (copy), p18 (copy), v27 (copy)
        local v34 = p17[p23]

        p17[p23] = v34 + (p18[p23] - v34) * v27
    end

    local Size = p17.Size
    local Size2 = p18.Size

    p17.Size = EmitterUtil.averageNumberSequence(Size, Size2, v27)

    local Color = p17.Color
    local Color2 = p18.Color

    p17.Color = EmitterUtil.averageColorSequence(Color, Color2, v27)

    local Transparency = p17.Transparency
    local Transparency2 = p18.Transparency

    p17.Transparency = EmitterUtil.averageNumberSequence(Transparency, Transparency2, v27)

    local Lifetime = p17.Lifetime
    local Lifetime2 = p18.Lifetime

    p17.Lifetime = NumberRange.new(Lifetime.Min + (Lifetime2.Min - Lifetime.Min) * v27, Lifetime.Max + (Lifetime2.Max - Lifetime.Max) * v27)

    local Speed = p17.Speed
    local Speed2 = p18.Speed

    p17.Speed = NumberRange.new(Speed.Min + (Speed2.Min - Speed.Min) * v27, Speed.Max + (Speed2.Max - Speed.Max) * v27)

    local LightEmission = p17.LightEmission

    p17.LightEmission = LightEmission + (p18.LightEmission - LightEmission) * v27

    local LightInfluence = p17.LightInfluence

    p17.LightInfluence = LightInfluence + (p18.LightInfluence - LightInfluence) * v27

    local RotSpeed = p17.RotSpeed
    local RotSpeed2 = p18.RotSpeed

    p17.RotSpeed = NumberRange.new(RotSpeed.Min + (RotSpeed2.Min - RotSpeed.Min) * v27, RotSpeed.Max + (RotSpeed2.Max - RotSpeed.Max) * v27)

    local Rotation = p17.Rotation
    local Rotation2 = p18.Rotation

    p17.Rotation = NumberRange.new(Rotation.Min + (Rotation2.Min - Rotation.Min) * v27, Rotation.Max + (Rotation2.Max - Rotation.Max) * v27)
end

local function readAttribute(p24, p25, p26) -- line: 440
    local Attribute, v36

    if p24 then
        Attribute = p24:GetAttribute(p26)
        v36 = Attribute == nil
    end

    if p24 and not v36 then
        return Attribute
    end

    for _, v37 in p25 do
        local Attribute = v37:GetAttribute(p26)

        if Attribute ~= nil then
            return Attribute
        end
    end

    return nil
end

function t1.register(p27, p28, p29) -- line: 458
    -- upvalues: t2 (copy), mergeEmitterProperties (copy), readAttribute (copy)
    local Attachment = Instance.new("Attachment")
    local AllowCluster = readAttribute(p29, p28, "AllowCluster")
    local NoCluster = readAttribute(p29, p28, "NoCluster")
    local ClusterRadius = readAttribute(p29, p28, "ClusterRadius")
    local MaxClusterAmount = readAttribute(p29, p28, "MaxClusterAmount")
    local v38 = readAttribute(p29, p28, "VFXPriority") or readAttribute(p29, p28, "Priority")

    if AllowCluster == nil and typeof(NoCluster) == "boolean" then
        AllowCluster = not NoCluster
    end

    local t15 = {
        originalRadius = 1,
        attachment = Attachment,
        allowCluster = if typeof(AllowCluster) ~= "boolean" then nil else AllowCluster,
        clusterRadius = if typeof(ClusterRadius) ~= "number" then nil else ClusterRadius,
        maxClusterAmount = if typeof(MaxClusterAmount) ~= "number" then nil else MaxClusterAmount,
        priority = if typeof(v38) ~= "string" then nil else v38,
        emitters = {},
        emitterData = {},
        soundData = {}
    }
    local t16 = {}

    for _, v39 in p28 do
        local Radius = v39:GetAttribute("Radius")
        local Attachment2 = Instance.new("Attachment")

        Attachment2.CFrame = v39.CFrame

        if Radius then
            t15.originalRadius = Radius
        end

        for _, child in v39:GetChildren() do
            if child:IsA("ParticleEmitter") then
                local clone = child:Clone()

                clone.Enabled = false
                clone.Parent = Attachment2
                table.insert(t16, {
                    emitter = clone,
                    emitDelay = child:GetAttribute("EmitDelay"),
                    emitDuration = child:GetAttribute("EmitDuration"),
                    emitCount = child:GetAttribute("EmitCount") or 1,
                    attachment = Attachment2
                })
            elseif child:IsA("Sound") then
                table.insert(t15.soundData, {
                    sound = child,
                    attachment = Attachment2
                })
            end
        end

        Attachment2.Parent = Attachment
    end

    local t19 = {}

    for _, v40 in t16 do
        local Texture = v40.emitter.Texture

        if t19[Texture] then
            local v41 = t19[Texture]

            v41.mergeCount += 1
            v41.emitCount += v40.emitCount
            v41.emitter.Rate += v40.emitter.Rate
            mergeEmitterProperties(v41.emitter, v40.emitter, v41.mergeCount)
            v40.emitter:Destroy()
            continue
        end

        t19[Texture] = {
            mergeCount = 1,
            emitter = v40.emitter,
            emitCount = v40.emitCount,
            emitDelay = v40.emitDelay,
            emitDuration = v40.emitDuration
        }
    end

    for _, v42 in t19 do
        table.insert(t15.emitters, v42.emitter)
        table.insert(t15.emitterData, {
            emitter = v42.emitter,
            emitDelay = v42.emitDelay,
            emitDuration = v42.emitDuration,
            emitCount = v42.emitCount
        })
    end

    Attachment.Name = ("%*Effect"):format(p27)
    Attachment.Parent = workspace.Terrain
    t2[p27] = t15
end

local t21 = {}
local v43 = false

local function fireEmitDirect(p30, p31, p32, p33, p34, _) -- line: 597
    -- upvalues: EasySound (copy), EmitterUtil (copy), TimescaleUtilities (copy), t2 (copy), v1 (copy)
    p33 = p33 or 1

    local v45 = t2[p30]

    if not v45 then
        warn("EmitterManager: Emitter " .. p30 .. " does not exist")

        return
    end

    if p32 and v45.originalRadius ~= nil then
        local v46 = p32 / v45.originalRadius

        EmitterUtil:scaleEmitter(v45.emitters, v46, true)
    end

    v45.attachment.WorldCFrame = p31

    for _, v47 in ipairs(v45.emitterData) do
        local v48 = v47.emitCount * p33
        local v49 = v47.emitDuration or 0
        local v50 = v47.emitDelay or 0

        local function runEmitter() -- line: 621
            -- upvalues: v47 (copy), v48 (copy), v49 (copy), TimescaleUtilities (copy)
            v47.emitter:Emit(v48)

            if v49 > 0 then
                v47.emitter.Enabled = true
                TimescaleUtilities.Delay(v47.emitDuration, function() -- line: 627
                    -- upvalues: v47 (copy)
                    v47.emitter.Enabled = false
                end)
            end
        end

        if v50 > 0 then
            TimescaleUtilities.Delay(v47.emitDelay, runEmitter)
        else
            v47.emitter:Emit(v48)

            if v49 > 0 then
                v47.emitter.Enabled = true
                TimescaleUtilities.Delay(v47.emitDuration, function() -- line: 627
                    -- upvalues: v47 (copy)
                    v47.emitter.Enabled = false
                end)
            end
        end
    end

    if p34 or p34 == nil then
        for _, v51 in ipairs(v45.soundData) do
            EasySound.Play({
                destroyOnEnd = true,
                audioGroup = "Towers",
                id = v51.sound.SoundId,
                parent = v51.attachment,
                volume = v51.sound.Volume,
                playbackSpeed = v1:NextNumber(0.9, 1.1)
            })
        end
    end
end

local function priorityIsCritical(p36) -- line: 657
    -- upvalues: t3 (copy)
    return p36 ~= nil and t3[p36] == true
end

local function nameLooksCritical(p37) -- line: 661
    -- upvalues: t4 (copy), t5 (copy)
    if t4[p37] then
        return true
    end

    local v52 = string.lower(p37)

    for _, v53 in t5 do
        if string.find(v52, v53, 1, true) then
            return true
        end
    end

    return false
end

local function isCriticalEmit(p38, p39) -- line: 676
    -- upvalues: t2 (copy), t3 (copy), nameLooksCritical (copy)
    local v54 = t2[p38]
    local priority = if p39 then p39.priority else nil
    local priority2 = if v54 then v54.priority else nil

    if priority ~= nil and t3[priority] == true or priority2 ~= nil and t3[priority2] == true or p39 and p39.allowCluster == false or v54 and v54.allowCluster == false then
        return true
    end

    if not p39 or p39.allowCluster ~= true then
        local v55 = if v54 then v54.allowCluster == true else nil

        if not v54 or not v55 then
            return (nameLooksCritical(p38))
        end
    end

    return false
end

local function getClusterPolicy(p40, p41, p42) -- line: 702
    -- upvalues: t2 (copy), isCriticalEmit (copy)
    if isCriticalEmit(p40, p42) then
        return {
            canMerge = false,
            radius = 0,
            maxAmount = 1e999
        }
    end

    local v56 = t2[p40]
    local maxClusterAmount = if p42 and p42.maxClusterAmount ~= nil then p42.maxClusterAmount elseif v56 then v56.maxClusterAmount else nil

    if p42 and p42.clusterRadius then
        return {
            canMerge = true,
            radius = p42.clusterRadius,
            maxAmount = maxClusterAmount or 1e999
        }
    end

    if v56 and v56.clusterRadius then
        return {
            canMerge = true,
            radius = v56.clusterRadius,
            maxAmount = maxClusterAmount or 1e999
        }
    end

    local CurrentCamera = workspace.CurrentCamera

    if not CurrentCamera then
        return {
            canMerge = true,
            radius = 2.5,
            maxAmount = maxClusterAmount or 5
        }
    end

    local Magnitude = (CurrentCamera.CFrame.Position - p41.Position).Magnitude

    if Magnitude <= 16 then
        return {
            canMerge = true,
            radius = 0.5,
            maxAmount = maxClusterAmount or 1e999
        }
    end

    if Magnitude <= 32 then
        return {
            canMerge = true,
            radius = 2.5,
            maxAmount = maxClusterAmount or 5
        }
    end

    return {
        canMerge = true,
        radius = 5,
        maxAmount = maxClusterAmount or 2
    }
end

local function radiiCompatible(p43, p44) -- line: 762
    if p43 == p44 then
        return true
    end

    if p43 == nil or p44 == nil then
        return false
    end

    return math.abs(p43 - p44) <= math.max(0.5, math.max(p43, p44) * 0.15)
end

local function canMergePending(p45, p46) -- line: 773
    -- upvalues: isCriticalEmit (copy), getClusterPolicy (copy)
    if p45.name ~= p46.name or p45.playSound ~= p46.playSound or p45.soundGroupName ~= p46.soundGroupName then
        return false
    end

    local radius = p45.radius
    local radius2 = p46.radius

    if (radius == radius2 or radius ~= nil and radius2 ~= nil and math.abs(radius - radius2) <= math.max(0.5, math.max(radius, radius2) * 0.15)) and not (isCriticalEmit(p45.name, p45.options) or isCriticalEmit(p46.name, p46.options)) then
        local v64 = getClusterPolicy(p45.name, p45.cframe, p45.options)
        local v65 = getClusterPolicy(p46.name, p46.cframe, p46.options)

        if v64.canMerge and v65.canMerge then
            return math.min(v64.radius, v65.radius) >= (p45.cframe.Position - p46.cframe.Position).Magnitude
        end
    end

    return false
end

local function flushPendingEmits() -- line: 814
    -- upvalues: t6 (copy), v6 (ref), t21 (copy), v43 (ref), fireEmitDirect (copy), isCriticalEmit (copy), getClusterPolicy (copy), canMergePending (copy)
    v43 = false

    if #t21 == 0 then
        return
    end

    local t22 = {}

    for _, v66 in t21 do
        local v67 = false

        for _, v68 in t22 do
            if canMergePending(v68, v66) then
                v68.amountMultiplier += v66.amountMultiplier
                v67 = true
                t6.emitMerged = (t6.emitMerged or 0) + 1
                break
            end
        end

        if not v67 then
            table.insert(t22, {
                name = v66.name,
                cframe = v66.cframe,
                radius = v66.radius,
                amountMultiplier = v66.amountMultiplier,
                playSound = v66.playSound,
                soundGroupName = v66.soundGroupName,
                options = v66.options
            })
        end
    end

    table.clear(t21)

    for _, v69 in t22 do
        local amountMultiplier = v69.amountMultiplier
        local v70 = getClusterPolicy(v69.name, v69.cframe, v69.options)

        if v70.maxAmount < amountMultiplier then
            amountMultiplier = v70.maxAmount
            t6.emitCapped = (t6.emitCapped or 0) + 1
        end

        if v6 and not isCriticalEmit(v69.name, v69.options) then
            amountMultiplier *= v6(v69.cframe.Position)
        end

        if amountMultiplier <= 0 then
            t6.emitSkipped = (t6.emitSkipped or 0) + 1
        else
            t6.emitFired = (t6.emitFired or 0) + 1
            fireEmitDirect(v69.name, v69.cframe, v69.radius, amountMultiplier, v69.playSound, v69.soundGroupName)
        end
    end
end

function t1.Emit(p47, p48, p49, p50, p51, p52, p53) -- line: 877
    -- upvalues: RunService (copy), v2 (ref), t6 (copy), t21 (copy), v43 (ref), fireEmitDirect (copy), flushPendingEmits (copy)
    t6.emitRequests = (t6.emitRequests or 0) + 1

    if not v2 then
        t6.emitSkipped = (t6.emitSkipped or 0) + 1

        return
    end

    p50 = p50 or 1

    if RunService:IsServer() then
        t6.emitFired = (t6.emitFired or 0) + 1
        fireEmitDirect(p47, p48, p49, p50, p51, p52)
    else
        table.insert(t21, {
            name = p47,
            cframe = p48,
            radius = p49,
            amountMultiplier = p50,
            playSound = p51,
            soundGroupName = p52,
            options = p53
        })

        if #t21 > t6.pendingPeak then
            t6.pendingPeak = #t21
        end

        if not v43 then
            v43 = true
            task.defer(flushPendingEmits)
        end
    end
end

function t1.toggle(p54, p55, p56) -- line: 922
    -- upvalues: TimescaleUtilities (copy)
    local function toggleInstance(p57) -- line: 923
        -- upvalues: p55 (copy), p56 (copy), TimescaleUtilities (copy)
        if p56 and not p57:IsA(p56) then
            return
        end

        if p57:IsA("ParticleEmitter") or p57:IsA("Beam") or p57:IsA("Trail") then
            local Delay = p57:GetAttribute("Delay")

            if p55 and Delay and Delay > 0 then
                TimescaleUtilities.Delay(Delay, function() -- line: 934
                    -- upvalues: p57 (copy), p55 (copy)
                    p57.Enabled = p55
                end)
            else
                p57.Enabled = p55
            end
        end
    end

    toggleInstance(p54)

    for _, descendant in p54:GetDescendants() do
        toggleInstance(descendant)
    end
end

for _, child in ReplicatedStorage.Assets.Effects.SingleEmit:GetChildren() do
    local Name = child.Name
    local t25 = {}

    for _, child in child:GetChildren() do
        if child:IsA("Attachment") then
            table.insert(t25, child)
        end
    end

    t1.register(Name, t25, child)
end

return t1
--И второй
-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EasySound = require(ReplicatedStorage.Resources.Common.EasySound)
local EmitterUtil = require(ReplicatedStorage.Resources.Universal.EmitterUtil)
local TimescaleUtilities = require(ReplicatedStorage.Resources.Common.TimescaleUtilities)
local t2 = {}
local v1 = Random.new()
local v2 = true

if not RunService:IsServer() then
    local Settings = require(ReplicatedStorage.Client.Modules.Universal.Static.Settings)

    v2 = Settings.Game:Get("HQ Effects")
    Settings.Game:On("HQ Effects", function(p1) -- line: 29
        -- upvalues: v2 (ref)
        v2 = p1
    end)
end

local t1 = {
    manualEmit = function(p2) -- manualEmit | line: 34
        -- upvalues: EasySound (copy), v1 (copy), v2 (ref)
        if not v2 then
            return
        end

        local t3 = {
            "ParticleEmitter",
            "Beam",
            "Trail",
            "Sound"
        }

        for _, v3 in {
                p2,
                unpack(p2:GetDescendants())
            } do
            if table.find(t3, v3.ClassName) then
                local v4 = v3:GetAttribute(if v3:IsA("Sound") then "Delay" else "EmitDelay") or 0
                local v5 = v3:GetAttribute("EmitCount") or 0
                local v6 = v3:GetAttribute("EmitDuration") or 0

                local function emit() -- line: 52
                    -- upvalues: v3 (copy), v5 (copy), v6 (copy), EasySound (copy), v1 (copy)
                    if v3:IsA("ParticleEmitter") then
                        v3:Emit(v5)
                    end

                    if v3:IsA("Sound") then
                        EasySound.Play({
                            soundGroupName = "Towers",
                            destroyOnEnd = true,
                            id = v3.SoundId,
                            parent = v3.Parent,
                            volume = v3.Volume,
                            playbackSpeed = v3.PlaybackSpeed * v1:NextNumber(0.9, 1.1)
                        })
                    elseif v6 > 0 then
                        task.defer(function() -- line: 68
                            -- upvalues: v3 (copy), v6 (copy)
                            v3.Enabled = true
                            task.wait(v6)
                            v3.Enabled = false
                        end)
                    end
                end

                if v4 > 0 then
                    task.delay(v4, emit)
                else
                    emit()
                end
            end
        end
    end,
    register = function(p3, p4) -- register | line: 85
        -- upvalues: t2 (copy)
        local Attachment = Instance.new("Attachment")
        local t4 = {
            originalRadius = 1,
            attachment = Attachment,
            emitters = {},
            emitterData = {},
            soundData = {}
        }

        for _, v7 in p4 do
            local Radius = v7:GetAttribute("Radius")
            local Attachment2 = Instance.new("Attachment")

            Attachment2.CFrame = v7.CFrame

            if Radius then
                t4.originalRadius = Radius
            end

            for _, child in v7:GetChildren() do
                if child:IsA("ParticleEmitter") then
                    local clone = child:Clone()

                    clone.Enabled = false

                    local t5 = {
                        emitter = clone,
                        emitDelay = child:GetAttribute("EmitDelay"),
                        emitDuration = child:GetAttribute("EmitDuration"),
                        emitCount = child:GetAttribute("EmitCount") or 1
                    }

                    clone.Parent = Attachment2
                    table.insert(t4.emitters, clone)
                    table.insert(t4.emitterData, t5)
                elseif child:IsA("Sound") then
                    table.insert(t4.soundData, {
                        sound = child,
                        attachment = Attachment2
                    })
                end
            end

            Attachment2.Parent = Attachment
        end

        Attachment.Name = ("%*Effect"):format(p3)
        Attachment.Parent = workspace.Terrain
        t2[p3] = t4
    end,
    Emit = function(p5, p6, p7, p8, p9, _) -- Emit | line: 132
        -- upvalues: EasySound (copy), EmitterUtil (copy), TimescaleUtilities (copy), t2 (copy), v1 (copy), v2 (ref)
        if not v2 then
            return
        end

        p8 = p8 or 1

        local v9 = t2[p5]

        if not v9 then
            warn("EmitterManager: Emitter " .. p5 .. " does not exist")

            return
        end

        if p7 and v9.originalRadius ~= nil then
            local v10 = p7 / v9.originalRadius

            EmitterUtil:scaleEmitter(v9.emitters, v10, true)
        end

        v9.attachment.WorldCFrame = p6

        for _, v11 in ipairs(v9.emitterData) do
            local v12 = v11.emitCount * p8
            local v13 = v11.emitDuration or 0
            local v14 = v11.emitDelay or 0

            local function runEmitter() -- line: 160
                -- upvalues: v11 (copy), v12 (copy), v13 (copy), TimescaleUtilities (copy)
                v11.emitter:Emit(v12)

                if v13 > 0 then
                    v11.emitter.Enabled = true
                    TimescaleUtilities.Delay(v11.emitDuration, function() -- line: 166
                        -- upvalues: v11 (copy)
                        v11.emitter.Enabled = false
                    end)
                end
            end

            if v14 > 0 then
                TimescaleUtilities.Delay(v11.emitDelay, runEmitter)
            else
                v11.emitter:Emit(v12)

                if v13 > 0 then
                    v11.emitter.Enabled = true
                    TimescaleUtilities.Delay(v11.emitDuration, function() -- line: 166
                        -- upvalues: v11 (copy)
                        v11.emitter.Enabled = false
                    end)
                end
            end
        end

        if p9 or p9 == nil then
            for _, v15 in ipairs(v9.soundData) do
                EasySound.Play({
                    destroyOnEnd = true,
                    audioGroup = "Towers",
                    id = v15.sound.SoundId,
                    parent = v15.attachment,
                    volume = v15.sound.Volume,
                    playbackSpeed = v1:NextNumber(0.9, 1.1)
                })
            end
        end
    end,
    toggle = function(p11, p12, p13) -- toggle | line: 196
        -- upvalues: TimescaleUtilities (copy)
        for _, descendant in p11:GetDescendants() do
            if (not p13 or descendant:IsA(p13)) and (descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail")) then
                local Delay = descendant:GetAttribute("Delay")

                if p12 and Delay and Delay > 0 then
                    TimescaleUtilities.Delay(Delay, function() -- line: 206
                        -- upvalues: p12 (copy), descendant (copy)
                        descendant.Enabled = p12
                    end)
                else
                    descendant.Enabled = p12
                end
            end
        end
    end
}

for _, child in ReplicatedStorage.Assets.Effects.SingleEmit:GetChildren() do
    local Name = child.Name
    local t7 = {}

    for _, child in child:GetChildren() do
        if child:IsA("Attachment") then
            table.insert(t7, child)
        end
    end

    t1.register(Name, t7)
end

return t1
