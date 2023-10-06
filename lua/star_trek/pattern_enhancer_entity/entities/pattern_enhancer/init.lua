---------------------------------------
---------------------------------------
--         Star Trek Modules         --
--                                   --
--            Created by             --
--       Jan 'Oninoni' Ziegler       --
--                                   --
-- This software can be used freely, --
--    but only distributed by me.    --
--                                   --
--    Copyright © 2022 Jan Ziegler   --
---------------------------------------
---------------------------------------

---------------------------------------
--     Pattern Enhancer | Server     --
---------------------------------------

if not istable(ENT) then Star_Trek:LoadAllModules() return end

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local RADIUS = 250
local MAX_DEPTH = 3
local connectedEnhancers = {} -- {{connectedEnts = {111, 113, 324}, locName = name}, ...}
local AllIds = {}
local offset = Vector(0, 0, 43)

sound.Add({
	name = "pattern_enhancer_hum",
	channel = CHAN_AUTO,
	volume = 0.2,
	level = 80,
	pitch = 100,
	sound = "ambient/energy/force_field_loop1.wav"})

function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end

	local dotProduct = tr.HitNormal:Dot(Vector(0, 0, 1))

	local angle = math.deg(math.acos(dotProduct))

	if angle > 30 then return end

	local ent = ents.Create(ClassName)
	ent:SetPos(tr.HitPos + Vector(0,0,0.4))
	ent:SetAngles(tr.HitNormal:Angle() + Angle(90, 0, 0))
	ent:Spawn()
	ent:Activate()
	return ent
end

function ENT:Initialize()
	self:SetModel("models/crazycanadian/star_trek/tools/pattern_enhancer/pattern_enhancer_unfolded.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
	end
	self:SetNWBool("active", false)
	self:SetVar("connected", false)
	self:UpdateScannerData()

	if not timer.Exists("patternEnhancersCheckDistAng") then
		-- Since motion is disabled the distance can't be too long, but
		-- the pattern enhancers can still be unfrozen with physguns, so this is here just in case.
		-- So this happens only every 2 secs
		timer.Create("patternEnhancersCheckDistAng", 2, 0, CheckPatternEnhancers)
	end
end

-- Check if the pattern enhancers are still in a valid position
function CheckPatternEnhancers()
	if table.IsEmpty(connectedEnhancers) then return end

	for j, connection in ipairs(connectedEnhancers) do
		local connectedEnts = connection["connectedEnts"]
		local newMiddlePos = Vector(0,0,0)

		for i, ent in ipairs(connectedEnts) do
			local other
			if i == #connectedEnts then
				other = connectedEnts[1]
			else
				other = connectedEnts[i + 1]
			end
			if not (IsValid(other) and IsValid(ent)) then return end

			if not ent:CheckDistWith(other) or not ent:CheckAngle() or not ent:CheckTrace(other) then
				ent:RemoveConnection()
				break
			end
			newMiddlePos:Add(ent:GetPos())
		end

		local ent = connectedEnts[1]
		if not IsValid(ent) then continue end
		newMiddlePos:Div(#connectedEnts)

		-- Update the transporter location
		for i, externalData in pairs(Star_Trek.Transporter.Externals) do
			if externalData.Name ~= connection["locName"] then continue end

			local success, middlePosValid = CheckMiddlePos(newMiddlePos)
			if not success then
				ent:RemoveConnection()
				break
			end
			if not externalData.Pos:IsEqualTol(middlePosValid, 10) then
				externalData.Pos = middlePosValid
			end
			break
		end
	end
end

-- returns true if within radius
function ENT:CheckDistWith(other)
	return self:GetPos():DistToSqr(other:GetPos()) <= RADIUS * RADIUS
end

function ENT:Use(ply)
	if not self:GetNWBool("active") then
		self:TurnOn()
		self:StartConnection()
	else
		self:TurnOff()
	end
end

function ENT:OnRemove()
	self:TurnOff()

	-- Remove the timer if there are no more pattern enhancers
	local AllClassObjects = ents.FindByClass("pattern_enhancer")
	if #AllClassObjects <= 0 then
		timer.Remove("patternEnhancersCheckDistAng")
	end
end

function ENT:OnTakeDamage(damage)
	-- Make the pattern enhancer react to the damage
	local phys = self:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(true)
		phys:ApplyForceCenter(damage:GetDamageForce())
	end

	-- Create the effect
	local effectdata = EffectData()
	effectdata:SetOrigin(damage:GetDamagePosition())
	util.Effect("StunstickImpact", effectdata)

	self:TurnOff()
	self:EmitSound("ambient/energy/spark" .. math.random(1, 6) .. ".wav")
end

function ENT:TurnOn()
	self:SetSkin(1)

	self:SetNWBool("active", true)
	self:EmitSound("oninoni/startrek/lcars/lcars_click2.wav")
end

function ENT:TurnOff()
	if self:GetNWBool("Active") then
		self:EmitSound("oninoni/startrek/lcars/lcars_click2.wav")
	end

	self:SetSkin(0)
	self:SetNWBool("active", false)

	if self.connected then
		self:RemoveConnection()
	end
end

function ENT:CheckAngle()

	local dotProduct = self:GetUp():Dot(vector_up)

	local angle = math.deg(math.acos(dotProduct))

	return angle <= 45
end

function ENT:UpdateScannerData()
	local active = self:GetNWBool("active") and "Activated" or "Not activated"

	local connectionIndex = self:CheckIndexConnectedEnhancers()

	local transporterLocName = "None"
	if connectionIndex ~= 0 then -- self is not connected to anything
		transporterLocName = connectedEnhancers[connectionIndex]["locName"]
	end
	self.ScannerData = active .. "\nTransporter Location: " .. transporterLocName
end

function ENT:StartConnection()
	local orgTrail = {self}
	local success = false
	local finalTrail = {}
	if not self:CheckAngle() then
		return
	end

	for _, other in ipairs(self:FindNearbyPatternEnhancers()) do
		if not other:IsValidNewConnection(self) or not other:IsValidNewConnection(self) then
			continue
		end
		
		local dist = self:GetPos():Distance(other:GetPos())
		success, finalTrail = other:ContinueConnection(table.Copy(orgTrail), 1, dist)
		if success then break end
	end

	if success then
		print("CONNECTION FOUND")
		self:AddConnection(finalTrail)
	else
		print("CONNECTION NOT FOUND")
	end
end

--[[
	depth: how many pattern enhancers are already connected
	dist: distance between the first and last pattern enhancer
]]
function ENT:ContinueConnection(currentTrail, depth, dist)
	if depth >= MAX_DEPTH then return false, {} end

	local orgStartEnhancer = currentTrail[1]

	for _, other in ipairs(self:FindNearbyPatternEnhancers()) do
		local newTrail = table.Copy(currentTrail)

		-- is the other the same as the original start enhancer
		if other:EntIndex() == orgStartEnhancer:EntIndex() then
			-- check if the trail is long enough and if the other is valid
			if #currentTrail >= 2 and self:CheckDistWith(other) and other:CheckTrace(self) then
				if not distAlmostEqualToDist(dist, self:GetPos():Distance(other:GetPos())) then
					continue
				end
				table.insert(newTrail, self)

				return true, newTrail
			end
			continue
		end

		-- check if already connected and if the other is valid
		if table.HasValue(currentTrail, other:EntIndex()) or not other:IsValidNewConnection(self) then
			continue
		end

		-- check if the distance is almost the same as the first distance so 
		-- that the pattern enhancers are similair to a equilateral triangle
		if not distAlmostEqualToDist(dist, self:GetPos():Distance(other:GetPos())) then
			continue
		end
		table.insert(newTrail, self)

		local success, trail = other:ContinueConnection(newTrail, depth + 1, dist)
		if success then return true, trail end
	end

	return false, {}
end

-- returns true if the distance is almost the same
function distAlmostEqualToDist(dist, curDist)
	return math.abs((curDist - dist) / ((curDist + dist) / 2)) < 0.35
end

-- returns true if the trace is not blocked
function ENT:CheckTrace(other)
	local offset1 = Vector(offset:Unpack())
	local offset2 = Vector(offset:Unpack())
	offset1:Rotate(self:GetAngles())
	offset2:Rotate(other:GetAngles())

	local tr = util.TraceLine( {
		start = self:GetPos() + offset1,
		endpos = other:GetPos() + offset2,
		mask = MASK_SOLID,
		filter = function(hitEnt) if hitEnt == self then return false else return true end end,
	})
	if tr.HitWorld then
		return false
	end
	return true
end

-- returns true if the other is a valid new connection
function ENT:IsValidNewConnection(other)
	if self:GetNWBool("active") and not self.connected and self:CheckAngle() and not self.HoloMatter then
		return self:CheckTrace(other)
	else
		return false
	end
end

-- returns all pattern enhancers within the radius
function ENT:FindNearbyPatternEnhancers()
	local AllClassObjects = ents.FindByClass("pattern_enhancer")

	local objects = {}
	for _, ent in ipairs(AllClassObjects) do
		if ent:IsValid() and self:CheckDistWith(ent) and ent:EntIndex() ~= self:EntIndex() then
			table.insert(objects, ent)
		end
	end
	return objects
end

-- returns the index of the connected enhancers table otherwise 0
function ENT:CheckIndexConnectedEnhancers()
	for i, connection in ipairs(connectedEnhancers) do
		if table.HasValue(connection["connectedEnts"], self) then
			return i
		end
	end
	return 0
end

function ENT:RemoveConnection()
	local connectionIndex = self:CheckIndexConnectedEnhancers()
	if connectionIndex == 0 then return end -- self is not connected to anything

	-- Get the corresponding Transporter location
	local transportIndex
	for i, externalData in pairs(Star_Trek.Transporter.Externals) do
		if externalData.Name == connectedEnhancers[connectionIndex]["locName"] then
			transportIndex = i
			break
		end
	end

	if transportIndex ~= nil then
		table.remove(Star_Trek.Transporter.Externals, transportIndex)

		hook.Run("Star_Trek.Transporter.ExternalsChanged")
	end

	-- Remove LocName ID from the all IDs
	local locNameID = string.Split(connectedEnhancers[connectionIndex]["locName"], " ")[3]
	AllIds[locNameID] = nil

	local connectedEnts = table.Copy(connectedEnhancers[connectionIndex]["connectedEnts"])
	table.remove(connectedEnhancers, connectionIndex)

	for i, ent in ipairs(connectedEnts) do
		ent.connected = false
		ent:UpdateScannerData()
		ent:EmitSound("oninoni/startrek/pattern_enhancer_startup.mp3", 75, 80, 0.75)

		if ent.soundLoopID ~= nil then
			ent:StopLoopingSound(ent.soundLoopID)
			ent.soundLoopID = nil
		end

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(true)
		end
	end
	UpdateConnectedEnhancers()
end

-- returns true if the middle position is valid
function CheckMiddlePos(middlePos)
	local tr = util.TraceLine({
		start = middlePos + offset,
		endpos = middlePos - Vector(0, 0, 10),
		mask = MASK_SOLID_BRUSHONLY,
	})

	if tr.AllSolid then
		return false, vector_origin
	end
	if tr.HitWorld then
		return true, tr.HitPos + Vector(0, 0, 4)
	end
	return false, vector_origin
end

function ENT:AddConnection(connenctedTable)
	-- claculate the middle position
	local middlePos = Vector(0,0,0)
	for i, ent in ipairs(connenctedTable) do
		middlePos:Add(ent:GetPos())
	end
	middlePos:Div(#connenctedTable)

	-- Check if the middle position is valid
	local success, middlePosValid = CheckMiddlePos(middlePos)
	if not success then
		local connectionIndex = self:CheckIndexConnectedEnhancers()

		table.remove(connectedEnhancers, connectionIndex)
		UpdateConnectedEnhancers()
		return
	end

	-- Give unique LocName
	local transporterLocID
	repeat
		transporterLocID = tostring(math.random(0, 1000))
	until (AllIds[transporterLocID] ~= true)

	AllIds[transporterLocID] = true

	-- Make transporter location
	local name = "Pattern Enhancer " .. transporterLocID
	local externalData = {
		Name = name,
		Pos = middlePosValid,
		IgnoreInterference = true
	}

	table.insert(Star_Trek.Transporter.Externals, externalData)

	-- Connect the other enhancers
	table.insert(connectedEnhancers, {connectedEnts = connenctedTable, locName = name})
	for _, ent in ipairs(connenctedTable) do
		ent.connected = true
		ent:UpdateScannerData()
		ent:EmitSound("oninoni/startrek/pattern_enhancer_startup.mp3", 75, 100, 0.75)
		ent.soundLoopID = self:StartLoopingSound("pattern_enhancer_hum")

		local phys = ent:GetPhysicsObject()
		if IsValid(phys) then
			phys:EnableMotion(false)
		end
	end
	UpdateConnectedEnhancers()
end

-- Send the connected enhancers to the clients
util.AddNetworkString("UpdatePatternEnhancersConnected")
function UpdateConnectedEnhancers(ply)
	net.Start("UpdatePatternEnhancersConnected")
	net.WriteUInt(#connectedEnhancers, 7) -- Max number of connections 127

	for _, connection in ipairs(connectedEnhancers) do
		local connectedEnts = connection["connectedEnts"]
		for _, ent in ipairs(connectedEnts) do
			net.WriteUInt(ent:EntIndex(), 14) -- max value 16383
		end
	end

	if ply ~= nil then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

-- Sync connected enhancers with newly joined players.
hook.Add("PlayerInitialSpawn", "StarTrek.PatternEnhancer.SyncConnectedBeams", function( ply )
	UpdateConnectedEnhancers(ply)
end)