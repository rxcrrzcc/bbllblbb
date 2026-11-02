-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local t1 = {}

t1.__index = t1

t1.__tostring = function(p1) -- line: 6
    return "Unit_" .. tostring(p1.Name)
end

local TweenService = require(ReplicatedStorage.Client.Modules.TweenService)
local DebugController = require(ReplicatedStorage.Client.Controllers.Shared.DebugController)
local HumanoidUtil = require(ReplicatedStorage.Shared.Modules.HumanoidUtil)
local NPCReplicator = require(ReplicatedStorage.Client.Modules.Replicators.NPCReplicator)
local NPCUtils = require(ReplicatedStorage.Shared.Modules.NPCUtils)
local ParticleLODController = require(ReplicatedStorage.Client.Modules.ParticleLODController)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local StatusEffectRenderer = require(ReplicatedStorage.Client.Modules.StatusEffects.StatusEffectRenderer)
local TaggedInstances = require(ReplicatedStorage.Shared.Modules.TaggedInstances)
local TimeFieldParticles = require(ReplicatedStorage.Client.Modules.TimeFieldParticles)
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local Asset = require(ReplicatedStorage.Shared.Modules.Asset)
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)
local Laser = require(ReplicatedStorage.Client.Modules.Laser)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local Network = require(ReplicatedStorage.Shared.Modules.Network)
local TagReplicator = require(ReplicatedStorage.Client.Modules.TagReplicator)
local Folder = Instance.new("Folder")

Folder.Name = "ClientUnits"
Folder.Parent = workspace

local GoldenPerks = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("Particles"):WaitForChild("GoldenPerks")
local Streaming = Network.Channel("Streaming")
local v1 = Random.new()
local t2 = {}
local t3 = {}
local Gizmo = DebugController.Gizmo

DebugController.createGizmo("Unit Hitboxes", function() -- line: 47
    -- upvalues: t3 (copy), Gizmo (copy)
    Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(141, 166, 255))

    for _, v2 in t3 do
        Gizmo.Box:Draw(v2.Hitbox.CFrame, v2.Hitbox.Size, false)
    end
end)

function t1.new(p2, p3) -- line: 55
    -- upvalues: t1 (copy), HumanoidUtil (copy), NPCUtils (copy), ParticleLODController (copy), Signal (copy), StatusEffectRenderer (copy), TaggedInstances (copy), TimeFieldParticles (copy), Upgrades (copy), Asset (copy), GameState (copy), Maid (copy), TagReplicator (copy), Folder (copy), GoldenPerks (copy), Streaming (copy), v1 (copy), t2 (copy), t3 (copy)
    local ModelName = p3:WaitForState("ModelName")
    local v3 = p3:Get("Skin") or "Default"
    local v4 = Streaming:InvokeServer("SelectUnit", ModelName, v3, true)

    if not v4 or v4 < 1 then
        v3 = "Default"
        Streaming:FireServer("SelectUnit", ModelName, "Default", true)
    end

    local v5 = Asset("NewUnits", ModelName)

    assert(v5, "Unit data " .. ModelName .. " does not exist.")

    local v7 = Asset("NewUnitsModel", ModelName, v3)

    assert(v7, "Unit model " .. ModelName .. " does not exist.")

    local v9 = p2:WaitForChild("StatusEffects", 5)

    if not v9 then
        return
    end

    local self = setmetatable({}, v5.Animator and setmetatable(v5.Animator, t1) or t1)

    self.Maid = Maid.new()
    self.PathTeam = p3:Get("PathTeam")

    local clone = v7:Clone()

    self.BaseScale = clone:GetScale()
    clone:ScaleTo(p3:Get("Scale") * self.BaseScale)
    self.TimeScaled = true
    self.Name = ModelName
    self.Model = clone
    self.Maid:Mark(TimeFieldParticles.track(self.Model))
    self.Model.PrimaryPart.Anchored = true
    self.Model.Parent = Folder
    self.PrimaryPart = self.Model.PrimaryPart
    self.FBXModel = HumanoidUtil.findFirstRigBone(self.Model)

    local v12, v13 = HumanoidUtil.createAnimationHost(self.Model, self.FBXModel ~= nil)

    self.AnimationController = v12
    self.AnimationAnimator = v13
    NPCUtils.configureModelParts(self.Model)
    self.BoneVFX = self.Model:FindFirstChild("BoneVFX")
    self.Tagged = TaggedInstances.getTaggedInstances(self.Model)
    self.Golden = p3:Get("Golden")
    self.Upgrade = p3:Get("Upgrade") or 0
    self.OnDestroy = Signal.new()

    if self.Golden then
        for _, descendant in self.Model:GetDescendants() do
            if descendant:IsA("BasePart") and descendant.Name == "Torso" and not descendant:FindFirstChild("Shine") then
                GoldenPerks.Shine:Clone().Parent = descendant
            end
        end
    end

    if self.Model:FindFirstChild("UpgradesModule") then
        for i = 1, self.Upgrade do
            Upgrades.upgrade(self, i, "unit")
        end
    end

    local v14

    if v5.NewStats then
        local v15 = v5.NewStats[if self.Golden then "Golden" else "Default"] or v5.NewStats.Default

        v14 = v15.Upgrades[math.clamp(self.Upgrade, 0, #v15.Upgrades)] or v15.Defaults
    else
        v14 = v5.Stats[if self.Golden then "Golden" else "Default"] or v5.Stats.Default
    end

    self.Stats = v14

    if self.Model:FindFirstChild("Effects") then
        self.Effects = require(self.Model.Effects)
    end

    local Hitbox = self.Model:FindFirstChild("Hitbox")
    local Size = Hitbox and Hitbox.Size or self.Model:GetExtentsSize()
    local v17 = math.max(Size.X, Size.Z)

    self.RenderRadius = Size.Magnitude / 2

    local v18 = Hitbox or Instance.new("Part")

    v18.Anchored = false
    v18.CanCollide = false
    v18.CanTouch = false
    v18.CanQuery = true
    v18.Transparency = 1
    v18.CFrame = self.Model:GetPivot()

    if not Hitbox then
        v18.Name = "Hitbox"
        v18.Size = Vector3.new(v17, math.abs(self.PrimaryPart.Node.Position.Y * 2), v17)

        local WeldConstraint = Instance.new("WeldConstraint")

        WeldConstraint.Part0 = self.Model.PrimaryPart
        WeldConstraint.Part1 = v18
        WeldConstraint.Parent = self.Model.PrimaryPart
        v18.Parent = self.Model
    end

    self.Hitbox = v18
    self.FolderPointer = Instance.new("ObjectValue")
    self.FolderPointer.Name = "RootPointer"
    self.FolderPointer.Value = p2
    self.FolderPointer.Parent = self.Model

    local v22 = math.clamp((15 - self.Model:GetExtentsSize().Magnitude) / 15, 0, 1)

    self.PositionHeightOffset = -self.PrimaryPart.Node.Position
    self.EntityId = p3:Get("ID")
    self.Type = p3:Get("Type")
    self.Rotation = CFrame.new()
    self.Replicator = p3
    self.Scale = p3:Get("Scale")
    self.PathDistance = p3:Get("PathDistance")
    self.SendTime = p3:Get("SendTime")
    self.LastPathDistance = self.PathDistance
    self.PathOffset = v1:NextNumber(-v22, v22)
    self.ForcePosition = p3:Get("ForcePosition")
    self.AdditiveOffset = p3:Get("PositionOffset")
    self.Lifetime = p3:Get("Lifetime")
    self.Modifiers = TagReplicator.getReplicatorEntityFromFolder(v9)
    self.Maid:Mark(self.Modifiers)
    self.StatusEffectRenderer = StatusEffectRenderer.new(self, v9, self.Modifiers)
    self.StatusEffects = self.StatusEffectRenderer
    self.Maid:Mark(self.StatusEffectRenderer)

    if not self.ForcePosition then
        self.Path = GameState.Paths[self.PathTeam][p3:Get("PathName")] or GameState.Paths[self.PathTeam][tonumber(p3:Get("PathName"))]
    end

    self.Lifespan = p3:Get("Lifespan")
    self.MaxLifespan = p3:Get("MaxLifespan")
    self.Replicator:GetStateChangedSignal("Lifespan"):Connect(function(p4) -- line: 212
        -- upvalues: self (copy)
        self.Lifespan = p4
    end)
    self.Replicator:GetStateChangedSignal("MaxLifespan"):Connect(function(p5) -- line: 215
        -- upvalues: self (copy)
        self.MaxLifespan = p5
    end)
    self.Reverse = p3:Get("Reverse")
    self.Replicator:GetStateChangedSignal("Reverse"):Connect(function(p6) -- line: 220
        -- upvalues: self (copy)
        self.Reverse = p6
    end)
    self.Cooldown = p3:Get("Cooldown")
    self.Replicator:GetStateChangedSignal("Cooldown"):Connect(function(p7) -- line: 225
        -- upvalues: self (copy)
        self.Cooldown = p7
    end)
    self.Speed = p3:Get("Speed")
    self.Replicator:GetStateChangedSignal("Speed"):Connect(function(p8) -- line: 230
        -- upvalues: self (copy)
        self.Speed = p8
    end)
    self.Stopped = false
    self.Replicator:GetStateChangedSignal("Stopped"):Connect(function(p9) -- line: 235
        -- upvalues: self (copy)
        self.Stopped = p9
    end)
    task.defer(function() -- line: 240
        -- upvalues: p2 (copy), self (copy)
        p2:SetAttribute("Speed", self.Speed)
    end)
    self.Replicator:GetStateChangedSignal("PathDistance"):Connect(function(p10) -- line: 244
        -- upvalues: self (copy)
        if math.abs(self.PathDistance - p10) > 0.5 then
            self.PathDistance = p10
        end
    end)
    self.Replicator:GetStateChangedSignal("Scale"):Connect(function(p11) -- line: 251
        -- upvalues: self (copy), clone (copy)
        clone:ScaleTo(p11 * self.BaseScale)
        self.RenderRadius = clone:GetExtentsSize().Magnitude / 2
    end)
    self.Replicator:Hook(self)
    self.Name = p3:Get("DisplayName") or p3:Get("ModelName")
    self.Replicator:GetStateChangedSignal("DisplayName"):Connect(function(p12) -- line: 258
        -- upvalues: self (copy)
        self.Name = p12 or self.Replicator:Get("ModelName")
    end)
    self.Connections = self.Maid
    self.Dead = false
    table.insert(t2, self)
    ParticleLODController.registerModel(self.Model, function() -- line: 268
        -- upvalues: self (copy)
        return self.Model.PrimaryPart and self.Model.PrimaryPart.Position or Vector3.new(0, 0, 0)
    end)
    self.Maid:Mark(function() -- line: 271
        -- upvalues: self (copy), ParticleLODController (copy)
        ParticleLODController.unregisterModel(self.Model)
    end)
    self.Maid:Mark(self.Model)
    self.Maid:Mark(function() -- line: 275
        -- upvalues: self (copy), t2 (copy)
        self.Connections = nil

        local v25 = table.find(t2, self)

        if v25 then
            table.remove(t2, v25)
        end
    end)
    t3[p2] = self
    self.Maid:Mark(function() -- line: 285
        -- upvalues: p2 (copy), t3 (copy)
        t3[p2] = nil
    end)
    self:Initialize()

    local v26 = if self.ForcePosition then self.ForcePosition else self.Path:GetScalar(self.PathDistance, self.PathOffset)

    self.Model:PivotTo(CFrame.new(v26 + self.PositionHeightOffset))

    if self.Effects then
        self.Effects.Initialize(self)
    end

    return self
end

function t1.Thread(p13, p14) -- line: 304
    p13.ThreadFunction = p14
    p13._threadCo = nil
    p13._threadDelayRemaining = 0
end

function t1.Wait(_, p16) -- line: 310
    -- upvalues: TimescaleUtilities (copy)
    return TimescaleUtilities.Wait(p16)
end

function t1.Delay(p17, p18, p19) -- line: 314
    -- upvalues: TimescaleUtilities (copy)
    if p19 then
        return TimescaleUtilities.Delay(p18, p19)
    end

    p17:Wait(p18)
end

function t1.IsAlive(p20) -- line: 323
    return p20.Maid ~= nil and not p20.Dead
end

function t1.GetNPCFromFolder(p21) -- line: 327
    -- upvalues: t3 (copy)
    return t3[p21]
end

local function scanReplace(p22) -- line: 331
    -- upvalues: t1 (copy), NPCReplicator (copy), scanReplace (copy)
    for v27, _ in pairs(p22) do
        if typeof(p22[v27]) == "table" then
            scanReplace(p22[v27])
        end

        if typeof(p22[v27]) == "Instance" and p22[v27]:IsA("Folder") then
            local v30 = t1.GetNPCFromFolder(p22[v27]) or NPCReplicator.GetNPCFromFolder(p22[v27])

            if v30 then
                p22[v27] = v30.Model
            end
        end
    end
end

Network.Channel("Replicate"):On("UnitInstance", function(p23) -- line: 346
    -- upvalues: t3 (copy), scanReplace (copy)
    debug.profilebegin("UnitInstanceDispatch")

    for _, v31 in p23 do
        task.spawn(function() -- line: 349
            -- upvalues: v31 (copy), t3 (copy), scanReplace (copy)
            local v32 = v31[2]
            local v33 = v31[1]
            local t5 = { unpack(v31, 3) }
            local v34 = t3[v32]

            if not v34 then
                return
            end

            debug.profilebegin("UnitInstanceScanReplace")
            scanReplace(t5)
            debug.profileend()
            v34.Executables[v33](unpack(t5))
        end)
    end

    debug.profileend()
end)

function t1.Bullet(_, p25) -- line: 368
    -- upvalues: Laser (copy), v1 (copy)
    if p25.End == nil or p25.Start == nil then
        return
    end

    local Magnitude = (p25.Start - p25.End).Magnitude
    local v39 = CFrame.new(p25.Start, p25.End) * CFrame.Angles(math.rad(v1:NextNumber(-p25.Spread, p25.Spread) / Magnitude), math.rad(v1:NextNumber(-p25.Spread, p25.Spread) / Magnitude), 0)

    Laser:Cast({
        Start = v39.p,
        Pos = v39 * CFrame.new(0, 0, -Magnitude).Position,
        Color = not p25.NoColor and (p25.Color or BrickColor.new("Cork").Color),
        Transparency = p25.Transparency or 0.1,
        Size = p25.Size or 0.04,
        Fade = p25.Speed or 90,
        Type = "Bullet",
        Bullet = p25.Bullet or "Normal",
        Reversed = p25.Reversed or false
    })
end

function t1.FindTarget(p26) -- line: 395
    -- upvalues: NPCReplicator (copy)
    local Target = p26.Replicator.Folder:FindFirstChild("Target")

    if not Target then
        return
    end

    local v40 = NPCReplicator.GetNPCFromFolder(Target.Value)

    return v40 and v40.Model or nil
end

function t1.Animate(p27, p28, p29) -- line: 404
    local Animations = p27.Model:FindFirstChild("Animations")

    if not Animations then
        return
    end

    if not p27.LoadedAnimations then
        p27.LoadedAnimations = {}
    end

    if not p27.LoadedAnimations[p28] then
        p27.LoadedAnimations[p28] = p27.AnimationAnimator:LoadAnimation(Animations:FindFirstChild(p28))
    end

    local v41 = p27.LoadedAnimations[p28]

    if v41 and v41 then
        if p29 then
            for v42, v43 in pairs(p29) do
                v41[v42] = v43
            end
        end

        return v41
    end
end

function t1.Face(p30, p31, p32) -- line: 436
    -- upvalues: TweenService (copy)
    local PrimaryPart = p30.Model.PrimaryPart
    local v44 = CFrame.lookAt(PrimaryPart.Position, (Vector3.new(p31.X, PrimaryPart.Position.Y, p31.Z)))

    p30.Rotation = CFrame.new() * v44.Rotation

    if p32 then
        TweenService:Create(PrimaryPart, p32, {
            CFrame = v44
        }):Play()
    else
        PrimaryPart.CFrame = v44
    end

    return v44
end

function t1.Destroy(p33) -- line: 452
    if p33.Maid then
        p33.OnDestroy:Fire()
        p33.Dead = true
        p33.Maid:Sweep()
        p33.Maid = nil
    end
end

local function currentTimeScale() -- line: 462
    -- upvalues: GameState (copy)
    local State = GameState.State

    return State and State.TimeScale or GameState.TimeScale or 1
end

function t1.Step(p34, p35) -- line: 468
    -- upvalues: NPCUtils (copy), GameState (copy)
    local stepThread = NPCUtils.stepThread
    local State = GameState.State

    stepThread(p34, p35 * (State and State.TimeScale or GameState.TimeScale or 1))
end

local Hz15 = Enum.StepFrequency.Hz15
local t7 = {}
local t8 = {}

local function queueRenderTarget(p36, p37, p38) -- line: 481
    p36.RenderPart = p36.PrimaryPart
    p36.PrevRenderCFrame = p36.TargetRenderCFrame or p37
    p36.TargetRenderCFrame = p37
    p36.RenderStepStartTime = p38
    p36.RenderStepDuration = 0.06666666666666667
end

local function isOffScreen(p39, p40, p41, p42, p43, p44, p45) -- line: 489
    if p40 then
        return false
    end

    local v45 = math.max(p39.Z, 1)
    local v47 = p41 * (p42.Y / (math.tan(p45 / 2) * 2 * v45))
    local v48 = p43 + v47
    local v49 = p44 + v47

    if p39.X < -v48 or p39.X > p42.X + v48 or p39.Y < -v49 then
        return true
    end

    return p39.Y > p42.Y + v49
end

Scheduler.bindToSimulation("UnitReplicator", function(p46) -- line: 519
    -- upvalues: GameState (copy), t2 (copy)
    local ServerTimeNow = workspace:GetServerTimeNow()

    if #t2 <= 0 then
        return
    end

    local v50 = p46 * GameState.TimeScale

    debug.profilebegin("StepUnits")

    for _, v51 in ipairs(t2) do
        if v51.FolderPointer.Value.Parent ~= nil then
            if v51:IsAlive() then
                local v52 = if v51.TimeScaled then v50 else p46

                v51._pendingStepDt = (v51._pendingStepDt or 0) + v52

                if v51.ForcePosition then
                    local v53 = v51.AdditiveOffset or Vector3.new(0, 0, 0)
                    local v54 = not v51._stationaryRenderInitialized

                    if v53.Magnitude > 0.001 then
                        debug.profilebegin("AdditiveOffset")
                        v53 = v53:Lerp(Vector3.new(0, 0, 0), v52 * v51.Speed)

                        if v53.Magnitude <= 0.001 then
                            v53 = Vector3.new(0, 0, 0)
                        end

                        v51.AdditiveOffset = v53
                        v54 = true
                        debug.profileend()
                    else
                        v51.AdditiveOffset = Vector3.new(0, 0, 0)
                    end

                    if v54 then
                        local v55 = CFrame.new(v51.ForcePosition + v51.PositionHeightOffset + v53) * v51.Rotation

                        v51.RenderPart = v51.PrimaryPart
                        v51.PrevRenderCFrame = v51.TargetRenderCFrame or v55
                        v51.TargetRenderCFrame = v55
                        v51.RenderStepStartTime = ServerTimeNow
                        v51.RenderStepDuration = 0.06666666666666667
                        v51._stationaryRenderInitialized = true
                    end
                elseif v51.Speed ~= 0 and not v51.Stopped then
                    if v51.Reverse then
                        v51.PathDistance -= v52 * v51.Speed
                    else
                        v51.PathDistance += v52 * v51.Speed
                    end

                    debug.profilebegin("AdditiveOffset")
                    v51.AdditiveOffset = v51.AdditiveOffset:Lerp(Vector3.new(), v52 * v51.Speed)
                    debug.profileend()
                    debug.profilebegin("GetPath")

                    local Scalar, _, Scalar2, Scalar3 = v51.Path:GetScalar(v51.PathDistance, v51.PathOffset)
                    local v56 = Scalar + v51.PositionHeightOffset

                    debug.profileend()

                    if v51.LastPosition and (if v51.Reverse then v51.LastPathDistance > v51.PathDistance else v51.LastPathDistance < v51.PathDistance) and v51.LastPosition ~= v56 and Scalar2 and Scalar3 then
                        debug.profilebegin("CFrameLook")

                        if GameState.Difficulty == "Duck Hunt" then
                            Scalar2 -= Vector3.new(0, Scalar2.Y, 0)
                            Scalar3 -= Vector3.new(0, Scalar3.Y, 0)
                        end

                        local v57 = if v51.Reverse then CFrame.lookAt(Scalar3, Scalar2) else CFrame.lookAt(Scalar2, Scalar3)

                        debug.profileend()

                        if v51.Rotation then
                            v51.Rotation = v51.Rotation:Lerp(v57 - v57.Position, v52 * v51.Speed)
                        else
                            v51.Rotation = v57 - v57.Position
                        end
                    end

                    v51.LastPosition = v56
                    v51.LastPathDistance = v51.PathDistance

                    if v51.Rotation and not v51.Stopped then
                        if GameState.Difficulty == "Duck Hunt" then
                            v56 = Vector3.new(v56.X, 4.1 + v51.PositionHeightOffset.Y, v56.Z)
                        end

                        local v59 = CFrame.new(v56) * v51.Rotation + v51.AdditiveOffset

                        v51.RenderPart = v51.PrimaryPart
                        v51.PrevRenderCFrame = v51.TargetRenderCFrame or v59
                        v51.TargetRenderCFrame = v59
                        v51.RenderStepStartTime = ServerTimeNow
                        v51.RenderStepDuration = 0.06666666666666667
                    end
                end
            end
        else
            v51._pendingDestroy = true
        end
    end

    debug.profileend()
end, Hz15)
Scheduler.add("UnitReplicatorRender", RunService.Heartbeat, function() -- line: 644
    -- upvalues: t2 (copy), t7 (copy), t8 (copy), isOffScreen (copy)
    if #t2 <= 0 then
        return
    end

    local ServerTimeNow = workspace:GetServerTimeNow()

    table.clear(t7)
    table.clear(t8)

    local CurrentCamera = workspace.CurrentCamera
    local ViewportSize = CurrentCamera and CurrentCamera.ViewportSize or Vector2.zero
    local v60 = ViewportSize.X * 0.15
    local v61 = ViewportSize.Y * 0.15
    local v62 = CurrentCamera and math.rad(CurrentCamera.FieldOfView) or 0

    debug.profilebegin("RenderUnits")

    local n1 = 1

    for _, v63 in ipairs(t2) do
        if v63._pendingDestroy then
            v63._pendingDestroy = nil
            v63:Destroy()
        else
            local _pendingStepDt = v63._pendingStepDt

            if _pendingStepDt and _pendingStepDt > 0 then
                debug.profilebegin("RenderUnitsStep")
                v63._pendingStepDt = nil

                if v63:IsAlive() then
                    v63:Step(_pendingStepDt)
                end

                if v63.OnStepFunction then
                    v63.OnStepFunction(_pendingStepDt)
                end

                debug.profileend()
            end

            local RenderPart, TargetRenderCFrame, PrevRenderCFrame = v63.RenderPart, v63.TargetRenderCFrame, v63.PrevRenderCFrame

            if RenderPart and TargetRenderCFrame and PrevRenderCFrame then
                local v64 = v63.RenderStepDuration or 0.06666666666666667
                local v65 = if v64 > 0 then math.clamp((ServerTimeNow - v63.RenderStepStartTime) / v64, 0, 1) else 1

                debug.profilebegin("RenderUnitsInterpolate")

                local v67 = PrevRenderCFrame:Lerp(TargetRenderCFrame, v65)

                debug.profileend()

                if v67 ~= v63.LastCFrame then
                    local v68

                    if CurrentCamera then
                        debug.profilebegin("RenderUnitsVisibility")

                        local v69 = v63.RenderRadius or 0
                        local v70, v71 = CurrentCamera:WorldToViewportPoint(v67.Position)
                        local v72, v73 = CurrentCamera:WorldToViewportPoint(RenderPart.Position)

                        v68 = isOffScreen(v70, v71, v69, ViewportSize, v60, v61, v62) and isOffScreen(v72, v73, v69, ViewportSize, v60, v61, v62)
                        debug.profileend()
                    else
                        v68 = false
                    end

                    if not v68 then
                        debug.profilebegin("RenderUnitsQueueMove")
                        t7[n1] = v67
                        t8[n1] = RenderPart
                        n1 += 1
                        v63.LastCFrame = v67
                        debug.profileend()
                    end
                end
            end
        end
    end

    debug.profileend()

    if not (n1 > 1) then
        return
    end

    debug.profilebegin("RenderUnitsBulkMoveTo")
    workspace:BulkMoveTo(t8, t7, Enum.BulkMoveMode.FireCFrameChanged)
    debug.profileend()
end)
TagReplicator.hook("Units", function(p47, p48) -- line: 751
    -- upvalues: t1 (copy)
    return (t1.new(p47, p48))
end)

return t1
