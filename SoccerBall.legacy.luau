local SoccerBall = script.Parent
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Find or wait for your RemoteEvent
local SoccerRespawnedEvent = ReplicatedStorage.ServerMods.Event:FindFirstChild("SoccerRespawnedEvent")
local DataStoreService = game:GetService("DataStoreService")
local GoalsOrdered = DataStoreService:GetOrderedDataStore("GlobalGoals") -- Global leaderboard

if not SoccerRespawnedEvent then
	warn("Soccer remote event 'SoccerRespawnedEvent' was not found in ReplicatedStorage.ServerMods.Event")
end

-- 1. TRACK THE KICKS
SoccerBall.Touched:Connect(function(hit)
	if SoccerBall:GetAttribute("Destroying") == true then return end --Prevents players from claiming due to delay destroying just for the Fire.
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if humanoid then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			-- Just update the attribute. Clean and simple.
			SoccerBall:SetAttribute("LastKickedBy", player.Name)
		end
	end
end)

-- 2. HANDLE THE RESPAWN SIGNAL (Runs exactly once when the ball is destroyed)
SoccerBall:GetAttributeChangedSignal("Destroying"):Connect(function()
	if SoccerBall:GetAttribute("Destroying") then
		task.wait(0.05)
		local Player = Players:FindFirstChild(SoccerBall:GetAttribute("LastKickedBy"))
		local Reason = SoccerBall:GetAttribute("DestroyingReason") or "Unknown"


		if Player then
			--give global leader board point to player
			--not leaderstats
			SoccerRespawnedEvent:FireClient(Player, Reason)
			
			if SoccerBall:GetAttribute("DestroyingReason") == "Goal" then
				local success, err = pcall(function()
					GoalsOrdered:IncrementAsync(Player.UserId, 1)
				end)

				if not success then
					warn("Failed to update global leaderboard for " .. Player.Name .. ": " .. err)
					--Reason likely left the game, or something else went wrong.
				end
			end
		else
			warn("Player not found in LastKickedBy: '" .. SoccerBall:GetAttribute("LastKickedBy"), "' Likely fled from the server.")
		end
	end
end)