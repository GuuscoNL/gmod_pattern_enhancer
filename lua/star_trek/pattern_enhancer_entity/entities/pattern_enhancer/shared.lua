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
--     Pattern Enhancer | Server     --
---------------------------------------

if not istable(ENT) then Star_Trek:LoadAllModules() return end

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Pattern Enhancer"
ENT.Author = "GuuscoNL"

ENT.Category = "Star Trek"

ENT.Spawnable = true