
loadstring(game:HttpGet('https://raw.githubusercontent.com/Kazamatcha/matcha.tea/refs/heads/main/key%20system'))()
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kazamatcha/matcha.tea/refs/heads/main/theme%20obdisian"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles
Library.ForceCheckbox = false 
Library.ShowToggleFrameInKeybinds = true
local Window = Library:CreateWindow({
	Title = "matcha.lol",
	Footer = "matcha.lol | Free",
	Icon = 77218680285262,
	NotifySide = "Left",
    Compact = true,
})
task.wait(1)
local isDaHood = (game.PlaceId == 2788229376)
local Tabs = { 
	Main = Window:AddTab('Main', 'swords'), 
    Character = Window:AddTab('Character', 'user'), 
	Visuals = Window:AddTab('Visuals', 'eye'), 
	Misc = Window:AddTab('Misc', 'ellipsis'), 
	Players = Window:AddTab('Players', 'user'), 
	['UI Settings'] = Window:AddTab('UI Settings', "settings") 
}
local GunMods = Tabs.Main:AddRightGroupbox('Gun Mods')
local KillAura = Tabs.Main:AddRightGroupbox('Combat')

game.Players.LocalPlayer.Character.Humanoid.Health = 0

local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

local LocalPlayer = game:GetService('Players').LocalPlayer
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local chatWindow = TextChatService:FindFirstChild("ChatWindowConfiguration")
local StatsService = game:GetService("Stats")
local VIM = game:GetService("VirtualInputManager")
getgenv().whitelist = {}
local lockedTarget = nil
local StickyAimEnabled = false
local HighlightEnabled = false
local TracerEnabled = false
local ViewTargetEnabled = false
local targetHitPart = "Head"
local targetToMouseTracer = true
local grabCheckEnabled = true
local koCheckEnabled = true
local friendCheckEnabled = false
getgenv().switchWhenDie = false
local stompTargetEnabled = false
local lastPosition = nil
local oldPosition = nil
local Core = nil
local BodyVelocity = nil
local PredicTvalue = 1
local hiddenBulletsEnabled = false
local AutoAmmoEnabled = false
local possibleRemotes = {
    "MAINEVENT",
    "MainEvent",
    "Remote",
    "Packages",
    "MainRemotes",
    "Bullets"
}  
getgenv().lastSDeath = {}
local tracer = Drawing.new("Line")
tracer.Visible = true
tracer.Thickness = 1
tracer.Color = Color3.fromRGB(255, 255, 255)
local desync_setback = Instance.new("Part")
desync_setback.Name = "Spoofer"
desync_setback.Parent = workspace
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1
local targetHighlight = Instance.new("Highlight")
targetHighlight.Name = "TargetHighlight"
targetHighlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
targetHighlight.FillColor = Color3.fromRGB(255, 0, 0)  -- Màu mặc định, sẽ thay đổi qua color picker
targetHighlight.OutlineColor = Color3.fromRGB(255, 255, 255)
targetHighlight.OutlineTransparency = 0
targetHighlight.FillTransparency = 0.5
targetHighlight.Parent = game.CoreGui  -- Để highlight hiển thị
AntiLock = {
    Enabled = false,
    Mode = "Custom",
    Custom = { X = 0, Y = 0, Z = 0 },
    Up = { Amount = 0 },
    Down = { Amount = 0 },
    VelMultiply = { Walk = 0, Jump = 0 },
    LookVec = { Amount = 0 },
    Reverse = { Amount = 0, Type = "CFrame" },
    Confusion = { Amount = 0 },
    PredBreaker = false
}
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
desync = {
    enabled = false,
    mode = "Void",
    teleportPosition = Vector3.new(0, 0, 0),
    old_position = nil,
    voidSpamActive = false,
    toggleEnabled = false
}
local function getMainRemote()
    if ReplicatedStorage:FindFirstChild("MainEvent") then
        return ReplicatedStorage.MainEvent
    end
    if ReplicatedStorage:FindFirstChild("MAINEVENT") then
        return ReplicatedStorage.MAINEVENT
    end

    if ReplicatedStorage:FindFirstChild("Remote") then
        return ReplicatedStorage.Remote
    end

    if ReplicatedStorage:FindFirstChild("Bullets") then
        return ReplicatedStorage.Bullets
    end

    -- 3. MainRemotes.MainRemoteEvent
    local mainRemotes = ReplicatedStorage:FindFirstChild("MainRemotes")
    if mainRemotes and mainRemotes:FindFirstChild("MainRemoteEvent") then
        return mainRemotes.MainRemoteEvent
    end

    -- 4. Packages.Knit.Services.ToolService.RE.UpdateAim
    local packages = ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local knit = packages:FindFirstChild("Knit")
        if knit and knit:FindFirstChild("Services") then
            local toolService = knit.Services:FindFirstChild("ToolService")
            if toolService and toolService:FindFirstChild("RE") then
                local re = toolService.RE
                if re:FindFirstChild("UpdateAim") then
                    return re.UpdateAim
                end
            end
        end
    end

    -- fallback: không tìm thấy
    return nil
end

-- Hàm equip tất cả tool có Ammo
function equipAllGuns()
    local player = game.Players.LocalPlayer
    local backpack = player:WaitForChild("Backpack")
    local char = player.Character or player.CharacterAdded:Wait()

    local equippedSomething = false

    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            tool.Parent = char
            equippedSomething = true
        end
    end

    if equippedSomething then
        Library:Notify("✅ Equipped all guns with Ammo")
    else
        Library:Notify("❌ No guns with Ammo found")
    end
end

-- Hàm unequip tất cả tool có Ammo
function unequipAllGuns()
    local player = game.Players.LocalPlayer
    local char = player.Character
    if not char then return end

    local unequippedSomething = false

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            tool.Parent = player.Backpack
            unequippedSomething = true
        end
    end

    if unequippedSomething then
        Library:Notify("🛑 Unequipped all guns")
    end
end
local MainRemote = getMainRemote()

function predictPosition(targetRoot, predictionMultiplier)
    if not targetRoot then return targetRoot.Position end
    if targetRoot.Velocity.Magnitude > 700 then
        return targetRoot.Position
    end
    return targetRoot.Position + (targetRoot.Velocity * predictionMultiplier)
end
local function selectClosestTarget()
    local camera = workspace.CurrentCamera
    local mouseLocation = UserInputService:GetMouseLocation()
    local closestTarget, closestDistance = nil, math.huge

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer ~= LocalPlayer 
            and otherPlayer.Character 
            and otherPlayer.Character:FindFirstChild(targetHitPart) 
            and not table.find(getgenv().whitelist, otherPlayer.Name) then

            local bodyEffects = otherPlayer.Character:FindFirstChild("BodyEffects")
            local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
            local isGrabbed = otherPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")

            if (not grabCheckEnabled or not isGrabbed) 
                and (not friendCheckEnabled or not LocalPlayer:IsFriendsWith(otherPlayer.UserId)) then

                local targetPart = otherPlayer.Character[targetHitPart]
                local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - mouseLocation).Magnitude
                    if distance < closestDistance then
                        closestTarget = otherPlayer
                        closestDistance = distance
                    end
                end
            end
        end
    end

    if closestTarget then
        lockedTarget = closestTarget
        Library:Notify("Locked: " .. closestTarget.DisplayName, 2)
        return true
    end
    return false
end
local TargetingGroup = Tabs.Main:AddLeftGroupbox('Targeting')

TargetingGroup:AddToggle("StickyAim", {
    Text = "Sticky Aim",
    Default = false,
    Tooltip = "Enable or disable sticky aim functionality",
    Callback = function(Value)
        StickyAimEnabled = Value
        if not Value then
            lockedTarget = nil
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
            tracer.Visible = false
            targetHighlight.Adornee = nil  -- Xóa highlight khi tắt
        end
        -- Cập nhật visibility ImageButton nếu mobile
        if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
            Sigmaballs:FindFirstChild("ImageButton").Visible = Value
        end
    end
}):AddKeyPicker("StickyAimKeybind", {
    Default = "Q",
    NoUI = false,
    Text = "Sticky Aim",
    Mode = "Toggle",
    SyncToggleState = false,
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if StickyAimEnabled then
            if lockedTarget then
                lockedTarget = nil
                workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
                tracer.Visible = false
                targetHighlight.Adornee = nil  -- Xóa highlight khi unlock
                Library:Notify("Sticky Aim: Unlocked", 2)
            else
                selectClosestTarget()
            end
        end
    end
})

-- Nút Switch khi target chết
TargetingGroup:AddToggle("SwitchWhenDie", {
    Text = "Switch When Target Die",
    Default = false,
    Tooltip = "Automatically select new target when current target dies",
    Callback = function(Value)
        getgenv().switchWhenDie = Value
    end
})

TargetingGroup:AddToggle("TracerToggle", {
    Text = "Draw Tracer",
    Default = false,
    Callback = function(Value)
        TracerEnabled = Value
        if not Value then
            tracer.Visible = false
        end
    end
}):AddColorPicker('HitboxColorPicker', {
    Text = '',
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        tracer.Color = color
    end,
})

TargetingGroup:AddDropdown("TracerMode", {
    Text = "Tracer Mode",
    Values = {"Mouse", "HumanoidRootPart"},
    Default = "Mouse",
    Callback = function(Value)
        targetToMouseTracer = (Value == "Mouse")
    end
})
TargetingGroup:AddToggle("HighlightToggle", {
    Text = "Highlight Target",
    Default = false,
    Callback = function(Value)
        HighlightEnabled = Value
        if not Value then
            targetHighlight.Adornee = nil
        end
    end
}):AddColorPicker('HighlightColorPicker', {
    Text = '',
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        targetHighlight.FillColor = color
    end,
}):AddColorPicker('HighlightOutlineColorPicker', {   -- <-- THÊM DÒNG NÀY
    Text = '',
    Default = Color3.fromRGB(255, 255, 255),        -- Màu viền mặc định (trắng)
    Callback = function(color)
        targetHighlight.OutlineColor = color
    end,
})
local function autoStompTarget()
    if getgenv().stompTargetEnabled and lockedTarget and lockedTarget ~= LocalPlayer then
        local character = lockedTarget.Character
        if character then
            local bodyEffects = character:FindFirstChild("BodyEffects")
            if bodyEffects then
                local isKO = bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                local isSDeath = bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value
                
                if isKO and not isSDeath then
                    local upperTorso = character:FindFirstChild("UpperTorso")
                    if upperTorso then
                        if not getgenv().lastPosition then
                            getgenv().lastPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                        end
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))
                        MainRemote:FireServer("Stomp")
                    end
                elseif isSDeath and getgenv().lastPosition then
                    LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().lastPosition
                    getgenv().lastPosition = nil
                end
            end
        end
    end
end
local Target = Tabs.Main:AddLeftGroupbox('Target')
Target:AddToggle("StompTargetToggle", {
    Text = "Auto Stomp Target",
    Default = false,
    Callback = function(Value)
        getgenv().stompTargetEnabled = Value
        if Value then
            if not stompConnection then
                stompConnection = RunService.RenderStepped:Connect(autoStompTarget)
            end
        else
            if stompConnection then
                stompConnection:Disconnect()
                stompConnection = nil
            end
            if getgenv().lastPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().lastPosition
                getgenv().lastPosition = nil
            end
        end
    end
})

Target:AddToggle("killsay", { 
    Text = "Kill Say", 
    Default = false,
    Callback = function(Value)
        killSayEnabled = Value
    end
})
vhuyplsnomad = false

TargetingGroup:AddToggle("ViewTarget", {
    Text = "spectate",
    Default = false,
    Callback = function(Value)
        vhuyplsnomad = Value
        if not Value then
            ViewTargetEnabled = false
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
}):AddKeyPicker("ViewTargetKeybind", {
    Default = "B",
    NoUI = false,
    Text = "spectate",
    Mode = "Toggle",
    Callback = function()
        if not vhuyplsnomad or UserInputService:GetFocusedTextBox() then return end
        ViewTargetEnabled = not ViewTargetEnabled
        if ViewTargetEnabled and lockedTarget then
            workspace.CurrentCamera.CameraSubject = lockedTarget.Character
        else
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        end
    end
})

TargetingGroup:AddDropdown("hp", {
    Text = "Hit Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"},
    Default = "Head",
    Callback = function(Value)
        targetHitPart = Value
    end
})
local silentAimFakeEnabled = false
local targetLockEnabled = false
local fovEnabled = false
local fovColor = Color3.fromRGB(255, 255, 255)
local fovSize = 100
local currentTarget = nil
local isMobile = UserInputService.TouchEnabled

local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 100
fovCircle.Radius = fovSize
fovCircle.Visible = false
fovCircle.Color = fovColor
fovCircle.Filled = false
fovCircle.Transparency = 1
fovCircle.Position = Vector2.new(0, 0)

local function getClosestPlayer(checkFOV)
    local camera = workspace.CurrentCamera
    local pos = isMobile and (camera.ViewportSize / 2) or UserInputService:GetMouseLocation()
    local closest, closestDist = nil, math.huge

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") and not table.find(getgenv().whitelist, player.Name) then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - pos).Magnitude
                if checkFOV and fovEnabled and dist > fovSize then continue end

                -- Check for obstacles/walls
                local rayParams = RaycastParams.new()
                rayParams.FilterType = Enum.RaycastFilterType.Exclude
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                local ray = workspace:Raycast(camera.CFrame.Position, (head.Position - camera.CFrame.Position), rayParams)
                if ray and ray.Instance:IsDescendantOf(player.Character) then
                    if dist < closestDist then
                        closestDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if fovEnabled then
        local pos = isMobile and (workspace.CurrentCamera.ViewportSize / 2) or UserInputService:GetMouseLocation()
        fovCircle.Position = pos
        fovCircle.Radius = fovSize
    end
    
    if targetLockEnabled then return end
    if silentAimFakeEnabled then
        local newTarget = getClosestPlayer(true)
        if newTarget then
            currentTarget = newTarget
        else
            currentTarget = nil
        end
    end
end)

local isFiring2 = false

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        if currentTarget then
            isFiring2 = true
            task.spawn(function()
                while isFiring2 and currentTarget do
                    local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
                    if tool and tool:FindFirstChild("Handle") and currentTarget.Character and currentTarget.Character:FindFirstChild("Head") then
                        MainRemote:FireServer(
                            "ShootGun",
                            tool.Handle,
                            tool.Handle.CFrame.Position,
                            currentTarget.Character.Head.Position,
                            currentTarget.Character.Head,
                            Vector3.new(0, 0, -1)
                        )
                    end
                    task.wait()
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isFiring2 = false
    end
end)
local FakeSilentAim = Tabs.Main:AddLeftGroupbox('Fake Silent Aim for bad executor')

FakeSilentAim:AddToggle('SilentAimToggle', {
    Text = 'Silent Aim',
    Default = false,
    Callback = function(Value)
        silentAimFakeEnabled = Value
        if not Value then
            currentTarget = nil
        end
    end
})
FakeSilentAim:AddToggle('TargetLockToggle', {
    Text = 'Target Lock',
    Default = false,
    Callback = function(Value)
        targetLockEnabled = Value
        if not Value then
            currentTarget = nil
        end
    end
}):AddKeyPicker('TargetLockKeybind', {
    Default = 'Q',
    NoUI = false,
    Text = 'Target Lock',
    Mode = 'Toggle',
    SyncToggleState = false,
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if targetLockEnabled then
            if currentTarget then
                currentTarget = nil
                Library:Notify("Untargeted", 2)
            else
                currentTarget = getClosestPlayer(false)
                if currentTarget then
                    Library:Notify("Locked: " .. currentTarget.DisplayName, 2)
                end
            end
        end
    end
})

FakeSilentAim:AddToggle('FOVToggle', {
    Text = 'FOV',
    Default = false,
    Callback = function(Value)
        fovEnabled = Value
        fovCircle.Visible = Value
    end
}):AddColorPicker('FOVColorPicker', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        fovColor = color
        fovCircle.Color = color
    end
})

FakeSilentAim:AddSlider('FOVSizeSlider', {
    Text = 'FOV Size',
    Default = 100,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        fovSize = Value
    end
})

TargetingGroup:AddToggle("HiddenBullets", {
    Text = "invisible bullets",
    Default = false,
    Callback = function(Value)
        hiddenBulletsEnabled = Value
    end
})

TargetingGroup:AddToggle("AutoAmmo", {
    Text = "Auto Ammo",
    Default = false,
    Callback = function(Value)
        AutoAmmoEnabled = Value
    end
})

local function getCurrentGun()
    local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return nil
end

local function getAmmoCount(gunName)
    local inventory = LocalPlayer.DataFolder.Inventory
    local ammo = inventory:FindFirstChild(gunName)
    if ammo then
        return tonumber(ammo.Value) or 0
    end
    return 0
end

local function buyAmmo(gunName)
    local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
    local AmmoMap = {
        ["[Revolver]"] = "12 [Revolver Ammo] - $55",
        ["[AUG]"] = "90 [AUG Ammo] - $87",
        ["[LMG]"] = "200 [LMG Ammo] - $328",
        ["[Rifle]"] = "5 [Rifle Ammo] - $273",
    }

    local ammoItemName = AmmoMap[gunName]
    if not ammoItemName then return end

    local ammoItem = ShopFolder:FindFirstChild(ammoItemName)
    if not ammoItem then return end

    local oldPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
    local currentTool = LocalPlayer.Character:FindFirstChildOfClass("Tool")

    if currentTool then
        currentTool.Parent = LocalPlayer.Backpack
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = ammoItem.Head.CFrame * CFrame.new(0, 3.2, 0)

    local clickDetector = ammoItem:FindFirstChild("ClickDetector")
    if clickDetector then
        for i = 1, 5 do
            fireclickdetector(clickDetector)
            task.wait(0)
        end
    end

    if currentTool then
        currentTool.Parent = LocalPlayer.Character
    end

    LocalPlayer.Character.HumanoidRootPart.CFrame = oldPosition
end

local function checkAmmoAndBuy()
    if not AutoAmmoEnabled then return end

    local gunName = getCurrentGun()
    if not gunName then return end

    local ammoCount = getAmmoCount(gunName)
    if ammoCount <= 0 then
        if Core then
            Core:Destroy()
            Core = nil
        end
        if BodyVelocity then
            BodyVelocity:Destroy()
            BodyVelocity = nil
        end

        buyAmmo(gunName)

    end
end

getgenv().hitsounds = {
    ["Bubble"] = "rbxassetid://6534947588",
    ["Lazer"] = "rbxassetid://130791043",
    ["Pick"] = "rbxassetid://1347140027",
    ["Pop"] = "rbxassetid://198598793",
    ["Rust"] = "rbxassetid://1255040462",
    ["Sans"] = "rbxassetid://3188795283",
    ["Fart"] = "rbxassetid://130833677",
    ["Big"] = "rbxassetid://5332005053",
    ["Vine"] = "rbxassetid://5332680810",
    ["UwU"] = "rbxassetid://8679659744",
    ["Bruh"] = "rbxassetid://4578740568",
    ["Skeet"] = "rbxassetid://5633695679",
    ["Neverlose"] = "rbxassetid://6534948092",
    ["Fatality"] = "rbxassetid://6534947869",
    ["Bonk"] = "rbxassetid://5766898159",
    ["Minecraft"] = "rbxassetid://5869422451",
    ["Gamesense"] = "rbxassetid://4817809188",
    ["RIFK7"] = "rbxassetid://9102080552",
    ["Bamboo"] = "rbxassetid://3769434519",
    ["Crowbar"] = "rbxassetid://546410481",
    ["Weeb"] = "rbxassetid://6442965016",
    ["Beep"] = "rbxassetid://8177256015",
    ["Bambi"] = "rbxassetid://8437203821",
    ["Stone"] = "rbxassetid://3581383408",
    ["Old Fatality"] = "rbxassetid://6607142036",
    ["Click"] = "rbxassetid://8053704437",
    ["Ding"] = "rbxassetid://7149516994",
    ["Snow"] = "rbxassetid://6455527632",
    ["Laser"] = "rbxassetid://7837461331",
    ["Mario"] = "rbxassetid://2815207981",
    ["Steve"] = "rbxassetid://4965083997",
    ["Call of Duty"] = "rbxassetid://5952120301",
    ["Bat"] = "rbxassetid://3333907347",
    ["TF2 Critical"] = "rbxassetid://296102734",
    ["Saber"] = "rbxassetid://8415678813",
    ["Baimware"] = "rbxassetid://3124331820",
    ["Osu"] = "rbxassetid://7149255551",
    ["TF2"] = "rbxassetid://2868331684",
    ["Slime"] = "rbxassetid://6916371803",
    ["Among Us"] = "rbxassetid://5700183626",
    ["One"] = "rbxassetid://7380502345"
}
getgenv().selectedHitsound = "Bubble"
getgenv().hitsoundEnabled = false
getgenv().hitsoundVolume = 1

function playHitsound()
    if getgenv().hitsoundEnabled then
        local sound = Instance.new("Sound")
        sound.SoundId = getgenv().hitsounds[getgenv().selectedHitsound]
        sound.Volume = getgenv().hitsoundVolume
        sound.Parent = workspace
        sound:Play()
        sound.Ended:Connect(function()
            sound:Destroy()
        end)
    end
end

GunMods:AddToggle('hstoggle', {
    Text = 'Hitsounds',
    Default = false,
    Tooltip = 'Enable or disable hitsounds for combat',
    Callback = function(state)
        getgenv().hitsoundEnabled = state
    end,
    Disabled = false,
    Visible = true
})

GunMods:AddDropdown('hs', {
    Text = 'Select Hitsound',
    Values = {"Bubble", "Lazer", "Pick", "Pop", "Rust", "Sans", "Fart", "Big", "Vine", "UwU", "Bruh", "Skeet", "Neverlose", "Fatality", "Bonk", "Minecraft", "Gamesense", "RIFK7", "Bamboo", "Crowbar", "Weeb", "Beep", "Bambi", "Stone", "Old Fatality", "Click", "Ding", "Snow", "Laser", "Mario", "Steve", "Call of Duty", "Bat", "TF2 Critical", "Saber", "Baimware", "Osu", "TF2", "Slime", "Among Us", "One"},
    Default = "Bubble",
    Tooltip = 'Select a hitsound to play on hit',
    Searchable = true, -- Thêm để hỗ trợ tìm kiếm với danh sách dài
    Multi = false,
    Callback = function(value)
        getgenv().selectedHitsound = value
    end,
    Disabled = false,
    Visible = true
})

GunMods:AddSlider('hsvolume', {
    Text = 'Volume',
    Default = 1,
    Min = 1,
    Max = 5,
    Rounding = 2,
    Tooltip = 'Adjust the volume of hitsounds',
    Compact = false,
    HideMax = false,
    Callback = function(value)
        getgenv().hitsoundVolume = value
    end,
    Disabled = false,
    Visible = true
})
RunService.RenderStepped:Connect(function()
    checkAmmoAndBuy()
    
    if lockedTarget and lockedTarget.Character then 
        local targetPart = lockedTarget.Character:FindFirstChild(targetHitPart)
        local bodyEffects = lockedTarget.Character:FindFirstChild("BodyEffects")
        local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
        local isGrabbed = lockedTarget.Character:FindFirstChild("GRABBING_CONSTRAINT")
        

        local bodyEffects = lockedTarget.Character:FindFirstChild("BodyEffects")
        local isSDeath = bodyEffects and bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value
        
        if not getgenv().lastSDeath[lockedTarget.Name] then
            getgenv().lastSDeath[lockedTarget.Name] = false
        end
        
        if killSayEnabled and isSDeath and not getgenv().lastSDeath[lockedTarget.Name] then
            local randomMessage = killSayMessages[math.random(1, #killSayMessages)]
            local textChannels = TextChatService:FindFirstChild("TextChannels")
            if textChannels then
                local generalChannel = textChannels:FindFirstChild("RBXGeneral")
                if generalChannel then
                    generalChannel:SendAsync(randomMessage)
                end
            end
        end
        
        getgenv().lastSDeath[lockedTarget.Name] = isSDeath
        
        -- Hitsound check
        local humanoid = lockedTarget.Character:FindFirstChild("Humanoid")
        if humanoid then
            if not getgenv().lastHealth[lockedTarget.Name] then
                getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
            end
            if humanoid.Health < getgenv().lastHealth[lockedTarget.Name] then
                playHitsound()
            end
            getgenv().lastHealth[lockedTarget.Name] = humanoid.Health
        end
        
        -- Tracer (chỉ set Visible nếu bật và có điều kiện, tránh lặp true/false)
        if TracerEnabled and targetPart and StickyAimEnabled then
            tracer.Visible = true
            local camera = workspace.CurrentCamera
            local targetScreenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            local endScreenPos
            if targetToMouseTracer then
                endScreenPos = UserInputService:GetMouseLocation()
            else
                local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    local rootScreenPos, rootOnScreen = camera:WorldToViewportPoint(rootPart.Position)
                    if rootOnScreen then
                        endScreenPos = Vector2.new(rootScreenPos.X, rootScreenPos.Y)
                    end
                end
            end
            if onScreen and endScreenPos then
                tracer.From = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                tracer.To = endScreenPos
            else
                tracer.Visible = false
            end
        else
            tracer.Visible = false
        end
        
        -- Bắn
        local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
        local handle = tool and tool:FindFirstChild("Handle")
        if tool and handle and targetPart then
            if hiddenBulletsEnabled then
                MainRemote:FireServer(
                    "ShootGun",
                    handle,
                    handle.CFrame.Position - Vector3.new(0, 10, 0),
                    targetPart.Position - Vector3.new(0, 10, 0),
                    targetPart,
                    Vector3.new(0, 0, -1))
            else
                MainRemote:FireServer(
                    "ShootGun",
                    handle,
                    handle.CFrame.Position,
                    targetPart.Position,
                    targetPart,
                    Vector3.new(0, 0, -1))
            end
        end
    else
        if oldPosition then
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = oldPosition
            end
            oldPosition = nil
        end
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        tracer.Visible = false
        if getgenv().switchWhenDie and StickyAimEnabled and lockedTarget and lockedTarget.Character then
            local bodyEffects = lockedTarget.Character:FindFirstChild("BodyEffects")
            local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
            local isSDeath = bodyEffects and bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value
            if (isKO or isSDeath) and lockedTarget.Character:FindFirstChild("Humanoid").Health <= 0 then
                lockedTarget = nil
                selectClosestTarget()
            end
        end
    end
end)
local killSayEnabled = false
local killSayMessages = {
    "matcha.lol is a free script and u die to it..", 
    "Must be hard without matcha.lol 💔", 
    "Why aim when matcha.lol does it for you?",
    "Bros not on matcha.lol already 😂",
    "Cant be me icl",
    "hey come on if u cant win get matcha.lol",
    "how to win a hvh? step 1 get matcha.lol"
}

local StarterGui = game:GetService("StarterGui")
RapidFireEnabled = false
RapidFireDelay = 0
local hyperFireEnabled = false
local utility = {}
utility.get_gun = function()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in next, char:GetChildren() do
        if tool:IsA("Tool") and (tool:FindFirstChild("Ammo") or tool:FindFirstChild("AmmoCount") or tool:FindFirstChild("GunScript")) then
            return tool
        end
    end
end

utility.rapid = function(tool)
    tool:Activate()
end

local isFiring = false

-- Input bắt đầu (chuột hoặc cảm ứng)
UserInputService.InputBegan:Connect(function(i, gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        local gun = utility.get_gun()
        if RapidFireEnabled and gun and not isFiring then
            isFiring = true
            task.spawn(function()
                while isFiring and RapidFireEnabled do
                    utility.rapid(gun)
                    task.wait(RapidFireDelay)
                end
            end)
        end
    end
end)

-- Input kết thúc (chuột hoặc cảm ứng)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        isFiring = false
    end
end)
getgenv().EquipAllGun = false
GunMods:AddToggle('EquipAllGun', {
    Text = 'Equip All Gun',
    Default = false,
    Callback = function(state)
        getgenv().EquipAllGun = state

        if state then
            equipAllGuns()
        else
            unequipAllGuns()
        end
    end
}):AddKeyPicker("EquipAllGunKeyPicker", {
    Default = "H",
    Text = "EquipAllGunKey",
    Mode = "Toggle",
    Callback = function(state)
        getgenv().EquipAllGun = state

        if state then
            equipAllGuns()
        else
            unequipAllGuns()
        end
    end
})
GunMods:AddToggle("RapidFireToggle", {
    Text = "Rapid Fire",
    Default = false,
    Callback = function(Value)
        RapidFireEnabled = Value
    end
})

local function updateHyperFire()
    for _, obj in ipairs(game:GetDescendants()) do
        if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
            obj.Value = 0 
        end
    end
end

GunMods:AddToggle("HyperFireToggle", {
    Text = "Rapid Fire v2",
    Default = false,
    Callback = function(Value)
        hyperFireEnabled = Value
        updateHyperFire()
    end
})

game.DescendantAdded:Connect(function(obj)
    if obj.Name == "ToleranceCooldown" and obj:IsA("ValueBase") then
        obj.Value = hyperFireEnabled and 0 or 3
    end
end)

RunService.RenderStepped:Connect(function()
    if hyperFireEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        local character = LocalPlayer.Character
        if character then
            local tool = character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                tool:Activate()
            end
        end
    end
end)

local HBE = Tabs.Main:AddRightGroupbox('HBE')

local size = 10
local hitboxColor = Color3.new(0, 1, 1)
local visualizeHitbox = false
local hitboxExpanderEnabled = false
local Client = game.Players.LocalPlayer

HBE:AddToggle('HitboxExpanderToggle', {
    Text = 'Hitbox Expander',
    Default = false,
    Callback = function(state)
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end,
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "L",
    Text = "Hitbox",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        hitboxExpanderEnabled = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    resetCharacter(Player.Character)
                end
            end
        end
    end
})

HBE:AddSlider('HitboxSizeSlider', {
    Text = 'Hitbox Size',
    Default = 10,
    Min = 10,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        size = value
    end,
})

HBE:AddToggle('VisualizerToggle', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        visualizeHitbox = state
        if not state then
            for _, Player in pairs(Players:GetPlayers()) do
                if Player ~= Client and Player.Character then
                    removeVisuals(Player.Character)
                end
            end
        end
    end,
}):AddColorPicker('HitboxColorPicker', {
    Text = 'Hitbox Color',
    Default = Color3.new(0, 1, 1),
    Callback = function(color)
        hitboxColor = color
    end,
})

local function removeVisuals(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if outline then outline:Destroy() end
        local glow = HRP:FindFirstChild("HitboxGlow")
        if glow then glow:Destroy() end
    end
end

local function resetCharacter(Character)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        -- Reset HRP size to default (2, 1, 2)
        HRP.Size = Vector3.new(2, 1, 2)
        HRP.Transparency = 1
        HRP.CanCollide = true
        removeVisuals(Character)
    end
end

local function handleCharacter(Character)
    if not Character or not hitboxExpanderEnabled then
        resetCharacter(Character)
        return
    end
    local HRP = Character:FindFirstChild("HumanoidRootPart") or Character:WaitForChild("HumanoidRootPart", 5)
    if not HRP then return end

    HRP.Size = Vector3.new(size, size, size)
    HRP.Transparency = 1
    HRP.CanCollide = false

    if visualizeHitbox then
        local outline = HRP:FindFirstChild("HitboxOutline")
        if not outline then
            outline = Instance.new("BoxHandleAdornment")
            outline.Name = "HitboxOutline"
            outline.Adornee = HRP
            outline.Size = HRP.Size
            outline.Transparency = 0.8
            outline.ZIndex = 10
            outline.AlwaysOnTop = true
            outline.Color3 = hitboxColor
            outline.Parent = HRP

            local glow = Instance.new("BoxHandleAdornment")
            glow.Name = "HitboxGlow"
            glow.Adornee = HRP
            glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
            glow.Transparency = 0.9
            glow.ZIndex = 9
            glow.AlwaysOnTop = true
            glow.Color3 = hitboxColor
            glow.Parent = HRP
        else
            outline.Size = HRP.Size
            outline.Color3 = hitboxColor
            local glow = HRP:FindFirstChild("HitboxGlow")
            if glow then
                glow.Size = HRP.Size + Vector3.new(0.1, 0.1, 0.1)
                glow.Color3 = hitboxColor
            end
        end
    else
        removeVisuals(Character)
    end
end

local function handlePlayer(Player)
    if Player == Client then return end
    Player.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("HumanoidRootPart")
        handleCharacter(Character)
    end)
    if Player.Character then
        handleCharacter(Player.Character)
    end
end

for _, Player in pairs(Players:GetPlayers()) do
    handlePlayer(Player)
end

Players.PlayerAdded:Connect(handlePlayer)

RunService.Heartbeat:Connect(function()
    if not hitboxExpanderEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= Client and Player.Character then
                resetCharacter(Player.Character)
            end
        end
        return
    end
    for _, Player in pairs(Players:GetPlayers()) do
        if Player ~= Client and Player.Character then
            handleCharacter(Player.Character)
        end
    end
end)
local LegitBox = Tabs.Main:AddRightTabbox()
local Camlock = LegitBox:AddTab("Camlock")
local SilentAim = LegitBox:AddTab("SilentAim")
local Triggerbot = LegitBox:AddTab("Triggerbot")

-- ===== CAMLOCK TAB (SỬA SMOOTH + JUMP OFFSET THÀNH INPUT) =====
local camlockEnabled = false
local camlockFOVVisible = false
local camlockFOVSize = 150
local camlockSmooth = 1
local camlockAimPart = "Head"
local camlockJumpOffset = 0
local camlockFOVColor = Color3.fromRGB(255, 255, 255)
local camlockOutlineColor = Color3.fromRGB(255, 0, 0)

-- FOV Circle
local camlockFOVCircle = Drawing.new("Circle")
camlockFOVCircle.Thickness = 1
camlockFOVCircle.NumSides = 100
camlockFOVCircle.Radius = camlockFOVSize
camlockFOVCircle.Visible = false
camlockFOVCircle.Color = camlockFOVColor
camlockFOVCircle.Filled = false
camlockFOVCircle.Transparency = 1

-- Outline Circle
local camlockOutlineCircle = Drawing.new("Circle")
camlockOutlineCircle.Thickness = 2
camlockOutlineCircle.NumSides = 100
camlockOutlineCircle.Radius = camlockFOVSize + 1
camlockOutlineCircle.Visible = false
camlockOutlineCircle.Color = camlockOutlineColor
camlockOutlineCircle.Filled = false
camlockOutlineCircle.Transparency = 1

-- isAlive function
local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local be = plr.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        local grabbed = plr.Character:FindFirstChild("GRABBING_CONSTRAINT")
        if (ko and ko.Value) or grabbed then return false end
    end
    return true
end

-- Toggle + Keybind
Camlock:AddToggle("CamlockToggle", {
    Text = "Camlock",
    Default = false,
    Callback = function(Value)
        camlockEnabled = Value
    end
})

-- FOV Visible + 2 ColorPicker
Camlock:AddToggle("CamlockFOVToggle", {
    Text = "FOV Visible",
    Default = false,
    Callback = function(Value)
        camlockFOVVisible = Value
        camlockFOVCircle.Visible = Value
        camlockOutlineCircle.Visible = Value
    end
}):AddColorPicker("CamlockFOVColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        camlockFOVColor = color
        camlockFOVCircle.Color = color
    end
}):AddColorPicker("CamlockOutlineColor", {
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        camlockOutlineColor = color
        camlockOutlineCircle.Color = color
    end
})

-- FOV Size Slider
Camlock:AddSlider("CamlockFOVSize", {
    Text = "FOV Size",
    Default = 150,
    Min = 1,
    Max = 1000,
    Rounding = 0,
    Callback = function(Value)
        camlockFOVSize = Value
        camlockFOVCircle.Radius = Value
        camlockOutlineCircle.Radius = Value + 1
    end
})

-- Smooth → Input (thay Slider)
Camlock:AddInput("CamlockSmoothInput", {
    Default = "1",
    Numeric = true,
    Finished = true,
    Text = "Smooth",
    Placeholder = "0.01 - 1.00",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 and num <= 1 then
            camlockSmooth = num
        else
            Options.CamlockSmoothInput:SetValue(tostring(camlockSmooth))
        end
    end
})

-- Jump Offset → Input
Camlock:AddInput("CamlockJumpOffsetInput", {
    Default = "0",
    Numeric = true,
    Finished = true,
    Text = "Jump Offset",
    Placeholder = "0 - 50",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 and num <= 50 then
            camlockJumpOffset = num
        else
            Options.CamlockJumpOffsetInput:SetValue(tostring(camlockJumpOffset))
        end
    end
})

-- Aim Part Dropdown
Camlock:AddDropdown("CamlockAimPart", {
    Text = "Aim Part",
    Values = {"Head", "HumanoidRootPart"},
    Default = "Head",
    Callback = function(Value)
        camlockAimPart = Value
    end
})

RunService.RenderStepped:Connect(function()
    -- Cập nhật FOV
    if camlockFOVVisible then
        local mousePos = UserInputService:GetMouseLocation()
        camlockFOVCircle.Position = mousePos
        camlockOutlineCircle.Position = mousePos
    end

    if camlockEnabled and lockedTarget and isAlive(lockedTarget) then
        local targetPart = lockedTarget.Character:FindFirstChild(camlockAimPart == "HumanoidRootPart" and "HumanoidRootPart" or "Head")
        if targetPart then
            local camera = workspace.CurrentCamera
            local mousePos = UserInputService:GetMouseLocation()
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
            
            -- CHECK FOV: Nếu target KHÔNG trong FOV thì bỏ qua
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if dist > camlockFOVSize then
                    return  -- Không aim nếu ngoài FOV
                end
            else
                return  -- Không aim nếu ngoài màn hình
            end

            local targetPos = targetPart.Position
            
            -- Jump offset
            local humanoid = lockedTarget.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                targetPos += Vector3.new(0, camlockJumpOffset, 0)
            end

            local targetCFrame = CFrame.lookAt(camera.CFrame.Position, targetPos)
            camera.CFrame = camera.CFrame:lerp(targetCFrame, camlockSmooth)
        end
    end
end)


-- Check metatable hook support
local mtSupport = pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local old = mt.__index
    mt.__index = old  -- Test restore
    setreadonly(mt, true)
end)

if not mtSupport then
    Library:Notify("Your executor does not support Silent Aim", 5)
    SilentAim:AddLabel("Your executor does not support Silent Aim")
else
    local silentAimEnabled = false
    local silentPrediction = 0
    local silentHitPart = "Head"
    local silentFOVEnabled = false
    local silentFOVSize = 100
    local silentFOVColor = Color3.fromRGB(255, 255, 255)
    local silentOutlineColor = Color3.fromRGB(255, 0, 0)
    local silentMousePos = Vector2.new()
    local silentWallCheck = false
    local silentJumpOffset = 0
    local useAirPart = false
    local silentAirPart = "Head"
    -- FOV Circles
    local silentFOVCircle = Drawing.new("Circle")
    silentFOVCircle.Thickness = 1
    silentFOVCircle.NumSides = 100
    silentFOVCircle.Radius = silentFOVSize
    silentFOVCircle.Visible = false
    silentFOVCircle.Color = silentFOVColor
    silentFOVCircle.Filled = false
    silentFOVCircle.Transparency = 1
    local silentOutlineCircle = Drawing.new("Circle")
    silentOutlineCircle.Thickness = 2
    silentOutlineCircle.NumSides = 100
    silentOutlineCircle.Radius = silentFOVSize + 1
    silentOutlineCircle.Visible = false
    silentOutlineCircle.Color = silentOutlineColor
    silentOutlineCircle.Filled = false
    silentOutlineCircle.Transparency = 1
    local function isADS()
        local lp = LocalPlayer
        if lp.Character then
            local tool = lp.Character:FindFirstChildOfClass("Tool")
            if tool and tool:FindFirstChild("Ammo") then return true end
        end
        local pg = lp:FindFirstChildOfClass("PlayerGui")
        if pg then
            local aim = pg:FindFirstChild("Aim")
            if aim and aim.Visible then return true end
        end
        local mouse = lp:GetMouse()
        if mouse and mouse.Icon == "rbxasset://SystemCursors/Cross" then return true end
        return false
    end
    -- Get aim pos
    local function getAimPos()
        if UserInputService.TouchEnabled then
            return Vector2.new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
        end
        return UserInputService:GetMouseLocation()
    end
    local function getClosestTarget()
        local camera = workspace.CurrentCamera
        local aimPos = getAimPos()
        local closest, closestDist = nil, math.huge
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and isAlive(plr) and not table.find(getgenv().whitelist, plr.Name) then
                local partName = silentHitPart == "Torso" and "UpperTorso" or silentHitPart
                local targetPart = plr.Character:FindFirstChild(partName)
                if targetPart then
                    local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPos).Magnitude
                       
                        -- WALL CHECK
                        local visible = true
                        if silentWallCheck then
                            local rayParams = RaycastParams.new()
                            rayParams.FilterType = Enum.RaycastFilterType.Exclude
                            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                            local ray = workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, rayParams)
                            if ray and not ray.Instance:IsDescendantOf(plr.Character) then
                                visible = false
                            end
                        end
                       
                        if visible and (not silentFOVEnabled or dist <= silentFOVSize) then
                            if dist < closestDist then
                                closestDist = dist
                                closest = plr
                            end
                        end
                    end
                end
            end
        end
        return closest
    end
    -- UI chỉ load nếu support
    SilentAim:AddToggle("SilentAimToggle", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(Value)
            silentAimEnabled = Value
            if not Value then
                lockedTarget = nil
            end
        end
    })
    SilentAim:AddInput("SilentPredictionInput", {
        Default = "0",
        Numeric = true,
        Finished = true,
        Text = "Prediction",
        Placeholder = "0 - 0.2",
        Callback = function(Value)
            local num = tonumber(Value)
            if num and num >= 0 and num <= 0.2 then
                silentPrediction = num
            else
                Options.SilentPredictionInput:SetValue(tostring(silentPrediction))
            end
        end
    })
    SilentAim:AddDropdown("SilentHitPart", {
        Text = "Hit Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"},
        Default = "Head",
        Callback = function(Value)
            silentHitPart = Value
        end
    })
    SilentAim:AddToggle("SilentFOVToggle", {
        Text = "FOV Circle",
        Default = false,
        Callback = function(Value)
            silentFOVEnabled = Value
            silentFOVCircle.Visible = Value
            silentOutlineCircle.Visible = Value
        end
    }):AddColorPicker("SilentFOVColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(color)
            silentFOVColor = color
            silentFOVCircle.Color = color
        end
    }):AddColorPicker("SilentOutlineColor", {
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(color)
            silentOutlineColor = color
            silentOutlineCircle.Color = color
        end
    })
    SilentAim:AddSlider("SilentFOVSize", {
        Text = "FOV Size",
        Default = 100,
        Min = 1,
        Max = 1000,
        Rounding = 0,
        Callback = function(Value)
            silentFOVSize = Value
            silentFOVCircle.Radius = Value
            silentOutlineCircle.Radius = Value + 1
        end
    })
    SilentAim:AddToggle("SilentWallCheck", {
        Text = "Check Wall",
        Default = false,
        Callback = function(Value)
            silentWallCheck = Value
        end
    })
    SilentAim:AddInput("SilentJumpOffset", {
        Default = "0",
        Numeric = true,
        Finished = true,
        Text = "Jump Offset",
        Placeholder = "0 - 5",
        Callback = function(Value)
            silentJumpOffset = tonumber(Value) or 0
        end
    })
    SilentAim:AddToggle("UseAirPart", {
        Text = "Use Air Part",
        Default = false,
        Callback = function(Value)
            useAirPart = Value
        end
    })
    SilentAim:AddDropdown("SilentAirPart", {
        Text = "Air Hit Part",
        Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"},
        Default = "Head",
        Callback = function(Value)
            silentAirPart = Value
        end
    })
    -- Hook metatable
    local oldIndex
    local mouse = LocalPlayer:GetMouse()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    oldIndex = mt.__index
    mt.__index = newcclosure(function(self, idx)
        if silentAimEnabled and self == mouse and (idx == "Hit" or idx == "Target") and lockedTarget then
            local char = lockedTarget.Character
            if not char then return oldIndex(self, idx) end
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return oldIndex(self, idx) end
            local isTargetFreefall = hum:GetState() == Enum.HumanoidStateType.Freefall
            local localChar = LocalPlayer.Character
            local localHum = localChar and localChar:FindFirstChildOfClass("Humanoid")
            local isLocalFreefall = localHum and localHum:GetState() == Enum.HumanoidStateType.Freefall or false
            local freefall = isTargetFreefall or isLocalFreefall
            local currentHitPart = (freefall and useAirPart) and silentAirPart or silentHitPart
            local partName = currentHitPart == "Torso" and "UpperTorso" or currentHitPart
            local targetPart = char:FindFirstChild(partName)
            if not targetPart then return oldIndex(self, idx) end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return oldIndex(self, idx) end
            local predPos = targetPart.Position + root.Velocity * silentPrediction
            if freefall and silentJumpOffset ~= 0 then
                predPos = predPos + Vector3.new(0, silentJumpOffset, 0)
            end
            if idx == "Hit" then
                return CFrame.new(targetPart.Position, predPos)
            elseif idx == "Target" then
                return targetPart
            end
        end
        return oldIndex(self, idx)
    end)
    setreadonly(mt, true)
    -- Update loop
    RunService.Heartbeat:Connect(function()
        silentMousePos = getAimPos()
       
        -- Update FOV pos
        if silentFOVEnabled then
            silentFOVCircle.Position = silentMousePos
            silentOutlineCircle.Position = silentMousePos
        end
       
        -- Find target
        if not silentAimEnabled then return end
        lockedTarget = getClosestTarget()
    end)
end
pcall(function()
	local function isHoldingKnife()
	    local char = LocalPlayer.Character
	    if char then
	        local tool = char:FindFirstChildWhichIsA("Tool")
	        if tool and tool.Name:lower():find("knife") then return true end
	    end
	    return false
	end
	local function isKO(plr)
	    return not isAlive(plr)
	end
	local function canSeeThroughWall(origin, targetPart)
	    local direction = (targetPart.Position - origin).Unit * 1000
	    local rayParams = RaycastParams.new()
	    rayParams.FilterType = Enum.RaycastFilterType.Exclude
	    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	    local ray = workspace:Raycast(origin, direction, rayParams)
	    return not ray or ray.Instance:IsDescendantOf(targetPart.Parent)
	end
	-- ===== TRIGGERBOT TAB =====
	local triggerEnabled = false
	local triggerFOV = 20
	local triggerDelay = 0
	local triggerOnlyTarget = false
	local triggerChecks = {
	    Team = false,
	    Friend = false,
	    KO = true,
	    Grab = true,
	    Wall = true,
	    Knife = true
	}
	local HitParts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
	
	local function isValidTriggerTarget(plr)
	    if plr == LocalPlayer then return false end
	    if table.find(getgenv().whitelist or {}, plr.Name) then return false end
	    if triggerChecks.Team and plr.Team == LocalPlayer.Team then return false end
	    if triggerChecks.Friend and LocalPlayer:IsFriendsWith(plr.UserId) then return false end
	    if triggerChecks.KO and isKO(plr) then return false end
	    local be = plr.Character and plr.Character:FindFirstChild("BodyEffects")
	    if triggerChecks.Grab and be and be:FindFirstChild("GRABBING_CONSTRAINT") then return false end
	    if triggerChecks.Knife and isHoldingKnife() then return false end
	    return isAlive(plr)
	end
	
	local function distToCursor(part)
	    local camera = workspace.CurrentCamera
	    local v, vis = camera:WorldToViewportPoint(part.Position)
	    if not vis then return math.huge end
	    local m = UserInputService.TouchEnabled and Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2) or UserInputService:GetMouseLocation()
	    return (Vector2.new(v.X, v.Y) - m).Magnitude
	end
	
	local function toolActivate(tool)
	    pcall(function()
	        tool:Activate()
	        task.wait(triggerDelay)
	    end)
	end
	
	local function click()
	    if UserInputService.TouchEnabled then
	        local touchPos = UserInputService:GetMouseLocation()
	        game:GetService("VirtualInputManager"):SendTouchEvent(0, Enum.UserInputState.Begin, touchPos)
	        task.wait(triggerDelay)
	        game:GetService("VirtualInputManager"):SendTouchEvent(0, Enum.UserInputState.End, touchPos)
	    else
	        if mouse1press and mouse1release then
	            mouse1press()
	            task.wait(triggerDelay)
	            mouse1release()
	        else
	            local vim = game:GetService("VirtualInputManager")
	            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
	            task.wait(triggerDelay)
	            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
	        end
	    end
	end
	
	local function GetBestTargetPart()
	    local bestPart, bestDist = nil, triggerFOV
	    local playersToCheck = triggerOnlyTarget and lockedTarget and {lockedTarget} or Players:GetPlayers()
	    for _, plr in pairs(playersToCheck) do
	        if isValidTriggerTarget(plr) and plr.Character then
	            for _, partName in ipairs(HitParts) do
	                local part = plr.Character:FindFirstChild(partName)
	                if part and part:IsA("BasePart") then
	                    local dist = distToCursor(part)
	                    if dist < bestDist then
	                        bestDist = dist
	                        bestPart = part
	                    end
	                end
	            end
	        end
	    end
	    return bestPart
	end
	
	Triggerbot:AddToggle("TriggerbotToggle", {
	    Text = "Triggerbot",
	    Default = false,
	    Callback = function(Value)
	        triggerEnabled = Value
	    end
	}):AddKeyPicker("TriggerbotKeybind", {
	    Default = "V",
	    Text = "Triggerbot",
	    Mode = "Toggle",
	    Callback = function()
	        triggerEnabled = not triggerEnabled
	    end
	})
	
	Triggerbot:AddToggle("TriggerOnlyTarget", {
	    Text = "Only Target",
	    Default = false,
	    Callback = function(Value)
	        triggerOnlyTarget = Value
	    end
	})
	
	Triggerbot:AddSlider("TriggerFOV", {
	    Text = "FOV",
	    Default = 20,
	    Min = 1,
	    Max = 200,
	    Rounding = 0,
	    Callback = function(Value)
	        triggerFOV = Value
	    end
	})
	
	Triggerbot:AddSlider("TriggerDelay", {
	    Text = "Delay",
	    Default = 0,
	    Min = 0,
	    Max = 0.5,
	    Rounding = 2,
	    Callback = function(Value)
	        triggerDelay = Value
	    end
	})
	
	Triggerbot:AddDropdown("TriggerChecks", {
	    Text = "Checks",
	    Values = {"Team", "Friend", "KO", "Grab", "Wall", "Knife"},
	    Default = {"KO", "Grab", "Wall", "Knife"},
	    Multi = true,
	    Callback = function(Value)
	        -- Reset all
	        for k, _ in pairs(triggerChecks) do triggerChecks[k] = false end
	        -- Set selected
	        for _, v in ipairs(Value) do
	            triggerChecks[v] = true
	        end
	    end
	})
	
	-- Main Loop (giữ nguyên)
	RunService.RenderStepped:Connect(function()
	    if triggerEnabled then
	        local part = GetBestTargetPart()
	        if part and distToCursor(part) <= triggerFOV then
	            local camera = workspace.CurrentCamera
	            local origin = camera.CFrame.Position
	            local direction = (part.Position - origin)
	            local rayParams = RaycastParams.new()
	            rayParams.FilterType = Enum.RaycastFilterType.Exclude
	            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
	            local result = workspace:Raycast(origin, direction, rayParams)
	            
	            if not result or result.Instance:IsDescendantOf(part.Parent) then
	                local char = LocalPlayer.Character
	                local tool = char and char:FindFirstChildWhichIsA("Tool")
	                local ammo = tool and tool:FindFirstChild("Ammo")
	                if tool and ammo then
	                    task.spawn(function() toolActivate(tool) end)
	                else
	                    task.spawn(click)
	                end
	            end
	        end
	    end
	end)
end)
local function gettargetsticky()
    if lockedTarget then
        lockedTarget = nil
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character:FindFirstChild("Humanoid")
        targetHighlight.Enabled = true
        tracer.Visible = true
    else
        local camera = workspace.CurrentCamera
        local screenCenter = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2) -- Tâm màn hình
        local closestTarget, closestDistance = nil, math.huge

        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild(targetHitPart) and not table.find(getgenv().whitelist, otherPlayer.Name) then
                local bodyEffects = otherPlayer.Character:FindFirstChild("BodyEffects")
                local isKO = bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
                local isGrabbed = otherPlayer.Character:FindFirstChild("GRABBING_CONSTRAINT")

                if (not grabCheckEnabled or not isGrabbed) and
                   (not friendCheckEnabled or not LocalPlayer:IsFriendsWith(otherPlayer.UserId)) then

                    local targetPart = otherPlayer.Character[targetHitPart]
                    local screenPosition, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                    if onScreen then
                        -- Đo khoảng cách từ nhân vật đến tâm màn hình
                        local distance = (Vector2.new(screenPosition.X, screenPosition.Y) - screenCenter).Magnitude
                        if distance < closestDistance then
                            closestTarget = otherPlayer
                            closestDistance = distance
                        end
                    end
                end
            end
        end

        if closestTarget then
            lockedTarget = closestTarget
        end
    end
end

local Sigmaballs = Instance.new("ScreenGui")
Sigmaballs.Name = "Sigmaballs"
Sigmaballs.Parent = game.CoreGui
Sigmaballs.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Sigmaballs.ResetOnSpawn = false

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    local ImageButton = Instance.new("ImageButton")
    ImageButton.Name = "ImageButton"
    ImageButton.Parent = Sigmaballs
    ImageButton.Active = true
    ImageButton.Draggable = true
    ImageButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    ImageButton.BackgroundTransparency = 0.5
    ImageButton.Size = UDim2.new(0, 90, 0, 90)
    ImageButton.Image = "http://www.roblox.com/asset/?id=11351620343"
    ImageButton.Position = UDim2.new(0.5, -25, 0.5, -25)
    ImageButton.Visible = false  -- Ẩn mặc định
    local Ui2corner = Instance.new("UICorner")
    Ui2corner.CornerRadius = UDim.new(0.2, 0)
    Ui2corner.Parent = ImageButton
    ImageButton.MouseButton1Click:Connect(function()
        if StickyAimEnabled then
            gettargetsticky()
        end
    end)
end

getgenv().range = 250

getgenv().whitelist = {}

getgenv().tracer = Instance.new("Part")
getgenv().tracer.Size = Vector3.new(0.2, 0.2, 0.2)
getgenv().tracer.Material = Enum.Material.Neon
getgenv().tracer.Color = Color3.new(1, 0, 0)
getgenv().tracer.Transparency = 1
getgenv().tracer.Anchored = true
getgenv().tracer.CanCollide = false
getgenv().tracer.Parent = workspace

getgenv().enabled = false
getgenv().active = false
getgenv().visualizeEnabled = false
getgenv().silentEnabled = false
getgenv().lastHealth = {}

KillAura:AddToggle('MainToggle', {
    Text = 'Kill Aura',
    Default = false,
    Callback = function(state)
        getgenv().enabled = state
        if not state then
            getgenv().active = false
            getgenv().tracer.Transparency = 1
        end
    end
}):AddKeyPicker('Keybind', {
    Default = 'K',
    Text = 'kill aura',
    Mode = 'Toggle',
    Callback = function(state)
        if not getgenv().enabled or UserInputService:GetFocusedTextBox() then return end
        getgenv().active = state
    end
})

KillAura:AddSlider("Range", {
    Text = "Range",
    Default = 250,
    Min = 10,
    Max = 10000,
    Rounding = 1,
    Callback = function(value)
        getgenv().range = value
    end
})

KillAura:AddToggle('Visualizer', {
    Text = 'Visualize',
    Default = false,
    Callback = function(state)
        getgenv().visualizeEnabled = state
    end
}):AddColorPicker('VisualizerColor', {
    Text = 'Visualizer Color',
    Default = Color3.new(1, 0, 0),
    Callback = function(value)
        getgenv().tracer.Color = value
    end
})

KillAura:AddToggle('Silent', {
    Text = 'Silent',
    Default = false,
    Callback = function(state)
        getgenv().silentEnabled = state
    end
})

KillAura:AddInput('wlb', {
    Default = '',
    Numeric = false,
    Finished = false,
    Text = 'Add/Remove Player',
    Tooltip = 'Type a name or display name to add/remove from whitelist',
    Placeholder = 'Player Name',
    Callback = function(input)
        for _, player in pairs(game.Players:GetPlayers()) do
            if player.Name == input or player.DisplayName == input then
                if getgenv().whitelist[player.Name] then
                    getgenv().whitelist[player.Name] = nil
                    Library:Notify(player.Name .. " removed from whitelist.", 2)
                else
                    getgenv().whitelist[player.Name] = true
                    Library:Notify(player.Name .. " added to whitelist.", 2)
                end
                return
            end
        end
        Library:Notify("Player not found.", 2)
    end,
    Autocomplete = function(input)
        local suggestions = {}
        for _, player in pairs(game.Players:GetPlayers()) do
            if string.find(string.lower(player.Name), string.lower(input)) or string.find(string.lower(player.DisplayName), string.lower(input)) then
                table.insert(suggestions, player.Name .. " (" .. player.DisplayName .. ")")
            end
        end
        return suggestions
    end
})



task.spawn(function()
    while true do
        if getgenv().active and getgenv().enabled and game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool") and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle") then
            if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name) and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects:FindFirstChild("K.O") and workspace.Players:FindFirstChild(game.Players.LocalPlayer.Name).BodyEffects["K.O"].Value then
                task.wait()
            else
                local closest = math.huge
                target = nil

                for _, player in pairs(game.Players:GetPlayers()) do
                    if player ~= game.Players.LocalPlayer and not getgenv().whitelist[player.Name] and player.Character and player.Character:FindFirstChild("Head") and not player.Character:FindFirstChild("GRABBING_CONSTRAINT") then
                        if workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild(player.Name) and workspace.Players:FindFirstChild(player.Name):FindFirstChild("BodyEffects") and workspace.Players:FindFirstChild(player.Name).BodyEffects:FindFirstChild("K.O") and not workspace.Players:FindFirstChild(player.Name).BodyEffects["K.O"].Value then
                            local dist = (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - player.Character.Head.Position).Magnitude
                            if dist < closest and dist <= getgenv().range then
                                closest = dist
                                target = player
                            end
                        end
                    end
                end

                if target and target.Character and target.Character:FindFirstChild("Head") then
                    if getgenv().visualizeEnabled then
                        getgenv().tracer.Transparency = 0
                        getgenv().tracer.Size = Vector3.new(0.2, 0.2, (game.Players.LocalPlayer.Character.HumanoidRootPart.Position - target.Character.Head.Position).Magnitude)
                        getgenv().tracer.CFrame = CFrame.lookAt(game.Players.LocalPlayer.Character.HumanoidRootPart.Position, target.Character.Head.Position) * CFrame.new(0, 0, -getgenv().tracer.Size.Z / 2)
                    else
                        getgenv().tracer.Transparency = 1
                    end

                    local humanoid = target.Character:FindFirstChild("Humanoid")
                    if humanoid then
                        if not getgenv().lastHealth[target.Name] then
                            getgenv().lastHealth[target.Name] = humanoid.Health
                        end
                        if humanoid.Health < getgenv().lastHealth[target.Name] then
                            playHitsound()
                        end
                        getgenv().lastHealth[target.Name] = humanoid.Health
                    end

                    if getgenv().silentEnabled then
                        MainRemote:FireServer(
                            "ShootGun",
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"),
                            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position - Vector3.new(0, 12, 0),
                            target.Character.Head.Position - Vector3.new(0, 12, 0),
                            target.Character.Head,
                            Vector3.new(0, 0, -1)
                    )
                    else
                        MainRemote:FireServer("ShootGun", game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle"), game.Players.LocalPlayer.Character:FindFirstChildOfClass("Tool"):FindFirstChild("Handle").CFrame.Position, target.Character.Head.Position, target.Character.Head, Vector3.new(0, 0, -1))
                    end
                else
                    getgenv().tracer.Transparency = 1
                end
            end
        else
            getgenv().tracer.Transparency = 1
        end
        task.wait()
    end
end)

getgenv().espEnabled = false
getgenv().espColor = Color3.fromRGB(255, 255, 255)
getgenv().nameESPEnabled = false
getgenv().nameColor = Color3.fromRGB(255, 255, 255)
getgenv().nameDisplayMode = "DisplayName"
getgenv().nameTextSize = 14
getgenv().studsESPEnabled = false
getgenv().distanceColor = Color3.fromRGB(255, 255, 255)
getgenv().distanceTextSize = 14
getgenv().healthBarESP = false
getgenv().healthBarColor = Color3.fromRGB(0, 255, 0)
getgenv().healthBased = false  -- New: Health-based color toggle
getgenv().healthTextEnabled = false  -- New: Health text toggle
getgenv().healthTextColor = Color3.fromRGB(255, 255, 255)  -- New: Health text color
getgenv().weaponESPEnabled = false
getgenv().weaponColor = Color3.fromRGB(255, 255, 255)
getgenv().armorBarESP = false
getgenv().armorBarColor = Color3.fromRGB(0, 0, 255)
getgenv().outlineEnabled = false
getgenv().outlineColor = Color3.fromRGB(0, 0, 0)  -- New: Outline color (for thickness fix)
getgenv().penisESPEnabled = false
getgenv().penisColor = Color3.fromRGB(255, 0, 0)
getgenv().ESPSkeleton = false  -- New: Skeleton toggle
getgenv().ESPSkeletonColor = Color3.fromRGB(255, 255, 255)  -- New: Skeleton color
getgenv().headDotEnabled = false  -- New: Head dot toggle
getgenv().headDotColor = Color3.fromRGB(255, 0, 0)  -- New: Head dot color
getgenv().headDotSize = 5  -- New: Head dot size
getgenv().tracerEnabled = false  -- New: Tracer toggle
getgenv().tracerColor = Color3.fromRGB(255, 255, 255)  -- New: Tracer color
getgenv().ESPTracerType = "Cursor"  -- New: Tracer type
getgenv().espTransparency = 1  -- Transparency (add slider if needed)

-- Font mapping
local fontMap = {
    ["SourceSans"] = 0
}

-- ESP Objects storage
local ESPObjects = {}

-- Get the game's camera
local Camera = workspace.CurrentCamera

-- Function to destroy ESP for a player
local function DestroyESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if typeof(obj) == "table" then
                for _, subObj in pairs(obj) do
                    subObj:Remove()
                end
            else
                obj:Remove()
            end
        end
        ESPObjects[player] = nil
    end
end

-- Function to create ESP for a player
local function CreateESP(player)
    DestroyESP(player)
    
    local box = Drawing.new("Square")
    box.Thickness = 1
    box.Filled = false
    box.Color = getgenv().espColor
    box.Visible = false
    box.ZIndex = 1
    
    local boxOutline = Drawing.new("Square")
    boxOutline.Thickness = 3
    boxOutline.Filled = false
    boxOutline.Color = getgenv().outlineColor
    boxOutline.Visible = false
    boxOutline.ZIndex = 0
    
    local username = Drawing.new("Text")
    username.Size = getgenv().nameTextSize
    username.Center = true
    username.Color = getgenv().nameColor
    username.Visible = false
    username.Font = fontMap["SourceSans"]
    username.Outline = true
    username.OutlineColor = getgenv().outlineColor
    
    local distance = Drawing.new("Text")
    distance.Size = getgenv().distanceTextSize
    distance.Center = true
    distance.Color = getgenv().distanceColor
    distance.Visible = false
    distance.Font = fontMap["SourceSans"]
    distance.Outline = true
    distance.OutlineColor = getgenv().outlineColor
    
    local healthBar = Drawing.new("Square")
    healthBar.Thickness = 1
    healthBar.Filled = true
    healthBar.Color = getgenv().healthBarColor
    healthBar.Visible = false
    healthBar.ZIndex = 1
    
    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Thickness = 3
    healthBarOutline.Filled = false
    healthBarOutline.Color = getgenv().outlineColor
    healthBarOutline.Visible = false
    healthBarOutline.ZIndex = 0
    
    local healthText = Drawing.new("Text")  -- New: Health text
    healthText.Size = 12
    healthText.Center = true
    healthText.Color = getgenv().healthTextColor
    healthText.Visible = false
    healthText.Font = fontMap["SourceSans"]
    healthText.Outline = true
    healthText.OutlineColor = getgenv().outlineColor
    
    local weapon = Drawing.new("Text")
    weapon.Size = getgenv().nameTextSize
    weapon.Center = true
    weapon.Color = getgenv().weaponColor
    weapon.Visible = false
    weapon.Font = fontMap["SourceSans"]
    weapon.Outline = true
    weapon.OutlineColor = getgenv().outlineColor
    
    local armorBar = Drawing.new("Square")
    armorBar.Thickness = 1
    armorBar.Filled = true
    armorBar.Color = getgenv().armorBarColor
    armorBar.Visible = false
    armorBar.ZIndex = 1
    
    local armorBarOutline = Drawing.new("Square")
    armorBarOutline.Thickness = 3
    armorBarOutline.Filled = false
    armorBarOutline.Color = getgenv().outlineColor
    armorBarOutline.Visible = false
    armorBarOutline.ZIndex = 0
    
    local penisLine = Drawing.new("Line")
    penisLine.Thickness = 2
    penisLine.Color = getgenv().penisColor
    penisLine.Visible = false
    penisLine.ZIndex = 1
    
    local skeletonLines = {}  -- New: Skeleton lines
    for i = 1, 14 do
        local line = Drawing.new("Line")
        line.Thickness = 1
        line.Color = getgenv().ESPSkeletonColor
        line.Visible = false
        skeletonLines[i] = line
    end
    
    local headDot = Drawing.new("Circle") 
    headDot.Filled = false
    headDot.Radius = getgenv().headDotSize
    headDot.Color = getgenv().headDotColor
    headDot.Visible = false
    headDot.ZIndex = 2
    
    local tracer = Drawing.new("Line")  -- New: Tracer
    tracer.Thickness = 1
    tracer.Color = getgenv().tracerColor
    tracer.Visible = false
    tracer.ZIndex = 1
    
    local tracerOutline = Drawing.new("Line")  -- New: Tracer outline
    tracerOutline.Thickness = 3
    tracerOutline.Color = getgenv().outlineColor
    tracerOutline.Visible = false
    tracerOutline.ZIndex = 0
    
    ESPObjects[player] = {
        Box = box,
        BoxOutline = boxOutline,
        Username = username,
        Distance = distance,
        HealthBar = healthBar,
        HealthBarOutline = healthBarOutline,
        HealthText = healthText,  -- New
        Weapon = weapon,
        ArmorBar = armorBar,
        ArmorBarOutline = armorBarOutline,
        PenisLine = penisLine,
        SkeletonLines = skeletonLines,  -- New
        HeadDot = headDot,  -- New
        Tracer = tracer,  -- New
        TracerOutline = tracerOutline  -- New
    }
end

-- Function to update ESP
local function UpdateESP()
    for player, objects in pairs(ESPObjects) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") and player ~= LocalPlayer and getgenv().espEnabled then
            local rootPart = character.HumanoidRootPart
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local rootPosition, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local headPart = character:FindFirstChild("Head")
                local headPosition = headPart and Camera:WorldToViewportPoint(headPart.Position) or rootPosition
                local footPosition = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
                if onScreen then
                    local boxHeight = math.abs(headPosition.Y - footPosition.Y)
                    local boxWidth = boxHeight / 2
                    
                    -- Box ESP
                    objects.Box.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                    objects.Box.Size = Vector2.new(boxWidth, boxHeight)
                    objects.Box.Color = getgenv().espColor
                    objects.Box.Transparency = getgenv().espTransparency
                    objects.Box.Visible = true
                    
                    -- Box Outline
                    objects.BoxOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2, headPosition.Y)
                    objects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
                    objects.BoxOutline.Color = getgenv().outlineColor
                    objects.BoxOutline.Transparency = getgenv().espTransparency
                    objects.BoxOutline.Visible = getgenv().outlineEnabled
                    
                    -- Name ESP (Above the box)
                    if getgenv().nameESPEnabled then
                        local displayName
                        if getgenv().nameDisplayMode == "Username" then
                            displayName = player.Name
                        elseif getgenv().nameDisplayMode == "DisplayName" then
                            displayName = player.DisplayName
                        elseif getgenv().nameDisplayMode == "Username (DisplayName)" then
                            displayName = player.Name .. " (" .. player.DisplayName .. ")"
                        elseif getgenv().nameDisplayMode == "Username (DisplayName) [UserID]" then
                            displayName = player.Name .. " (" .. player.DisplayName .. ") [" .. player.UserId .. "]"
                        end
                        objects.Username.Position = Vector2.new(rootPosition.X, headPosition.Y - 15)
                        objects.Username.Text = displayName
                        objects.Username.Size = getgenv().nameTextSize
                        objects.Username.Font = fontMap["SourceSans"]
                        objects.Username.Color = getgenv().nameColor
                        objects.Username.Transparency = getgenv().espTransparency
                        objects.Username.Visible = true
                        objects.Username.OutlineColor = getgenv().outlineColor
                    else
                        objects.Username.Visible = false
                    end
                    
                    -- Distance ESP (Below the box)
                    if getgenv().studsESPEnabled then
                        local distanceText = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - rootPart.Position).Magnitude) .. " studs"
                        objects.Distance.Position = Vector2.new(rootPosition.X, footPosition.Y + 5)
                        objects.Distance.Text = distanceText
                        objects.Distance.Size = getgenv().distanceTextSize
                        objects.Distance.Font = fontMap["SourceSans"]
                        objects.Distance.Color = getgenv().distanceColor
                        objects.Distance.Transparency = getgenv().espTransparency
                        objects.Distance.Visible = true
                        objects.Distance.OutlineColor = getgenv().outlineColor
                    else
                        objects.Distance.Visible = false
                    end
                    
                    -- Health Bar ESP
                    if getgenv().healthBarESP and humanoid then
                        local healthRatio = humanoid.Health / humanoid.MaxHealth
                        local barHeight = boxHeight * healthRatio
                        local barPositionY = headPosition.Y + (boxHeight - barHeight)
                        
                        -- Health Bar (inline/fill)
                        objects.HealthBar.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, barPositionY)
                        objects.HealthBar.Size = Vector2.new(3, barHeight)
                        objects.HealthBar.Color = getgenv().healthBased and Color3.new(1 - healthRatio, healthRatio, 0) or getgenv().healthBarColor
                        objects.HealthBar.Transparency = getgenv().espTransparency
                        objects.HealthBar.Visible = true
                        
                        -- Health Bar Outline
                        objects.HealthBarOutline.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6, headPosition.Y)
                        objects.HealthBarOutline.Size = Vector2.new(3, boxHeight)
                        objects.HealthBarOutline.Color = getgenv().outlineColor
                        objects.HealthBarOutline.Transparency = getgenv().espTransparency
                        objects.HealthBarOutline.Visible = getgenv().outlineEnabled
                        
                        -- Health Text
                        if getgenv().healthTextEnabled then
                            objects.HealthText.Text = tostring(math.floor(humanoid.Health))
                            objects.HealthText.Position = Vector2.new(rootPosition.X - boxWidth / 2 - 6 - objects.HealthText.TextBounds.X / 2, barPositionY - objects.HealthText.Size / 2)
                            objects.HealthText.Color = getgenv().healthTextColor
                            objects.HealthText.Transparency = getgenv().espTransparency
                            objects.HealthText.Visible = true
                            objects.HealthText.OutlineColor = getgenv().outlineColor
                        else
                            objects.HealthText.Visible = false
                        end
                    else
                        objects.HealthBar.Visible = false
                        objects.HealthBarOutline.Visible = false
                        objects.HealthText.Visible = false
                    end
                    
                    -- Weapon ESP
                    if getgenv().weaponESPEnabled then
                        local tool = character:FindFirstChildOfClass("Tool")
                        if tool then
                            objects.Weapon.Position = Vector2.new(rootPosition.X, footPosition.Y + 20)
                            objects.Weapon.Text = tool.Name
                            objects.Weapon.Size = getgenv().nameTextSize
                            objects.Weapon.Font = fontMap["SourceSans"]
                            objects.Weapon.Color = getgenv().weaponColor
                            objects.Weapon.Transparency = getgenv().espTransparency
                            objects.Weapon.Visible = true
                            objects.Weapon.OutlineColor = getgenv().outlineColor
                        else
                            objects.Weapon.Visible = false
                        end
                    else
                        objects.Weapon.Visible = false
                    end
                    
                    -- Armor Bar ESP
                    if getgenv().armorBarESP then
                        local dataFolder = player:FindFirstChild("DataFolder")
                        if dataFolder then
                            local information = dataFolder:FindFirstChild("Information")
                            if information then
                                local armorSave = information:FindFirstChild("ArmorSave")
                                if armorSave then
                                    local armorRatio = armorSave.Value / 130  -- Adjust max if needed
                                    local armorHeight = boxHeight * armorRatio
                                    local armorPositionY = headPosition.Y + (boxHeight - armorHeight)
                                    
                                    objects.ArmorBar.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, armorPositionY)
                                    objects.ArmorBar.Size = Vector2.new(3, armorHeight)
                                    objects.ArmorBar.Color = getgenv().armorBarColor
                                    objects.ArmorBar.Transparency = getgenv().espTransparency
                                    objects.ArmorBar.Visible = true
                                    
                                    objects.ArmorBarOutline.Position = Vector2.new(rootPosition.X + boxWidth / 2 + 3, headPosition.Y)
                                    objects.ArmorBarOutline.Size = Vector2.new(3, boxHeight)
                                    objects.ArmorBarOutline.Color = getgenv().outlineColor
                                    objects.ArmorBarOutline.Transparency = getgenv().espTransparency
                                    objects.ArmorBarOutline.Visible = getgenv().outlineEnabled
                                else
                                    objects.ArmorBar.Visible = false
                                    objects.ArmorBarOutline.Visible = false
                                end
                            else
                                objects.ArmorBar.Visible = false
                                objects.ArmorBarOutline.Visible = false
                            end
                        else
                            objects.ArmorBar.Visible = false
                            objects.ArmorBarOutline.Visible = false
                        end
                    else
                        objects.ArmorBar.Visible = false
                        objects.ArmorBarOutline.Visible = false
                    end
                    
                    -- Penis ESP
                    if getgenv().penisESPEnabled then
                        local pelvis = character:FindFirstChild("Head")
                        if pelvis then
                            local pelvisPosition, pelvisOnScreen = Camera:WorldToViewportPoint(pelvis.Position)
                            local lookVector = rootPart.CFrame.LookVector
                            local penisEndPosition, penisEndOnScreen = Camera:WorldToViewportPoint(pelvis.Position + lookVector * 2)
                            if pelvisOnScreen and penisEndOnScreen then
                                objects.PenisLine.From = Vector2.new(pelvisPosition.X, pelvisPosition.Y)
                                objects.PenisLine.To = Vector2.new(penisEndPosition.X, penisEndPosition.Y)
                                objects.PenisLine.Color = getgenv().penisColor
                                objects.PenisLine.Transparency = getgenv().espTransparency
                                objects.PenisLine.Visible = true
                            else
                                objects.PenisLine.Visible = false
                            end
                        else
                            objects.PenisLine.Visible = false
                        end
                    else
                        objects.PenisLine.Visible = false
                    end
                    
                    -- Skeleton ESP (New)
                    if getgenv().ESPSkeleton then
                        local parts = {
                            head = character:FindFirstChild("Head"),
                            upper_torso = character:FindFirstChild("UpperTorso"),
                            lower_torso = character:FindFirstChild("LowerTorso"),
                            left_upper_arm = character:FindFirstChild("LeftUpperArm"),
                            left_lower_arm = character:FindFirstChild("LeftLowerArm"),
                            left_hand = character:FindFirstChild("LeftHand"),
                            right_upper_arm = character:FindFirstChild("RightUpperArm"),
                            right_lower_arm = character:FindFirstChild("RightLowerArm"),
                            right_hand = character:FindFirstChild("RightHand"),
                            left_upper_leg = character:FindFirstChild("LeftUpperLeg"),
                            left_lower_leg = character:FindFirstChild("LeftLowerLeg"),
                            left_foot = character:FindFirstChild("LeftFoot"),
                            right_upper_leg = character:FindFirstChild("RightUpperLeg"),
                            right_lower_leg = character:FindFirstChild("RightLowerLeg"),
                            right_foot = character:FindFirstChild("RightFoot")
                        }
                        if parts.head and parts.upper_torso and parts.lower_torso and parts.left_upper_arm and parts.left_lower_arm and parts.left_hand and parts.right_upper_arm and parts.right_lower_arm and parts.right_hand and parts.left_upper_leg and parts.left_lower_leg and parts.left_foot and parts.right_upper_leg and parts.right_lower_leg and parts.right_foot then
                            local connections = {
                                {parts.head, parts.upper_torso, 1},
                                {parts.upper_torso, parts.lower_torso, 2},
                                {parts.upper_torso, parts.left_upper_arm, 3},
                                {parts.left_upper_arm, parts.left_lower_arm, 4},
                                {parts.left_lower_arm, parts.left_hand, 5},
                                {parts.upper_torso, parts.right_upper_arm, 6},
                                {parts.right_upper_arm, parts.right_lower_arm, 7},
                                {parts.right_upper_arm, parts.right_hand, 8},
                                {parts.lower_torso, parts.left_upper_leg, 9},
                                {parts.left_upper_leg, parts.left_lower_leg, 10},
                                {parts.left_lower_leg, parts.left_foot, 11},
                                {parts.lower_torso, parts.right_upper_leg, 12},
                                {parts.right_upper_leg, parts.right_lower_leg, 13},
                                {parts.right_lower_leg, parts.right_foot, 14}
                            }
                            for _, conn in ipairs(connections) do
                                local from_pos, from_on_screen = Camera:WorldToViewportPoint(conn[1].Position)
                                local to_pos, to_on_screen = Camera:WorldToViewportPoint(conn[2].Position)
                                if from_on_screen and to_on_screen then
                                    objects.SkeletonLines[conn[3]].From = Vector2.new(from_pos.X, from_pos.Y)
                                    objects.SkeletonLines[conn[3]].To = Vector2.new(to_pos.X, to_pos.Y)
                                    objects.SkeletonLines[conn[3]].Color = getgenv().ESPSkeletonColor
                                    objects.SkeletonLines[conn[3]].Transparency = getgenv().espTransparency
                                    objects.SkeletonLines[conn[3]].Visible = true
                                else
                                    objects.SkeletonLines[conn[3]].Visible = false
                                end
                            end
                        else
                            for _, line in ipairs(objects.SkeletonLines) do line.Visible = false end
                        end
                    else
                        for _, line in ipairs(objects.SkeletonLines) do line.Visible = false end
                    end
                    
                    -- Head Dot ESP (New)
                    if getgenv().headDotEnabled and headPart then
                        local headPos, headOnScreen = Camera:WorldToViewportPoint(headPart.Position)
                        if headOnScreen then
                            objects.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
                            objects.HeadDot.Radius = getgenv().headDotSize
                            objects.HeadDot.Color = getgenv().headDotColor
                            objects.HeadDot.Transparency = getgenv().espTransparency
                            objects.HeadDot.Visible = true
                        else
                            objects.HeadDot.Visible = false
                        end
                    else
                        objects.HeadDot.Visible = false
                    end
                    
                    -- Tracer ESP (New)
                    if getgenv().tracerEnabled then
                        local from_pos
                        if getgenv().ESPTracerType == "Cursor" then
                            from_pos = UserInputService:GetMouseLocation()
                        elseif getgenv().ESPTracerType == "Bottom Screen" then
                            from_pos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        elseif getgenv().ESPTracerType == "Top Screen" then
                            from_pos = Vector2.new(Camera.ViewportSize.X / 2, 0)
                        end
                        local to_pos = Vector2.new(rootPosition.X, footPosition.Y + boxHeight / 2)  -- To center or foot
                        objects.Tracer.From = from_pos
                        objects.Tracer.To = to_pos
                        objects.Tracer.Color = getgenv().tracerColor
                        objects.Tracer.Transparency = getgenv().espTransparency
                        objects.Tracer.Visible = true
                        
                        -- Tracer Outline
                        objects.TracerOutline.From = from_pos
                        objects.TracerOutline.To = to_pos
                        objects.TracerOutline.Color = getgenv().outlineColor
                        objects.TracerOutline.Transparency = getgenv().espTransparency
                        objects.TracerOutline.Visible = getgenv().outlineEnabled
                    else
                        objects.Tracer.Visible = false
                        objects.TracerOutline.Visible = false
                    end
                else
                    -- Hide all if off-screen or dead
                    objects.Box.Visible = false
                    objects.BoxOutline.Visible = false
                    objects.Username.Visible = false
                    objects.Distance.Visible = false
                    objects.HealthBar.Visible = false
                    objects.HealthBarOutline.Visible = false
                    objects.HealthText.Visible = false
                    objects.Weapon.Visible = false
                    objects.ArmorBar.Visible = false
                    objects.ArmorBarOutline.Visible = false
                    objects.PenisLine.Visible = false
                    for _, line in ipairs(objects.SkeletonLines) do line.Visible = false end
                    objects.HeadDot.Visible = false
                    objects.Tracer.Visible = false
                    objects.TracerOutline.Visible = false
                end
            end
        end
    end
end

-- Function to apply ESP settings (optional, call on toggle changes)
local function applyESP()
    for _, objects in pairs(ESPObjects) do
        objects.Box.Visible = getgenv().espEnabled
        objects.BoxOutline.Visible = getgenv().outlineEnabled and getgenv().espEnabled
        -- Apply to others similarly if needed
    end
end

-- Player Added/Removed Events
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        CreateESP(player)
    end)
end)
Players.PlayerRemoving:Connect(DestroyESP)

-- Initialize ESP for existing players
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESP(player)
    end
end

-- Update ESP on every frame
RunService.RenderStepped:Connect(UpdateESP)

local ESPGroup = Tabs.Visuals:AddLeftGroupbox('ESP')

ESPGroup:AddToggle('ESPEnabled', {
    Text = 'Enable ESP',
    Default = false,
    Callback = function(Value)
        getgenv().espEnabled = Value
        applyESP()
    end
}):AddColorPicker('ESPColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().espColor = color
    end
})

ESPGroup:AddToggle('NameESP', {
    Text = 'Name ESP',
    Default = false,
    Callback = function(Value)
        getgenv().nameESPEnabled = Value
    end
}):AddColorPicker('NameColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().nameColor = color
    end
})

ESPGroup:AddDropdown('NameMode', {
    Text = 'Name Mode',
    Values = {"Username", "DisplayName", "Username (DisplayName)", "Username (DisplayName) [UserID]"},
    Default = "DisplayName",
    Callback = function(Value)
        getgenv().nameDisplayMode = Value
    end
})

ESPGroup:AddSlider('NameSize', {
    Text = 'Name Size',
    Min = 10,
    Max = 20,
    Default = 14,
    Callback = function(Value)
        getgenv().nameTextSize = Value
    end
})

ESPGroup:AddToggle('StudsESP', {
    Text = 'Distance ESP',
    Default = false,
    Callback = function(Value)
        getgenv().studsESPEnabled = Value
    end
}):AddColorPicker('DistanceColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().distanceColor = color
    end
})

ESPGroup:AddSlider('DistanceSize', {
    Text = 'Distance Size',
    Min = 10,
    Max = 20,
    Default = 14,
    Callback = function(Value)
        getgenv().distanceTextSize = Value
    end
})

ESPGroup:AddToggle('HealthBarESP', {
    Text = 'Health Bar ESP',
    Default = false,
    Callback = function(Value)
        getgenv().healthBarESP = Value
    end
}):AddColorPicker('HealthBarColor', {
    Default = Color3.fromRGB(0, 255, 0),
    Callback = function(color)
        getgenv().healthBarColor = color
    end
})

ESPGroup:AddToggle('HealthBased', {
    Text = 'Health Based Color',
    Default = false,
    Callback = function(Value)
        getgenv().healthBased = Value
    end
})

ESPGroup:AddToggle('HealthTextESP', {
    Text = 'Health Text ESP',
    Default = false,
    Callback = function(Value)
        getgenv().healthTextEnabled = Value
    end
}):AddColorPicker('HealthTextColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().healthTextColor = color
    end
})

ESPGroup:AddToggle('WeaponESP', {
    Text = 'Weapon ESP',
    Default = false,
    Callback = function(Value)
        getgenv().weaponESPEnabled = Value
    end
}):AddColorPicker('WeaponColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().weaponColor = color
    end
})

ESPGroup:AddToggle('ArmorBarESP', {
    Text = 'Armor Bar ESP',
    Default = false,
    Callback = function(Value)
        getgenv().armorBarESP = Value
    end
}):AddColorPicker('ArmorBarColor', {
    Default = Color3.fromRGB(0, 0, 255),
    Callback = function(color)
        getgenv().armorBarColor = color
    end
})

ESPGroup:AddToggle('OutlineEnabled', {
    Text = 'Outline ESP',
    Default = false,
    Callback = function(Value)
        getgenv().outlineEnabled = Value
        applyESP()
    end
}):AddColorPicker('OutlineColor', {
    Default = Color3.fromRGB(0, 0, 0),
    Callback = function(color)
        getgenv().outlineColor = color
    end
})

ESPGroup:AddToggle('PenisESP', {
    Text = 'Penis ESP',
    Default = false,
    Callback = function(Value)
        getgenv().penisESPEnabled = Value
    end
}):AddColorPicker('PenisColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        getgenv().penisColor = color
    end
})

ESPGroup:AddToggle('ESPSkeleton', {
    Text = 'Skeleton ESP',
    Default = false,
    Callback = function(Value)
        getgenv().ESPSkeleton = Value
    end
}):AddColorPicker('ESPSkeletonColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().ESPSkeletonColor = color
    end
})

ESPGroup:AddToggle('HeadDotEnabled', {
    Text = 'Head Dot ESP',
    Default = false,
    Callback = function(Value)
        getgenv().headDotEnabled = Value
    end
}):AddColorPicker('HeadDotColor', {
    Default = Color3.fromRGB(255, 0, 0),
    Callback = function(color)
        getgenv().headDotColor = color
    end
})

ESPGroup:AddSlider('HeadDotSize', {
    Text = 'Head Dot Size',
    Min = 1,
    Max = 20,
    Default = 5,
    Callback = function(Value)
        getgenv().headDotSize = Value
    end
})

ESPGroup:AddToggle('TracerEnabled', {
    Text = 'Tracer ESP',
    Default = false,
    Callback = function(Value)
        getgenv().tracerEnabled = Value
    end
}):AddColorPicker('TracerColor', {
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(color)
        getgenv().tracerColor = color
    end
})

ESPGroup:AddDropdown('TracerType', {
    Text = 'Tracer Type',
    Values = {"Cursor", "Bottom Screen", "Top Screen"},
    Default = "Cursor",
    Callback = function(Value)
        getgenv().ESPTracerType = Value
    end
})

local HudUi = Tabs.Visuals:AddLeftGroupbox('Hud Changer')

local defaultTextHP = " Health "
local defaultTextArmor = "                   Armor"
local defaultTextEnergy = "Dark Energy              "

local defaultColorHP = Color3.new(1, 1, 1)
local defaultColorArmor = Color3.new(1, 0.701960784, 0.729411765)
local defaultColorEnergy = Color3.new(0.878431373, 0.439215686, 0.478431373)

local textHP, textArmor, textEnergy = defaultTextHP, defaultTextArmor, defaultTextEnergy
local colorHP, colorArmor, colorEnergy = defaultColorHP, defaultColorArmor, defaultColorEnergy

local toggleHP, toggleArmor, toggleEnergy = false, false, false

local function skibiditoilet()
    local player = game.Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    local gui = playerGui:WaitForChild("MainScreenGui").Bar

    if toggleHP then
        gui.HP.TextLabel.Text = textHP
        gui.HP.bar.BackgroundColor3 = colorHP
    end

    if toggleArmor then
        gui.Armor.TextLabel.Text = textArmor
        gui.Armor.bar.BackgroundColor3 = colorArmor
    end

    if toggleEnergy then
        gui.Energy.TextLabel.Text = textEnergy
        gui.Energy.bar.BackgroundColor3 = colorEnergy
    end
end

HudUi:AddToggle('ToggleHP', {
    Text = 'Customize Health',
    Default = false,
    Callback = function(state)
        toggleHP = state
        skibiditoilet()
    end
}):AddColorPicker('ColorHP', {
    Text = 'Health Color',
    Default = defaultColorHP,
    Callback = function(value)
        if toggleHP then colorHP = value skibiditoilet() end
    end
})

HudUi:AddInput('TextHP', {
    Text = 'Health Text',
    Default = defaultTextHP,
    Callback = function(value)
        if toggleHP then textHP = value skibiditoilet() end
    end
})

HudUi:AddToggle('ToggleArmor', {
    Text = 'Customize Armor',
    Default = false,
    Callback = function(state)
        toggleArmor = state
        skibiditoilet()
    end
}):AddColorPicker('ColorArmor', {
    Text = 'Armor Color',
    Default = defaultColorArmor,
    Callback = function(value)
        if toggleArmor then colorArmor = value skibiditoilet() end
    end
})

HudUi:AddInput('TextArmor', {
    Text = 'Armor Text',
    Default = defaultTextArmor,
    Callback = function(value)
        if toggleArmor then textArmor = value skibiditoilet() end
    end
})

HudUi:AddToggle('ToggleEnergy', {
    Text = 'Customize Energy',
    Default = false,
    Callback = function(state)
        toggleEnergy = state
        skibiditoilet()
    end
}):AddColorPicker('ColorEnergy', {
    Text = 'Energy Color',
    Default = defaultColorEnergy,
    Callback = function(value)
        if toggleEnergy then colorEnergy = value skibiditoilet() end
    end
})

HudUi:AddInput('TextEnergy', {
    Text = 'Energy Text',
    Default = defaultTextEnergy,
    Callback = function(value)
        if toggleEnergy then textEnergy = value skibiditoilet() end
    end
})

local player = game.Players.LocalPlayer

player.CharacterAdded:Connect(function()
    if toggleHP or toggleArmor or toggleEnergy then
        player:WaitForChild("PlayerGui")
        skibiditoilet()
    end
end)

local player = Players.LocalPlayer

local Auras = Tabs.Visuals:AddRightGroupbox("Self")
utility = utility or {}

local Settings = {
    Visuals = {
        SelfESP = {
            Trail = {
                Color = Color3.fromRGB(255, 110, 0),
                Color2 = Color3.fromRGB(255, 0, 0), -- Second color for gradient
                LifeTime = 1.6,
                Width = 0.1
            },
            Aura = {
                Color = Color3.fromRGB(255, 255, 255)
            }
        }
    }
}

utility.trail_character = function(Bool)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

    if Bool then
        if not humanoidRootPart:FindFirstChild("BlaBla") then
            local BlaBla = Instance.new("Trail", humanoidRootPart)
            BlaBla.Name = "BlaBla"
            humanoidRootPart.Material = Enum.Material.Neon

            local attachment0 = Instance.new("Attachment", humanoidRootPart)
            attachment0.Position = Vector3.new(0, 1, 0)

            local attachment1 = Instance.new("Attachment", humanoidRootPart)
            attachment1.Position = Vector3.new(0, -1, 0)

            BlaBla.Attachment0 = attachment0
            BlaBla.Attachment1 = attachment1
            BlaBla.Color = ColorSequence.new(Settings.Visuals.SelfESP.Trail.Color, Settings.Visuals.SelfESP.Trail.Color2) -- Gradient effect
            BlaBla.Lifetime = Settings.Visuals.SelfESP.Trail.LifeTime
            BlaBla.Transparency = NumberSequence.new(0, 0)
            BlaBla.LightEmission = 0.2
            BlaBla.Brightness = 10
            BlaBla.WidthScale = NumberSequence.new{
                NumberSequenceKeypoint.new(0, Settings.Visuals.SelfESP.Trail.Width),
                NumberSequenceKeypoint.new(1, 0)
            }
        end
    else
        for _, child in ipairs(humanoidRootPart:GetChildren()) do
            if child:IsA("Trail") and child.Name == 'BlaBla' then
                child:Destroy()
            end
        end
    end
end
task.wait(1)
local function onCharacterAdded(character)
    if getgenv().trailEnabled then
        utility.trail_character(true)
    end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then onCharacterAdded(player.Character) end

Auras:AddToggle("TrailToggle", {
    Text = "Trail",
    Default = false,
    Callback = function(state)
        getgenv().trailEnabled = state
        utility.trail_character(state)
    end
}):AddColorPicker("TrailColor", {
    Text = "Trail Color",
    Default = Settings.Visuals.SelfESP.Trail.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
}):AddColorPicker("TrailColor2", {
    Text = "Trail Color 2",
    Default = Settings.Visuals.SelfESP.Trail.Color2,
    Callback = function(color)
        Settings.Visuals.SelfESP.Trail.Color2 = color
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

Auras:AddSlider("TrailLifetime", {
    Text = "Trail Lifetime",
    Default = 1.6,
    Min = 0.1,
    Max = 5,
    Rounding = 1,
    Callback = function(value)
        Settings.Visuals.SelfESP.Trail.LifeTime = value
        if getgenv().trailEnabled then
            utility.trail_character(false)
            utility.trail_character(true)
        end
    end
})

local HitEffectModule = {
    Locals = {
        HitEffect = {
            Type = {}
        }
    }
}
local Attachment = Instance.new("Attachment")
HitEffectModule.Locals.HitEffect.Type["Skibidi RedRizz"] = Attachment
local swirl = Instance.new("ParticleEmitter", Attachment)
swirl.Name = "swirl"
swirl.Lifetime = NumberRange.new(2)
swirl.SpreadAngle = Vector2.new(-360, 360)
swirl.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.5), NumberSequenceKeypoint.new(1, 1)})
swirl.LightEmission = 10
swirl.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
swirl.VelocitySpread = -360
swirl.Squash = NumberSequence.new(0)
swirl.Speed = NumberRange.new(0.01)
swirl.Size = NumberSequence.new(7)
swirl.ZOffset = -1
swirl.ShapeInOut = Enum.ParticleEmitterShapeInOut.InAndOut
swirl.Rate = 40
swirl.LockedToPart = true
swirl.Texture = "rbxassetid://10558425570"
swirl.RotSpeed = NumberRange.new(200)
swirl.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
local Bolts = Instance.new("ParticleEmitter", Attachment)
Bolts.Name = "Bolts"
Bolts.Lifetime = NumberRange.new(0.333)
Bolts.LockedToPart = true
Bolts.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.88), NumberSequenceKeypoint.new(0.055, 0.98),
    NumberSequenceKeypoint.new(0.111, 0.17), NumberSequenceKeypoint.new(0.166, 0.39),
    NumberSequenceKeypoint.new(0.222, 0.12), NumberSequenceKeypoint.new(0.277, 0.92),
    NumberSequenceKeypoint.new(0.333, 0.41), NumberSequenceKeypoint.new(0.388, 0.21),
    NumberSequenceKeypoint.new(0.444, 0.78), NumberSequenceKeypoint.new(0.499, 0.23),
    NumberSequenceKeypoint.new(0.555, 0.78), NumberSequenceKeypoint.new(0.610, 0.81),
    NumberSequenceKeypoint.new(0.666, 0.91), NumberSequenceKeypoint.new(0.721, 0.87),
    NumberSequenceKeypoint.new(0.777, 0.41), NumberSequenceKeypoint.new(0.832, 0.30),
    NumberSequenceKeypoint.new(0.888, 0.16), NumberSequenceKeypoint.new(0.943, 0.39),
    NumberSequenceKeypoint.new(0.999, 0.70), NumberSequenceKeypoint.new(1, 1)
})
Bolts.LightEmission = 1
Bolts.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
Bolts.Speed = NumberRange.new(0)
Bolts.Size = NumberSequence.new(4.8)
Bolts.Rate = 12
Bolts.Texture = "rbxassetid://1084955012"
Bolts.Rotation = NumberRange.new(-180, 180)
local Bubble = Instance.new("ParticleEmitter", Attachment)
Bubble.Name = "Bubble"
Bubble.Lifetime = NumberRange.new(1)
Bubble.LockedToPart = true
Bubble.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.7), NumberSequenceKeypoint.new(1, 1)})
Bubble.LightEmission = 1
Bubble.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
Bubble.Speed = NumberRange.new(0)
Bubble.Size = NumberSequence.new(4)
Bubble.Rate = 6
Bubble.Texture = "rbxassetid://1084955488"
Bubble.Rotation = NumberRange.new(-180, 180)

local HealingWave1 = Instance.new("ParticleEmitter", Attachment)
HealingWave1.Name = "HealingWave1"
HealingWave1.Lifetime = NumberRange.new(1.5, 1.5)
HealingWave1.SpreadAngle = Vector2.new(10, -10)
HealingWave1.LockedToPart = true
HealingWave1.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1702454, 0.7, 0.014881), NumberSequenceKeypoint.new(0.2254601, 0.03125, 0.03125), NumberSequenceKeypoint.new(0.2852761, 0), NumberSequenceKeypoint.new(0.702454, 0), NumberSequenceKeypoint.new(0.8374233, 0.9125, 0.0601461), NumberSequenceKeypoint.new(1, 1)})
HealingWave1.LightEmission = 0.4
HealingWave1.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
HealingWave1.VelocitySpread = 10
HealingWave1.Speed = NumberRange.new(3, 6)
HealingWave1.Brightness = 10
HealingWave1.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.0624998, 1.8805969), NumberSequenceKeypoint.new(0.6420546, 1.9999999, 1.7619393), NumberSequenceKeypoint.new(1, 0.7499999, 0.7499999)})
HealingWave1.Rate = 20
HealingWave1.Texture = "rbxassetid://8047533775"
HealingWave1.RotSpeed = NumberRange.new(200, 400)
HealingWave1.Rotation = NumberRange.new(-180, 180)
HealingWave1.Orientation = Enum.ParticleOrientation.VelocityPerpendicular

local HealingWave2 = Instance.new("ParticleEmitter", Attachment)
HealingWave2.Name = "HealingWave2"
HealingWave2.Lifetime = NumberRange.new(1.5, 1.5)
HealingWave2.SpreadAngle = Vector2.new(10, -10)
HealingWave2.LockedToPart = true
HealingWave2.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2254601, 0.03125, 0.03125), NumberSequenceKeypoint.new(0.6288344, 0.25625, 0.0593491), NumberSequenceKeypoint.new(0.8374233, 0.9125, 0.0601461), NumberSequenceKeypoint.new(1, 1)})
HealingWave2.LightEmission = 1
HealingWave2.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
HealingWave2.VelocitySpread = 10
HealingWave2.Speed = NumberRange.new(3, 5)
HealingWave2.Brightness = 10
HealingWave2.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 3.125), NumberSequenceKeypoint.new(0.4165329, 1.3749999, 1.3749999), NumberSequenceKeypoint.new(1, 0.9375, 0.9375)})
HealingWave2.Rate = 20
HealingWave2.Texture = "rbxassetid://8047796070"
HealingWave2.RotSpeed = NumberRange.new(100, 300)
HealingWave2.Rotation = NumberRange.new(-180, 180)
HealingWave2.Orientation = Enum.ParticleOrientation.VelocityPerpendicular

local Sparks = Instance.new("ParticleEmitter", Attachment)
Sparks.Name = "Sparks"
Sparks.Lifetime = NumberRange.new(0.5, 2)
Sparks.SpreadAngle = Vector2.new(180, -180)
Sparks.LightEmission = 1
Sparks.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
Sparks.Drag = 3
Sparks.VelocitySpread = 180
Sparks.Speed = NumberRange.new(5, 15)
Sparks.Brightness = 10
Sparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.14687, 0.4374999, 0.1875001), NumberSequenceKeypoint.new(1, 0)})
Sparks.Acceleration = Vector3.new(0, 3, 0)
Sparks.ZOffset = -1
Sparks.Rate = 40
Sparks.Texture = "rbxassetid://8611887361"
Sparks.RotSpeed = NumberRange.new(-30, 30)
Sparks.Orientation = Enum.ParticleOrientation.VelocityParallel

local StarSparks = Instance.new("ParticleEmitter", Attachment)
StarSparks.Name = "StarSparks"
StarSparks.Lifetime = NumberRange.new(1.5, 1.5)
StarSparks.SpreadAngle = Vector2.new(180, -180)
StarSparks.LightEmission = 1
StarSparks.Color = ColorSequence.new(Settings.Visuals.SelfESP.Aura.Color)
StarSparks.Drag = 3
StarSparks.VelocitySpread = 180
StarSparks.Speed = NumberRange.new(5, 10)
StarSparks.Brightness = 10
StarSparks.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.1492777, 0.6874996, 0.6874996), NumberSequenceKeypoint.new(1, 0)})
StarSparks.Acceleration = Vector3.new(0, 3, 0)
StarSparks.ZOffset = 2
StarSparks.Texture = "rbxassetid://8611887703"
StarSparks.RotSpeed = NumberRange.new(-30, 30)
StarSparks.Rotation = NumberRange.new(-30, 30)

local function applyAura(auraName)
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    Attachment.Parent = humanoidRootPart
    if getgenv().auraEnabled then
        swirl.Enabled = auraName == "Skibidi RedRizz"
        Bolts.Enabled = auraName == "Bolts"
        Bubble.Enabled = auraName == "Bubble"
        HealingWave1.Enabled = auraName == "Heal"
        HealingWave2.Enabled = auraName == "Heal"
        Sparks.Enabled = auraName == "Heal"
        StarSparks.Enabled = auraName == "Heal"
        humanoidRootPart.Material = Enum.Material.Neon
    else
        swirl.Enabled = false
        Bolts.Enabled = false
        Bubble.Enabled = false
        HealingWave1.Enabled = false
        HealingWave2.Enabled = false
        Sparks.Enabled = false
        StarSparks.Enabled = false
    end
end

Auras:AddToggle("AuraToggle", {
    Text = "Auras",
    Default = false,
    Callback = function(state)
        getgenv().auraEnabled = state
        applyAura(getgenv().selectedAura or "Skibidi RedRizz")
    end
}):AddColorPicker("AuraColor", {
    Text = "Aura Color",
    Default = Settings.Visuals.SelfESP.Aura.Color,
    Callback = function(color)
        Settings.Visuals.SelfESP.Aura.Color = color
        swirl.Color = ColorSequence.new(color)
        Bolts.Color = ColorSequence.new(color)
        Bubble.Color = ColorSequence.new(color)
        HealingWave1.Color = ColorSequence.new(color)
        HealingWave2.Color = ColorSequence.new(color)
        Sparks.Color = ColorSequence.new(color)
        StarSparks.Color = ColorSequence.new(color)
        if getgenv().auraEnabled then
            applyAura(getgenv().selectedAura or "Skibidi RedRizz")
        end
    end
})
Auras:AddDropdown("AuraType", {
    Text = "Select Aura",
    Values = {"Skibidi RedRizz", "Bolts", "Bubble", "Heal"},
    Default = "Bubble",
    Callback = function(selected)
        getgenv().selectedAura = selected
        if getgenv().auraEnabled then
            applyAura(selected)
        end
    end
})
getgenv().envt = Tabs.Visuals:AddRightGroupbox('Environment')

local LightingService = game:GetService("Lighting")
local originalAmbient = LightingService.Ambient
local originalOutdoorAmbient = LightingService.OutdoorAmbient
local originalFogColor = LightingService.FogColor
local originalFogStart = LightingService.FogStart
local originalFogEnd = LightingService.FogEnd
local originalBrightness = LightingService.Brightness
local originalClockTime = LightingService.ClockTime
local originalGlobalShadows = LightingService.GlobalShadows
local originalEnvironmentDiffuseScale = LightingService.EnvironmentDiffuseScale
local originalEnvironmentSpecularScale = LightingService.EnvironmentSpecularScale
local originalExposureCompensation = LightingService.ExposureCompensation
local originalColorShiftBottom = LightingService.ColorShift_Bottom
local originalColorShiftTop = LightingService.ColorShift_Top
local originalGeographicLatitude = LightingService.GeographicLatitude
local originalShadowSoftness = LightingService.ShadowSoftness
local nebulaThemeColor = Color3.fromRGB(173, 216, 230)
local Visuals = {}
local Skyboxes = {}
function Visuals:NewSky(Data)
    local Name = Data.Name
    Skyboxes[Name] = {
        SkyboxBk = Data.SkyboxBk,
        SkyboxDn = Data.SkyboxDn,
        SkyboxFt = Data.SkyboxFt,
        SkyboxLf = Data.SkyboxLf,
        SkyboxRt = Data.SkyboxRt,
        SkyboxUp = Data.SkyboxUp,
        MoonTextureId = Data.Moon or "rbxasset://sky/moon.jpg",
        SunTextureId = Data.Sun or "rbxasset://sky/sun.jpg"
    }
end
function Visuals:SwitchSkybox(Name)
    local OldSky = LightingService:FindFirstChildOfClass("Sky")
    if OldSky then OldSky:Destroy() end
    local Sky = Instance.new("Sky", LightingService)
    for Index, Value in pairs(Skyboxes[Name]) do
        Sky[Index] = Value
    end
end
if LightingService:FindFirstChildOfClass("Sky") then
    local OldSky = LightingService:FindFirstChildOfClass("Sky")
    Visuals:NewSky({
        Name = "Game's Default Sky",
        SkyboxBk = OldSky.SkyboxBk,
        SkyboxDn = OldSky.SkyboxDn,
        SkyboxFt = OldSky.SkyboxFt,
        SkyboxLf = OldSky.SkyboxLf,
        SkyboxRt = OldSky.SkyboxRt,
        SkyboxUp = OldSky.SkyboxUp
    })
end
Visuals:NewSky({
    Name = "Sunset",
    SkyboxBk = "rbxassetid://600830446",
    SkyboxDn = "rbxassetid://600831635",
    SkyboxFt = "rbxassetid://600832720",
    SkyboxLf = "rbxassetid://600886090",
    SkyboxRt = "rbxassetid://600833862",
    SkyboxUp = "rbxassetid://600835177"
})
Visuals:NewSky({
    Name = "Arctic",
    SkyboxBk = "http://www.roblox.com/asset/?id=225469390",
    SkyboxDn = "http://www.roblox.com/asset/?id=225469395",
    SkyboxFt = "http://www.roblox.com/asset/?id=225469403",
    SkyboxLf = "http://www.roblox.com/asset/?id=225469450",
    SkyboxRt = "http://www.roblox.com/asset/?id=225469471",
    SkyboxUp = "http://www.roblox.com/asset/?id=225469481"
})
Visuals:NewSky({
    Name = "Space",
    SkyboxBk = "http://www.roblox.com/asset/?id=166509999",
    SkyboxDn = "http://www.roblox.com/asset/?id=166510057",
    SkyboxFt = "http://www.roblox.com/asset/?id=166510116",
    SkyboxLf = "http://www.roblox.com/asset/?id=166510092",
    SkyboxRt = "http://www.roblox.com/asset/?id=166510131",
    SkyboxUp = "http://www.roblox.com/asset/?id=166510114"
})
Visuals:NewSky({
    Name = "Roblox Default",
    SkyboxBk = "rbxasset://textures/sky/sky512_bk.tex",
    SkyboxDn = "rbxasset://textures/sky/sky512_dn.tex",
    SkyboxFt = "rbxasset://textures/sky/sky512_ft.tex",
    SkyboxLf = "rbxasset://textures/sky/sky512_lf.tex",
    SkyboxRt = "rbxasset://textures/sky/sky512_rt.tex",
    SkyboxUp = "rbxasset://textures/sky/sky512_up.tex"
})
Visuals:NewSky({
    Name = "Red Night",
    SkyboxBk = "http://www.roblox.com/Asset/?ID=401664839";
    SkyboxDn = "http://www.roblox.com/Asset/?ID=401664862";
    SkyboxFt = "http://www.roblox.com/Asset/?ID=401664960";
    SkyboxLf = "http://www.roblox.com/Asset/?ID=401664881";
    SkyboxRt = "http://www.roblox.com/Asset/?ID=401664901";
    SkyboxUp = "http://www.roblox.com/Asset/?ID=401664936";
})
Visuals:NewSky({
    Name = "Deep Space",
    SkyboxBk = "http://www.roblox.com/asset/?id=149397692";
    SkyboxDn = "http://www.roblox.com/asset/?id=135207662";
    SkyboxFt = "http://www.roblox.com/asset/?id=135207770";
    SkyboxLf = "http://www.roblox.com/asset/?id=135207615";
    SkyboxRt = "http://www.roblox.com/asset/?id=135207695";
    SkyboxUp = "http://www.roblox.com/asset/?id=135207794";
})
Visuals:NewSky({
    Name = "Pink Skies",
    SkyboxBk = "http://www.roblox.com/asset/?id=151165214";
    SkyboxDn = "http://www.roblox.com/asset/?id=151165197";
    SkyboxFt = "http://www.roblox.com/asset/?id=151165224";
    SkyboxLf = "http://www.roblox.com/asset/?id=151165191";
    SkyboxRt = "http://www.roblox.com/asset/?id=151165206";
    SkyboxUp = "http://www.roblox.com/asset/?id=151165227";
})
Visuals:NewSky({
    Name = "Purple Sunset",
    SkyboxBk = "rbxassetid://264908339";
    SkyboxDn = "rbxassetid://264907909";
    SkyboxFt = "rbxassetid://264909420";
    SkyboxLf = "rbxassetid://264909758";
    SkyboxRt = "rbxassetid://264908886";
    SkyboxUp = "rbxassetid://264907379";
})
Visuals:NewSky({
    Name = "Blue Night",
    SkyboxBk = "http://www.roblox.com/Asset/?ID=12064107";
    SkyboxDn = "http://www.roblox.com/Asset/?ID=12064152";
    SkyboxFt = "http://www.roblox.com/Asset/?ID=12064121";
    SkyboxLf = "http://www.roblox.com/Asset/?ID=12063984";
    SkyboxRt = "http://www.roblox.com/Asset/?ID=12064115";
    SkyboxUp = "http://www.roblox.com/Asset/?ID=12064131";
})
Visuals:NewSky({
    Name = "Blossom Daylight",
    SkyboxBk = "http://www.roblox.com/asset/?id=271042516";
    SkyboxDn = "http://www.roblox.com/asset/?id=271077243";
    SkyboxFt = "http://www.roblox.com/asset/?id=271042556";
    SkyboxLf = "http://www.roblox.com/asset/?id=271042310";
    SkyboxRt = "http://www.roblox.com/asset/?id=271042467";
    SkyboxUp = "http://www.roblox.com/asset/?id=271077958";
})
Visuals:NewSky({
    Name = "Blue Nebula",
    SkyboxBk = "http://www.roblox.com/asset?id=135207744";
    SkyboxDn = "http://www.roblox.com/asset?id=135207662";
    SkyboxFt = "http://www.roblox.com/asset?id=135207770";
    SkyboxLf = "http://www.roblox.com/asset?id=135207615";
    SkyboxRt = "http://www.roblox.com/asset?id=135207695";
    SkyboxUp = "http://www.roblox.com/asset?id=135207794";
})
Visuals:NewSky({
    Name = "Blue Planet",
    SkyboxBk = "rbxassetid://218955819";
    SkyboxDn = "rbxassetid://218953419";
    SkyboxFt = "rbxassetid://218954524";
    SkyboxLf = "rbxassetid://218958493";
    SkyboxRt = "rbxassetid://218957134";
    SkyboxUp = "rbxassetid://218950090";
})
Visuals:NewSky({
    Name = "Deep Space",
    SkyboxBk = "http://www.roblox.com/asset/?id=159248188";
    SkyboxDn = "http://www.roblox.com/asset/?id=159248183";
    SkyboxFt = "http://www.roblox.com/asset/?id=159248187";
    SkyboxLf = "http://www.roblox.com/asset/?id=159248173";
    SkyboxRt = "http://www.roblox.com/asset/?id=159248192";
    SkyboxUp = "http://www.roblox.com/asset/?id=159248176";
})
Visuals:NewSky({
    Name = "Summer",
    SkyboxBk = "rbxassetid://16648590964",
    SkyboxDn = "rbxassetid://16648617436",
    SkyboxFt = "rbxassetid://16648595424",
    SkyboxLf = "rbxassetid://16648566370",
    SkyboxRt = "rbxassetid://16648577071",
    SkyboxUp = "rbxassetid://16648598180"
})
Visuals:NewSky({
    Name = "Galaxy",
    SkyboxBk = "rbxassetid://15983968922",
    SkyboxDn = "rbxassetid://15983966825",
    SkyboxFt = "rbxassetid://15983965025",
    SkyboxLf = "rbxassetid://15983967420",
    SkyboxRt = "rbxassetid://15983966246",
    SkyboxUp = "rbxassetid://15983964246"
})
Visuals:NewSky({
    Name = "Stylized",
    SkyboxBk = "rbxassetid://18351376859",
    SkyboxDn = "rbxassetid://18351374919",
    SkyboxFt = "rbxassetid://18351376800",
    SkyboxLf = "rbxassetid://18351376469",
    SkyboxRt = "rbxassetid://18351376457",
    SkyboxUp = "rbxassetid://18351377189"
})
Visuals:NewSky({
    Name = "Minecraft",
    SkyboxBk = "rbxassetid://8735166756",
    SkyboxDn = "http://www.roblox.com/asset/?id=8735166707",
    SkyboxFt = "http://www.roblox.com/asset/?id=8735231668",
    SkyboxLf = "http://www.roblox.com/asset/?id=8735166755",
    SkyboxRt = "http://www.roblox.com/asset/?id=8735166751",
    SkyboxUp = "http://www.roblox.com/asset/?id=8735166729"
})
Visuals:NewSky({
    Name = "Sunset",
    SkyboxBk = "http://www.roblox.com/asset/?id=151165214",
    SkyboxDn = "http://www.roblox.com/asset/?id=151165197",
    SkyboxFt = "http://www.roblox.com/asset/?id=151165224",
    SkyboxLf = "http://www.roblox.com/asset/?id=151165191",
    SkyboxRt = "http://www.roblox.com/asset/?id=151165206",
    SkyboxUp = "http://www.roblox.com/asset/?id=151165227"
})
Visuals:NewSky({
    Name = "Cloudy Rain",
    SkyboxBk = "http://www.roblox.com/asset/?id=4498828382",
    SkyboxDn = "http://www.roblox.com/asset/?id=4498828812",
    SkyboxFt = "http://www.roblox.com/asset/?id=4498829917",
    SkyboxLf = "http://www.roblox.com/asset/?id=4498830911",
    SkyboxRt = "http://www.roblox.com/asset/?id=4498830417",
    SkyboxUp = "http://www.roblox.com/asset/?id=4498831746"
})
Visuals:NewSky({
    Name = "Black Cloudy Rain",
    SkyboxBk = "http://www.roblox.com/asset/?id=149679669",
    SkyboxDn = "http://www.roblox.com/asset/?id=149681979",
    SkyboxFt = "http://www.roblox.com/asset/?id=149679690",
    SkyboxLf = "http://www.roblox.com/asset/?id=149679709",
    SkyboxRt = "http://www.roblox.com/asset/?id=149679722",
    SkyboxUp = "http://www.roblox.com/asset/?id=149680199"
})
local SkyboxNames = {}
for Name, _ in pairs(Skyboxes) do
    table.insert(SkyboxNames, Name)
end
getgenv().envt:AddToggle("CustomAmbient", {
    Text = "Custom Ambient",
    Default = false,
    Callback = function(Value)
        CustomAmbient = Value
        LightingService.Ambient = Value and AmbientColor or originalAmbient
    end
}):AddColorPicker("AmbientColor", {
    Default = originalAmbient,
    Callback = function(Value)
        AmbientColor = Value
        if CustomAmbient then
            LightingService.Ambient = Value
        end
    end
})
-- Custom Outdoor Ambient
getgenv().envt:AddToggle("CustomOutdoorAmbient", {
    Text = "Custom Outdoor Ambient",
    Default = false,
    Callback = function(Value)
        CustomOutdoorAmbient = Value
        LightingService.OutdoorAmbient = Value and OutdoorAmbientColor or originalOutdoorAmbient
    end
}):AddColorPicker("OutdoorAmbientColor", {
    Default = originalOutdoorAmbient,
    Callback = function(Value)
        OutdoorAmbientColor = Value
        if CustomOutdoorAmbient then
            LightingService.OutdoorAmbient = Value
        end
    end
})
-- Custom Fog
getgenv().envt:AddToggle("CustomFog", {
    Text = "Custom Fog",
    Default = false,
    Callback = function(Value)
        CustomFog = Value
        if Value then
            LightingService.FogColor = FogColor
            LightingService.FogStart = FogStart
            LightingService.FogEnd = FogEnd
        else
            LightingService.FogColor = originalFogColor
            LightingService.FogStart = originalFogStart
            LightingService.FogEnd = originalFogEnd
        end
    end
}):AddColorPicker("FogColor", {
    Default = originalFogColor,
    Callback = function(Value)
        FogColor = Value
        if CustomFog then
            LightingService.FogColor = Value
        end
    end
})
getgenv().envt:AddSlider("FogStart", {
    Text = "Fog Start",
    Min = 0,
    Max = 1000,
    Default = originalFogStart,
    Rounding = 1,
    Callback = function(Value)
        FogStart = Value
        if CustomFog then
            LightingService.FogStart = Value
        end
    end
})
getgenv().envt:AddSlider("FogEnd", {
    Text = "Fog End",
    Min = 0,
    Max = 1000,
    Default = originalFogEnd,
    Rounding = 1,
    Callback = function(Value)
        FogEnd = Value
        if CustomFog then
            LightingService.FogEnd = Value
        end
    end
})
-- Custom Brightness
getgenv().envt:AddToggle("CustomBrightness", {
    Text = "Custom Brightness",
    Default = false,
    Callback = function(Value)
        CustomBrightness = Value
        LightingService.Brightness = Value and BrightnessValue or originalBrightness
    end
})
getgenv().envt:AddSlider("BrightnessValue", {
    Text = "Brightness",
    Min = 0,
    Max = 10,
    Default = originalBrightness,
    Rounding = 1,
    Callback = function(Value)
        BrightnessValue = Value
        if CustomBrightness then
            LightingService.Brightness = Value
        end
    end
})
-- Custom Clock Time
getgenv().envt:AddToggle("CustomClockTime", {
    Text = "Custom Clock Time",
    Default = false,
    Callback = function(Value)
        CustomClockTime = Value
        LightingService.ClockTime = Value and ClockTimeValue or originalClockTime
    end
})
getgenv().envt:AddSlider("ClockTimeValue", {
    Text = "Clock Time",
    Min = 0,
    Max = 24,
    Default = originalClockTime,
    Rounding = 1,
    Callback = function(Value)
        ClockTimeValue = Value
        if CustomClockTime then
            LightingService.ClockTime = Value
        end
    end
})
-- Global Shadows
getgenv().envt:AddToggle("GlobalShadows", {
    Text = "Global Shadows",
    Default = originalGlobalShadows,
    Callback = function(Value)
        LightingService.GlobalShadows = Value
    end
})
-- Environment Diffuse
getgenv().envt:AddToggle("CustomEnvironmentDiffuse", {
    Text = "Custom Environment Diffuse",
    Default = false,
    Callback = function(Value)
        CustomEnvironmentDiffuse = Value
        LightingService.EnvironmentDiffuseScale = Value and EnvironmentDiffuseValue or originalEnvironmentDiffuseScale
    end
})
getgenv().envt:AddSlider("EnvironmentDiffuseValue", {
    Text = "Environment Diffuse Scale",
    Min = 0,
    Max = 1,
    Default = originalEnvironmentDiffuseScale,
    Rounding = 2,
    Callback = function(Value)
        EnvironmentDiffuseValue = Value
        if CustomEnvironmentDiffuse then
            LightingService.EnvironmentDiffuseScale = Value
        end
    end
})
-- Environment Specular
getgenv().envt:AddToggle("CustomEnvironmentSpecular", {
    Text = "Custom Environment Specular",
    Default = false,
    Callback = function(Value)
        CustomEnvironmentSpecular = Value
        LightingService.EnvironmentSpecularScale = Value and EnvironmentSpecularValue or originalEnvironmentSpecularScale
    end
})
getgenv().envt:AddSlider("EnvironmentSpecularValue", {
    Text = "Environment Specular Scale",
    Min = 0,
    Max = 1,
    Default = originalEnvironmentSpecularScale,
    Rounding = 2,
    Callback = function(Value)
        EnvironmentSpecularValue = Value
        if CustomEnvironmentSpecular then
            LightingService.EnvironmentSpecularScale = Value
        end
    end
})
-- Exposure Compensation
getgenv().envt:AddToggle("CustomExposure", {
    Text = "Custom Exposure",
    Default = false,
    Callback = function(Value)
        CustomExposure = Value
        LightingService.ExposureCompensation = Value and ExposureValue or originalExposureCompensation
    end
})
getgenv().envt:AddSlider("ExposureValue", {
    Text = "Exposure Compensation",
    Min = -3,
    Max = 3,
    Default = originalExposureCompensation,
    Rounding = 1,
    Callback = function(Value)
        ExposureValue = Value
        if CustomExposure then
            LightingService.ExposureCompensation = Value
        end
    end
})
-- Color Shift Bottom
getgenv().envt:AddToggle("CustomColorShiftBottom", {
    Text = "Custom Color Shift Bottom",
    Default = false,
    Callback = function(Value)
        CustomColorShiftBottom = Value
        LightingService.ColorShift_Bottom = Value and ColorShiftBottomColor or originalColorShiftBottom
    end
}):AddColorPicker("ColorShiftBottomColor", {
    Default = originalColorShiftBottom,
    Callback = function(Value)
        ColorShiftBottomColor = Value
        if CustomColorShiftBottom then
            LightingService.ColorShift_Bottom = Value
        end
    end
})
-- Color Shift Top
getgenv().envt:AddToggle("CustomColorShiftTop", {
    Text = "Custom Color Shift Top",
    Default = false,
    Callback = function(Value)
        CustomColorShiftTop = Value
        LightingService.ColorShift_Top = Value and ColorShiftTopColor or originalColorShiftTop
    end
}):AddColorPicker("ColorShiftTopColor", {
    Default = originalColorShiftTop,
    Callback = function(Value)
        ColorShiftTopColor = Value
        if CustomColorShiftTop then
            LightingService.ColorShift_Top = Value
        end
    end
})
-- Geographic Latitude
getgenv().envt:AddToggle("CustomGeographicLatitude", {
    Text = "Custom Geographic Latitude",
    Default = false,
    Callback = function(Value)
        CustomGeographicLatitude = Value
        LightingService.GeographicLatitude = Value and GeographicLatitudeValue or originalGeographicLatitude
    end
})
getgenv().envt:AddSlider("GeographicLatitudeValue", {
    Text = "Geographic Latitude",
    Min = -90,
    Max = 90,
    Default = originalGeographicLatitude,
    Rounding = 1,
    Callback = function(Value)
        GeographicLatitudeValue = Value
        if CustomGeographicLatitude then
            LightingService.GeographicLatitude = Value
        end
    end
})
-- Shadow Mode
getgenv().envt:AddDropdown("ShadowMode", {
    Values = { "Hard", "Medium", "Soft" },
    Default = "Medium",
    Multi = false,
    Text = "Shadow Mode",
    Callback = function(Value)
        local softness = Value == "Hard" and 0 or Value == "Medium" and 0.5 or 1
        LightingService.ShadowSoftness = softness
    end
})
--====================================================================--
--============================== MISC =================================--
--====================================================================--
-- Nebula Theme
getgenv().envt:AddToggle("NebulaTheme", {
    Text = "Nebula Theme",
    Default = false,
    Callback = function(state)
        nebulaEnabled = state
        if state then
            local b = Instance.new("BloomEffect", LightingService)
            b.Intensity = 0.7
            b.Size = 24
            b.Threshold = 1
            b.Name = "NebulaBloom"
            local c = Instance.new("ColorCorrectionEffect", LightingService)
            c.Saturation = 0.5
            c.Contrast = 0.2
            c.TintColor = nebulaThemeColor
            c.Name = "NebulaColorCorrection"
            local a = Instance.new("Atmosphere", LightingService)
            a.Density = 0.4
            a.Offset = 0.25
            a.Glare = 1
            a.Haze = 2
            a.Color = nebulaThemeColor
            a.Decay = Color3.fromRGB(25, 25, 112)
            a.Name = "NebulaAtmosphere"
            LightingService.Ambient = nebulaThemeColor
            LightingService.OutdoorAmbient = nebulaThemeColor
            LightingService.FogStart = 100
            LightingService.FogEnd = 500
            LightingService.FogColor = nebulaThemeColor
        else
            for _, name in pairs({"NebulaBloom", "NebulaColorCorrection", "NebulaAtmosphere"}) do
                local obj = LightingService:FindFirstChild(name)
                if obj then obj:Destroy() end
            end
            LightingService.Ambient = originalAmbient
            LightingService.OutdoorAmbient = originalOutdoorAmbient
            LightingService.FogStart = originalFogStart
            LightingService.FogEnd = originalFogEnd
            LightingService.FogColor = originalFogColor
        end
    end
}):AddColorPicker("NebulaColor", {
    Default = Color3.fromRGB(173, 216, 230),
    Callback = function(c)
        nebulaThemeColor = c
        if nebulaEnabled then
            local nc = LightingService:FindFirstChild("NebulaColorCorrection")
            if nc then nc.TintColor = c end
            local na = LightingService:FindFirstChild("NebulaAtmosphere")
            if na then na.Color = c end
            LightingService.Ambient = c
            LightingService.OutdoorAmbient = c
            LightingService.FogColor = c
        end
    end
})
-- Custom Skybox
getgenv().envt:AddToggle("CustomSkybox", {
    Text = "Custom Skybox",
    Default = false,
    Callback = function(Value)
        CustomSkybox = Value
        Visuals:SwitchSkybox(Value and (SelectedSkybox or "Game's Default Sky") or "Game's Default Sky")
    end
})
getgenv().envt:AddDropdown("SelectedSkybox", {
    Values = SkyboxNames,
    Default = "Game's Default Sky",
    Multi = false,
    Text = "Skybox",
    Callback = function(Value)
        SelectedSkybox = Value
        if CustomSkybox then
            Visuals:SwitchSkybox(Value)
        end
    end
})

getgenv().walkSpeedEnabled, getgenv().jumpPowerEnabled, getgenv().cframeSpeedEnabled = false, false, false
getgenv().walkSpeedKeybindActive, getgenv().cframeSpeedKeybindActive = false, false
getgenv().walkSpeed, getgenv().jumpPower, getgenv().cframeSpeed = 16, 50, 10

local uhhh = Tabs.Character:AddLeftGroupbox('Movement')

uhhh:AddToggle('CFrameSpeedToggle', {
    Text = 'cframe',
    Default = false,
    Callback = function(state)
        getgenv().cframeSpeedEnabled = state
        if not state then getgenv().cframeSpeedKeybindActive = false end
    end,
}):AddKeyPicker('CFrameSpeedKeybind', {
    Default = 'T',
    Text = 'Cframe',
    Mode = 'Toggle',
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        if getgenv().cframeSpeedEnabled then getgenv().cframeSpeedKeybindActive = state end
    end,
})

uhhh:AddToggle('WalkSpeedToggle', {
    Text = 'WalkSpeed',
    Default = false,
    Callback = function(state)
        getgenv().walkSpeedEnabled = state
        if not state then getgenv().walkSpeedKeybindActive = false end
    end,
}):AddKeyPicker('WalkSpeedKeybind', {
    Default = 'T',
    Text = 'Velocity',
    Mode = 'Toggle',
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        if getgenv().walkSpeedEnabled then getgenv().walkSpeedKeybindActive = state end
    end,
})

uhhh:AddToggle('JumpPowerToggle', {
    Text = 'JumpPower',
    Default = false,
    Callback = function(state)
        getgenv().jumpPowerEnabled = state
    end,
})

uhhh:AddSlider('WalkSpeedSlider', {
    Text = 'WalkSpeed',
    Default = 16,
    Min = 16,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().walkSpeed = value
    end,
})

uhhh:AddSlider('JumpPowerSlider', {
    Text = 'JumpPower',
    Default = 50,
    Min = 50,
    Max = 500,
    Rounding = 0,
    Callback = function(value)
        getgenv().jumpPower = value
    end,
})

uhhh:AddSlider('CFrameSpeedSlider', {
    Text = 'Speed',
    Default = 10,
    Min = 1,
    Max = 200,
    Rounding = 1,
    Callback = function(value)
        getgenv().cframeSpeed = value
    end,
})

RunService.RenderStepped:Connect(function()
    if HighlightEnabled and lockedTarget and lockedTarget.Character then
        targetHighlight.Adornee = lockedTarget.Character
    else
        targetHighlight.Adornee = nil
    end
    local player = game.Players.LocalPlayer
    local humanoid = player.Character and player.Character:FindFirstChild('Humanoid')
    if not humanoid then return end
    
    humanoid.WalkSpeed = getgenv().walkSpeedEnabled and getgenv().walkSpeedKeybindActive and getgenv().walkSpeed or 16
    humanoid.JumpPower = getgenv().jumpPowerEnabled and getgenv().jumpPower or 50
end)
Players.PlayerRemoving:Connect(function(player)
    if lockedTarget and lockedTarget == player then
        lockedTarget = nil
        targetHighlight.Adornee = nil
    end
end)
task.spawn(function()
    while task.wait(0) do
        local player = game.Players.LocalPlayer
        local character = player.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        if getgenv().cframeSpeedEnabled and getgenv().cframeSpeedKeybindActive and character and humanoid and humanoid.MoveDirection.Magnitude > 0 then
            character:TranslateBy(humanoid.MoveDirection * getgenv().cframeSpeed * task.wait() * 3)
        end
    end
end)


getgenv().FlightKeybind = Enum.KeyCode.X
getgenv().FlySpeed = 50
getgenv().FlightEnabled = false
getgenv().Flying = false

local function CreateCore()
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
    local Core = Instance.new("Part")
    Core.Name = "Core"
    Core.Size = Vector3.new(0.05, 0.05, 0.05)
    Core.CanCollide = false
    Core.Transparency = 1
    Core.Parent = workspace
    local Weld = Instance.new("Weld", Core)
    Weld.Part0 = Core
    Weld.Part1 = LocalPlayer.Character.HumanoidRootPart
    Weld.C0 = CFrame.new(0, 0, 0)
    return Core
end

local function StartFly()
    if getgenv().Flying then return end
    getgenv().Flying = true
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = true
    local Core = CreateCore()
    local BV = Instance.new("BodyVelocity", Core)
    BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    BV.Velocity = Vector3.zero
    local BG = Instance.new("BodyGyro", Core)
    BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    BG.P = 9e4
    BG.CFrame = Core.CFrame
    RunService.RenderStepped:Connect(function()
        if not getgenv().Flying then return end
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveDirection = moveDirection - Vector3.new(0, 1, 0) end
        BV.Velocity = moveDirection * getgenv().FlySpeed
        BG.CFrame = camera.CFrame
    end)
end

local function StopFly()
    if not getgenv().Flying then return end
    getgenv().Flying = false
    LocalPlayer.Character:FindFirstChildOfClass("Humanoid").PlatformStand = false
    if workspace:FindFirstChild("Core") then workspace.Core:Destroy() end
end

uhhh:AddToggle("FlightToggle", {
    Text = "Flight",
    Default = false,
    Callback = function(state)
        getgenv().FlightEnabled = state
        if not state then StopFly() end
    end
}):AddKeyPicker("FlightKeybindPicker", {
    Default = "X",
    Text = "Flight",
    Mode = "Toggle",
    Callback = function(state)
        if UserInputService:GetFocusedTextBox() then return end
        if state and getgenv().FlightEnabled then
            StartFly()
        else
            StopFly()
        end
    end
})

uhhh:AddSlider("FlySpeedSlider", {
    Text = "Fly Speed",
    Default = 50,
    Min = 10,
    Max = 5000,
    Rounding = 0,
    Callback = function(value)
        getgenv().FlySpeed = value
    end
})

getgenv().SpinbotEnabled = false
getgenv().SpinSpeed = 10

local function toggleSpinbot(state)
    if state then
        if not getgenv().SpinConnection then
            getgenv().SpinConnection = RunService.RenderStepped:Connect(function()
                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and not getgenv().Flying then
                    LocalPlayer.Character.Humanoid.AutoRotate = false
                    LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(getgenv().SpinSpeed), 0)
                end
            end)
        end
    else
        if getgenv().SpinConnection then
            getgenv().SpinConnection:Disconnect()
            getgenv().SpinConnection = nil
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.AutoRotate = true
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().SpinbotEnabled then
        toggleSpinbot(true)
    end
end)

uhhh:AddToggle('SpinbotToggle', {
    Text = 'Spinbot',
    Default = false,
    Callback = function(state)
        getgenv().SpinbotEnabled = state
        toggleSpinbot(state)
    end,
}):AddKeyPicker('SpinbotKeybind', {
    Default = 'N',
    Text = 'Spinbot',
    Mode = 'Toggle',
    Callback = function(state)
        if not UserInputService:GetFocusedTextBox() and getgenv().SpinbotEnabled then
            toggleSpinbot(state)
        end
    end,
})

uhhh:AddSlider('SpinSpeedSlider', {
    Text = 'Spin Speed',
    Default = 10,
    Min = 1,
    Max = 50,
    Rounding = 1,
    Callback = function(value)
        getgenv().SpinSpeed = value
    end,
})

getgenv().selectedAnimationId = "rbxassetid://95656304023751"  -- Default: Take The L
getgenv().AnimationSpeed = 1  -- Default speed
getgenv().playAnimationEnabled = false  -- Thay vì takethelEnabled
getgenv().animationTrack = nil
getgenv().isPlaying = false

local function loadAnimationTrack(character)
    local humanoid = character:WaitForChild("Humanoid")
    local animation = Instance.new("Animation")
    animation.AnimationId = getgenv().selectedAnimationId  -- Load ID từ lựa chọn
    getgenv().animationTrack = humanoid:LoadAnimation(animation)
    getgenv().animationTrack.Looped = true
    getgenv().animationTrack.Priority = Enum.AnimationPriority.Action
    
    if getgenv().playAnimationEnabled then
        task.wait(0.6)
        getgenv().animationTrack:Play()
        getgenv().animationTrack:AdjustSpeed(getgenv().AnimationSpeed)
        getgenv().isPlaying = true
    end
end

game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function(character)
    loadAnimationTrack(character)
end)

if game:GetService("Players").LocalPlayer.Character then
    loadAnimationTrack(game:GetService("Players").LocalPlayer.Character)
end

local stutz = Tabs.Character:AddRightGroupbox('Misc')

-- Danh sách animation (có thêm "Take The L")
local animations = {
    ["Take The L"] = "rbxassetid://95656304023751",
    ["Floss"] = "rbxassetid://10714340543",
    ["Yungblud Happier Jump"] = "rbxassetid://15609995579",
    ["Godlike"] = "rbxassetid://10714347256",
    ["Mae Stephens - Piano Hands"] = "rbxassetid://16553163212",
    ["Victory Dance"] = "rbxassetid://15505456446",
    ["Elton John - Heart Skip"] = "rbxassetid://11309255148",
    ["Sturdy Dance - Ice Spice"] = "rbxassetid://17746180844",
    ["Old Town Road Dance - Lil Nas X (LNX)"] = "rbxassetid://10714391240",
    ["Sidekicks"] = "rbxassetid://10370362157",
    ["Baby Dance"] = "rbxassetid://10713983178",
    ["Baby Queen - Bouncy Twirl"] = "rbxassetid://14352343065",
    ["Rampage"] = "rbxassetid://139658061151500",
    ["Rambunctious"] = "rbxassetid://85916053135662",
    ["Griddy"] = "rbxassetid://121966805049108",
    ["Orange Justice"] = "rbxassetid://78927657777256",
}

-- Tạo danh sách hiển thị (loại trùng nếu có)
local animationNames = {}
local seen = {}
for name, _ in pairs(animations) do
    if not seen[name] then
        table.insert(animationNames, name)
        seen[name] = true
    end
end

stutz:AddDropdown("AnimationDropdown", {
    Values = {
        "Take The L",
        "Baby Queen - Bouncy Twirl",
        "Floss",
        "Yungblud Happier Jump",
        "Godlike",
        "Mae Stephens - Piano Hands",
        "Victory Dance",
        "Elton John - Heart Skip",
        "Sturdy Dance - Ice Spice",
        "Old Town Road Dance - Lil Nas X (LNX)",
        "Sidekicks",
        "Baby Dance",
        "Rampage",
        "Rambunctious",
        "Griddy",
        "Orange Justice"
    },
    Default = "Take The L",
    Multi = false,
    Text = "Select Animation",
    Callback = function(value)
        -- Bảng animation ID
        local animationIds = {
            ["Take The L"] = "rbxassetid://95656304023751",
            ["Baby Queen - Bouncy Twirl"] = "rbxassetid://14352343065",
            ["Floss"] = "rbxassetid://10714340543",
            ["Yungblud Happier Jump"] = "rbxassetid://15609995579",
            ["Godlike"] = "rbxassetid://10714347256",
            ["Mae Stephens - Piano Hands"] = "rbxassetid://16553163212",
            ["Victory Dance"] = "rbxassetid://15505456446",
            ["Elton John - Heart Skip"] = "rbxassetid://11309255148",
            ["Sturdy Dance - Ice Spice"] = "rbxassetid://17746180844",
            ["Old Town Road Dance - Lil Nas X (LNX)"] = "rbxassetid://10714391240",
            ["Sidekicks"] = "rbxassetid://10370362157",
            ["Baby Dance"] = "rbxassetid://10713983178",
            ["Rampage"] = "rbxassetid://139658061151500",
            ["Rambunctious"] = "rbxassetid://85916053135662",
            ["Griddy"] = "rbxassetid://121966805049108",
            ["Orange Justice"] = "rbxassetid://78927657777256"
        }

        -- Gán animation được chọn
        getgenv().selectedAnimationId = animationIds[value]

        -- Dừng animation hiện tại (nếu có)
        if getgenv().animationTrack then
            getgenv().animationTrack:Stop()
            getgenv().animationTrack = nil
        end

        -- Tải lại animation nếu đang bật
        if getgenv().playAnimationEnabled and LocalPlayer.Character then
            loadAnimationTrack(LocalPlayer.Character)
        end
    end
})


stutz:AddSlider("AnimationSpeedSlider", {
    Text = "Animation Speed",
    Default = 1,
    Min = 1,
    Max = 50,
    Rounding = 0,
    Callback = function(value)
        getgenv().AnimationSpeed = value
        if getgenv().animationTrack then
            getgenv().animationTrack:AdjustSpeed(getgenv().AnimationSpeed)
        end
    end
})

stutz:AddToggle("PlayAnimationToggle", {
    Text = "Play Animation",
    Default = false,
    Callback = function(state)
        getgenv().playAnimationEnabled = state
        if state and getgenv().animationTrack then
            getgenv().animationTrack:Play()
            getgenv().animationTrack:AdjustSpeed(getgenv().AnimationSpeed)
            getgenv().isPlaying = true
        elseif not state and getgenv().animationTrack then
            getgenv().animationTrack:Stop()
            getgenv().isPlaying = false
        end
    end
}):AddKeyPicker("PlayAnimationKeybind", {
    Default = "C",
    Text = "Play Animation",
    Mode = "Toggle",
    Callback = function(key)
        if UserInputService:GetFocusedTextBox() then return end
        if getgenv().playAnimationEnabled and getgenv().animationTrack then
            if getgenv().isPlaying then
                getgenv().animationTrack:Stop()
            else
                getgenv().animationTrack:Play()
                getgenv().animationTrack:AdjustSpeed(getgenv().AnimationSpeed)
            end
            getgenv().isPlaying = not getgenv().isPlaying
        end
    end
})
stutz:AddToggle("NoClipToggle", {
    Text = "NoClip",
    Default = false,
    Callback = function(state)
        noClipEnabled = state
    end
}):AddKeyPicker("NoClipKeybindPicker", {
    Default = "J",
    Text = "NoClip",
    Mode = "Toggle",
    Callback = function(state)
        if noClipEnabled then
            local character = game:GetService("Players").LocalPlayer.Character
            if character then
                for _, part in pairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and not part.Name:match("Arm") and not part.Name:match("Leg") then
                        part.CanCollide = state
                    end
                end
            end
        end
    end
})

DesyncBox = Tabs.Character:AddRightGroupbox("Anti Aim")

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

function resetCamera()
    if LocalPlayer.Character then
        local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
        if humanoid then
            workspace.CurrentCamera.CameraSubject = humanoid
        end
    end
end

function toggleDesync(state)
    desync.enabled = state
    if desync.enabled then
        workspace.CurrentCamera.CameraSubject = desync_setback
        Library:Notify("Desync Enabled '" .. desync.mode .. "' matcha.lol $", 2)
    else
        resetCamera()
        Library:Notify("Desync Disabled '" .. desync.mode .. "' matcha.lol  $", 2)
    end
end

function setDesyncMode(mode)
    desync.mode = mode
end

DesyncBox:AddToggle('DesyncToggle', {
    Text = 'Anti Aim',
    Default = false,
    Callback = function(state)
        desync.toggleEnabled = state
        if not state then
            toggleDesync(false)
        end
    end,
}):AddKeyPicker('DesyncKeybind', {
    Default = 'V',
    Text = 'Desync',
    Mode = 'Toggle',
    Callback = function(state)
        if not desync.toggleEnabled or UserInputService:GetFocusedTextBox() then return end
        toggleDesync(not desync.enabled)
    end,
})

DesyncBox:AddDropdown('DesyncMethodDropdown', {
    Values = {"Destroy Cheaters", "Underground", "Void Spam", "Void"},
    Default = "Void",
    Multi = false,
    Text = 'Method',
    Callback = function(selected)
        setDesyncMode(selected)
    end
})

RunService.Heartbeat:Connect(function()
    if desync.enabled and LocalPlayer.Character then
        local rootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            desync.old_position = rootPart.CFrame

            if desync.mode == "Destroy Cheaters" then
                desync.teleportPosition = Vector3.new(11223344556677889900, 1, 1)

            elseif desync.mode == "Underground" then
                desync.teleportPosition = rootPart.Position - Vector3.new(0, 12, 0)

            elseif desync.mode == "Void Spam" then
                desync.teleportPosition = math.random(1, 2) == 1 and desync.old_position.Position or Vector3.new(
                    math.random(10000, 50000),
                    math.random(10000, 50000),
                    math.random(10000, 50000)
                )

            elseif desync.mode == "Void" then
                desync.teleportPosition = Vector3.new(
                    rootPart.Position.X + math.random(-444444, 444444),
                    rootPart.Position.Y + math.random(-444444, 444444),
                    rootPart.Position.Z + math.random(-44444, 44444)
                )
            end

            if desync.mode ~= "Rotation" then
                rootPart.CFrame = CFrame.new(desync.teleportPosition)
                workspace.CurrentCamera.CameraSubject = desync_setback

                RunService.RenderStepped:Wait()

                desync_setback.CFrame = desync.old_position * CFrame.new(0, rootPart.Size.Y / 2 + 0.5, 0)
                rootPart.CFrame = desync.old_position
            end
        end
    end
end)

DesyncBox:AddToggle("AntiLockEnabled", {
	Text = "Anti Lock",
	Default = false,

	Callback = function(Value)
		AntiLock.Enabled = Value
	end,
}):AddKeyPicker("AntiLockKeybind", {
	Default = "B",
	Mode = "Toggle",
	Text = "Anti Lock Key",
	NoUI = false,

	Callback = function()
		AntiLock.Enabled = not AntiLock.Enabled
	end,
})

-- Anti Lock Mode
DesyncBox:AddDropdown("AntiLockMode", {
    Values = { "Custom", "Up", "Down", "VelMultiply", "LookVec", "Reverse", "Confusion", "PredBreaker" },
    Default = "Custom",
    Multi = false,
    Text = "Anti Lock Mode",
    Callback = function(v)
        AntiLock.Mode = v
    end
})

--====================================================================--
--========================= CUSTOM MODE ==============================--
--====================================================================--

DesyncBox:AddSlider("CustomX", {
    Text = "Custom X",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Custom.X = v
    end
})

DesyncBox:AddSlider("CustomY", {
    Text = "Custom Y",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Custom.Y = v
    end
})

DesyncBox:AddSlider("CustomZ", {
    Text = "Custom Z",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Custom.Z = v
    end
})

--====================================================================--
--========================= UP / DOWN ================================--
--====================================================================--

DesyncBox:AddSlider("UpAmount", {
    Text = "Up Amount",
    Min = 1,
    Max = 10000,
    Default = 100,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Up.Amount = v
    end
})

DesyncBox:AddSlider("DownAmount", {
    Text = "Down Amount",
    Min = 1,
    Max = 10000,
    Default = 100,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Down.Amount = v
    end
})

--====================================================================--
--========================= VELOCITY MULTIPLY ========================--
--====================================================================--

DesyncBox:AddInput("VelWalk", {
    Text = "Vel Walk",
    Default = "1.5",
    Numeric = true,
    Finished = true,
    Placeholder = "1.5",
    Callback = function(v)
        AntiLock.VelMultiply.Walk = tonumber(v) or 1.5
    end
})

DesyncBox:AddInput("VelJump", {
    Text = "Vel Jump",
    Default = "1.0",
    Numeric = true,
    Finished = true,
    Placeholder = "1.0",
    Callback = function(v)
        AntiLock.VelMultiply.Jump = tonumber(v) or 1.0
    end
})

--====================================================================--
--========================= LOOKVEC / REVERSE ========================--
--====================================================================--

DesyncBox:AddSlider("LookVecAmt", {
    Text = "LookVec Amount",
    Min = 1,
    Max = 10000,
    Default = 500,
    Rounding = 0,
    Callback = function(v)
        AntiLock.LookVec.Amount = v
    end
})

DesyncBox:AddSlider("ReverseAmt", {
    Text = "Reverse Amount",
    Min = 1,
    Max = 10000,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Reverse.Amount = v
    end
})

DesyncBox:AddDropdown("ReverseType", {
    Values = { "CFrame", "Velocity" },
    Default = "CFrame",
    Multi = false,
    Text = "Reverse Type",
    Callback = function(v)
        AntiLock.Reverse.Type = v
    end
})

--====================================================================--
--========================= CONFUSION ================================--
--====================================================================--

DesyncBox:AddSlider("ConfusionAmt", {
    Text = "Confusion Amount",
    Min = 1,
    Max = 10000,
    Default = 5,
    Rounding = 0,
    Callback = function(v)
        AntiLock.Confusion.Amount = v
    end
})

-- === ANTI LOCK LOGIC (Heartbeat) ===
RunService.Heartbeat:Connect(function()
    if not AntiLock.Enabled or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local vel = hrp.Velocity
    local cf = hrp.CFrame
    local S = AntiLock

    if S.Mode == "Custom" and (S.Custom.X ~= 0 or S.Custom.Y ~= 0 or S.Custom.Z ~= 0) then
        hrp.Velocity = Vector3.new(S.Custom.X, S.Custom.Y, S.Custom.Z)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    elseif S.Mode == "Up" and S.Up.Amount > 0 then
        hrp.Velocity = Vector3.new(vel.X, S.Up.Amount, vel.Z)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    elseif S.Mode == "Down" and S.Down.Amount > 0 then
        hrp.Velocity = Vector3.new(vel.X, -S.Down.Amount, vel.Z)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    elseif S.Mode == "VelMultiply" and (S.VelMultiply.Walk > 0 or S.VelMultiply.Jump > 0) then
        hrp.Velocity = vel * Vector3.new(S.VelMultiply.Walk, S.VelMultiply.Jump, S.VelMultiply.Walk)
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    elseif S.Mode == "LookVec" and S.LookVec.Amount > 0 then
        hrp.Velocity = cf.lookVector * S.LookVec.Amount
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    elseif S.Mode == "Reverse" and S.Reverse.Amount > 0 then
        if S.Reverse.Type == "CFrame" then
            hrp.CFrame = cf - hum.MoveDirection * (S.Reverse.Amount / 10)
        else
            hrp.Velocity = vel * Vector3.new(-S.Reverse.Amount/2.5, 1, -S.Reverse.Amount/2.5)
            RunService.RenderStepped:Wait()
            hrp.Velocity = vel
        end
    elseif S.Mode == "Confusion" and S.Confusion.Amount > 0 then
        hrp.CFrame = cf * CFrame.new(math.random(1,2)==1 and S.Confusion.Amount or -S.Confusion.Amount, 0, 0)
    elseif S.Mode == "PredBreaker" then
        hrp.Velocity = Vector3.zero
        RunService.RenderStepped:Wait()
        hrp.Velocity = vel
    end
end)

getgenv().RemoveShootAnimationsEnabled = false
getgenv().ShootAnimationIds = {
    ["rbxassetid://2807049953"] = true, 
    ["rbxassetid://2809413000"] = true, 
    ["rbxassetid://2809419094"] = true,  
    ["rbxassetid://507768375"] = true,
    ["rbxassetid://507755388"] = true,
    ["rbxassetid://2807049953"] = true,
    ["rbxassetid://2877910736"] = true 
}

getgenv().StopAnimationTracks = function(character)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        for _, track in ipairs(humanoid:GetPlayingAnimationTracks()) do
            if getgenv().ShootAnimationIds[track.Animation.AnimationId] then
                track:Stop()
            end
        end
    end
end

getgenv().MonitorCharacter = function(character)
    character.DescendantAdded:Connect(function(descendant)
        if descendant:IsA("AnimationTrack") and getgenv().RemoveShootAnimationsEnabled then
            if getgenv().ShootAnimationIds[descendant.Animation.AnimationId] then
                descendant:Stop()
            end
        end
    end)
end

getgenv().MonitorPlayers = function()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        local character = player.Character or player.CharacterAdded:Wait()
        getgenv().StopAnimationTracks(character)
        getgenv().MonitorCharacter(character)

        player.CharacterAdded:Connect(function(newCharacter)
            getgenv().StopAnimationTracks(newCharacter)
            getgenv().MonitorCharacter(newCharacter)
        end)
    end

    game:GetService("Players").PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(character)
            getgenv().StopAnimationTracks(character)
            getgenv().MonitorCharacter(character)
        end)
    end)
end

getgenv().MonitorAnimations = function()
    game:GetService("RunService").RenderStepped:Connect(function()
        if getgenv().RemoveShootAnimationsEnabled then
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                local character = player.Character
                if character then
                    getgenv().StopAnimationTracks(character)
                end
            end
        end
    end)
end

GunMods:AddToggle("AntiflingToggle", {
    Text = "remove shoot animations",
    Default = false,
    Callback = function(enabled)
        getgenv().RemoveShootAnimationsEnabled = enabled
        if enabled then
            getgenv().MonitorPlayers()
            task.spawn(getgenv().MonitorAnimations)
        end
    end
})


getgenv().Test = false
getgenv().SoundId = "6899466638"
getgenv().ToolEnabled = false

getgenv().CreateTool = function()
    getgenv().Tool = Instance.new("Tool")
    getgenv().Tool.RequiresHandle = false
    getgenv().Tool.Name = "[Kick]"
    getgenv().Tool.TextureId = "rbxassetid://483225199"
    getgenv().Animation = Instance.new("Animation")
    getgenv().Animation.AnimationId = "rbxassetid://2788306916"
    getgenv().Tool.Activated:Connect(function()
        getgenv().Test = true
        getgenv().Player = game.Players.LocalPlayer
        getgenv().Character = getgenv().Player.Character or getgenv().Player.CharacterAdded:Wait()
        getgenv().Humanoid = getgenv().Character:FindFirstChild("Humanoid")
        if getgenv().Humanoid then
            getgenv().AnimationTrack = getgenv().Humanoid:LoadAnimation(getgenv().Animation)
            getgenv().AnimationTrack:AdjustSpeed(3.4)
            getgenv().AnimationTrack:Play()
        end
        task.wait(0.6)
        getgenv().Boombox = game.Players.LocalPlayer.Backpack:FindFirstChild("[Boombox]")
        if getgenv().Boombox then
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Character
            MainRemote:FireServer("Boombox", tonumber(getgenv().SoundId))
            getgenv().Boombox.RequiresHandle = false
            getgenv().Boombox.Parent = game.Players.LocalPlayer.Backpack
            task.wait(1)
            MainRemote:FireServer("BoomboxStop")
        else
            getgenv().Sound = Instance.new("Sound", workspace)
            getgenv().Sound.SoundId = "rbxassetid://" .. getgenv().SoundId
            getgenv().Sound:Play()
            task.wait(1)
            getgenv().Sound:Stop()
        end
        wait(1.4)
        getgenv().Test = false
    end)
    getgenv().Tool.Parent = game.Players.LocalPlayer:WaitForChild("Backpack")
end

getgenv().RemoveTool = function()
    getgenv().Player = game.Players.LocalPlayer
    getgenv().Tool = getgenv().Player.Backpack:FindFirstChild("[Kick]") or getgenv().Player.Character:FindFirstChild("[Kick]")
    if getgenv().Tool then getgenv().Tool:Destroy() end
end

game:GetService("RunService").Heartbeat:Connect(function()
    if getgenv().Test then
        getgenv().Character = game.Players.LocalPlayer.Character
        if not getgenv().Character then return end
        getgenv().HumanoidRootPart = getgenv().Character:FindFirstChild("HumanoidRootPart")
        if not getgenv().HumanoidRootPart then return end
        getgenv().originalVelocity = getgenv().HumanoidRootPart.Velocity
        getgenv().HumanoidRootPart.Velocity = Vector3.new(getgenv().HumanoidRootPart.CFrame.LookVector.X * 800, 800, getgenv().HumanoidRootPart.CFrame.LookVector.Z * 800)
        game:GetService("RunService").RenderStepped:Wait()
        getgenv().HumanoidRootPart.Velocity = getgenv().originalVelocity
    end
end)

local stuffs = Tabs.Misc:AddRightGroupbox("Stuff")

getgenv().jerkOffEnabled = false

stuffs:AddToggle('JerkOffToggle', {
    Text = 'Jerk Off',
    Default = false,
    Tooltip = 'Adds a Jerk Off tool to your backpack with animation',
    Callback = function(state)
        getgenv().jerkOffEnabled = state
        if state then
            local speaker = game.Players.LocalPlayer
            local humanoid = speaker.Character and speaker.Character:FindFirstChildOfClass("Humanoid")
            local backpack = speaker:FindFirstChild("Backpack")
            if not humanoid or not backpack then
                Library:Notify("Character or backpack not found!", 5)
                return
            end

            local function createJerkOffTool()
                local tool = Instance.new("Tool")
                tool.Name = "Jerk Off"
                tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
                tool.RequiresHandle = false
                tool.Parent = backpack

                local jorkin = false
                local track = nil

                local function stopTomfoolery()
                    jorkin = false
                    if track then
                        track:Stop()
                        track = nil
                    end
                end

                tool.Equipped:Connect(function()
                    jorkin = true
                end)
                tool.Unequipped:Connect(stopTomfoolery)
                humanoid.Died:Connect(stopTomfoolery)

                task.spawn(function()
                    while task.wait() do
                        if not jorkin then continue end
                        local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
                        if not track then
                            local anim = Instance.new("Animation")
                            anim.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
                            track = humanoid:LoadAnimation(anim)
                        end
                        track:Play()
                        track:AdjustSpeed(isR15 and 0.7 or 0.65)
                        track.TimePosition = 0.6
                        task.wait(0.1)
                        while track and track.TimePosition < (isR15 and 0.7 or 0.65) do
                            task.wait(0.1)
                        end
                        if track then
                            track:Stop()
                            track = nil
                        end
                    end
                end)
            end

            createJerkOffTool()
        else
            local speaker = game.Players.LocalPlayer
            local backpack = speaker:FindFirstChild("Backpack")
            local character = speaker.Character
            if backpack then
                local toolInBackpack = backpack:FindFirstChild("Jerk Off")
                if toolInBackpack then
                    toolInBackpack:Destroy()
                end
            end
            if character then
                local toolInCharacter = character:FindFirstChild("Jerk Off")
                if toolInCharacter then
                    toolInCharacter:Destroy()
                end
            end
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(newChar)
    if getgenv().jerkOffEnabled then
        task.wait(0.5)
        local humanoid = newChar:FindFirstChildOfClass("Humanoid")
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if humanoid and backpack then
            local tool = Instance.new("Tool")
            tool.Name = "Jerk Off"
            tool.ToolTip = "in the stripped club. straight up \"jorking it\" . and by \"it\" , haha, well. let's justr say. My peanits."
            tool.RequiresHandle = false
            tool.Parent = backpack

            local jorkin = false
            local track = nil

            local function stopTomfoolery()
                jorkin = false
                if track then
                    track:Stop()
                    track = nil
                end
            end

            tool.Equipped:Connect(function()
                jorkin = true
            end)
            tool.Unequipped:Connect(stopTomfoolery)
            humanoid.Died:Connect(stopTomfoolery)

            task.spawn(function()
                while task.wait() do
                    if not jorkin then continue end
                    local isR15 = humanoid.RigType == Enum.HumanoidRigType.R15
                    if not track then
                        local anim = Instance.new("Animation")
                        anim.AnimationId = isR15 and "rbxassetid://698251653" or "rbxassetid://72042024"
                        track = humanoid:LoadAnimation(anim)
                    end
                    track:Play()
                    track:AdjustSpeed(isR15 and 0.7 or 0.65)
                    track.TimePosition = 0.6
                    task.wait(0.1)
                    while track and track.TimePosition < (isR15 and 0.7 or 0.65) do
                        task.wait(0.1)
                    end
                    if track then
                        track:Stop()
                        track = nil
                    end
                end
            end)
        end
    end
end)

stuffs:AddToggle("ToolToggle", {
    Text = "Pqnd4 kick",
    Default = false,
    Callback = function(state)
        getgenv().ToolEnabled = state
        if state then getgenv().CreateTool() else getgenv().RemoveTool() end
    end
})

game.Players.LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().ToolEnabled then task.wait(1) getgenv().CreateTool() end
end)

local Modifications = Tabs.Misc:AddRightGroupbox("Modifications")

getgenv().Ohio = {
    Fps = 120, 
    Saver = false, 
}
if isDaHood then
	Modifications:AddButton({
	    Text = 'AutoFarm',
	    Func = function()
	        if (not game:IsLoaded()) then 
	            game.Loaded:Wait()
	            task.wait(1)
	        end
	        repeat task.wait(0.1) until (game:GetService("Players").LocalPlayer) and (game:GetService("Players").LocalPlayer.Character)
	        local SG = Instance.new("ScreenGui")
	        SG.Parent = game:GetService("CoreGui")
	        SG.Name = "abcdefg"
	        SG.IgnoreGuiInset = true 
	        local TL = Instance.new("TextLabel")
	        TL.Parent = SG 
	        TL.BackgroundColor3 = Color3.fromRGB(0, 0, 128)
	        TL.Active = false
	        TL.Font = Enum.Font.MontserratMedium
	        TL.TextColor3 = Color3.fromRGB(135, 206, 235)
	        TL.TextSize = 25
	        TL.AnchorPoint = Vector2.new(0.5, 0.5)
	        TL.Position = UDim2.new(0.5, 0, 0.5, 0)
	        TL.Size = UDim2.new(1, 0, 1, 0)
	        local Player = game:GetService("Players").LocalPlayer
	        local Cashiers = workspace.Cashiers 
	        local Drop = workspace.Ignored.Drop
	        local Dis = false
	        local Broken = 0 
	        local StartTick = os.time()
	        _G.Disable = function()
	            Dis = true
	            game:GetService("RunService"):Set3dRenderingEnabled(true)
	            setfpscap(60)
	            game:GetService("CoreGui").abcdefg:Destroy()
	        end
	        Player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	        Player.CameraMaxZoomDistance = 6
	        Player.CameraMinZoomDistance = 6
	        TL.Text = "MilkyBoy AUTOPARM\n@"..Player.Name.."\n$999,999,999"
	        pcall(function()local a=game:GetService("ReplicatedStorage").MainEvent;local b={"CHECKER_1","TeleportDetect","OneMoreTime"}local c;c=hookmetamethod(game,"__namecall",function(...)local d={...}local self=d[1]local e=getnamecallmethod()local f=getcallingscript()if e=="FireServer"and self==a and table.find(b,d[2])then return end return c(...)end)end)
	        local Click = function(Part)
	            local Input = game:GetService("VirtualInputManager")
	            local Pos = workspace.Camera:WorldToScreenPoint(Part.Position)
	            local T = os.time()
	            if (Part:GetAttribute("OriginalPos") == nil) then 
	                Part:SetAttribute("OriginalPos", Part.Position)
	            end
	            repeat 
	                Part.CFrame = (workspace.Camera.CFrame + workspace.Camera.CFrame.LookVector * 1) * CFrame.Angles(90, 0, 0)
	                Input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, true, game, 1)
	                task.wait()
	                Input:SendMouseButtonEvent(workspace.Camera.ViewportSize.X/2, workspace.Camera.ViewportSize.Y/2, 0, false, game, 1)
	            until (Part == nil) or (Part:FindFirstChild("ClickDetector") == nil) or (os.time()-T>=2)
	        end
	        local AntiSit = function(Char)
	            task.wait(1)    
	            local Hum = Char:WaitForChild("Humanoid")
	            Hum.Seated:Connect(function()
	                warn("SITTING")
	                Hum.Sit = false
	                Hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	                task.wait(0.3)
	                Hum.Jump = true
	            end)
	        end
	        local GetCash = function()
	            local Found = {}
	            
	            for i,v in pairs(Drop:GetChildren()) do 
	                if (v.Name == "MoneyDrop") then 
	                    local Pos = nil 
	                    
	                    if (v:GetAttribute("OriginalPos") ~= nil) then 
	                        Pos = v:GetAttribute("OriginalPos")
	                    else 
	                        Pos = v.Position
	                    end
	                    if (Pos - Player.Character.HumanoidRootPart.Position).Magnitude <= 17 then 
	                        Found[#Found+1] = v 
	                    end
	                end
	            end
	            return Found
	        end
	        local GetCashier = function()
	            for i,v in pairs(Cashiers:GetChildren()) do 
	                if (i == 15) and (Vector3.new(-625, 10, -286) - v.Head.Position).Magnitude <= 20 then 
	                    v:MoveTo(Vector3.new(-622.948, 24, -286.52))
	                    for x,z in pairs(v:GetChildren()) do 
	                        if (z:IsA("Part")) or (z:IsA("BasePart")) then 
	                            z.CanCollide = false 
	                        end
	                    end
	                elseif (i == 16) and (Vector3.new(-625, 10, -286) - v.Head.Position).Magnitude <= 20 then
	                    v:MoveTo(Vector3.new(-629.948, 24, -286.52))
	                    for x,z in pairs(v:GetChildren()) do 
	                        if (z:IsA("Part")) or (z:IsA("BasePart")) then 
	                            z.CanCollide = false 
	                        end
	                    end
	                end
	                
	                if (v.Humanoid.Health > 0) then 
	                    return v 
	                end
	            end
	            return nil
	        end
	        local To = function(CF)
	            Player.Character.HumanoidRootPart.CFrame = CF 
	            Player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
	        end
	        task.spawn(function()
	            while true and task.wait() do 
	                if (Player.Character == nil) or (Player.Character:FindFirstChild("FULLY_LOADED_CHAR") == nil) or (Dis == true) then 
	                    return print("NO")
	                end
	                
	                local Cashier = nil
	                repeat 
	                    Cashier = GetCashier()
	                    if (Player.Backpack:FindFirstChild("Combat") ~= nil) then 
	                        Player.Backpack.Combat.Parent = Player.Character 
	                    end
	                    task.wait()
	                until (Cashier ~= nil)
	                
	                repeat 
	                    To( (Cashier.Head.CFrame+Vector3.new(0, -2.5, 0)) * CFrame.Angles(math.rad(90), 0, 0) ) 
	                    task.wait()
	                    Player.Character.Combat:Activate()
	                until (Cashier.Humanoid.Health <= 0)
	                Broken += 1
	                To(Cashier.Head.CFrame + Cashier.Head.CFrame.LookVector * Vector3.new(0, 2, 0))
	                for i,v in pairs(Player.Character:GetChildren()) do 
	                    if (v:IsA("Tool")) then 
	                        v.Parent = Player.Backpack 
	                    end
	                end
	                
	                local Cash = GetCash()
	                
	                for i,v in pairs(Cash) do 
	                    Click(v)
	                end
	            end
	        end)
	        local StartCash = Player.DataFolder.Currency.Value
	        task.spawn(function()
	            while true and task.wait(0.5) do 
	                print(TL.Text)
	                TL.Text = "autofarm - @MilkyBoy0216\n@"..Player.Name.."\n$"..tostring(Player.DataFolder.Currency.Value):reverse():gsub("...","%0,",math.floor((#tostring(Player.DataFolder.Currency.Value)-1)/3)):reverse().."\nATMS: "..tostring(Broken).."\n"..string.format("%02i:%02i:%02i", (os.time()-StartTick)/60^2, (os.time()-StartTick)/60%60, (os.time()-StartTick)%60).."\nProfit: $"..tostring(Player.DataFolder.Currency.Value-StartCash):reverse():gsub("...","%0,",math.floor((#tostring(Player.DataFolder.Currency.Value-StartCash)-1)/3)):reverse().."\n"..tostring(GetCashier())
	            end
	        end)
	        Player.Idled:Connect(function()
	            for i = 1, 10 do 
	                game:GetService("VirtualUser"):Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame) 
	                task.wait(0.2) 
	                game:GetService("VirtualUser"):Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
	                task.wait(0.2)
	            end
	        end)
	        pcall(function() UserSettings().GameSettings.MasterVolume = 0 end)
	        pcall(function() settings().Rendering.QualityLevel = "Level01" end)
	        Player.CharacterAdded:Connect(AntiSit)
	        task.spawn(function()
	            task.wait(3)
	            AntiSit(Player.Character)
	        end)
	        for i = 1, 10 do 
	            setfpscap(getgenv().Ohio.Fps)
	            task.wait(0.1)
	        end
	        if (getgenv().Ohio.Saver == true) then 
	            game:GetService("RunService"):Set3dRenderingEnabled(false) 
	        else 
	            SG.Enabled = false
	        end
	        Library:Notify('AutoFarm Activated!', 5)
	    end,
	    Tooltip = 'Activate AutoFarm',
	    DoubleClick = false,
	    Disabled = false,
	    Visible = true
	})
	
	Modifications:AddSlider('FpsSlider', {
	    Text = 'Set FPS',
	    Default = 120,
	    Min = 1,
	    Max = 300,
	    Rounding = 0,
	    Compact = false,
	    HideMax = false,
	    Callback = function(Value)
	        getgenv().Ohio.Fps = Value
	        Library:Notify('FPS set to: ' .. Value, 3)
	    end,
	    Disabled = false,
	    Visible = true
	})
end
local antiStompActive = false
local flashbackActive = false
local lastPosition = nil

local function startAntiStomp()
    local RunService = game:GetService("RunService")

    local function checkAndKill()
        local chr = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local hum = chr:WaitForChild("Humanoid", 5)
        local bodyEffects = chr:WaitForChild("BodyEffects", 5)

        if not bodyEffects or not hum then
            warn("BodyEffects or Humanoid not found in the character!")
            return
        end

        local koValue = bodyEffects:WaitForChild("K.O", 5)
        if not koValue then
            warn("K.O value not found!")
            return
        end

        local connection
        connection = RunService.Heartbeat:Connect(function()
            if not antiStompActive then
                connection:Disconnect()
                return
            end

            if koValue.Value == true and hum.Health > 0 then
                if flashbackActive then
                    lastPosition = chr:GetPrimaryPartCFrame()
                end
                hum.Health = 0
            end
        end)
    end

    checkAndKill()

    LocalPlayer.CharacterAdded:Connect(function(newCharacter)
        if antiStompActive then
            checkAndKill()

            if flashbackActive and lastPosition then
                local rootPart = newCharacter:WaitForChild("HumanoidRootPart", 5)
                if rootPart then
                    while (rootPart.Position - lastPosition.Position).Magnitude > 5 do
                        rootPart.CFrame = lastPosition
                        task.wait()
                    end
                end
                lastPosition = nil
            end
        end
    end)
end

Modifications:AddToggle('AntiStomp', {
    Text = 'Anti Stomp',
    Default = false,
    Callback = function(state)
        antiStompActive = state
        if state then
            startAntiStomp()
        end
    end,
})

Modifications:AddToggle('Flashback', {
    Text = 'Flashback',
    Default = false,
    Callback = function(state)
        flashbackActive = state
    end,
})

if isDaHood then
    -- === CHỈ LOAD KHI LÀ DA HOOD ===
    getgenv().XZQW_ENABLED = false
    getgenv().HIDE_ANIMATIONS = false
    getgenv().YRWL_Connection___ = {}
    getgenv().BlockedAnimations = {
        "rbxassetid://2788289281",
        "rbxassetid://507766388",
        "rbxassetid://2788292075",
        "rbxassetid://278829075",
        "rbxassetid://4798175381",
        "rbxassetid://2953512033",
        "rbxassetid://2788309982",
        "rbxassetid://2788312709",
        "rbxassetid://2788313790",
        "rbxassetid://2788316350",
        "rbxassetid://2788315673",
        "rbxassetid://2788314837"
    }

    -- Fix animation block
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    pcall(function()
        ReplicatedStorage:WaitForChild("ClientAnimations").Block.AnimationId = "rbxassetid://0"
    end)

    local RunService = game:GetService("RunService")
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local function startAutoBlock()
        table.insert(getgenv().YRWL_Connection___, RunService.Stepped:Connect(function()
            if getgenv().XZQW_ENABLED then
                local character = LocalPlayer.Character
                if character and character:FindFirstChild("BodyEffects") then
                    local bodyEffects = character.BodyEffects
                    if bodyEffects:FindFirstChild("Block") then
                        bodyEffects.Block:Destroy()
                    end
                    local tool = character:FindFirstChildWhichIsA("Tool")
                    if tool and tool:FindFirstChild("Ammo") then
                        MainRemote:FireServer("Block", false)
                    else
                        MainRemote:FireServer("Block", true)
                        task.wait()
                        MainRemote:FireServer("Block", false)
                    end
                end
            end
        end))
    end

    local function stopAutoBlock()
        for _, conn in ipairs(getgenv().YRWL_Connection___) do
            conn:Disconnect()
        end
        table.clear(getgenv().YRWL_Connection___)
    end

    local function startHidingAnimations()
        RunService:BindToRenderStep("Hide - Block", Enum.RenderPriority.Last.Value, function()
            if getgenv().HIDE_ANIMATIONS then
                local character = LocalPlayer.Character
                if character then
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                            if table.find(getgenv().BlockedAnimations, track.Animation.AnimationId) then
                                track:Stop()
                            end
                        end
                    end
                end
            end
        end)
    end

    local function stopHidingAnimations()
        pcall(function()
            RunService:UnbindFromRenderStep("Hide - Block")
        end)
    end

    -- UI Obsidian
    local RightGroupbox = Tabs.Character:AddRightGroupbox('Auto Block Settings')
    RightGroupbox:AddToggle('AutoBlock', {
        Text = 'God Block',
        Default = false,
        Callback = function(state)
            getgenv().XZQW_ENABLED = state
            if state then startAutoBlock() else stopAutoBlock() end
        end,
    })

    local Depbox = RightGroupbox:AddDependencyBox()
    Depbox:AddToggle('HideAnimations', {
        Text = 'Hide Animations',
        Default = false,
        Callback = function(state)
            getgenv().HIDE_ANIMATIONS = state
            if state then startHidingAnimations() else stopHidingAnimations() end
        end,
    })

    Depbox:SetupDependencies({ { Toggles.AutoBlock, true } })

else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Auto Block")
end

if isDaHood then
    -- === CHỈ LOAD CASH AURA KHI LÀ DA HOOD ===
    getgenv().CASH_AURA_ENABLED = false
    getgenv().CASH_AURA_RANGE = 17
    getgenv().COOLDOWN = 0.2

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Workspace = game:GetService("Workspace")

    local function GetCash()
        local Found = {}
        local Drop = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild("Drop")
        if not Drop then return Found end

        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return Found end

        for _, v in Drop:GetChildren() do
            if v.Name == "MoneyDrop" then
                local pos = v:GetAttribute("OriginalPos") or v.Position
                if (pos - root.Position).Magnitude <= getgenv().CASH_AURA_RANGE then
                    table.insert(Found, v)
                end
            end
        end
        return Found
    end

    local function CashAura()
        while getgenv().CASH_AURA_ENABLED do
            local cash = GetCash()
            for _, v in cash do
                local cd = v:FindFirstChildOfClass("ClickDetector")
                if cd then fireclickdetector(cd) end
            end
            task.wait(getgenv().COOLDOWN)
        end
    end

    -- UI Obsidian Lib
    Modifications:AddToggle('Cash_Aura_Toggle', {
        Text = 'Cash Aura',
        Default = false,
        Callback = function(v)
            getgenv().CASH_AURA_ENABLED = v
            if v then task.spawn(CashAura) end
        end
    })

    Modifications:AddSlider('CashAuraRange', {
        Text = 'Cash Aura Range',
        Default = 17,
        Min = 10,
        Max = 50,
        Rounding = 1,
        Callback = function(v) getgenv().CASH_AURA_RANGE = v end
    })

    Modifications:AddSlider('CashAuraCooldown', {
        Text = 'Cash Aura Cooldown',
        Default = 0.2,
        Min = 0.1,
        Max = 1,
        Rounding = 2,
        Callback = function(v) getgenv().COOLDOWN = v end
    })

else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Cash Aura")
end

local autoReloadEnabled = false
local reloadMethod = "Normal"

function startAutoReload()
    _G.Connection = game:GetService("RunService").RenderStepped:Connect(function()
        if not autoReloadEnabled then
            _G.Connection:Disconnect()
            return
        end

        local tool = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
        local ammo = tool and tool:FindFirstChild("Ammo")
        if ammo and ammo.Value <= (reloadMethod == "Rifle" and 1 or 0) then
            MainRemote:FireServer("Reload", tool)
            task.wait(3.7)
        end
    end)
end

Modifications:AddToggle('AntiStomp', {
    Text = 'Auto Reload',
    Default = false,

    Callback = function(state)
        autoReloadEnabled = state
        _G.AutoReloadEnabled = state
        if state then
            startAutoReload()
        end
    end,
})
task.wait(1)
Modifications:AddDropdown('MyDropdown', {
    Values = { 'Normal', 'Rifle'},
    Default = "Normal",
    Multi = false,

    Text = 'Reload Method',

    Callback = function(selected)
        reloadMethod = selected
    end
})
if isDaHood then
	local AutoBuy = Tabs.Misc:AddLeftGroupbox("Shop")
	local Workspace = game:GetService("Workspace")
	
	local ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
	local SelectedItem, Debounce = nil, false
	local AutoBuyOnRespawn = false
	local AmmoBuyCount = 0
	
	local ShopItems = {
	    "[Taco] - $4",
	    "[Hamburger] - $11",
	    "[Revolver] - $1421",
	    "[AUG] - $2131",
	    "[Rifle] - $1694",
	    "[LMG] - $4098",
        "[GrenadeLauncher] - $10927",
        "[Double-Barrel SG] - $1530",
	}
	
	AutoBuy:AddDropdown('Shop_Dropdown', {
	    Values = ShopItems,
	    Default = 1,
	    Multi = false,
	    Text = 'Select an Item',
	    Callback = function(Value)
	        SelectedItem = Value
	    end
	})
	
	local function GetCharacterRoot()
	    local Character = LocalPlayer.Character
	    return Character and Character:FindFirstChild("HumanoidRootPart")
	end
	
	local function BuyItem(ItemName)
	    if not ItemName or Debounce then return end
	    Debounce = true
	
	    local wasDesyncEnabled = desync.enabled
	    if wasDesyncEnabled then
	        toggleDesync(false)
	        task.wait(0.1)
	    end
	
	    local RootPart = GetCharacterRoot()
	    if not RootPart then 
	        Library:Notify("[ERROR] No HumanoidRootPart found!", 3)
	        Debounce = false
	        return
	    end
	
	    local ItemModel = ShopFolder:FindFirstChild(ItemName)
	    if ItemModel then
	        local ClickDetector = ItemModel:FindFirstChildOfClass("ClickDetector")
	        if ClickDetector then
	            local OriginalPosition = RootPart.CFrame
	
	            RootPart.CFrame = CFrame.new(ItemModel.Head.Position + Vector3.new(0, 3, 0))
	            task.wait(0.2)
	
	            fireclickdetector(ClickDetector)
	
	            Library:Notify("Purchased: " .. ItemName, 3)
	
	            RootPart.CFrame = OriginalPosition
	        else
	            Library:Notify("[ERROR] ClickDetector not found in " .. ItemName, 3)
	        end
	    else
	        Library:Notify("[ERROR] Item not found: " .. ItemName, 3)
	    end
	
	    if wasDesyncEnabled then
	        task.wait(0.2)
	        toggleDesync(true)
	    end
	
	    Debounce = false
	end
	
	local function BuyAmmo()
	    if not SelectedItem or Debounce then return end
	
	    local AmmoMap = {
	        ["[Revolver] - $1421"] = "12 [Revolver Ammo] - $82",
	        ["[AUG] - $2131"] = "90 [AUG Ammo] - $87",
	        ["[LMG] - $4098"] = "200 [LMG Ammo] - $328",
	        ["[Rifle] - $1694"] = "5 [Rifle Ammo] - $273",
            ["[GrenadeLauncher] - $10927"] = "12 [GrenadeLauncher Ammo] - $3278",
	        ["[Double-Barrel SG] - $1530"] = "18 [Double-Barrel SG Ammo] - $66",
	    }
	
	    local AmmoItem = AmmoMap[SelectedItem]
	    if AmmoItem then
	        BuyItem(AmmoItem)
	    else
	        Library:Notify("[ERROR] No ammo available.", 3)
	    end
	end
	
	local function AutoBuyOnRespawnHandler()
	    if not AutoBuyOnRespawn or not SelectedItem then return end
	
	    BuyItem(SelectedItem)
	
	    if AmmoBuyCount < 3 then
	        for i = 1, 3 do
	            BuyAmmo()
	            task.wait(0.5)
	        end
	        AmmoBuyCount = 3
	    end
	end
	
	AutoBuy:AddToggle('AutoBuyOnRespawn', {
	    Text = 'Auto Buy on Respawn',
	    Default = false,
	    Callback = function(state)
	        AutoBuyOnRespawn = state
	        AmmoBuyCount = 0
	    end
	})
	
	local buy = AutoBuy:AddButton({
	    Text = 'Buy Item',
	    Func = function()
	        BuyItem(SelectedItem)
	    end,
	    DoubleClick = false,
	    Tooltip = 'Buys the selected item'
	})
	
	buy:AddButton({
	    Text = 'Buy Ammo',
	    Func = function()
	        BuyAmmo()
	    end,
	    DoubleClick = false,
	    Tooltip = 'Buys ammo for the selected weapon'
	})
	
	LocalPlayer.CharacterAdded:Connect(function()
	    task.wait(1)
	    ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
	    AutoBuyOnRespawnHandler()
	end)
	
else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Auto Buy")
end
Modifications:AddToggle('AntiVoid', {
    Text = 'Anti Void',
    Default = false,

    Callback = function(immatouchyoumaddie)
		if immatouchyoumaddie then
			workspace.FallenPartsDestroyHeight = -math.huge
		else
			Workspace.FallenPartsDestroyHeight = -50
		end
    end,
})

local antiSlowConnection  -- Biến để lưu connection của Heartbeat
Modifications:AddToggle('AntiSlowToggle', {
    Text = 'Anti Slow',
    Default = false,
    Tooltip = 'Removes slowdown effects like NoJumping, ReduceWalk, etc.',
    Callback = function(Value)
        getgenv().antiSlowEnabled = Value  -- Lưu trạng thái toggle
        local LocalPlayer = game:GetService("Players").LocalPlayer
        local RunService = game:GetService("RunService")

        if Value then
            -- Bật anti-slow: Kết nối Heartbeat và chạy logic
            antiSlowConnection = RunService.Heartbeat:Connect(function()
                if getgenv().antiSlowEnabled then
                    local character = LocalPlayer.Character
                    if character then
                        local bodyEffects = character:FindFirstChild("BodyEffects")
                        if bodyEffects then
                            local movement = bodyEffects:FindFirstChild("Movement")
                            if movement then
                                local noJumping = movement:FindFirstChild("NoJumping")
                                if noJumping then noJumping:Destroy() end
                                
                                local reduceWalk = movement:FindFirstChild("ReduceWalk")
                                if reduceWalk then reduceWalk:Destroy() end
                                
                                local noWalkSpeed = movement:FindFirstChild("NoWalkSpeed")
                                if noWalkSpeed then noWalkSpeed:Destroy() end
                            end
                            
                            local reload = bodyEffects:FindFirstChild("Reload")
                            if reload and reload.Value then
                                reload.Value = false
                            end
                        end
                    end
                end
            end)
            Library:Notify("Anti-Slow Enabled", 3)
        else
            -- Tắt anti-slow: Ngắt kết nối Heartbeat
            if antiSlowConnection then
                antiSlowConnection:Disconnect()
                antiSlowConnection = nil
            end
            Library:Notify("Anti-Slow Disabled", 3)
        end
    end
})

if isDaHood then
    -- === CHỈ LOAD AUTO ARMOR KHI LÀ DA HOOD ===
    getgenv().autoArmorEnabled = false
    getgenv().autoFArmorEnabled = false
    getgenv().armorThreshold = 75
    getgenv().fArmorThreshold = 75

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local Workspace = game:GetService("Workspace")

    local dataFolder = LocalPlayer:WaitForChild("DataFolder")
    local armorInfo = dataFolder:WaitForChild("Information"):FindFirstChild("ArmorSave")
    local fireArmorInfo = dataFolder:WaitForChild("Information"):FindFirstChild("FireArmorSave")

    local armorShop = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild("Shop") and Workspace.Ignored.Shop:FindFirstChild("[High-Medium Armor] - $2513")
    local fireArmorShop = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild("Shop") and Workspace.Ignored.Shop:FindFirstChild("[Fire Armor] - $2623")

    local armorClickDetector = armorShop and armorShop:FindFirstChild("ClickDetector")
    local fireArmorClickDetector = fireArmorShop and fireArmorShop:FindFirstChild("ClickDetector")

    -- Kiểm tra điều kiện mua
    local function canBuyArmor()
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("Humanoid") then return false end
        if char.Humanoid.Health <= 1 then return false end
        local bodyEffects = char:FindFirstChild("BodyEffects")
        if bodyEffects and bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value then return false end
        return true
    end

    -- Teleport + mua
    local function teleportAndBuy(shop, detector)
        local char = LocalPlayer.Character
        if not char or not char.PrimaryPart or not shop or not detector then return end

        local origCFrame = char.PrimaryPart.CFrame
        task.wait(0.1)

        char:SetPrimaryPartCFrame(shop.Head.CFrame * CFrame.new(0, 3.1, 0))
        task.wait(0.2)

        fireclickdetector(detector)
        task.wait(0.1)

        char:SetPrimaryPartCFrame(origCFrame)
        task.wait(0.1)
    end

    -- Mua Armor thường
    local function buyArmor()
        if armorInfo and getgenv().autoArmorEnabled and tonumber(armorInfo.Value) < getgenv().armorThreshold and canBuyArmor() then
            if armorShop and armorClickDetector then
                local wasDesync = desync and desync.enabled
                if wasDesync then toggleDesync(false) end

                teleportAndBuy(armorShop, armorClickDetector)

                if wasDesync then toggleDesync(true) end
            end
        end
    end

    -- Mua Fire Armor
    local function buyFireArmor()
        if fireArmorInfo and getgenv().autoFArmorEnabled and tonumber(fireArmorInfo.Value) < getgenv().fArmorThreshold and canBuyArmor() then
            if fireArmorShop and fireArmorClickDetector then
                local wasDesync = desync and desync.enabled
                if wasDesync then toggleDesync(false) end

                teleportAndBuy(fireArmorShop, fireArmorClickDetector)

                if wasDesync then toggleDesync(true) end
            end
        end
    end

    -- Loop kiểm tra
    local function startArmorLoop()
        task.spawn(function()
            while task.wait(0.3) do
                if getgenv().autoArmorEnabled or getgenv().autoFArmorEnabled then
                    buyArmor()
                    buyFireArmor()
                end
            end
        end)
    end

    -- Khi respawn
    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1.5)
        startArmorLoop()
    end)

    -- Bắt đầu ngay
    startArmorLoop()

    -- === UI OBSIDIAN LIB ===
    Modifications:AddToggle('AutoArmorToggle', {
        Text = 'Auto Armor',
        Default = false,
        Callback = function(v) getgenv().autoArmorEnabled = v end
    })

    Modifications:AddSlider('ArmorThresholdSlider', {
        Text = 'Armor Threshold',
        Default = 75,
        Min = 1,
        Max = 130,
        Rounding = 0,
        Callback = function(v) getgenv().armorThreshold = v end
    })

    Modifications:AddToggle('AutoFArmorToggle', {
        Text = 'Auto Fire Armor',
        Default = false,
        Callback = function(v) getgenv().autoFArmorEnabled = v end
    })

    Modifications:AddSlider('FArmorThresholdSlider', {
        Text = 'Fire Armor Threshold',
        Default = 75,
        Min = 1,
        Max = 130,
        Rounding = 0,
        Callback = function(v) getgenv().fArmorThreshold = v end
    })

else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Auto Armor")
end

-- === CODE SAU VẪN CHẠY BÌNH THƯỜNG (ngoài if) ===
Modifications:AddToggle("AntiSitToggle", {
    Text = "Anti Sit",
    Default = false,
    Callback = function(state)
        getgenv().antiSitEnabled = state
        for _, seat in ipairs(workspace:GetDescendants()) do
            if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
                seat.CanTouch = not state
            end
        end

        workspace.DescendantAdded:Connect(function(seat)
            if getgenv().antiSitEnabled and (seat:IsA("Seat") or seat:IsA("VehicleSeat")) then
                seat.CanTouch = false
            end
        end)
    end
})
if isDaHood then
	getgenv().AntiRPGDesyncEnabled, getgenv().GrenadeDetectionEnabled, getgenv().AntiRPGDesyncLoop = false, false, nil
	local RunService, Workspace, LocalPlayer = game:GetService("RunService"), game.Workspace, game.Players.LocalPlayer
	
	local function IsThreatNear(threatName)
	    local Threat = Workspace:FindFirstChild("Ignored") and Workspace.Ignored:FindFirstChild(threatName)
	    local HRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	    return Threat and HRP and (Threat.Position - HRP.Position).Magnitude < 16
	end
	
	local function StartThreatDetection()
	    if getgenv().AntiRPGDesyncLoop then return end
	
	    getgenv().AntiRPGDesyncLoop = RunService.PostSimulation:Connect(function()
	        local HRP, Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
	        if not HRP or not Humanoid then return end
	
	        local RPGThreat = Workspace.Ignored:FindFirstChild("Model") and Workspace.Ignored.Model:FindFirstChild("Launcher")
	        local GrenadeThreat = IsThreatNear("Handle")
	
	        if (getgenv().AntiRPGDesyncEnabled and RPGThreat or getgenv().GrenadeDetectionEnabled and GrenadeThreat) then
	            local Offset = Vector3.new(math.random(-100, 100), math.random(50, 150), math.random(-100, 100))
	            Humanoid.CameraOffset = -Offset
	            local OldCFrame = HRP.CFrame
	            HRP.CFrame = CFrame.new(HRP.CFrame.Position + Offset)
	            RunService.RenderStepped:Wait()
	            HRP.CFrame = OldCFrame
	        end
	    end)
	
	    LocalPlayer.CharacterAdded:Connect(function()
	        task.wait(1)
	        if getgenv().AntiRPGDesyncEnabled or getgenv().GrenadeDetectionEnabled then StartThreatDetection() end
	    end)
	end
	
	local function StopThreatDetection()
	    if getgenv().AntiRPGDesyncLoop then
	        getgenv().AntiRPGDesyncLoop:Disconnect()
	        getgenv().AntiRPGDesyncLoop = nil
	    end
	end
	
	Modifications:AddToggle('RPGDetection', {
	    Text = 'RPG detection',
	    Default = false,
	    Callback = function(state)
	        getgenv().AntiRPGDesyncEnabled = state
	        if state or getgenv().GrenadeDetectionEnabled then StartThreatDetection() else StopThreatDetection() end
	    end,
	})
	
	Modifications:AddToggle('GrenadeDetection', {
	    Text = 'grenade detection',
	    Default = false,
	    Callback = function(state)
	        getgenv().GrenadeDetectionEnabled = state
	        if state or getgenv().AntiRPGDesyncEnabled then StartThreatDetection() else StopThreatDetection() end
	    end,
	})
	
else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua antirpg,grenade detection and redeem code")
end
local webhook = Modifications:AddButton('Redeem Codes', function()
	local codes = {
		"MUSIC", "KINGPIN",
		"BUBU", "BRAINROT", "LUXE", "TURBO", "BLOSSOM", "VALENTINES24", "ShortCake", "Beary"
	}
	local mainEvent = game:GetService("ReplicatedStorage"):WaitForChild("MainEvent") or nil

	for _, code in pairs(codes) do
		mainEvent:FireServer("EnterPromoCode", code)
		Library:Notify("Trying code: " .. code .. " matcha.lol | Private", 5)
		task.wait(4.2)
	end
end)
webhook:AddButton('Force Reset', function()
    game.Players.LocalPlayer.Character.Humanoid.Health = 0
end)
if isDaHood then
	Modifications:AddButton('Unjail', function()
	    local plr = game.Players.LocalPlayer
	    if plr.DataFolder.Currency.Value >= 125 then
	        plr.Character.HumanoidRootPart.CFrame = CFrame.new(-270.94, 20.327, -242.38)--Key
	        plr.Character.HumanoidRootPart.CFrame = CFrame.new(-270.94, 20.327, -242.38)--Key(Backup)
	        wait()
	        fireclickdetector(game:GetService("Workspace").Ignored.Shop["[Key] - $125"].ClickDetector)
	        wait(.1)
	        fireclickdetector(game:GetService("Workspace").Ignored.Shop["[Key] - $125"].ClickDetector)
	        fireclickdetector(game:GetService("Workspace").Ignored.Shop["[Key] - $125"].ClickDetector)
	        repeat wait() until plr.Backpack:FindFirstChild('[Key]')
	        local Hum = plr.Character:FindFirstChildOfClass('Humanoid')
	        if Hum.Health > 0 then
	            key1 = plr.Backpack:FindFirstChild('[Key]')
	            if key1 then
	                Hum:EquipTool(key1)
	                for i,v in pairs(game:GetService'Players'.LocalPlayer.Character:GetChildren())do
	                    if v:isA("Tool") then
	                        plr.Character.Humanoid:EquipTool(key1)
	                        plr.Character.HumanoidRootPart.CFrame = CFrame.new(-485.668, 23.631, -285.169)--Bank
	                        v:Activate()
	                    end
	                end
	            end
	        end
	    elseif plr.DataFolder.Currency.Value < 125 then
	        Library:Notify('Not Enough Cash (Required 125$)', 5)
	    end
	end)
else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Unjail")
end
local ChatEnabled = true
if chatWindow then
    chatWindow.Enabled = ChatEnabled
end

Modifications:AddToggle('Chat Spy', {
    Text = 'Chat Spy',
    Default = true,
    Callback = function(state)
        ChatEnabled = state
        if chatWindow then
            chatWindow.Enabled = state
        end
    end,
})
if isDaHood then
	local flashbackBox = Tabs.Misc:AddRightGroupbox("Detection")
	local antiModEnabled, checkModFriendsEnabled, groupCheckEnabled = false, false, false
	local antiModMethod = "Notify"
	
	
	local modList = {
	    163721789, 15427717, 201454243, 822999, 63794379, 17260230, 28357488,
	    93101606, 8195210, 89473551, 16917269, 85989579, 1553950697, 476537893,
	    155627580, 31163456, 7200829, 25717070, 201454243, 15427717, 63794379,
	    16138978, 60660789, 17260230, 16138978, 1161411094, 9125623, 11319153,
	    34758833, 194109750, 35616559, 1257271138, 28885841, 23558830, 25717070,
	    4255947062, 29242182, 2395613299, 3314981799, 3390225662, 2459178,
	    2846299656, 2967502742, 7001683347, 7312775547, 328566086, 170526279,
	    99356639, 352087139, 6074834798, 2212830051, 3944434729, 5136267958,
	    84570351, 542488819, 1830168970, 3950637598, 1962396833
	}
	
	local groupIDs = {10604500, 17215700}
	
	local function detectModerators()
	    while antiModEnabled do
	        task.wait(1)
	        for _, player in ipairs(Players:GetPlayers()) do
	            if table.find(modList, player.UserId) then
	                local message = "⚠️ MODERATOR DETECTED: " .. player.DisplayName .. " (" .. player.Name .. ")"
	                if antiModMethod == "Notify" then
	                    Library:Notify(message, 3)
	                else
	                    game.Players.LocalPlayer:Kick("🚨 " .. message)
	                end
	            end
	
	            if groupCheckEnabled then
	                for _, groupID in ipairs(groupIDs) do
	                    local success, isInGroup = pcall(function() return player:IsInGroup(groupID) end)
	                    if success and isInGroup then
	                        local roleName = "Unknown Role"
	                        pcall(function()
	                            roleName = player:GetRoleInGroup(groupID)
	                        end)
	
	                        local groupMessage = "⚠️ [" .. roleName .. "] JOINED: " .. player.DisplayName .. " (" .. player.Name .. ")"
	                        if antiModMethod == "Notify" then
	                            Library:Notify(groupMessage, 3)
	                        else
	                            game.Players.LocalPlayer:Kick("🚨 " .. groupMessage)
	                        end
	                    end
	                end
	            end
	        end
	    end
	end
	
	local function checkFriendsWithMods()
	    while checkModFriendsEnabled do
	        task.wait(1)
	        for _, player in ipairs(Players:GetPlayers()) do
	            pcall(function()
	                for _, friend in pairs(player:GetFriendsAsync():GetCurrentPage()) do
	                    if table.find(modList, friend.Id) then
	                        local friendMessage = "⚠️ " .. player.DisplayName .. " (" .. player.Name .. ") is friends with a Moderator!"
	                        Library:Notify(friendMessage, 4)
	                        break
	                    end
	                end
	            end)
	        end
	    end
	end
	
	local AntiModToggle = flashbackBox:AddToggle("AntiModToggle", {
	    Text = "Mod Detection",
	    Default = false,
	    Callback = function(Value)
	        antiModEnabled = Value
	        Library:Notify(antiModEnabled and "✅ Anti-Mod Enabled" or "⚠️ Anti-Mod Disabled", 3)
	        if antiModEnabled then task.spawn(detectModerators) end
	    end
	})
	
	local AntiModDepbox = flashbackBox:AddDependencyBox()
	AntiModDepbox:SetupDependencies({ { AntiModToggle, true } })
	
	AntiModDepbox:AddDropdown("AntiModMethod", {
	    Values = {"Notify", "Kick"},
	    Default = "Notify",
	    Multi = false,
	    Text = "Anti-Mod Method",
	    Callback = function(Value)
	        antiModMethod = Value
	        Library:Notify("ℹ️ Anti-Mod Method set to: " .. antiModMethod, 3)
	    end
	})
	
	AntiModDepbox:AddToggle("CheckModFriends", {
	    Text = "Friended Checking",
	    Tooltip = "Detects if any player is friends with a Moderator",
	    Default = false,
	    Callback = function(Value)
	        checkModFriendsEnabled = Value
	        Library:Notify(checkModFriendsEnabled and "✅ Checking for Mod Friends Enabled" or "⚠️ Checking for Mod Friends Disabled", 3)
	        if checkModFriendsEnabled then task.spawn(checkFriendsWithMods) end
	    end
	})
	
	local GroupCheckDepbox = AntiModDepbox:AddDependencyBox()
	GroupCheckDepbox:SetupDependencies({ { AntiModToggle, true } })
	
	GroupCheckDepbox:AddToggle("GroupCheck", {
	    Text = "Group Role Checking",
	    Tooltip = "Detects if any player is in the restricted groups",
	    Default = false,
	    Callback = function(Value)
	        groupCheckEnabled = Value
	        Library:Notify(groupCheckEnabled and "✅ Group Membership Check Enabled" or "⚠️ Group Membership Check Disabled", 3)
	        if groupCheckEnabled then task.spawn(detectModerators) end
	    end
	})
else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua antimod")
end
if isDaHood then
	Modifications:AddButton('Animations Packs', function()
	    repeat
	        wait()
	    until game:IsLoaded() and game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
	    
	    local uiLoaded = false  -- Track whether the UI has been loaded
	    local notificationShown = false  -- Track if the notification has been shown
	    
	    -- Function to load UI
	    local function loadUI()
	        local player = game.Players.LocalPlayer
	        local animationPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
	        local animationPlusPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
	    
	        if animationPack and not animationPack.Visible then
	            animationPack.Visible = true
	        end
	    
	        if animationPlusPack and not animationPlusPack.Visible then
	            animationPlusPack.Visible = true
	        end
	    
	        uiLoaded = true
	    end
	    
	    -- Function to unload UI
	    local function unloadUI()
	        local player = game.Players.LocalPlayer
	        local animationPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack")
	        local animationPlusPack = player.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
	    
	        if animationPack and animationPack.Visible then
	            animationPack.Visible = false
	        end
	    
	        if animationPlusPack and animationPlusPack.Visible then
	            animationPlusPack.Visible = false
	        end
	    
	        uiLoaded = false
	    end
	    
	    -- Function to show notification only once
	    local function showNotificationOnce()
	        if not notificationShown then
	            Library:Notify("animationpack Loaded 🎭 matcha.lol 🎭", 5)
	            notificationShown = true
	        end
	    end
	    
	    -- Trigger notification
	    showNotificationOnce()
	    
	    -- Toggle UI
	    if uiLoaded then
	        unloadUI()
	    else
	        loadUI()
	    end
	    
	    -- Xóa animations cũ
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lean") then
	        game.ReplicatedStorage.ClientAnimations.Lean:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Lay") then
	        game.ReplicatedStorage.ClientAnimations.Lay:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance1") then
	        game.ReplicatedStorage.ClientAnimations.Dance1:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Dance2") then
	        game.ReplicatedStorage.ClientAnimations.Dance2:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Greet") then
	        game.ReplicatedStorage.ClientAnimations.Greet:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Chest Pump") then
	        game.ReplicatedStorage.ClientAnimations["Chest Pump"]:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Praying") then
	        game.ReplicatedStorage.ClientAnimations.Praying:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("TheDefault") then
	        game.ReplicatedStorage.ClientAnimations.TheDefault:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Sturdy") then
	        game.ReplicatedStorage.ClientAnimations.Sturdy:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Rossy") then
	        game.ReplicatedStorage.ClientAnimations.Rossy:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("Griddy") then
	        game.ReplicatedStorage.ClientAnimations.Griddy:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("TPose") then
	        game.ReplicatedStorage.ClientAnimations.TPose:Destroy()
	    end
	    if game.ReplicatedStorage.ClientAnimations:FindFirstChild("SpeedBlitz") then
	        game.ReplicatedStorage.ClientAnimations.SpeedBlitz:Destroy()
	    end
	    
	    -- Thêm animations mới
	    local Animations = game.ReplicatedStorage.ClientAnimations
	    
	    local LeanAnimation = Instance.new("Animation", Animations)
	    LeanAnimation.Name = "Lean"
	    LeanAnimation.AnimationId = "rbxassetid://3152375249"
	    
	    local LayAnimation = Instance.new("Animation", Animations)
	    LayAnimation.Name = "Lay"
	    LayAnimation.AnimationId = "rbxassetid://3152378852"
	    
	    local Dance1Animation = Instance.new("Animation", Animations)
	    Dance1Animation.Name = "Dance1"
	    Dance1Animation.AnimationId = "rbxassetid://3189773368"
	    
	    local Dance2Animation = Instance.new("Animation", Animations)
	    Dance2Animation.Name = "Dance2"
	    Dance2Animation.AnimationId = "rbxassetid://3189776546"
	    
	    local GreetAnimation = Instance.new("Animation", Animations)
	    GreetAnimation.Name = "Greet"
	    GreetAnimation.AnimationId = "rbxassetid://3189777795"
	    
	    local ChestPumpAnimation = Instance.new("Animation", Animations)
	    ChestPumpAnimation.Name = "Chest Pump"
	    ChestPumpAnimation.AnimationId = "rbxassetid://3189779152"
	    
	    local PrayingAnimation = Instance.new("Animation", Animations)
	    PrayingAnimation.Name = "Praying"
	    PrayingAnimation.AnimationId = "rbxassetid://3487719500"
	    
	    local TheDefaultAnimation = Instance.new("Animation", Animations)
	    TheDefaultAnimation.Name = "TheDefault"
	    TheDefaultAnimation.AnimationId = "rbxassetid://507771019"  -- Sửa ID chuẩn
	    
	    local SturdyAnimation = Instance.new("Animation", Animations)
	    SturdyAnimation.Name = "Sturdy"
	    SturdyAnimation.AnimationId = "rbxassetid://11710524717"
	    
	    local RossyAnimation = Instance.new("Animation", Animations)
	    RossyAnimation.Name = "Rossy"
	    RossyAnimation.AnimationId = "rbxassetid://11710527244"
	    
	    local GriddyAnimation = Instance.new("Animation", Animations)
	    GriddyAnimation.Name = "Griddy"
	    GriddyAnimation.AnimationId = "rbxassetid://11710529220"
	    
	    local TPoseAnimation = Instance.new("Animation", Animations)
	    TPoseAnimation.Name = "TPose"
	    TPoseAnimation.AnimationId = "rbxassetid://11710524200"
	    
	    local SpeedBlitzAnimation = Instance.new("Animation", Animations)
	    SpeedBlitzAnimation.Name = "SpeedBlitz"
	    SpeedBlitzAnimation.AnimationId = "rbxassetid://11710541744"
	    
	    -- Hàm xử lý animations
	    local function AnimationPack(Character)
	        Character:WaitForChild("Humanoid")
	        repeat
	            wait()
	        until game.Players.LocalPlayer.Character:FindFirstChild("FULLY_LOADED_CHAR") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPack") and game.Players.LocalPlayer.PlayerGui.MainScreenGui:FindFirstChild("AnimationPlusPack")
	    
	        local AnimationPack = game:GetService("Players").LocalPlayer.PlayerGui.MainScreenGui.AnimationPack
	        local AnimationPackPlus = game:GetService("Players").LocalPlayer.PlayerGui.MainScreenGui.AnimationPlusPack
	        local ScrollingFrame = AnimationPack.ScrollingFrame
	        local CloseButton = AnimationPack.CloseButton
	        local ScrollingFramePlus = AnimationPackPlus.ScrollingFrame
	        local CloseButtonPlus = AnimationPackPlus.CloseButton
	    
	        local Lean = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LeanAnimation)
	        local Lay = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(LayAnimation)
	        local Dance1 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance1Animation)
	        local Dance2 = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(Dance2Animation)
	        local Greet = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(GreetAnimation)
	        local ChestPump = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(ChestPumpAnimation)
	        local Praying = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(PrayingAnimation)
	        local TheDefault = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(TheDefaultAnimation)
	        local Sturdy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(SturdyAnimation)
	        local Rossy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(RossyAnimation)
	        local Griddy = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(GriddyAnimation)
	        local TPose = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(TPoseAnimation)
	        local SpeedBlitz = game:GetService("Players").LocalPlayer.Character.Humanoid:LoadAnimation(SpeedBlitzAnimation)
	    
	        AnimationPack.Visible = true
	        AnimationPackPlus.Visible = true
	    
	        ScrollingFrame.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	        ScrollingFramePlus.UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	    
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Lean" then
	                    v.Name = "LeanButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Lay" then
	                    v.Name = "LayButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Dance1" then
	                    v.Name = "Dance1Button"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Dance2" then
	                    v.Name = "Dance2Button"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Greet" then
	                    v.Name = "GreetButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Chest Pump" then
	                    v.Name = "ChestPumpButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFrame:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Praying" then
	                    v.Name = "PrayingButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "The Default" then
	                    v.Name = "TheDefaultButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Sturdy" then
	                    v.Name = "SturdyButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Rossy" then
	                    v.Name = "RossyButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Griddy" then
	                    v.Name = "GriddyButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "T Pose" then
	                    v.Name = "TPoseButton"
	                end
	            end
	        end
	        for i,v in pairs(ScrollingFramePlus:GetChildren()) do
	            if v.Name == "TextButton" then
	                if v.Text == "Speed Blitz" then
	                    v.Name = "SpeedBlitzButton"
	                end
	            end
	        end
	    
	        local function Stop()
	            Lean:Stop()
	            Lay:Stop()
	            Dance1:Stop()
	            Dance2:Stop()
	            Greet:Stop()
	            ChestPump:Stop()
	            Praying:Stop()
	            TheDefault:Stop()
	            Sturdy:Stop()
	            Rossy:Stop()
	            Griddy:Stop()
	            TPose:Stop()
	            SpeedBlitz:Stop()
	        end
	    
	        local LeanTextButton = ScrollingFrame.LeanButton
	        local LayTextButton = ScrollingFrame.LayButton
	        local Dance1TextButton = ScrollingFrame.Dance1Button
	        local Dance2TextButton = ScrollingFrame.Dance2Button
	        local GreetTextButton = ScrollingFrame.GreetButton
	        local ChestPumpTextButton = ScrollingFrame.ChestPumpButton
	        local PrayingTextButton = ScrollingFrame.PrayingButton
	        local TheDefaultTextButton = ScrollingFramePlus.TheDefaultButton
	        local SturdyTextButton = ScrollingFramePlus.SturdyButton
	        local RossyTextButton = ScrollingFramePlus.RossyButton
	        local GriddyTextButton = ScrollingFramePlus.GriddyButton
	        local TPoseTextButton = ScrollingFramePlus.TPoseButton
	        local SpeedBlitzTextButton = ScrollingFramePlus.SpeedBlitzButton
	    
	        AnimationPack.MouseButton1Click:Connect(function()
	            if ScrollingFrame.Visible == false then
	                ScrollingFrame.Visible = true
	                CloseButton.Visible = true
	                AnimationPackPlus.Visible = false
	            end
	        end)
	        AnimationPackPlus.MouseButton1Click:Connect(function()
	            if ScrollingFramePlus.Visible == false then
	                ScrollingFramePlus.Visible = true
	                CloseButtonPlus.Visible = true
	                AnimationPack.Visible = false
	            end
	        end)
	        CloseButton.MouseButton1Click:Connect(function()
	            if ScrollingFrame.Visible == true then
	                ScrollingFrame.Visible = false
	                CloseButton.Visible = false
	                AnimationPackPlus.Visible = true
	            end
	        end)
	        CloseButtonPlus.MouseButton1Click:Connect(function()
	            if ScrollingFramePlus.Visible == true then
	                ScrollingFramePlus.Visible = false
	                CloseButtonPlus.Visible = false
	                AnimationPack.Visible = true
	            end
	        end)
	    
	        LeanTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Lean:Play()
	        end)
	        LayTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Lay:Play()
	        end)
	        Dance1TextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Dance1:Play()
	        end)
	        Dance2TextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Dance2:Play()
	        end)
	        GreetTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Greet:Play()
	        end)
	        ChestPumpTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            ChestPump:Play()
	        end)
	        PrayingTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Praying:Play()
	        end)
	        TheDefaultTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            TheDefault:Play()
	        end)
	        SturdyTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Sturdy:Play()
	        end)
	        RossyTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Rossy:Play()
	        end)
	        GriddyTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            Griddy:Play()
	        end)
	        TPoseTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            TPose:Play()
	        end)
	        SpeedBlitzTextButton.MouseButton1Click:Connect(function()
	            Stop()
	            SpeedBlitz:Play()
	        end)
	    
	        game:GetService("Players").LocalPlayer.Character.Humanoid.Running:Connect(function()
	            Stop()
	        end)
	    
	        game:GetService("Players").LocalPlayer.CharacterAdded:Connect(function()
	            Stop()
	        end)
	    end
	    
	    AnimationPack(game.Players.LocalPlayer.Character)
	    game.Players.LocalPlayer.CharacterAdded:Connect(AnimationPack)
	end)
else
    -- === BỎ QUA NẾU KHÔNG PHẢI DA HOOD ===
    print("Không phải Da Hood → Bỏ qua Animationpack free")
end

local LeftGroupBox = Tabs.Misc:AddLeftGroupbox("Animation")

local KeepOnDeath = false

local AnimationOptions = {
    ["Idle1"] = "http://www.roblox.com/asset/?id=180435571",
    ["Idle2"] = "http://www.roblox.com/asset/?id=180435792",
    ["Walk"] = "http://www.roblox.com/asset/?id=180426354",
    ["Run"] = "http://www.roblox.com/asset/?id=180426354",
    ["Jump"] = "http://www.roblox.com/asset/?id=125750702",
    ["Climb"] = "http://www.roblox.com/asset/?id=180436334",
    ["Fall"] = "http://www.roblox.com/asset/?id=180436148"
}

local AnimationSets = {
    ["Default"] = {
        idle1 = "http://www.roblox.com/asset/?id=180435571",
        idle2 = "http://www.roblox.com/asset/?id=180435792",
        walk = "http://www.roblox.com/asset/?id=180426354",
        run = "http://www.roblox.com/asset/?id=180426354",
        jump = "http://www.roblox.com/asset/?id=125750702",
        climb = "http://www.roblox.com/asset/?id=180436334",
        fall = "http://www.roblox.com/asset/?id=180436148"
    },
    ["Ninja"] = {
        idle1 = "http://www.roblox.com/asset/?id=656117400",
        idle2 = "http://www.roblox.com/asset/?id=656118341",
        walk = "http://www.roblox.com/asset/?id=656121766",
        run = "http://www.roblox.com/asset/?id=656118852",
        jump = "http://www.roblox.com/asset/?id=656117878",
        climb = "http://www.roblox.com/asset/?id=656114359",
        fall = "http://www.roblox.com/asset/?id=656115606"
    },
    ["Superhero"] = {
        idle1 = "http://www.roblox.com/asset/?id=616111295",
        idle2 = "http://www.roblox.com/asset/?id=616113536",
        walk = "http://www.roblox.com/asset/?id=616122287",
        run = "http://www.roblox.com/asset/?id=616117076",
        jump = "http://www.roblox.com/asset/?id=616115533",
        climb = "http://www.roblox.com/asset/?id=616104706",
        fall = "http://www.roblox.com/asset/?id=616108001"
    },
    ["Robot"] = {
        idle1 = "http://www.roblox.com/asset/?id=616088211",
        idle2 = "http://www.roblox.com/asset/?id=616089559",
        walk = "http://www.roblox.com/asset/?id=616095330",
        run = "http://www.roblox.com/asset/?id=616091570",
        jump = "http://www.roblox.com/asset/?id=616090535",
        climb = "http://www.roblox.com/asset/?id=616086039",
        fall = "http://www.roblox.com/asset/?id=616087089"
    },
    ["Cartoon"] = {
        idle1 = "http://www.roblox.com/asset/?id=742637544",
        idle2 = "http://www.roblox.com/asset/?id=742638445",
        walk = "http://www.roblox.com/asset/?id=742640026",
        run = "http://www.roblox.com/asset/?id=742638842",
        jump = "http://www.roblox.com/asset/?id=742637942",
        climb = "http://www.roblox.com/asset/?id=742636889",
        fall = "http://www.roblox.com/asset/?id=742637151"
    },
    ["Catwalk"] = {
        idle1 = "http://www.roblox.com/asset/?id=133806214992291",
        idle2 = "http://www.roblox.com/asset/?id=94970088341563",
        walk = "http://www.roblox.com/asset/?id=109168724482748",
        run = "http://www.roblox.com/asset/?id=81024476153754",
        jump = "http://www.roblox.com/asset/?id=116936326516985",
        climb = "http://www.roblox.com/asset/?id=119377220967554",
        fall = "http://www.roblox.com/asset/?id=92294537340807"
    },
    ["Zombie"] = {
        idle1 = "http://www.roblox.com/asset/?id=616158929",
        idle2 = "http://www.roblox.com/asset/?id=616160636",
        walk = "http://www.roblox.com/asset/?id=616168032",
        run = "http://www.roblox.com/asset/?id=616163682",
        jump = "http://www.roblox.com/asset/?id=616161997",
        climb = "http://www.roblox.com/asset/?id=616156119",
        fall = "http://www.roblox.com/asset/?id=616157476"
    },
    ["Mage"] = {
        idle1 = "http://www.roblox.com/asset/?id=707742142",
        idle2 = "http://www.roblox.com/asset/?id=707855907",
        walk = "http://www.roblox.com/asset/?id=707897309",
        run = "http://www.roblox.com/asset/?id=707861613",
        jump = "http://www.roblox.com/asset/?id=707853694",
        climb = "http://www.roblox.com/asset/?id=707826056",
        fall = "http://www.roblox.com/asset/?id=707829716"
    },
    ["Pirate"] = {
        idle1 = "http://www.roblox.com/asset/?id=750785693",
        idle2 = "http://www.roblox.com/asset/?id=750782770",
        walk = "http://www.roblox.com/asset/?id=750785693",
        run = "http://www.roblox.com/asset/?id=750782770",
        jump = "http://www.roblox.com/asset/?id=750782770",
        climb = "http://www.roblox.com/asset/?id=750782770",
        fall = "http://www.roblox.com/asset/?id=750782770"
    },
    ["Knight"] = {
        idle1 = "http://www.roblox.com/asset/?id=657595757",
        idle2 = "http://www.roblox.com/asset/?id=657568135",
        walk = "http://www.roblox.com/asset/?id=657552124",
        run = "http://www.roblox.com/asset/?id=657564596",
        jump = "http://www.roblox.com/asset/?id=657560148",
        climb = "http://www.roblox.com/asset/?id=657556206",
        fall = "http://www.roblox.com/asset/?id=657552124"
    },
    ["Vampire"] = {
        idle1 = "http://www.roblox.com/asset/?id=1083465857",
        idle2 = "http://www.roblox.com/asset/?id=1083465857",
        walk = "http://www.roblox.com/asset/?id=1083465857",
        run = "http://www.roblox.com/asset/?id=1083465857",
        jump = "http://www.roblox.com/asset/?id=1083465857",
        climb = "http://www.roblox.com/asset/?id=1083465857",
        fall = "http://www.roblox.com/asset/?id=1083465857"
    },
    ["Bubbly"] = {
        idle1 = "http://www.roblox.com/asset/?id=910004836",
        idle2 = "http://www.roblox.com/asset/?id=910009958",
        walk = "http://www.roblox.com/asset/?id=910034870",
        run = "http://www.roblox.com/asset/?id=910025107",
        jump = "http://www.roblox.com/asset/?id=910016857",
        climb = "http://www.roblox.com/asset/?id=910009958",
        fall = "http://www.roblox.com/asset/?id=910009958"
    },
    ["Elder"] = {
        idle1 = "http://www.roblox.com/asset/?id=845386501",
        idle2 = "http://www.roblox.com/asset/?id=845397899",
        walk = "http://www.roblox.com/asset/?id=845403856",
        run = "http://www.roblox.com/asset/?id=845386501",
        jump = "http://www.roblox.com/asset/?id=845386501",
        climb = "http://www.roblox.com/asset/?id=845386501",
        fall = "http://www.roblox.com/asset/?id=845386501"
    },
    ["Toy"] = {
        idle1 = "http://www.roblox.com/asset/?id=782841498",
        idle2 = "http://www.roblox.com/asset/?id=782841498",
        walk = "http://www.roblox.com/asset/?id=782841498",
        run = "http://www.roblox.com/asset/?id=782841498",
        jump = "http://www.roblox.com/asset/?id=782841498",
        climb = "http://www.roblox.com/asset/?id=782841498",
        fall = "http://www.roblox.com/asset/?id=782841498"
    }
}

local function applyCustomAnimations(character)
    if not character then return end

    local Animate = character:FindFirstChild("Animate")
    if not Animate then return end

    local ClonedAnimate = Animate:Clone()

    ClonedAnimate.idle.Animation1.AnimationId = AnimationOptions["Idle1"]
    ClonedAnimate.idle.Animation2.AnimationId = AnimationOptions["Idle2"]
    ClonedAnimate.walk.WalkAnim.AnimationId = AnimationOptions["Walk"]
    ClonedAnimate.run.RunAnim.AnimationId = AnimationOptions["Run"]
    ClonedAnimate.jump.JumpAnim.AnimationId = AnimationOptions["Jump"]
    ClonedAnimate.climb.ClimbAnim.AnimationId = AnimationOptions["Climb"]
    ClonedAnimate.fall.FallAnim.AnimationId = AnimationOptions["Fall"]

    Animate:Destroy()
    ClonedAnimate.Parent = character
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if KeepOnDeath then
        task.wait(1)
        applyCustomAnimations(character)
    end
end)

local animationNames = {"Default", "Ninja", "Superhero", "Robot", "Cartoon", "Catwalk", "Zombie", "Mage", "Pirate", "Knight", "Vampire", "Bubbly", "Elder", "Toy"}

LeftGroupBox:AddDropdown("Idle1Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle1",
    Callback = function(Value)
        AnimationOptions["Idle1"] = AnimationSets[Value].idle1
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("Idle2Dropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Idle2",
    Callback = function(Value)
        AnimationOptions["Idle2"] = AnimationSets[Value].idle2
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("WalkDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Walk",
    Callback = function(Value)
        AnimationOptions["Walk"] = AnimationSets[Value].walk
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("RunDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Run",
    Callback = function(Value)
        AnimationOptions["Run"] = AnimationSets[Value].run
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("JumpDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Jump",
    Callback = function(Value)
        AnimationOptions["Jump"] = AnimationSets[Value].jump
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("ClimbDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Climb",
    Callback = function(Value)
        AnimationOptions["Climb"] = AnimationSets[Value].climb
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddDropdown("FallDropdown", {
    Values = animationNames,
    Default = 0,
    Multi = false,
    Text = "Fall",
    Callback = function(Value)
        AnimationOptions["Fall"] = AnimationSets[Value].fall
        applyCustomAnimations(LocalPlayer.Character)
    end
})

LeftGroupBox:AddToggle("MyToggle", {
    Text = "Keep On Death",
    Default = false,
    Tooltip = "Keeps the animation after respawning",
    Callback = function(Value)
        KeepOnDeath = Value
    end
})

getgenv().SelectedTarget = nil
getgenv().SelectedTeleportType = "unsafe"
getgenv().PlayerList = {}
getgenv().groupIDs = {10604500, 17215700}
getgenv().autoKillEnabled = false
getgenv().orbitStompEnabled = false
getgenv().lastPosition = nil
getgenv().strafeEnabled = false
getgenv().AutoAmmoEnabled = false
getgenv().oldPosition = nil
getgenv().invisiblePart = nil
getgenv().isActionRunning = false
getgenv().stompTargetEnabled = false

function knockTarget(targetPlayer)
    local character = targetPlayer.Character
    local humanoid = character:FindFirstChild("Humanoid")
    local bodyEffects = character:FindFirstChild("BodyEffects")
    
    if not bodyEffects or not humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    local koValue = bodyEffects:WaitForChild("K.O", 5)
    if not koValue then
        warn("K.O value not found!")
        return
    end
    
    local oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    task.spawn(function()
        while not koValue.Value and getgenv().isActionRunning do
            local targetPosition = character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(targetPosition + Vector3.new(0, 20, 0))
            
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                MainRemote:FireServer("ShootGun", tool:FindFirstChild("Handle"), tool:FindFirstChild("Handle").CFrame.Position, character.Head.Position, character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(oldPosition)
    end)
end


function bringTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, 20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                MainRemote:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            MainRemote:FireServer("Grabbing", false)
            task.wait(0.2)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")

        task.wait(0.2)
        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stompTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    
    if not getgenv().bodyEffects or not getgenv().humanoid then
        warn("BodyEffects or Humanoid not found in the character!")
        return
    end
    
    getgenv().koValue = getgenv().bodyEffects:WaitForChild("K.O", 5)
    getgenv().sDeathValue = getgenv().bodyEffects:WaitForChild("SDeath", 5)
    if not getgenv().koValue or not getgenv().sDeathValue then
        warn("K.O or SDeath value not found!")
        return
    end
    
    getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
    task.wait(1)
    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character.HumanoidRootPart.Position
            LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, 20, 0))
            
            getgenv().tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                MainRemote:FireServer("ShootGun", getgenv().tool:FindFirstChild("Handle"), getgenv().tool:FindFirstChild("Handle").CFrame.Position, getgenv().character.Head.Position, getgenv().character.Head, Vector3.new(0, 0, -1))
            end
            
            task.wait()
        end
        
        while not getgenv().sDeathValue.Value and getgenv().isActionRunning do
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart = LocalPlayer.Character:WaitForChild("HumanoidRootPart")
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                RunService.RenderStepped:Wait()
            end
            MainRemote:FireServer("Stomp")
            task.wait()
        end
        
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function voidTarget(targetPlayer)
    getgenv().character = targetPlayer.Character
    if not getgenv().character then return end
    
    getgenv().humanoid = getgenv().character:FindFirstChild("Humanoid")
    getgenv().bodyEffects = getgenv().character:FindFirstChild("BodyEffects")
    if not getgenv().bodyEffects or not getgenv().humanoid then return end
    
    getgenv().koValue = getgenv().bodyEffects:FindFirstChild("K.O")
    if not getgenv().koValue then return end

    getgenv().localCharacter = LocalPlayer.Character
    if not getgenv().localCharacter then return end

    getgenv().humanoidRootPart = getgenv().localCharacter:FindFirstChild("HumanoidRootPart")
    if not getgenv().humanoidRootPart then return end
    
    getgenv().oldPosition = getgenv().humanoidRootPart.Position
    getgenv().isActionRunning = true

    task.spawn(function()
        while not getgenv().koValue.Value and getgenv().isActionRunning do
            getgenv().targetPosition = getgenv().character:FindFirstChild("HumanoidRootPart") and getgenv().character.HumanoidRootPart.Position or nil
            if getgenv().targetPosition then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().targetPosition + Vector3.new(0, 20, 0))
            end
            
            getgenv().tool = getgenv().localCharacter:FindFirstChildWhichIsA("Tool")
            if getgenv().tool and getgenv().tool:FindFirstChild("Ammo") then
                MainRemote:FireServer(
                    "ShootGun",
                    getgenv().tool:FindFirstChild("Handle"),
                    getgenv().tool:FindFirstChild("Handle").CFrame.Position,
                    getgenv().character.Head.Position,
                    getgenv().character.Head,
                    Vector3.new(0, 0, -1)
                )
            end

            task.wait()
        end
        
        repeat
            getgenv().upperTorso = getgenv().character:FindFirstChild("UpperTorso")
            if getgenv().upperTorso then
                getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().upperTorso.Position + Vector3.new(0, 3, 0))
                game:GetService("RunService").RenderStepped:Wait()
            end
            
            MainRemote:FireServer("Grabbing", false)
            task.wait(0.2)
        until getgenv().character:FindFirstChild("GRABBING_CONSTRAINT")

        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-1000, 10000, -1000)
        task.wait(0.3)
        MainRemote:FireServer("Grabbing", false)
        task.wait(0.2)
        getgenv().humanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end)
end

function stopAllActions()
    getgenv().isActionRunning = false
    if getgenv().oldPosition then
        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(getgenv().oldPosition)
    end
    Library:Notify("All actions stopped.", 5)
end

getgenv().Services = {
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer
}

getgenv().PlayerInfo = Tabs.Players:AddLeftGroupbox('Player Info')

PlayerInfo:AddToggle('view', {
    Text = 'View',
    Default = false,
    Callback = function(state)
        if state and getgenv().SelectedTarget then
            local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("Humanoid") then
                workspace.CurrentCamera.CameraSubject = targetPlayer.Character.Humanoid
            end
        else
            workspace.CurrentCamera.CameraSubject = Services.LocalPlayer.Character.Humanoid
        end
    end,
})

PlayerInfo:AddButton('Teleport', function()
    local targetPlayer = Services.Players:FindFirstChild(getgenv().SelectedTarget)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        Services.LocalPlayer.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end)

PlayerInfo:AddDropdown('teleportType', {
    Values = { 'safe', 'unsafe' },
    Default = 'unsafe',
    Multi = false,
    Text = 'Teleport Type',
    Callback = function(value)
        getgenv().SelectedTeleportType = value
    end,
})
--[[ MÀU CHỦ ĐẠO
local MATCHA = Color3.fromRGB(152, 251, 152)
local DARK_BG = Color3.fromRGB(25, 25, 25)
local DARK_BORDER = Color3.fromRGB(15, 15, 15)
local TEXT_WHITE = Color3.fromRGB(230, 255, 230)
local HOVER_BG = Color3.fromRGB(40, 40, 40)
--------------------------------------------------------------
-- HÀM KÉO MƯỢT
--------------------------------------------------------------
local function makeSmoothDraggable(frame, speed)
    speed = speed or 0.15
    local dragging, dragInput, dragStart, startPos
    local function update(input)
        local delta = input.Position - dragStart
        local goal = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
        TweenService:Create(
            frame,
            TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { Position = goal }
        ):Play()
    end
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end
--------------------------------------------------------------
-- GUI KHỞI TẠO
--------------------------------------------------------------
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MatchaPlayerList_" .. tostring(math.random(1e6, 1e7))
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 180, 0, 260)
Frame.Position = UDim2.new(0.05, 0, 0.25, 0)
Frame.BackgroundColor3 = DARK_BG
Frame.BorderColor3 = DARK_BORDER
Frame.BackgroundTransparency = 0
Frame.Visible = true
Frame.Parent = ScreenGui
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 10)
makeSmoothDraggable(Frame, 0.15)
-- Đổ bóng nhẹ
local Shadow = Instance.new("ImageLabel")
Shadow.Name = "Shadow"
Shadow.Image = "rbxassetid://1316045217"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.6
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, -10)
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(10, 10, 118, 118)
Shadow.ZIndex = 0
Shadow.Parent = Frame
-- Gradient matcha
local Grad = Instance.new("UIGradient")
Grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, MATCHA),
    ColorSequenceKeypoint.new(1, DARK_BG)
})
Grad.Rotation = 270
Grad.Parent = Frame
--------------------------------------------------------------
-- TIÊU ĐỀ
--------------------------------------------------------------
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 0, 28)
Title.Position = UDim2.new(0, 5, 0, 4)
Title.BackgroundTransparency = 1
Title.Text = "🌿 Matcha Player List"
Title.TextColor3 = MATCHA
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Center
Title.Parent = Frame
--------------------------------------------------------------
-- KHUNG DANH SÁCH
--------------------------------------------------------------
local Scroller = Instance.new("ScrollingFrame")
Scroller.Size = UDim2.new(1, -8, 1, -70)
Scroller.Position = UDim2.new(0, 4, 0, 35)
Scroller.BackgroundTransparency = 1
Scroller.ScrollBarThickness = 4
Scroller.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroller.Parent = Frame
local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Parent = Scroller
Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroller.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)
--------------------------------------------------------------
-- CẬP NHẬT DANH SÁCH NGƯỜI CHƠI
--------------------------------------------------------------
local function UpdateList()
    for _, c in pairs(Scroller:GetChildren()) do
        if c:IsA("TextButton") then
            c:Destroy()
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -4, 0, 28)
            btn.BackgroundColor3 = DARK_BG
            btn.BackgroundTransparency = 0.25
            btn.TextColor3 = TEXT_WHITE
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            btn.AutoButtonColor = false
            btn.TextXAlignment = Enum.TextXAlignment.Center
            btn.Parent = Scroller
            btn.BorderSizePixel = 0
            Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
            local function refresh()
                local mark = ""
                if getgenv().SelectedTarget == p.Name then
                    mark = " ✓"
                elseif table.find(getgenv().whitelist or {}, p.Name) then
                    mark = " ✩"
                end
                btn.Text = p.DisplayName .. " (@" .. p.Name .. ")" .. mark
            end
            refresh()
            btn.MouseEnter:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.05}):Play()
            end)
            btn.MouseLeave:Connect(function()
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundTransparency = 0.25}):Play()
            end)
            btn.MouseButton1Click:Connect(function()
                if getgenv().SelectedTarget == p.Name then
                    getgenv().SelectedTarget = nil
                    Library:Notify("Untargeted.", 2)
                else
                    getgenv().SelectedTarget = p.Name
                    Library:Notify("Selected: " .. p.DisplayName .. " (@" .. p.Name .. ")", 2.5)
                end
                UpdateList()
            end)
        end
    end
end
UpdateList()
Players.PlayerAdded:Connect(UpdateList)
Players.PlayerRemoving:Connect(UpdateList)
--------------------------------------------------------------
-- NÚT WHITELIST
--------------------------------------------------------------
local addWhitelistBtn = Instance.new("TextButton")
addWhitelistBtn.Text = "+ Add Whitelist"
addWhitelistBtn.Font = Enum.Font.GothamBold
addWhitelistBtn.TextSize = 13
addWhitelistBtn.BackgroundColor3 = MATCHA
addWhitelistBtn.TextColor3 = DARK_BG
addWhitelistBtn.Position = UDim2.new(0, 10, 1, -32)
addWhitelistBtn.Size = UDim2.new(1, -20, 0, 24)
addWhitelistBtn.Parent = Frame
Instance.new("UICorner", addWhitelistBtn).CornerRadius = UDim.new(0, 6)
addWhitelistBtn.MouseEnter:Connect(function()
    TweenService:Create(addWhitelistBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 255, 180)}):Play()
end)
addWhitelistBtn.MouseLeave:Connect(function()
    TweenService:Create(addWhitelistBtn, TweenInfo.new(0.15), {BackgroundColor3 = MATCHA}):Play()
end)
addWhitelistBtn.MouseButton1Click:Connect(function()
    if getgenv().SelectedTarget then
        local targetName = getgenv().SelectedTarget
        getgenv().whitelist = getgenv().whitelist or {}
        local idx = table.find(getgenv().whitelist, targetName)
        if idx then
            table.remove(getgenv().whitelist, idx)
            Library:Notify(targetName .. " removed from whitelist", 3)
        else
            table.insert(getgenv().whitelist, targetName)
            Library:Notify(targetName .. " added to whitelist", 3)
        end
        getgenv().SelectedTarget = nil
        UpdateList()
    else
        Library:Notify("Select a player first!", 2.5)
    end
end)]]
PlayerInfo:AddToggle('ShowPlayerListToggle', {
    Text = 'Show Player List',
    Default = false,
    Tooltip = 'Bật/tắt danh sách người chơi',
    Callback = function(v) showGUI(v) end
}):AddKeyPicker('QuickTargetKey', {
    Default = 'H',
    Text = 'Quick Target',
    Mode = 'Toggle',
    Tooltip = 'Chọn nhanh target gần nhất / untarget',
    Callback = function()
        if UserInputService:GetFocusedTextBox() then return end
        if getgenv().SelectedTarget then
            getgenv().SelectedTarget = nil
            Library:Notify("Đã untarget.", 2)
            UpdateList()
            return
        end
        local cam = workspace.CurrentCamera
        local ref = UserInputService.TouchEnabled and (cam.ViewportSize/2) or UserInputService:GetMouseLocation()
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer 
               and p.Character 
               and p.Character:FindFirstChild("HumanoidRootPart") 
               and not table.find(getgenv().whitelist, p.Name) then  -- Đã check whitelist: bỏ qua
                local scr, on = cam:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                if on then
                    local d = (Vector2.new(scr.X, scr.Y) - ref).Magnitude
                    if d < bestDist then
                        bestDist, best = d, p
                    end
                end
            end
        end
        if best then
            getgenv().SelectedTarget = best.Name
            Library:Notify("Selected target: " .. best.DisplayName .. " (@" .. best.Name .. ")", 3)
            UpdateList()
        else
            Library:Notify("No nearby player found! (skipping whitelist)", 2)
        end
    end
})

getgenv().animEnabled = false
getgenv().animTrack = nil
getgenv().bangConnection = nil

-- Hàm dừng animation và teleport
local function stopAnimAndTp()
    if getgenv().animTrack then
        getgenv().animTrack:Stop()
        getgenv().animTrack = nil
    end
    if getgenv().bangConnection then
        getgenv().bangConnection:Disconnect()
        getgenv().bangConnection = nil
    end
    getgenv().animEnabled = false
end

-- Xử lý khi respawn (đặt ở cuối script, sau RunService.RenderStepped:Connect(...))
LocalPlayer.CharacterAdded:Connect(function()
    if getgenv().animEnabled then
        task.wait(0.5) 
        local target = Services.Players:FindFirstChild(getgenv().SelectedTarget)
        if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myHum and myHRP then
                -- Chọn lại animation theo rig type
                local anim = Instance.new("Animation")
                anim.AnimationId = myHum.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://148840371" or "rbxassetid://5918726674"

                -- Phát lại animation
                getgenv().animTrack = myHum:LoadAnimation(anim)
                getgenv().animTrack:Play()
                getgenv().animTrack:AdjustSpeed(1)

                -- Teleport liên tục
                getgenv().bangConnection = RunService.Heartbeat:Connect(function()
                    if getgenv().animEnabled and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                        myHRP.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                    else
                        stopAnimAndTp()
                    end
                end)
            end
        else
            stopAnimAndTp()
        end
    end
end)

PlayerInfo:AddToggle('BangPlayerToggle', {
    Text = 'Bang Player',
    Default = false,  -- Bắt đầu ở trạng thái OFF
    Tooltip = 'Toggle Bang Player on selected target',  -- Tùy chọn: thêm tooltip
    Callback = function(state)
        getgenv().animEnabled = state
        
        if not state then
            stopAnimAndTp()
        else
            local target = Services.Players:FindFirstChild(getgenv().SelectedTarget)
            if not target then
                getgenv().animEnabled = false
                Library:Notify("No target selected!", 5)  -- Thông báo nếu không có target
                return
            end

            local myChar = LocalPlayer.Character
            local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not (myHum and myHRP) then
                getgenv().animEnabled = false
                Library:Notify("Character not ready!", 5)
                return
            end

            -- Chọn animation theo rig type
            local anim = Instance.new("Animation")
            anim.AnimationId = myHum.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://148840371" or "rbxassetid://126786971779567"  -- Giữ nguyên từ code gốc, nhưng lưu ý ID này có thể sai, kiểm tra lại nếu cần

            -- Phát animation
            getgenv().animTrack = myHum:LoadAnimation(anim)
            getgenv().animTrack:Play()
            getgenv().animTrack:AdjustSpeed(1)

            -- Teleport liên tục
            getgenv().bangConnection = RunService.Heartbeat:Connect(function()
                if getgenv().animEnabled and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                    myHRP.CFrame = target.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, 1)
                else
                    stopAnimAndTp()
                end
            end)
        end
    end
})

getgenv().PlayerActions = Tabs.Players:AddRightGroupbox('Player Actions')

getgenv().PlayerActions:AddDropdown('actionType', {
    Values = { 'Knock', 'Bring', 'Stomp', 'Void' },
    Default = 'Knock',
    Multi = false,
    Text = 'action',
    Callback = function(value)
        getgenv().SelectedAction = value
    end,
})

getgenv().PlayerActions:AddButton({
    Text = 'Execute Action',
    Func = function()
        local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
        if targetPlayer and targetPlayer.Character then
            local tool = LocalPlayer.Character:FindFirstChildWhichIsA("Tool")
            if tool and tool:FindFirstChild("Ammo") then
                getgenv().isActionRunning = true
                getgenv().oldPosition = LocalPlayer.Character.HumanoidRootPart.Position
                if getgenv().SelectedAction == "Knock" then
                    knockTarget(targetPlayer)
                elseif getgenv().SelectedAction == "Bring" then
                    bringTarget(targetPlayer)
                elseif getgenv().SelectedAction == "Stomp" then
                    stompTarget(targetPlayer)
                elseif getgenv().SelectedAction == "Void" then
                    voidTarget(targetPlayer)
                end
            else
                Library:Notify("Equip a tool to use this function. | matcha.lol", 5)
            end
        end
    end,
    Tooltip = 'Execute selected action on target player',
    DoubleClick = false,
    Disabled = false,
    Visible = true
})

PlayerActions:AddToggle("AutoKill", {
    Text = "Auto Kill",
    Default = false,
    Callback = function(State)
        getgenv().autoKillEnabled = State
        while getgenv().autoKillEnabled and getgenv().SelectedTarget do
            local targetPlayer = Players:FindFirstChild(getgenv().SelectedTarget)
            if targetPlayer and targetPlayer.Character then
                stompTarget(targetPlayer)
            end
            task.wait()
        end
    end
})

getgenv().PlayerActions:AddButton({
    Text = 'Stop',
    Func = function()
        stopAllActions()
    end,
    Tooltip = 'Stop all ongoing actions',
    DoubleClick = false,
    Disabled = false,
    Visible = true
})

getgenv().AllPlayerActions = Tabs.Players:AddRightGroupbox('All Player Actions')

getgenv().ShopFolder = Workspace:WaitForChild("Ignored"):WaitForChild("Shop")
getgenv().OriginalPosition = nil
getgenv().KillAllEnabled = false
getgenv().StompAllEnabled = false
getgenv().CurrentTarget = nil

getgenv().BuyItem = function(itemName)
    -- Unequip all tools before buying
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool:IsA("Tool") then
            tool.Parent = LocalPlayer.Backpack
        end
    end

    for _, item in pairs(getgenv().ShopFolder:GetChildren()) do
        if item.Name == itemName then
            local itemHead = item:FindFirstChild("Head")
            if itemHead then
                LocalPlayer.Character.HumanoidRootPart.CFrame = itemHead.CFrame + Vector3.new(0, 3.2, 0)
                task.wait(0.3) 
                fireclickdetector(item:FindFirstChild("ClickDetector"))
            end
            break
        end
    end
end

getgenv().EquipLMG = function()
    -- Check for LMG in both Backpack and Character
    for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
        if tool.Name == "[LMG]" then
            tool.Parent = LocalPlayer.Character
            return tool
        end
    end
    for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
        if tool.Name == "[LMG]" then
            return tool
        end
    end
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character:FindFirstChild("Head")
    if not targetHead then return end
    MainRemote:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().IsKnockedOut = function(target)
    local bodyEffects = target.Character:FindFirstChild("BodyEffects")
    if not bodyEffects then return false end
    local koValue = bodyEffects:FindFirstChild("K.O")
    return koValue and koValue.Value
end

getgenv().HasForcefield = function(target)
    return target.Character and target.Character:FindFirstChild("ForceField")
end

getgenv().IsGrabbing = function(target)
    return target.Character and target.Character:FindFirstChild("GRABBING_CONSTRAINT")
end

getgenv().IsTooFar = function(target)
    local distance = (LocalPlayer.Character.HumanoidRootPart.Position - target.Character.HumanoidRootPart.Position).Magnitude
    return distance > 10000
end

getgenv().KillAllPlayers = function()
    task.spawn(function()
        -- Lưu vị trí ban đầu để quay lại khi tắt
        getgenv().OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame

        -- Unequip tất cả tool trước khi mua
        for _, tool in pairs(LocalPlayer.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool.Parent = LocalPlayer.Backpack
            end
        end

        -- Mua LMG nếu chưa có
        while not (LocalPlayer.Backpack:FindFirstChild("[LMG]") or LocalPlayer.Character:FindFirstChild("[LMG]")) and getgenv().KillAllEnabled do
            getgenv().BuyItem("[LMG] - $4098")
            task.wait(0.2)
            for i = 1, 5 do
                getgenv().BuyItem("200 [LMG Ammo] - $328")
                task.wait(1)
            end
        end

        local lmgTool = getgenv().EquipLMG()
        if not lmgTool then return end

        -- Vòng lặp chính
        while getgenv().KillAllEnabled do
            for _, player in pairs(Players:GetPlayers()) do
                if not getgenv().KillAllEnabled then break end
                if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    if getgenv().HasForcefield(player) or getgenv().IsGrabbing(player) or getgenv().IsTooFar(player) then
                        continue
                    end

                    getgenv().CurrentTarget = player
                    workspace.CurrentCamera.CameraSubject = player.Character.Humanoid

                    -- Bắn cho đến khi target bị KO
                    while not getgenv().IsKnockedOut(player) and getgenv().KillAllEnabled do
                        -- Dịch lên trên mục tiêu 20 stud để bắn
                        LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame + Vector3.new(0, 100, 0)
                        getgenv().ShootPlayer(player, lmgTool)
                        task.wait(0)
                    end

                    -- Nếu bị KO thì TP lên trên UpperTorso 3 stud rồi stomp
                    if getgenv().IsKnockedOut(player) and player.Character:FindFirstChild("UpperTorso") then
                        local torso = player.Character.UpperTorso
                        LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(torso.Position + Vector3.new(0, 3, 0))
                        MainRemote:FireServer("Stomp")
                        task.wait(0.1) -- nghỉ chút để stomp ổn định
                    end
                end
            end
            task.wait(0.1) -- tránh lag
        end

        -- Reset khi tắt KillAll
        if getgenv().OriginalPosition then
            LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
        end
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
        getgenv().CurrentTarget = nil

        -- Nếu StompAll cũng bật thì gọi lại
        if getgenv().StompAllEnabled then
            getgenv().StompAllPlayers()
        end
    end)
end

getgenv().StompAllPlayers = function()
    task.spawn(function()
        while getgenv().StompAllEnabled do
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= LocalPlayer and player.Character then
                    local character = player.Character
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    local bodyEffects = character:FindFirstChild("BodyEffects")
                    local upperTorso = character:FindFirstChild("UpperTorso")

                    if humanoid and bodyEffects and upperTorso then
                        local koValue = bodyEffects:FindFirstChild("K.O")
                        local sDeathValue = bodyEffects:FindFirstChild("SDeath")

                        if koValue and sDeathValue and koValue.Value and not sDeathValue.Value then
                            -- Lưu vị trí ban đầu
                            getgenv().OriginalPosition = LocalPlayer.Character.HumanoidRootPart.CFrame
                            
                            -- Dịch chuyển lên trên đầu 3 stud
                            LocalPlayer.Character.HumanoidRootPart.CFrame =
                                CFrame.new(upperTorso.Position + Vector3.new(0, 3, 0))

                            -- Gửi Stomp
                            MainRemote:FireServer("Stomp")

                            -- Đợi 0.1 giây
                            task.wait(0.1)

                            -- Kiểm tra lại K.O
                            if koValue and not koValue.Value then
                                -- Nếu không còn K.O, trở về vị trí cũ
                                if getgenv().OriginalPosition then
                                    LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
                                    getgenv().OriginalPosition = nil
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.2) -- Vòng lặp liên tục nhưng nhẹ
        end
    end)
end

getgenv().AllPlayerActions:AddToggle("KillAllToggle", {
    Text = "Kill All",
    Default = false,
    Callback = function(value)
        getgenv().KillAllEnabled = value
        if value then
            getgenv().KillAllPlayers()
        else
            if getgenv().OriginalPosition then
                LocalPlayer.Character.HumanoidRootPart.CFrame = getgenv().OriginalPosition
            end
            workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
        end
    end
})

getgenv().AllPlayerActions:AddToggle("StompAllToggle", {
    Text = "Stomp All",
    Default = false,
    Callback = function(value)
        getgenv().StompAllEnabled = value
        if value and not getgenv().KillAllEnabled then
            getgenv().StompAllPlayers()
        end
    end
})

getgenv().serenity = {}
getgenv().AutoShootEnabled = false

function isPlayerInSerenity(playerName)
    for _, name in pairs(getgenv().serenity) do
        if name == playerName then
            return true
        end
    end
    return false
end

function findPlayerByName(playerName)
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        if player.Name:lower() == playerName:lower() then
            return player
        end
    end
    return nil
end

function togglePlayerInSerenity(playerName)
    local player = findPlayerByName(playerName)
    
    if not player then
        Library:Notify("Player not found in the game!", 5)
        return
    end

    if isPlayerInSerenity(playerName) then
        for i, name in pairs(getgenv().serenity) do
            if name == playerName then
                table.remove(getgenv().serenity, i)
                break
            end
        end
        Library:Notify(playerName .. " has been removed from Serenity Mode", 5)
    else
        table.insert(getgenv().serenity, playerName)
        Library:Notify(playerName .. " has been added to Serenity Mode", 5)
    end
end

function autoEquipTool()
    local player = game.Players.LocalPlayer
    local backpack = player:FindFirstChild("Backpack")
    if not backpack then return nil end

    local bestTool = nil

    -- Prioritize tools named "Rifle" or "Aug"
    for _, tool in pairs(backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then
            local toolName = tool.Name:lower()
            if toolName == "rifle" or toolName == "aug" then
                bestTool = tool
                break
            elseif not bestTool then
                bestTool = tool -- Fallback if no prioritized tool is found
            end
        end
    end

    if bestTool then
        bestTool.Parent = player.Character -- Equip the tool
        Library:Notify("Equipped tool: " .. bestTool.Name, 3)
        repeat task.wait() until player.Character:FindFirstChildOfClass("Tool") == bestTool

        return bestTool
    end

    Library:Notify("No tool with Ammo found!", 3)
    return nil
end

getgenv().ShootPlayer = function(target, tool)
    if not tool or not tool:FindFirstChild("Handle") then return end
    local targetHead = target.Character and target.Character:FindFirstChild("Head")
    if not targetHead then return end
    
    -- Fire the shot
    MainRemote:FireServer("ShootGun", tool.Handle, tool.Handle.CFrame.Position, targetHead.Position, targetHead, Vector3.new(0, 0, -1))
end

getgenv().playerTextBox = AllPlayerActions:AddInput('PlayerTextBox', {
    Text = 'Serenity Mode',
    Tooltip = 'This will add a player to a table and if they go near you, it will automatically shoot them.',
    Default = '',
    Finished = true,
    Callback = function(Value)
        if Value and Value ~= "" then
            togglePlayerInSerenity(Value)
        end
    end
})

getgenv().autoShootToggle = AllPlayerActions:AddToggle('AutoShootToggle', {
    Text = 'Auto Shoot',
    Tooltip = 'Automatically shoots players in the Serenity table within 250 studs',
    Default = false,
    Callback = function(Value)
        getgenv().AutoShootEnabled = Value

        if Value then
            while getgenv().AutoShootEnabled do
                local character = game.Players.LocalPlayer.Character
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")

                if rootPart then
                    for _, targetPlayerName in pairs(getgenv().serenity) do
                        local targetPlayer = game:GetService("Players"):FindFirstChild(targetPlayerName)
                        if targetPlayer and targetPlayer.Character then
                            local targetHead = targetPlayer.Character:FindFirstChild("Head")
                            if targetHead then
                                local distance = (rootPart.Position - targetHead.Position).Magnitude
                                
                                if distance <= 250 then
                                    local tool = character:FindFirstChildOfClass("Tool")

                                    if not tool then
                                        tool = autoEquipTool()
                                    end

                                    if tool then
                                        getgenv().ShootPlayer(targetPlayer, tool)
                                    end
                                end
                            end
                        end
                    end
                end
                task.wait(0)
            end
        end
    end
})

MenuGroup:AddButton({
    Text = 'Unload',
    Func = function() Library:Unload() end,
    Tooltip = 'Unload the script', -- Tùy chọn
    DoubleClick = false, -- Tùy chọn
    Disabled = false, -- Tùy chọn
    Visible = true -- Tùy chọn
})
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', {
    Default = 'RightControl',
    NoUI = true,
    Text = 'Menu keybind',
    Tooltip = 'Keybind to toggle the menu',
    Mode = 'Toggle',
    Callback = function() end, -- Không cần callback vì đã có Library.ToggleKeybind
    ChangedCallback = function(New)
        print('Menu keybind changed to:', New)
    end
})
Library.ToggleKeybind = Options.MenuKeybind

MenuGroup:AddToggle('KeybindListToggle', {
    Text = 'Show Keybind List',
    Default = false,
    Tooltip = 'Show or hide the keybind list',
    Callback = function(state)
        Library.KeybindFrame.Visible = state
    end,
    Disabled = false,
    Visible = true
})

getgenv().vu = game:GetService("VirtualUser")
getgenv().isAntiAfkEnabled = false
getgenv().antiAfkConnection = nil

MenuGroup:AddToggle('AntiAFKToggle', {
    Text = 'Anti-AFK',
    Default = false,
    Tooltip = 'Prevent AFK timeout',
    Callback = function(state)
        getgenv().isAntiAfkEnabled = state
        if getgenv().isAntiAfkEnabled then
            getgenv().antiAfkConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
                getgenv().vu:CaptureController()
                getgenv().vu:ClickButton2(Vector2.new())
            end)
        else
            if getgenv().antiAfkConnection then
                getgenv().antiAfkConnection:Disconnect()
                getgenv().antiAfkConnection = nil
            end
        end
    end,
    Disabled = false,
    Visible = true
})

MenuGroup:AddButton({
    Text = 'Copy Job ID',
    Func = function()
        setclipboard(game.JobId)
    end,
    Tooltip = 'Copy the current server Job ID to clipboard',
    DoubleClick = false,
    Disabled = false,
    Visible = true
})
MenuGroup:AddButton({
    Text = 'Copy JS Join Script',
    Func = function()
        local jsScript = 'Roblox.GameLauncher.joinGameInstance(' .. game.PlaceId .. ', "' .. game.JobId .. '")'
        setclipboard(jsScript)
    end,
    Tooltip = 'Copy the join script for the current server',
    DoubleClick = false,
    Disabled = false,
    Visible = true
})
MenuGroup:AddInput('JobIdInput', {
    Default = '',
    Numeric = false,
    Finished = true,
    Text = '..JobId..',
    Tooltip = 'Enter a Job ID to join a specific server',
    Placeholder = 'Enter Job ID here',
    ClearTextOnFocus = true,
    Callback = function(Value)
        game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, Value, game:GetService('Players').LocalPlayer)
    end,
    Disabled = false,
    Visible = true
})
MenuGroup:AddButton({
    Text = 'Rejoin Server',
    Func = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, game.Players.LocalPlayer)
    end,
    Tooltip = 'Rejoin the current server',
    DoubleClick = false,
    Disabled = false,
    Visible = true
})

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })
ThemeManager:SetFolder('matcha.lol')
SaveManager:SetFolder('Nigga/configs')
SaveManager:BuildConfigSection(Tabs['UI Settings'])
ThemeManager:ApplyToTab(Tabs['UI Settings'])
SaveManager:LoadAutoloadConfig()
Library:SetWatermarkVisibility(true)
MenuGroup:AddToggle('WatermarkToggle', {
    Text = 'Show Watermark',
    Default = true,  -- Bắt đầu bật
    Tooltip = 'Toggle the watermark visibility',
    Callback = function(Value)
        Library:SetWatermarkVisibility(Value)
    end
})
local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = RunService.RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    local Ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue())

    Library:SetWatermark(("matcha.lol | FPS: %d | %d ms"):format(FPS, Ping))
end)
task.wait(1)
Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    print('Unloaded!')
    Library.Unloaded = true
end)

loadstring(game:HttpGet("https://raw.githubusercontent.com/Kazamatcha/matcha.tea/refs/heads/main/admin"))()
