local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local espObjects = {}

local SETTINGS = {
    MaxDistance = 2000,
    RealHeight = 5.2,
    RealWidth = 3.0,
    BaseDistance = 25,
    BasePixelHeight = 85,
    BoxThickness = 1.8,
    BoxColor = Color3.fromRGB(0, 255, 0),
    HealthGreenColor = Color3.fromRGB(0, 255, 0),
    HealthRedColor = Color3.fromRGB(255, 0, 0),
    HealthBarThickness = 3,
    HealthBarOffset = 4,
    TracerColor = Color3.fromRGB(0, 255, 0),
    TracerThickness = 1.2,
    NameColor = Color3.fromRGB(255, 255, 255),
    NameSize = 13,
    NameOutline = true,
    NameOutlineColor = Color3.fromRGB(0, 0, 0)
}

local function getScreenSize(distance)
    local scale = SETTINGS.BaseDistance / math.max(distance, 0.5)
    local heightPx = SETTINGS.BasePixelHeight * scale
    heightPx = math.clamp(heightPx, 20, 250)
    local widthPx = heightPx * (SETTINGS.RealWidth / SETTINGS.RealHeight)
    return widthPx, heightPx
end

local function hideOriginalName(player)
    local character = player.Character
    if not character then return end
    local head = character:FindFirstChild("Head")
    if head then
        local nameDisplay = head:FindFirstChild("NameDisplay")
        if nameDisplay and nameDisplay:IsA("BillboardGui") then
            nameDisplay.Enabled = false
        end
    end
end

local function createESP(player)
    if player == LocalPlayer or espObjects[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = SETTINGS.BoxThickness
    box.Color = SETTINGS.BoxColor
    box.Filled = false
    box.Visible = false
    
    local healthGreen = Drawing.new("Line")
    healthGreen.Thickness = SETTINGS.HealthBarThickness
    healthGreen.Color = SETTINGS.HealthGreenColor
    healthGreen.Visible = false
    
    local healthRed = Drawing.new("Line")
    healthRed.Thickness = SETTINGS.HealthBarThickness
    healthRed.Color = SETTINGS.HealthRedColor
    healthRed.Visible = false
    
    local tracer = Drawing.new("Line")
    tracer.Thickness = SETTINGS.TracerThickness
    tracer.Color = SETTINGS.TracerColor
    tracer.Visible = false
    
    local nameLabel = Drawing.new("Text")
    nameLabel.Size = SETTINGS.NameSize
    nameLabel.Center = true
    nameLabel.Color = SETTINGS.NameColor
    nameLabel.Outline = SETTINGS.NameOutline
    nameLabel.OutlineColor = SETTINGS.NameOutlineColor
    nameLabel.Visible = false
    
    espObjects[player] = {
        box = box,
        healthGreen = healthGreen,
        healthRed = healthRed,
        tracer = tracer,
        nameLabel = nameLabel
    }
    
    local function onCharacterAdded(character)
        task.wait()
        hideOriginalName(player)
    end
    
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
end

local function removeESP(player)
    local data = espObjects[player]
    if data then
        data.box:Remove()
        data.healthGreen:Remove()
        data.healthRed:Remove()
        data.tracer:Remove()
        data.nameLabel:Remove()
        espObjects[player] = nil
    end
end

local function updateESP(player)
    local data = espObjects[player]
    if not data then return end
    
    data.box.Visible = false
    data.healthGreen.Visible = false
    data.healthRed.Visible = false
    data.tracer.Visible = false
    data.nameLabel.Visible = false
    
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not character or not humanoid or not rootPart or humanoid.Health <= 0 then
        return
    end
    
    local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
    if distance > SETTINGS.MaxDistance then
        return
    end
    
    local screenCenter, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
    if not onScreen or screenCenter.Z <= 0 then
        return
    end
    
    local widthPx, heightPx = getScreenSize(distance)
    local boxX = screenCenter.X - widthPx / 2
    local boxY = screenCenter.Y - heightPx / 2
    
    data.box.Position = Vector2.new(boxX, boxY)
    data.box.Size = Vector2.new(widthPx, heightPx)
    data.box.Visible = true
    
    local barX = boxX - SETTINGS.HealthBarThickness - SETTINGS.HealthBarOffset
    local barTopY = boxY
    local barBottomY = boxY + heightPx
    local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    
    local greenStartY = barBottomY
    local greenEndY = barBottomY - heightPx * healthPercent
    
    data.healthGreen.From = Vector2.new(barX, greenStartY)
    data.healthGreen.To = Vector2.new(barX, greenEndY)
    data.healthGreen.Visible = true
    
    data.healthRed.From = Vector2.new(barX, barTopY)
    data.healthRed.To = Vector2.new(barX, greenEndY)
    data.healthRed.Visible = true
    
    local screenCenterBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    local targetPoint = Vector2.new(screenCenter.X, boxY + heightPx)
    data.tracer.From = screenCenterBottom
    data.tracer.To = targetPoint
    data.tracer.Visible = true
    
    data.nameLabel.Position = Vector2.new(screenCenter.X, boxY - SETTINGS.NameSize - 3)
    data.nameLabel.Text = player.Name
    data.nameLabel.Visible = true
end

local function setup()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
    
    Players.PlayerAdded:Connect(function(player)
        if player ~= LocalPlayer then
            createESP(player)
        end
    end)
    
    Players.PlayerRemoving:Connect(removeESP)
    
    RunService.RenderStepped:Connect(function()
        for player, _ in pairs(espObjects) do
            if player and player.Parent then
                updateESP(player)
            else
                removeESP(player)
            end
        end
    end)
end

setup()