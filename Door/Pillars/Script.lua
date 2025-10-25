local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PILLARS_FOLDER_NAME = "Pillars"
local TRIGGER_DISTANCE = 30
local ANIMATION_SMOOTHNESS = 0.08
local CASCADE_DELAY = 0.1

local MOVEMENT_PATTERN = {
	["Pillar1"] = -3, ["Pillar2"] = 3, ["Pillar3"] = 3,
	["Pillar4"] = -3, ["Pillar5"] = -3, ["Pillar6"] = 3
}

local allGatePillars = {}
local pillarsFolder = nil

local function setupExistingPillars()
	if not pillarsFolder then return end
	
	local children = pillarsFolder:GetChildren()
	if #children == 0 then return end
	
	table.sort(children, function(a, b) return a.Name < b.Name end)

	for i, pillar in ipairs(children) do
		if pillar:IsA("BasePart") and MOVEMENT_PATTERN[pillar.Name] then
			pillar.Anchored = true
			
			table.insert(allGatePillars, {
				instance = pillar,
				originalPosition = pillar.Position,
				moveDirection = MOVEMENT_PATTERN[pillar.Name],
				moveDistance = pillar.Size.Y,
				activationTime = -1
			})
		end
	end
end

local function updateGate()
	if #allGatePillars == 0 then return end

	local closestPlayer = nil
	local minDistance = TRIGGER_DISTANCE + 20

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local rootPart = player.Character.HumanoidRootPart
			local dist = (rootPart.Position - allGatePillars[1].instance.Position).Magnitude
			if dist < minDistance then
				minDistance = dist
				closestPlayer = rootPart
			end
		end
	end

	if closestPlayer then
		for i, pillarData in ipairs(allGatePillars) do
			if pillarData.activationTime == -1 then
				if i == 1 then
					pillarData.activationTime = tick()
				else
					local prevPillarData = allGatePillars[i-1]
					if prevPillarData.activationTime > 0 and (tick() - prevPillarData.activationTime) > CASCADE_DELAY then
						pillarData.activationTime = tick()
					end
				end
			end
		end
	else
		for _, pillarData in ipairs(allGatePillars) do
			pillarData.activationTime = -1
		end
	end

	for _, pillarData in ipairs(allGatePillars) do
		local pillar = pillarData.instance
		local originalPos = pillarData.originalPosition
		
		local openAlpha = 0
		if pillarData.activationTime > 0 and closestPlayer then
			local distanceToPillar = (closestPlayer.Position - pillar.Position).Magnitude
			
			if distanceToPillar < TRIGGER_DISTANCE then
				openAlpha = 1 - (distanceToPillar / TRIGGER_DISTANCE)
				openAlpha = math.clamp(openAlpha, 0, 1)
			end
		end

		local moveOffset = openAlpha * pillarData.moveDistance * pillarData.moveDirection
		local targetPosition = originalPos + Vector3.new(0, moveOffset, 0)

		pillar.Position = pillar.Position:Lerp(targetPosition, ANIMATION_SMOOTHNESS)
	end
end

pillarsFolder = workspace:WaitForChild(PILLARS_FOLDER_NAME, 30)

if pillarsFolder then
	setupExistingPillars()
	RunService.Heartbeat:Connect(updateGate)
else
	error("A pasta '" .. PILLARS_FOLDER_NAME .. "' não foi encontrada no Workspace.")
end
