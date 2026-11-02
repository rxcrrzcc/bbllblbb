--Там очень много таких модулей, поэтому возьму один
-- https://lua.expert

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Enum = require(ReplicatedStorage.Shared.Modules.Enum)
local EasySound = require(ReplicatedStorage.Shared.Modules.EasySound)
local EmitterManager = require(ReplicatedStorage.Shared.Modules.EmitterManager)
local TransientVFX = require(ReplicatedStorage.Client.Modules.TransientVFX)
local Particles = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Effects"):WaitForChild("Particles")

return {
    onAdded = function(p1, p2) -- onAdded | line: 19
        -- upvalues: Enum (copy), EasySound (copy), EmitterManager (copy), TransientVFX (copy), Particles (copy)
        if p2.definitionName ~= Enum.StatusEffect.Stunned then
            return nil
        end

        local Model = p1.Model
        local v1 = Model and Model.PrimaryPart

        if not v1 then
            return nil
        end

        local BaseStunParticles = p1.BaseStunParticles
        local v2

        if not (BaseStunParticles and BaseStunParticles.Parent) then
            local Dizzy = Particles:FindFirstChild("Dizzy")

            if not Dizzy then
                return nil
            end

            v2 = Dizzy:Clone()
            v2.Parent = workspace.Trash
            TransientVFX.track(v2, {
                profileName = "BaseStun"
            })
            v2.Anchored = false

            if p1.Maid then
                p1.Maid:Mark(v2)
            end

            p1.BaseStunParticles = v2
        else
            v2 = BaseStunParticles
        end

        local Rotate = v2:FindFirstChild("Rotate")

        if Rotate and Rotate:IsA("JointInstance") then
            Rotate.Part1 = v1
        end

        EmitterManager.toggle(v2, true)

        local v3 = v2:FindFirstChild("Sound", true)

        if v3 and v3:IsA("Sound") then
            EasySound.Play({
                soundGroupName = "Towers",
                id = v3.SoundId,
                position = v1.Position,
                volume = v3.Volume,
                playbackSpeed = v3.PlaybackSpeed
            })
        end

        return {
            effect = v2
        }
    end,
    onRemoved = function(p3, _, p5) -- onRemoved | line: 70
        -- upvalues: Debris (copy), EmitterManager (copy)
        if not (p5 and p5.effect) then
            return
        end

        local effect = p5.effect

        EmitterManager.toggle(effect, false)

        if p3.BaseStunParticles == effect then
            p3.BaseStunParticles = nil
        end

        if p3.Maid then
            p3.Maid:Unmark(effect)
        end

        Debris:AddItem(effect, 3)
    end
}
