--TagReplicator
-- https://lua.expert

local CollectionService = game:GetService("CollectionService")

game:GetService("HttpService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t1 = {}

t1.__index = t1

local TypedPromise = require(ReplicatedStorage.Shared.Modules.TypedPromise)
local AttributeSerializer = require(ReplicatedStorage.Shared.Modules.AttributeSerializer)
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local SharedGameConstants = require(ReplicatedStorage.Shared.Modules.SharedGameConstants)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local Deserialize, Serialize, Sanitize = AttributeSerializer.Deserialize, AttributeSerializer.Serialize, AttributeSerializer.Sanitize
local VALUE_OBJECT_OVERRIDES = SharedGameConstants.VALUE_OBJECT_OVERRIDES
local t2 = {}
local t3 = {}
local t4 = {}
local t5 = {
    Total = 0
}
local v1 = Signal.new()
local v2 = Signal.new()
local t6 = {
    TowerReplicator = "TagReplicator_AttributeChanged_Tower",
    StatusEffects = "TagReplicator_AttributeChanged_StatusEffects",
    Attributes = "TagReplicator_AttributeChanged_Attributes",
    AbilityEffects = "TagReplicator_AttributeChanged_AbilityEffects",
    Stuns = "TagReplicator_AttributeChanged_Stuns",
    Abilities = "TagReplicator_AttributeChanged_Abilities",
    AbilityData = "TagReplicator_AttributeChanged_AbilityData",
    Queues = "TagReplicator_AttributeChanged_Queues"
}
local t7 = {
    Tower = "TagReplicator_Lifecycle_Tower",
    StatusEffects = "TagReplicator_Lifecycle_StatusEffects",
    Attributes = "TagReplicator_Lifecycle_Attributes",
    AbilityEffects = "TagReplicator_Lifecycle_AbilityEffects",
    Stuns = "TagReplicator_Lifecycle_Stuns",
    Abilities = "TagReplicator_Lifecycle_Abilities",
    AbilityData = "TagReplicator_Lifecycle_AbilityData",
    Queues = "TagReplicator_Lifecycle_Queues"
}

local function getProfileKind(p1) -- line: 55
    if not p1 then
        return "Unknown"
    end

    if p1.Name == "TowerReplicator" then
        return "Tower"
    end

    return p1.Name
end

local function getAttributeProfileLabel(p2) -- line: 67
    -- upvalues: t6 (copy)
    return t6[p2.Name] or "TagReplicator_AttributeChanged_Other"
end

local function getLifecycleProfileLabel(p3) -- line: 72
    -- upvalues: t7 (copy)
    return t7[p3] or "TagReplicator_Lifecycle_Other"
end

local function bumpActiveCount(p4, p5) -- line: 76
    -- upvalues: t5 (copy)
    t5.Total += p5
    t5[p4] = (t5[p4] or 0) + p5

    if t5[p4] <= 0 then
        t5[p4] = nil
    end
end

local function hookStateObject(p6, p7) -- line: 85
    local Name = p7.Name

    p6.Maid:Mark(p7.Changed:Connect(function() -- line: 87
        -- upvalues: p6 (copy), p7 (copy), Name (copy)
        debug.profilebegin("TagReplicator_ValueChanged")

        local Value = p7.Value

        if p6.AttributeConnections[Name] then
            p6.AttributeConnections[Name]:Fire(Value)
        end

        p6.Changed:Fire(Name, Value)
        debug.profileend()
    end))
    p6.Changed:Fire(Name, p7.Value)
end

local function isReplicatorAlive(p8) -- line: 102
    return p8 and p8.Maid ~= nil
end

function t1._new(p9) -- line: 125
    -- upvalues: t1 (copy), Maid (copy), Signal (copy), Deserialize (copy), VALUE_OBJECT_OVERRIDES (copy), t5 (copy), t6 (copy), t7 (copy), hookStateObject (copy)
    local self = setmetatable({}, t1)

    self.Maid = Maid.new()
    self.Changed = Signal.new()
    self.Maid:Mark(self.Changed)
    self.Folder = p9
    self.State = {}
    self.RawState = {}
    self.AttributeConnections = {}
    self._profileKind = if not p9 then "Unknown" elseif p9.Name == "TowerReplicator" then "Tower" else p9.Name
    self._attributeProfileLabel = t6[p9.Name] or "TagReplicator_AttributeChanged_Other"
    self._lifecycleProfileLabel = t7[self._profileKind] or "TagReplicator_Lifecycle_Other"
    debug.profilebegin("TagReplicator_Create")
    debug.profilebegin(self._lifecycleProfileLabel)

    local _profileKind2 = self._profileKind

    t5.Total += 1
    t5[_profileKind2] = (t5[_profileKind2] or 0) + 1

    if t5[_profileKind2] <= 0 then
        t5[_profileKind2] = nil
    end

    debug.profileend()
    debug.profileend()
    self.Maid:Mark(self.Folder.AttributeChanged:Connect(function(p10) -- line: 147
        -- upvalues: self (copy), Deserialize (copy)
        debug.profilebegin("TagReplicator_AttributeChanged")
        debug.profilebegin(self._attributeProfileLabel)

        local Attribute = self.Folder:GetAttribute(p10)

        if self.RawState[p10] ~= Attribute then
            self.RawState[p10] = Attribute

            if Attribute ~= nil then
                Attribute = Deserialize(Attribute)
            end

            self.State[p10] = Attribute
            self.Changed:Fire(p10, Attribute)

            if self.AttributeConnections[p10] then
                self.AttributeConnections[p10]:Fire(Attribute)
            end
        end

        debug.profileend()
        debug.profileend()
    end))

    for _, child in pairs(self.Folder:GetChildren()) do
        if VALUE_OBJECT_OVERRIDES[child.Name] then
            hookStateObject(self, child)
        end
    end

    self.Maid:Mark(self.Folder.ChildAdded:Connect(function(p11) -- line: 178
        -- upvalues: self (copy), VALUE_OBJECT_OVERRIDES (copy), hookStateObject (copy)
        debug.profilebegin("TagReplicator_ChildAdded")

        if VALUE_OBJECT_OVERRIDES[p11.Name] then
            hookStateObject(self, p11)
        end

        debug.profileend()
    end))
    self.Maid:Mark(self.Changed:Connect(function(p12, p13) -- line: 186
        -- upvalues: self (copy)
        self.State[p12] = p13
    end))

    for v5, v6 in self.Folder:GetAttributes() do
        self.RawState[v5] = v6
        self.State[v5] = Deserialize(v6)
    end

    return self
end

function t1.WaitForState(p14, p15) -- line: 198
    -- upvalues: TypedPromise (copy), Sanitize (copy)
    local v7 = Sanitize(p15)

    return TypedPromise.new(function(p16, p17, p18) -- line: 201
        -- upvalues: v7 (copy), p14 (copy)
        if p14:Get(v7) ~= nil then
            p16(p14:Get(v7))

            return
        end

        local v8 = task.delay(10, function() -- line: 207
            -- upvalues: v7 (copy)
            warn((("Potential infinite yield on WaitForState: %*"):format(v7)))
        end)
        local connection

        local function v9() -- line: 212
            -- upvalues: p17 (copy), v8 (copy), connection (ref)
            connection:Disconnect()
            task.cancel(v8)
            p17("State was destroyed")
        end

        connection = p14.Changed:Connect(function(p19, p20) -- line: 219
            -- upvalues: p16 (copy), v8 (copy), connection (ref), v9 (copy), v7 (copy), p14 (copy)
            if p19 ~= v7 then
                return
            end

            p16(p20)
            p14.Maid:Unmark(v9)
            task.cancel(v8)
            connection:Disconnect()
        end)
        p18(v9)
        p14.Maid:Mark(v9)
    end):expect()
end

function t1.Has(p21, p22) -- line: 235
    -- upvalues: Sanitize (copy)
    local v10 = Sanitize(p22)

    return p21.Folder:GetAttribute(v10) ~= nil
end

function t1.Set(p23, p24, p25) -- line: 240
    -- upvalues: Serialize (copy), Sanitize (copy), VALUE_OBJECT_OVERRIDES (copy)
    if VALUE_OBJECT_OVERRIDES[p24] then
        local v11 = p23.Folder:FindFirstChild(p24)

        if v11 then
            v11.Value = p25
        else
            local v12 = Instance.new(VALUE_OBJECT_OVERRIDES[p24])

            v12.Name = p24
            v12.Value = p25
            v12.Parent = p23.Folder
            p23.Maid:Mark(v12)
        end
    else
        local v13 = Sanitize(p24)

        p23.Folder:SetAttribute(v13, Serialize(p25))
    end
end

function t1.Get(p26, p27) -- line: 259
    -- upvalues: Deserialize (copy), Sanitize (copy), VALUE_OBJECT_OVERRIDES (copy)
    if VALUE_OBJECT_OVERRIDES[p27] then
        return p26.Folder:FindFirstChild(p27) and p26.Folder:FindFirstChild(p27).Value
    end

    local v14 = Sanitize(p27)
    local v15 = p26.State[v14]

    if v15 ~= nil then
        return v15
    end

    local Attribute = p26.Folder:GetAttribute(v14)

    if Attribute == nil then
        return nil
    end

    local v16 = Deserialize(Attribute)

    p26.State[v14] = v16

    return v16
end

function t1.GetObject(p28, p29) -- line: 280
    -- upvalues: VALUE_OBJECT_OVERRIDES (copy)
    if VALUE_OBJECT_OVERRIDES[p29] then
        return p28.Folder:FindFirstChild(p29) and p28.Folder:FindFirstChild(p29)
    end
end

function t1.RefreshValueObjects(p30, p31) -- line: 286
    -- upvalues: VALUE_OBJECT_OVERRIDES (copy)
    for v17 in pairs(VALUE_OBJECT_OVERRIDES) do
        local v18 = p30.Folder:FindFirstChild(v17)

        if v18 then
            p31[v18.Name] = v18.Value
        end
    end
end

function t1.Hook(p32, p33) -- line: 300
    -- upvalues: Deserialize (copy), Sanitize (copy), VALUE_OBJECT_OVERRIDES (copy)
    for v19, v20 in next, p32.Folder:GetAttributes() do
        p33[Sanitize(v19)] = Deserialize(v20)
    end

    for _, child in pairs(p32.Folder:GetChildren()) do
        if VALUE_OBJECT_OVERRIDES[child.Name] then
            p33[child.Name] = child.Value
        end
    end

    p32.Maid:Mark(p32.Folder.ChildAdded:Connect(function(p34) -- line: 312
        -- upvalues: p33 (copy), VALUE_OBJECT_OVERRIDES (copy)
        if VALUE_OBJECT_OVERRIDES[p34.Name] then
            p33[p34.Name] = p34.Value
        end
    end))
    p32.Maid:Mark(p32.Changed:Connect(function(p35, p36) -- line: 318
        -- upvalues: p33 (copy)
        p33[p35] = p36
    end))
end

function t1.GetStateChangedSignal(p37, p38) -- line: 330
    -- upvalues: Signal (copy), Sanitize (copy)
    local v21 = Sanitize(p38)

    if not p37.AttributeConnections[v21] then
        p37.AttributeConnections[v21] = Signal.new()
        p37.Maid:Mark(p37.AttributeConnections[v21])
    end

    return p37.AttributeConnections[v21]
end

function t1._initializeState(p39) -- line: 346
    -- upvalues: Deserialize (copy), VALUE_OBJECT_OVERRIDES (copy)
    for v22, v23 in pairs(p39.Folder:GetAttributes()) do
        if p39.AttributeConnections[v22] then
            p39.AttributeConnections[v22]:Fire(Deserialize(v23))
        end

        p39.Changed:Fire(v22, v23)
    end

    for _, child in pairs(p39.Folder:GetChildren()) do
        if VALUE_OBJECT_OVERRIDES[child.Name] then
            if p39.AttributeConnections[child.Name] then
                p39.AttributeConnections[child.Name]:Fire(child.Value)
            end

            p39.Changed:Fire(child.Name, child.Value)
        end
    end
end

function t1.GetAllStates(p40) -- line: 366
    return p40.State
end

function t1.Destroy(p41) -- line: 370
    -- upvalues: t5 (copy)
    if p41.Maid then
        debug.profilebegin("TagReplicator_Destroy")
        debug.profilebegin(p41._lifecycleProfileLabel)
        p41.Maid:Sweep()
        p41.Maid = nil

        local _profileKind = p41._profileKind

        t5.Total += -1
        t5[_profileKind] = (t5[_profileKind] or 0) + -1

        if t5[_profileKind] <= 0 then
            t5[_profileKind] = nil
        end

        debug.profileend()
        debug.profileend()
    end
end

function t1.hook(p42, p43) -- line: 417
    -- upvalues: CollectionService (copy), t1 (copy), t2 (copy), t3 (copy), v1 (copy), v2 (copy)
    if t2[p42] ~= nil then
        warn("TagReplicator.hook: tag already hooked: " .. p42)

        return
    end

    t2[p42] = {}

    local t9 = {}

    local function onTagAdded(p44) -- line: 427
        -- upvalues: p42 (copy), p43 (copy), t9 (copy), t1 (copy), t2 (copy), t3 (copy), v1 (copy), v2 (copy)
        if t9[p44] then
            return
        end

        local v24 = t1._new(p44)

        v24._tracked = true

        local t10 = {
            creating = true,
            removed = false
        }

        t9[p44] = t10
        t3[p44] = v24
        v1:Fire(v24)

        local v25 = p43(p44, v24)

        if v25 then
            if v25.Maid then
                v25.Maid:Mark(v24)
            end

            if t9[p44] ~= t10 or t10.removed then
                v25:Destroy()
            else
                t2[p42][p44] = v25
            end
        end

        if t9[p44] == t10 and not t10.removed then
            t9[p44] = true

            return
        end

        if t9[p44] ~= true or t10.removed then
            if t3[p44] == v24 then
                v2:Fire(v24)
                t3[p44] = nil
            end

            v24:Destroy()
        end
    end

    local function onTagRemoved(p45) -- line: 469
        -- upvalues: p42 (copy), t9 (copy), t2 (copy), t3 (copy), v2 (copy)
        local v27 = t9[p45]

        if typeof(v27) == "table" and v27.creating then
            v27.removed = true
            t9[p45] = nil

            return
        end

        t9[p45] = nil

        local v28 = t3[p45]

        if t2[p42][p45] then
            t2[p42][p45]:Destroy()
            t2[p42][p45] = nil
        elseif v28 then
            v28:Destroy()
        end

        if v28 then
            v2:Fire(v28)
            t3[p45] = nil
        end
    end

    CollectionService:GetInstanceAddedSignal(p42):Connect(onTagAdded)
    CollectionService:GetInstanceRemovedSignal(p42):Connect(onTagRemoved)

    for _, v29 in CollectionService:GetTagged(p42) do
        task.defer(onTagAdded, v29)
    end
end

function t1.getTrackedReplicator(p46) -- line: 501
    -- upvalues: t3 (copy)
    local v30 = t3[p46]

    return if v30 and v30.Maid ~= nil then v30 else nil
end

function t1.watchTrackedReplicator(p47, p48, p49) -- line: 506
    -- upvalues: Maid (copy), t3 (copy), v1 (copy), v2 (copy)
    local v31 = Maid.new()
    local v32 = t3[p47]

    if v32 and v32.Maid ~= nil then
        task.defer(p48, v32)
    end

    v31:Mark(v1:Connect(function(p50) -- line: 514
        -- upvalues: p47 (copy), p48 (copy)
        if p50 and p50.Maid ~= nil and p50.Folder == p47 then
            p48(p50)
        end
    end))

    if p49 then
        v31:Mark(v2:Connect(function(p51) -- line: 521
            -- upvalues: p47 (copy), p49 (copy)
            if p51 and p51.Folder == p47 then
                p49(p51)
            end
        end))
    end

    return function() -- line: 528
        -- upvalues: v31 (copy)
        v31:Sweep()
    end
end

function t1.getChangedReplicators(p52, p53, p54) -- line: 533
    -- upvalues: Maid (copy), v1 (copy), v2 (copy)
    local v33 = Maid.new()

    v33:Mark(v1:Connect(function(p55) -- line: 536
        -- upvalues: p52 (copy), p53 (copy)
        if p55 and p55:Get("Name") == p52 then
            p53(p55)
        end
    end))
    v33:Mark(v2:Connect(function(p56) -- line: 542
        -- upvalues: p52 (copy), p54 (copy)
        if p56 and p56:Get("Name") == p52 then
            p54(p56)
        end
    end))

    return function() -- line: 548
        -- upvalues: v33 (copy)
        v33:Sweep()
    end
end

function t1.acquireReplicatorEntityFromFolder(p57) -- line: 553
    -- upvalues: t1 (copy), t3 (copy), t4 (copy)
    local v34 = t3[p57]

    if v34 and v34.Maid ~= nil then
        return v34, function() -- line: 556
        end
    end

    local v35 = t4[p57]

    if not (v35 and v35.replicator.Maid) then
        v35 = {
            references = 0,
            replicator = t1._new(p57)
        }
        v35.replicator._transient = true
        t4[p57] = v35
    end

    v35.references += 1

    local v36 = false

    return v35.replicator, function() -- line: 573
        -- upvalues: p57 (copy), v35 (ref), v36 (ref), t4 (copy)
        if v36 then
            return
        end

        v36 = true

        local v37 = v35

        v37.references -= 1

        if v35.references <= 0 and t4[p57] == v35 then
            t4[p57] = nil
            v35.replicator:Destroy()
        end
    end
end

function t1.getReplicatorEntityFromFolder(p58) -- line: 588
    -- upvalues: t1 (copy)
    return t1._new(p58)
end

function t1.getActiveCounts() -- line: 592
    -- upvalues: t5 (copy)
    local t11 = {}

    for v38, v39 in t5 do
        t11[v38] = v39
    end

    return t11
end

return t1
