-- [[ 🔪 LMM MM2 (beta) v3.9 | 防踢Anti-AFK按钮 + 自动糖果下方速度调节 + 顶部折叠栏 | 手机端触控修复 ]]

local _P = game:GetService("Players")
local _RS = game:GetService("RunService")
local _CG = game:GetService("CoreGui")
local _TS = game:GetService("TweenService")
local _UIS = game:GetService("UserInputService")
local _WS = workspace
local _LP = _P.LocalPlayer

if not _LP then
    _P.PlayerAdded:Wait()
    _LP = _P.LocalPlayer
end

-- 跨服/重进自启底层支持
local _AutoExecuteEnabled = false
pcall(function()
    local coreQueue = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
    if coreQueue then
        coreQueue([[
            task.wait(3)
        ]])
    end
end)

-- 清理旧版 UI
local targetParent = (gethui and gethui()) or _CG
pcall(function()
    if targetParent:FindFirstChild("LMM_MM2_Gui") then 
        targetParent.LMM_MM2_Gui:Destroy() 
    end
end)

local _S = Instance.new("ScreenGui")
_S.Name = "LMM_MM2_Gui"
_S.ResetOnSpawn = false
_S.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
_S.IgnoreGuiInset = true
_S.Parent = targetParent

-- 统一点击绑定函数（兼容手机触屏 / 电脑鼠标 / 手柄）
local function BindTap(btn, callback)
    btn.Active = true
    local busy = false
    btn.Activated:Connect(function()
        if busy then return end
        busy = true
        task.spawn(function()
            pcall(callback)
            task.wait(0.12)
            busy = false
        end)
    end)
end

-- 状态配置
local _Config = {
    RoleESP = false,
    GunDropESP = false,
    CandyESP = false,
    AutoFarmer = false,
    AutoCollectCandy = false, 
    AntiAFK = false,
    HideName = false,
    AutoExecute = false,
    CandySpeed = 20,
    ThemeColor = Color3.fromRGB(99, 102, 241),
    BgColor = Color3.fromRGB(15, 15, 24),
    ButtonColor = Color3.fromRGB(22, 22, 35),
    ColorMurderer = Color3.fromRGB(239, 68, 68),
    ColorSheriff  = Color3.fromRGB(59, 130, 246),
    ColorInnocent = Color3.fromRGB(34, 197, 94),
    ColorGunDrop  = Color3.fromRGB(250, 204, 21),
    ColorCandy    = Color3.fromRGB(249, 115, 22)
}

-- 糖果收集统计变量
local totalCandiesCollected = 0
local sessionStartTime = tick()

-- 主面板
local _Main = Instance.new("Frame", _S)
_Main.Size = UDim2.new(0, 480, 0, 310)
_Main.Position = UDim2.new(0.05, 0, 0.28, 0)
_Main.BackgroundColor3 = _Config.BgColor
_Main.BackgroundTransparency = 0.02
_Main.Active = true
_Main.ClipsDescendants = true
Instance.new("UICorner", _Main).CornerRadius = UDim.new(0, 16)

local _Stroke = Instance.new("UIStroke", _Main)
_Stroke.Thickness = 2
local _StrokeGrad = Instance.new("UIGradient", _Stroke)
_StrokeGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(99, 102, 241)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(168, 85, 247)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(59, 130, 246))
})

-- 顶部标题栏
local _Title = Instance.new("TextLabel", _Main)
_Title.Size = UDim2.new(1, -100, 0, 45)
_Title.Position = UDim2.new(0, 18, 0, 0)
_Title.BackgroundTransparency = 1
_Title.Text = "🔪  LMM MM2 <font color='rgb(168, 85, 247)'>(beta)</font>   <font color='rgb(140, 140, 160)'>v3.9</font>"
_Title.RichText = true
_Title.TextColor3 = Color3.fromRGB(255, 255, 255)
_Title.Font = Enum.Font.GothamBold
_Title.TextSize = 15
_Title.TextXAlignment = Enum.TextXAlignment.Left
_Title.Active = true

-- 拖动逻辑
local dragging, dragStart, startPos
_Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = _Main.Position
    end
end)
_UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        _Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
_UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- 分隔线
local _Line = Instance.new("Frame", _Main)
_Line.Size = UDim2.new(1, -24, 0, 1)
_Line.Position = UDim2.new(0, 12, 0, 45)
_Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
_Line.BackgroundTransparency = 0.92
_Line.BorderSizePixel = 0

-- 顶部右侧控制按钮：`×` (关闭) 与 `-` (最小化折叠)
local function CreateHeaderCtrl(text, xOffset, bgCol, hoverCol, callback)
    local btn = Instance.new("TextButton", _Main)
    btn.Size = UDim2.new(0, 30, 0, 30)
    btn.Position = UDim2.new(1, xOffset, 0, 8)
    btn.BackgroundColor3 = bgCol
    btn.BackgroundTransparency = 0.2
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseEnter:Connect(function() _TS:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = hoverCol}):Play() end)
    btn.MouseLeave:Connect(function() _TS:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = bgCol}):Play() end)
    
    BindTap(btn, callback)
    return btn
end

-- 声明最小化悬浮条（放置在屏幕正上方正中间长方形）
local miniBar = Instance.new("TextButton", _S)
miniBar.Size = UDim2.new(0, 220, 0, 36)
miniBar.Position = UDim2.new(0.5, -110, 0, -50)
miniBar.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
miniBar.BackgroundTransparency = 0.1
miniBar.Text = "🔪 LMM MM2 (点击展开面板)"
miniBar.TextColor3 = Color3.fromRGB(210, 210, 235)
miniBar.Font = Enum.Font.GothamBold
miniBar.TextSize = 12
miniBar.AutoButtonColor = false
miniBar.Visible = false
Instance.new("UICorner", miniBar).CornerRadius = UDim.new(0, 10)
local miniStroke = Instance.new("UIStroke", miniBar)
miniStroke.Thickness = 1.5
miniStroke.Color = Color3.fromRGB(99, 102, 241)

local isMinimized = false

-- 🧹 清理函数
local function CleanupAll()
    _Config.AutoCollectCandy = false
    _Config.AutoFarmer = false
    _Config.AntiAFK = false
    for _, p in pairs(_P:GetPlayers()) do
        if p.Character then
            local box = p.Character:FindFirstChild("LMM_BoxESP")
            if box then box:Destroy() end
            local tag = p.Character:FindFirstChild("LMM_NameTag")
            if tag then tag:Destroy() end
        end
    end
    for _, obj in pairs(_WS:GetDescendants()) do
        if obj.Name == "LMM_GunESP" or obj.Name == "LMM_GunHighlight" or obj.Name == "LMM_CandyESP" then
            obj:Destroy()
        end
    end
    local char = _LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then 
        hum.PlatformStand = false 
        hum.WalkSpeed = 16
    end
    if _WS:FindFirstChild("LMM_SafePlatform") then
        _WS.LMM_SafePlatform:Destroy()
    end
    _S:Destroy()
end

CreateHeaderCtrl("×", -40, Color3.fromRGB(239, 68, 68), Color3.fromRGB(255, 90, 90), CleanupAll)

CreateHeaderCtrl("—", -76, Color3.fromRGB(45, 45, 65), Color3.fromRGB(70, 70, 90), function()
    isMinimized = true
    _TS:Create(_Main, TweenInfo.new(0.35, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0, 20),
        BackgroundTransparency = 1
    }):Play()
    task.wait(0.3)
    _Main.Visible = false
    
    miniBar.Visible = true
    miniBar.Position = UDim2.new(0.5, -110, 0, -45)
    _TS:Create(miniBar, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0.5, -110, 0, 12)
    }):Play()
end)

BindTap(miniBar, function()
    if not isMinimized then return end
    _TS:Create(miniBar, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
        Position = UDim2.new(0.5, -110, 0, -50)
    }):Play()
    task.wait(0.25)
    miniBar.Visible = false
    
    _Main.Visible = true
    _Main.Size = UDim2.new(0, 0, 0, 0)
    _Main.Position = UDim2.new(0.5, 0, 0.28, 0)
    _TS:Create(_Main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 480, 0, 310),
        Position = UDim2.new(0.05, 0, 0.28, 0),
        BackgroundTransparency = 0.02
    }):Play()
    isMinimized = false
end)

-- 左侧导航栏
local sidebar = Instance.new("Frame", _Main)
sidebar.Size = UDim2.new(0, 115, 1, -55)
sidebar.Position = UDim2.new(0, 12, 0, 52)
sidebar.BackgroundTransparency = 1

-- 页面容器
local pages = {}
local function CreatePage(name)
    local page = Instance.new("ScrollingFrame", _Main)
    page.Size = UDim2.new(1, -145, 1, -58)
    page.Position = UDim2.new(0, 135, 0, 52)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    pages[name] = page
    return page
end

local pageData     = CreatePage("Data")
local pageAuto     = CreatePage("Auto")
local pageVisual   = CreatePage("Visual")
local pageSettings = CreatePage("Settings")

local currentTabBtn = nil
local navButtons = {}

local function SwitchTab(tabName, btnObj)
    for name, p in pairs(pages) do
        p.Visible = (name == tabName)
    end
    if currentTabBtn then
        _TS:Create(currentTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = _Config.ButtonColor, BackgroundTransparency = 0.3}):Play()
        currentTabBtn.TextColor3 = Color3.fromRGB(180, 180, 195)
    end
    currentTabBtn = btnObj
    _TS:Create(currentTabBtn, TweenInfo.new(0.2), {BackgroundColor3 = _Config.ThemeColor, BackgroundTransparency = 0.1}):Play()
    currentTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
end

local function CreateNavBtn(text, tabName, yPos)
    local btn = Instance.new("TextButton", sidebar)
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = _Config.ButtonColor
    btn.BackgroundTransparency = 0.3
    btn.Text = "  " .. text
    btn.TextColor3 = Color3.fromRGB(180, 180, 195)
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

    table.insert(navButtons, btn)
    BindTap(btn, function()
        SwitchTab(tabName, btn)
    end)
    return btn
end

local btnData     = CreateNavBtn("📊 数据", "Data", 0)
local btnAuto     = CreateNavBtn("🤖 自动", "Auto", 44)
local btnVisual   = CreateNavBtn("👁️ 视觉", "Visual", 88)
local btnSettings = CreateNavBtn("⚙️ 设定", "Settings", 132)

SwitchTab("Data", btnData)

-- 胶囊滑动开关生成器
local function CreateToggle(parentPage, name, yPos, configKey)
    local btn = Instance.new("TextButton", parentPage)
    btn.Size = UDim2.new(1, -10, 0, 42)
    btn.Position = UDim2.new(0, 0, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
    btn.BackgroundTransparency = 0.2
    btn.AutoButtonColor = false
    btn.Text = ""
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    
    local btnStroke = Instance.new("UIStroke", btn)
    btnStroke.Thickness = 1
    btnStroke.Color = Color3.fromRGB(40, 40, 58)

    local txt = Instance.new("TextLabel", btn)
    txt.Size = UDim2.new(1, -60, 1, 0)
    txt.Position = UDim2.new(0, 14, 0, 0)
    txt.BackgroundTransparency = 1
    txt.Text = name
    txt.TextColor3 = Color3.fromRGB(210, 210, 225)
    txt.Font = Enum.Font.GothamMedium
    txt.TextSize = 13
    txt.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame", btn)
    track.Size = UDim2.new(0, 42, 0, 22)
    track.Position = UDim2.new(1, -52, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local knob = Instance.new("Frame", track)
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(150, 150, 165)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

    local function refreshUI(animate)
        local state = _Config[configKey]
        local trackColor = state and Color3.fromRGB(34, 197, 94) or Color3.fromRGB(28, 28, 40)
        local knobPos = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local knobColor = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 165)
        local textColor = state and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(210, 210, 225)

        txt.TextColor3 = textColor
        if animate then
            _TS:Create(track, TweenInfo.new(0.2), {BackgroundColor3 = trackColor}):Play()
            _TS:Create(knob, TweenInfo.new(0.2), {Position = knobPos, BackgroundColor3 = knobColor}):Play()
        else
            track.BackgroundColor3 = trackColor
            knob.Position = knobPos
            knob.BackgroundColor3 = knobColor
        end
    end
    refreshUI(false)

    BindTap(btn, function()
        _Config[configKey] = not _Config[configKey]
        refreshUI(true)
        if configKey == "AutoExecute" then
            _AutoExecuteEnabled = _Config[configKey]
        end
        if not _Config[configKey] then
            if configKey == "RoleESP" then 
                for _, p in pairs(_P:GetPlayers()) do
                    if p.Character then
                        local b = p.Character:FindFirstChild("LMM_BoxESP")
                        if b then b:Destroy() end
                        local t = p.Character:FindFirstChild("LMM_NameTag")
                        if t then t:Destroy() end
                    end
                end
            end
            if configKey == "GunDropESP" then 
                for _, obj in pairs(_WS:GetDescendants()) do
                    if obj.Name == "LMM_GunESP" or obj.Name == "LMM_GunHighlight" then obj:Destroy() end
                end
            end
            if configKey == "CandyESP" then 
                for _, obj in pairs(_WS:GetDescendants()) do
                    if obj.Name == "LMM_CandyESP" then obj:Destroy() end
                end
            end
            if configKey == "AutoCollectCandy" then
                local char = _LP.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then 
                    hum.PlatformStand = false 
                    hum.WalkSpeed = 16
                end
            end
        end
    end)
end

-- ==========================================
-- 【1. 数据面板】
-- ==========================================
local profileCard = Instance.new("Frame", pageData)
profileCard.Size = UDim2.new(1, -10, 0, 82)
profileCard.Position = UDim2.new(0, 0, 0, 0)
profileCard.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
profileCard.BackgroundTransparency = 0.2
Instance.new("UICorner", profileCard).CornerRadius = UDim.new(0, 12)
local pStroke = Instance.new("UIStroke", profileCard)
pStroke.Color = Color3.fromRGB(40, 40, 58)

local avatarImg = Instance.new("ImageLabel", profileCard)
avatarImg.Size = UDim2.new(0, 58, 0, 58)
avatarImg.Position = UDim2.new(0, 12, 0.5, -29)
avatarImg.BackgroundColor3 = Color3.fromRGB(24, 24, 36)
avatarImg.Image = "rbxthumb://type=AvatarHeadShot&id=" .. _LP.UserId .. "&w=150&h=150"
Instance.new("UICorner", avatarImg).CornerRadius = UDim.new(1, 0)
local avStroke = Instance.new("UIStroke", avatarImg)
avStroke.Thickness = 1.5
avStroke.Color = Color3.fromRGB(99, 102, 241)

local nameLbl = Instance.new("TextLabel", profileCard)
nameLbl.Size = UDim2.new(1, -85, 0, 24)
nameLbl.Position = UDim2.new(0, 80, 0, 16)
nameLbl.BackgroundTransparency = 1
nameLbl.Text = _LP.DisplayName
nameLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLbl.Font = Enum.Font.GothamBold
nameLbl.TextSize = 14
nameLbl.TextXAlignment = Enum.TextXAlignment.Left

local userLbl = Instance.new("TextLabel", profileCard)
userLbl.Size = UDim2.new(1, -85, 0, 20)
userLbl.Position = UDim2.new(0, 80, 0, 40)
userLbl.BackgroundTransparency = 1
userLbl.Text = "@" .. _LP.Name .. "  |  ID: " .. _LP.UserId
userLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
userLbl.Font = Enum.Font.GothamMedium
userLbl.TextSize = 11
userLbl.TextXAlignment = Enum.TextXAlignment.Left

local statsCard = Instance.new("Frame", pageData)
statsCard.Size = UDim2.new(1, -10, 0, 65)
statsCard.Position = UDim2.new(0, 0, 0, 92)
statsCard.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
statsCard.BackgroundTransparency = 0.2
Instance.new("UICorner", statsCard).CornerRadius = UDim.new(0, 12)
local sStroke = Instance.new("UIStroke", statsCard)
sStroke.Color = Color3.fromRGB(40, 40, 58)

local statsText = Instance.new("TextLabel", statsCard)
statsText.Size = UDim2.new(1, -24, 1, -10)
statsText.Position = UDim2.new(0, 14, 0, 5)
statsText.BackgroundTransparency = 1
statsText.TextColor3 = Color3.fromRGB(210, 210, 225)
statsText.Font = Enum.Font.GothamMedium
statsText.TextSize = 13
statsText.TextXAlignment = Enum.TextXAlignment.Left
statsText.TextYAlignment = Enum.TextYAlignment.Top
statsText.LineHeight = 1.4
statsText.Text = "正在同步游戏状态..."

CreateToggle(pageData, "隐藏名称为乱码 (Hide Name)", 168, "HideName")

-- ==========================================
-- 【2. 自动面板 + 糖果速度调节器 + 收益统计】
-- ==========================================
CreateToggle(pageAuto, "智能自动挂机农夫 (Auto Farmer)", 0, "AutoFarmer")
CreateToggle(pageAuto, "自动拾取糖果 (Auto Candy)", 52, "AutoCollectCandy")

local speedCard = Instance.new("Frame", pageAuto)
speedCard.Size = UDim2.new(1, -10, 0, 42)
speedCard.Position = UDim2.new(0, 0, 0, 104)
speedCard.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
speedCard.BackgroundTransparency = 0.2
Instance.new("UICorner", speedCard).CornerRadius = UDim.new(0, 10)
local scStroke = Instance.new("UIStroke", speedCard)
scStroke.Color = Color3.fromRGB(40, 40, 58)

local speedLbl = Instance.new("TextLabel", speedCard)
speedLbl.Size = UDim2.new(0.6, 0, 1, 0)
speedLbl.Position = UDim2.new(0, 14, 0, 0)
speedLbl.BackgroundTransparency = 1
speedLbl.Text = "⚡ 自动糖果移动速度"
speedLbl.TextColor3 = Color3.fromRGB(210, 210, 225)
speedLbl.Font = Enum.Font.GothamMedium
speedLbl.TextSize = 13
speedLbl.TextXAlignment = Enum.TextXAlignment.Left

local speedBox = Instance.new("TextBox", speedCard)
speedBox.Size = UDim2.new(0, 70, 0, 28)
speedBox.Position = UDim2.new(1, -80, 0.5, -14)
speedBox.BackgroundColor3 = Color3.fromRGB(24, 24, 38)
speedBox.BackgroundTransparency = 0.2
speedBox.Text = tostring(_Config.CandySpeed)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.Font = Enum.Font.GothamBold
speedBox.TextSize = 13
Instance.new("UICorner", speedBox).CornerRadius = UDim.new(0, 6)
local sbStroke = Instance.new("UIStroke", speedBox)
sbStroke.Color = Color3.fromRGB(99, 102, 241)

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val then
        _Config.CandySpeed = math.clamp(val, 10, 100)
    end
    speedBox.Text = tostring(_Config.CandySpeed)
end)

local candyStatsCard = Instance.new("Frame", pageAuto)
candyStatsCard.Size = UDim2.new(1, -10, 0, 68)
candyStatsCard.Position = UDim2.new(0, 0, 0, 152)
candyStatsCard.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
candyStatsCard.BackgroundTransparency = 0.2
Instance.new("UICorner", candyStatsCard).CornerRadius = UDim.new(0, 12)
local csStroke = Instance.new("UIStroke", candyStatsCard)
csStroke.Color = Color3.fromRGB(40, 40, 58)

local candyStatsText = Instance.new("TextLabel", candyStatsCard)
candyStatsText.Size = UDim2.new(1, -20, 1, -10)
candyStatsText.Position = UDim2.new(0, 12, 0, 6)
candyStatsText.BackgroundTransparency = 1
candyStatsText.TextColor3 = Color3.fromRGB(249, 115, 22)
candyStatsText.Font = Enum.Font.GothamBold
candyStatsText.TextSize = 12
candyStatsText.TextXAlignment = Enum.TextXAlignment.Left
candyStatsText.TextYAlignment = Enum.TextYAlignment.Top
candyStatsText.LineHeight = 1.4
candyStatsText.Text = "🍬 糖果收益统计：\n• 累计已拿到：0 个\n• 预计一小时赚取：0 个/小时"

local autoDesc = Instance.new("TextLabel", pageAuto)
autoDesc.Size = UDim2.new(1, -14, 0, 80)
autoDesc.Position = UDim2.new(0, 4, 0, 228)
autoDesc.BackgroundTransparency = 1
autoDesc.TextColor3 = Color3.fromRGB(140, 140, 160)
autoDesc.Font = Enum.Font.GothamMedium
autoDesc.TextSize = 11
autoDesc.TextXAlignment = Enum.TextXAlignment.Left
autoDesc.TextYAlignment = Enum.TextYAlignment.Top
autoDesc.TextWrapped = true
autoDesc.LineHeight = 1.35
autoDesc.Text = "• 自动吸糖果：可自由调节移速，穿墙顺畅！\n• 平民与警长：自动飞往高空隐形安全平台挂机"

-- ==========================================
-- 【3. 视觉面板】
-- ==========================================
CreateToggle(pageVisual, "角色身份透视 (ESP)", 0, "RoleESP")
CreateToggle(pageVisual, "掉落枪支实时追踪 (Gun ESP)", 52, "GunDropESP")
CreateToggle(pageVisual, "万圣节糖果透视 (Candy ESP)", 104, "CandyESP")

-- ==========================================
-- 【4. 设定面板】
-- ==========================================
local settingsTitle1 = Instance.new("TextLabel", pageSettings)
settingsTitle1.Size = UDim2.new(1, 0, 0, 22)
settingsTitle1.Position = UDim2.new(0, 0, 0, 0)
settingsTitle1.BackgroundTransparency = 1
settingsTitle1.Text = "🎨 第一部分：按钮颜色色盘"
settingsTitle1.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTitle1.Font = Enum.Font.GothamBold
settingsTitle1.TextSize = 12
settingsTitle1.TextXAlignment = Enum.TextXAlignment.Left

local paletteBtnFrame = Instance.new("Frame", pageSettings)
paletteBtnFrame.Size = UDim2.new(1, -10, 0, 52)
paletteBtnFrame.Position = UDim2.new(0, 0, 0, 24)
paletteBtnFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
paletteBtnFrame.BackgroundTransparency = 0.2
Instance.new("UICorner", paletteBtnFrame).CornerRadius = UDim.new(0, 10)
local pbStroke = Instance.new("UIStroke", paletteBtnFrame)
pbStroke.Color = Color3.fromRGB(40, 40, 58)

local function CreateBtnColorBlock(themeColor, btnColor, xPos, yPos, w, h)
    local btn = Instance.new("TextButton", paletteBtnFrame)
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = themeColor
    btn.Text = ""
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local str = Instance.new("UIStroke", btn)
    str.Thickness = 1.5
    if themeColor == Color3.fromRGB(20, 20, 26) then
        str.Color = Color3.fromRGB(120, 120, 140)
    else
        str.Color = Color3.fromRGB(255, 255, 255)
    end
    str.Transparency = 0.3

    BindTap(btn, function()
        _Config.ThemeColor = themeColor
        _Config.ButtonColor = btnColor
        if currentTabBtn then
            _TS:Create(currentTabBtn, TweenInfo.new(0.3), {BackgroundColor3 = themeColor}):Play()
        end
        for _, b in pairs(navButtons) do
            if b ~= currentTabBtn then
                _TS:Create(b, TweenInfo.new(0.3), {BackgroundColor3 = btnColor}):Play()
            end
        end
    end)
end

CreateBtnColorBlock(Color3.fromRGB(239, 68, 68), Color3.fromRGB(32, 16, 18), 10, 10, 36, 32)
CreateBtnColorBlock(Color3.fromRGB(249, 115, 22), Color3.fromRGB(32, 22, 16), 50, 10, 36, 32)
CreateBtnColorBlock(Color3.fromRGB(34, 197, 94),  Color3.fromRGB(16, 32, 22), 90, 10, 36, 32)
CreateBtnColorBlock(Color3.fromRGB(59, 130, 246), Color3.fromRGB(16, 22, 34), 130, 10, 36, 32)
CreateBtnColorBlock(Color3.fromRGB(168, 85, 247), Color3.fromRGB(24, 16, 34), 170, 10, 36, 32)
CreateBtnColorBlock(Color3.fromRGB(255, 255, 255),Color3.fromRGB(35, 35, 42), 210, 10, 42, 32)
CreateBtnColorBlock(Color3.fromRGB(150, 150, 160),Color3.fromRGB(28, 28, 36), 256, 10, 42, 32)
CreateBtnColorBlock(Color3.fromRGB(20, 20, 26),   Color3.fromRGB(10, 10, 14), 302, 10, 44, 32)

local settingsTitle2 = Instance.new("TextLabel", pageSettings)
settingsTitle2.Size = UDim2.new(1, 0, 0, 22)
settingsTitle2.Position = UDim2.new(0, 0, 0, 84)
settingsTitle2.BackgroundTransparency = 1
settingsTitle2.Text = "🎨 第二部分：UI背景颜色色盘"
settingsTitle2.TextColor3 = Color3.fromRGB(255, 255, 255)
settingsTitle2.Font = Enum.Font.GothamBold
settingsTitle2.TextSize = 12
settingsTitle2.TextXAlignment = Enum.TextXAlignment.Left

local paletteBgFrame = Instance.new("Frame", pageSettings)
paletteBgFrame.Size = UDim2.new(1, -10, 0, 52)
paletteBgFrame.Position = UDim2.new(0, 0, 0, 108)
paletteBgFrame.BackgroundColor3 = Color3.fromRGB(16, 16, 24)
paletteBgFrame.BackgroundTransparency = 0.2
Instance.new("UICorner", paletteBgFrame).CornerRadius = UDim.new(0, 10)
local pbgStroke = Instance.new("UIStroke", paletteBgFrame)
pbgStroke.Color = Color3.fromRGB(40, 40, 58)

local function CreateBgColorBlock(bgColor, xPos, yPos, w, h)
    local btn = Instance.new("TextButton", paletteBgFrame)
    btn.Size = UDim2.new(0, w, 0, h)
    btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.BackgroundColor3 = bgColor
    btn.BackgroundTransparency = 0
    btn.Text = ""
    btn.AutoButtonColor = true
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    local str = Instance.new("UIStroke", btn)
    str.Thickness = 1.5
    if bgColor == Color3.fromRGB(12, 12, 16) then
        str.Color = Color3.fromRGB(120, 120, 140)
    else
        str.Color = Color3.fromRGB(255, 255, 255)
    end
    str.Transparency = 0.3

    BindTap(btn, function()
        _Config.BgColor = bgColor
        _TS:Create(_Main, TweenInfo.new(0.3), {BackgroundColor3 = bgColor}):Play()
    end)
end

CreateBgColorBlock(Color3.fromRGB(38, 38, 56), 10, 10, 36, 32)
CreateBgColorBlock(Color3.fromRGB(64, 32, 45), 50, 10, 36, 32)
CreateBgColorBlock(Color3.fromRGB(28, 64, 48), 90, 10, 36, 32)
CreateBgColorBlock(Color3.fromRGB(28, 48, 76), 130, 10, 36, 32)
CreateBgColorBlock(Color3.fromRGB(58, 34, 70), 170, 10, 36, 32)
CreateBgColorBlock(Color3.fromRGB(240, 240, 245), 210, 10, 42, 32)
CreateBgColorBlock(Color3.fromRGB(110, 110, 125), 256, 10, 42, 32)
CreateBgColorBlock(Color3.fromRGB(12, 12, 16),   302, 10, 44, 32)

CreateToggle(pageSettings, "自动重新注入/重进自启 (Auto-Execute)", 168, "AutoExecute")
CreateToggle(pageSettings, "Anti-AFK (防踢保护)", 220, "AntiAFK")

-- 右下角拖动缩放 UI
local resizer = Instance.new("TextButton", _Main)
resizer.Size = UDim2.new(0, 26, 0, 26)
resizer.Position = UDim2.new(1, -26, 1, -26)
resizer.BackgroundTransparency = 1
resizer.Text = "◢"
resizer.TextColor3 = Color3.fromRGB(150, 150, 180)
resizer.TextSize = 15
resizer.Font = Enum.Font.GothamBold
resizer.Active = true

local resizing = false
local resizeStart, startSize
resizer.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        resizing = true
        resizeStart = i.Position
        startSize = _Main.AbsoluteSize
    end
end)
_UIS.InputChanged:Connect(function(i)
    if resizing and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
        local delta = i.Position - resizeStart
        _Main.Size = UDim2.new(0, math.clamp(startSize.X + delta.X, 420, 680), 0, math.clamp(startSize.Y + delta.Y, 280, 520))
    end
end)
_UIS.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        resizing = false
    end
end)

-- ==========================================
-- 核心逻辑与判定函数
-- ==========================================
local function IsInActiveRound()
    for _, obj in pairs(_WS:GetDescendants()) do
        if obj.Name == "CoinContainer" then
            return true, obj
        end
    end
    return false, nil
end

local function GetMM2Role(player)
    local char = player.Character
    local bp = player:FindFirstChild("Backpack")
    local hasKnife, hasGun = false, false

    local function scan(container)
        if not container then return end
        for _, item in pairs(container:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("dagger") or n:find("scythe") then
                    hasKnife = true
                elseif n:find("gun") or n:find("revolver") or n:find("pistol") then
                    hasGun = true
                end
            end
        end
    end

    scan(char)
    scan(bp)

    if hasKnife then
        return "Murderer", _Config.ColorMurderer, "【 杀手 】"
    elseif hasGun then
        return "Sheriff", _Config.ColorSheriff, "【 警长 】"
    else
        return "Innocent", _Config.ColorInnocent, "【 平民 】"
    end
end

local function EquipWeapon(weaponType)
    local char = _LP.Character
    local bp = _LP:FindFirstChild("Backpack")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not char or not hum then return nil end

    for _, item in pairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local n = item.Name:lower()
            if weaponType == "Knife" and (n:find("knife") or n:find("blade") or n:find("dagger") or n:find("scythe")) then
                return item
            elseif weaponType == "Gun" and (n:find("gun") or n:find("revolver") or n:find("pistol")) then
                return item
            end
        end
    end

    if bp then
        for _, item in pairs(bp:GetChildren()) do
            if item:IsA("Tool") then
                local n = item.Name:lower()
                if weaponType == "Knife" and (n:find("knife") or n:find("blade") or n:find("dagger") or n:find("scythe")) then
                    hum:EquipTool(item)
                    return item
                elseif weaponType == "Gun" and (n:find("gun") or n:find("revolver") or n:find("pistol")) then
                    hum:EquipTool(item)
                    return item
                end
            end
        end
    end
    return nil
end

local function TeleportToSafeSky(hrp)
    local plat = _WS:FindFirstChild("LMM_SafePlatform")
    if not plat then
        plat = Instance.new("Part", _WS)
        plat.Name = "LMM_SafePlatform"
        plat.Size = Vector3.new(30, 2, 30)
        plat.Anchored = true
        plat.Transparency = 0.75
        plat.Color = Color3.fromRGB(99, 102, 241)
        plat.Material = Enum.Material.SmoothPlastic
    end
    plat.Position = Vector3.new(0, 496, 0)
    hrp.CFrame = CFrame.new(0, 500, 0)
end

-- Anti-AFK 防踢挂机监听
local afkConnection = nil
task.spawn(function()
    while _S and _S.Parent do
        if _Config.AntiAFK then
            if not afkConnection then
                pcall(function()
                    local vu = game:GetService("VirtualUser")
                    afkConnection = _LP.Idled:Connect(function()
                        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                        task.wait(1)
                        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
                    end)
                end)
            end
        else
            if afkConnection then
                afkConnection:Disconnect()
                afkConnection = nil
            end
        end
        task.wait(1)
    end
end)

-- 独立自动收糖循环（避免 Tween 等待阻塞主刷新）
task.spawn(function()
    while _S and _S.Parent do
        if _Config.AutoCollectCandy then
            pcall(function()
                local inRound, coinContainer = IsInActiveRound()
                local myChar = _LP.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
                if inRound and coinContainer and myHrp and myHum and myHum.Health > 0 then
                    for _, part in pairs(myChar:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end

                    local candies = {}
                    for _, coin in pairs(coinContainer:GetChildren()) do
                        local cPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                        if cPart and cPart.Parent then
                            local dist = (cPart.Position - myHrp.Position).Magnitude
                            if dist < 120 then
                                table.insert(candies, {part = cPart, dist = dist})
                            end
                        end
                    end

                    table.sort(candies, function(a, b)
                        return a.dist < b.dist
                    end)

                    for _, item in ipairs(candies) do
                        if not _Config.AutoCollectCandy then break end
                        local cPart = item.part
                        if cPart and cPart.Parent and myHrp.Parent then
                            local dist = (cPart.Position - myHrp.Position).Magnitude
                            myHum:MoveTo(cPart.Position)
                            local targetCF = CFrame.new(cPart.Position + Vector3.new(0, 0.5, 0)) * myHrp.CFrame.Rotation
                            local duration = math.max(dist / _Config.CandySpeed, 0.08)
                            local tween = _TS:Create(myHrp, TweenInfo.new(duration, Enum.EasingStyle.Linear), {CFrame = targetCF})
                            tween:Play()
                            tween.Completed:Wait()
                            totalCandiesCollected = totalCandiesCollected + 1
                            task.wait(0.2)
                        end
                    end
                end
            end)
        end
        task.wait(0.25)
    end
end)

-- ==========================================
-- 主循环
-- ==========================================
task.spawn(function()
    local innocentTeleported = false
    local lastRoundState = false

    while _S and _S.Parent do
        pcall(function()
            if _AutoExecuteEnabled then
                pcall(function()
                    local coreQueue = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
                    if coreQueue then
                        coreQueue([[
                            task.wait(3)
                        ]])
                    end
                end)
            end

            local inRound, coinContainer = IsInActiveRound()
            local _, _, roleText = GetMM2Role(_LP)

            if inRound ~= lastRoundState then
                innocentTeleported = false
                lastRoundState = inRound
            end

            statsText.Text = string.format(
                "当前状态：%s\n服务器人数：%d / %d 人  (v3.9)",
                inRound and ("对局中 " .. roleText) or "大厅等待中",
                #_P:GetPlayers(), _P.MaxPlayers
            )

            if _Config.HideName then
                nameLbl.Text = "Anonymous"
                userLbl.Text = "@Anonymous  |  ID: 999999"
            else
                nameLbl.Text = _LP.DisplayName
                userLbl.Text = "@" .. _LP.Name .. "  |  ID: " .. _LP.UserId
            end

            local myChar = _LP.Character
            if myChar then
                local head = myChar:FindFirstChild("Head")
                if head then
                    for _, obj in pairs(head:GetChildren()) do
                        if obj:IsA("BillboardGui") or obj:IsA("SurfaceGui") then
                            obj.Enabled = not _Config.HideName
                        end
                    end
                end
            end

            if _Config.HideName then
                pcall(function()
                    local playerGui = _LP:FindFirstChild("PlayerGui")
                    if playerGui then
                        for _, gui in pairs(playerGui:GetDescendants()) do
                            if gui:IsA("TextLabel") and (gui.Text:find(_LP.Name) or gui.Text:find(_LP.DisplayName)) then
                                gui.Text = "Anonymous"
                            end
                        end
                    end
                end)
            end

            -- 角色身份透视 (Role ESP)
            if _Config.RoleESP then
                for _, p in pairs(_P:GetPlayers()) do
                    if p ~= _LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        local tChar = p.Character
                        local hrp = tChar.HumanoidRootPart
                        local _, color, labelText = GetMM2Role(p)

                        local box = tChar:FindFirstChild("LMM_BoxESP")
                        if not box then
                            box = Instance.new("BillboardGui", tChar)
                            box.Name = "LMM_BoxESP"
                            box.Adornee = hrp
                            box.Size = UDim2.new(4.2, 0, 5.5, 0)
                            box.AlwaysOnTop = true

                            local frame = Instance.new("Frame", box)
                            frame.Name = "BoxFrame"
                            frame.Size = UDim2.new(1, 0, 1, 0)
                            frame.BackgroundColor3 = color
                            frame.BackgroundTransparency = 0.88
                            frame.BorderSizePixel = 0
                        else
                            box.BoxFrame.BackgroundColor3 = color
                        end

                        local tag = tChar:FindFirstChild("LMM_NameTag")
                        if not tag then
                            tag = Instance.new("BillboardGui", tChar)
                            tag.Name = "LMM_NameTag"
                            tag.Adornee = hrp
                            tag.Size = UDim2.new(0, 140, 0, 30)
                            tag.StudsOffset = Vector3.new(0, 3.5, 0)
                            tag.AlwaysOnTop = true

                            local txt = Instance.new("TextLabel", tag)
                            txt.Name = "Txt"
                            txt.Size = UDim2.new(1, 0, 1, 0)
                            txt.BackgroundTransparency = 1
                            txt.Font = Enum.Font.GothamMedium
                            txt.TextSize = 12
                            txt.TextStrokeTransparency = 1
                        end
                        tag.Txt.Text = labelText .. " " .. p.Name
                        tag.Txt.TextColor3 = color
                    end
                end
            end

            -- 掉落枪支追踪 (GunDrop ESP)
            if _Config.GunDropESP then
                for _, obj in pairs(_WS:GetDescendants()) do
                    if obj.Name == "GunDrop" and (obj:IsA("BasePart") or obj:IsA("Model")) then
                        if not obj:FindFirstChild("LMM_GunESP") then
                            local gBb = Instance.new("BillboardGui", obj)
                            gBb.Name = "LMM_GunESP"
                            gBb.Adornee = obj
                            gBb.Size = UDim2.new(0, 140, 0, 35)
                            gBb.StudsOffset = Vector3.new(0, 1.5, 0)
                            gBb.AlwaysOnTop = true

                            local gTxt = Instance.new("TextLabel", gBb)
                            gTxt.Size = UDim2.new(1, 0, 1, 0)
                            gTxt.BackgroundTransparency = 1
                            gTxt.Font = Enum.Font.GothamMedium
                            gTxt.TextSize = 13
                            gTxt.TextColor3 = _Config.ColorGunDrop
                            gTxt.TextStrokeTransparency = 1
                            gTxt.Text = "⭐ 【掉落的枪】"

                            local hl = Instance.new("Highlight", obj)
                            hl.Name = "LMM_GunHighlight"
                            hl.FillColor = _Config.ColorGunDrop
                            hl.OutlineColor = Color3.new(1, 1, 1)
                            hl.FillTransparency = 0.3
                        end
                    end
                end
            end

            -- 万圣节糖果透视 (Candy ESP)
            if _Config.CandyESP and coinContainer then
                for _, coin in pairs(coinContainer:GetChildren()) do
                    if not coin:FindFirstChild("LMM_CandyESP") then
                        local targetPart = coin:IsA("BasePart") and coin or coin:FindFirstChildWhichIsA("BasePart")
                        if targetPart then
                            local cBb = Instance.new("BillboardGui", coin)
                            cBb.Name = "LMM_CandyESP"
                            cBb.Adornee = targetPart
                            cBb.Size = UDim2.new(0, 80, 0, 24)
                            cBb.StudsOffset = Vector3.new(0, 1.2, 0)
                            cBb.AlwaysOnTop = true

                            local cTxt = Instance.new("TextLabel", cBb)
                            cTxt.Size = UDim2.new(1, 0, 1, 0)
                            cTxt.BackgroundTransparency = 1
                            cTxt.Font = Enum.Font.GothamBold
                            cTxt.TextSize = 11
                            cTxt.TextColor3 = _Config.ColorCandy
                            cTxt.TextStrokeTransparency = 1
                            cTxt.Text = "🍬 糖果"
                        end
                    end
                end
            end

            -- 实时更新糖果统计面板数值
            local elapsedHours = (tick() - sessionStartTime) / 3600
            local candyPerHour = elapsedHours > 0 and math.floor(totalCandiesCollected / elapsedHours) or 0
            candyStatsText.Text = string.format(
                "🍬 糖果收益统计：\n• 累计已拿到：%d 个\n• 预计一小时赚取：%d 个/小时",
                totalCandiesCollected, candyPerHour
            )

            -- 智能自动挂机农夫 (Auto Farmer)
            if _Config.AutoFarmer and inRound then
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")

                if myHrp and myHum and myHum.Health > 0 then
                    local myRole, _, _ = GetMM2Role(_LP)
                    if myRole == "Innocent" or myRole == "Sheriff" then
                        if not innocentTeleported or myHrp.Position.Y < 450 then
                            TeleportToSafeSky(myHrp)
                            innocentTeleported = true
                        end
                    elseif myRole == "Murderer" then
                        local knife = EquipWeapon("Knife")
                        for _, p in pairs(_P:GetPlayers()) do
                            if p ~= _LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                                local tChar = p.Character
                                local tHrp = tChar.HumanoidRootPart
                                local tHum = tChar:FindFirstChildOfClass("Humanoid")
                                
                                if tHum and tHum.Health > 0 and tHrp.Position.Y < 300 then
                                    local role = GetMM2Role(p)
                                    if role ~= "Murderer" then
                                        myHrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.5)
                                        if knife then knife:Activate() end
                                        task.wait(0.2)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        task.wait(0.2)
    end
end)
