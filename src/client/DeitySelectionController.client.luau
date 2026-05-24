--!strict
-- Platziert in: src/client/DeitySelectionController.client.luau
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local GridConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GridConfig") :: ModuleScript)
local Events = ReplicatedStorage:WaitForChild("Events") :: Folder
local activatePlacementEvent = Events:WaitForChild("ActivatePlacement") :: BindableEvent

-- Preis-Katalog (muss mit dem Server übereinstimmen)
local DEITY_PRICES: { [string]: number } = {
	["old_forest_spirit"] = 500,
	["sun_temple"] = 1200,
	["water_shrine"] = 300,
}

-- Erstelle die UI-Elemente dynamisch
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CitadelDeitySelectionGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true

-- Haupt-Deck (Glassmorphic Premium Frame)
local mainDeck = Instance.new("Frame")
mainDeck.Name = "MainDeck"
mainDeck.Size = UDim2.new(0, 520, 0, 110)
mainDeck.Position = UDim2.new(0.5, 0, 1, -15)
mainDeck.AnchorPoint = Vector2.new(0.5, 1)
mainDeck.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
mainDeck.BackgroundTransparency = 0.25
mainDeck.BorderSizePixel = 0
mainDeck.ClipsDescendants = true
mainDeck.Parent = screenGui

local deckCorner = Instance.new("UICorner")
deckCorner.CornerRadius = UDim.new(0, 12)
deckCorner.Parent = mainDeck

local deckStroke = Instance.new("UIStroke")
deckStroke.Color = Color3.fromRGB(50, 53, 65)
deckStroke.Thickness = 1.2
deckStroke.Parent = mainDeck

local deckGradient = Instance.new("UIGradient")
deckGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 20, 26)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 27, 35))
})
deckGradient.Rotation = 45
deckGradient.Parent = mainDeck

-- List-Layout für die Gottheiten-Karten
local listLayout = Instance.new("UIListLayout")
listLayout.FillDirection = Enum.FillDirection.Horizontal
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
listLayout.Padding = UDim.new(0, 15)
listLayout.Parent = mainDeck

-- Minimieren-Button (Edler Knopf direkt über dem Deck)
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 45, 0, 22)
minimizeBtn.Position = UDim2.new(0.5, 0, 1, -125)
minimizeBtn.AnchorPoint = Vector2.new(0.5, 1)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(15, 17, 22)
minimizeBtn.BackgroundTransparency = 0.25
minimizeBtn.BorderSizePixel = 0
minimizeBtn.Text = "▼"
minimizeBtn.TextSize = 11
minimizeBtn.Font = Enum.Font.BuilderSansBold
minimizeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
minimizeBtn.Parent = screenGui

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 6)
minCorner.Parent = minimizeBtn

local minStroke = Instance.new("UIStroke")
minStroke.Color = Color3.fromRGB(50, 53, 65)
minStroke.Thickness = 1
minStroke.Parent = minimizeBtn

-- Karten-Referenzen für Live-Validierung
local cards: { [string]: {
	Button: TextButton,
	Stroke: UIStroke,
	Title: TextLabel,
	Stats: TextLabel,
	Cost: TextLabel,
	Stock: TextLabel,
	DeityId: string,
	Price: number
} } = {}

-- Erstelle die Karten für alle Gottheiten
for deityId, profile in pairs(GridConfig.DeityProfiles) do
	local price = DEITY_PRICES[deityId] or 0
	
	local card = Instance.new("TextButton")
	card.Name = "Card_" .. deityId
	card.Size = UDim2.new(0, 145, 0, 85)
	card.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Text = ""
	card.AutoButtonColor = false
	card.Parent = mainDeck

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 8)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(45, 48, 58)
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	-- Anzeigename
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -20, 0, 16)
	titleLabel.Position = UDim2.new(0, 10, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = profile.DisplayName or deityId
	titleLabel.TextSize = 13
	titleLabel.Font = Enum.Font.BuilderSansBold
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = card

	-- Stats (Breite x Länge • +Generierung)
	local statsLabel = Instance.new("TextLabel")
	statsLabel.Name = "StatsLabel"
	statsLabel.Size = UDim2.new(1, -20, 0, 14)
	statsLabel.Position = UDim2.new(0, 10, 0, 28)
	statsLabel.BackgroundTransparency = 1
	statsLabel.Text = string.format("%dx%d  •  +%d/s ✨", profile.Width, profile.Length, profile.BeliefPerSecond)
	statsLabel.TextSize = 9.5
	statsLabel.Font = Enum.Font.BuilderSansMedium
	statsLabel.TextColor3 = Color3.fromRGB(150, 150, 170)
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.Parent = card

	-- Baukosten (✨)
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(0.6, -10, 0, 20)
	costLabel.Position = UDim2.new(0, 10, 1, -28)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = string.format("%d ✨", price)
	costLabel.TextSize = 12
	costLabel.Font = Enum.Font.BuilderSansBold
	costLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
	costLabel.TextXAlignment = Enum.TextXAlignment.Left
	costLabel.Parent = card

	-- Bestand im Inventar
	local stockLabel = Instance.new("TextLabel")
	stockLabel.Name = "StockLabel"
	stockLabel.Size = UDim2.new(0.4, -10, 0, 20)
	stockLabel.Position = UDim2.new(0.6, 0, 1, -28)
	stockLabel.BackgroundTransparency = 1
	stockLabel.Text = "x0"
	stockLabel.TextSize = 11
	stockLabel.Font = Enum.Font.BuilderSansBold
	stockLabel.TextColor3 = Color3.fromRGB(100, 220, 100)
	stockLabel.TextXAlignment = Enum.TextXAlignment.Right
	stockLabel.Parent = card

	-- Hover- und Klickanimationen
	card.MouseEnter:Connect(function()
		if not card.Active then return end
		TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(100, 100, 120) }):Play()
	end)

	card.MouseLeave:Connect(function()
		if not card.Active then return end
		TweenService:Create(card, TweenInfo.new(0.2), { BackgroundTransparency = 0.2 }):Play()
		TweenService:Create(cardStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(45, 48, 58) }):Play()
	end)

	card.MouseButton1Click:Connect(function()
		if not card.Active then return end
		
		-- Starte Platzierung über das BindableEvent
		activatePlacementEvent:Fire(deityId)
		
		-- Sanfte Klick-Rückmeldung
		card.Size = UDim2.new(0, 141, 0, 81)
		task.delay(0.05, function()
			card.Size = UDim2.new(0, 145, 0, 85)
		end)
	end)

	-- Registriere Karte für die Live-Validierung
	cards[deityId] = {
		Button = card,
		Stroke = cardStroke,
		Title = titleLabel,
		Stats = statsLabel,
		Cost = costLabel,
		Stock = stockLabel,
		DeityId = deityId,
		Price = price
	}
end

-- Live-Validierungs-Funktion
local function validateDeityButtons()
	local belief = player:GetAttribute("CitadelBelief") or 0
	local rawInventory = player:GetAttribute("CitadelInventory") or "{}"
	local inventory = {}
	
	pcall(function()
		inventory = HttpService:JSONDecode(rawInventory)
	end)

	for deityId, item in pairs(cards) do
		local stock = inventory[deityId] or 0
		item.Stock.Text = "x" .. tostring(stock)

		local hasStock = stock > 0
		local canAfford = belief >= item.Price

		if not hasStock then
			-- Ausgrauen: Kein Bestand im Inventar
			item.Button.Active = false
			item.Button.BackgroundTransparency = 0.6
			item.Stroke.Color = Color3.fromRGB(35, 38, 48)
			item.Title.TextColor3 = Color3.fromRGB(100, 100, 110)
			item.Stats.TextColor3 = Color3.fromRGB(80, 80, 90)
			item.Cost.TextColor3 = Color3.fromRGB(200, 75, 75)
			item.Cost.Text = "Kein Bestand"
			item.Stock.TextColor3 = Color3.fromRGB(200, 75, 75)
		elseif not canAfford then
			-- Ausgrauen: Zu teuer
			item.Button.Active = false
			item.Button.BackgroundTransparency = 0.6
			item.Stroke.Color = Color3.fromRGB(35, 38, 48)
			item.Title.TextColor3 = Color3.fromRGB(100, 100, 110)
			item.Stats.TextColor3 = Color3.fromRGB(80, 80, 90)
			item.Cost.TextColor3 = Color3.fromRGB(200, 75, 75)
			item.Cost.Text = string.format("Benötigt %d ✨", item.Price)
			item.Stock.TextColor3 = Color3.fromRGB(100, 150, 100)
		else
			-- Aktivieren
			item.Button.Active = true
			item.Button.BackgroundTransparency = 0.2
			item.Stroke.Color = Color3.fromRGB(45, 48, 58)
			item.Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			item.Stats.TextColor3 = Color3.fromRGB(150, 150, 170)
			item.Cost.TextColor3 = Color3.fromRGB(255, 200, 80)
			item.Cost.Text = string.format("%d ✨", item.Price)
			item.Stock.TextColor3 = Color3.fromRGB(100, 220, 100)
		end
	end
end

-- Auf Attribut-Änderungen lauschen
player:GetAttributeChangedSignal("CitadelBelief"):Connect(validateDeityButtons)
player:GetAttributeChangedSignal("CitadelInventory"):Connect(validateDeityButtons)

-- Initial ausführen
validateDeityButtons()

screenGui.Parent = playerGui

-- Minimieren / Maximieren Logik
local isMinimized = false

minimizeBtn.MouseEnter:Connect(function()
	TweenService:Create(minimizeBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.1, TextColor3 = Color3.fromRGB(255, 255, 255) }):Play()
	TweenService:Create(minStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(100, 100, 120) }):Play()
end)

minimizeBtn.MouseLeave:Connect(function()
	TweenService:Create(minimizeBtn, TweenInfo.new(0.2), { BackgroundTransparency = 0.25, TextColor3 = Color3.fromRGB(180, 180, 200) }):Play()
	TweenService:Create(minStroke, TweenInfo.new(0.2), { Color = Color3.fromRGB(50, 53, 65) }):Play()
end)

minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	
	if isMinimized then
		-- Herunterfahren
		TweenService:Create(mainDeck, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1, 95)
		}):Play()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1, -15)
		}):Play()
		minimizeBtn.Text = "▲"
	else
		-- Hochfahren
		TweenService:Create(mainDeck, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1, -15)
		}):Play()
		TweenService:Create(minimizeBtn, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 1, -125)
		}):Play()
		minimizeBtn.Text = "▼"
	end
end)

print("[DeitySelectionController] Baumenü (Deity Selection UI) erfolgreich geladen.")
