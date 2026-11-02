-- https://lua.expert
--ОГРОМЕННЫЙ МОДУЛЬ TowerReplicator
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

game:GetService("TweenService")

local t1 = {}

t1.__index = t1

local Effects = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects")
local Particles = Effects:WaitForChild("Particles")
local Buffs = Effects:WaitForChild("Buffs")
local AbilitiesStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.AbilitiesStore)
local AbilityAmmoStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.AbilityAmmoStore)
local AbilityIndicatorStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.AbilityIndicatorStore)
local DebugController = require(ReplicatedStorage.Client.Controllers.Shared.DebugController)
local PathPlacementCursorController = require(ReplicatedStorage.Client.Controllers.Game.PathPlacementCursorController)
local TimeField = require(ReplicatedStorage.Shared.Modules.TimeField)
local TimeFieldParticles = require(ReplicatedStorage.Client.Modules.TimeFieldParticles)
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)
local TowerRangeRules = require(ReplicatedStorage.Shared.Modules.TowerRangeRules)
local TowerSignals = require(ReplicatedStorage.Shared.Modules.TowerSignals)
local TowerStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.TowerStore)
local TowerUpgradeUtils = require(ReplicatedStorage.Shared.Modules.TowerUpgradeUtils)
local Upgrades = require(ReplicatedStorage.Shared.Modules.Upgrades)
local UpgradesStore = require(ReplicatedStorage.Client.Interfaces.Stores.Game.UpgradesStore)
local StatusEffectRenderer = require(ReplicatedStorage.Client.Modules.StatusEffects.StatusEffectRenderer)
local TagReplicator = require(ReplicatedStorage.Client.Modules.TagReplicator)
local NPCReplicator = require(ReplicatedStorage.Client.Modules.Replicators.NPCReplicator)
local AbilityStateConfig = require(ReplicatedStorage.Shared.Modules.AbilityStateConfig)
local Content = require(ReplicatedStorage.Shared.Modules.Content)
local EmitterManager = require(ReplicatedStorage.Shared.Modules.EmitterManager)
local GameRules = require(ReplicatedStorage.Shared.Modules.GameRules)
local HumanoidUtil = require(ReplicatedStorage.Shared.Modules.HumanoidUtil)

require(ReplicatedStorage.Shared.Modules.LegacyMiddleware)

local NPCUtils = require(ReplicatedStorage.Shared.Modules.NPCUtils)
local ParticleLODController = require(ReplicatedStorage.Client.Modules.ParticleLODController)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local SkillsUtil = require(ReplicatedStorage.Shared.Modules.SkillsUtil)
local Sound = require(ReplicatedStorage.Client.Modules.LegacyInterfaces.Components.Sound)
local TaggedInstances = require(ReplicatedStorage.Shared.Modules.TaggedInstances)
local TransientVFX = require(ReplicatedStorage.Client.Modules.TransientVFX)
local TweenService = require(ReplicatedStorage.Client.Modules.TweenService)
local Animation = require(ReplicatedStorage.Shared.Modules.Animation)
local Asset = require(ReplicatedStorage.Shared.Modules.Asset)
local Create = require(ReplicatedStorage.Shared.Modules.Standalone.Create)
local _Enum = require(ReplicatedStorage.Shared.Modules.Enum)
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)
local Laser = require(ReplicatedStorage.Client.Modules.Laser)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local Network = require(ReplicatedStorage.Shared.Modules.Network)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local spr = require(ReplicatedStorage.Shared.Modules.spr)
local Troops = Network.Channel("Troops")
local USE_OWNER_ABILITY_STATE = AbilityStateConfig.USE_OWNER_ABILITY_STATE
local UserId = Players.LocalPlayer.UserId
local v1 = Random.new()

local function getAvailableAbilities(p1, p2, p3) -- line: 73
    -- upvalues: TowerUpgradeUtils (copy)
    local t2 = {}

    for _, v2 in p1 or {} do
        if (v2.Level or 0) <= p2 and TowerUpgradeUtils.matchesPath(v2, p3) then
            table.insert(t2, v2)
        end
    end

    return t2
end

local t3 = {
    FrozenDeath = function(p4) -- line: 86
        -- upvalues: TransientVFX (copy)
        local clone = p4.Model:Clone()

        for _, descendant in clone:GetDescendants() do
            if descendant:IsA("MeshPart") then
                descendant.TextureID = ""
            end

            if descendant:IsA("BasePart") then
                descendant.Anchored = true
                descendant.Material = Enum.Material.Foil
                descendant.Color = Color3.fromRGB(213, 255, 255)
                descendant.LocalTransparencyModifier = 0
            end
        end

        clone.Parent = workspace.Trash
        debug.profilebegin("VFX_FrozenDeathTTL")
        TransientVFX.track(clone, {
            ttl = 5,
            profileName = "FrozenDeath"
        })
        debug.profileend()
    end
}
local t4 = {}

t4[_Enum.BuffType.Cooldown] = {
    Enter = function(p5) -- Enter | line: 109
        -- upvalues: Buffs (copy), TransientVFX (copy)
        if p5.CooldownBuffEffect then
            return
        end

        p5.CooldownBuffEffect = Buffs.Cooldown:Clone()
        p5.CooldownBuffEffect:PivotTo(CFrame.new(p5.BottomPosition) * CFrame.Angles(0, 0, 3.141592653589793))
        p5.CooldownBuffEffect.Parent = workspace.Trash
        TransientVFX.track(p5.CooldownBuffEffect, {
            profileName = "CooldownBuff"
        })
    end,
    Exit = function(p6) -- Exit | line: 120
        if p6.CooldownBuffEffect then
            p6.CooldownBuffEffect:Destroy()
            p6.CooldownBuffEffect = nil
        end
    end
}

local FortifyReduction = _Enum.BuffType.Damage
local v3 = {}

function v3.Enter(p7) -- line: 130
    -- upvalues: Buffs (copy), TransientVFX (copy)
    if p7.DamageBuffEffect then
        return
    end

    local clone = Buffs.Damage:Clone()

    clone:PivotTo(CFrame.new(p7.BottomPosition) * CFrame.Angles(0, 0, 3.141592653589793))
    clone.Parent = workspace.Trash
    TransientVFX.track(clone, {
        profileName = "DamageBuff"
    })
    p7.DamageBuffEffect = clone
    p7.Maid:Mark(clone)
end

function v3.Exit(p8) -- line: 144
    if p8.DamageBuffEffect then
        p8.DamageBuffEffect:Destroy()
        p8.DamageBuffEffect = nil
    end
end

t4[FortifyReduction] = v3
FortifyReduction = _Enum.BuffType.Range
v3 = {}

function v3.Enter(p9) -- line: 154
    -- upvalues: Buffs (copy), TransientVFX (copy)
    if not p9.RangeBuffEffect and not p9.RangeBoostImmune then
        local clone = Buffs.Range:Clone()

        clone:PivotTo(CFrame.new(p9.BottomPosition) * CFrame.Angles(0, 0, 3.141592653589793))
        clone.Parent = workspace.Trash
        TransientVFX.track(clone, {
            profileName = "RangeBuff"
        })
        p9.RangeBuffEffect = clone
        p9.Maid:Mark(clone)
    end
end

function v3.Exit(p10) -- line: 167
    if p10.RangeBuffEffect then
        p10.RangeBuffEffect:Destroy()
        p10.RangeBuffEffect = nil
    end
end

t4[FortifyReduction] = v3
FortifyReduction = _Enum.BuffType.FortifyReduction
v3 = {}

function v3.Enter(p11) -- line: 177
    -- upvalues: RunService (copy), Buffs (copy), EmitterManager (copy), TransientVFX (copy)
    if p11.FortifyBuffEffect then
        return
    end

    local Fortify = Buffs.Fortify
    local v4

    if Fortify:IsA("Folder") then
        local v5 = Fortify:FindFirstChild(p11.Name)

        v5 = v5 and v5:IsA("Folder") and v5:FindFirstChild(p11.Model.Name)
        v4 = if not (v5 and v5:IsA("Model")) then Fortify:FindFirstChild("Default") else v5

        if not (v4 and v4:IsA("Model")) then
            return
        end
    else
        v4 = Fortify
    end

    local clone = v4:Clone()
    local Shield = clone:FindFirstChild("Shield")
    local Deco = clone:FindFirstChild("Deco")
    local _CFrame = p11.Model.PrimaryPart.CFrame
    local _CFrame2 = _CFrame

    if Shield then
        Shield.Anchored = true
        Shield.CFrame = _CFrame
        Shield.Parent = workspace.Trash
        TransientVFX.track(Shield, {
            profileName = "FortifyShield"
        })
    end

    if Deco then
        Deco.Anchored = true
        Deco.CFrame = _CFrame
        Deco.Parent = workspace.Trash
        TransientVFX.track(Deco, {
            profileName = "FortifyDeco"
        })
    end

    clone:Destroy()
    p11.FortifyBuffEffect = {
        Shield = Shield,
        Deco = Deco
    }

    if Shield then
        p11.Maid:Mark(Shield)
    end

    if Deco then
        p11.Maid:Mark(Deco)
    end

    if not Shield then
        return
    end

    local Emit = Shield:FindFirstChild("Emit")
    local n1 = 0

    if Emit then
        EmitterManager.manualEmit(Emit)
    end

    p11._fortifySpinConn = RunService.Heartbeat:Connect(function(p12) -- line: 233
        -- upvalues: p11 (copy), Shield (copy), Deco (copy), _CFrame2 (ref), n1 (ref)
        if p11.Model.PrimaryPart then
            _CFrame2 = p11.Model.PrimaryPart.CFrame
            n1 = (n1 + p12 * 3.141592653589793 / 2) % 6.283185307179586
            Shield.CFrame = _CFrame2

            if Deco then
                Deco.CFrame = _CFrame2 * CFrame.Angles(0, n1, 0)
            end
        end
    end)
    p11.Maid:Mark(p11._fortifySpinConn)
end

function v3.Exit(p13) -- line: 248
    if p13.FortifyBuffEffect then
        if p13._fortifySpinConn then
            p13._fortifySpinConn:Disconnect()
            p13._fortifySpinConn = nil
        end

        if p13.FortifyBuffEffect.Shield then
            p13.FortifyBuffEffect.Shield:Destroy()
        end

        if p13.FortifyBuffEffect.Deco then
            p13.FortifyBuffEffect.Deco:Destroy()
        end

        p13.FortifyBuffEffect = nil
    end
end

t4[FortifyReduction] = v3

local t5 = {}

t5[_Enum.StunType.Boomer] = {
    Enter = function(p14) -- Enter | line: 271
        -- upvalues: ReplicatedStorage (copy), TransientVFX (copy)
        local clone = ReplicatedStorage.Assets.Effects.Particles.BoomerSmoke:Clone()

        clone:ScaleTo(p14.Model.Head.Size.Y * 2)
        clone:PivotTo(p14.Model.Head.CFrame)

        local WeldConstraint = Instance.new("WeldConstraint")

        WeldConstraint.Part0 = p14.Model.Head
        WeldConstraint.Part1 = clone.Effect
        WeldConstraint.Parent = clone.Effect
        clone.Parent = workspace.Trash
        TransientVFX.track(clone, {
            profileName = "BoomerStun"
        })
        p14.Maid:Mark(clone)
        p14._boomerDebuffEffect = clone
    end,
    Exit = function(p15) -- Exit | line: 287
        local _boomerDebuffEffect = p15._boomerDebuffEffect

        if _boomerDebuffEffect then
            _boomerDebuffEffect:Destroy()
        end
    end
}
t5[_Enum.StunType.Normal] = {
    Enter = function() -- Enter | line: 296
    end,
    Exit = function() -- Exit | line: 297
    end
}
v3 = _Enum.StunType.Legacy

local v7 = {}

function v7.Enter(p16) -- line: 300
    -- upvalues: Particles (copy)
    if p16.LegacyStunParticles then
        return
    end

    p16.LegacyStunParticles = Particles.Stun:Clone()
    p16.LegacyStunParticles.Enabled = true
    p16.LegacyStunParticles.Parent = p16.Model.Head
end

function v7.Exit(p17) -- line: 308
    if p17.LegacyStunParticles then
        p17.LegacyStunParticles:Destroy()
        p17.LegacyStunParticles = nil
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Golden
v7 = {}

function v7.Enter(p18) -- line: 317
    -- upvalues: ReplicatedStorage (copy), TransientVFX (copy)
    if p18.GoldenStunParticles then
        return
    end

    local clone = ReplicatedStorage.Assets.Effects.Mob.GoldSpike.Ice2:Clone()

    clone.Transparency = 0.5
    clone.Position = p18.Model:GetPivot().Position + Vector3.new(0, clone.Size.Y / 2, 0)
    clone.Parent = workspace.Trash
    TransientVFX.track(clone, {
        profileName = "GoldenStun"
    })
    p18.GoldenStunParticles = clone
    p18.Maid:Mark(clone)
end

function v7.Exit(p19) -- line: 331
    -- upvalues: TimescaleUtilities (copy), TweenService (copy)
    if p19.GoldenStunParticles then
        local GoldenStunParticles = p19.GoldenStunParticles

        p19.GoldenStunParticles = nil
        TweenService:Create(GoldenStunParticles, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, 0), {
            Transparency = 1
        }):Play()
        TimescaleUtilities.Delay(1, function() -- line: 344
            -- upvalues: GoldenStunParticles (copy)
            GoldenStunParticles:Destroy()
        end)
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Ducky
v7 = {}

function v7.Enter(p20) -- line: 350
    -- upvalues: Particles (copy)
    if p20.DuckyParticles then
        return
    end

    p20.DuckyParticles = Particles.Duck:Clone()
    p20.DuckyParticles.Enabled = true
    p20.DuckyParticles.Parent = p20.Model.Head
end

function v7.Exit(p21) -- line: 358
    if p21.DuckyParticles then
        p21.DuckyParticles:Destroy()
        p21.DuckyParticles = nil
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Poison
v7 = {}

function v7.Enter(p22) -- line: 367
    -- upvalues: Particles (copy)
    if p22.PoisonParticles then
        return
    end

    p22.PoisonParticles = Particles.Poison:Clone()
    p22.PoisonParticles.Enabled = true
    p22.PoisonParticles.Parent = p22.Model.Head
end

function v7.Exit(p23) -- line: 375
    if p23.PoisonParticles then
        p23.PoisonParticles:Destroy()
        p23.PoisonParticles = nil
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Fire
v7 = {}

function v7.Enter(p24) -- line: 384
    -- upvalues: Effects (copy)
    if p24.FireParticles then
        return
    end

    local v9 = p24.Model:FindFirstChild("Torso") or p24.Model.PrimaryPart

    if v9 then
        p24.FireParticles = {}

        local Flames = Effects:WaitForChild("Particles"):WaitForChild("Flames")

        for _, child in pairs(Flames:GetChildren()) do
            local clone = child:Clone()

            clone.Parent = v9
            clone.Enabled = true
            table.insert(p24.FireParticles, clone)
        end
    end
end

function v7.Exit(p25) -- line: 404
    if p25.FireParticles then
        for _, v10 in pairs(p25.FireParticles) do
            v10:Destroy()
        end

        p25.FireParticles = nil
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Frozen
v7 = {}

function v7.Enter(p26) -- line: 416
    -- upvalues: TransientVFX (copy)
    if p26.FrozenParts then
        return
    end

    p26.FrozenParts = {}
    p26.AnchoredParts = {}
    p26.DestroyConnection = p26.OnDestroy:Connect(function() -- line: 423
        -- upvalues: p26 (copy)
        for _, v11 in pairs(p26.FrozenParts) do
            v11:Destroy()
        end
    end)

    local function v12(p27) -- line: 429
        -- upvalues: TransientVFX (copy)
        if not p27:IsA("BasePart") then
            return nil
        end

        local clone = p27:Clone()

        clone.Anchored = true
        clone.CFrame = p27.CFrame
        clone.Size = Vector3.new(p27.Size.X * 1.1, p27.Size.Y * 1.1, p27.Size.Z * 1.1)
        clone.BrickColor = BrickColor.new("Pastel light blue")
        clone.Material = Enum.Material.Glass
        clone.Transparency = 0.25

        if clone:IsA("MeshPart") then
            clone.TextureID = ""
        end

        local SpecialMesh = clone:FindFirstChildWhichIsA("SpecialMesh")

        if SpecialMesh then
            SpecialMesh.Scale = Vector3.new(SpecialMesh.Scale.X * 1.1, SpecialMesh.Scale.Y * 1.1, SpecialMesh.Scale.Z * 1.1)
            SpecialMesh.TextureId = ""
        end

        for _, descendant in pairs(clone:GetDescendants()) do
            if descendant:IsA("Decal") then
                descendant:Destroy()
            end
        end

        clone.Parent = workspace.Trash
        TransientVFX.track(clone, {
            profileName = "FrozenStatusPart"
        })

        return clone
    end

    for _, descendant in pairs(p26.Model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Anchored == false and descendant.Transparency == 0 then
            descendant.Anchored = true

            local v19 = v12(descendant)

            table.insert(p26.FrozenParts, v19)
            table.insert(p26.AnchoredParts, descendant)
        end
    end
end

function v7.Exit(p28) -- line: 481
    if p28.FrozenParts then
        p28.DestroyConnection:Disconnect()

        for _, v20 in pairs(p28.FrozenParts) do
            v20:Destroy()
        end

        for _, v21 in pairs(p28.AnchoredParts) do
            v21.Anchored = false
        end

        p28.FrozenParts = nil
        p28.AnchoredParts = nil
    end
end

t5[v3] = v7
v3 = _Enum.StunType.Spooky
v7 = {}

function v7.Enter(p29) -- line: 499
    -- upvalues: Animation (copy), Create (copy)
    if not p29.Spooked and p29.Model:FindFirstChild("AnimationController") then
        p29.Spooked = Animation.new({
            Id = 15046387335,
            Looped = true,
            Target = p29.Model.AnimationController
        }):Play()
    end

    if p29.SpookedSound or not p29.Model.PrimaryPart then
        return
    end

    p29.SpookedSound = Create("Sound", {
        SoundId = "rbxassetid://4678640322",
        Looped = true
    })
    p29.SpookedSound.Parent = p29.Model.PrimaryPart
    p29.SpookedSound:Play()
end

function v7.Exit(p30) -- line: 524
    if p30.Spooked then
        p30.Spooked:Stop()
        p30.Spooked = nil
    end

    if p30.SpookedSound then
        p30.SpookedSound:Destroy()
        p30.SpookedSound = nil
    end
end

t5[v3] = v7

local t6 = {}

t6[_Enum.StatusEffect.Frozen] = {
    Enter = function(p31) -- Enter | line: 540
        -- upvalues: ReplicatedStorage (copy), EmitterManager (copy), TransientVFX (copy), TweenService (copy)
        local PrimaryPart = p31.Model.PrimaryPart
        local Children = ReplicatedStorage.Assets.Effects.Misc.IceModels:GetChildren()

        p31.freezeWelds = {}
        p31.freezeParts = {}

        for _, descendant in pairs(p31.Model:GetDescendants()) do
            if descendant:IsA("Motor6D") and descendant.Part1 ~= PrimaryPart then
                local Part1 = descendant.Part1
                local WeldConstraint = Instance.new("WeldConstraint")

                WeldConstraint.Part0 = PrimaryPart
                WeldConstraint.Part1 = Part1
                WeldConstraint.Name = Part1.Name .. "_ICE_WELD"
                WeldConstraint.Enabled = true

                local clone = Children[math.random(1, #Children)]:Clone()

                WeldConstraint.Parent = clone

                local v22 = Part1.Size + Vector3.new(0.25, 0.25, 0.25)

                clone.Parent = workspace.Trash
                TransientVFX.track(clone, {
                    profileName = "FreezeStatusIce"
                })
                clone.Size = Vector3.new(0, 0, 0)
                clone.CFrame = Part1.CFrame
                clone.Weld.Part1 = Part1
                TweenService:Create(clone, TweenInfo.new(Random.new():NextNumber(0.1, 0.25), Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0), {
                    Size = v22
                }):Play()
                p31.Maid:Mark(clone)
                table.insert(p31.freezeWelds, WeldConstraint)
                table.insert(p31.freezeParts, clone)
            end
        end

        EmitterManager.Emit("Freeze", PrimaryPart.CFrame, nil, nil, nil, nil, {
            priority = "GameplayCritical"
        })
    end,
    Exit = function(p32) -- Exit | line: 590
        -- upvalues: TweenService (copy)
        if p32.freezeParts then
            for _, v24 in pairs(p32.freezeParts) do
                local v25 = Random.new():NextNumber(0.1, 0.25)

                TweenService:Create(v24, TweenInfo.new(v25, Enum.EasingStyle.Sine, Enum.EasingDirection.In, 0, false, 0), {
                    Transparency = 1
                }):Play()
                game.Debris:AddItem(v24, v25)
            end
        end

        if p32.freezeWelds then
            for _, v27 in pairs(p32.freezeWelds) do
                v27:Destroy()
            end
        end
    end
}
v7 = _Enum.StatusEffect.Cursed

local t7 = {}

function t7.Enter(p33) -- line: 619
    -- upvalues: ReplicatedStorage (copy)
    local CurseTower, v28, v29, v30

    if p33.Model:FindFirstChild("CurseTower") then
        v30 = true
    else
        CurseTower = ReplicatedStorage.Assets.Effects.Buffs:FindFirstChild("CurseTower")

        if CurseTower then
            v28 = math.abs(p33.Model.PrimaryPart.HeightOffset.Position.Y)
            v29 = if v28 > 1.15 then v28 * 2 else 5.5
            v30 = false
        else
            v30 = true
        end
    end

    if v30 then
        return
    end

    local v31 = v29 * 2
    local clone = CurseTower:Clone()

    clone:ScaleTo(v31)
    clone:PivotTo(p33.Model:GetPivot() * CFrame.new(0, v28, 0))
    clone.Parent = p33.Model
    p33._cursedEffect = clone
    p33.Maid:Mark(clone)
end

function t7.Exit(p34) -- line: 637
    local _cursedEffect = p34._cursedEffect

    if _cursedEffect then
        _cursedEffect:Destroy()
    end
end

t6[v7] = t7
v7 = _Enum.StatusEffect.Jailed
t7 = {}

function t7.Enter(p35) -- line: 646
    -- upvalues: ReplicatedStorage (copy), RunService (copy), Scheduler (copy), TransientVFX (copy), spr (copy)
    if p35.Model:GetAttribute("SuppressJailedVFX") then
        if p35._jailedEffect then
            p35._jailedEffect:Destroy()
            p35._jailedEffect = nil
        end
    else
        local Jail = p35.Model:FindFirstChild("Jail")
        local v32 = Jail
        local Jailed, v33, v34

        if not Jail and not p35.Model:FindFirstChild("CurseTower") then
            Jailed = ReplicatedStorage.Assets.Effects.Buffs:FindFirstChild("Jailed")

            if Jailed then
                v33 = math.abs(p35.Model.PrimaryPart.HeightOffset.Position.Y)
                v34 = if v33 > 1.15 then v33 * 2 else 5.5

                local v35 = v34 * 2
                local clone = Jailed:Clone()

                v32 = clone
                clone:ScaleTo(v35)
                clone:PivotTo(p35.Model:GetPivot() * CFrame.new(0, v33, 0))
                clone.Parent = workspace.Trash
                TransientVFX.track(clone, {
                    profileName = "JailedStatus"
                })
                p35._jailedEffect = clone
                p35.Maid:Mark(clone)

                local t8 = {
                    progress = 0
                }

                spr.target(t8, 0.55, 1, {
                    progress = 1
                })

                local v36 = v34
                local v37 = Scheduler.addDynamic("JailedModifier", RunService.RenderStepped, function() -- line: 676
                    -- upvalues: v32 (ref), v35 (copy), t8 (copy), v36 (copy)
                    local v38 = v35 - v36
                    local v39 = NumberSequence.new(1 - t8.progress)
                    local v40 = v32

                    v40:ScaleTo(v35 - v38 * t8.progress)
                    v32.Part.Chain1.Beam1.Transparency = v39
                    v32.Part.Chain1.Beam2.Transparency = v39
                    v32.Part.Chain2.Beam1.Transparency = v39
                    v32.Part.Chain2.Beam2.Transparency = v39
                end)

                spr.completed(t8, function() -- line: 686
                    -- upvalues: v37 (copy)
                    v37()
                end)
            end
        end
    end
end

function t7.Exit(p36) -- line: 692
    local _jailedEffect = p36._jailedEffect

    if _jailedEffect then
        _jailedEffect:Destroy()
        p36._jailedEffect = nil
    end
end

t6[v7] = t7

local t9 = {}
local t10 = {}
local t11 = {}
local t12 = {}
local t13 = {}
local t14 = {}
local v41

local function scheduleAbilityStateFlush() -- line: 711
    -- upvalues: RunService (copy), AbilitiesStore (copy), AbilityAmmoStore (copy), t13 (ref), t14 (ref), v41 (ref)
    v41 = v41 or RunService.Heartbeat:Connect(function() -- line: 716
        -- upvalues: AbilitiesStore (copy), AbilityAmmoStore (copy), t13 (ref), t14 (ref), v41 (ref)
        v41:Disconnect()
        v41 = nil
        debug.profilebegin("AbilityState_ClientFlush")

        local t15 = {}

        for _, v42 in t13 do
            table.insert(t15, v42)
        end

        t13 = {}

        local t16 = {}

        for _, v43 in t14 do
            table.insert(t16, v43)
        end

        t14 = {}

        if #t15 > 0 then
            AbilitiesStore.updateAbilities(t15)
        end

        if #t16 > 0 then
            AbilityAmmoStore.bulkUpdate(t16)
        end

        debug.profileend()
    end)
end

local function queueAbilityStateUpdate(p37) -- line: 746
    -- upvalues: RunService (copy), AbilitiesStore (copy), AbilityAmmoStore (copy), UserId (copy), t11 (copy), t12 (copy), t13 (ref), t14 (ref), v41 (ref)
    local v44 = t11[p37.uid]

    if v44 then
        if v44.Replicator:Get("OwnerId") == UserId then
            if p37.cooldownEnd ~= nil or p37.cooldownDuration ~= nil then
                local v45 = p37.name:gsub("[^%w]", "")
                local t17 = t13

                t17[tostring(p37.uid) .. "\000" .. v45] = {
                    model = v44.Model,
                    name = v45,
                    deltaTime = p37.cooldownEnd or 0,
                    maxDeltaTime = p37.cooldownDuration or 0
                }
            end

            if p37.ammo ~= nil or p37.maxAmmo ~= nil or p37.interval ~= nil or p37.startTick ~= nil or p37.syncPoint ~= nil then
                local v46 = p37.name .. tostring(p37.uid)
                local v47 = t14[v46]
                local v48 = if v47 then v47.payload else AbilityAmmoStore.getState()[v46] or {}
                local t18 = t14

                t18[v46] = {
                    id = v46,
                    payload = {
                        ammo = if p37.ammo == nil then v48.ammo else p37.ammo,
                        maxAmmo = if p37.maxAmmo == nil then v48.maxAmmo else p37.maxAmmo,
                        interval = if p37.interval == nil then v48.interval else p37.interval,
                        startTick = if p37.startTick == nil then v48.startTick else p37.startTick,
                        syncPoint = if p37.syncPoint == nil then v48.syncPoint else p37.syncPoint
                    }
                }
            end

            v41 = v41 or RunService.Heartbeat:Connect(function() -- line: 716
                -- upvalues: AbilitiesStore (copy), AbilityAmmoStore (copy), t13 (ref), t14 (ref), v41 (ref)
                v41:Disconnect()
                v41 = nil
                debug.profilebegin("AbilityState_ClientFlush")

                local t21 = {}

                for _, v49 in t13 do
                    table.insert(t21, v49)
                end

                t13 = {}

                local t22 = {}

                for _, v50 in t14 do
                    table.insert(t22, v50)
                end

                t14 = {}

                if #t21 > 0 then
                    AbilitiesStore.updateAbilities(t21)
                end

                if #t22 > 0 then
                    AbilityAmmoStore.bulkUpdate(t22)
                end

                debug.profileend()
            end)
        end
    else
        local v51 = t12[p37.uid]

        if not v51 then
            v51 = {}
            t12[p37.uid] = v51
        end

        table.insert(v51, p37)
    end
end

local function flushBufferedAbilityState(p38) -- line: 799
    -- upvalues: t12 (copy), queueAbilityStateUpdate (copy)
    local v52 = t12[p38]

    if v52 then
        t12[p38] = nil

        for _, v53 in v52 do
            queueAbilityStateUpdate(v53)
        end
    end
end

local function scanReplace(p39) -- line: 811
    -- upvalues: ReplicatedStorage (copy), NPCReplicator (copy), scanReplace (copy)
    local UnitReplicator = require(ReplicatedStorage.Client.Modules.Replicators.UnitReplicator)

    for v54, v55 in pairs(p39) do
        if typeof(v55) == "table" then
            scanReplace(v55)
        end

        if typeof(v55) == "Instance" and v55:IsA("Folder") then
            local v56 = NPCReplicator.GetNPCFromFolder(v55) or UnitReplicator.GetNPCFromFolder(v55)

            if v56 then
                p39[v54] = v56.Model
            end
        end
    end
end

local Replicate = Network.Channel("Replicate")

Replicate:On("TowerInstance", function(p40) -- line: 831
    -- upvalues: t10 (copy), scanReplace (copy)
    for _, v57 in p40 do
        task.spawn(function() -- line: 833
            -- upvalues: v57 (copy), t10 (copy), scanReplace (copy)
            local v58 = v57[2]
            local v59 = v57[1]
            local t23 = { table.unpack(v57, 3) }
            local v60 = t10[v58]

            scanReplace(t23)

            if v60 and v60.Executables then
                v60.Executables[v59](unpack(t23))
            end
        end)
    end
end)
Replicate:On("SetTowerStats", function(p41, p42, p43, p44, p45, p46) -- line: 850
    -- upvalues: TowerSignals (copy), Content (copy)
    local v61 = Content("Tower"):FindFirstChild(p41)

    assert(v61, (("Tower with name %* does not exist"):format(p41)))

    local Stats = require(v61.Stats)

    assert(Stats, (("Tower with name %* does not have stats"):format(p41)))

    local v64 = Stats.Stats[if p42 then "Golden" else "Default"] or Stats.Stats.Default

    if p46 then
        if p43 == "Defaults" then
            v64.Defaults[p46][p44] = p45
        else
            v64.Upgrades[p43][p46].Stats[p44] = p45
        end
    elseif p43 == "Defaults" then
        v64.Defaults[p44] = p45
    else
        v64.Upgrades[p43].Stats[p44] = p45
    end

    TowerSignals.StatsChanged:Fire(p41)
end)
Replicate:On("SetTowerDetection", function(p47, p48, p49, p50, p51, p52) -- line: 877
    -- upvalues: TowerSignals (copy), Content (copy)
    local v65 = Content("Tower"):FindFirstChild(p47)

    assert(v65, (("Tower with name %* does not exist"):format(p47)))

    local Stats = require(v65.Stats)

    assert(Stats, (("Tower with name %* does not have stats"):format(p47)))

    local v68 = Stats.Stats[if p48 then "Golden" else "Default"] or Stats.Stats.Default

    if p52 then
        if p49 == "Defaults" then
            local v69 = v68.Defaults[p52].Detections or {}

            v69[p50] = p51
            v68.Defaults[p52].Detections = v69
        else
            local v70 = v68.Upgrades[p49][p52].Stats.Detections or {}

            v70[p50] = p51
            v68.Upgrades[p49][p52].Stats.Detections = v70
        end
    elseif p49 == "Defaults" then
        local v71 = v68.Defaults.Detections or {}

        v71[p50] = p51
        v68.Defaults.Detections = v71
    else
        local v72 = v68.Upgrades[p49].Stats.Detections or {}

        v72[p50] = p51
        v68.Upgrades[p49].Stats.Detections = v72
    end

    TowerSignals.StatsChanged:Fire(p47)
end)

local Gizmo = DebugController.Gizmo

DebugController.createGizmo("Tower Targets", function() -- line: 917
    -- upvalues: t10 (copy), Gizmo (copy)
    Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(255, 250, 93))

    for _, v73 in t10 do
        local v74 = v73:FindTarget()

        if v74 then
            Gizmo.Ray:Draw(v73.Model.PrimaryPart.Position, v74:GetPivot().Position)
        end
    end
end)
DebugController.createGizmo("Tower Hitboxes", function() -- line: 930
    -- upvalues: t10 (copy), Gizmo (copy)
    Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(149, 255, 141))

    for v75 in t10 do
        local BoundingBox, BoundingBox2 = v75:GetBoundingBox()

        Gizmo.Box:Draw(BoundingBox, BoundingBox2, false)
    end
end)

function t1.getTowerByModel(p53) -- line: 939
    -- upvalues: t10 (copy)
    return t10[p53]
end

function t1.getTowerByUID(p54) -- line: 943
    -- upvalues: t11 (copy)
    return t11[p54]
end

function t1.getTowers() -- line: 947
    -- upvalues: t10 (copy)
    return t10
end

TimeField.setImmunityCheck(function(p55) -- line: 951
    -- upvalues: t10 (copy)
    local v76 = t10[p55]

    return v76 ~= nil and v76.Replicator:Get("TimeFieldImmune") == true
end)

function t1.waitForTowerByModel(p56) -- line: 956
    -- upvalues: t10 (copy)
    while not t10[p56] do
        task.wait()
    end

    return t10[p56]
end

if USE_OWNER_ABILITY_STATE then
    Troops:On("AbilityState", function(p57) -- line: 964
        -- upvalues: queueAbilityStateUpdate (copy)
        debug.profilebegin("AbilityState_ClientReceive")

        for _, v77 in p57 do
            queueAbilityStateUpdate(v77)
        end

        debug.profileend()
    end)
    task.defer(function() -- line: 974
        -- upvalues: Troops (copy)
        Troops:FireServer("AbilityStateReady")
    end)
end

function t1.new(p58, p59) -- line: 979
    -- upvalues: t1 (copy), AbilitiesStore (copy), AbilityAmmoStore (copy), TimeFieldParticles (copy), TimescaleUtilities (copy), TowerRangeRules (copy), TowerStore (copy), StatusEffectRenderer (copy), TagReplicator (copy), HumanoidUtil (copy), ParticleLODController (copy), TaggedInstances (copy), TweenService (copy), Animation (copy), Asset (copy), _Enum (copy), Maid (copy), Signal (copy), USE_OWNER_ABILITY_STATE (copy), getAvailableAbilities (copy), t4 (copy), t5 (copy), t6 (copy), t9 (copy), t10 (copy), t11 (copy), t12 (copy), queueAbilityStateUpdate (copy)
    local Name = p59:WaitForState("Name")
    local v78 = Asset("Troops", Name)

    if not v78 then
        return
    end

    local v79 = {
        Model = p58.Parent
    }
    local v80 = setmetatable(v78.Animator, t1)
    local v81 = setmetatable(v79, v80)

    v81.Name = Name
    v81.Path = p59:Get("Path") or 0
    v81.FBXModel = HumanoidUtil.findFirstRigBone(v81.Model)
    v79, v80 = HumanoidUtil.createAnimationHost(v81.Model, v81.FBXModel ~= nil)
    v81.AnimationController = v79
    v81.AnimationAnimator = v80
    v81.BoneVFX = v81.Model:FindFirstChild("BoneVFX")
    v81.UID = p59:Get("UID")
    v81.Maid = Maid.new()
    v81.Maid:Mark(TimeFieldParticles.track(v81.Model))
    v81.Reposition = Maid.new()

    local function clearSuppressedJailedVFX() -- line: 1003
        -- upvalues: v81 (copy)
        if v81.Model:GetAttribute("SuppressJailedVFX") and v81._jailedEffect then
            v81._jailedEffect:Destroy()
            v81._jailedEffect = nil
        end
    end

    v81.Maid:Mark(v81.Model:GetAttributeChangedSignal("SuppressJailedVFX"):Connect(function() -- line: 1011
        -- upvalues: v81 (copy)
        if v81.Model:GetAttribute("SuppressJailedVFX") and v81._jailedEffect then
            v81._jailedEffect:Destroy()
            v81._jailedEffect = nil
        end
    end))

    if v81.Model:GetAttribute("SuppressJailedVFX") and v81._jailedEffect then
        v81._jailedEffect:Destroy()
        v81._jailedEffect = nil
    end

    v81.Replicator = p59
    v81.OnDestroy = Signal.new()
    v81.OnUpgrade = Signal.new()
    v81.OnAbilitiesUpdated = Signal.new()
    v81.Queues = TagReplicator.getReplicatorEntityFromFolder(v81.Model:WaitForChild("Queues"))
    v81.Maid:Mark(v81.OnUpgrade)
    v81.Maid:Mark(v81.Queues)
    v81.PrimaryPart = v81.Model.PrimaryPart
    v81.AllOptions = v78.UpgradeOptions or {}
    v81.Options = {}
    v81.Tagged = TaggedInstances.getTaggedInstances(v81.Model)

    for _, v82 in v81.AllOptions do
        v81.Options[v82.Name] = v82.Default
    end

    t10[v81.Model] = v81
    t11[v81.UID] = v81
    v80 = v81.UID

    local Animator = t12[v80]

    if Animator then
        t12[v80] = nil

        for _, v83 in Animator do
            queueAbilityStateUpdate(v83)
        end
    end

    ParticleLODController.registerModel(v81.Model, function() -- line: 1041
        -- upvalues: v81 (copy)
        return v81.Model.PrimaryPart and v81.Model.PrimaryPart.Position or Vector3.new(0, 0, 0)
    end)
    v81.Maid:Mark(function() -- line: 1044
        -- upvalues: v81 (copy), ParticleLODController (copy), t10 (copy), t11 (copy)
        v81.PrimaryPart = nil
        t10[v81.Model] = nil

        if t11[v81.UID] == v81 then
            t11[v81.UID] = nil
        end

        ParticleLODController.unregisterModel(v81.Model)
    end)
    p59:Hook(v81)
    v81.Asset = v78
    v81.RangeBoostImmune = TowerRangeRules.isBoostImmune(v78)

    local v84, v85

    if v81.GoldenPerks and v78.Stats.Golden then
        v80 = v78.Stats.Golden

        if v80 then
            v84 = v80
            v85 = true
        else
            v85 = false
        end
    else
        v85 = false
    end

    if not v85 then
        v84 = v78.Stats.Default
    end

    v81.Sellback = v84.Defaults.Sellback
    v81.Stats = v84
    v81.TowerName = Name
    v81.Deadzone = v81.Stats.Attributes and v81.Stats.Attributes.Deadzone or 0
    Animator = if v81.Stats.Attributes then v81.Stats.Attributes.Buildzone or v81.Stats.Attributes.FortifyRadius or 0 else 0
    v81.Buildzone = Animator
    v81.CFrame = (v81.Model:FindFirstChild("HumanoidRootPart") or v81.Model.PrimaryPart).CFrame
    v81.UpdatedCFrame = false
    v81.Target = v81.Model:FindFirstChild("Target")
    v81.Upgrades = v81.Model:WaitForChild("Upgrades")
    v81.Animations = v81.Model:WaitForChild("Animations")
    Name = v81.Model.PrimaryPart.Position
    Animator = v81.Model:GetPivot().Position.Y - Name.Y
    v81.BottomPosition = v81.Model.PrimaryPart.HeightOffset.WorldPosition
    v81.Maid:Mark(v81.Model.PrimaryPart:GetPropertyChangedSignal("Position"):Connect(function() -- line: 1078
        -- upvalues: v81 (copy)
        v81.BottomPosition = v81.Model.PrimaryPart.HeightOffset.WorldPosition

        local v86 = CFrame.new(v81.BottomPosition) * CFrame.Angles(0, 0, 3.141592653589793)

        if v81.DamageBuffEffect then
            v81.DamageBuffEffect:PivotTo(v86)
        end

        if v81.CooldownBuffEffect then
            v81.CooldownBuffEffect:PivotTo(v86)
        end

        if v81.RangeBuffEffect then
            v81.RangeBuffEffect:PivotTo(v86)
        end
    end))
    v81.Upgrade = p59:Get("Upgrade")
    v81.State = {
        Type = p59:Get("Name"),
        Owner = p59:Get("Owner"),
        Target = p59:Get("Target"),
        Upgrade = p59:Get("Upgrade"),
        Cooldown = p59:Get("Cooldown"),
        TargetingMode = p59:Get("TargetingMode")
    }
    Animator = p59.Folder:WaitForChild("StatusEffects")

    if Animator then
        v81.StatusEffectRenderer = StatusEffectRenderer.new(v81, Animator)
        v81.StatusEffects = v81.StatusEffectRenderer
        v81.Maid:Mark(v81.StatusEffectRenderer)
    end

    v81.Stuns = TagReplicator.getReplicatorEntityFromFolder(p59.Folder:WaitForChild("Stuns"))
    v81.BuffEffects = TagReplicator.getReplicatorEntityFromFolder(p59.Folder:WaitForChild("AbilityEffects"))
    v81.Attributes = TagReplicator.getReplicatorEntityFromFolder(p59.Folder:WaitForChild("Attributes"))
    v81.Abilities = TagReplicator.getReplicatorEntityFromFolder(p59.Folder:WaitForChild("Abilities"))
    v81.AbilityDataReplicator = TagReplicator.getReplicatorEntityFromFolder(p59.Folder:WaitForChild("AbilityData"))
    v81.Maid:Mark(v81.Stuns)
    v81.Maid:Mark(v81.BuffEffects)
    v81.Maid:Mark(v81.Attributes)
    v81.Maid:Mark(v81.Abilities)
    v81.Maid:Mark(v81.AbilityDataReplicator)
    v81.AvailableAbilities = {}
    v81.AbilityCallbacks = {}
    v81.AvailableAbilities = getAvailableAbilities(v84.Defaults.Abilities, v81.State.Upgrade, v81.Path)

    for v87, v88 in pairs(v81.State) do
        v81.State[v87] = v88
    end

    local v89 = v81.Maid

    v89:Mark(p59.Changed:Connect(function(p60, p61) -- line: 1136
        -- upvalues: v81 (copy), v84 (ref), getAvailableAbilities (copy)
        v81.State[p60] = p61
        v81.Stats[p60] = p61

        if p60 ~= "Path" then
            return
        end

        v81.Path = p61 or 0
        v81.AvailableAbilities = getAvailableAbilities(v84.Defaults.Abilities, v81.Upgrade, v81.Path)
        v81.OnAbilitiesUpdated:Fire(v81.AvailableAbilities)
    end))
    v81.Maid:Mark(v81.Attributes.Changed:Connect(function(p62, p63) -- line: 1148
        -- upvalues: v81 (copy)
        v81.Stats.Attributes[p62] = p63
    end))

    if not USE_OWNER_ABILITY_STATE then
        v81.Maid:Mark(v81.Abilities.Changed:Connect(function(p64, p65) -- line: 1153
            -- upvalues: v81 (copy), AbilitiesStore (copy)
            local v90, v91

            if p65 then
                v90, v91 = p65:match("^([^,]+),([^,]+)$")
            else
                v90 = 0
                v91 = 0
            end

            AbilitiesStore.updateAbility(v81.Model, p64, tonumber(v90), (tonumber(v91)))
        end))
    end

    v81.Animations = {}

    local AnimationController = v81.Model:FindFirstChild("AnimationController")

    if AnimationController then
        local function register(p66, p67, p68) -- line: 1170
            -- upvalues: v81 (copy), AnimationController (copy), Animation (copy)
            local v92 = v81.Animations[p66]

            if not v92 then
                v92 = {}
                v81.Animations[p66] = v92
            end

            if not v92[p67] then
                v92[p67] = Animation.new({
                    IgnorePriority = true,
                    IsPersistent = true,
                    Preload = true,
                    Track = p68,
                    Target = AnimationController,
                    Entity = v81
                })
            end
        end

        v89 = v81.Model:WaitForChild("Animations")

        for _, child in v89:GetChildren() do
            if child:IsA("Animation") then
                register(child.Name, "0", child)
            else
                for _, child2 in child:GetChildren() do
                    if child2:IsA("Animation") then
                        register(child.Name, child2.Name, child2)
                    end
                end
            end
        end

        for _, child in v89:GetChildren() do
            for _, child in child:GetChildren() do
                if not child:IsA("Animation") then
                    for _, child2 in child:GetChildren() do
                        if child2:IsA("Animation") then
                            register(child2.Name, child.Name, child2)
                        end
                    end
                end
            end
        end
    end

    v81.Upgrades_D = v78.Upgrades
    v81.Stats = {}
    v81.Stats.Attributes = {}

    for v93, v94 in p59:GetAllStates() do
        v81.Stats[v93] = v94
    end

    for v95, v96 in v81.Attributes:GetAllStates() do
        v81.Stats.Attributes[v95] = v96
    end

    local v97

    if not USE_OWNER_ABILITY_STATE then
        for v98, v99 in v81.Abilities:GetAllStates() do
            local State

            State, v97 = v99:match("^([^,]+),([^,]+)$")
            AbilitiesStore.updateAbility(v81.Model, v98, tonumber(State), (tonumber(v97)))
        end
    end

    v81._idleAnimation = nil
    v81:Initialize()
    v81.Maid:Mark(v81.Replicator:GetStateChangedSignal("Position"):Connect(function(_) -- line: 1250
        -- upvalues: v81 (copy)
        v81.CFrame = (v81.Model:FindFirstChild("HumanoidRootPart") or v81.Model.PrimaryPart).CFrame
        v81.UpdatedCFrame = true
    end))
    v81.Maid:Mark(v81.Replicator:GetStateChangedSignal("Upgrade"):Connect(function(p70) -- line: 1255
        -- upvalues: v81 (copy), v84 (ref), getAvailableAbilities (copy)
        local v100 = getAvailableAbilities(v84.Defaults.Abilities, p70, v81.Path)

        v81.Upgrade = p70
        v81.AvailableAbilities = v100
        v81.OnAbilitiesUpdated:Fire(v100)
        v81:DoUpgrade(p70, v81.Path)
        v81:Animate("Idle", {
            Priority = Enum.AnimationPriority.Core
        })
    end))
    v78 = v81.Path
    v89 = v81.Upgrade
    v81.UpgradeFolder = v81.Model.Upgrades:FindFirstChild((("%*%*"):format(v89, v78)))

    if not v81.UpgradeFolder then
        v81.UpgradeFolder = v81.Model.Upgrades:FindFirstChild((tostring(v89)))
    end

    v81.Maid:Mark(v81.Model.ChildAdded:Connect(function(p71) -- line: 1275
        -- upvalues: v81 (copy)
        if p71.Name == "Target" then
            v81.Target = p71
        end
    end))

    local function updateHidenModel(p72) -- line: 1281
        -- upvalues: v81 (copy), TimescaleUtilities (copy), TweenService (copy), _Enum (copy)
        if v81.Replicator:Get(_Enum.StatusEffect.Hologram) then
            if p72 then
                v81.Model:SetAttribute("Flying", true)

                for _, descendant in v81.Model:GetDescendants() do
                    if descendant:IsA("BasePart")
                        or descendant:IsA("Decal")
                        or descendant:IsA("Texture")
                        or descendant:IsA("ParticleEmitter")
                        or descendant:IsA("Beam")
                        or descendant:IsA("Trail") then
                        descendant.LocalTransparencyModifier = 1

                        if descendant:IsA("BasePart") then
                            descendant.CanQuery = false
                        end
                    end
                end
            else
                v81.Model:SetAttribute("Flying", false)

                for _, descendant in v81.Model:GetDescendants() do
                    if descendant:IsA("BasePart") or descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") or descendant:IsA("Trail") then
                        if descendant:IsA("BasePart") then
                            descendant.CanQuery = true
                        end

                        TimescaleUtilities.Delay(Random.new():NextNumber(0, 1.25), function() -- line: 1315
                            -- upvalues: descendant (copy), TweenService (copy)
                            TweenService:Create(descendant, TweenInfo.new(2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
                                LocalTransparencyModifier = 0
                            }):Play()
                        end)
                    end
                end
            end
        end
    end

    v81.Maid:Mark(v81.Replicator:GetStateChangedSignal("HideModel"):Connect(updateHidenModel))
    updateHidenModel(v81.Replicator:Get("HideModel"))

    local Changed

    if v81.StatusEffectRenderer then
        for v102, v103 in t6 do
            if v103 then
                v97 = v81.Maid
                Changed = v81.StatusEffectRenderer.Changed
                v97:Mark(Changed:Connect(function(p73, p74) -- line: 1340
                    -- upvalues: v81 (copy), v103 (copy), v102 (copy)
                    if p73 == v102 then
                        if p74 then
                            v103.Enter(v81)
                        else
                            v103.Exit(v81)
                        end
                    end
                end))

                if v81.StatusEffectRenderer:has(v102) then
                    v103.Enter(v81)
                end
            end
        end
    end

    for _, v104 in pairs(_Enum.BuffType) do
        if t4[v104] then
            v97 = v81.Maid
            Changed = v81.BuffEffects:GetStateChangedSignal(v104)
            v97:Mark(Changed:Connect(function(p75) -- line: 1365
                -- upvalues: v81 (copy), v104 (copy), t4 (copy)
                if p75 then
                    t4[v104].Enter(v81)
                else
                    t4[v104].Exit(v81)
                end
            end))

            if v81.BuffEffects:Get(v104) then
                t4[v104].Enter(v81)
            end

            continue
        end

        warn("Missing buff function for " .. tostring(v104))
    end

    for _, v105 in pairs(_Enum.StunType) do
        if t5[v105] then
            v97 = v81.Maid
            Changed = v81.Stuns:GetStateChangedSignal(v105)
            v97:Mark(Changed:Connect(function(p76) -- line: 1385
                -- upvalues: v81 (copy), v105 (copy), t5 (copy)
                if p76 then
                    t5[v105].Enter(v81)
                else
                    t5[v105].Exit(v81)
                end
            end))
        else
            warn("Missing stun function for " .. tostring(v105))
        end
    end

    for i = 1, p59:Get("Upgrade") do
        v81:DoUpgrade(i, v81.Path)
    end

    v81:Animate("Idle", {
        Priority = Enum.AnimationPriority.Core
    })
    t9[v81] = v81
    v81.Maid:Mark(function() -- line: 1402
        -- upvalues: v81 (copy), AbilitiesStore (copy), AbilityAmmoStore (copy), TowerStore (copy), t9 (copy)
        TowerStore.removeTower(v81.Model, v81)
        AbilitiesStore.removeTower(v81.Model)
        AbilityAmmoStore.removeTower(v81.UID)
        t9[v81] = nil
    end)
    TowerStore.addTower(v81.Model, p59, v81)

    return v81
end

function t1.ScanReplace(_, p78) -- line: 1414
    -- upvalues: scanReplace (copy)
    scanReplace(p78)

    return p78
end

function t1.toggleFigure8(p79, p80) -- line: 1419
    -- upvalues: UpgradesStore (copy)
    UpgradesStore.setFigure8Enabled(p80)
    p79.Figure8 = p80
end

function t1.StopPlacement(_) -- line: 1424
    -- upvalues: ReplicatedStorage (copy)
    require(ReplicatedStorage.Shared.Modules.SharedGameFunctions).StopPlacement()
end

function t1.DeselectTowers(_) -- line: 1429
    -- upvalues: ReplicatedStorage (copy), AbilityIndicatorStore (copy), UpgradesStore (copy)
    local NewPlacementController = require(ReplicatedStorage.Client.Controllers.Game.NewPlacementController)

    AbilityIndicatorStore.update({})
    UpgradesStore.updateTower({
        enabled = false,
        showBoundaries = false,
        valid = false,
        model = nil,
        flightRange = nil,
        range = 0,
        boundary = 0,
        deadzone = 0,
        buildzone = 0
    })
    NewPlacementController:Stop()
end

function t1.GetExplosionRadiusMultiplier(p83) -- line: 1449
    -- upvalues: GameRules (copy), SkillsUtil (copy), _Enum (copy)
    if p83.OwnerId then
        local t24 = {
            UserId = p83.OwnerId
        }

        if GameRules.HasSkill(_Enum.SkillTreeNode.SplashDamage) then
            return 1 + SkillsUtil.skillEval(t24, _Enum.SkillTreeNode.SplashDamage) / 100
        end
    end

    return 1
end

function t1.ToggleReposition(p84, p85) -- line: 1469
    -- upvalues: ReplicatedStorage (copy), RunService (copy), PathPlacementCursorController (copy), UpgradesStore (copy), Scheduler (copy), Sound (copy), _Enum (copy)
    p84.Reposition:Sweep()

    local Name = p85.towerData and p85.towerData.Name or p84.Name
    local NewPlacementController = require(ReplicatedStorage.Client.Controllers.Game.NewPlacementController)

    if not p85.enabled then
        UpgradesStore.updateTower({
            enabled = false,
            showBoundaries = false,
            valid = false,
            model = nil,
            flightRange = nil,
            range = 0,
            boundary = 0,
            deadzone = 0,
            buildzone = 0
        })
        NewPlacementController:CleanHighlights()

        return
    end

    local SharedGameFunctions = require(ReplicatedStorage.Shared.Modules.SharedGameFunctions)

    p84.Reposition:Mark(Scheduler.addDynamic("TowerReposition", RunService.Heartbeat, function(_) -- line: 1485
        -- upvalues: p84 (copy), p85 (copy), Name (copy), SharedGameFunctions (copy), PathPlacementCursorController (copy)
        local CurrentPosition = PathPlacementCursorController.CurrentPosition

        PathPlacementCursorController.CantPlace = not SharedGameFunctions.CheckTowerCollisions(Name, CurrentPosition, p84.Team, nil, p85.ignoredTower)
    end))
    Sound("Click"):Play()
    UpgradesStore.updateTower({
        enabled = false,
        showBoundaries = true,
        valid = true,
        range = 0,
        flightRange = 0,
        deadzone = 0,
        buildzone = 0,
        model = p84.Model,
        tower = Name,
        boundary = p85.range * 2
    })
    NewPlacementController:ShowHighlights(p85.towerData and p85.towerData.Class or _Enum.TowerType.Ground)
end

function t1.Frozen(p87, p88) -- line: 1534
    -- upvalues: TransientVFX (copy)
    local t25 = {}

    local function v107(p89, p90) -- line: 1539
        -- upvalues: TransientVFX (copy)
        if not p89:IsA("BasePart") then
            return nil
        end

        local clone = p89:Clone()

        clone.Anchored = true
        clone.CFrame = p89.CFrame
        clone.Size = Vector3.new(p89.Size.X * 1.1, p89.Size.Y * 1.1, p89.Size.Z * 1.1)
        clone.BrickColor = BrickColor.new("Pastel light blue")
        clone.Material = Enum.Material.Glass
        clone.Transparency = 0.25

        if clone:IsA("MeshPart") then
            clone.TextureID = ""
        end

        local SpecialMesh = clone:FindFirstChildWhichIsA("SpecialMesh")

        if SpecialMesh then
            SpecialMesh.Scale = Vector3.new(SpecialMesh.Scale.X * 1.1, SpecialMesh.Scale.Y * 1.1, SpecialMesh.Scale.Z * 1.1)
            SpecialMesh.TextureId = ""
        end

        for _, descendant in pairs(clone:GetDescendants()) do
            if descendant:IsA("Decal") then
                descendant:Destroy()
            end
        end

        clone.Parent = workspace.CurrentCamera
        TransientVFX.track(clone, {
            profileName = "TowerFreezeClone",
            ttl = p90
        })
        game.Debris:AddItem(clone, p90)

        return clone
    end

    for _, descendant in pairs(p87.Model:GetDescendants()) do
        if descendant:IsA("BasePart") and descendant.Anchored == false and descendant.Transparency == 0 then
            table.insert(t25, descendant)
            descendant.Anchored = true
            v107(descendant, p88)
        end
    end

    p87:Delay(p88, function() -- line: 1591
        -- upvalues: t25 (copy)
        for _, v114 in pairs(t25) do
            v114.Anchored = false
        end
    end)
end

function t1.Face(p91, p92, p93, p94, p95) -- line: 1604
    -- upvalues: TweenService (copy)
    local PrimaryPart = p91.Model.PrimaryPart
    local PrimaryPartPosition = PrimaryPart.Position
    local v115 = if p95 then p92 else Vector3.new(p92.X, PrimaryPartPosition.Y, p92.Z)
    local v116 = CFrame.lookAt(PrimaryPartPosition, v115)

    if v115:FuzzyEq(PrimaryPartPosition, 1E-05) then
        return
    end

    if p94 ~= false then
        if p93 then
            TweenService:Create(PrimaryPart, p93, {
                CFrame = v116
            }):Play()

            return v116
        end

        p91.Model.PrimaryPart.CFrame = v116
    end

    return v116
end

function t1.UpdateCFrame(p96, p97) -- line: 1640
    p96.CFrame = p97
    p96.UpdatedCFrame = true
end

function t1.Thread(p98, p99) -- line: 1652
    p98.ThreadFunction = p99
    p98._threadCo = nil
    p98._threadDelayRemaining = 0
end

function t1.Wait(_, p101) -- line: 1665
    -- upvalues: TimescaleUtilities (copy)
    return TimescaleUtilities.Wait(p101)
end

function t1.Delay(p102, p103, p104) -- line: 1677
    -- upvalues: TimescaleUtilities (copy)
    if p104 then
        return TimescaleUtilities.Delay(p103, p104)
    end

    p102:Wait(p103)
end

function t1.Tween(_, p106, p107, p108) -- line: 1695
    -- upvalues: TweenService (copy), GameState (copy)
    return TweenService:Create(p106, TweenInfo.new(p107.Time / GameState.TimeScale, p107.EasingStyle, p107.EasingDirection, p107.RepeatCount, p107.Reverses, p107.DelayTime / GameState.TimeScale), p108)
end

function t1.FindTarget(p109, p110) -- line: 1708
    -- upvalues: NPCReplicator (copy)
    if p109.Target then
        if p110 then
            return p109.Target.Value
        end

        local v118 = NPCReplicator.GetNPCFromFolder(p109.Target.Value)

        return v118 and v118.Model or nil
    end
end

function t1.GetLevel(p111) -- line: 1721
    return p111.Upgrade
end

function t1.GetBuffCount(p112, p113) -- line: 1725
    return p112.Replicator:Get(p113 .. "Buff") or 0
end

local function getEnhancedOpticsRangeBonus(p114) -- line: 1729
    -- upvalues: GameRules (copy), SkillsUtil (copy), _Enum (copy)
    if p114.OwnerId and GameRules.HasSkill(_Enum.SkillTreeNode.EnhancedOptics) then
        local t26 = {
            UserId = p114.OwnerId
        }

        return p114.Stats.Range * SkillsUtil.skillEval(t26, _Enum.SkillTreeNode.EnhancedOptics) / 100
    end

    return 0
end

function t1.GetRange(p115) -- line: 1740
    -- upvalues: TowerRangeRules (copy), GameRules (copy), GameState (copy), getEnhancedOpticsRangeBonus (copy)
    return TowerRangeRules.calculate({
        baseRange = p115.Replicator:Get("Range"),
        rangeBuffPercent = p115:GetBuffCount("Range"),
        scaredPercent = p115:GetBuffCount("Scared"),
        skillBonus = getEnhancedOpticsRangeBonus(p115),
        fogEnabled = GameState.IsModifierEnabled("Fog"),
        towerRangeMultiplier = GameRules.Get("TowerRangeMultiplier") or 1,
        boostImmune = p115.RangeBoostImmune == true
    })
end

function t1.GetCooldown(p116) -- line: 1752
    local v119 = p116.Cooldown * (p116.CooldownBuff / 100)
    local v120 = p116.Cooldown * (p116.FatigueBuff / 100)

    return (math.clamp(p116.Cooldown - v119 + v120, 0.02, 1e999))
end

function t1.Bullet(_, p118) -- line: 1761
    -- upvalues: Laser (copy), v1 (copy)
    if p118.End == nil or p118.Start == nil then
        return
    end

    local Magnitude = (p118.Start - p118.End).Magnitude
    local v126 = CFrame.new(p118.Start, p118.End) * CFrame.Angles(math.rad(v1:NextNumber(-p118.Spread, p118.Spread) / Magnitude), math.rad(v1:NextNumber(-p118.Spread, p118.Spread) / Magnitude), 0)

    Laser:Cast({
        Start = v126.p,
        Pos = v126 * CFrame.new(0, 0, -Magnitude).Position,
        Color = if p118.NoColor then nil else p118.Color or BrickColor.new("Cork").Color,
        Transparency = p118.Transparency or 0.1,
        Size = p118.Size or 0.04,
        Fade = p118.Speed or 90,
        Type = "Bullet",
        Bullet = p118.Bullet or "Normal",
        Reversed = p118.Reversed
    })
end

function t1.GetMaxAmmo(p119) -- line: 1799
    return p119.MaxAmmo
end

function t1.GetAnimation(p120, p121) -- line: 1803
    local v127 = p120.Animations[p121]

    if not v127 then
        return nil
    end

    local v128 = if p120.Path and p120.Path > 0 then string.char(96 + p120.Path) else nil
    local Upgrade = p120.Upgrade
    local v130

    for i = 0, Upgrade do
        if v128 and v127[("%*%*"):format(i, v128)] then
            v130 = v127[("%*%*"):format(i, v128)]
        elseif v127[tostring(i)] then
            v130 = v127[tostring(i)]
        end
    end

    return v130
end

function t1.Animate(p122, p123, p124, p125) -- line: 1823
    if p123 == "Idle" and p122._idleAnimation then
        p122._idleAnimation:Stop()
        p122._idleAnimation = nil
    end

    local Animation = p122:GetAnimation(p123)

    if not Animation then
        return
    end

    if p124 then
        for v131, v132 in pairs(p124) do
            Animation[v131] = v132
        end
    end

    if p123 == "Idle" then
        p122._idleAnimation = Animation
    end

    return Animation:Play(p125 and unpack(p125))
end

function t1.DoUpgrade(p126, p127, p128) -- line: 1846
    -- upvalues: Upgrades (copy)
    local v133

    if p126.Model:FindFirstChild("UpgradesModule") then
        v133 = Upgrades.upgrade(p126, p127, "tower")
    elseif p126.Asset.Upgrades then
        local v134 = p126.Asset.Upgrades[p127]

        v133 = v134 and v134(p126.Model, p126.Model.Upgrades:FindFirstChild((tostring(p127))), p126)
    end

    local v135 = if p128 and p128 > 0 then string.char(p128 + 96) else nil

    p126.UpgradeFolder = p126.Model.Upgrades:FindFirstChild((("%*%*"):format(p127, v135)))

    if not p126.UpgradeFolder then
        p126.UpgradeFolder = p126.Model.Upgrades:FindFirstChild((tostring(p127)))
    end

    p126.OnUpgrade:Fire(p127, p128)

    return v133
end

local function currentTimeScale() -- line: 1873
    -- upvalues: GameState (copy)
    local State = GameState.State

    return State and State.TimeScale or GameState.TimeScale or 1
end

function t1.Step(p129, p130) -- line: 1879
    -- upvalues: NPCUtils (copy), GameState (copy)
    if p129.OnStepFunction then
        debug.profilebegin("TowerOnStepFunction")
        p129.OnStepFunction(p130)
        debug.profileend()
    end

    debug.profilebegin("TowerThreadStep")

    local stepThread = NPCUtils.stepThread
    local State = GameState.State

    stepThread(p129, p130 * (State and State.TimeScale or GameState.TimeScale or 1))
    debug.profileend()
end

function t1.InvokeServer(p131, p132, ...) -- line: 1891
    -- upvalues: Troops (copy)
    local t28 = { ... }

    if #t28 == 0 then
        return
    end

    return Troops:InvokeServer("TowerServerEvent", p132, p131.Model, table.unpack(t28))
end

function t1.FireServer(p133, p134, ...) -- line: 1905
    -- upvalues: Troops (copy)
    local t29 = { ... }

    if #t29 ~= 0 then
        Troops:FireServer("TowerServerEvent", p134, p133.Model, table.unpack(t29))
    end
end

function t1.IsAlive(p135) -- line: 1914
    return p135.Maid ~= nil
end

function t1.Destroy(p136) -- line: 1918
    -- upvalues: _Enum (copy), t3 (copy), t4 (copy), t5 (copy), t6 (copy)
    local DeathEffect = p136.Replicator:Get("DeathEffect")

    if DeathEffect and t3[DeathEffect] then
        t3[DeathEffect](p136)
    end

    for _, v137 in pairs(_Enum.BuffType) do
        if t4[v137] then
            t4[v137].Exit(p136)
        end
    end

    for _, v138 in pairs(_Enum.StunType) do
        if t5[v138] then
            t5[v138].Exit(p136)
        end
    end

    for _, v139 in t6 do
        v139.Exit(p136)
    end

    if p136.Maid then
        p136.OnDestroy:Fire()
        p136.Maid:Sweep()
        p136.Maid = nil
    end

    if p136._threadCo then
        coroutine.close(p136._threadCo)
        p136._threadCo = nil
    end
end

Scheduler.bindToSimulation("TowerReplicator", function(p137) -- line: 1958
    -- upvalues: t9 (copy)
    debug.profilebegin("TowerReplicator")

    local t30 = {}
    local t31 = {}

    debug.profilebegin("TowerReplicatorStepLoop")

    local n2 = 0
    local v140 = false

    for _, v141 in t9 do
        v141.UpdatedCFrame = false
        v141:Step(p137)

        if v141.UpdatedCFrame then
            n2 += 1
            t30[n2] = v141.Model.PrimaryPart
            v140 = true
            t31[n2] = v141.CFrame
        end
    end

    debug.profileend()

    if v140 then
        debug.profilebegin("TowerReplicatorBulkMoveTo")
        workspace:BulkMoveTo(t30, t31, Enum.BulkMoveMode.FireCFrameChanged)
        debug.profileend()
    end

    debug.profileend()
end, Enum.StepFrequency.Hz15)
TagReplicator.hook("Tower", function(p138, p139) -- line: 1996
    -- upvalues: t1 (copy)
    return (t1.new(p138, p139))
end)

return t1
