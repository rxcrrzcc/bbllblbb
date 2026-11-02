-- https://lua.expert

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Maid = require(ReplicatedStorage.Shared.Modules.Maid)
local Signal = require(ReplicatedStorage.Shared.Modules.Signal)
local TagReplicator = require(ReplicatedStorage.Client.Modules.TagReplicator)

require(ReplicatedStorage.Shared.Types.StatusEffects)

local t1 = {}

t1.__index = t1

local t2 = {
    Stunned = "Stun"
}
local t3 = {}

local function getVisuals(p1) -- line: 38
    -- upvalues: t2 (copy), t3 (copy)
    if t3[p1] ~= nil then
        return t3[p1]
    end

    local Visuals = script.Parent:FindFirstChild("Visuals")

    if Visuals then
        local t4 = {
            p1
        }
        local v1 = t2[p1]

        if v1 then
            table.insert(t4, v1)
        end

        for _, v2 in t4 do
            local v3 = Visuals:FindFirstChild((("%*Visuals"):format(v2)))

            if v3 then
                t3[p1] = require(v3)

                return t3[p1]
            end
        end
    end

    t3[p1] = nil

    return nil
end

function t1.new(p2, p3, p4) -- line: 64
    -- upvalues: Maid (copy), Signal (copy), TagReplicator (copy), t1 (copy), getVisuals (copy)
    local self = setmetatable({}, t1)

    self._entity = p2
    self._activeEffects = {}
    self._cleanupData = {}
    self._maid = Maid.new()
    self._replicator = p4 or TagReplicator.getReplicatorEntityFromFolder(p3)

    if not p4 then
        self._maid:Mark(self._replicator)
    end

    self.Changed = Signal.new()
    self._maid:Mark(self.Changed)

    local function onChanged(p5, p6) -- line: 79
        -- upvalues: self (copy), getVisuals (copy)
        if p6 then
            if self._activeEffects[p5] then
                self._activeEffects[p5] = p6

                local v5 = getVisuals(p5)

                if v5 and v5.onUpdated then
                    v5.onUpdated(self._entity, p6, self._cleanupData[p5])
                end
            else
                self._activeEffects[p5] = p6

                local v6 = getVisuals(p5)

                if v6 and v6.onAdded then
                    self._cleanupData[p5] = v6.onAdded(self._entity, p6)
                end
            end
        else
            local v7 = self._activeEffects[p5]

            if v7 then
                local v8 = getVisuals(p5)

                if v8 and v8.onRemoved then
                    v8.onRemoved(self._entity, v7, self._cleanupData[p5])
                end

                self._activeEffects[p5] = nil
                self._cleanupData[p5] = nil
            end
        end

        self.Changed:Fire(p5, p6 ~= nil)
    end

    self._maid:Mark(self._replicator.Changed:Connect(onChanged))

    for v9, v10 in self._replicator:GetAllStates() do
        task.spawn(onChanged, v9, v10)
    end

    return self
end

function t1:has(p8) -- line: 118
    return self._activeEffects[p8] ~= nil
end

function t1:hasAnyWithTag(p10) -- line: 122
    for _, v11 in self._activeEffects do
        for _, v12 in v11.tags or {} do
            if v12 == p10 then
                return true
            end
        end
    end

    return false
end

function t1:get(p12) -- line: 134
    return self._activeEffects[p12]
end

function t1:destroy() -- line: 138
    -- upvalues: getVisuals (copy)
    for v13, v14 in self._activeEffects do
        local v15 = getVisuals(v13)

        if v15 and v15.onRemoved then
            v15.onRemoved(self._entity, v14, self._cleanupData[v13])
        end
    end

    table.clear(self._activeEffects)
    table.clear(self._cleanupData)
    self._maid:Sweep()
    setmetatable(self, nil)
end

return t1
