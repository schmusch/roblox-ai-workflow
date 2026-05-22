--!strict
-- Platziert in: src/client/BeliefViewController.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Hilfsfunktion: Formatiert Zahlen mit Tausendertrennzeichen (z.B. 2,000)
local function formatNumber(n: number): string
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

-- Erstelle die UI-Elemente dynamisch
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CitadelBeliefGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Hauptcontainer (Glassmorphic Premium Frame)
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 220, 0, 70)
mainFrame.Position = UDim2.new(1, -20, 0, 20)
mainFrame.AnchorPoint = Vector2.new(1, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
mainFrame.BackgroundTransparency = 0.25
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = mainFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(50, 53, 65)
stroke.Thickness = 1.2
stroke.Parent = mainFrame

-- Plastischer Verlauf
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 20, 26)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 27, 35))
})
gradient.Rotation = 45
gradient.Parent = mainFrame

-- Icon (✨)
local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "IconLabel"
iconLabel.Size = UDim2.new(0, 40, 0, 40)
iconLabel.Position = UDim2.new(0, 15, 0.5, 0)
iconLabel.AnchorPoint = Vector2.new(0, 0.5)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "✨"
iconLabel.TextSize = 24
iconLabel.Parent = mainFrame

-- Belief-Zahl
local amountLabel = Instance.new("TextLabel")
amountLabel.Name = "AmountLabel"
amountLabel.Size = UDim2.new(1, -75, 0, 30)
amountLabel.Position = UDim2.new(0, 60, 0, 12)
amountLabel.BackgroundTransparency = 1
amountLabel.Text = "0"
amountLabel.TextSize = 26
amountLabel.Font = Enum.Font.BuilderSansBold
amountLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
amountLabel.TextXAlignment = Enum.TextXAlignment.Left
amountLabel.Parent = mainFrame

-- Einkommensrate (+X/s)
local rateLabel = Instance.new("TextLabel")
rateLabel.Name = "RateLabel"
rateLabel.Size = UDim2.new(1, -75, 0, 16)
rateLabel.Position = UDim2.new(0, 60, 0, 42)
rateLabel.BackgroundTransparency = 1
rateLabel.Text = "+0/s"
rateLabel.TextSize = 13
rateLabel.Font = Enum.Font.BuilderSansMedium
rateLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
rateLabel.TextXAlignment = Enum.TextXAlignment.Left
rateLabel.Parent = mainFrame

screenGui.Parent = playerGui

-- Zustandsvariablen für das UI
local lastBelief = 0
local initialLoad = true

-- Update-Funktion für den Glaubensstand
local function updateBelief(currentBelief: number)
	amountLabel.Text = formatNumber(currentBelief)
	
	if initialLoad then
		lastBelief = currentBelief
		initialLoad = false
		return
	end
	
	local diff = currentBelief - lastBelief
	if diff == 0 then return end
	
	-- Stop laufende Tweens
	TweenService:Create(amountLabel, TweenInfo.new(0.05), {
		TextColor3 = Color3.fromRGB(255, 255, 255),
		TextSize = 26,
		Position = UDim2.new(0, 60, 0, 12)
	}):Play()
	
	if diff > 0 then
		-- Haptischer Zuwachs-Puls (Grün leuchtend)
		amountLabel.TextColor3 = Color3.fromRGB(80, 255, 120)
		amountLabel.TextSize = 31 -- Puls-Größe +15%
		
		-- Sanft zurück-tweenen
		local tween = TweenService:Create(amountLabel, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 26
		})
		tween:Play()
	else
		-- Haptischer Abbuchungs-Zuck-Schmerz (Rot leuchtend & Shake)
		amountLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
		amountLabel.TextSize = 23 -- Schrumpf-Größe -10%
		amountLabel.Position = UDim2.new(0, 52, 0, 12) -- Leicht nach links versetzt
		
		-- Zuck-Tween zurück in Original-Position und -Farbe
		local tween = TweenService:Create(amountLabel, TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 26,
			Position = UDim2.new(0, 60, 0, 12)
		})
		tween:Play()
	end
	
	lastBelief = currentBelief
end

-- Update-Funktion für das passive Einkommen
local function updateRate(currentRate: number)
	rateLabel.Text = "+" .. tostring(math.floor(currentRate)) .. "/s"
	
	-- Rate-Puls-Effekt zur visuellen Zufriedenstellung
	if currentRate > 0 then
		rateLabel.TextColor3 = Color3.fromRGB(130, 255, 130)
		TweenService:Create(rateLabel, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextColor3 = Color3.fromRGB(100, 220, 100)
		}):Play()
	else
		rateLabel.TextColor3 = Color3.fromRGB(150, 150, 160)
	end
end

-- Auf Attribut-Änderungen auf dem Spieler-Objekt lauschen
player:GetAttributeChangedSignal("CitadelBelief"):Connect(function()
	local val = player:GetAttribute("CitadelBelief")
	if typeof(val) == "number" then
		updateBelief(val)
	end
end)

player:GetAttributeChangedSignal("CitadelBeliefRate"):Connect(function()
	local val = player:GetAttribute("CitadelBeliefRate")
	if typeof(val) == "number" then
		updateRate(val)
	end
end)

-- Initialen Zustand auslesen
local initBelief = player:GetAttribute("CitadelBelief")
if typeof(initBelief) == "number" then
	updateBelief(initBelief)
else
	-- Fallback, falls Attribut noch nicht repliziert wurde
	updateBelief(2000)
end

local initRate = player:GetAttribute("CitadelBeliefRate")
if typeof(initRate) == "number" then
	updateRate(initRate)
else
	updateRate(0)
end

print("[BeliefViewController] Initialisiert und dynamisch geladen. Replikation aktiv.")
