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
--     Pattern Enhancer | Client     --
---------------------------------------

if not istable(ENT) then Star_Trek:LoadAllModules() return end

include("shared.lua")

-- Stores all the pattern enhancers that are connected to eachother
local connectedEnhancers = {}
net.Receive("UpdatePatternEnhancersConnected", function()
	numberConnections = net.ReadUInt(7)
	connectedEnhancers = {}
	for i = 1, numberConnections do
		local connection = {}
		for j = 1, 3 do
			table.insert(connection, net.ReadUInt(14))
		end
		table.insert(connectedEnhancers, connection)
	end
end)

local offset = Vector(0, 0, 43)
local BEAM_MATERIAL = Material("sprites/tp_beam001")
local SPRITE_MATERIAL = Material( "sprites/light_glow02_add" )
hook.Add("PostDrawTranslucentRenderables", "DrawBeams", function ()
	for _, connection in ipairs(connectedEnhancers) do
		local middlePos = Vector(0, 0, 0)
		local success = true
		for i, ent1ID in ipairs(connection) do
			local ent1 = Entity(ent1ID)

			if not IsValid(ent1) then
				success = false
				break
			end

			local ent2

			if i == #connection then
				ent2 = Entity(connection[1])
			else
				ent2 = Entity(connection[i + 1])
			end
			if not IsValid(ent2) then
				success = false
				break
			end
			middlePos:Add(ent1:GetPos())

			local offset1 = Vector(offset:Unpack())
			local offset2 = Vector(offset:Unpack())
			offset1:Rotate(ent1:GetAngles())
			offset2:Rotate(ent2:GetAngles())

			cam.Start3D()
				render.SetMaterial(SPRITE_MATERIAL)
				render.DrawSprite(ent1:GetPos() + offset1, 90, 90, Color(44, 62, 127))
				render.SetMaterial(BEAM_MATERIAL)
				render.DrawBeam(ent1:GetPos() + offset1, ent2:GetPos() + offset2, 4, 0, 1, Color(48, 25, 138))
				render.DrawBeam(ent1:GetPos() + offset1, ent2:GetPos() + offset2, 2, 0.5, 1.5, Color(150, 150, 150))
			cam.End3D()
		end

		if success then
			-- create light
			-- print("LIGHT")
			middlePos:Div(#connection)

			local light = DynamicLight(connection[1])
			if light then
				light.pos = middlePos + offset
				light.r = 0
				light.g = 23
				light.b = 126
				light.brightness = 1
				light.Decay = 500
				light.Size = 250
				light.DieTime = CurTime() + 1
			end
		end
	end
end)

hook.Add("PostDrawTranslucentRenderables", "DrawActiveGlow", function ()
	local AllClassObjects = ents.FindByClass("pattern_enhancer")
	for _, ent in ipairs(AllClassObjects) do
		if not IsValid(ent) then break end

		if ent:GetNWBool("active") then
			local offset1 = Vector(offset:Unpack())
			offset1:Rotate(ent:GetAngles())
			cam.Start3D()
				render.SetMaterial(SPRITE_MATERIAL)
				render.DrawSprite(ent:GetPos() + offset1, 40, 40, Color(71, 71, 162))
			cam.End3D()
		end
	end
end)
