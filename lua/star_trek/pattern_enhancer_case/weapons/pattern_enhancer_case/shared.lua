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
--  Pattern Enhancer case | Shared   --
---------------------------------------
if not istable(SWEP) then Star_Trek:LoadAllModules() return end

SWEP.Base = "oni_base"

SWEP.PrintName = "Pattern Enhancer Case"

SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.Slot = 3
SWEP.SlotPos = 0


SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/crazycanadian/star_trek/tools/pattern_enhancer/pattern_enhancer_case.mdl"

SWEP.HoldType = "slam"

SWEP.BoneManip = {
    ["ValveBiped.clip"] = {
        Pos = Vector(-100, 0, 0),
    },
    ["ValveBiped.base"] = {
        Pos = Vector(-100, 0, 0),
    },
    ["ValveBiped.square"] = {
        Pos = Vector(-100, 0, 0),
    },
    ["ValveBiped.hammer"] = {
        Pos = Vector(-100, 0, 0),
    },
    ["ValveBiped.Bip01_R_Finger1"] = {
        Ang = Angle(-20, -40, 0)
    },
    ["ValveBiped.Bip01_R_Hand"] = {
    Ang = Angle(21.707, 0, -90)
},}

-- CustomViewModel stuff does nothing?
SWEP.CustomViewModel = "models/crazycanadian/star_trek/tools/pattern_enhancer/pattern_enhancer_case.mdl"
SWEP.CustomViewModelBone = "ValveBiped.Bip01_R_Hand"
SWEP.CustomViewModelOffset = Vector(0, -18, 4)
SWEP.CustomViewModelAngle = Angle(140, 180, 90)
SWEP.CustomViewModelScale = 1

SWEP.CustomDrawWorldModel = true
SWEP.CustomWorldModelBone = "ValveBiped.Bip01_R_Hand"
SWEP.CustomWorldModelOffset = Vector(0, -2, 16)
SWEP.CustomWorldModelAngle = Angle(180, 180, 10)
SWEP.CustomWorldModelScale = 1

SWEP.Primary.Ammo = ""
SWEP.Primary.ClipSize = 3
SWEP.Primary.DefaultClip = 3
SWEP.Primary.Automatic = false

-- SWEP.Secondary.Ammo = ""
-- SWEP.Secondary.ClipSize = 0
-- SWEP.Secondary.DefaultClip = 0
-- SWEP.Secondary.Automatic = false