---------------------------------------
---------------------------------------
--   This file is protected by the   --
--           MIT License.            --
--                                   --
--   See LICENSE for full            --
--   license details.                --
---------------------------------------
---------------------------------------

---------------------------------------
--  Pattern Enhancer case | Client   --
---------------------------------------

include("shared.lua")
if not istable(SWEP) then Star_Trek:LoadAllModules() return end


SWEP.Author         = "GuuscoNL"
SWEP.Contact        = "Discord: guusconl"
SWEP.Purpose        = "A container for holding pattern enhancers and to place them down"
SWEP.Instructions   = "Left-Click to place a pattern enhancer, Right-Click to pickup a pattern enhancer"
SWEP.Category       = "Star Trek (Utilities)"

SWEP.DrawAmmo       = true

SWEP.ViewModelOffset  = Vector(0, -20, -20)

-- Hide viewmodel off screen
function SWEP:GetViewModelPosition(EyePos, EyeAng)
	local Offset = self.ViewModelOffset

	EyePos = EyePos + Offset.x * EyeAng:Right()
	EyePos = EyePos + Offset.y * EyeAng:Forward()
	EyePos = EyePos + Offset.z * EyeAng:Up()

	return EyePos, EyeAng
end

-- code from oni_swep_base :)
function SWEP:DrawWorldModel(flags)

    local owner = self:GetOwner()
    if not IsValid(owner) then
        self:DrawModel(flags)

        return
    end

    if not IsValid(self.CustomWorldModelEntity) then
        self.CustomWorldModelEntity = ClientsideModel(self.WorldModel)
        if not IsValid(self.CustomWorldModelEntity) then
            return
        end

        self.CustomWorldModelEntity:SetNoDraw(true)
        self.CustomWorldModelEntity:SetModelScale(self.CustomWorldModelScale)
    end

    local boneId = owner:LookupBone(self.CustomWorldModelBone)
    if boneId == nil then
        return
    end

    local m = owner:GetBoneMatrix(boneId)
    if not m then
        return
    end

    local pos, ang = LocalToWorld(self.CustomWorldModelOffset, self.CustomWorldModelAngle, m:GetTranslation(), m:GetAngles())

    self.CustomWorldModelEntity:SetPos(pos)
    self.CustomWorldModelEntity:SetAngles(ang)

    self.CustomWorldModelEntity:SetBodyGroups(self:GetNWString("bodyGroups"))

    self.CustomWorldModelEntity:DrawModel(flags)

	if isfunction(self.DrawWorldModelCustom) then
		self:DrawWorldModelCustom(flags)
	end
end
