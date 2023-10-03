---------------------------------------
---------------------------------------
--         Star Trek Weapons         --
--                                   --
--            Created by             --
--       Jan 'Oninoni' Ziegler       --
--                                   --
-- This software can be used freely, --
--    but only distributed by me.    --
--                                   --
--    Copyright © 2021 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
--  Pattern Enhancer case | Server   --
---------------------------------------

if not istable(SWEP) then Star_Trek:LoadAllModules() return end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function SWEP:Initialize()
	self:SetNWString("bodyGroups", "0000")
end

function SWEP:PrimaryAttack()
	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return end

	local tr = owner:GetEyeTrace()
	if not tr.Hit then return end

	if self:Clip1() > 0 and tr.HitPos:Distance(owner:GetPos()) < 200 and self:CheckAngle(tr.HitNormal) then
		self:SpawnEnhancer(tr)
	end
end

function SWEP:SpawnEnhancer(tr)
	self:SetClip1(self:Clip1() - 1)
	self:UpdatePatternEnhacerBodygroup()

	local ent = ents.Create("pattern_enhancer")
	ent:SetPos(tr.HitPos + Vector(0,0,0.4))
	ent:SetAngles(tr.HitNormal:Angle() + Angle(90, 0, 0))
	ent:Spawn()
	ent:Activate()
end

function SWEP:RemoveEnhancer(ent)
	self:SetClip1(self:Clip1() + 1)
	self:UpdatePatternEnhacerBodygroup()
	ent:Remove()
end

function SWEP:SecondaryAttack()
	if not IsFirstTimePredicted() then return end

	local owner = self:GetOwner()
	if not IsValid(owner) then return true end

	local tr = owner:GetEyeTrace()
	if not tr.Hit then return end

	local hitEnt = tr.Entity
	if not IsValid(hitEnt) then return end

	if hitEnt:GetClass() == "pattern_enhancer" and tr.HitPos:Distance(owner:GetPos()) < 200 and self:Clip1() < 3 then
			self:RemoveEnhancer(hitEnt)
	end
end

function SWEP:CheckAngle(normal)
	local worldUp = Vector(0, 0, 1)

	local dotProduct = normal:Dot(worldUp)

	-- Calculate the angle between the vectors in degrees
	local angle = math.deg(math.acos(dotProduct))

	return angle <= 25
end

function SWEP:UpdatePatternEnhacerBodygroup()

	local bodygroup = "0000" -- why 4? no idea :)
    if self:Clip1() == 0 then
        bodygroup = "1111"
    elseif self:Clip1() == 1 then
        bodygroup = "0110"
    elseif self:Clip1() == 2 then
        bodygroup = "0010"
	end

	self:SetNWString("bodyGroups", bodygroup)
end

hook.Add("PlayerDroppedWeapon", "Star_Trek.Transporter.Enhancer_case_drop", function(ply, weapon)
	if weapon:GetClass() ~= "pattern_enhancer_case" then return end
	weapon:SetBodyGroups(weapon:GetNWString("bodyGroups"))
end)

hook.Add("PlayerCanPickupWeapon", "Star_Trek.Transporter.Enhancer_case_pickup", function(ply, weapon)
	if weapon:GetClass() ~= "pattern_enhancer_case" then return end

	if ply:HasWeapon("pattern_enhancer_case") then
		return false
	end
end)