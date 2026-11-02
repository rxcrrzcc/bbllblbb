--ОГРОМНЫЙ модуль как я понимаю. Projectile
-- https://lua.expert

local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local EmitterManager = require(ReplicatedStorage.Shared.Modules.EmitterManager)
local GameState = require(ReplicatedStorage.Shared.Modules.GameState)
local ProjectilePath = require(ReplicatedStorage.Shared.Modules.ProjectilePath)
local Scheduler = require(ReplicatedStorage.Shared.Modules.Scheduler)
local TimeField = require(ReplicatedStorage.Shared.Modules.TimeField)
local TypedPromise = require(ReplicatedStorage.Shared.Modules.TypedPromise)
local v1 = RunService:IsServer()
local v2 = if v1 then nil else require(ReplicatedStorage.Shared.Modules.ProjectilePool)
local t1 = {}
local Container = v1 and require(ServerStorage.Server.Modules.NPC).Container or workspace
local t2 = {}
local TimescaleUtilities = require(ReplicatedStorage.Shared.Modules.TimescaleUtilities)
local _Enum = require(ReplicatedStorage.Shared.Modules.Enum)
local math = require(ReplicatedStorage.Shared.Modules.Utils.math)
local Heartbeat = v1 and RunService.Heartbeat or RunService.RenderStepped
local v3 = Random.new()
local n1 = 0

local function isPointInsidePart(p1, p2) -- line: 37
    -- upvalues: math (copy)
    local v4 = p2.CFrame:PointToObjectSpace(p1)
    local v5 = p2.Size * 0.5

    if math.abs(v4.X) <= v5.X and math.abs(v4.Y) <= v5.Y then
        return math.abs(v4.Z) <= v5.Z
    end

    return false
end

local function emitProjectileHitParticles(p3) -- line: 46
    -- upvalues: EmitterManager (copy), math (copy)
    local DamageEmitter = p3:FindFirstChild("DamageEmitter")

    if DamageEmitter and DamageEmitter:IsA("ParticleEmitter") then
        EmitterManager.emitParticle(DamageEmitter, math.random(5, 10), p3)
    end

    local HitEmitter = p3:FindFirstChild("HitEmitter")

    if HitEmitter and HitEmitter:IsA("ParticleEmitter") then
        EmitterManager.emitParticle(HitEmitter, 1, p3)
    end
end

local function playPierceHitSound(p4, p5) -- line: 58
    -- upvalues: TimescaleUtilities (copy), v3 (copy), n1 (ref)
    if n1 >= 12 then
        debug.profilebegin("ProjectilePierceHitSoundCapped")
        debug.profileend()
    elseif p4:IsA("Sound") then
        n1 += 1
        debug.profilebegin("ProjectilePierceHitSound")

        local clone = p4:Clone()

        clone.PlaybackSpeed = v3:NextNumber(clone.PlaybackSpeed * 0.8, clone.PlaybackSpeed * 1.3)
        clone.Name = "HitClone"
        clone.Parent = p5
        clone:Play()
        TimescaleUtilities.CleanUp(clone, clone.TimeLength)
        debug.profileend()
    end
end

local t3 = {}
local t4 = {}
local t5 = {}
local t6 = {
    heartbeat = 0,
    connect = 0,
    preSim = 0
}
local t7 = {}

local function queueThrowBullet(p6, p7) -- line: 92
    -- upvalues: t7 (copy)
    t7[p6] = p7
end

local function clearThrowBullet(p8) -- line: 96
    -- upvalues: t7 (copy)
    if p8 then
        t7[p8] = nil
    end
end

local function flushThrowBullets() -- line: 102
    -- upvalues: t7 (copy)
    debug.profilebegin("ProjectileFlushThrowBullets")

    local n2 = 0

    for _ in t7 do
        n2 += 1
    end

    if n2 == 0 then
        debug.profileend()
    else
        local v6 = table.create(n2)
        local v7 = table.create(n2)
        local n3 = 1

        for v8, v9 in t7 do
            v6[n3] = v8
            v7[n3] = v9
            n3 += 1
        end

        table.clear(t7)
        debug.profilebegin("ProjectileThrowBulkMoveTo")

        local function v10() -- line: 127
            -- upvalues: v6 (copy), v7 (copy)
            workspace:BulkMoveTo(v6, v7, Enum.BulkMoveMode.FireCFrameChanged)
        end

        local traceback = debug.traceback
        local v11, v12 = xpcall(v10, traceback)

        debug.profileend()
        debug.profileend()

        if not v11 then
            error(v12, 0)
        end
    end
end

local function usesClientHitDetection(p9) -- line: 138
    return p9.ClientHitDetection == true
end

local function writeClientHits(p10, p11) -- line: 142
    local t8 = {}

    for v13, v14 in p11 do
        local model = v14.model

        if v14.enemy and v14.enemy.Replicator then
            model = v14.enemy.Replicator.ReplicationFolder
        end

        t8[v13] = {
            model,
            v14.position,
            v14.time
        }
    end

    p10.ClientHits = if not (#t8 > 0) then nil else t8
end

local function readClientHitTime(p12) -- line: 157
    return p12.Time or p12.time or p12[3] or 0
end

local function fireClientHits(p13, p14, p15, p16) -- line: 161
    local t9 = {}
    local v15 = p14
    local n4 = 0

    while v15 <= #p13 do
        local v16 = p13[v15]

        if p15 < (v16.Time or v16.time or v16[3] or 0) then
            break
        end

        local Model = v16.Model or v16.model or v16[1]
        local Position = v16.Position or v16.position or v16[2]

        if Model then
            table.insert(t9, {
                Model,
                Position
            })

            if p16 then
                p16(Model, Position)
            end
        end

        n4 += 1
        v15 += 1
    end

    return v15, n4, t9
end

local function addCallback(p17, p18, p19, p20) -- line: 187
    -- upvalues: t6 (copy)
    if p19 and not p17[p19] then
        p17[p19] = p20 or p18
        t6[p18] += 1
    end
end

local function removeCallback(p21, p22, p23) -- line: 205
    -- upvalues: t6 (copy)
    if p23 and p21[p23] then
        p21[p23] = nil
        t6[p22] -= 1
    end
end

local function runCallbackSet(p24, p25, p26) -- line: 218
    for v17, v18 in p24 do
        debug.profilebegin((("%*_%*"):format(p25, v18)))

        local traceback = debug.traceback
        local v19, v20 = xpcall(v17, traceback, p26)

        debug.profileend()

        if not v19 then
            error(v20, 0)
        end
    end
end

local t11 = {}
local v21 = if v1 then require(ServerStorage.Server.Modules.NPC) else nil
local quadBezier = ProjectilePath.quadBezier

local function getCurved(p27, p28, p29, p30) -- line: 242
    -- upvalues: v1 (copy), quadBezier (copy)
    local v22 = quadBezier(p28, p29.Start.p, p30, p29.End)

    if v1 then
        return CFrame.new(v22)
    end

    return CFrame.new(p27, v22) - p27 + v22
end

local function getLinear(p31, p32, p33) -- line: 251
    -- upvalues: math (copy)
    local v23 = math.lerp(CFrame.new(p33.Start.p).p, p33.End, p32)

    return CFrame.new(p31, v23) - p31 + v23
end

local throwPosition = ProjectilePath.throwPosition

if not v1 then
    local DebugController = require(ReplicatedStorage.Client.Controllers.Shared.DebugController)
    local Gizmo = DebugController.Gizmo

    DebugController.createGizmo("Projectiles", function() -- line: 263
        -- upvalues: t1 (copy), Gizmo (copy)
        for v24, v25 in t1 do
            local CFrame, Size = v24.CFrame, v24.Size

            Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(122, 245, 241))
            Gizmo.Box:Draw(CFrame, Size, false)
            Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(255, 53, 144))
            Gizmo.Ray:Draw(CFrame.Position, CFrame.Position + v25)
        end
    end)
end

function t2.CalcDuration(_, p35) -- line: 278
    -- upvalues: ProjectilePath (copy)
    return ProjectilePath.throwDilatedDuration(p35)
end

function MultiHitRayCast(p36) -- line: 282
    -- upvalues: CollectionService (copy), Container (copy)
    local v26 = Ray.new(p36.Position, p36.Direction)
    local t12 = {}
    local n5 = 0

    repeat
        local v27 = Container:FindPartOnRayWithIgnoreList(v26, p36.Ignore)
        local v28

        if v27 then
            if CollectionService:HasTag(v27, "NPCHitbox") then
                table.insert(p36.Ignore, v27.Parent)

                local Parent2 = v27.Parent

                v28 = false
                table.insert(t12, Parent2)
                n5 += 1
            else
                local Ignore = p36.Ignore

                v28 = false
                table.insert(Ignore, v27)
            end
        else
            v28 = true
        end
    until v28 or p36.Hits + n5 >= (p36.MaxHits or 1)

    return nil, nil, nil, t12
end

local function laser(p37, p38) -- line: 310
    -- upvalues: TimescaleUtilities (copy)
    local Part = Instance.new("Part")

    Part.Parent = workspace.Trash
    Part.BrickColor = BrickColor.new("Bright red")
    Part.Material = "Neon"
    Part.Transparency = 0.25
    Part.Anchored = true
    Part.CanCollide = false

    local magnitude = (p37 - p38).magnitude

    Part.Size = Vector3.new(0.1, 0.1, magnitude)
    Part.CFrame = CFrame.new(p37, p38) * CFrame.new(0, 0, -magnitude / 2)
    TimescaleUtilities.CleanUp(Part, 1)
end

if not v1 then
    local DebugController = require(ReplicatedStorage.Client.Controllers.Shared.DebugController)
    local Gizmo = DebugController.Gizmo

    DebugController.createGizmo("Projectiles", function() -- line: 329
        -- upvalues: t1 (copy), Gizmo (copy)
        for v29, v30 in t1 do
            local CFrame, Size = v29.CFrame, v29.Size

            Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(122, 245, 241))
            Gizmo.Box:Draw(CFrame, Size, false)
            Gizmo.PushProperty(Gizmo.Styles.Color, Color3.fromRGB(255, 53, 144))
            Gizmo.Ray:Draw(CFrame.Position, CFrame.Position + v30)
        end
    end)
end

local function createHitscanModel(p39) -- line: 343
    -- upvalues: ServerStorage (copy), t11 (copy)
    local WorldModel = Instance.new("WorldModel")

    WorldModel.Name = ("%*'s world model"):format(p39.UserId)
    WorldModel.Parent = ServerStorage
    t11[p39] = WorldModel

    return WorldModel
end

function t2.MultiRaycast(p40) -- line: 353
    -- upvalues: CollectionService (copy), Container (copy), v21 (copy)
    local t13 = {}
    local t14 = {}
    local v31 = RaycastParams.new()

    v31.FilterDescendantsInstances = CollectionService:GetTagged("NPCHitbox")
    v31.FilterType = Enum.RaycastFilterType.Include

    local n6 = 0

    while true do
        local v32 = Container:Raycast(p40.Origin, p40.Direction, v31)
        local v33, v34

        if v32 then
            local v35 = v21.getNPCByModel(v32.Instance)

            if v35 then
                if p40.EnemyFilter and p40.EnemyFilter(v35) then
                    v33 = n6
                    v34 = true
                else
                    v34 = false
                    table.insert(t13, v35)
                end
            else
                v34 = false
            end
        else
            v33 = n6
            v34 = true
        end

        if not v34 then
            table.insert(t14, v32.Position)
            v33 = n6 + 1
        end

        if v32 == nil or p40.MaxHits <= v33 then
            break
        end

        n6 = v33
    end

    return t13, t14
end

function t2.MultiHitRaycast(p41) -- line: 389
    -- upvalues: CollectionService (copy), Container (copy), math (copy), isPointInsidePart (copy), v21 (copy)
    local t15 = {}
    local t16 = {}
    local v36 = RaycastParams.new()
    local v37 = math.max(1, p41.MaxHits or 1)
    local Direction = p41.Direction
    local Magnitude = Direction.Magnitude

    if not (Magnitude <= 0) then
        local Unit = Direction.Unit
        local Origin = p41.Origin
        local v38 = p41.RaycastFilterType or Enum.RaycastFilterType.Include
        local t17 = {}

        for _, v39 in p41.FilterList or CollectionService:GetTagged("NPCHitbox") do
            if typeof(v39) == "Instance" then
                table.insert(t17, v39)
            end
        end

        v36.FilterType = v38

        if v38 == Enum.RaycastFilterType.Include then
            for i = #t17, 1, -1 do
                local v40 = t17[i]

                if v40:IsA("BasePart") and isPointInsidePart(Origin, v40) then
                    table.remove(t17, i)

                    local v41 = v21.getNPCByModel(v40)

                    if v41 and (not p41.EnemyFilter or not p41.EnemyFilter(v41)) then
                        table.insert(t15, v41)
                        table.insert(t16, Origin)

                        if v37 <= #t15 then
                            return t15, t16
                        end
                    end
                end
            end
        end

        while true do
            if #t15 < v37 and Magnitude > 0 and (v38 ~= Enum.RaycastFilterType.Include or #t17 ~= 0) then
                v36.FilterDescendantsInstances = t17

                local v42 = Container:Raycast(Origin, Unit * Magnitude, v36)

                if v42 then
                    local Instance = v42.Instance

                    if v38 == Enum.RaycastFilterType.Include then
                        for i = #t17, 1, -1 do
                            local v43 = t17[i]

                            if v43 == Instance or Instance:IsDescendantOf(v43) then
                                table.remove(t17, i)
                            end
                        end
                    end

                    local v44 = v21.getNPCByModel(Instance)

                    if not (not v44 or p41.EnemyFilter and p41.EnemyFilter(v44)) then
                        table.insert(t15, v44)
                        table.insert(t16, v42.Position)
                    end

                    Magnitude -= (v42.Position - Origin).Magnitude + 0.05
                    Origin = v42.Position + Unit * 0.05
                    continue
                end
            end

            break
        end
    end

    return t15, t16
end

function t2.LagCompensatedRaycast(_, p43) -- line: 480
    -- upvalues: ServerStorage (copy), _Enum (copy), math (copy), t11 (copy), v21 (copy)
    local v45 = t11[p43.player]

    if not v45 then
        local player = p43.player

        v45 = Instance.new("WorldModel")
        v45.Name = ("%*'s world model"):format(player.UserId)
        v45.Parent = ServerStorage
        t11[player] = v45
    end

    if p43.clientSync == nil then
        return
    end

    local Sync = workspace:GetAttribute("Sync")

    if not Sync then
        return nil, Vector3.new(), nil, {}
    end

    local function getClosestSync() -- line: 500
        -- upvalues: p43 (copy), v21 (copy)
        local n7 = 0
        local n8 = 0

        for _, v46 in v21.PreviousPositions do
            for _, v47 in v46 do
                if v47.CurrentSync <= p43.clientSync and n7 < v47.CurrentSync then
                    n7 = v47.CurrentSync
                end
            end

            if n7 ~= 0 then
                n8 = n7
                break
            end

            n8 = n7
        end

        return n8
    end

    local function getNextClosestSync(p44) -- line: 517
        -- upvalues: v21 (copy)
        for _, v48 in v21.PreviousPositions do
            for v49, v50 in v48 do
                if v48[v49 - 1] and p44 == v48[v49 - 1].CurrentSync then
                    return v50.CurrentSync
                end
            end
        end

        return nil
    end

    local v51 = getClosestSync()
    local v52 = getNextClosestSync(v51) or Sync
    local v53 = if v51 == v52 then 0 else math.clamp(math.ilerp(v51, v52, p43.clientSync), 0, 1)
    local t18 = {}

    v45:ClearAllChildren()

    for v54, v55 in v21.PreviousPositions do
        local v56 = v21.getNPCByModel(v54)

        if v56 and v56:IsAlive() then
            local v57 = false

            for v58, v59 in v55 do
                local _CFrame = v54.CFrame

                if v59[v58 + 1] then
                    _CFrame = v59[v58 + 1].CFrame
                end

                if v59.CurrentSync == v51 then
                    local Part = Instance.new("Part")

                    Part:AddTag("NPCHitbox")
                    Part.Size = v54.Size + Vector3.new(0, 0, 2)
                    Part.CFrame = v59.CFrame:Lerp(_CFrame, v53) * CFrame.new(0, math.abs(v59.Model.PrimaryPart.Node.Position.Y) - Part.Size.Y / 2, 0)
                    Part.Anchored = true
                    Part.CanCollide = false
                    Part.Size += Vector3.new(0, 1, 0)
                    Part.Parent = v45
                    t18[Part] = v54
                    v57 = true
                    task.delay(10, function() -- line: 586
                        -- upvalues: Part (copy)
                        Part:Destroy()
                    end)
                    break
                end
            end

            if not v57 then
                local Part = Instance.new("Part")

                Part:AddTag("NPCHitbox")
                Part.Size = v54.Size + Vector3.new(0, 0, 2)
                Part.CFrame = v54.CFrame
                Part.Anchored = true
                Part.CanCollide = false
                Part.Size += Vector3.new(0, 1, 0)
                Part.Parent = v45
                t18[Part] = v54
                task.delay(10, function() -- line: 607
                    -- upvalues: Part (copy)
                    Part:Destroy()
                end)
            end
        end
    end

    local v60 = Ray.new(p43.position, p43.direction)
    local t19 = {}
    local n9 = 0
    local v61, v62, v63

    repeat
        v61, v62, v63 = v45:FindPartOnRayWithIgnoreList(v60, p43.ignore)

        local v64

        if v61 then
            if v61:HasTag("NPCHitbox") then
                table.insert(p43.ignore, v61)

                local v65 = v21.getNPCByModel(t18[v61])

                if not v65 or not v65:IsAlive() or v65.Team == p43.inheritance.Team then
                    v64 = false
                else
                    p43.inheritance:DealDamage(v65, n9, _Enum.DamageType.Normal)

                    local ReplicationFolder = v65.Replicator.ReplicationFolder

                    v64 = false
                    table.insert(t19, ReplicationFolder)
                    n9 += 1
                end
            else
                local ignore = p43.ignore

                v64 = false
                table.insert(ignore, v61)
            end
        else
            v64 = true
        end
    until v64 or n9 >= 3

    return v61, v62, v63, t19
end

function t2.PeirceRaycast(_, p46) -- line: 653
    -- upvalues: CollectionService (copy), Container (copy), _Enum (copy), v21 (copy)
    local v66 = RaycastParams.new()

    v66.FilterType = Enum.RaycastFilterType.Exclude
    v66.FilterDescendantsInstances = {}

    local t20 = {}
    local n10 = 0

    repeat
        local v67 = Container:Raycast(p46.start, p46.direction, v66)

        if v67 then
            if CollectionService:HasTag(v67.Instance, "NPCHitbox") then
                v66:AddToFilter({
                    v67.Instance.Parent
                })

                local v68 = v21.getNPCByModel(v67.Instance)

                if v68.Team ~= p46.tower.Team then
                    p46.tower:DealDamage(v68, n10, _Enum.DamageType.Normal)
                    table.insert(t20, v68.Replicator.ReplicationFolder)
                    n10 += 1
                end
            else
                v66:AddToFilter({
                    v67.Instance
                })
            end
        else
            break
        end
    until p46.maxPerice <= n10

    return t20
end

function t2.Raycast(_, p48, p49, p50, p51) -- line: 695
    -- upvalues: CollectionService (copy), Container (copy), _Enum (copy), isPointInsidePart (copy), v21 (copy)
    local v69 = Ray.new(p49, p50)
    local t21 = {}
    local n11 = 0
    local n12 = 0

    for _, v70 in CollectionService:GetTagged("NPCHitbox") do
        if v70:IsA("BasePart") and isPointInsidePart(p49, v70) then
            table.insert(p51, v70.Parent)

            local v71 = v21.getNPCByModel(v70)

            if v71 and v71.Team ~= p48.Team then
                p48:DealDamage(v71, n11, _Enum.DamageType.Normal)
                table.insert(t21, v71.Replicator.ReplicationFolder)
                n11 += 1

                if n11 >= 3 then
                    return v70, p49, Vector3.new(0, 0, 0), t21
                end
            end
        end

        n12 = n11
    end

    local v72, v73, v74

    repeat
        v72, v73, v74 = Container:FindPartOnRayWithIgnoreList(v69, p51)

        local v75

        if v72 then
            if CollectionService:HasTag(v72, "NPCHitbox") then
                table.insert(p51, v72.Parent)

                local v76 = v21.getNPCByModel(v72)

                if v76.Team == p48.Team then
                    v75 = false
                else
                    p48:DealDamage(v76, n12, _Enum.DamageType.Normal)

                    local ReplicationFolder = v76.Replicator.ReplicationFolder

                    v75 = false
                    table.insert(t21, ReplicationFolder)
                    n12 += 1
                end
            else
                v75 = false
                table.insert(p51, v72)
            end
        else
            v75 = true
        end
    until v75 or n12 >= 3

    return v72, v73, v74, t21
end

local getLogicalThrowHits

function t2.Throw(_, p53, p54) -- line: 758
    -- upvalues: GameState (copy), ProjectilePath (copy), TimeField (copy), v1 (copy), t1 (copy), TimescaleUtilities (copy), math (copy), t3 (copy), t6 (copy), t7 (copy), writeClientHits (copy), fireClientHits (copy), quadBezier (copy), throwPosition (copy), getLogicalThrowHits (ref), v2 (copy)
    local n13 = 0
    local Start = p53.Start
    local n14 = 0
    local v77, v78

    if not v1 then
        local v79

        if p53.Part:IsA("BasePart") then
            local v80 = v2.get(p53.Part, p53.PoolSize)

            v78 = v80
            v79 = v80:take()
            v77 = v79
        else
            v79 = p53.Part:Clone()
            v77 = v79
            v79.Parent = workspace.CurrentCamera
        end

        v79.CFrame = Start
    end

    local StartPosition = Start.Position
    local v81 = (Start.p - p53.End).Magnitude / p53.Speed
    local v82 = ProjectilePath.throwMid(p53)
    local v83 = p53.MaxHits or 1
    local v84 = p53.Ignore or {}
    local v85 = p53.ClientHitDetection == true

    if not v1 then
        local v86
        local v87 = p53.ClientHits or {}
        local n15 = 1

        local function finishProjectile() -- line: 807
            -- upvalues: v77 (ref), v78 (ref), v86 (ref), t1 (copy), t3 (copy), t6 (copy), t7 (copy)
            local v88 = v86

            if v88 and t3[v88] then
                t3[v88] = nil
                t6.heartbeat -= 1
            end

            t1[v77] = nil

            local v89 = v77

            if v89 then
                t7[v89] = nil
            end

            if v77.Name == "RailgunBullet" then
                v77.Transparency = 1
                task.wait(1)
            end

            if v78 then
                v78:release(v89)
            else
                v77:Destroy()
            end
        end

        v86 = function(p55) -- line: 825
            -- upvalues: p53 (copy), p54 (copy), n13 (ref), n14 (ref), v77 (ref), StartPosition (ref), v81 (copy), v82 (copy), v83 (copy), n15 (ref), finishProjectile (copy), v87 (copy), v84 (copy), v85 (copy), GameState (copy), TimeField (copy), v1 (copy), t1 (copy), math (copy), t7 (copy), fireClientHits (copy), quadBezier (copy), throwPosition (copy)
            if n14 >= v83 then
                finishProjectile()
            else
                local v91 = p55 * GameState.TimeScale

                if TimeField.hasFields() then
                    v91 *= TimeField.scaleAt(StartPosition)
                end

                local v92 = n13

                n13 += v91

                local v93 = math.clamp(v92 / v81, 0, 1)
                local v94 = math.clamp(n13 / v81, 0, 1)
                local v95, v96

                if p53.Type == "Curve" then
                    local StartPosition2 = StartPosition
                    local v97 = quadBezier(v94, p53.Start.p, v82, p53.End)
                    local v98 = if v1 then CFrame.new(v97) else CFrame.new(StartPosition2, v97) - StartPosition2 + v97

                    if v98 then
                        v95 = v98
                        v96 = true
                    else
                        v96 = false
                    end
                else
                    v96 = false
                end

                if not v96 then
                    local StartPosition2 = StartPosition
                    local v99 = math.lerp(CFrame.new(p53.Start.p).p, p53.End, v94)

                    v95 = CFrame.new(StartPosition2, v99) - StartPosition2 + v99
                end

                if not v1 then
                    if p53.Type == "Curve" then
                        v95 *= CFrame.Angles(0, 0, math.rad(p53.Turn * n13))
                    else
                        v95 *= CFrame.Angles(math.rad(-p53.Turn * n13), 0, 0)
                    end
                end

                local v100 = v95.Position - StartPosition

                if #v87 > 0 then
                    local v101, v102 = fireClientHits(v87, n15, n13, p54)

                    n15 = v101
                    n14 += v102
                elseif v85 then
                    local v103 = throwPosition(v93, p53, v82)

                    v100 = v95.Position - v103

                    while v93 < v94 and n14 < v83 do
                        v93 = math.min(v93 + 0.125, v94)

                        local v104 = throwPosition(v93, p53, v82)
                        local v105 = v104 - v103

                        if not (v105.Magnitude <= 0) then
                            local _, _, _, v106 = MultiHitRayCast({
                                Position = v103,
                                Direction = v105,
                                Ignore = v84,
                                Hits = n14,
                                MaxHits = v83
                            })

                            for _, v107 in pairs(v106) do
                                if p54 then
                                    p54(v107)
                                end

                                n14 += 1
                            end
                        end

                        v103 = v104
                    end
                end

                if not v1 then
                    t1[v77] = v100
                    StartPosition = v95.Position
                    t7[v77] = v95
                end

                if v94 >= 1 or n14 >= v83 then
                    finishProjectile()
                end
            end
        end

        if v86 and not t3[v86] then
            t3[v86] = "Throw"
            t6.heartbeat += 1
        end

        return v77
    end

    local v109 = getLogicalThrowHits(p53, v83, v84, v82)

    writeClientHits(p53, v109)

    for _, v110 in v109 do
        TimescaleUtilities.Delay(v110.delay, function() -- line: 793
            -- upvalues: p54 (copy), v110 (copy)
            if v110.enemy:IsAlive() and p54 then
                p54(v110.model, v110.position)
            end
        end)
    end
end

local t22 = {}
local v111

local function flushPierceBullets() -- line: 921
    -- upvalues: t22 (copy), v111 (ref)
    debug.profilebegin("ProjectileFlushPierceBullets")

    local n16 = 0

    for _ in t22 do
        n16 = 0 + 1
        break
    end

    if n16 == 0 then
        if v111 then
            v111:Disconnect()
            v111 = nil
        end

        debug.profileend()
    else
        local t23 = {}
        local t24 = {}
        local n17 = 0

        for v112, v113 in t22 do
            n17 += 1
            t23[n17] = v112
            t24[n17] = v113
        end

        table.clear(t22)
        debug.profilebegin("ProjectilePierceBulkMoveTo")

        local function v114() -- line: 949
            -- upvalues: t23 (copy), t24 (copy)
            workspace:BulkMoveTo(t23, t24, Enum.BulkMoveMode.FireCFrameChanged)
        end

        local traceback = debug.traceback
        local v115, v116 = xpcall(v114, traceback)

        debug.profileend()
        debug.profileend()

        if not v115 then
            error(v116, 0)
        end
    end
end

local function setPierceBulletCFrame(p56, p57) -- line: 960
    -- upvalues: RunService (copy), t22 (copy), v111 (ref), flushPierceBullets (copy)
    t22[p56] = p57
    v111 = v111 or RunService.PreRender:Connect(flushPierceBullets)
end

local function isIgnoredByList(p58, p59) -- line: 971
    if not p59 then
        return false
    end

    for _, v117 in p59 do
        if v117 and (p58 == v117 or p58:IsDescendantOf(v117)) then
            return true
        end
    end

    return false
end

local function getNPCPathVelocity(p60) -- line: 985
    local v118 = if typeof(p60.Speed) == "number" then p60.Speed elseif p60.GetWalkSpeed then p60:GetWalkSpeed() else 0

    if p60.Stopped then
        v118 = 0
    end

    if p60.Reverse then
        v118 = -v118
    end

    if typeof(p60.ForceSpeed) == "number" then
        v118 += p60.ForceSpeed
    end

    return v118
end

local function getNPCCenterAtTime(p61, p62) -- line: 1005
    local v119 = p61.Height or Vector3.new(0, 0, 0)

    if p61.Path and not p61.ForcePosition and typeof(p61.PathDistance) == "number" then
        local v120 = if typeof(p61.Speed) == "number" then p61.Speed elseif p61.GetWalkSpeed then p61:GetWalkSpeed() else 0

        if p61.Stopped then
            v120 = 0
        end

        if p61.Reverse then
            v120 = -v120
        end

        if typeof(p61.ForceSpeed) == "number" then
            v120 += p61.ForceSpeed
        end

        if v120 ~= 0 then
            return p61.Path:GetScalar(p61.PathDistance + v120 * p62) + v119
        end
    end

    if p61.Position then
        return p61.Position + v119
    end

    if p61.Part then
        return p61.Part.Position
    end

    return (Vector3.new(0, 0, 0))
end

local function getNPCHitRadius(p63, p64) -- line: 1026
    -- upvalues: math (copy)
    local _hitboxSize = p63._hitboxSize
    local v121, v122

    if _hitboxSize then
        v121 = _hitboxSize
        v122 = true
    elseif p63.Part then
        local Size = p63.Part.Size

        if Size then
            v121 = Size
            v122 = true
        else
            v122 = false
        end
    else
        v122 = false
    end

    if not v122 then
        v121 = Vector3.new(0, 0, 0)
    end

    local Size = p63.Part and p63.Part.Size or Vector3.new(0, 0, 0)

    return math.max(v121.X, v121.Z, Size.X, Size.Z) * 0.5 + p64
end

local function sortAndLimitLogicalHits(p65, p66) -- line: 1034
    -- upvalues: math (copy)
    table.sort(p65, function(p67, p68) -- line: 1035
        if p67.time == p68.time then
            return p67.missDistance < p68.missDistance
        end

        return p67.time < p68.time
    end)

    local t25 = {}

    for i = 1, math.min(p66, #p65) do
        t25[i] = p65[i]
    end

    return t25
end

local function getLogicalPierceHits(p69, p70, p71, p72) -- line: 1051
    -- upvalues: CollectionService (copy), TimeField (copy), math (copy), v21 (copy), isIgnoredByList (copy), getNPCCenterAtTime (copy), sortAndLimitLogicalHits (copy)
    debug.profilebegin("ProjectileLogicalPierceHits")

    local Start = p69.Start
    local v123 = p69.End - Start
    local Magnitude = v123.Magnitude
    local Speed = p69.Speed

    if not (Magnitude <= 0) and Speed and not (Speed <= 0) then
        local v124 = v123 / Magnitude
        local v125 = Magnitude / Speed
        local v126 = (p69.Size or 0) * 0.5
        local v127 = p72 or 0
        local t26 = {}
        local v128 = TimeField.timeMap(v125, function(p73) -- line: 1075
            -- upvalues: Start (copy), v123 (copy)
            return Start + v123 * p73
        end)

        for _, v129 in CollectionService:GetTagged("NPCHitbox") do
            if v129.Parent and not isIgnoredByList(v129, p71) then
                local v130 = v21.getNPCByModel(v129)

                if v130 and v130:IsAlive() then
                    local v131 = getNPCCenterAtTime(v130, v127)
                    local n18 = 0

                    for _ = 1, 4 do
                        n18 = math.clamp((v131 - Start):Dot(v124) / Magnitude, 0, 1)

                        local v132 = n18 * v125

                        if v128 then
                            v132 = v128(v132)
                        end

                        v131 = getNPCCenterAtTime(v130, v127 + v132)
                    end

                    local v133 = Start + v124 * Magnitude * n18
                    local _hitboxSize = v130._hitboxSize or v130.Part and v130.Part.Size or Vector3.new(0, 0, 0)
                    local v134 = v130.Part and v130.Part.Size or Vector3.new(0, 0, 0)
                    local v135 = math.max(_hitboxSize.X, _hitboxSize.Z, v134.X, v134.Z) * 0.5 + v126
                    local Magnitude2 = (v131 - v133).Magnitude

                    if Magnitude2 <= v135 then
                        local v136 = n18 * v125

                        table.insert(t26, {
                            enemy = v130,
                            model = v129.Parent,
                            position = v133,
                            time = v136,
                            delay = if v128 then v128(v136) else v136,
                            missDistance = Magnitude2
                        })
                    end
                end
            end
        end

        local v137 = sortAndLimitLogicalHits(t26, p70)

        debug.profileend()

        return v137
    end

    debug.profileend()

    return {}
end

function t2.PreparePierceClientHits(_, p75, p76) -- line: 1123
    -- upvalues: v1 (copy), writeClientHits (copy), getLogicalPierceHits (copy)
    if not v1 then
        return {}
    end

    local v138 = p75.MaxHits or 1
    local v139 = p75.Ignore or {}

    p75.Ignore = v139

    local v140 = getLogicalPierceHits(p75, v138, v139, p76)

    writeClientHits(p75, v140)

    return v140
end

function getLogicalThrowHits(p77, p78, p79, p80) -- line: 1138
    -- upvalues: CollectionService (copy), TimeField (copy), math (copy), v21 (copy), throwPosition (copy), isIgnoredByList (copy), getNPCCenterAtTime (copy), sortAndLimitLogicalHits (copy)
    debug.profilebegin("ProjectileLogicalThrowHits")

    local Magnitude = (p77.Start.p - p77.End).Magnitude
    local Speed = p77.Speed

    if not (Magnitude <= 0) and Speed and not (Speed <= 0) then
        local v141 = Magnitude / Speed
        local v142 = math.ceil(8)
        local v143 = math.clamp(math.ceil(v141 * 30), v142, 48)
        local v144 = (p77.Size or 0) * 0.5
        local t28 = {}
        local v145 = TimeField.timeMap(v141, function(p81) -- line: 1158
            -- upvalues: p77 (copy), p80 (copy), throwPosition (copy)
            return throwPosition(p81, p77, p80)
        end)

        for _, v146 in CollectionService:GetTagged("NPCHitbox") do
            if v146.Parent and not isIgnoredByList(v146, p79) then
                local v147 = v21.getNPCByModel(v146)

                if v147 and v147:IsAlive() then
                    local v148 = math.huge
                    local v149 = v143 - 1
                    local n19 = 0
                    local v150

                    for i = 0, v149 do
                        local v151 = i / v143
                        local v152 = (i + 1) / v143
                        local v153 = throwPosition(v151, p77, p80)
                        local v154 = throwPosition(v152, p77, p80) - v153
                        local Magnitude = v154.Magnitude
                        local v155 = v150
                        local Magnitude2 = v148
                        local v156 = n19

                        if not (Magnitude <= 0) then
                            local v157 = v154 / Magnitude
                            local v158 = math.lerp(v151, v152, 0.5) * v141

                            if v145 then
                                v158 = v145(v158)
                            end

                            local v159 = getNPCCenterAtTime(v147, v158)
                            local n20 = 0.5

                            for _ = 1, 4 do
                                n20 = math.clamp((v159 - v153):Dot(v157) / Magnitude, 0, 1)

                                local v160 = math.lerp(v151, v152, n20) * v141

                                if v145 then
                                    v160 = v145(v160)
                                end

                                v159 = getNPCCenterAtTime(v147, v160)
                            end

                            v155 = v153 + v154 * n20
                            Magnitude2 = (v159 - v155).Magnitude

                            if Magnitude2 < v148 then
                                v156 = math.lerp(v151, v152, n20) * v141
                            else
                                v156 = n19
                                Magnitude2 = v148
                                v155 = v150
                            end
                        end

                        n19 = v156
                        v148 = Magnitude2
                        v150 = v155
                    end

                    local _hitboxSize = v147._hitboxSize or v147.Part and v147.Part.Size or Vector3.new(0, 0, 0)
                    local v161 = v147.Part and v147.Part.Size or Vector3.new(0, 0, 0)
                    local v162 = math.max(_hitboxSize.X, _hitboxSize.Z, v161.X, v161.Z) * 0.5 + v144

                    if v150 and v148 <= v162 then
                        local t29 = {
                            enemy = v147,
                            model = v146.Parent,
                            position = v150,
                            time = n19
                        }

                        if v145 then
                            n19 = v145(n19)
                        end

                        t29.delay = n19
                        t29.missDistance = v148
                        table.insert(t28, t29)
                    end
                end
            end
        end

        local v163 = sortAndLimitLogicalHits(t28, p78)

        debug.profileend()

        return v163
    end

    debug.profileend()

    return {}
end

function t2.Pierce(p82, p83, p84) -- line: 1231
    -- upvalues: RunService (copy), GameState (copy), TimeField (copy), v1 (copy), t1 (copy), TimescaleUtilities (copy), math (copy), emitProjectileHitParticles (copy), playPierceHitSound (copy), t4 (copy), t6 (copy), fireClientHits (copy), t22 (copy), v111 (ref), flushPierceBullets (copy), v2 (copy)
    local magnitude = (p83.Start - p83.End).magnitude
    local Speed = p83.Speed
    local v164, v165, v166

    if magnitude <= 0 then
        v166 = true
    elseif not Speed or Speed <= 0 then
        v166 = true
    else
        v164 = p83.MaxHits or 1
        v165 = p83.Ignore or {}
        v166 = false
    end

    if v166 then
        return
    end

    p83.Ignore = v165

    if v1 then
        for _, v167 in p82:PreparePierceClientHits(p83) do
            TimescaleUtilities.Delay(v167.delay, function() -- line: 1248
                -- upvalues: p84 (copy), v167 (copy)
                if v167.enemy:IsAlive() and p84 then
                    p84(v167.model, v167.position)
                end
            end)
        end
    else
        local v168 = magnitude / Speed
        local n21 = 0
        local n22 = 0
        local v169 = p83.ClientHitDetection == true
        local v170 = p83.ClientHits or {}
        local n23 = 1
        local v171, v172
        local v173 = false
        local t30 = {}

        local function hideBullet() -- line: 1269
            -- upvalues: v171 (ref), v172 (ref), t30 (copy), t1 (copy), t22 (copy)
            if not v171 then
                return
            end

            t1[v171] = nil
            t22[v171] = nil

            if v172 then
                local v174 = v172

                v174:hide(v171)
            else
                v171.Transparency = 1

                for _, v176 in pairs(t30) do
                    v176.Enabled = false
                end

                for _, descendant in pairs(v171:GetDescendants()) do
                    if descendant:IsA("BasePart") then
                        descendant.Transparency = 1
                    end
                end
            end
        end

        local function releaseBullet() -- line: 1293
            -- upvalues: v171 (ref), v172 (ref), v173 (ref), t1 (copy), t22 (copy)
            local v177 = v171

            if not v177 or v173 then
                return
            end

            v173 = true
            t1[v171] = nil
            t22[v171] = nil

            if v172 then
                v172:release(v177)
            else
                v171:Destroy()
            end
        end

        if p83.Projectile then
            if p83.Projectile:IsA("BasePart") then
                v172 = v2.get(p83.Projectile, p83.PoolSize)
                v171 = v172:take()
                v172:enableEffects(v171)
            else
                v171 = p83.Projectile:Clone()

                local CurrentCamera = workspace.CurrentCamera
                local v180 = v171

                v180.Parent = CurrentCamera

                for _, descendant in pairs(v171:GetDescendants()) do
                    if descendant:IsA("Trail") or descendant:IsA("ParticleEmitter") or descendant:IsA("Beam") then
                        descendant.Enabled = true
                        table.insert(t30, descendant)
                    elseif descendant:IsA("Weld") or descendant:IsA("WeldConstraint") then
                        descendant:Destroy()
                    end
                end

                v180.Anchored = true
            end

            local v181 = CFrame.new(p83.Start, p83.End)

            v171.CFrame = v181
        end

        local v182 = p83.Start
        local v183 = v164
        local v184 = v165
        local v185

        v185 = function(p85) -- line: 1337
            -- upvalues: v185 (ref), p83 (copy), p84 (copy), magnitude (copy), v168 (copy), n21 (ref), n22 (ref), n23 (ref), v171 (ref), v172 (ref), v173 (ref), hideBullet (copy), releaseBullet (copy), v182 (ref), v183 (copy), v184 (copy), v169 (copy), v170 (copy), RunService (copy), GameState (copy), TimeField (copy), t1 (copy), TimescaleUtilities (copy), math (copy), emitProjectileHitParticles (copy), playPierceHitSound (copy), t4 (copy), t6 (copy), fireClientHits (copy), t22 (copy), v111 (ref), flushPierceBullets (copy)
            local v186 = p85 * GameState.TimeScale

            if TimeField.hasFields() then
                v186 *= TimeField.scaleAt(v182)
            end

            n21 += v186

            local v187 = math.clamp(n21 / v168, 0, 1)

            if not (v187 >= 1) and not (n22 >= v183) then
                local v188 = CFrame.new(p83.Start, p83.End) * CFrame.new(0, 0, -magnitude * v187)
                local lookVector = v188.lookVector

                v182 = v188.Position

                local v189 = {}
                local v190 = v189
                local n24 = 0

                if #v170 > 0 then
                    local v191

                    v191, n24, v189 = fireClientHits(v170, n23, n21, nil)
                    n23 = v191
                    v190 = v189
                elseif v169 then
                    local _, _, _, v192 = MultiHitRayCast({
                        Position = v188.p,
                        Direction = lookVector * p83.Size,
                        Ignore = v184,
                        Hits = n22,
                        MaxHits = v183
                    })

                    for _, v193 in v192 do
                        table.insert(v189, {
                            v193
                        })
                    end

                    n24 = #v189
                end

                n22 += n24

                if v171 then
                    t22[v171] = v188
                    v111 = v111 or RunService.PreRender:Connect(flushPierceBullets)
                end

                if v171 then
                    t1[v171] = lookVector * p83.Size
                end

                if #v189 > 0 then
                    debug.profilebegin("ProjectilePierceHitEffects")

                    if v171 then
                        local HitSound = v171:FindFirstChild("HitSound")

                        if HitSound then
                            playPierceHitSound(HitSound, v171)
                        end

                        local Indicator = v171:FindFirstChild("Indicator")

                        if Indicator then
                            debug.profilebegin("ProjectilePierceHitParticles")
                            emitProjectileHitParticles(Indicator)
                            debug.profileend()
                        end
                    end

                    debug.profilebegin("ProjectilePierceHitFunctions")

                    local function v195() -- line: 1409
                        -- upvalues: v190 (ref), p84 (copy)
                        for _, v196 in pairs(v190) do
                            if p84 then
                                p84(v196[1], v196[2])
                            end
                        end
                    end

                    local traceback = debug.traceback
                    local v197, v198 = xpcall(v195, traceback)

                    debug.profileend()
                    debug.profileend()

                    if not v197 then
                        error(v198, 0)
                    end
                end
            else
                if v171 then
                    if p83.Decay then
                        hideBullet()
                        TimescaleUtilities.Delay(p83.Decay, releaseBullet)
                    elseif v171 and not v173 then
                        v173 = true
                        t1[v171] = nil
                        t22[v171] = nil

                        if v172 then
                            v172:release(v171)
                        else
                            v171:Destroy()
                        end
                    end
                end

                local v201 = v185

                if v201 and t4[v201] then
                    t4[v201] = nil
                    t6.connect -= 1
                end
            end
        end

        if v185 and not t4[v185] then
            t4[v185] = "Pierce"
            t6.connect += 1
        end
    end
end

function t2.throwWithPhysics(_, p87) -- line: 1443
    -- upvalues: GameState (copy), TimeField (copy), TypedPromise (copy), t1 (copy), math (copy), t5 (copy), t6 (copy)
    return TypedPromise.new(function(p88, p89) -- line: 1444
        -- upvalues: p87 (copy), GameState (copy), TimeField (copy), t1 (copy), math (copy), t5 (copy), t6 (copy)
        local asset = p87.asset

        assert(asset and asset:IsA("BasePart"), "asset must be a BasePart")

        local bounce, rotation, gravity = p87.bounce, p87.rotation, p87.gravity

        if not gravity then
            gravity = Vector3.new(0, -workspace.Gravity, 0)
        end

        local start = p87.start
        local v204 = start
        local n25 = 0
        local velocity = p87.velocity
        local v205

        if velocity then
            v205 = p87.velocity
        else
            local duration = p87.duration

            v205 = (p87.target - start - 0.5 * gravity * duration * duration) / duration
        end

        local connection
        local v206 = RaycastParams.new()

        v206.FilterType = Enum.RaycastFilterType.Include
        v206.FilterDescendantsInstances = p87.include or {}
        v206.RespectCanCollide = true
        v206.IgnoreWater = true
        asset.Anchored = true
        asset.CanCollide = false
        asset.Position = p87.start

        local v207

        v207 = function(p90) -- line: 1481
            -- upvalues: v207 (ref), p88 (copy), asset (copy), bounce (copy), rotation (copy), gravity (ref), v204 (ref), n25 (ref), v205 (ref), connection (ref), v206 (copy), p87 (copy), GameState (copy), TimeField (copy), t1 (copy), math (copy), t5 (copy), t6 (copy)
            local v208 = p90 * GameState.TimeScale

            if TimeField.hasFields() then
                v208 *= TimeField.scaleAt(asset.Position)
            end

            n25 += v208

            local v209 = 0.5 * gravity * n25 * n25 + v205 * n25 + v204
            local v210 = v209 - asset.Position
            local v211 = v210.Unit * math.max(v210.Magnitude, (asset.Size * v210.Unit).Magnitude / 2)
            local v212 = workspace:Shapecast(asset, v211, v206)

            t1[asset] = v211

            local v213

            if v212 then
                asset.CFrame = CFrame.new(v212.Position + v212.Normal * asset.Size * 0.57) * (rotation and rotation(v205) or CFrame.identity)
                v205 = (v211 - 2 * v211:Dot(v212.Normal) * v212.Normal).Unit * v205.Magnitude * 0.3
                v204 = asset.Position
                n25 = 0

                if p87.onHit then
                    p87.onHit(v212.Instance)
                end

                if bounce then
                    bounce(v205)
                end

                v213 = true
            else
                local v216 = CFrame.new(v209)
                local v217 = rotation and rotation(v211) or CFrame.identity

                v213 = false
                asset.CFrame = v216 * v217
            end

            if not (v209.Y < workspace.FallenPartsDestroyHeight or v205.Magnitude < 0.1 or v213 and p87.finishOnHit) then
                return false
            end

            connection:Disconnect()

            local v218 = v207

            if v218 and t5[v218] then
                t5[v218] = nil
                t6.preSim -= 1
            end

            t1[asset] = nil
            p88(v209)

            return true
        end

        local function v219() -- line: 1537
            -- upvalues: v207 (ref), p89 (copy), t5 (copy), t6 (copy)
            local v220 = v207

            if v220 and t5[v220] then
                t5[v220] = nil
                t6.preSim -= 1
            end

            p89()
        end

        if v207 and not t5[v207] then
            t5[v207] = "Physics"
            t6.preSim += 1
        end

        connection = asset.Destroying:Once(v219)

        if not (p87.delta and p87.delta < n25) then
            return
        end

        local v221 = n25

        for _ = v221, p87.delta, 0.016666666666666666 do
            if v207(p87.delta) then
                break
            end
        end
    end)
end

Scheduler.add("Projectile_PreSim", RunService.PreSimulation, function(p91) -- line: 1556
    -- upvalues: t5 (copy), t6 (copy), runCallbackSet (copy)
    if t6.preSim <= 0 then
        return
    end

    debug.profilebegin("ProjectilePreSimCallbacks")

    local traceback = debug.traceback
    local v222, v223 = xpcall(runCallbackSet, traceback, t5, "ProjectilePreSimCallback", p91)

    debug.profileend()

    if not v222 then
        error(v223, 0)
    end
end)
Scheduler.add("Projectile_Heartbeat", RunService.Heartbeat, function(p92) -- line: 1571
    -- upvalues: t3 (copy), t6 (copy), flushThrowBullets (copy), runCallbackSet (copy)
    if t6.heartbeat <= 0 then
        return
    end

    debug.profilebegin("ProjectileHeartbeatCallbacks")

    local traceback = debug.traceback
    local v224, v225 = xpcall(runCallbackSet, traceback, t3, "ProjectileHeartbeatCallback", p92)

    debug.profileend()

    if not v224 then
        error(v225, 0)
    end

    flushThrowBullets()
end)
Scheduler.add("Projectile_Conn", Heartbeat, function(p93) -- line: 1593
    -- upvalues: n1 (ref), t4 (copy), t6 (copy), runCallbackSet (copy)
    if t6.connect <= 0 then
        return
    end

    n1 = 0
    debug.profilebegin("ProjectileConnectCallbacks")

    local traceback = debug.traceback
    local v226, v227 = xpcall(runCallbackSet, traceback, t4, "ProjectileConnectCallback", p93)

    debug.profileend()

    if not v226 then
        error(v227, 0)
    end
end)

return t2
