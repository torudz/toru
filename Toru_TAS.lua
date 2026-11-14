-- ══════════════════════════════════════════════════════════
-- AUTO FARM HUB - FLUENT UI EDITION (RESPONSIVE + FLOATING UI)
-- ══════════════════════════════════════════════════════════

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local PathfindingService = game:GetService("PathfindingService")
local VIM = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
playerGui:WaitForChild("HudLancer", 30)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestRemote = Remotes:WaitForChild("Request")

local okCS, ClientState = pcall(function()
    return require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ClientState", 10))
end)

local okBal, Balance = pcall(function()
    return require(ReplicatedStorage:WaitForChild("Balance", 10))
end)

-- ══════════════════════════════════════════════════════════
-- ANTI-AFK (CHỐNG VĂNG GAME KHI TREO)
-- ══════════════════════════════════════════════════════════
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    task.wait(1)
    vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
end)

-- ══════════════════════════════════════════════════════════
-- CẤU HÌNH & LƯU TRỮ TRẠNG THÁI (JSON + GETGENV)
-- ══════════════════════════════════════════════════════════
local DEFAULT_SCRIPT_URL = "https://raw.githubusercontent.com/torudz/throw-a-seed/refs/heads/main/throw-a-seed.luau"
local configFile = "AutoFarmHub_Fluent_Config.json"

local DefaultSettings = {
    AutoThrow = false,
    AutoTrain = false,
    LoopEnabled = false,
    ThrowMinutes = 5,
    TrainMinutes = 5,
    AutoPlaceBest = false,
    AutoUpgrade = false,
    AutoUpgradeBar = false,
    AutoBuyBestSeed = false,
    MaxSeedIndex = 20,
    AutoX2 = false,
    AutoRewards = false,
    AutoRejoin = false,
    AutoExecEnabled = true,
    ScriptURL = DEFAULT_SCRIPT_URL
}

local Settings = {}
for k, v in pairs(DefaultSettings) do
    Settings[k] = v
end

local function loadSettings()
    if isfile and readfile and isfile(configFile) then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                if Settings[k] ~= nil and type(v) == type(Settings[k]) then
                    Settings[k] = v
                end
            end
        end
    end
    if not Settings.ScriptURL or Settings.ScriptURL == "" then
        Settings.ScriptURL = DEFAULT_SCRIPT_URL
    end
    if type(getgenv().TeleportFarmConfig) == "table" then
        for k, v in pairs(getgenv().TeleportFarmConfig) do
            if Settings[k] ~= nil then
                Settings[k] = v
            end
        end
    end
end

local function saveSettings()
    if writefile then
        pcall(function()
            writefile(configFile, HttpService:JSONEncode(Settings))
        end)
    end
end

loadSettings()

if Settings.LoopEnabled then
    Settings.AutoThrow = false
    Settings.AutoTrain = false
elseif Settings.AutoThrow and Settings.AutoTrain then
    Settings.AutoThrow = false
end
saveSettings()

for k, v in pairs(Settings) do
    getgenv()[k] = v
end

-- ══════════════════════════════════════════════════════════
-- TỰ ĐỘNG TÍNH TỈ LỆ MÀN HÌNH (RESPONSIVE SCALING)
-- ══════════════════════════════════════════════════════════
local Camera = workspace.CurrentCamera
local Viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local winWidth = IsMobile and math.clamp(math.floor(Viewport.X * 0.68), 380, 500) or 530
local winHeight = IsMobile and math.clamp(math.floor(Viewport.Y * 0.72), 280, 420) or 460
local tabWidth = IsMobile and 115 or 140

-- ══════════════════════════════════════════════════════════
-- KHỞI TẠO FLUENT UI
-- ══════════════════════════════════════════════════════════
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Auto Farm Hub",
    SubTitle = "Fluent Smart Edition",
    TabWidth = tabWidth,
    Size = UDim2.fromOffset(winWidth, winHeight),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Farm & Loop", Icon = "repeat" }),
    Upgrade = Window:AddTab({ Title = "Shop & Nâng Cấp", Icon = "shopping-cart" }),
    Misc = Window:AddTab({ Title = "Tiện Ích & Quà", Icon = "gift" }),
    System = Window:AddTab({ Title = "Rejoin & Auto Exec", Icon = "settings" })
}

local Options = Fluent.Options
local ScriptRunning = true

-- ══════════════════════════════════════════════════════════
-- NÚT BẬT/TẮT NỔI BÊN NGOÀI MÀN HÌNH (KÉO THẢ TỰ DO)
-- ══════════════════════════════════════════════════════════
local guiParent = (gethui and gethui()) or CoreGui or playerGui
if guiParent:FindFirstChild("AutoFarmHub_FloatingBtn") then
    guiParent:FindFirstChild("AutoFarmHub_FloatingBtn"):Destroy()
end

local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "AutoFarmHub_FloatingBtn"
ToggleGui.ResetOnSpawn = false
ToggleGui.IgnoreGuiInset = true
ToggleGui.DisplayOrder = 100
ToggleGui.Parent = guiParent

local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "ToggleMenuBtn"
FloatBtn.Size = IsMobile and UDim2.fromOffset(46, 46) or UDim2.fromOffset(44, 44)
FloatBtn.Position = UDim2.new(0, 14, 0.42, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
FloatBtn.Text = "HUB"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.Font = Enum.Font.GothamBold
FloatBtn.TextSize = 13
FloatBtn.AutoButtonColor = false
FloatBtn.Active = true
FloatBtn.Parent = ToggleGui

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(1, 0)
BtnCorner.Parent = FloatBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color = Color3.fromRGB(88, 166, 255)
BtnStroke.Thickness = 2
BtnStroke.Parent = FloatBtn

-- Hỗ trợ kéo thả mượt mà trên cả Mobile & PC, phân biệt kéo vs bấm
local draggingBtn = false
local movedBtn = false
local dragStartPos, btnStartPos

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingBtn = true
        movedBtn = false
        dragStartPos = input.Position
        btnStartPos = FloatBtn.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                draggingBtn = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingBtn and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        if delta.Magnitude > 6 then
            movedBtn = true
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            local newX = math.clamp(btnStartPos.X.Offset + delta.X, 6, vp.X - FloatBtn.AbsoluteSize.X - 6)
            local newY = math.clamp(btnStartPos.Y.Offset + delta.Y, 6, vp.Y - FloatBtn.AbsoluteSize.Y - 6)
            FloatBtn.Position = UDim2.new(btnStartPos.X.Scale, newX, btnStartPos.Y.Scale, newY)
        end
    end
end)

FloatBtn.MouseButton1Click:Connect(function()
    if movedBtn then return end
    if Window and Window.Minimize then
        Window:Minimize()
    else
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
            task.wait(0.03)
            VIM:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
        end)
    end
end)

-- Tự động cập nhật lại kích thước & vị trí nút nếu xoay ngang/dọc màn hình
if Camera then
    Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        local vp = Camera.ViewportSize
        if IsMobile and Window and Window.Root then
            local newW = math.clamp(math.floor(vp.X * 0.68), 380, 500)
            local newH = math.clamp(math.floor(vp.Y * 0.72), 280, 420)
            pcall(function()
                Window.Root.Size = UDim2.fromOffset(newW, newH)
            end)
        end
        local curX = math.clamp(FloatBtn.Position.X.Offset, 6, math.max(10, vp.X - FloatBtn.AbsoluteSize.X - 6))
        local curY = math.clamp(FloatBtn.Position.Y.Offset, 6, math.max(10, vp.Y - FloatBtn.AbsoluteSize.Y - 6))
        FloatBtn.Position = UDim2.new(FloatBtn.Position.X.Scale, curX, FloatBtn.Position.Y.Scale, curY)
    end)
end

-- ══════════════════════════════════════════════════════════
-- BỘ PHÂN TÍCH TIỀN TỆ & ĐIỀU KIỆN THÔNG MINH
-- ══════════════════════════════════════════════════════════
local SuffixMultipliers = {
    k = 1e3, m = 1e6, b = 1e9, t = 1e12,
    qa = 1e15, qi = 1e18, sx = 1e21, sp = 1e24,
    oc = 1e27, no = 1e30, dc = 1e33, ud = 1e36, dd = 1e39
}

local function parseFormattedNumber(val)
    if type(val) == "number" then return val end
    if type(val) ~= "string" then return nil end

    local cleaned = val:gsub("[%$,%s]", ""):lower()
    local numPart, suffixPart = cleaned:match("^([%d%.]+)(%a*)$")
    local num = tonumber(numPart)
    if not num then return nil end

    if suffixPart and suffixPart ~= "" then
        local mult = SuffixMultipliers[suffixPart]
        if mult then
            return num * mult
        end
    end
    return num
end

local function getPlayerMoney()
    local moneyKeys = { "Cash", "Money", "Coins", "Gold", "Balance" }

    for _, key in ipairs(moneyKeys) do
        local attr = LocalPlayer:GetAttribute(key)
        local parsed = parseFormattedNumber(attr)
        if parsed then return parsed end
    end

    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, key in ipairs(moneyKeys) do
            local stat = leaderstats:FindFirstChild(key)
            if stat and stat:IsA("ValueBase") then
                local parsed = parseFormattedNumber(stat.Value)
                if parsed then return parsed end
            end
        end
    end

    if okCS and type(ClientState) == "table" then
        for _, key in ipairs(moneyKeys) do
            local val = ClientState[key] or ClientState[key:lower()]
            local parsed = parseFormattedNumber(val)
            if parsed then return parsed end
        end
    end

    return nil
end

-- ══════════════════════════════════════════════════════════
-- CÁC HÀM XỬ LÝ HÀNH ĐỘNG & DỪNG TRẠNG THÁI AN TOÀN
-- ══════════════════════════════════════════════════════════
local function fireGuiButton(btn)
    if not btn then return end
    pcall(function()
        if getconnections then
            for _, conn in ipairs(getconnections(btn.Activated)) do conn:Fire() end
            for _, conn in ipairs(getconnections(btn.MouseButton1Click)) do conn:Fire() end
        end
    end)
end

local function stopTrainingNow()
    local char = LocalPlayer.Character
    if char and char:GetAttribute("Training") then
        local hudTrain = playerGui:FindFirstChild("HudEntrainement")
        local barre = hudTrain and hudTrain:FindFirstChild("Barre")
        local stopBtn = barre and barre:FindFirstChild("Stop")
        if stopBtn then fireGuiButton(stopBtn) end
        if okCS and ClientState and ClientState.Request then
            pcall(function() ClientState.Request("StopTrain") end)
        end
    end
end

local function stopThrowingNow()
    local fx = playerGui:FindFirstChild("ThrowFX")
    local st = fx and fx:GetAttribute("State") or "idle"

    if st == "result" then
        local choiceGui = playerGui:FindFirstChild("ChoixApresLancer")
        local boutons = choiceGui and choiceGui:FindFirstChild("Boutons")
        local retourBtn = boutons and boutons:FindFirstChild("Retour")
        if retourBtn then
            fireGuiButton(retourBtn)
        else
            pcall(function()
                VIM:SendKeyEvent(true, Enum.KeyCode.Backspace, false, game)
                task.wait(0.05)
                VIM:SendKeyEvent(false, Enum.KeyCode.Backspace, false, game)
            end)
        end
    elseif st == "aiming" then
        pcall(function()
            VIM:SendKeyEvent(true, Enum.KeyCode.S, false, game)
            task.wait(0.08)
            VIM:SendKeyEvent(false, Enum.KeyCode.S, false, game)
        end)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Anchored then
            hrp.Anchored = false
            hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 14)
        end
    end
end

local function updateSetting(key, val)
    Settings[key] = val
    getgenv()[key] = val
    saveSettings()
end

local function getSeedProgressionInfo()
    local currentTier = tonumber(LocalPlayer:GetAttribute("SeedTier"))
        or tonumber(LocalPlayer:GetAttribute("Seed"))
        or tonumber(LocalPlayer:GetAttribute("SeedIndex"))
        or tonumber(LocalPlayer:GetAttribute("MaxSeed"))
        or 0

    local maxTier = Settings.MaxSeedIndex or 20
    if okBal and Balance and type(Balance.Seeds) == "table" and #Balance.Seeds > 0 then
        maxTier = math.min(maxTier, #Balance.Seeds)
    end
    return currentTier, maxTier
end

local function findBarUpgradePrompt()
    if okCS and ClientState and ClientState.MyPlot then
        local myPlot = ClientState.MyPlot()
        if myPlot then
            local barStation = myPlot:FindFirstChild("BarStation")
            local trainPad = barStation and barStation:FindFirstChild("TrainPad")
            local prompt = trainPad and trainPad:FindFirstChild("UpgradePrompt")
            if prompt and prompt:IsA("ProximityPrompt") then
                return prompt, trainPad
            end
        end
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local bestPrompt, bestPart, bestDist = nil, nil, math.huge

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ProximityPrompt") and desc.Name == "UpgradePrompt" and desc:FindFirstAncestor("BarStation") then
            local part = desc.Parent:IsA("BasePart") and desc.Parent or desc.Parent:FindFirstAncestorWhichIsA("BasePart")
            if part and hrp then
                local d = (part.Position - hrp.Position).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestPrompt = desc
                    bestPart = part
                end
            else
                bestPrompt = desc
                bestPart = part
            end
        end
    end
    return bestPrompt, bestPart
end

local function triggerBarUpgrade(forceIgnoreMode)
    if not forceIgnoreMode then
        if getgenv().AutoThrow or not getgenv().AutoTrain then
            return false, "Bỏ qua (Chỉ nâng khi đang Auto Train)"
        end
    end

    local prompt, part = findBarUpgradePrompt()
    if not prompt or not prompt.Enabled then
        return false, "Không tìm thấy hoặc đã nâng tối đa"
    end

    local requiredCost = parseFormattedNumber(prompt.ObjectText) or parseFormattedNumber(prompt.ActionText)
    local currentMoney = getPlayerMoney()
    if requiredCost and currentMoney and currentMoney < requiredCost then
        return false, string.format("Chưa đủ tiền (Cần: %s)", tostring(prompt.ObjectText))
    end

    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp and part then
        local dist = (hrp.Position - part.Position).Magnitude
        if dist > (prompt.MaxActivationDistance or 9) then
            return false, "Đứng quá xa khu tập luyện"
        end
    end

    pcall(function()
        if fireproximityprompt then
            fireproximityprompt(prompt)
        else
            prompt:InputHoldBegin()
            task.wait((prompt.HoldDuration or 0) + 0.1)
            prompt:InputHoldEnd()
        end
    end)
    return true, prompt.ActionText
end

-- ══════════════════════════════════════════════════════════
-- TAB 1: FARM & VÒNG LẶP THỜI GIAN (LOOP)
-- ══════════════════════════════════════════════════════════
local LoopStatus = Tabs.Main:AddParagraph({
    Title = "Trạng thái Vòng Lặp",
    Content = Settings.LoopEnabled and "Đang khởi động vòng lặp..." or "Đang tắt (Chạy thủ công từng chế độ bên dưới)"
})

local ThrowSlider = Tabs.Main:AddSlider("ThrowMinutes", {
    Title = "Thời gian Ném (Phút)",
    Description = "Số phút Auto Throw trong 1 vòng lặp",
    Default = Settings.ThrowMinutes,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Callback = function(Value)
        updateSetting("ThrowMinutes", Value)
    end
})

local TrainSlider = Tabs.Main:AddSlider("TrainMinutes", {
    Title = "Thời gian Tập Luyện (Phút)",
    Description = "Số phút Auto Train sau khi ném xong",
    Default = Settings.TrainMinutes,
    Min = 1,
    Max = 60,
    Rounding = 1,
    Callback = function(Value)
        updateSetting("TrainMinutes", Value)
    end
})

local LoopToggle = Tabs.Main:AddToggle("LoopEnabled", {
    Title = "Bật Vòng Lặp (Ném <-> Tập Luyện)",
    Description = "Tự động luân phiên giữa Ném và Tập luyện theo số phút đã chỉnh",
    Default = Settings.LoopEnabled
})

local ManualSection = Tabs.Main:AddSection("Chế Độ Đơn Lẻ (Tự tắt nếu bật Vòng Lặp)")

local ThrowToggle = Tabs.Main:AddToggle("AutoThrow", {
    Title = "Auto Throw (Chỉ Ném)",
    Default = Settings.AutoThrow
})

local TrainToggle = Tabs.Main:AddToggle("AutoTrain", {
    Title = "Auto Train (Chỉ Tập Luyện)",
    Default = Settings.AutoTrain
})

local ignoreCallback = false

LoopToggle:OnChanged(function()
    if ignoreCallback then return end
    local val = Options.LoopEnabled.Value
    updateSetting("LoopEnabled", val)
    if val then
        ignoreCallback = true
        ThrowToggle:SetValue(false)
        TrainToggle:SetValue(false)
        ignoreCallback = false
    else
        updateSetting("AutoThrow", false)
        updateSetting("AutoTrain", false)
        task.spawn(stopThrowingNow)
        task.spawn(stopTrainingNow)
        LoopStatus:SetDesc("Đã tắt vòng lặp.")
    end
end)

ThrowToggle:OnChanged(function()
    if ignoreCallback then return end
    local val = Options.AutoThrow.Value
    updateSetting("AutoThrow", val)
    if val then
        ignoreCallback = true
        if Options.LoopEnabled.Value then LoopToggle:SetValue(false) end
        if Options.AutoTrain.Value then TrainToggle:SetValue(false) end
        ignoreCallback = false
        updateSetting("LoopEnabled", false)
        updateSetting("AutoTrain", false)
        task.spawn(stopTrainingNow)
    else
        task.spawn(stopThrowingNow)
    end
end)

TrainToggle:OnChanged(function()
    if ignoreCallback then return end
    local val = Options.AutoTrain.Value
    updateSetting("AutoTrain", val)
    if val then
        ignoreCallback = true
        if Options.LoopEnabled.Value then LoopToggle:SetValue(false) end
        if Options.AutoThrow.Value then ThrowToggle:SetValue(false) end
        ignoreCallback = false
        updateSetting("LoopEnabled", false)
        updateSetting("AutoThrow", false)
        task.spawn(stopThrowingNow)
    else
        task.spawn(stopTrainingNow)
    end
end)

-- ══════════════════════════════════════════════════════════
-- TAB 2: SHOP & NÂNG CẤP THÔNG MINH
-- ══════════════════════════════════════════════════════════
local UpgradeStatus = Tabs.Upgrade:AddParagraph({
    Title = "Trạng thái Nâng Cấp Thông Minh",
    Content = "Sẵn sàng kiểm tra điều kiện tiền và trạng thái..."
})

local UpgradeToggle = Tabs.Upgrade:AddToggle("AutoUpgrade", {
    Title = "Auto Upgrade Capacity (Check Tiền)",
    Description = "Chỉ gọi BuyCapacity khi kiểm tra đủ tiền nâng sức chứa vườn",
    Default = Settings.AutoUpgrade
})
UpgradeToggle:OnChanged(function()
    updateSetting("AutoUpgrade", Options.AutoUpgrade.Value)
end)

local UpgradeBarToggle = Tabs.Upgrade:AddToggle("AutoUpgradeBar", {
    Title = "Auto Upgrade Thanh Tạ (Chỉ Khi Auto Train + Đủ Tiền)",
    Description = "Tự động bỏ qua khi đang Auto Throw; chỉ nâng khi đang Train và đủ tiền",
    Default = Settings.AutoUpgradeBar
})
UpgradeBarToggle:OnChanged(function()
    updateSetting("AutoUpgradeBar", Options.AutoUpgradeBar.Value)
end)

local SeedSection = Tabs.Upgrade:AddSection("Nâng Cấp Hạt Giống (Từ Thấp Lên Cao)")

local SeedStatus = Tabs.Upgrade:AddParagraph({
    Title = "Tiến độ Hạt Giống",
    Content = "Đang chờ bật..."
})

local MaxSeedSlider = Tabs.Upgrade:AddSlider("MaxSeedIndex", {
    Title = "Cấp Hạt Giống Mục Tiêu Tối Đa",
    Description = "Tự động nâng cấp tuần tự từ cấp 1 lên tới cấp này",
    Default = Settings.MaxSeedIndex,
    Min = 1,
    Max = 30,
    Rounding = 1,
    Callback = function(Value)
        updateSetting("MaxSeedIndex", Value)
    end
})

local BuySeedToggle = Tabs.Upgrade:AddToggle("AutoBuyBestSeed", {
    Title = "Auto Nâng Cấp Hạt Giống (Thấp -> Cao)",
    Description = "Kiểm tra đủ tiền trước khi mở khóa tuần tự từng cấp (1 -> Max)",
    Default = Settings.AutoBuyBestSeed
})
BuySeedToggle:OnChanged(function()
    local val = Options.AutoBuyBestSeed.Value
    updateSetting("AutoBuyBestSeed", val)
    if not val then
        SeedStatus:SetDesc("Đã tạm dừng nâng cấp hạt giống.")
    end
end)

Tabs.Upgrade:AddButton({
    Title = "Nâng Cấp Ngay 1 Lần (Thủ Công)",
    Description = "Thử nâng cấp sức chứa, thanh tạ và bậc hạt giống kế tiếp",
    Callback = function()
        pcall(function() RequestRemote:InvokeServer("BuyCapacity", {}) end)
        local _, barInfo = triggerBarUpgrade(true)
        Fluent:Notify({
            Title = "Kiểm Tra Thanh Tạ",
            Content = tostring(barInfo),
            Duration = 3
        })

        local curTier, maxTier = getSeedProgressionInfo()
        local startIdx = math.max(1, curTier + 1)

        for i = startIdx, maxTier do
            local ok, res = pcall(function()
                return RequestRemote:InvokeServer("BuySeed", { i = i })
            end)
            if ok and res == true then
                Fluent:Notify({
                    Title = "Nâng Cấp Hạt Giống",
                    Content = "Đã mở khóa hạt giống cấp #" .. tostring(i) .. "!",
                    Duration = 3
                })
                break
            end
        end
    end
})

-- ══════════════════════════════════════════════════════════
-- TAB 3: TIỆN ÍCH & NHẬN QUÀ
-- ══════════════════════════════════════════════════════════
local PlaceBestToggle = Tabs.Misc:AddToggle("AutoPlaceBest", {
    Title = "Auto Place Best",
    Description = "Tự động trang bị vật phẩm tốt nhất mỗi 2 giây",
    Default = Settings.AutoPlaceBest
})
PlaceBestToggle:OnChanged(function()
    updateSetting("AutoPlaceBest", Options.AutoPlaceBest.Value)
end)

local X2Toggle = Tabs.Misc:AddToggle("AutoX2", {
    Title = "Auto X2 XP",
    Description = "Tự động bấm nhận X2 XP khi xuất hiện",
    Default = Settings.AutoX2
})
X2Toggle:OnChanged(function()
    updateSetting("AutoX2", Options.AutoX2.Value)
end)

local RewardsToggle = Tabs.Misc:AddToggle("AutoRewards", {
    Title = "Auto Rewards (Quà Online & Điểm Danh)",
    Description = "Tự động nhận quà hằng ngày và quà theo thời gian online",
    Default = Settings.AutoRewards
})
RewardsToggle:OnChanged(function()
    updateSetting("AutoRewards", Options.AutoRewards.Value)
end)

-- ══════════════════════════════════════════════════════════
-- TAB 4: REJOIN & AUTO EXECUTE KHI CHUYỂN SERVER
-- ══════════════════════════════════════════════════════════
local queue_teleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)

local AutoRejoinToggle = Tabs.System:AddToggle("AutoRejoin", {
    Title = "Auto Rejoin Khi Nhận Hết Quà Online",
    Description = "Tự động vào lại server để reset chuỗi quà online",
    Default = Settings.AutoRejoin
})
AutoRejoinToggle:OnChanged(function()
    updateSetting("AutoRejoin", Options.AutoRejoin.Value)
end)

Tabs.System:AddSection("Auto Execute (Tự Chạy Lại Script Khi Rejoin / Teleport)")

local ScriptUrlInput = Tabs.System:AddInput("ScriptURL", {
    Title = "Link Raw Script (GitHub)",
    Description = "Đã gắn sẵn link GitHub Raw mặc định của bạn",
    Default = Settings.ScriptURL,
    Placeholder = DEFAULT_SCRIPT_URL,
    Numeric = false,
    Finished = true,
    Callback = function(Value)
        updateSetting("ScriptURL", Value ~= "" and Value or DEFAULT_SCRIPT_URL)
    end
})

local AutoExecToggle = Tabs.System:AddToggle("AutoExecEnabled", {
    Title = "Bật Auto Execute Khi Rejoin / Chuyển Server",
    Description = "Tự động đẩy script vào hàng đợi teleport của Executor",
    Default = Settings.AutoExecEnabled
})

local function QueueScriptForTeleport()
    if not queue_teleport then return false end
    local url = (Settings.ScriptURL and Settings.ScriptURL ~= "") and Settings.ScriptURL or DEFAULT_SCRIPT_URL

    local payload = string.format([[
        repeat task.wait() until game:IsLoaded()
        getgenv().TeleportFarmConfig = {
            AutoThrow = %s,
            AutoTrain = %s,
            LoopEnabled = %s,
            ThrowMinutes = %d,
            TrainMinutes = %d,
            AutoPlaceBest = %s,
            AutoUpgrade = %s,
            AutoUpgradeBar = %s,
            AutoBuyBestSeed = %s,
            MaxSeedIndex = %d,
            AutoX2 = %s,
            AutoRewards = %s,
            AutoRejoin = %s,
            AutoExecEnabled = true,
            ScriptURL = %q
        }
        local success, result = pcall(function()
            return game:HttpGet(%q)
        end)
        if success and result then
            local fn, err = loadstring(result)
            if fn then
                pcall(fn)
            else
                warn("Lỗi biên dịch script (Syntax Error):", err)
            end
        else
            warn("Không thể tải script từ GitHub (HTTP Error):", result)
        end
    ]],
        tostring(Settings.AutoThrow),
        tostring(Settings.AutoTrain),
        tostring(Settings.LoopEnabled),
        Settings.ThrowMinutes,
        Settings.TrainMinutes,
        tostring(Settings.AutoPlaceBest),
        tostring(Settings.AutoUpgrade),
        tostring(Settings.AutoUpgradeBar),
        tostring(Settings.AutoBuyBestSeed),
        Settings.MaxSeedIndex,
        tostring(Settings.AutoX2),
        tostring(Settings.AutoRewards),
        tostring(Settings.AutoRejoin),
        url,
        url
    )

    queue_teleport(payload)
    return true
end

AutoExecToggle:OnChanged(function()
    local val = Options.AutoExecEnabled.Value
    updateSetting("AutoExecEnabled", val)
    if val then
        if not queue_teleport then
            Fluent:Notify({
                Title = "Lỗi Executor",
                Content = "Executor của bạn không hỗ trợ queue_on_teleport!",
                Duration = 5
            })
        else
            QueueScriptForTeleport()
            Fluent:Notify({
                Title = "Auto Execute",
                Content = "Đã kích hoạt! Script sẽ tự chạy khi rejoin hoặc đổi server.",
                Duration = 4
            })
        end
    end
end)

LocalPlayer.OnTeleport:Connect(function(State)
    if Settings.AutoExecEnabled and State == Enum.TeleportState.Started then
        QueueScriptForTeleport()
    end
end)

Tabs.System:AddButton({
    Title = "Rejoin Server Ngay Lập Tức",
    Description = "Thoát và kết nối lại server hiện tại",
    Callback = function()
        if Settings.AutoExecEnabled then
            QueueScriptForTeleport()
        end
        if #Players:GetPlayers() <= 1 then
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end
})

-- ══════════════════════════════════════════════════════════
-- LUỒNG ĐIỀU KHIỂN VÒNG LẶP THỜI GIAN (LOOP CONTROLLER)
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while ScriptRunning do
        task.wait(0.5)
        if getgenv().LoopEnabled then
            getgenv().AutoTrain = false
            task.spawn(stopTrainingNow)
            task.wait(0.4)
            getgenv().AutoThrow = true

            local throwEnd = os.clock() + (Settings.ThrowMinutes * 60)
            while getgenv().LoopEnabled and os.clock() < throwEnd and ScriptRunning do
                local rem = math.max(0, math.ceil(throwEnd - os.clock()))
                local mins = math.floor(rem / 60)
                local secs = rem % 60
                LoopStatus:SetDesc(string.format("Đang NÉM (Auto Throw) | Còn lại: %02d:%02d", mins, secs))
                task.wait(0.5)
            end

            if not getgenv().LoopEnabled or not ScriptRunning then
                getgenv().AutoThrow = false
                task.spawn(stopThrowingNow)
                continue
            end

            getgenv().AutoThrow = false
            task.spawn(stopThrowingNow)
            task.wait(0.5)
            getgenv().AutoTrain = true

            local trainEnd = os.clock() + (Settings.TrainMinutes * 60)
            while getgenv().LoopEnabled and os.clock() < trainEnd and ScriptRunning do
                local rem = math.max(0, math.ceil(trainEnd - os.clock()))
                local mins = math.floor(rem / 60)
                local secs = rem % 60
                LoopStatus:SetDesc(string.format("Đang TẬP LUYỆN (Auto Train) | Còn lại: %02d:%02d", mins, secs))
                task.wait(0.5)
            end

            getgenv().AutoTrain = false
            task.spawn(stopTrainingNow)
            task.wait(0.4)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- CÁC HÀM HỖ TRỢ GAME (THROW & TRAIN)
-- ══════════════════════════════════════════════════════════
local function getThrowFX()
    return playerGui:FindFirstChild("ThrowFX")
end

local function getState()
    local fx = getThrowFX()
    return fx and fx:GetAttribute("State") or "idle"
end

local function getCurseur()
    local hud = playerGui:FindFirstChild("HudLancer")
    if not hud then return nil end
    local jauge = hud:FindFirstChild("Jauge")
    if not jauge then return nil end
    local capsule = jauge:FindFirstChild("Capsule")
    if not capsule then return nil end
    return capsule:FindFirstChild("Curseur")
end

local function isOnStrip()
    local Character = LocalPlayer.Character
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local strip = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Canyon")
        and workspace.Map.Canyon:FindFirstChild("LaunchStrip")
    if not strip then return false end

    local rel = strip.CFrame:PointToObjectSpace(hrp.Position)
    local half = strip.Size / 2
    return math.abs(rel.X) < half.X
        and math.abs(rel.Z) < half.Z
        and rel.Y > -2 and rel.Y < 8
end

local function walkToStrip()
    local Character = LocalPlayer.Character
    local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
    local hum = Character and Character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    local strip = workspace:FindFirstChild("Map")
        and workspace.Map:FindFirstChild("Canyon")
        and workspace.Map.Canyon:FindFirstChild("LaunchStrip")
    if not strip then return end

    local target = strip.Position + Vector3.new(0, 3, 0)
    hum:MoveTo(target)

    local timeout = tick() + 10
    while not isOnStrip() and tick() < timeout and getgenv().AutoThrow do
        task.wait(0.1)
    end
end

-- ══════════════════════════════════════════════════════════
-- LUỒNG 1: AUTO THROW
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while ScriptRunning do
        if getgenv().AutoThrow then
            local char = LocalPlayer.Character
            if char and char:GetAttribute("Training") then
                stopTrainingNow()
                task.wait(0.4)
            else
                local state = getState()
                if state == "idle" then
                    if not isOnStrip() then walkToStrip() end
                    task.wait(0.1)
                elseif state == "aiming" then
                    local fx = getThrowFX()
                    local curseur = getCurseur()
                    if curseur then
                        local fired = false
                        local timeout = tick() + 4
                        local conn
                        conn = RunService.RenderStepped:Connect(function()
                            if not getgenv().AutoThrow or tick() > timeout then
                                conn:Disconnect()
                                fired = true
                                return
                            end
                            local offset = curseur.Position.Y.Offset
                            local n7 = math.clamp((317 - offset) / 304, 0, 1)
                            if n7 >= 0.98 then
                                conn:Disconnect()
                                fired = true
                                local testTap = fx and fx:FindFirstChild("TestTap")
                                if testTap then testTap:Fire() end
                            end
                        end)
                        while not fired do task.wait() end
                    else
                        local testTap = fx and fx:FindFirstChild("TestTap")
                        if testTap then testTap:Fire() end
                    end
                    task.wait(0.3)
                elseif state == "result" then
                    if getgenv().AutoThrow and not getgenv().AutoTrain then
                        local fx = getThrowFX()
                        local testAgain = fx and fx:FindFirstChild("TestAgain")
                        if testAgain then testAgain:Fire() end
                    end
                    task.wait(0.5)
                else
                    task.wait(0.2)
                end
            end
        else
            task.wait(0.2)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- LUỒNG 2: AUTO TRAIN (PATHFINDING + ANTI-STUCK)
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    local barName = "BarStation"
    local promptName = "TrainPrompt"

    local function findTrainPrompt()
        if okCS and ClientState and ClientState.MyPlot then
            local myPlot = ClientState.MyPlot()
            if myPlot then
                local barStation = myPlot:FindFirstChild(barName)
                if barStation then
                    local prompt = barStation:FindFirstChild(promptName, true) or barStation:FindFirstChildWhichIsA("ProximityPrompt", true)
                    local part = barStation:FindFirstChild("Bar") or barStation:FindFirstChildWhichIsA("BasePart", true)
                    if prompt then return prompt, part end
                end
            end
        end

        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local bestPrompt, bestPart, bestDist = nil, nil, math.huge

        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc:IsA("ProximityPrompt") and desc.Name == promptName then
                local parent = desc.Parent
                local part = parent:IsA("BasePart") and parent or parent:FindFirstAncestorWhichIsA("BasePart")
                if part and hrp then
                    local d = (part.Position - hrp.Position).Magnitude
                    if d < bestDist then
                        bestDist = d; bestPrompt = desc; bestPart = part
                    end
                elseif desc then
                    bestPrompt = desc; bestPart = part
                end
            end
        end
        return bestPrompt, bestPart
    end

    local function smartWalkTo(targetPos)
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local path = PathfindingService:CreatePath({
            AgentRadius = 2.5,
            AgentHeight = 5,
            AgentCanJump = true,
            WaypointSpacing = 4
        })

        local success = pcall(function()
            path:ComputeAsync(hrp.Position, targetPos)
        end)

        local waypoints = {}
        if success and path.Status == Enum.PathStatus.Success then
            waypoints = path:GetWaypoints()
        else
            waypoints = { { Position = targetPos, Action = Enum.PathWaypointAction.Walk } }
        end

        for _, wp in ipairs(waypoints) do
            if not getgenv().AutoTrain or getState() ~= "idle" then break end
            if (hrp.Position - targetPos).Magnitude <= 7.5 then break end

            if wp.Action == Enum.PathWaypointAction.Jump then
                hum.Jump = true
            end

            hum:MoveTo(wp.Position)
            local wpTimeout = tick() + 2.5
            local lastPos = hrp.Position
            local stuckTimer = tick()

            while (hrp.Position - wp.Position).Magnitude > 3.5 and tick() < wpTimeout and getgenv().AutoTrain do
                if (hrp.Position - targetPos).Magnitude <= 7.5 then break end

                if (hrp.Position - lastPos).Magnitude < 0.4 then
                    if tick() - stuckTimer > 0.7 then
                        hum.Jump = true
                        local sideOffset = hrp.CFrame.RightVector * (math.random(0, 1) == 0 and 5 or -5)
                        hum:MoveTo(hrp.Position + sideOffset)
                        task.wait(0.35)
                        hum:MoveTo(wp.Position)
                        stuckTimer = tick()
                    end
                else
                    lastPos = hrp.Position
                    stuckTimer = tick()
                end
                task.wait(0.1)
            end
        end
    end

    while ScriptRunning do
        if getgenv().AutoTrain then
            if getState() ~= "idle" then
                stopThrowingNow()
                task.wait(0.35)
            else
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local hum = char and char:FindFirstChildOfClass("Humanoid")

                if char and hrp and hum and not char:GetAttribute("Training") then
                    local prompt, part = findTrainPrompt()
                    if prompt then
                        local rawPos = part and part.Position or (prompt.Parent:IsA("Attachment") and prompt.Parent.WorldPosition)
                        if rawPos then
                            local dir = Vector3.new(hrp.Position.X - rawPos.X, 0, hrp.Position.Z - rawPos.Z)
                            local standPos = dir.Magnitude > 0.1 and (rawPos + dir.Unit * 4) or rawPos

                            if (hrp.Position - rawPos).Magnitude > 8 then
                                smartWalkTo(standPos)
                            end
                        end

                        if getgenv().AutoTrain and getState() == "idle" and not char:GetAttribute("Training") then
                            pcall(function()
                                if fireproximityprompt then
                                    fireproximityprompt(prompt)
                                else
                                    prompt:InputHoldBegin()
                                    task.wait((prompt.HoldDuration or 0) + 0.1)
                                    prompt:InputHoldEnd()
                                end
                            end)
                        end
                    end
                end
                task.wait(0.6)
            end
        else
            task.wait(0.3)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- LUỒNG 3: AUTO PLACE BEST
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while ScriptRunning do
        if getgenv().AutoPlaceBest then
            pcall(function() RequestRemote:InvokeServer("PlaceBest", {}) end)
            task.wait(2)
        else
            task.wait(0.3)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- LUỒNG 4: AUTO UPGRADE THÔNG MINH (CAPACITY + BAR + SEED)
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    local trackedTier = 0

    while ScriptRunning do
        local currentMoney = getPlayerMoney()
        local statusParts = {}

        if getgenv().AutoUpgrade then
            local canBuyCap = true
            local currentCap = (okCS and ClientState and tonumber(ClientState.capacity))
                or tonumber(LocalPlayer:GetAttribute("Capacity"))

            if currentMoney and okBal and Balance then
                local capTable = Balance.Capacity or Balance.Capacities or Balance.PenCapacity
                if type(capTable) == "table" and currentCap then
                    local nextCapEntry = capTable[currentCap + 1] or capTable[currentCap]
                    local capCost = type(nextCapEntry) == "number" and nextCapEntry
                        or (type(nextCapEntry) == "table" and tonumber(nextCapEntry.cost or nextCapEntry.price or nextCapEntry.Cost))
                    if capCost and currentMoney < capCost then
                        canBuyCap = false
                    end
                end
            end

            if canBuyCap then
                pcall(function()
                    RequestRemote:InvokeServer("BuyCapacity", {})
                end)
                table.insert(statusParts, "Capacity: Đang check mua")
            else
                table.insert(statusParts, "Capacity: Chờ đủ tiền")
            end
            task.wait(0.25)
        end

        if getgenv().AutoUpgradeBar then
            if getgenv().AutoThrow or not getgenv().AutoTrain then
                table.insert(statusParts, "Tạ: Tạm dừng (Đang không Train)")
            else
                local okBar, barMsg = triggerBarUpgrade(false)
                table.insert(statusParts, okBar and "Tạ: Đã kích hoạt nâng!" or ("Tạ: " .. tostring(barMsg)))
            end
            task.wait(0.25)
        end

        if #statusParts > 0 then
            UpgradeStatus:SetDesc(table.concat(statusParts, " | "))
        else
            UpgradeStatus:SetDesc("Đang tắt tự động nâng cấp Capacity & Tạ.")
        end

        if getgenv().AutoBuyBestSeed then
            local attrTier, maxTier = getSeedProgressionInfo()
            local currentHighest = math.max(trackedTier, attrTier)

            if currentHighest >= maxTier then
                SeedStatus:SetDesc(string.format("Đã đạt cấp hạt giống tối đa (%d/%d)!", currentHighest, maxTier))
                task.wait(1.5)
            else
                local nextTier = currentHighest + 1
                local canAfford = true
                local costStr = ""

                if currentMoney and okBal and Balance and type(Balance.Seeds) == "table" and Balance.Seeds[nextTier] then
                    local seedData = Balance.Seeds[nextTier]
                    local cost = tonumber(seedData.cost or seedData.price or seedData.Cost or seedData.Price)
                    if cost then
                        costStr = " (Giá: " .. (Balance.Short and Balance.Short(cost) or tostring(cost)) .. ")"
                        if currentMoney < cost then
                            canAfford = false
                        end
                    end
                end

                if not canAfford then
                    SeedStatus:SetDesc(string.format("Chờ đủ tiền lên cấp #%d%s", nextTier, costStr))
                else
                    SeedStatus:SetDesc(string.format("Đang mở khóa cấp #%d%s...", nextTier, costStr))
                    local ok, res = pcall(function()
                        return RequestRemote:InvokeServer("BuySeed", { i = nextTier })
                    end)

                    if ok and res == true then
                        trackedTier = nextTier
                        SeedStatus:SetDesc(string.format("Đã mở khóa thành công cấp #%d!", nextTier))
                    else
                        local msg = tostring(res or ""):lower()
                        if msg:find("owned") or msg:find("already") or msg:find("unlocked") or msg:find("bought") then
                            trackedTier = nextTier
                        end
                    end
                end
                task.wait(0.6)
            end
        else
            task.wait(0.4)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- LUỒNG 5: AUTO X2 XP
-- ══════════════════════════════════════════════════════════
local function claimX2(child)
    if not getgenv().AutoX2 then return end
    task.wait(0.1)
    fireGuiButton(child)
end

local xpBoostHud = playerGui:WaitForChild("XPBoostHud", 10)
if xpBoostHud then
    xpBoostHud.ChildAdded:Connect(function(child)
        if child.Name == "XPOffer" and child:IsA("ImageButton") then
            claimX2(child)
        end
    end)
    for _, child in ipairs(xpBoostHud:GetChildren()) do
        if child.Name == "XPOffer" and child:IsA("ImageButton") then
            claimX2(child)
        end
    end
end

-- ══════════════════════════════════════════════════════════
-- LUỒNG 6: AUTO REWARDS
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    while ScriptRunning do
        if getgenv().AutoRewards then
            if LocalPlayer:GetAttribute("DailyReady") == true then
                pcall(function() RequestRemote:InvokeServer("ClaimDaily") end)
                task.wait(0.5)
            end

            if okBal and Balance and Balance.Gifts then
                local claimed = {}
                for id in tostring(LocalPlayer:GetAttribute("GiftsClaimed") or ""):gmatch("%d+") do
                    claimed[tonumber(id)] = true
                end

                local sessionStart = tonumber(LocalPlayer:GetAttribute("SessionStart")) or workspace:GetServerTimeNow()
                local elapsed = workspace:GetServerTimeNow() - sessionStart

                for i, gift in ipairs(Balance.Gifts) do
                    if not claimed[i] and elapsed >= (gift.at - 1) then
                        pcall(function() RequestRemote:InvokeServer("ClaimGift", { i = i }) end)
                        task.wait(0.4)
                    end
                end
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- LUỒNG 7: AUTO REJOIN
-- ══════════════════════════════════════════════════════════
task.spawn(function()
    local rejoining = false

    while ScriptRunning do
        if getgenv().AutoRejoin and not rejoining then
            if okBal and Balance and Balance.Gifts and #Balance.Gifts > 0 then
                local claimed = {}
                for id in tostring(LocalPlayer:GetAttribute("GiftsClaimed") or ""):gmatch("%d+") do
                    claimed[tonumber(id)] = true
                end

                local allClaimed = true
                for i = 1, #Balance.Gifts do
                    if not claimed[i] then
                        allClaimed = false
                        break
                    end
                end

                if allClaimed then
                    rejoining = true
                    if Settings.AutoExecEnabled then
                        QueueScriptForTeleport()
                    end
                    task.wait(2)
                    pcall(function()
                        if #Players:GetPlayers() <= 1 then
                            TeleportService:Teleport(game.PlaceId, LocalPlayer)
                        else
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
                        end
                    end)
                    task.delay(6, function()
                        if ScriptRunning then
                            pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
                        end
                    end)
                end
            end
            task.wait(2)
        else
            task.wait(0.5)
        end
    end
end)

-- ══════════════════════════════════════════════════════════
-- KHỞI TẠO HOÀN TẤT
-- ══════════════════════════════════════════════════════════
Window:SelectTab(1)

if Settings.AutoExecEnabled then
    QueueScriptForTeleport()
end

Fluent:Notify({
    Title = "Auto Farm Hub",
    Content = "Đã tải xong! Chạm nút HUB bên trái để ẩn/hiện menu.",
    Duration = 4
})