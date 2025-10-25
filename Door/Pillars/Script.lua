-- Não foi testado eu só criei e pronto
local RunS = game:GetService("RunService")
local Plrs = game:GetService("Players")

local P_FOLDER = "Pillars"
local TRG_DIST = 30
local ANIM_SMT = 0.08
local CASC_DLY = 0.1

local MOV_PATT = {
	["Pillar1"] = -3, ["Pillar2"] = 3, ["Pillar3"] = 3,
	["Pillar4"] = -3, ["Pillar5"] = -3, ["Pillar6"] = 3
}

local allPillars = {}
local pFolder = nil

local function setupPillars()
	if not pFolder then return end
	
	local children = pFolder:GetChildren()
	if #children == 0 then return end
	
	table.sort(children, function(a, b) return a.Name < b.Name end)

	for i, pillar in ipairs(children) do
		if pillar:IsA("BasePart") and MOV_PATT[pillar.Name] then
			pillar.Anchored = true
			
			table.insert(allPillars, {
				inst = pillar,
				ogPos = pillar.Position,
				movDir = MOV_PATT[pillar.Name],
				movDist = pillar.Size.Y,
				actTime = -1
			})
		end
	end
end

local function updateGate()
	if #allPillars == 0 then return end

	local closestPlr = nil
	local minDist = TRG_DIST + 20

	for _, plr in ipairs(Plrs:GetPlayers()) do
		if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local root = plr.Character.HumanoidRootPart
			local dist = (root.Position - allPillars[1].inst.Position).Magnitude
			if dist < minDist then
				minDist = dist
				closestPlr = root
			end
		end
	end

	if closestPlr then
		for i, pData in ipairs(allPillars) do
			if pData.actTime == -1 then
				if i == 1 then
					pData.actTime = tick()
				else
					local prevPData = allPillars[i-1]
					if prevPData.actTime > 0 and (tick() - prevPData.actTime) > CASC_DLY then
						pData.actTime = tick()
					end
				end
			end
		end
	else
		for _, pData in ipairs(allPillars) do
			pData.actTime = -1
		end
	end

	for _, pData in ipairs(allPillars) do
		local pillar = pData.inst
		local ogPos = pData.ogPos
		
		local openAlpha = 0
		if pData.actTime > 0 and closestPlr then
			local distToPillar = (closestPlr.Position - pillar.Position).Magnitude
			
			if distToPillar < TRG_DIST then
				openAlpha = 1 - (distToPillar / TRG_DIST)
				openAlpha = math.clamp(openAlpha, 0, 1)
			end
		end

		local movOffset = openAlpha * pData.movDist * pData.movDir
		local targetPos = ogPos + Vector3.new(0, movOffset, 0)

		pillar.Position = pillar.Position:Lerp(targetPos, ANIM_SMT)
	end
end

pFolder = workspace:WaitForChild(P_FOLDER, 30)

if pFolder then
	setupPillars()
	RunS.Heartbeat:Connect(updateGate)
else
	error("A pasta '" .. P_FOLDER .. "' não foi encontrada no Workspace.")
end
