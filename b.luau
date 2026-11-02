--Это файл называется NPCReplicator, я не смог его вставить в чат так как он слишком длинный. Пришлось сюда. Скажи, пожалуйста, в следующем запросе, это тот скрипт который нам нужен или же нет?

-- https://lua.expert

local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Animation = require(ReplicatedStorage.Shared.Modules.Animation)
local AreaIndicatorStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.AreaIndicatorStore)
local CharmUtil = require(ReplicatedStorage.Shared.Modules.CharmUtil)
local ClientAtoms = require(ReplicatedStorage.Shared.Modules.ClientAtoms)

require(ReplicatedStorage.Client.Modules.Replicators.ClientGameMiddleware)

local DebugController = require(ReplicatedStorage.Client.Controllers.Shared.DebugController)
local EmitterManager = require(ReplicatedStorage.Shared.Modules.EmitterManager)
local HumanoidUtil = require(ReplicatedStorage.Shared.Modules.HumanoidUtil)
local NPCUtils = require(ReplicatedStorage.Shared.Modules.NPCUtils)
local ParticleLODController = require(ReplicatedStorage.Client.Modules.ParticleLODController)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local SpringValue = require(ReplicatedStorage.Client.Interfaces.Hooks.Utility.SpringValue)
local StatusEffectRenderer = require(ReplicatedStorage.Client.Modules.StatusEffects.StatusEffectRenderer)
local TaggedInstances = require(ReplicatedStorage.Shared.Modules.TaggedInstances)
local TimeFieldParticles = require(ReplicatedStorage.Client.Modules.TimeFieldParticles)
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)
local TransientVFX = require(ReplicatedStorage.Client.Modules.TransientVFX)
local TweenService = require(ReplicatedStorage.Client.Modules.TweenService)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local Asset = require(ReplicatedStorage.Shared.Modules.Asset)
local _Enum = require(ReplicatedStorage.Shared.Modules.Enum)
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local LegacyMiddleware = require(ReplicatedStorage.Shared.Modules.LegacyMiddleware)
local Network = require(ReplicatedStorage.Shared.Modules.Network)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local TagReplicator = require(ReplicatedStorage.Client.Modules.TagReplicator)
local t1 = {}

t1.__index = t1

t1.__tostring = function(p1) -- line: 48
    return "NPC_" .. p1.Name
end

local Folder = Instance.new("Folder")

Folder.Name = "NPCs"
Folder.Parent = workspace

for _, v1 in { "Red", "Blue" } do
    local Model = Instance.new("Model")

    Model.Name = v1
    Model.Parent = Folder

    local Highlight = Instance.new("Highlight")

    Highlight.FillTransparency = 1
    Highlight.OutlineTransparency = 0.5
    Highlight.OutlineColor = v1 == "Red" and Color3.fromRGB(255, 71, 71) or Color3.fromRGB(0, 170, 255)
    Highlight.Parent = Model
end

local Enemies, NewEnemies = ReplicatedStorage.Assets.Enemies, ReplicatedStorage.Assets.NewEnemies
local v2 = Random.new()
local t2 = {}
local t3 = {}
local t4 = {}
local t5 = {}

local function scanReplace(p2) -- line: 84
    -- upvalues: ReplicatedStorage (copy), t1 (copy), scanReplace (copy)
    local UnitReplicator = require(ReplicatedStorage.Client.Modules.Replicators.UnitReplicator)

    require(ReplicatedStorage.Shared.Modules.HumanoidUtil)

    for v3, v4 in pairs(p2) do
        if typeof(v4) == "table" then
            scanReplace(v4)
        end

        if typeof(v4) == "Instance" and v4:IsA("Folder") then
            local v5 = t1.GetNPCFromFolder(v4) or UnitReplicator.GetNPCFromFolder(v4)

            if v5 then
                p2[v3] = v5.Model
            end
        end
    end
end

local function lerp(p3, p4, p5) -- line: 104
    return p3 * (1 - p5) + p4 * p5
end

local Gizmo = DebugController.Gizmo

DebugController.createGizmo("Enemy Hitboxes", function() -- line: 110
    -- upvalues: t4 (copy), Gizmo (copy)
    Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(255, 141, 141))

    for _, v6 in t4 do
        if v6.Type ~= "Units" then
            Gizmo.Box:Draw(v6.Hitbox.CFrame, v6.Hitbox.Size, false)
        end
    end
end)
DebugController.createGizmo("Unit Hitboxes", function() -- line: 120
    -- upvalues: t4 (copy), Gizmo (copy)
    Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(141, 166, 255))

    for _, v7 in t4 do
        if v7.Type == "Units" then
            Gizmo.Box:Draw(v7.Hitbox.CFrame, v7.Hitbox.Size, false)
        end
    end
end)
Network.Channel("Replicate"):On("NPCInstance", function(p6) -- line: 130
    -- upvalues: t3 (copy), scanReplace (copy)
    for _, v8 in p6 do
        task.spawn(function() -- line: 132
            -- upvalues: v8 (copy), t3 (copy), scanReplace (copy)
            local v9 = v8[2]
            local v10 = v8[1]
            local t6 = { unpack(v8, 3) }
            local v11 = t3[v9]

            if not v11 then
                return
            end

            scanReplace(t6)

            if not v11.Executables[v10] then
                warn("NPC " .. v11.Name .. " has no executable " .. v10)
            else
                v11.Executables[v10](unpack(t6))
            end
        end)
    end
end)

function t1.new(p7, p8) -- line: 155
    -- upvalues: CollectionService (copy), ReplicatedStorage (copy), CharmUtil (copy), ClientAtoms (copy), HumanoidUtil (copy), NPCUtils (copy), ParticleLODController (copy), SpringValue (copy), StatusEffectRenderer (copy), TaggedInstances (copy), TimeFieldParticles (copy), TimescaleUtilities (copy), TweenService (copy), Upgrades (copy), Asset (copy), GameState (copy), Maid (copy), Signal (copy), TagReplicator (copy), t1 (copy), Folder (copy), Enemies (copy), NewEnemies (copy), v2 (copy), t2 (copy), t3 (copy), t4 (copy), t5 (copy)
    local v12 = p8.Folder:WaitForChild("StatusEffects", 5)

    if not v12 then
        return
    end

    local NewEnemies2 = Asset("NewEnemies", p8:WaitForState("ModelName"))
    local Animator = NewEnemies2.Animator
    local Legacy = p8:Get("Legacy")
    local ModelName = p8:WaitForState("ModelName")
    local EnemySkinName = p8:Get("EnemySkinName")
    local v13 = GameState.NewGameModes and not Legacy
    local v14 = (v13 and NewEnemies or Enemies):FindFirstChild(ModelName)

    if Legacy then
        v14 = (v13 and NewEnemies or Enemies):FindFirstChild((("%* Legacy"):format(ModelName))) or v14
    end

    assert(v14, "Enemy model " .. ModelName .. " does not exist.")

    local v16 = {}
    local v17 = Animator and setmetatable(Animator, t1) or t1
    local v18 = setmetatable(v16, v17)

    v18.Maid = Maid.new()
    Legacy = p8:Get("HasNewModel") == true

    local v19

    if EnemySkinName then
        v19 = v14[EnemySkinName]
    else
        local v20 = false

        if Legacy and v14:FindFirstChild("NewModel") then
            Animator = v14.NewModel

            if Animator then
                v19 = Animator
                v20 = true
            end
        end

        if not v20 then
            v19 = v14.Model
        end
    end

    v18.FBXModel = HumanoidUtil.findFirstRigBone(v19)
    v18.Model = v19:Clone()
    v18.Model.Name = ("%*Enemy"):format(ModelName)
    v18.Maid:Mark(TimeFieldParticles.track(v18.Model))
    v18.BoneVFX = v18.Model:FindFirstChild("BoneVFX")

    local v21

    v21, v16 = HumanoidUtil.createAnimationHost(v18.Model, v18.FBXModel ~= nil)
    v18.AnimationController = v21
    v18.AnimationAnimator = v16
    v18.BaseScale = v18.Model:GetScale()
    v18.StateScale = p8:Get("Scale") or 1

    if v18.StateScale ~= 1 then
        v18.Model:ScaleTo(v18.StateScale * v18.BaseScale)
    end

    v18.Model.PrimaryPart.Anchored = true
    v18.PrimaryPart = v18.Model.PrimaryPart
    v18.HumanoidRootPart = v18.Model.PrimaryPart
    v18.OnDestroy = Signal.new()
    v18.Tagged = TaggedInstances.getTaggedInstances(v18.Model)
    v14 = v18.Model:GetExtentsSize()
    v21 = NPCUtils.getExtentsSize(v18.Model, NewEnemies2.Stats.HitboxIgnoredParts)
    ModelName = (v21.X + v21.Z) / 3
    v18.Height = v14.Y / 2
    v18.HeightYOffset = 0
    v18.RenderRadius = v14.Magnitude / 2

    if v18.Model:FindFirstChild("Hitbox") then
        v18.Hitbox = v18.Model.Hitbox
    else
        v21 = Instance.new("Part")
        v21.Name = "Hitbox"
        v21.Anchored = false
        v21.CanCollide = false
        v21.CanTouch = false
        v21.CanQuery = true
        v21.Transparency = 1
        v17 = math.abs(v18.PrimaryPart.Node.Position.Y) * 2
        v21.Size = Vector3.new(ModelName, v17, ModelName)
        v21.CFrame = v18.Model:GetPivot()
        v21.Parent = v18.Model
        v18.Hitbox = v21
        CollectionService:AddTag(v21, "NPCHitbox")
    end

    v14 = Instance.new("WeldConstraint")
    v14.Part0 = v18.Model.PrimaryPart
    v14.Part1 = v18.Hitbox
    v14.Parent = v18.Model.PrimaryPart
    v14 = v18.Model:FindFirstChild("Death")

    if v14 then
        v21 = v14:FindFirstChild("Death")

        if v21 and v21:IsA("Sound") then
            v21.PlaybackSpeed = Random.new():NextNumber(0.8, 1.2) * v21.PlaybackSpeed
            v18.Model.Head.Death.PlayOnRemove = true
        end
    end

    v18.Type = p8:WaitForState("Type")
    v18.Upgrade = p8:Get("Upgrade") or 0

    if v18.Type == "Units" and v18.Model:FindFirstChild("UpgradesModule") then
        v21 = v18.Upgrade

        for i = 1, v21 do
            Upgrades.upgrade(v18, i, "unit")
        end
    end

    v18.FolderPointer = Instance.new("ObjectValue")
    v18.FolderPointer.Name = "RootPointer"
    v18.FolderPointer.Value = p7
    v18.FolderPointer.Parent = v18.Model
    v18.ShouldLoop = p8:Get("ShouldLoop")
    v18.ScalePositionOffset = Vector3.new(1, 1, 1)
    v18.PositionOffset = -v18.PrimaryPart.Node.Position
    v18.PositionOffsetScaleBaseline = v18.Model:GetScale()
    v18.AdditiveOffset = p8:Get("PositionOffset")
    v18.DisableSpawnTween = p8:Get("DisableSpawnTween")
    v18.EntityId = p8:Get("ID")
    v18.ForcePosition = p8:Get("ForcePosition")
    v18._forcePositionChanged = v18.ForcePosition ~= nil
    v18.Maid:Mark(p8:GetStateChangedSignal("ForcePosition"):Connect(function(p9) -- line: 280
        -- upvalues: p8 (copy), v18 (copy)
        v18.ForcePosition = p9
        v18._forcePositionChanged = true

        if p9 == nil then
            v18.PathDistance = p8:Get("PathDistance") or v18.PathDistance
        end
    end))
    v18.Team = p8:WaitForState("Team")
    v14 = p8:WaitForState("PathName")
    v21 = p8:WaitForState("PathTeam")
    v18.PathName = v14
    v18.PathTeam = tostring(v21)
    v18.UpdateScale = false
    v18.ScaleSpring = SpringValue.new(1, 5, 0.5)
    v18.ControllerStats = NewEnemies2.Stats.ControllerStats
    v18.Stats = NewEnemies2.Stats
    v18.IntroPathName = p8:Get("IntroPathName")

    if v18.IntroPathName then
        v18.IntroPath = GameState.Paths[v18.PathTeam][v18.IntroPathName]
        v18.IntroDone = false
    end

    Legacy = GameState.Paths[v18.PathTeam][tonumber(v14)] or GameState.Paths[v18.PathTeam][v14]
    v18.Path = Legacy

    if not t5[Legacy] then
        t5[Legacy] = {}
    end

    t5[Legacy][v18] = true
    v18.Replicator = p8
    v18.PathDistance = p8:Get("PathDistance") or 0
    v18.LastPathDistance = v18.PathDistance

    if v18.Path then
        v16 = function() -- line: 323
            -- upvalues: v18 (copy)
            local Scalar = v18.Path:GetScalar(v18.PathDistance)

            v18.Model:PivotTo(CFrame.new(Scalar))
            v18.Position = Scalar
        end

        pcall(v16)
    end

    v18.Model.Parent = Folder
    NPCUtils.configureModelParts(v18.Model)
    Legacy = v18.Model:GetExtentsSize().Magnitude

    if ReplicatedStorage.State.Mode.Value == "DefendTheCenter" or ReplicatedStorage.State.Mode.Value == "Duck Hunt" then
        Animator = 0
    else
        v16 = (15 - Legacy) / 15
        Animator = math.clamp(v16, 0, 1)
    end

    if v18.Type ~= "Units" then
        local v23 = ReplicatedStorage.Assets.Effects.Mob.DeathEffect:Clone()

        v18.Effect = v23
        v18.Particles = {}

        local Head = v18.Model:FindFirstChild("Head") or v18.Model:FindFirstChild("Torso") or v18.Model.PrimaryPart

        v21 = v18.Model:FindFirstChild("Torso") or Head

        if v18.HumanoidRootPart:FindFirstChild("DeathParticle") then
            for _, child in pairs(v18.HumanoidRootPart.DeathParticle:GetChildren()) do
                local clone = child:Clone()

                clone.Parent = v23.MainAttachment
                table.insert(v18.Particles, clone)
            end
        else
            for _, child in pairs(v23.MainAttachment:GetChildren()) do
                table.insert(v18.Particles, child)
                child.Enabled = false

                if child.Name == "Chunks2" then
                    child.Color = ColorSequence.new(v21.Color)
                else
                    child.Color = ColorSequence.new(Head.Color)
                end
            end
        end
    end

    v18.PathOffset = p8:Get("PathOffset") or v2:NextNumber(-Animator, Animator)
    v18.Lifespan = p8:Get("Lifespan")
    v18.Health = p8:WaitForState("Health")
    v18.MaxHealth = p8:WaitForState("MaxHealth")
    v18.Shield = p8:Get("Shield") or 0
    v18.MaxShield = p8:Get("MaxShield") or 0
    v18.Replicator:GetStateChangedSignal("Health"):Connect(function(p10) -- line: 380
        -- upvalues: v18 (copy)
        v18.Health = p10
    end)
    v18.Replicator:GetStateChangedSignal("Shield"):Connect(function(p11) -- line: 383
        -- upvalues: v18 (copy)
        v18.Shield = p11
    end)
    v18.Replicator:GetStateChangedSignal("MaxHealth"):Connect(function(p12) -- line: 386
        -- upvalues: v18 (copy)
        v18.MaxHealth = p12
    end)
    v18.Replicator:GetStateChangedSignal("Scale"):Connect(function(p13) -- line: 389
        -- upvalues: v18 (copy)
        v18.StateScale = p13 or 1

        local Value = v18.ScaleSpring:GetValue()

        if not v18.FBXModel then
            v18.Model:ScaleTo(v18.BaseScale * v18.StateScale * Value)
            v18.RenderRadius = v18.Model:GetExtentsSize().Magnitude / 2
        end

        v18.ScalePositionOffset = Vector3.new(1, Value, 1)
    end)
    v18.BaseSpeed = p8:WaitForState("BaseSpeed")
    v18.SpeedLerp = p8:Get("SpeedLerp")
    v18.Speed = p8:WaitForState("Speed")
    v18.NewSpeed = v18.Speed
    v18.ForceSpeed = p8:Get("ForceSpeed") or 0
    v18.FakeUnit = p8:Get("FakeUnit") == true
    v18.Replicator:GetStateChangedSignal("FakeUnit"):Connect(function(p14) -- line: 406
        -- upvalues: v18 (copy), TimescaleUtilities (copy)
        v18.FakeUnit = p14

        if v18.FakeUnit then
            v18.Type = "Units"
            TimescaleUtilities.Delay(0.1, function() -- line: 411
                -- upvalues: v18 (copy)
                for _, v24 in v18.AnimationAnimator:GetPlayingAnimationTracks() do
                    if v24.Name:lower():sub(1, 4) ~= "walk" then
                        v24:Stop()
                        v24:Destroy()
                    end
                end
            end)
        end
    end)
    v18.TimeScaled = p8:Get("TimeScaled")
    v18.Replicator:GetStateChangedSignal("TimeScaled"):Connect(function(p15) -- line: 425
        -- upvalues: v18 (copy)
        v18.TimeScaled = p15
    end)
    v18.Reverse = p8:Get("Reverse")
    v18.Replicator:GetStateChangedSignal("Reverse"):Connect(function(p16) -- line: 430
        -- upvalues: v18 (copy)
        v18.Reverse = p16
    end)
    v18.Replicator:GetStateChangedSignal("SpeedLerp"):Connect(function(p17) -- line: 434
        -- upvalues: v18 (copy)
        v18.SpeedLerp = p17
    end)
    v18.Replicator:GetStateChangedSignal("Speed"):Connect(function(p18) -- line: 438
        -- upvalues: v18 (copy)
        if v18.Speed ~= p18 then
            v18.Speed = p18
            v18._pendingAdjustWalkSpeed = true
        end

        v18.NewSpeed = p18
    end)
    v18.Replicator:GetStateChangedSignal("ForceSpeed"):Connect(function(p19) -- line: 450
        -- upvalues: v18 (copy)
        v18.ForceSpeed = p19
    end)
    v18.Replicator:GetStateChangedSignal("Lifespan"):Connect(function(p20) -- line: 453
        -- upvalues: v18 (copy)
        v18.Lifespan = p20
    end)
    v18.Replicator:GetStateChangedSignal("PathDistance"):Connect(function(p21) -- line: 457
        -- upvalues: v18 (copy)
        local v25 = v18.NewSpeed == 0
        local v26 = if not v25 then math.abs(v18.PathDistance - p21) > 0.5 else nil

        if v25 or v26 then
            v18.PathDistance = p21
        end
    end)
    v18.TimeScaleChanged = GameState.Replicator:GetStateChangedSignal("TimeScale"):Connect(function(p22) -- line: 467
        -- upvalues: v18 (copy)
        v18:AdjustWalkSpeed(p22)
    end)
    task.defer(function() -- line: 472
        -- upvalues: v18 (copy), Folder (copy)
        while v18.Model.Parent ~= Folder do
            task.wait()
        end

        if not v18.Model.Animations:FindFirstChild("Walk") then
            return
        end

        local v28 = if v18.Model.Animations.Walk:IsA("Folder") then v18.Model.Animations.Walk:GetChildren()[math.random(1, #v18.Model.Animations.Walk:GetChildren())] else v18.Model.Animations.Walk
        local RageWalk = v18.Model.Animations:FindFirstChild("RageWalk")

        v18.RageWalkAnimation = RageWalk and v18.AnimationAnimator:LoadAnimation(RageWalk)

        local track = v18.AnimationAnimator:LoadAnimation(v28)
        local AnimSpeed = v18.PrimaryPart:FindFirstChild("AnimSpeed")
        local Speed = v28:GetAttribute("Speed")

        v18.WalkAnimSpeed = (AnimSpeed and AnimSpeed.Value or Speed or 1) * (v18.Stats.WalkAnimationSpeed or 1)
        v18.WalkTrack = track

        while v18.WalkTrack.Length == 0 do
            task.wait()
        end

        v18:AdjustWalkSpeed()
    end)

    Animator = function() -- line: 515
        -- upvalues: v18 (copy)
        local v30 = true

        if v18.AnimationsFrozen then
        elseif v18.RageWalkAnimation then
            if v18.WalkTrack then
                v18.WalkTrack:Stop(0)
            end

            v30 = false
        end

        if v30 then
            return
        end

        v18.WalkTrack = v18.RageWalkAnimation
        v18.WalkTrack:Play()
        v18:AdjustWalkSpeed()
    end

    v18.Replicator:GetStateChangedSignal("RageWalk"):Connect(Animator)

    if v18.Replicator:Get("RageWalk") and not v18.AnimationsFrozen and v18.RageWalkAnimation then
        if v18.WalkTrack then
            v18.WalkTrack:Stop(0)
        end

        v18.WalkTrack = v18.RageWalkAnimation
        v18.WalkTrack:Play()
        v18:AdjustWalkSpeed()
    end

    v18._onStepFunctions = {}
    v18.Maid:Mark(function() -- line: 534
        -- upvalues: v18 (copy), t5 (copy)
        table.clear(v18._onStepFunctions)

        local Path = v18.Path
        local v31 = t5[Path]

        if v31 then
            v31[v18] = nil

            if not next(v31) then
                t5[Path] = nil
            end
        end
    end)

    v16 = function() -- line: 550
        -- upvalues: v18 (copy)
        local v32 = v18.Path:GetScalar(v18.PathDistance) + Vector3.new(0, v18.PositionOffset.Y, 0)

        v18.Model:PivotTo(CFrame.new(v32))
    end

    pcall(v16)
    v18.Stopped = p8:Get("Stopped")
    v18.Replicator:GetStateChangedSignal("Stopped"):Connect(function(p23) -- line: 557
        -- upvalues: v18 (copy)
        v18.Stopped = p23
    end)
    v18.OwnerName = p8:Get("OwnerName")
    v18.Defense = p8:Get("Defense")
    v18.Replicator:GetStateChangedSignal("Defense"):Connect(function(p24) -- line: 563
        -- upvalues: v18 (copy)
        v18.Defense = p24
    end)
    v18.Name = p8:Get("DisplayName") or p8:Get("ModelName")
    v18.Replicator:GetStateChangedSignal("DisplayName"):Connect(function(p25) -- line: 568
        -- upvalues: v18 (copy)
        v18.Name = p25
    end)
    v18.Modifiers = TagReplicator.getReplicatorEntityFromFolder(v12)
    v18.Maid:Mark(v18.Modifiers)
    v18.StatusEffectRenderer = StatusEffectRenderer.new(v18, v12, v18.Modifiers)
    v18.Maid:Mark(v18.StatusEffectRenderer)
    t4[v18.Model] = v18
    t3[p7] = v18
    table.insert(t2, v18)
    ParticleLODController.registerModel(v18.Model, function() -- line: 583
        -- upvalues: v18 (copy)
        return v18.Model.PrimaryPart and v18.Model.PrimaryPart.Position or Vector3.new(0, 0, 0)
    end)
    v18.Maid:Mark(function() -- line: 587
        -- upvalues: v18 (copy), t2 (copy)
        local v33 = table.find(t2, v18)

        if v33 then
            table.remove(t2, v33)
        end
    end)
    v18.Maid:Mark(function() -- line: 594
        -- upvalues: p7 (copy), t3 (copy)
        t3[p7] = nil
    end)
    v18.Maid:Mark(function() -- line: 598
        -- upvalues: v18 (copy), ParticleLODController (copy), t4 (copy)
        ParticleLODController.unregisterModel(v18.Model)
        t4[v18.Model] = nil
        v18.Model:Destroy()
    end)

    if v18.Initialize then
        v18:Initialize()
    end

    task.delay(0, function() -- line: 608
        -- upvalues: p7 (copy), v18 (copy)
        local v34 = p7:WaitForChild("LayeredHats", 1)

        if v34 then
            for _, child in pairs(v34:GetChildren()) do
                v18:EquipHat(child.Value, true, not child.Value:GetAttribute("NoLayer"))
            end
        end
    end)

    if not v18.Executables then
        v18.Executables = {}
    end

    v18.Executables.LegacyFace = function(p26, p27) -- line: 622
        -- upvalues: v18 (copy), TweenService (copy)
        local HumanoidRootPart = v18.HumanoidRootPart

        if p27 then
            TweenService:Create(HumanoidRootPart, p27, {
                CFrame = CFrame.new(HumanoidRootPart.CFrame.Position, (Vector3.new(p26.X, HumanoidRootPart.Position.Y, p26.Z)))
            }):Play()
        else
            HumanoidRootPart.CFrame = CFrame.new(HumanoidRootPart.CFrame.Position, (Vector3.new(p26.X, HumanoidRootPart.Position.Y, p26.Z)))
        end
    end

    if v18.FakeUnit then
        v18.Type = "Units"
    end

    ClientAtoms.enemyReplicators(function(p28) -- line: 644
        -- upvalues: p7 (copy), v18 (copy), CharmUtil (copy)
        return CharmUtil.set(p28, p7, v18)
    end)
    v18.Maid:Mark(function() -- line: 648
        -- upvalues: p7 (copy), CharmUtil (copy), ClientAtoms (copy)
        ClientAtoms.enemyReplicators(function(p29) -- line: 649
            -- upvalues: p7 (copy), CharmUtil (copy)
            return CharmUtil.deleteKey(p29, p7)
        end)
    end)

    return v18
end

function t1.SetWalkAnimation(p30, p31) -- line: 657
    if p30.AnimationsFrozen then
        return
    end

    local v35 = p30.Model.Animations:FindFirstChild(p31)

    if v35 then
        p30.WalkTrack:Stop(0)
        p30.WalkTrack = p30.AnimationAnimator:LoadAnimation(v35)
        p30.WalkTrack:Play()
        p30:AdjustWalkSpeed()
    end
end

function t1.LoadAnimations(p32) -- line: 673
    -- upvalues: Animation (copy)
    p32._animations = {}

    for _, child in p32.Model:WaitForChild("Animations"):GetChildren() do
        if child:IsA("Animation") and child.Name ~= "Walk" then
            p32._animations[child.Name] = Animation.new({
                IsPersistent = true,
                IgnorePriority = true,
                Preload = true,
                Track = child,
                Target = p32.AnimationAnimator,
                Entity = p32
            })
        end
    end
end

function t1.PlayAnimation(p33, p34, p35) -- line: 689
    if not p33.AnimationsFrozen then
        p33._animations[p34]:Play(p35)
    end
end

function t1.StopAnimation(p36, p37) -- line: 697
    p36._animations[p37]:Stop()
end

function t1.WaitForAnimationFrame(p38, p39, p40) -- line: 701
    return p38._animations[p39].Controller:GetMarkerReachedSignal(p40):Wait()
end

function t1.SetYHeight(p41, p42) -- line: 705
    p41.HeightYOffset = p42
end

function t1.AnimateYOffset(p43, p44, p45) -- line: 709
    -- upvalues: RunService (copy), TweenService (copy)
    local HeightYOffset = p43.HeightYOffset
    local n1 = 0
    local connection

    connection = RunService.Heartbeat:Connect(function(p46) -- line: 716
        -- upvalues: p43 (copy), p44 (copy), p45 (copy), HeightYOffset (copy), n1 (ref), connection (ref), TweenService (copy)
        n1 += p46 / (p45 and p45.Time or 0.5)

        local Value = TweenService:GetValue(n1, p45.EasingStyle, p45.EasingDirection)

        p43.HeightYOffset = HeightYOffset * (1 - Value) + p44 * Value

        if not (n1 >= 1) then
            return
        end

        p43.HeightYOffset = p44
        connection:Disconnect()
    end)
end

function t1.IsAlive(p47) -- line: 729
    if p47.Health > 0 then
        return p47.Maid ~= nil
    end

    return false
end

function t1.GetNPCFromFolder(p48) -- line: 733
    -- upvalues: t3 (copy)
    return t3[p48]
end

function t1.GetNPCFromModel(p49) -- line: 737
    -- upvalues: t4 (copy)
    return t4[p49]
end

function t1.Wait(_, p51) -- line: 741
    -- upvalues: TimescaleUtilities (copy)
    return TimescaleUtilities.Wait(p51)
end

function t1.Delay(_, p53, p54) -- line: 745
    -- upvalues: TimescaleUtilities (copy)
    if p54 then
        return TimescaleUtilities.Delay(p53, p54)
    end

    return TimescaleUtilities.Wait(p53)
end

function t1.Tween(p55, p56, p57, p58) -- line: 754
    -- upvalues: TweenService (copy), GameState (copy)
    local TimeScale = p55.TimeScaled and GameState.TimeScale or 1

    return TweenService:Create(p56, TweenInfo.new(p57.Time / TimeScale, p57.EasingStyle, p57.EasingDirection, p57.RepeatCount, p57.Reverses, p57.DelayTime / TimeScale), p58)
end

function t1.SetWalkAnimationSpeed(p59, p60) -- line: 769
    p59.WalkAnimSpeed = p60
    p59:AdjustWalkSpeed()
end

function t1.AdjustWalkSpeed(p61, p62) -- line: 774
    -- upvalues: GameState (copy), v2 (copy)
    if p61.AnimationsFrozen then
        if p61.WalkTrack then
            p61.WalkTrack:AdjustSpeed(0)
            p61.WalkTrack:SetAttribute("Speed", 0)
        end
    else
        local v39 = p62 or GameState.TimeScale

        if not p61.TimeScaled then
            v39 = 1
        end

        if p61.WalkTrack then
            if not p61.WalkTrack.IsPlaying then
                p61.WalkTrack:Play()
                task.defer(function() -- line: 799
                    -- upvalues: p61 (copy), v2 (copy)
                    p61.WalkTrack.TimePosition = v2:NextNumber(0, p61.WalkTrack.Length)
                end)
            end

            local v40 = p61.Speed / (p61.WalkTrack.Length * 2.7) * p61.WalkAnimSpeed

            p61.WalkTrack:AdjustSpeed(v40 * v39)
        end
    end
end

local function findHeadBone(p63) -- line: 810
    local descendant

    for _, descendant2 in p63:GetDescendants() do
        if descendant2:IsA("Bone") and not descendant2:FindFirstAncestor("BoneVFX") then
            local v41 = string.lower(descendant2.Name)

            if v41 == "head" then
                return descendant2
            end

            if not descendant and string.find(v41, "head", 1, true) then
                descendant = descendant2
            end
        end
    end

    return descendant
end

function t1.EquipBoneHat(p64, p65, p66, p67) -- line: 828
    local v42 = if p65:IsA("BasePart") then p65 else p65.PrimaryPart
    local BasePart = p66:FindFirstAncestorWhichIsA("BasePart")

    if v42 and BasePart then
        p64.FBXHeadHeight = p64.FBXHeadHeight or p64.Model:GetExtentsSize().Y * 0.2 / p64.Model:GetScale()

        local v43 = p64.FBXHeadHeight * p64.Model:GetScale()

        if p67 then
            local v44 = v43 / 0.5709999799728394

            if p65:IsA("BasePart") then
                p65.Size *= v44
            else
                p65:ScaleTo(p65:GetScale() * v44)
            end
        end

        local TransformedWorldCFrame = p66.TransformedWorldCFrame
        local v45 = TransformedWorldCFrame:ToObjectSpace((BasePart.CFrame.Rotation + TransformedWorldCFrame.Position + BasePart.CFrame.UpVector * v43 * 0.9) * v42.CFrame:ToObjectSpace(p65:GetPivot()):Inverse())
        local v46 = if p65:IsA("BasePart") then { p65 } else p65:GetDescendants()

        for _, v47 in v46 do
            if v47:IsA("BasePart") then
                v47.Anchored = false
                v47.CanCollide = false
                v47.Massless = true
            end
        end

        local Weld = Instance.new("Weld")

        Weld.Part0 = BasePart
        Weld.Part1 = v42
        Weld.C0 = BasePart.CFrame:ToObjectSpace(TransformedWorldCFrame * v45)
        Weld.Parent = v42
        p65.Parent = p64.Model
        p64.BoneHats = p64.BoneHats or {}
        table.insert(p64.BoneHats, {
            weld = Weld,
            bone = p66,
            offset = v45,
            scale = p64.Model:GetScale()
        })

        return true
    end

    p65:Destroy()

    return false
end

function t1.UpdateBoneHats(p68) -- line: 882
    local Scale = p68.Model:GetScale()

    for i = #p68.BoneHats, 1, -1 do
        local v48 = p68.BoneHats[i]
        local Part0 = v48.weld.Part0

        if v48.weld.Parent and Part0 then
            local offset = v48.offset

            if Scale ~= v48.scale then
                offset = offset.Rotation + offset.Position * (Scale / v48.scale)
            end

            v48.weld.C0 = Part0.CFrame:ToObjectSpace(v48.bone.TransformedWorldCFrame * offset)
        else
            table.remove(p68.BoneHats, i)
        end
    end

    if #p68.BoneHats == 0 then
        p68.BoneHats = nil
    end
end

function t1.EquipHat(p69, p70, p71, p72) -- line: 902
    -- upvalues: findHeadBone (copy)
    if p69.Hat and not p72 then
        p69.Hat:Destroy()
    end

    local v49 = if p69.FBXModel then findHeadBone(p69.Model) else nil

    if v49 then
        local clone = p70:Clone()

        if p69:EquipBoneHat(clone, v49, p71) and not p72 then
            p69.Hat = clone
        end
    else
        local Head = p69.Model:FindFirstChild("Head")

        if Head then
            local clone = p70:Clone()

            clone:PivotTo(Head.CFrame * CFrame.new(0, Head.Size.Y * 0.49, 0))

            if p71 then
                local v50 = math.max(Head.Size.X, Head.Size.Y, Head.Size.Z) / 0.5709999799728394

                clone.Size *= v50
            end

            clone.Parent = Head.Parent

            local WeldConstraint = Instance.new("WeldConstraint")

            WeldConstraint.Part0 = Head
            WeldConstraint.Part1 = clone
            WeldConstraint.Parent = clone

            if not p72 then
                p69.Hat = clone
            end
        end
    end
end

function t1.RefreshAllNPCsByPath(p73, p74, p75) -- line: 939
    -- upvalues: t5 (copy)
    if t5[p73] then
        for v51, _ in t5[p73] do
            if v51:IsAlive() and v51.PathDistance <= (p74 or 1e999) then
                v51:RefreshPath(nil, p75, p75)
            end
        end
    end
end

function t1.RefreshPath(p76, p77, p78, p79) -- line: 951
    -- upvalues: EmitterManager (copy), GameState (copy), t5 (copy)
    local Path = p76.Path

    t5[Path][p76] = nil

    if not next(t5[Path]) then
        t5[Path] = nil
    end

    p76.Path = GameState.Paths[p76.PathTeam][p76.PathName] or GameState.Paths[p76.PathTeam][tonumber(p76.PathName)]

    if not t5[p76.Path] then
        t5[p76.Path] = {}
    end

    t5[p76.Path][p76] = true

    if not p79 then
        EmitterManager.Emit(p77 or "SnowExplosion", CFrame.new(p76.Position))

        if not p78 then
            p76.PathDistance /= 2
        end
    end

    p76.DistanceToEnd = p76.Path:GetDistanceToEnd(p76.PathDistance)
    p76.Position = p76.Path:GetScalar(p76.PathDistance)
    task.delay(0, function() -- line: 979
        -- upvalues: p76 (copy), p77 (copy), p79 (copy), EmitterManager (copy)
        if not p79 then
            EmitterManager.Emit(p77 or "SnowExplosion", CFrame.new(p76.Position))
        end
    end)
end

function t1.ScaleBy(p80, p81, p82, p83) -- line: 987
    if p80.Model:FindFirstChild("Head") and p80.Model.Head:FindFirstChild("Death") then
        p80.Model.Head.Death.PlaybackSpeed /= p81
    end

    if p80.FBXModel then
        local v54 = p81 * p80.PositionOffsetScaleBaseline

        p80.Model:ScaleTo(v54)
        p80.ScalePositionOffset = Vector3.new(1, p81, 1)
    else
        if p82 then
            p80.ScaleSpring:SetSpeed(p82)
        end

        if p83 then
            p80.ScaleSpring:SetDamper(p83)
        end

        p80.ScaleSpring:SetGoal(p81)
        p80.UpdateScale = true
    end
end

function t1.BindToStep(p84, p85, p86) -- line: 1012
    p84._onStepFunctions[p85] = p86
end

function t1.Destroy(p87) -- line: 1016
    -- upvalues: SoundService (copy), TransientVFX (copy)
    if p87.TimeScaleChanged then
        p87.TimeScaleChanged:Disconnect()
        p87.TimeScaleChanged = nil
    end

    if p87.Maid then
        if p87.Type ~= "Units" then
            debug.profilebegin("VFX_NPCDeathEffectEmit")
            p87.Effect.Parent = workspace.Trash
            p87.Effect:PivotTo(CFrame.new(p87.Model:FindFirstChild("Head") and p87.Model.Head.Position or p87.Model.PrimaryPart.Position))
            TransientVFX.track(p87.Effect, {
                ttl = 3,
                profileName = "NPCDeathEffect"
            })

            for _, v55 in pairs(p87.Particles) do
                v55:Emit(v55:GetAttribute("EmitCount") or 7)
            end

            local v56 = p87.Model:FindFirstChild("HumanoidRootPart") and p87.HumanoidRootPart:FindFirstChild("DeathEffect")

            if v56 then
                local clone = v56:Clone()
                local WorldPosition = clone.WorldPosition

                clone.Parent = workspace.Trash
                clone.WorldPosition = WorldPosition

                local n2 = 0

                for _, descendant in pairs(clone:GetDescendants()) do
                    if descendant:IsA("ParticleEmitter") then
                        n2 = math.max(n2, descendant.Lifetime.Max)
                        descendant:Emit(tonumber(descendant:GetAttribute("EmitCount")) or 1)
                    elseif descendant:IsA("Sound") then
                        SoundService:PlayLocalSound(descendant)
                    end
                end

                TransientVFX.track(clone, {
                    profileName = "NPCDeathAttachment",
                    ttl = n2 + 1
                })
            end

            debug.profileend()
        end

        p87.OnDestroy:Fire()
        p87.Maid:Sweep()
        p87.Maid = nil
    end
end

function t1.Step(p88, p89) -- line: 1070
    for _, v57 in p88._onStepFunctions do
        v57(p89)
    end
end

function t1.GetLookCFrame(p90) -- line: 1076
    return p90.Model.PrimaryPart.CFrame
end

function t1.Face(p91, p92, p93, _) -- line: 1080
    -- upvalues: TweenService (copy)
    local PrimaryPart = p91.Model.PrimaryPart
    local v58 = CFrame.lookAt(PrimaryPart.Position, (Vector3.new(p92.X, PrimaryPart.Position.Y, p92.Z)))

    p91.Rotation = CFrame.new() * v58.Rotation

    if p93 then
        TweenService:Create(PrimaryPart, p93, {
            CFrame = v58
        }):Play()

        return v58
    end

    PrimaryPart.CFrame = v58

    return v58
end

function t1.CreateAreaIndicator(_, p96) -- line: 1100
    -- upvalues: HttpService (copy), AreaIndicatorStore (copy), TimescaleUtilities (copy)
    local v59 = HttpService:GenerateGUID(false)

    AreaIndicatorStore.create(v59, {
        type = p96.angle < 360 and "normal" or "full",
        radius = p96.radius,
        initialAngle = p96.angle < 360 and 0,
        desiredAngle = p96.angle < 360 and p96.angle,
        color3 = p96.color or Color3.fromRGB(255, 0, 64),
        cframe = p96.angle < 360 and p96.cframe,
        position = p96.angle == 360 and p96.cframe.Position,
        tweenInfo = TweenInfo.new(0.25),
        lifeTime = p96.openTime
    })
    TimescaleUtilities.Delay(p96.openTime + 1, function() -- line: 1113
        -- upvalues: v59 (copy), AreaIndicatorStore (copy)
        AreaIndicatorStore.remove(v59)
    end)

    return v59
end

function t1.StepPath(p97, p98) -- line: 1120
    -- upvalues: ReplicatedStorage (copy), GameState (copy), v2 (copy)
    if p97.Replicator.Folder:IsDescendantOf(ReplicatedStorage) then
        if not p97.PathDistance then
            p97.PathDistance = 0
        end

        debug.profilebegin("NPCUpdate")

        if not (p97.ForcePosition or p97.Stopped and not p97.ForceSpeed) then
            local Speed = not p97.Stopped and p97.Speed or 0

            if p97.Reverse then
                p97.PathDistance += p98 * (-Speed + p97.ForceSpeed)
            else
                p97.PathDistance += p98 * (Speed + p97.ForceSpeed)
            end

            if not p97.IntroPath or p97.IntroDone then
                if p97.Reverse then
                    if p97.PathDistance <= 0 and p97.ShouldLoop then
                        p97.PathDistance += p97.Path.PathDistance
                    end
                elseif p97.PathDistance >= p97.Path.PathDistance and p97.ShouldLoop then
                    p97.PathDistance -= p97.Path.PathDistance
                end
            elseif p97.PathDistance >= p97.IntroPath.PathDistance then
                p97.PathDistance -= p97.IntroPath.PathDistance
                p97.IntroDone = true
            end
        end

        debug.profilebegin("AdditiveOffset")

        if p97.AdditiveOffset and not p97.DisableSpawnTween then
            p97.AdditiveOffset = p97.AdditiveOffset:Lerp(Vector3.new(), p98 * p97.Speed)
        end

        debug.profileend()

        if p97:IsAlive() and p97.UpdateScale then
            local v60 = p97.ScaleSpring:Update(p98)
            local Value = p97.ScaleSpring:GetValue()
            local v61 = p97.BaseScale * p97.StateScale * Value

            if not p97.FBXModel then
                p97._pendingScale = v61
            end

            p97.ScalePositionOffset = Vector3.new(1, Value, 1)
            p97.UpdateScale = v60
        end

        debug.profilebegin("GetPath")

        local ForcePosition = p97.ForcePosition
        local v62, Scalar, Scalar2

        if p97.ForcePosition then
            v62 = ForcePosition
        else
            local Scalar3, Scalar4, Scalar5

            if not p97.IntroPath or p97.IntroDone then
                local Scalar

                Scalar3, Scalar, Scalar4, Scalar5 = p97.Path:GetScalar(p97.PathDistance, p97.PathOffset)
            else
                local Scalar

                Scalar3, Scalar, Scalar4, Scalar5 = p97.IntroPath:GetScalar(p97.PathDistance, p97.PathOffset)
            end

            local v63 = Scalar3 + p97.PositionOffset * p97.ScalePositionOffset

            if p97.HeightYOffset then
                v63 += Vector3.new(0, p97.HeightYOffset, 0)
            end

            Scalar = Scalar4
            Scalar2 = Scalar5

            if p97.FlyingAnimation then
                if not p97.FlyingSeed then
                    p97.FlyingSeed = v2:NextNumber()
                end

                v62 = v63 + Vector3.new(0, math.sin((tick() + p97.FlyingSeed) * 6) * 0.8, 0)
            else
                v62 = v63
            end
        end

        debug.profileend()

        if p97:IsAlive() then
            p97._pendingStepDt = (p97._pendingStepDt or 0) + p98
        end

        local v66, v67

        if p97.LastPosition and p97.LastPathDistance ~= p97.PathDistance and p97.LastPosition ~= v62 and Scalar and Scalar2 then
            debug.profilebegin("CFrameLook")

            if GameState.Difficulty == "Duck Hunt" then
                v66 = Scalar - Vector3.new(0, Scalar.Y, 0)
                v67 = Scalar2 - Vector3.new(0, Scalar2.Y, 0)
            else
                v67 = Scalar2
                v66 = Scalar
            end

            local v68 = if p97.Reverse then CFrame.lookAt(v67, v66) else CFrame.lookAt(v66, v67)

            debug.profileend()

            if p97.Rotation then
                p97.Rotation = p97.Rotation.Rotation:Lerp(v68.Rotation, (math.clamp(p98 * p97.Speed * (p97.TimeScaled and GameState.TimeScale or 1), 0, 1)))
            else
                p97.Rotation = v68.Rotation
            end
        end

        local PrimaryPart, v71
        local v70 = v62

        if (p97.Rotation or p97.ForcePosition) and (p97.PathDistance ~= p97.LastPathDistance or p97._forcePositionChanged) then
            debug.profilebegin("TableSet")

            local v73 = p97.AdditiveOffset or Vector3.new(0, 0, 0)

            if GameState.Difficulty == "Duck Hunt" then
                v70 = Vector3.new(v62.X, 4.1 + p97.PositionOffset.Y, v62.Z)
            end

            local v75, v76

            if p97.ForcePosition then
                local v77 = CFrame.new(p97.ForcePosition) * (p97.Rotation or CFrame.identity) + v73

                if v77 then
                    v75 = v77
                    v76 = true
                else
                    v76 = false
                end
            else
                v76 = false
            end

            if not v76 then
                v75 = CFrame.new(v70) * p97.Rotation + v73
            end

            v71 = v75
            PrimaryPart = p97.PrimaryPart
            debug.profileend()
        end

        p97._forcePositionChanged = false
        p97.LastPosition = v70
        p97.LastPathDistance = p97.PathDistance
        debug.profileend()

        return PrimaryPart, v71
    end

    p97._pendingDestroy = true
end

local Hz15 = Enum.StepFrequency.Hz15
local t10 = {}
local t11 = {}

local function isOffScreen(p99, p100, p101, p102, p103, p104, p105) -- line: 1280
    if p100 then
        return false
    end

    local v78 = math.max(p99.Z, 1)
    local v80 = p101 * (p102.Y / (math.tan(p105 / 2) * 2 * v78))
    local v81 = p103 + v80
    local v82 = p104 + v80

    if p99.X < -v81 or p99.X > p102.X + v81 or p99.Y < -v82 then
        return true
    end

    return p99.Y > p102.Y + v82
end

Scheduler.bindToSimulation("NPCReplicator", function(p106) -- line: 1309
    -- upvalues: GameState (copy), t2 (copy)
    local ServerTimeNow = workspace:GetServerTimeNow()

    if #t2 <= 0 then
        return
    end

    local v83 = p106 * GameState.TimeScale

    debug.profilebegin("StepNPCs")

    for _, v84 in ipairs(t2) do
        local v85, v86 = v84:StepPath(if v84.TimeScaled then v83 else p106)

        if v85 and v86 then
            v84.RenderPart = v85

            if v84._renderTargetDirty then
                v84.PrevRenderCFrame = v84.TargetRenderCFrame or v86
            else
                v84.PrevRenderCFrame = v85.CFrame
            end

            v84._renderTargetDirty = true
            v84.TargetRenderCFrame = v86
            v84.RenderStepStartTime = ServerTimeNow
            v84.RenderStepDuration = 0.06666666666666667
        end
    end

    debug.profileend()
end, Hz15)
Scheduler.add("NPCReplicatorRender", RunService.Heartbeat, function() -- line: 1347
    -- upvalues: t2 (copy), t10 (copy), t11 (copy), isOffScreen (copy)
    if #t2 <= 0 then
        return
    end

    local ServerTimeNow = workspace:GetServerTimeNow()

    table.clear(t10)
    table.clear(t11)
    debug.profilebegin("RenderNPCs")

    local CurrentCamera = workspace.CurrentCamera
    local ViewportSize = CurrentCamera and CurrentCamera.ViewportSize or Vector2.zero
    local v87 = ViewportSize.X * 0.15
    local v88 = ViewportSize.Y * 0.15
    local v89 = CurrentCamera and math.rad(CurrentCamera.FieldOfView) or 0
    local n3 = 1

    for _, v90 in ipairs(t2) do
        if v90._pendingDestroy then
            v90._pendingDestroy = nil
            v90:Destroy()
        else
            if v90._pendingScale then
                local _pendingScale = v90._pendingScale

                v90._pendingScale = nil

                if v90.Model and not v90.FBXModel then
                    v90.Model:ScaleTo(_pendingScale)
                    v90.RenderRadius = v90.Model:GetExtentsSize().Magnitude / 2
                end
            end

            if v90._pendingAdjustWalkSpeed then
                v90._pendingAdjustWalkSpeed = nil
                v90:AdjustWalkSpeed()
            end

            local _pendingStepDt = v90._pendingStepDt

            if _pendingStepDt and _pendingStepDt > 0 then
                v90._pendingStepDt = nil

                if v90:IsAlive() then
                    v90:Step(_pendingStepDt)
                end

                if v90.OnStepFunction and not v90.FakeUnit then
                    v90.OnStepFunction(_pendingStepDt)
                end
            end

            if not v90.DisablePathRendering then
                local RenderPart, TargetRenderCFrame, PrevRenderCFrame = v90.RenderPart, v90.TargetRenderCFrame, v90.PrevRenderCFrame

                if RenderPart and TargetRenderCFrame and PrevRenderCFrame then
                    local v91 = v90.RenderStepDuration or 0.06666666666666667
                    local v92 = if v91 > 0 then math.clamp((ServerTimeNow - v90.RenderStepStartTime) / v91, 0, 1) else 1

                    if v92 >= 1 then
                        if v90._renderTargetDirty then
                            v90._renderTargetDirty = nil

                            local v94 = PrevRenderCFrame:Lerp(TargetRenderCFrame, v92)

                            if CurrentCamera then
                                local v95 = v90.RenderRadius or 0
                                local v96, v97 = CurrentCamera:WorldToViewportPoint(v94.Position)
                                local v98, v99 = CurrentCamera:WorldToViewportPoint(RenderPart.Position)

                                if not isOffScreen(v96, v97, v95, ViewportSize, v87, v88, v89) or not isOffScreen(v98, v99, v95, ViewportSize, v87, v88, v89) then
                                    t11[n3] = RenderPart
                                    t10[n3] = v94
                                    n3 += 1
                                end
                            else
                                t11[n3] = RenderPart
                                t10[n3] = v94
                                n3 += 1
                            end
                        end
                    else
                        local v100 = PrevRenderCFrame:Lerp(TargetRenderCFrame, v92)

                        if CurrentCamera then
                            local v101 = v90.RenderRadius or 0
                            local v102, v103 = CurrentCamera:WorldToViewportPoint(v100.Position)
                            local v104, v105 = CurrentCamera:WorldToViewportPoint(RenderPart.Position)

                            if not isOffScreen(v102, v103, v101, ViewportSize, v87, v88, v89) or not isOffScreen(v104, v105, v101, ViewportSize, v87, v88, v89) then
                                t11[n3] = RenderPart
                                t10[n3] = v100
                                n3 += 1
                            end
                        else
                            t11[n3] = RenderPart
                            t10[n3] = v100
                            n3 += 1
                        end
                    end
                end
            end
        end
    end

    debug.profileend()

    if n3 > 1 then
        workspace:BulkMoveTo(t11, t10, Enum.BulkMoveMode.FireCFrameChanged)
    end
end)
Scheduler.add("NPCAnimations", RunService.Heartbeat, function(p107) -- line: 1475
    -- upvalues: t2 (copy)
    for _, v106 in ipairs(t2) do
        if v106 then
            if v106.AnimationsFrozen then
                for _, v107 in v106.AnimationAnimator:GetPlayingAnimationTracks() do
                    v107:AdjustSpeed(0)
                    v107:SetAttribute("Speed", 0)
                end
            elseif v106.StepAnimations then
                v106.StepAnimations(p107)
            end

            if v106.BoneHats then
                v106:UpdateBoneHats()
            end
        else
            warn("NPC is nil")
        end
    end
end)
task.delay(1, function() -- line: 1498
    -- upvalues: _Enum (copy), LegacyMiddleware (copy), TagReplicator (copy), t1 (copy)
    TagReplicator.hook("Enemies", function(p108, p109) -- line: 1499
        -- upvalues: _Enum (copy), LegacyMiddleware (copy), t1 (copy)
        return LegacyMiddleware:RunFunction(_Enum.HookType.SpawnEnemy, nil, t1.new, p108, p109)
    end)
end)

return t1
