if not game:IsLoaded() then 
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

task.spawn(function()
	local g = getinfo or debug.getinfo
	local d = false
	local h = {}

	local x, y

	setthreadidentity(2)

	for i, v in getgc(true) do
		if typeof(v) == "table" then
			local a = rawget(v, "Detected")
			local b = rawget(v, "Kill")
		
			if typeof(a) == "function" and not x then
				x = a
				local o; o = hookfunction(x, function(c, f, n)
					if c ~= "_" then
						if d then
						end
					end
					
					return true
				end)
				table.insert(h, x)
			end

			if rawget(v, "Variables") and rawget(v, "Process") and typeof(b) == "function" and not y then
				y = b
				local o; o = hookfunction(y, function(f)
					if d then
					end
				end)
				table.insert(h, y)
			end
		end
	end

	local o; o = hookfunction(getrenv().debug.info, newcclosure(function(...)
		local a, f = ...

		if x and a == x then
			if d then
				warn(`zins | adonis bypassed`)
			end

			return coroutine.yield(coroutine.running())
		end
		
		return o(...)
	end))

	setthreadidentity(7)
end)

getgenv().matcha = {
    AimEnabled = false,
    StickyAim = false,
    HitChance = 100,
    AimEnabled = false,
    CheckSelect = {},
    AimCheck = {},
    AimDistanceCheck = false,
    AimDistance = 250,
    HealthCheck = false,
    HealthThreshold = 50,
    Resolver = false,
    ResolverMethod = "move direction",
    AutoPrediction = false,
    AutoPredMode = "0-225",
    PredictionX = 0.13,
    PredictionY = 0.13,
    HitPart = "Head",
    ClosestPart = false,
    Offset = 0,
    JumpOffset = 0,
    AirPartEnabled = false,
    AirPart = "Head",
    SmoothingEnabled = false,
    Smooth = 0.5,
    SmoothMethod = "Linear",
    AimMethod = "camera",
    SortType = "near mouse",
    ToggleAimbot = false,
    SmoothMouse = 7,
    NotifySelect = false,
    Target = nil,
    SelectedTarget = nil,
    TriggerbotEnabled = false,
    TriggerFOV = 20,
    OnlyTarget = false,
    TriggerCheckWall = false,
    TriggerCheckKO = false,
    TriggerCheckKnife = false,
    TriggerCheckGrab = false,
    TriggerCheckTeam = false,
    TriggerCheckFriend = false,
    TriggerDelay = 1,
    Enabledboost = false,
    WalkSpeed = 16,
    JumpPower = 50,

    -- Hitbox Expander vars
    HitboxExpanderEnabled = false,
    HitboxSize = 10,
    VisualizeHitbox = false,
    HitboxColor = Color3.fromRGB(70, 220, 110),
    HitboxOutlineColor = Color3.fromRGB(255, 255, 255),
    HitboxCheckTeam = false,
    HitboxOnlyTarget = false,
    NoJumpCooldown = false,
    BunnyHopEnabled = false,
    BunnyHopSpeed = 50,
    SpinbotEnabled = false,
    SpinSpeed = 10,
    AntiFlingEnabled = false,
    InfJumpEnabled = false,
    AntiVoidEnabled = false,
    FlyV2Enabled = false,
    AntiSlowdown = false,
    FlyNoclip = true,

    -- FOV Selection vars
    UseFOV = false,
    FOVSize = 100,
    FOVOutline = false,
    FOVOutlineColor = Color3.fromRGB(0, 0, 0),
    FOVFilled = false,
    FOVFilledColor = Color3.fromRGB(255, 255, 255),
    FOVThickness = 1,
}
local silentTarget = nil
local silentAimPosition = nil
-- Logic implementation
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local lastNotifiedTarget = nil
local targeting = false

-- FOV Drawing
local fovFill = Drawing.new("Circle")
fovFill.Visible = false
fovFill.Filled = true
fovFill.Transparency = 0.5
fovFill.Color = getgenv().matcha.FOVFilledColor
fovFill.Thickness = 1
fovFill.NumSides = 100

local fovOutline = Drawing.new("Circle")
fovOutline.Visible = false
fovOutline.Filled = false
fovOutline.Transparency = 1
fovOutline.Color = getgenv().matcha.FOVOutlineColor
fovOutline.Thickness = getgenv().matcha.FOVThickness
fovOutline.NumSides = 100

local function isAlive(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then
        return false
    end

    local be = plr.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        local grabbed = be:FindFirstChild("GRABBING_CONSTRAINT")
        if (ko and ko.Value) or (grabbed and grabbed.Value) then
            return false
        end
    end

    return true
end
local function isKO(plr)
    return not isAlive(plr)
end
local function canSeeThroughWall(localPlayer, target)
    local ray = Ray.new(Camera.CFrame.Position, (target.Character.HumanoidRootPart.Position - Camera.CFrame.Position).unit * 10000)
    local hit, pos = workspace:FindPartOnRayWithIgnoreList(ray, {localPlayer.Character})
    return hit and hit:IsDescendantOf(target.Character)
end
local function canSeeTarget(target, partName)
    if not target or not target.Character or not target.Character:FindFirstChild(partName) then
        return false
    end
    local camera = Workspace.CurrentCamera
    local targetPart = target.Character[partName]
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * 10000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.IgnoreWater = true
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult == nil or (raycastResult.Instance and raycastResult.Instance:IsDescendantOf(target.Character))
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = getgenv().matcha.UseFOV and getgenv().matcha.FOVSize or math.huge
    local mousePos = game:GetService("UserInputService"):GetMouseLocation()
    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and isAlive(player) then
            local character = player.Character
            if character then
                local root = character:FindFirstChild("HumanoidRootPart")
                if root then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                    local distance
                    local validForDistance = true

                    if getgenv().matcha.SortType == "near mouse" or getgenv().matcha.SortType == "near center" then
                        if not onScreen then validForDistance = false end
                    end

                    if validForDistance then
                        if getgenv().matcha.SortType == "near mouse" then
                            distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        elseif getgenv().matcha.SortType == "near center" then
                            distance = (Vector2.new(screenPos.X, screenPos.Y) - centerPos).Magnitude
                        elseif getgenv().matcha.SortType == "near character" then
                            local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if localRoot then
                                distance = (root.Position - localRoot.Position).Magnitude
                            else
                                distance = math.huge
                            end
                        end

                        if distance < shortestDistance then
                            local valid = true
                            if table.find(getgenv().matcha.CheckSelect, "Check Wall") and not canSeeTarget(player, "HumanoidRootPart") then
                                valid = false
                            end
                            if table.find(getgenv().matcha.CheckSelect, "Check Alive") and not isAlive(player) then
                                valid = false
                            end
                            if table.find(getgenv().matcha.CheckSelect, "Check Team") and player.Team == LocalPlayer.Team then
                                valid = false
                            end
                            if table.find(getgenv().matcha.CheckSelect, "Check Friend") then
                                valid = false -- Placeholder for friend check
                            end
                            if valid then
                                shortestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end

    return closestPlayer
end

local function toggleTarget()
    targeting = not targeting
    if targeting then
        getgenv().matcha.Target = GetClosestPlayer()
        if getgenv().matcha.Target then
            getgenv().matcha.SelectedTarget = getgenv().matcha.Target
            if getgenv().matcha.NotifySelect and getgenv().matcha.Target ~= lastNotifiedTarget then
                Library:Notification("Selected Target: " .. getgenv().matcha.Target.DisplayName .. " (@" .. getgenv().matcha.Target.Name .. ")", "", 3)
                lastNotifiedTarget = getgenv().matcha.Target
            end
        else
            targeting = false
        end
    else
        getgenv().matcha.Target = nil
        getgenv().matcha.SelectedTarget = nil
		if getgenv().matcha.NotifySelect then
            Library:Notify({ Title = "Target Cleared", Description = "Untargeted player.", Time = 3 })
        end
        lastNotifiedTarget = nil
    end
end

local function CalculateAutoPrediction(target)
    if not target or not target.Character or not target.Character:FindFirstChild("HumanoidRootPart") then
        return 0.1
    end

    local ping = math.clamp(Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000, 0.01, 1)
    local root = target.Character.HumanoidRootPart
    local distance = (root.Position - Camera.CFrame.Position).Magnitude

    local predicted_time = (distance / 100) * 0.05 + ping * 0.5
    predicted_time = math.clamp(predicted_time, 0.05, 0.4)

    return predicted_time
end

local function getPing()
    return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
end

local function calculateAdvancePrediction(target, cameraPosition, pingBase)
    local character = target.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            local dist = (cameraPosition - hrp.Position).Magnitude
            return pingBase + (dist / 1000) * (vel.Magnitude / 50)
        end
    end
    return pingBase
end

local Blatant = {
    {50, 0.12758545757236864},
    {60, 0.12593338424986178},
    {70, 0.1416310605747206},
    {80, 0.1441481061236737},
    {90, 0.14306050263254388},
    {100, 0.14698413210558095},
    {110, 0.14528324362031425},
    {120, 0.14556534594403},
    {130, 0.14614337395777216},
    {140, 0.14645603036905414},
    {150, 0.14736848095666674},
    {160, 0.14696985547996216},
    {170, 0.14718530231216217},
    {180, 0.1471532933015037},
    {190, 0.1471212842908452},
    {200, 0.14708927528018672},
    {210, 0.14705726626952823},
    {220, 0.14702525725886974},
    {230, 0.14699324824821125},
    {240, 0.14696123923755276},
    {250, 0.14692923022689427},
    {260, 0.14689722121623578},
    {270, 0.1468652122055773},
    {280, 0.1468332031949188},
    {290, 0.1468011941842603},
    {300, 0.1467691851736018},
}

local predictionTable = {
    {0, 0.1332},
    {10, 0.1234555},
    {20, 0.12435},
    {30, 0.124123},
    {40, 0.12766},
    {50, 0.128643},
    {60, 0.1264236},
    {70, 0.12533},
    {80, 0.1321042},
    {90, 0.1421951},
    {100, 0.134143},
    {105, 0.141199},
    {110, 0.142199},
    {125, 0.15465},
    {130, 0.12399},
    {135, 0.1659921},
    {140, 0.1659921},
    {145, 0.129934},
    {150, 0.1652131},
    {155, 0.125333},
    {160, 0.1223333},
    {165, 0.1652131},
    {170, 0.16863},
    {175, 0.16312},
    {180, 0.1632},
    {185, 0.16823},
    {190, 0.18659},
    {205, 0.17782},
    {215, 0.16937},
    {225, 0.176332},
}

local function updatePredictionValue()
    if not getgenv().matcha.AutoPrediction then return end

    local ping = getPing()
    local pred = 0.13

    if getgenv().matcha.AutoPredMode == "0-225" then
        for _, entry in ipairs(predictionTable) do
            if ping < entry[1] then
                pred = entry[2]
                break
            end
        end
    elseif getgenv().matcha.AutoPredMode == "Calculation" then
        pred = 0.1 + (ping / 1000) * 0.32
    elseif getgenv().matcha.AutoPredMode == "AdvanceCalculation" then
        for _, entry in ipairs(predictionTable) do
            if ping < entry[1] then
                local base = entry[2]
                pred = calculateAdvancePrediction(getgenv().matcha.SelectedTarget, Camera.CFrame.Position, base)
                break
            end
        end
    elseif getgenv().matcha.AutoPredMode == "Blatant" then
        for _, entry in ipairs(Blatant) do
            if ping < entry[1] then
                pred = entry[2]
                break
            end
        end
    elseif getgenv().matcha.AutoPredMode == "50-290" then
        if ping >= 50 and ping <= 290 then
            local map = {
                [50]=0.1433,[55]=0.1412,[60]=0.1389,[65]=0.1367,[70]=0.1346,[75]=0.1324,[80]=0.1303,
                [85]=0.1282,[90]=0.1261,[95]=0.1240,[100]=0.1219,[105]=0.1198,[110]=0.1177,[115]=0.1157,
                [120]=0.1136,[125]=0.1116,[130]=0.1095,[135]=0.1075,[140]=0.1055,[145]=0.1035,[150]=0.1015,
                [155]=0.0995,[160]=0.0975,[165]=0.0956,[170]=0.0936,[175]=0.0917,[180]=0.0897,[185]=0.0878,
                [190]=0.0859,[195]=0.0840,[200]=0.0821,[205]=0.0802,[210]=0.0783,[215]=0.0765,[220]=0.0746,
                [225]=0.0728,[230]=0.0710,[235]=0.0692,[240]=0.0674,[245]=0.0656,[250]=0.0638,[255]=0.0620,
                [260]=0.0603,[265]=0.0585,[270]=0.0568,[275]=0.0551,[280]=0.0534,[285]=0.0517,[290]=0.0500
            }
            for k,v in pairs(map) do if ping <= k then pred = v break end end
        end
    elseif getgenv().matcha.AutoPredMode == "10-190" then
        if ping > 190 then pred = 0.206547
        elseif ping > 180 then pred = 0.19284
        elseif ping > 170 then pred = 0.1923111
        elseif ping > 160 then pred = 0.1823111
        elseif ping > 150 then pred = 0.171
        elseif ping > 140 then pred = 0.165773
        elseif ping > 130 then pred = 0.1223333
        elseif ping > 120 then pred = 0.143765
        elseif ping > 110 then pred = 0.1455
        elseif ping > 100 then pred = 0.130340
        elseif ping > 90 then pred = 0.136
        elseif ping > 80 then pred = 0.1347
        elseif ping > 70 then pred = 0.119
        elseif ping > 60 then pred = 0.12731
        elseif ping > 50 then pred = 0.127668
        elseif ping > 40 then pred = 0.125
        elseif ping > 30 then pred = 0.11
        elseif ping > 20 then pred = 0.12588
        elseif ping > 10 then pred = 0.9
        end
    elseif getgenv().matcha.AutoPredMode == "10-1000" then
        local map = {
            [1000]=0.345,[900]=0.290724,[800]=0.254408,[700]=0.23398,[600]=0.215823,[500]=0.19284,
            [400]=0.18321,[360]=0.16537,[280]=0.16780,[270]=0.195566,[260]=0.175566,[250]=0.1651,
            [240]=0.16780,[230]=0.15692,[220]=0.165566,[210]=0.165566,[200]=0.16942,[190]=0.166547,
            [180]=0.19284,[170]=0.1923111,[160]=0.16,[150]=0.15,[140]=0.1223333,[130]=0.156692,
            [120]=0.14376,[110]=0.1455,[100]=0.130340,[90]=0.136,[80]=0.1347,[70]=0.119,[60]=0.12731,
            [50]=0.127668,[40]=0.125,[30]=0.11,[20]=0.12588,[10]=0.9
        }
        for k,v in pairs(map) do if ping <= k then pred = v break end end
    elseif getgenv().matcha.AutoPredMode == "5-500" then
        local map = {
            [5]=0.1030773,[10]=0.1061546,[15]=0.1092319,[20]=0.1123092,[25]=0.1153865,[30]=0.1184638,
            [35]=0.1215411,[40]=0.1246184,[45]=0.1276957,[50]=0.130773,[55]=0.1338503,[60]=0.1369276,
            [65]=0.1400049,[70]=0.1430822,[75]=0.1461595,[80]=0.1492368,[85]=0.1523141,[90]=0.1553914,
            [95]=0.1584687,[100]=0.161546,[105]=0.1646233,[110]=0.1677006,[115]=0.1707779,[120]=0.1738552,
            [125]=0.1769325,[130]=0.1800098,[135]=0.1830871,[140]=0.1861644,[145]=0.1892417,[150]=0.192319,
            [155]=0.1953963,[160]=0.1984736,[165]=0.2015509,[170]=0.2046282,[175]=0.2077055,[180]=0.2107828,
            [185]=0.2138601,[190]=0.2169374,[195]=0.2200147,[200]=0.223092,[205]=0.2261693,[210]=0.2292466,
            [215]=0.2323239,[220]=0.2354012,[225]=0.2384785,[230]=0.2415558,[235]=0.2446331,[240]=0.2477104,
            [245]=0.2507877,[250]=0.253865,[255]=0.2569423,[260]=0.2600196,[265]=0.2630969,[270]=0.2661742,
            [275]=0.2692515,[280]=0.2723288,[285]=0.2754061,[290]=0.2784834,[295]=0.2815607,[300]=0.284638,
            [305]=0.2877153,[310]=0.2907926,[315]=0.2938699,[320]=0.2969472,[325]=0.3000245,[330]=0.3031018,
            [335]=0.3061791,[340]=0.3092564,[345]=0.3123337,[350]=0.315411,[355]=0.3184883,[360]=0.3215656,
            [365]=0.3246429,[370]=0.3277202,[375]=0.3307975,[380]=0.3338748,[385]=0.3369521,[390]=0.3400294,
            [395]=0.3431067,[400]=0.346184,[405]=0.3492613,[410]=0.3523386,[415]=0.3554159,[420]=0.3584932,
            [425]=0.3615705,[430]=0.3646478,[435]=0.3677251,[440]=0.3708024,[445]=0.3738797,[450]=0.376957,
            [455]=0.3800343,[460]=0.3831116,[465]=0.3861889,[470]=0.3892662,[475]=0.3923435,[480]=0.3954208,
            [485]=0.3984981,[490]=0.4015754,[495]=0.4046527,[500]=0.40773
        }
        for k,v in pairs(map) do if ping <= k then pred = v break end end
    elseif getgenv().matcha.AutoPredMode == "drax" then
        pred = (ping / 1000) + 0.125
    elseif getgenv().matcha.AutoPredMode == "110-140" then
        if ping >= 110 and ping <= 140 then
            local vals = {0.1345, 0.1409, 0.141199, 0.143765}
            pred = vals[math.random(1,#vals)]
        end
    elseif getgenv().matcha.AutoPredMode == "matcha" then
        pred = CalculateAutoPrediction(getgenv().matcha.SelectedTarget)
    end

    getgenv().matcha.PredictionX = pred
    getgenv().matcha.PredictionY = pred
end

local HitParts = {
    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
}
local function isHoldingKnife()
    local char = LocalPlayer.Character
    if char then
        local tool = char:FindFirstChildWhichIsA("Tool")
        if tool and tool.Name:lower():find("knife") then
            return true
        end
    end
    return false
end

local function isValidTriggerTarget(plr)
    if plr == LocalPlayer then return false end
    if getgenv().matcha.OnlyTarget and plr ~= getgenv().matcha.SelectedTarget then return false end
    if getgenv().matcha.TriggerCheckTeam and plr.Team == LocalPlayer.Team then return false end
    if getgenv().matcha.TriggerCheckFriend and LocalPlayer:IsFriendsWith(plr.UserId) then return false end
    if getgenv().matcha.TriggerCheckKO and isKO(plr) then return false end
    if getgenv().matcha.TriggerCheckGrab and plr.Character:FindFirstChild("BodyEffects") and plr.Character.BodyEffects:FindFirstChild("GRABBING_CONSTRAINT") and plr.Character.BodyEffects.GRABBING_CONSTRAINT.Value then return false end
    if getgenv().matcha.TriggerCheckWall and not canSeeThroughWall(LocalPlayer, plr) then return false end
    if getgenv().matcha.TriggerCheckKnife and isHoldingKnife() then return false end
    return isAlive(plr)
end

local function distToCursor(part)
    local v, vis = Camera:WorldToViewportPoint(part.Position)
    if not vis then return math.huge end
    local m = UserInputService.TouchEnabled and Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2) or UserInputService:GetMouseLocation()
    return (Vector2.new(v.X, v.Y) - m).Magnitude
end

local function click()
    if UserInputService.TouchEnabled then
        local touchPos = UserInputService:GetMouseLocation()
        VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.Begin, touchPos)
        task.wait()
        VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.End, touchPos)
    else
        if mouse1press then
            mouse1press()
            mouse1release()
        elseif mouse1click then
            mouse1click()
        end
    end
end

local function toolActivate(tool)
    pcall(function() tool:Activate() end)
end

local function GetBestTargetPart()
    local bestPart, bestDist = nil, getgenv().matcha.TriggerFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if isValidTriggerTarget(plr) and plr.Character then
            for _, partName in ipairs(HitParts) do
                local part = plr.Character:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    local dist = distToCursor(part)
                    if dist < bestDist then
                        bestPart = part
                        bestDist = dist
                    end
                end
            end
        end
    end
    return bestPart
end

-- Hitbox Expander Logic
local highlights = {}

local function removeVisuals(Player)
    if highlights[Player] then
        highlights[Player]:Destroy()
        highlights[Player] = nil
    end
end

local function resetCharacter(Character, Player)
    if not Character then return end
    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if HRP then
        HRP.Size = Vector3.new(2, 1, 2)
        HRP.Transparency = 1
        HRP.CanCollide = true
    end
    removeVisuals(Player)
end

local function handleCharacter(Character, Player)
    if not Character or not getgenv().matcha.HitboxExpanderEnabled then
        resetCharacter(Character, Player)
        return
    end

    if not Player or Player == LocalPlayer then return end

    if getgenv().matcha.HitboxOnlyTarget and Player ~= getgenv().matcha.SelectedTarget then 
        resetCharacter(Character, Player)
        return 
    end
    if getgenv().matcha.HitboxCheckTeam and Player.Team == LocalPlayer.Team then 
        resetCharacter(Character, Player)
        return 
    end

    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    HRP.Size = Vector3.new(getgenv().matcha.HitboxSize, getgenv().matcha.HitboxSize, getgenv().matcha.HitboxSize)
    HRP.Transparency = 0.9
    HRP.CanCollide = false

    if getgenv().matcha.VisualizeHitbox then
        if not highlights[Player] then
            local hl = Instance.new("Highlight")
            hl.Name = "HitboxHighlight"
            hl.Adornee = Character
            hl.FillColor = getgenv().matcha.HitboxColor
            hl.OutlineColor = getgenv().matcha.HitboxOutlineColor
            hl.FillTransparency = 0.8
            hl.OutlineTransparency = 0
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            hl.Parent = HRP
            highlights[Player] = hl
        else
            local hl = highlights[Player]
            hl.FillColor = getgenv().matcha.HitboxColor
            hl.OutlineColor = getgenv().matcha.HitboxOutlineColor
            hl.FillTransparency = 0.8
            hl.OutlineTransparency = 0
        end
    else
        removeVisuals(Player)
    end
end

local function handlePlayer(Player)
    if Player == LocalPlayer then return end

    local function applyHitbox(Character)
        if getgenv().matcha and getgenv().matcha.HitboxExpanderEnabled then
            handleCharacter(Character, Player)
        end
    end

    Player.CharacterAdded:Connect(function(Character)
        Character:WaitForChild("HumanoidRootPart")
        applyHitbox(Character)
    end)

    if Player.Character then
        applyHitbox(Player.Character)
    end
end

for _, Player in pairs(Players:GetPlayers()) do
    handlePlayer(Player)
end

-- Connect new players
Players.PlayerAdded:Connect(handlePlayer)

RunService.RenderStepped:Connect(function()
    -- === CẬP NHẬT PREDICTION (AUTO) ===
    updatePredictionValue()

    -- === CẬP NHẬT FOV ===
    local mousePos = UserInputService:GetMouseLocation()
    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovPosition

    if getgenv().matcha.SortType == "near mouse" then
        fovPosition = mousePos
    elseif getgenv().matcha.SortType == "near center" then
        fovPosition = centerPos
    elseif getgenv().matcha.SortType == "near character" then
        if UserInputService.TouchEnabled then
            fovPosition = centerPos
        else
            fovPosition = mousePos
        end
    else
        fovPosition = mousePos  -- Default fallback
    end

    fovFill.Position = fovPosition
    fovFill.Radius = getgenv().matcha.FOVSize
    fovFill.Visible = getgenv().matcha.FOVFilled
    fovFill.Color = getgenv().matcha.FOVFilledColor
    fovFill.Transparency = 0.5

    fovOutline.Position = fovPosition
    fovOutline.Radius = getgenv().matcha.FOVSize
    fovOutline.Visible = getgenv().matcha.FOVOutline
    fovOutline.Color = getgenv().matcha.FOVOutlineColor
    fovOutline.Thickness = getgenv().matcha.FOVThickness

    -- === CẬP NHẬT TARGET (NON-STICKY) ===
    if not getgenv().matcha.StickyAim then
        getgenv().matcha.Target = GetClosestPlayer()
        if getgenv().matcha.Target and getgenv().matcha.Target ~= lastNotifiedTarget and getgenv().matcha.NotifySelect then
		Library:Notify({ Title = "Selected Target", Description = getgenv().matcha.Target.DisplayName .. " (@" .. getgenv().matcha.Target.Name .. ")", Time = 3 })
            lastNotifiedTarget = getgenv().matcha.Target
        end
        getgenv().matcha.SelectedTarget = getgenv().matcha.Target
    end

    local target = getgenv().matcha.SelectedTarget
    if not target or not target.Character then
        silentTarget = nil
        silentAimPosition = nil
        return
    end

    -- === VALIDATION CHUNG (Aimbot + Silent Aim) ===
    local hitPartName = getgenv().matcha.HitPart
    if hitPartName == "Torso (R6)" then hitPartName = "Torso" end

    local valid = true
    if table.find(getgenv().matcha.AimCheck, "Check Wall") and not canSeeTarget(target, hitPartName) then valid = false end
    if table.find(getgenv().matcha.AimCheck, "Check Alive") and not isAlive(target) then valid = false end
    if getgenv().matcha.AimDistanceCheck then
        local dist = (target.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
        if dist > getgenv().matcha.AimDistance then valid = false end
    end
    if getgenv().matcha.HealthCheck then
        local hum = target.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= getgenv().matcha.HealthThreshold then valid = false end
    end

    -- FOV Check
    local rootPart = target.Character:FindFirstChild("HumanoidRootPart")
    if rootPart and getgenv().matcha.UseFOV then
        local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        if onScreen then
            local distToFOVCenter = (Vector2.new(screenPos.X, screenPos.Y) - fovPosition).Magnitude
            if distToFOVCenter > getgenv().matcha.FOVSize then valid = false end
        else
            valid = false
        end
    end
    if not valid then
        silentTarget = nil
        silentAimPosition = nil
        return
    end

    -- === LẤY TARGET PART (Closest Part + Air Part) ===
    local targetPart = target.Character:FindFirstChild(hitPartName) or target.Character.HumanoidRootPart

    if getgenv().matcha.ClosestPart then
        local closestDist = math.huge
        for _, part in ipairs(target.Character:GetChildren()) do
            if part:IsA("BasePart") then
                local dist = (part.Position - Camera.CFrame.Position).Magnitude
                if dist < closestDist then
                    targetPart = part
                    closestDist = dist
                end
            end
        end
    end

    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    local inFreefall = targetHum and targetHum:GetState() == Enum.HumanoidStateType.Freefall

    if getgenv().matcha.AirPartEnabled and inFreefall then
        local airPartName = getgenv().matcha.AirPart
        if airPartName == "Torso (R6)" then airPartName = "Torso" end
        targetPart = target.Character:FindFirstChild(airPartName) or targetPart
    end

    -- === VELOCITY + RESOLVER (TÍCH HỢP TRỰC TIẾP) ===
    local velocity = targetPart.AssemblyLinearVelocity

    if getgenv().matcha.Resolver then
        local humanoid = targetPart.Parent:FindFirstChild("Humanoid")
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")

        if getgenv().matcha.ResolverMethod == "move direction" and humanoid then
            velocity = humanoid.MoveDirection * humanoid.WalkSpeed
        elseif getgenv().matcha.ResolverMethod == "lookvector" then
            velocity = targetPart.CFrame.LookVector * getgenv().matcha.PredictionX * 100
        elseif getgenv().matcha.ResolverMethod == "combined" and hrp then
            local groundVel = Vector3.new(targetPart.Velocity.X, 0, targetPart.Velocity.Z)
            targetPart.Velocity = groundVel
            targetPart.AssemblyLinearVelocity = groundVel
            if hrp.Velocity.Magnitude > 30 then
                targetPart.Velocity = Vector3.zero
                targetPart.AssemblyLinearVelocity = Vector3.zero
            end
            velocity = targetPart.Velocity
        end
    end

    -- === TÍNH TOÁN VỊ TRÍ AIM CUỐI (DÙNG CHUNG CHO AIMBOT + SILENT) ===
    local predictionOffset = velocity * getgenv().matcha.PredictionX
    local basePosition = targetPart.Position + Vector3.new(0,
        inFreefall and getgenv().matcha.JumpOffset or getgenv().matcha.Offset,
        0
    )
    local aimPosition = basePosition + predictionOffset
    silentTarget = target
    silentAimPosition = aimPosition
    -- === AIMBOT (CAMERA / MOUSE) ===
    if targeting and getgenv().matcha.ToggleAimbot then
        if getgenv().matcha.AimMethod == "camera" then
            local goalCFrame = CFrame.new(Camera.CFrame.Position, aimPosition)

            if getgenv().matcha.SmoothingEnabled then
                Camera.CFrame = Camera.CFrame:Lerp(
                    goalCFrame,
                    getgenv().matcha.Smooth,
                    Enum.EasingStyle[getgenv().matcha.SmoothMethod],
                    Enum.EasingDirection.InOut
                )
            else
                Camera.CFrame = goalCFrame
            end

        elseif getgenv().matcha.AimMethod == "mouse" then
            local screenPos, onScreen = Camera:WorldToViewportPoint(aimPosition)
            if onScreen then
                local smoothVal = getgenv().matcha.SmoothingEnabled and getgenv().matcha.SmoothMouse or 7
                local deltaX = (screenPos.X - mousePos.X) / smoothVal
                local deltaY = (screenPos.Y - mousePos.Y) / smoothVal
                mousemoverel(deltaX, deltaY)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if not getgenv().matcha.HitboxExpanderEnabled then
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Character then
                resetCharacter(Player.Character, Player)
            end
        end
    else
        for _, Player in pairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer and Player.Character then
                handleCharacter(Player.Character, Player)
            end
        end
    end
    if getgenv().matcha.TriggerbotEnabled then
        local part = GetBestTargetPart()
        if part then
            task.spawn(function()
                local cap = part
                task.wait(getgenv().matcha.TriggerDelay / 1000)
                if getgenv().matcha.TriggerbotEnabled and distToCursor(cap) <= getgenv().matcha.TriggerFOV then
                    local origin = Camera.CFrame.Position
                    local direction = (cap.Position - origin)
                    local rayParams = RaycastParams.new()
                    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}

                    local result = workspace:Raycast(origin, direction, rayParams)

                    if not result or result.Instance:IsDescendantOf(cap.Parent) then
                        local char = LocalPlayer.Character
                        local tool = char and char:FindFirstChildWhichIsA("Tool")
                        local ammo = tool and tool:FindFirstChild("Ammo")
                        if tool and ammo then
                            toolActivate(tool)
                        else
                            click()
                        end
                    end
                end
            end)
        end
    end
end)
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false 
Library.ShowToggleFrameInKeybinds = true
local Window = Library:CreateWindow({

	Title = "Matcha.tea",
	Footer = "Matcha.tea Premium",
	Icon = 122719141368198,
	NotifySide = "Left",
	ShowCustomCursor = true,
})

--more icons in https://lucide.dev/icons
local Tabs = {
	Main = Window:AddTab("Main", "crosshair"),
	Client = Window:AddTab("Client", "user"),
    Visual = Window:AddTab("Visual", "eye"),
	["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}
local Aim = Tabs.Main:AddLeftGroupbox("Aim", "sword")
local AimSettings = Tabs.Main:AddRightGroupbox("AimSettings", "cog")
local Triggerbot = Tabs.Main:AddLeftGroupbox("Triggerbot", "bot")
local HitboxExpander = Tabs.Main:AddLeftGroupbox("HitboxExpander", "box")
local FovCircle = Tabs.Main:AddRightGroupbox("FovCircle", "circledotdashed")
local MovementSelection = Tabs.Client:AddLeftGroupbox("Movement", "footprints")
local MiscClient = Tabs.Client:AddRightGroupbox("Misc", "circleellipsis")
local AntiAimBox = Tabs.Client:AddRightGroupbox("Anti Aim", "shield")
local Lighting = Tabs.Visual:AddLeftGroupbox("Lighting", "sun")
local Misc = Tabs.Visual:AddRightGroupbox("Misc", "circleellipsis")
local WorldFX = Tabs.Visual:AddRightGroupbox("World FX", "sparkles")
local aimbotToggle = Aim:AddToggle("AimEnabled", {
    Text = "Aim Enabled",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.AimEnabled = Value
    end
})

-- Keybind: Target Selection
aimbotToggle:AddKeyPicker("TargetKey", {
    Default = "Q",
    Mode = "Toggle",
    Text = "Target Key",
    Callback = function()
        toggleTarget()
    end
})

-- Dropdown: Aimbot Method
Aim:AddDropdown("AimMethod", {
    Text = "Aimbot Method",
    Values = {"camera", "mouse"},
    Default = "camera",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.AimMethod = Value
    end
})

-- Dropdown: Sort Type
Aim:AddDropdown("SortType", {
    Text = "Sort Type",
    Values = {"near mouse", "near center", "near character"},
    Default = "near mouse",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.SortType = Value
    end
})

-- Dropdown: Check Select (multi)
Aim:AddDropdown("CheckSelect", {
    Text = "Check Select",
    Values = {"Check Wall", "Check Alive", "Check Team", "Check Friend"},
    Default = {},
    Multi = true,
    Callback = function(Value)
        getgenv().matcha.CheckSelect = Value
    end
})

-- Dropdown: Aim Check (multi)
Aim:AddDropdown("AimCheck", {
    Text = "Aim Check",
    Values = {"Check Wall", "Check Alive"},
    Default = {},
    Multi = true,
    Callback = function(Value)
        getgenv().matcha.AimCheck = Value
    end
})

-- Toggle + Slider: Aim Distance Check
Aim:AddToggle("AimDistanceCheck", {
    Text = "Aim Distance Check",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.AimDistanceCheck = Value
    end
})

Aim:AddSlider("AimDistance", {
    Text = "Aim Distance",
    Min = 1,
    Max = 1000,
    Default = 250,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.AimDistance = Value
    end
})

-- Toggle + Slider: Health Check
Aim:AddToggle("HealthCheck", {
    Text = "Health Check",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.HealthCheck = Value
    end
})

Aim:AddSlider("HealthThreshold", {
    Text = "Health Threshold",
    Min = 1,
    Max = 100,
    Default = 50,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.HealthThreshold = Value
    end
})

-- Toggle: Sticky Aim
Aim:AddToggle("StickyAim", {
    Text = "Sticky Aim",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.StickyAim = Value
    end
})

-- Toggle: Toggle Aimbot
Aim:AddToggle("ToggleAimbot", {
    Text = "Toggle Aimbot",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.ToggleAimbot = Value
    end
})

-- Toggle: Silent Aim
Aim:AddToggle("SilentAimEnabled", {
    Text = "Silent Aim",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.SilentAimEnabled = Value
    end
})

-- Slider: HitChance
Aim:AddSlider("HitChance", {
    Text = "HitChance (%)",
    Min = 1,
    Max = 100,
    Default = 100,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.HitChance = Value
    end
})

-- Toggle: Notify Select Target
Aim:AddToggle("NotifySelect", {
    Text = "Notify Select Target",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.NotifySelect = Value
    end
})

-- Toggle: Resolver
AimSettings:AddToggle("Resolver", {
    Text = "Resolver",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.Resolver = Value
    end
})

-- Dropdown: Resolver Method
AimSettings:AddDropdown("ResolverMethod", {
    Text = "Resolver Method",
    Values = {"move direction", "lookvector", "combined"},
    Default = "move direction",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.ResolverMethod = Value
    end
})

-- Toggle: Auto Prediction
AimSettings:AddToggle("AutoPrediction", {
    Text = "Auto Prediction",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.AutoPrediction = Value
    end
})

-- Dropdown: Auto Pred Mode
AimSettings:AddDropdown("AutoPredMode", {
    Text = "Auto Pred Mode",
    Values = {"0-225", "Calculation", "AdvanceCalculation", "Blatant", "50-290", "10-190", "10-1000", "5-500", "drax", "110-140", "matcha"},
    Default = "0-225",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.AutoPredMode = Value
    end
})

-- Textbox: Prediction X
AimSettings:AddInput("PredictionX", {
    Text = "Prediction X",
    Default = "0.13",
    Placeholder = "0.000 - 1.000",
    Numeric = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 and num <= 1 then
            getgenv().matcha.PredictionX = num
        else
            getgenv().matcha.PredictionX = 0.13 -- reset nếu sai
        end
    end
})

-- Textbox: Prediction Y
AimSettings:AddInput("PredictionY", {
    Text = "Prediction Y",
    Default = "0.13",
    Placeholder = "0.000 - 1.000",
    Numeric = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 and num <= 1 then
            getgenv().matcha.PredictionY = num
        else
            getgenv().matcha.PredictionY = 0.13
        end
    end
})

-- Dropdown: Hit Part
AimSettings:AddDropdown("HitPart", {
    Text = "Hit Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso (R6)"},
    Default = "Head",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.HitPart = Value
    end
})

-- Toggle: Closest Part
AimSettings:AddToggle("ClosestPart", {
    Text = "Closest Part",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.ClosestPart = Value
    end
})

-- Textbox: Offset
AimSettings:AddInput("Offset", {
    Text = "Offset",
    Default = "0",
    Placeholder = "Enter offset",
    Numeric = true,
    Callback = function(Value)
        getgenv().matcha.Offset = tonumber(Value) or 0
    end
})

-- Textbox: Jump Offset
AimSettings:AddInput("JumpOffset", {
    Text = "Jump Offset",
    Default = "0",
    Placeholder = "Enter jump offset",
    Numeric = true,
    Callback = function(Value)
        getgenv().matcha.JumpOffset = tonumber(Value) or 0
    end
})

-- Toggle: Air Part Enabled
AimSettings:AddToggle("AirPartEnabled", {
    Text = "Air Part Enabled",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.AirPartEnabled = Value
    end
})

-- Dropdown: Air Part
AimSettings:AddDropdown("AirPart", {
    Text = "Air Part",
    Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso (R6)"},
    Default = "Head",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.AirPart = Value
    end
})

-- Toggle: Smoothing
AimSettings:AddToggle("SmoothingEnabled", {
    Text = "Smoothing",
    Default = true,
    Callback = function(Value)
        getgenv().matcha.SmoothingEnabled = Value
    end
})

-- Slider: Smooth
AimSettings:AddSlider("Smooth", {
    Text = "Smooth",
    Min = 0,
    Max = 1,
    Default = 0.9953595,
    Rounding = 3,
    Callback = function(Value)
        getgenv().matcha.Smooth = Value
    end
})

-- Slider: Smooth Mouse
AimSettings:AddSlider("SmoothMouse", {
    Text = "Smooth Mouse",
    Min = 1,
    Max = 20,
    Default = 7,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.SmoothMouse = Value
    end
})

-- Dropdown: Smooth Method
AimSettings:AddDropdown("SmoothMethod", {
    Text = "Smooth Method",
    Values = {"Linear", "Exponential", "Sine", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Back", "Cubic"},
    Default = "Linear",
    Multi = false,
    Callback = function(Value)
        getgenv().matcha.SmoothMethod = Value
    end
})

Triggerbot:AddToggle("TriggerbotEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.TriggerbotEnabled = Value
    end
})

-- Dropdown: Checks (multi)
Triggerbot:AddDropdown("TriggerChecks", {
    Text = "Checks",
    Values = {"Wall", "Knife", "Alive", "Friend", "Team"},
    Default = {},
    Multi = true,
    Callback = function(selected)
        getgenv().matcha.TriggerCheckWall   = table.find(selected, "Wall") and true or false
        getgenv().matcha.TriggerCheckKnife  = table.find(selected, "Knife") and true or false
        getgenv().matcha.TriggerCheckKO     = table.find(selected, "Alive") and true or false
        getgenv().matcha.TriggerCheckFriend = table.find(selected, "Friend") and true or false
        getgenv().matcha.TriggerCheckTeam   = table.find(selected, "Team") and true or false
        getgenv().matcha.TriggerCheckGrab   = false -- not included in dropdown
    end
})

-- Toggle: Only Target
Triggerbot:AddToggle("OnlyTarget", {
    Text = "Only Target",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.OnlyTarget = Value
    end
})

-- Slider: Trigger FOV
Triggerbot:AddSlider("TriggerFOV", {
    Text = "Trigger FOV",
    Min = 1,
    Max = 50,
    Default = 20,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.TriggerFOV = Value
    end
})

-- Slider: Trigger Delay (ms)
Triggerbot:AddSlider("TriggerDelay", {
    Text = "Trigger Delay (ms)",
    Min = 1,
    Max = 1000,
    Default = 1,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.TriggerDelay = Value
    end
})

HitboxExpander:AddToggle("HitboxExpanderEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.HitboxExpanderEnabled = Value
    end
})

-- Slider: Size
HitboxExpander:AddSlider("HitboxSize", {
    Text = "Size",
    Min = 1,
    Max = 50,
    Default = 10,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.HitboxSize = Value
    end
})

-- Toggle: Visualize Hitbox
local VisualizeToggle = HitboxExpander:AddToggle("VisualizeHitbox", {
    Text = "Visualize Hitbox",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.VisualizeHitbox = Value
    end
})

-- Colorpicker: Hitbox Color
VisualizeToggle:AddColorPicker("HitboxColor", {
    Default = Color3.fromRGB(70, 220, 110),
    Title = "Hitbox Color",
    Transparency = 0.2, -- tương ứng Alpha = 0.8
    Callback = function(Value)
        getgenv().matcha.HitboxColor = Value
    end
})

-- Colorpicker: Hitbox Outline Color
VisualizeToggle:AddColorPicker("HitboxOutlineColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "Hitbox Outline Color",
    Transparency = 1, -- tương ứng Alpha = 0
    Callback = function(Value)
        getgenv().matcha.HitboxOutlineColor = Value
    end
})

-- Toggle: Check Team
HitboxExpander:AddToggle("HitboxCheckTeam", {
    Text = "Check Team",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.HitboxCheckTeam = Value
    end
})

-- Toggle: Target Only
HitboxExpander:AddToggle("HitboxOnlyTarget", {
    Text = "Target Only",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.HitboxOnlyTarget = Value
    end
})

FovCircle:AddToggle("UseFOV", {
    Text = "Use FOV",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.UseFOV = Value
    end
})

-- Slider: FOV Size
FovCircle:AddSlider("FOVSize", {
    Text = "FOV Size",
    Min = 1,
    Max = 1000,
    Default = 100,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.FOVSize = Value
    end
})

-- Toggle: FOV Outline
local FOVOutlineToggle = FovCircle:AddToggle("FOVOutline", {
    Text = "FOV Outline",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.FOVOutline = Value
    end
})

-- Colorpicker: FOV Outline Color
FOVOutlineToggle:AddColorPicker("FOVOutlineColor", {
    Default = Color3.fromRGB(0, 0, 0),
    Title = "FOV Outline Color",
    Transparency = 0, -- Alpha 0 = trong suốt
    Callback = function(Value)
        getgenv().matcha.FOVOutlineColor = Value
    end
})

-- Toggle: FOV Filled
local FOVFilledToggle = FovCircle:AddToggle("FOVFilled", {
    Text = "FOV Filled",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.FOVFilled = Value
    end
})

-- Colorpicker: FOV Filled Color
FOVFilledToggle:AddColorPicker("FOVFilledColor", {
    Default = Color3.fromRGB(255, 255, 255),
    Title = "FOV Filled Color",
    Transparency = 0.5, -- Alpha = 0.5
    Callback = function(Value)
        getgenv().matcha.FOVFilledColor = Value
    end
})

-- Slider: FOV Thickness
FovCircle:AddSlider("FOVThickness", {
    Text = "FOV Thickness",
    Min = 1,
    Max = 10,
    Default = 1,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.FOVThickness = Value
    end
})

-- === FLY V1 (CFRAME) - ĐƠN GIẢN THEO FORMAT CỦA BẠN ===
local function UpdateFlyV1(deltaTime)
    if getgenv().matcha.FlyV1Enabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        local moveDirection = hum.MoveDirection
        local flySpeed = getgenv().matcha.FlySpeed
        local vertical = UserInputService:IsKeyDown(Enum.KeyCode.Space) and flySpeed / 10 or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) and -flySpeed / 10 or 0
        
        root.CFrame = root.CFrame + moveDirection * deltaTime * flySpeed * 1
        root.CFrame = root.CFrame + Vector3.new(0, vertical, 0)
        
        -- Giữ ổn định (không trôi)
        root.Velocity = root.Velocity * Vector3.new(1, 0, 1) + Vector3.new(0, 1.9, 0)
        root.RotVelocity = Vector3.new(0, 0, 0)
    end
end

-- Kết nối RenderStepped
local FlyV1Connection = nil
FlyV1Connection = RunService.RenderStepped:Connect(UpdateFlyV1)

-- LOGIC FLY V2 (Velocity) - Ổn định, chống kick
local FlyV2 = nil
FlyV2 = game:GetService("RunService").Stepped:Connect(function()
    if not getgenv().matcha.FlyV2Enabled then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    local cam = workspace.CurrentCamera
    local speed = getgenv().matcha.FlySpeed * 1.2
    
    local moveVector = Vector3.new(0, 0, 0)
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveVector = moveVector + cam.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveVector = moveVector - cam.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveVector = moveVector - cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveVector = moveVector + cam.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveVector = moveVector + Vector3.new(0, 1, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveVector = moveVector + Vector3.new(0, -1, 0)
    end
    
    if moveVector.Magnitude > 0 then
        hrp.Velocity = Vector3.new(
            moveVector.X * speed,
            moveVector.Y * speed,
            moveVector.Z * speed
        )
    else
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
    end
end)

-- Tự động ngắt fly khi respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    if getgenv().matcha.FlyV1Enabled then
        getgenv().matcha.FlyV1Enabled = false
        flyV1Toggle:Set(false)
        FlyV1:Disconnect()
    end
    if getgenv().matcha.FlyV2Enabled then
        getgenv().matcha.FlyV2Enabled = false
        flyV2Toggle:Set(false)
        FlyV2:Disconnect()
    end
end)

-- Logic CFrame Speed (chạy mỗi frame, tối ưu, không gây lag)
local cfSpeedConn
cfSpeedConn = RunService.Heartbeat:Connect(function(dt)
    if not getgenv().matcha.CFrameSpeedEnabled then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local root = char.HumanoidRootPart
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.MoveDirection.Magnitude == 0 then return end

    local speed = getgenv().matcha.CFrameSpeedAmount * dt * 1
    root.CFrame = root.CFrame + (hum.MoveDirection * speed)
end)

local defaultWalkSpeed = 16
local defaultJumpPower = 50

-- Cập nhật default khi script load (nếu đã có char)
if LocalPlayer.Character then
    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        defaultWalkSpeed = hum.WalkSpeed
        defaultJumpPower = hum.JumpPower
    end
end

-- Biến lưu connection để tránh leak
local walkConn, jumpConn = nil, nil

-- Hàm apply boost cho char hiện tại
local function applyBoostToCurrentChar()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    -- Ngắt connection cũ
    if walkConn then walkConn:Disconnect() end
    if jumpConn then jumpConn:Disconnect() end

    if getgenv().matcha.Enabledboost then
        -- Áp dụng ngay
        hum.WalkSpeed = getgenv().matcha.WalkSpeed
        hum.JumpPower = getgenv().matcha.JumpPower

        -- Chống bị game reset lại
        walkConn = hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if getgenv().matcha.Enabledboost then
                hum.WalkSpeed = getgenv().matcha.WalkSpeed
            end
        end)

        jumpConn = hum:GetPropertyChangedSignal("JumpPower"):Connect(function()
            if getgenv().matcha.Enabledboost then
                hum.JumpPower = getgenv().matcha.JumpPower
            end
        end)
    else
        hum.WalkSpeed = defaultWalkSpeed
        hum.JumpPower = defaultJumpPower
    end
end

-- Khi respawn: apply lại + chống reset
LocalPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end

    task.wait(0.1)  -- Đảm bảo load xong

    -- Áp dụng nếu đang bật
    if getgenv().matcha.Enabledboost then
        applyBoostToCurrentChar()
    end
end)
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if getgenv().matcha.Enabledboost then
        hum.WalkSpeed = getgenv().matcha.WalkSpeed
        hum.JumpPower = getgenv().matcha.JumpPower
    else
        hum.WalkSpeed = defaultWalkSpeed
        hum.JumpPower = defaultJumpPower
    end
end)

game:GetService("RunService").RenderStepped:Connect(function()
    if getgenv().matcha.BunnyHopEnabled then
        local char = game.Players.LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local cam = workspace.CurrentCamera
        if hum and hrp and cam then
            local spaceDown = game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) or (game:GetService("UserInputService").TouchEnabled and game:GetService("UserInputService"):GetFocusedTextBox() == nil and #game:GetService("UserInputService"):GetTouches() > 0)  -- Mobile support
            if spaceDown then
                hum.Jump = true
                local dir = cam.CFrame.LookVector * Vector3.new(1, 0, 1)
                local move = Vector3.zero
                local uis = game:GetService("UserInputService")
                if uis:IsKeyDown(Enum.KeyCode.W) or (uis.TouchEnabled and uis:GetFocusedTextBox() == nil) then move += dir end
                if uis:IsKeyDown(Enum.KeyCode.S) then move -= dir end
                if uis:IsKeyDown(Enum.KeyCode.D) then move += Vector3.new(-dir.Z, 0, dir.X) end
                if uis:IsKeyDown(Enum.KeyCode.A) then move += Vector3.new(dir.Z, 0, -dir.X) end
                if move.Magnitude > 0 then
                    hrp.Velocity = Vector3.new(move.Unit.X * getgenv().matcha.BunnyHopSpeed, hrp.Velocity.Y, move.Unit.Z * getgenv().matcha.BunnyHopSpeed)
                end
            end
        end
    end
end)

-- Fly V1 (CFrame)
local FlyV1Toggle = MovementSelection:AddToggle("FlyV1Enabled", {
    Text = "Fly V1 (CFrame)",
    Default = false,
    Callback = function(v)
        getgenv().matcha.FlyV1Enabled = v
        if v then
            FlyV2:Disconnect()
            FlyV1:Connect()
        else
            FlyV1:Disconnect()
        end
    end
})

FlyV1Toggle:AddKeyPicker("FlyV1Key", {
    Default = "F",
    Mode = "Toggle",
    Text = "Fly V1 Keybind",
    Callback = function()
        getgenv().matcha.FlyV1Enabled = not getgenv().matcha.FlyV1Enabled
        FlyV1Toggle:Set(getgenv().matcha.FlyV1Enabled)
        if getgenv().matcha.FlyV1Enabled then
            FlyV2:Disconnect()
            FlyV1:Connect()
        else
            FlyV1:Disconnect()
        end
    end
})

-- Fly V2 (Velocity)
local FlyV2Toggle = MovementSelection:AddToggle("FlyV2Enabled", {
    Text = "Fly V2 (Velocity)",
    Default = false,
    Callback = function(v)
        getgenv().matcha.FlyV2Enabled = v
        if v then
            FlyV1:Disconnect()
            FlyV2:Connect()
        else
            FlyV2:Disconnect()
        end
    end
})

FlyV2Toggle:AddKeyPicker("FlyV2Key", {
    Default = "G",
    Mode = "Toggle",
    Text = "Fly V2 Keybind",
    Callback = function()
        getgenv().matcha.FlyV2Enabled = not getgenv().matcha.FlyV2Enabled
        FlyV2Toggle:Set(getgenv().matcha.FlyV2Enabled)
        if getgenv().matcha.FlyV2Enabled then
            FlyV1:Disconnect()
            FlyV2:Connect()
        else
            FlyV2:Disconnect()
        end
    end
})

-- Slider: Fly Speed
MovementSelection:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Min = 1,
    Max = 500,
    Default = 100,
    Rounding = 1,
    Callback = function(v)
        getgenv().matcha.FlySpeed = v
    end
})

-- CFrame Speed Toggle + Keybind
local CFrameSpeedToggle = MovementSelection:AddToggle("CFrameSpeedEnabled", {
    Text = "CFrame Speed",
    Default = false,
    Callback = function(v)
        getgenv().matcha.CFrameSpeedEnabled = v
    end
})

CFrameSpeedToggle:AddKeyPicker("CFrameSpeedKey", {
    Default = "C",
    Mode = "Toggle",
    Text = "CFrame Speed Keybind",
    Callback = function()
        getgenv().matcha.CFrameSpeedEnabled = not getgenv().matcha.CFrameSpeedEnabled
        CFrameSpeedToggle:Set(getgenv().matcha.CFrameSpeedEnabled)
    end
})

-- Slider: CFrame Speed Amount
MovementSelection:AddSlider("CFrameSpeedAmount", {
    Text = "CFrame Speed Amount",
    Min = 1,
    Max = 5000,
    Default = 50,
    Rounding = 1,
    Callback = function(v)
        getgenv().matcha.CFrameSpeedAmount = v
    end
})

-- Speed / Jump Toggle + Keybind
local SpeedToggle = MovementSelection:AddToggle("SpeedJumpEnabled", {
    Text = "Speed / Jump",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.Enabledboost = Value
        applyBoostToCurrentChar()
    end
})

SpeedToggle:AddKeyPicker("SpeedJumpKey", {
    Default = "T",
    Mode = "Toggle",
    Text = "Speed / Jump Keybind",
    Callback = function()
        getgenv().matcha.Enabledboost = not getgenv().matcha.Enabledboost
        SpeedToggle:Set(getgenv().matcha.Enabledboost)
        applyBoostToCurrentChar()
    end
})

-- WalkSpeed Input
MovementSelection:AddInput("WalkSpeedValue", {
    Text = "WalkSpeed",
    Default = "50",
    Placeholder = "Enter WalkSpeed",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num > 0 then
            getgenv().matcha.WalkSpeed = num
            if getgenv().matcha.Enabledboost then
                applyBoostToCurrentChar()
            end
        end
    end
})

-- JumpPower Input
MovementSelection:AddInput("JumpPowerValue", {
    Text = "JumpPower",
    Default = "100",
    Placeholder = "Enter JumpPower",
    Callback = function(Value)
        local num = tonumber(Value)
        if num and num >= 0 then
            getgenv().matcha.JumpPower = num
            if getgenv().matcha.Enabledboost then
                applyBoostToCurrentChar()
            end
        end
    end
})

-- BunnyHop
MovementSelection:AddToggle("BunnyHopEnabled", {
    Text = "BunnyHop",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.BunnyHopEnabled = Value
    end
})

MovementSelection:AddSlider("BunnyHopSpeed", {
    Text = "BunnyHop Speed",
    Min = 1,
    Max = 200,
    Default = 50,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.BunnyHopSpeed = Value
    end
})

-- Infinite Jump
MovementSelection:AddToggle("InfJumpEnabled", {
    Text = "Inf Jump",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.InfJumpEnabled = Value
    end
})

-- Logic: Inf Jump (PC + Mobile)
game:GetService("UserInputService").InputBegan:Connect(function(input, processed)
    if getgenv().matcha.InfJumpEnabled and not processed then
        if input.KeyCode == Enum.KeyCode.Space or (game:GetService("UserInputService").TouchEnabled and input.UserInputType == Enum.UserInputType.Touch) then
            local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- No Jump Cooldown
MovementSelection:AddToggle("NoJumpCooldown", {
    Text = "No Jump Cooldown",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.NoJumpCooldown = Value
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.UseJumpPower = not Value
        end
    end
})

-- Anti Slowdown
MovementSelection:AddToggle("AntiSlowdown", {
    Text = "Anti Slowdown",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.AntiSlowdown = Value
        toggleAntiSlow()
    end
})
-- THÊM VÀO CUỐI FILE (sau tất cả logic hiện tại)
local function toggleAntiSlow()
    if getgenv().matcha.AntiSlowdown then
        RunService:BindToRenderStep("Anti-Slow", Enum.RenderPriority.Camera.Value, function()
            local char = LocalPlayer.Character
            if not char or not char:FindFirstChild("BodyEffects") then return end
            local movement = char.BodyEffects:FindFirstChild("Movement")
            local reload = char.BodyEffects:FindFirstChild("Reload")
            if movement then
                if movement:FindFirstChild("NoWalkSpeed") then movement.NoWalkSpeed:Destroy() end
                if movement:FindFirstChild("ReduceWalk") then movement.ReduceWalk:Destroy() end
                if movement:FindFirstChild("NoJumping") then movement.NoJumping:Destroy() end
            end
            if reload and reload:IsA("BoolValue") and reload.Value then
                reload.Value = false
            end
        end)
    else
        RunService:UnbindFromRenderStep("Anti-Slow")
    end
end

-- Tự động bật lại khi respawn (chống mất hiệu lực)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.2)
    if getgenv().matcha.AntiSlowdown then
        toggleAntiSlow(true)
    end
end)

-- === LOGIC NOCLIP – CHỈ CHẠY KHI FLY + NOCLIP BẬT ===
local parts = {}

local function updateNoclip()
    local char = LocalPlayer.Character
    if not char then parts = {} return end

    -- Chỉ bật khi đang Fly + Noclip
    local shouldNoclip = getgenv().matcha.FlyEnabled and getgenv().matcha.NoclipEnabled

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            if shouldNoclip then
                if not parts[part] then
                    parts[part] = part.CanCollide
                    part.CanCollide = false
                end
            else
                if parts[part] ~= nil then
                    part.CanCollide = parts[part]
                    parts[part] = nil
                end
            end
        end
    end
end

-- Chạy mỗi frame
RunService.Heartbeat:Connect(updateNoclip)

-- Reset khi respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    parts = {}
    updateNoclip()
end)

-- Toggle: Noclip
local NoclipToggle = MiscClient:AddToggle("NoclipEnabled", {
    Text = "Noclip",
    Default = false,
    Callback = function(v)
        getgenv().matcha.NoclipEnabled = v
    end
})

-- Keybind cho Noclip
NoclipToggle:AddKeyPicker("NoclipKey", {
    Default = "N",
    Mode = "Toggle",
    Text = "Noclip Keybind",
    Callback = function()
        getgenv().matcha.NoclipEnabled = not getgenv().matcha.NoclipEnabled
        NoclipToggle:Set(getgenv().matcha.NoclipEnabled)
    end
})

-- Toggle: AntiVoid
MiscClient:AddToggle("AntiVoidEnabled", {
    Text = "AntiVoid",
    Default = false,
    Callback = function(Value)
        if Value then
            workspace.FallenPartsDestroyHeight = -math.huge
        else
            workspace.FallenPartsDestroyHeight = -50
        end
    end
})

-- Toggle: Spinbot
MiscClient:AddToggle("SpinbotEnabled", {
    Text = "Spinbot",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.SpinbotEnabled = Value

        local RunService = game:GetService("RunService")
        if Value then
            RunService:BindToRenderStep("Spinbot", Enum.RenderPriority.Character.Value, function()
                local hrp = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(getgenv().matcha.SpinSpeed or 10), 0)
                end
            end)
        else
            RunService:UnbindFromRenderStep("Spinbot")
        end
    end
})

-- Slider: Spin Speed
MiscClient:AddSlider("SpinSpeed", {
    Text = "Spin Speed",
    Min = 1,
    Max = 10000,
    Default = 10,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.SpinSpeed = Value
    end
})

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
    SkyboxDn = "http://www.roblox.com/asset/?id=149397686";
    SkyboxFt = "http://www.roblox.com/asset/?id=149397697";
    SkyboxLf = "http://www.roblox.com/asset/?id=149397684";
    SkyboxRt = "http://www.roblox.com/asset/?id=149397688";
    SkyboxUp = "http://www.roblox.com/asset/?id=149397702";
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

Lighting:AddToggle("CustomAmbient", {
    Text = "Custom Ambient",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomAmbient = Value
        LightingService.Ambient = Value and getgenv().matcha.AmbientColor or originalAmbient
    end
}):AddColorPicker("AmbientColor", {
    Default = originalAmbient,
    Callback = function(Value)
        getgenv().matcha.AmbientColor = Value
        if getgenv().matcha.CustomAmbient then
            LightingService.Ambient = Value
        end
    end
})

-- Custom Outdoor Ambient
Lighting:AddToggle("CustomOutdoorAmbient", {
    Text = "Custom Outdoor Ambient",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomOutdoorAmbient = Value
        LightingService.OutdoorAmbient = Value and getgenv().matcha.OutdoorAmbientColor or originalOutdoorAmbient
    end
}):AddColorPicker("OutdoorAmbientColor", {
    Default = originalOutdoorAmbient,
    Callback = function(Value)
        getgenv().matcha.OutdoorAmbientColor = Value
        if getgenv().matcha.CustomOutdoorAmbient then
            LightingService.OutdoorAmbient = Value
        end
    end
})

-- Custom Fog
Lighting:AddToggle("CustomFog", {
    Text = "Custom Fog",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomFog = Value
        if Value then
            LightingService.FogColor = getgenv().matcha.FogColor
            LightingService.FogStart = getgenv().matcha.FogStart
            LightingService.FogEnd = getgenv().matcha.FogEnd
        else
            LightingService.FogColor = originalFogColor
            LightingService.FogStart = originalFogStart
            LightingService.FogEnd = originalFogEnd
        end
    end
}):AddColorPicker("FogColor", {
    Default = originalFogColor,
    Callback = function(Value)
        getgenv().matcha.FogColor = Value
        if getgenv().matcha.CustomFog then
            LightingService.FogColor = Value
        end
    end
})

Lighting:AddSlider("FogStart", {
    Text = "Fog Start",
    Min = 0,
    Max = 1000,
    Default = originalFogStart,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.FogStart = Value
        if getgenv().matcha.CustomFog then
            LightingService.FogStart = Value
        end
    end
})

Lighting:AddSlider("FogEnd", {
    Text = "Fog End",
    Min = 0,
    Max = 1000,
    Default = originalFogEnd,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.FogEnd = Value
        if getgenv().matcha.CustomFog then
            LightingService.FogEnd = Value
        end
    end
})

-- Custom Brightness
Lighting:AddToggle("CustomBrightness", {
    Text = "Custom Brightness",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomBrightness = Value
        LightingService.Brightness = Value and getgenv().matcha.BrightnessValue or originalBrightness
    end
})

Lighting:AddSlider("BrightnessValue", {
    Text = "Brightness",
    Min = 0,
    Max = 10,
    Default = originalBrightness,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.BrightnessValue = Value
        if getgenv().matcha.CustomBrightness then
            LightingService.Brightness = Value
        end
    end
})

-- Custom Clock Time
Lighting:AddToggle("CustomClockTime", {
    Text = "Custom Clock Time",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomClockTime = Value
        LightingService.ClockTime = Value and getgenv().matcha.ClockTimeValue or originalClockTime
    end
})

Lighting:AddSlider("ClockTimeValue", {
    Text = "Clock Time",
    Min = 0,
    Max = 24,
    Default = originalClockTime,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.ClockTimeValue = Value
        if getgenv().matcha.CustomClockTime then
            LightingService.ClockTime = Value
        end
    end
})

-- Global Shadows
Lighting:AddToggle("GlobalShadows", {
    Text = "Global Shadows",
    Default = originalGlobalShadows,
    Callback = function(Value)
        LightingService.GlobalShadows = Value
    end
})

-- Environment Diffuse
Lighting:AddToggle("CustomEnvironmentDiffuse", {
    Text = "Custom Environment Diffuse",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomEnvironmentDiffuse = Value
        LightingService.EnvironmentDiffuseScale = Value and getgenv().matcha.EnvironmentDiffuseValue or originalEnvironmentDiffuseScale
    end
})

Lighting:AddSlider("EnvironmentDiffuseValue", {
    Text = "Environment Diffuse Scale",
    Min = 0,
    Max = 1,
    Default = originalEnvironmentDiffuseScale,
    Rounding = 2,
    Callback = function(Value)
        getgenv().matcha.EnvironmentDiffuseValue = Value
        if getgenv().matcha.CustomEnvironmentDiffuse then
            LightingService.EnvironmentDiffuseScale = Value
        end
    end
})

-- Environment Specular
Lighting:AddToggle("CustomEnvironmentSpecular", {
    Text = "Custom Environment Specular",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomEnvironmentSpecular = Value
        LightingService.EnvironmentSpecularScale = Value and getgenv().matcha.EnvironmentSpecularValue or originalEnvironmentSpecularScale
    end
})

Lighting:AddSlider("EnvironmentSpecularValue", {
    Text = "Environment Specular Scale",
    Min = 0,
    Max = 1,
    Default = originalEnvironmentSpecularScale,
    Rounding = 2,
    Callback = function(Value)
        getgenv().matcha.EnvironmentSpecularValue = Value
        if getgenv().matcha.CustomEnvironmentSpecular then
            LightingService.EnvironmentSpecularScale = Value
        end
    end
})

-- Exposure Compensation
Lighting:AddToggle("CustomExposure", {
    Text = "Custom Exposure",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomExposure = Value
        LightingService.ExposureCompensation = Value and getgenv().matcha.ExposureValue or originalExposureCompensation
    end
})

Lighting:AddSlider("ExposureValue", {
    Text = "Exposure Compensation",
    Min = -3,
    Max = 3,
    Default = originalExposureCompensation,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.ExposureValue = Value
        if getgenv().matcha.CustomExposure then
            LightingService.ExposureCompensation = Value
        end
    end
})

-- Color Shift Bottom
Lighting:AddToggle("CustomColorShiftBottom", {
    Text = "Custom Color Shift Bottom",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomColorShiftBottom = Value
        LightingService.ColorShift_Bottom = Value and getgenv().matcha.ColorShiftBottomColor or originalColorShiftBottom
    end
}):AddColorPicker("ColorShiftBottomColor", {
    Default = originalColorShiftBottom,
    Callback = function(Value)
        getgenv().matcha.ColorShiftBottomColor = Value
        if getgenv().matcha.CustomColorShiftBottom then
            LightingService.ColorShift_Bottom = Value
        end
    end
})

-- Color Shift Top
Lighting:AddToggle("CustomColorShiftTop", {
    Text = "Custom Color Shift Top",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomColorShiftTop = Value
        LightingService.ColorShift_Top = Value and getgenv().matcha.ColorShiftTopColor or originalColorShiftTop
    end
}):AddColorPicker("ColorShiftTopColor", {
    Default = originalColorShiftTop,
    Callback = function(Value)
        getgenv().matcha.ColorShiftTopColor = Value
        if getgenv().matcha.CustomColorShiftTop then
            LightingService.ColorShift_Top = Value
        end
    end
})

-- Geographic Latitude
Lighting:AddToggle("CustomGeographicLatitude", {
    Text = "Custom Geographic Latitude",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomGeographicLatitude = Value
        LightingService.GeographicLatitude = Value and getgenv().matcha.GeographicLatitudeValue or originalGeographicLatitude
    end
})

Lighting:AddSlider("GeographicLatitudeValue", {
    Text = "Geographic Latitude",
    Min = -90,
    Max = 90,
    Default = originalGeographicLatitude,
    Rounding = 1,
    Callback = function(Value)
        getgenv().matcha.GeographicLatitudeValue = Value
        if getgenv().matcha.CustomGeographicLatitude then
            LightingService.GeographicLatitude = Value
        end
    end
})

-- Shadow Mode
Lighting:AddDropdown("ShadowMode", {
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
Misc:AddToggle("NebulaTheme", {
    Text = "Nebula Theme",
    Default = false,
    Callback = function(state)
        getgenv().matcha.nebulaEnabled = state
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
        if getgenv().matcha.nebulaEnabled then
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
Misc:AddToggle("CustomSkybox", {
    Text = "Custom Skybox",
    Default = false,
    Callback = function(Value)
        getgenv().matcha.CustomSkybox = Value
        Visuals:SwitchSkybox(Value and (getgenv().matcha.SelectedSkybox or "Game's Default Sky") or "Game's Default Sky")
    end
})

Misc:AddDropdown("SelectedSkybox", {
    Values = SkyboxNames,
    Default = "Game's Default Sky",
    Multi = false,
    Text = "Skybox",
    Callback = function(Value)
        getgenv().matcha.SelectedSkybox = Value
        if getgenv().matcha.CustomSkybox then
            Visuals:SwitchSkybox(Value)
        end
    end
})

getgenv().matcha.Desync = {
    Enabled = false,
    Mode = "Void"
}
getgenv().matcha.AntiLock = {
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

-- === TẠO PART DESYNC ===
local desync_setback = Instance.new("Part")
desync_setback.Name = "DesyncSetback"
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.CanCollide = false
desync_setback.Anchored = true
desync_setback.Transparency = 1
desync_setback.Parent = workspace

-- === RESET CAMERA ===
local function resetCamera()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        workspace.CurrentCamera.CameraSubject = LocalPlayer.Character.Humanoid
    end
end

AntiAimBox:AddToggle("DesyncEnabled", {
	Text = "Desync",
	Default = false,

	Callback = function(Value)
		getgenv().matcha.Desync.Enabled = Value
	end,
}):AddKeyPicker("DesyncKeybind", {
	Default = "V",
	Mode = "Toggle",
	Text = "Desync Key",
	NoUI = false,

	Callback = function(Value)
		getgenv().matcha.Desync.Enabled = Value
	end,
})

-- Desync Mode
AntiAimBox:AddDropdown("DesyncMode", {
    Values = { "Destroy Cheaters", "Underground", "Void Spam", "Void" },
    Default = "Void",
    Multi = false,
    Text = "Desync Mode",
    Callback = function(v)
        getgenv().matcha.Desync.Mode = v
    end
})

AntiAimBox:AddToggle("AntiLockEnabled", {
	Text = "Anti Lock",
	Default = false,

	Callback = function(Value)
		getgenv().matcha.AntiLock.Enabled = Value
	end,
}):AddKeyPicker("AntiLockKeybind", {
	Default = "B",
	Mode = "Toggle",
	Text = "Anti Lock Key",
	NoUI = false,

	Callback = function()
		getgenv().matcha.AntiLock.Enabled = not getgenv().matcha.AntiLock.Enabled
	end,
})

-- Anti Lock Mode
AntiAimBox:AddDropdown("AntiLockMode", {
    Values = { "Custom", "Up", "Down", "VelMultiply", "LookVec", "Reverse", "Confusion", "PredBreaker" },
    Default = "Custom",
    Multi = false,
    Text = "Anti Lock Mode",
    Callback = function(v)
        getgenv().matcha.AntiLock.Mode = v
    end
})

--====================================================================--
--========================= CUSTOM MODE ==============================--
--====================================================================--

AntiAimBox:AddSlider("CustomX", {
    Text = "Custom X",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Custom.X = v
    end
})

AntiAimBox:AddSlider("CustomY", {
    Text = "Custom Y",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Custom.Y = v
    end
})

AntiAimBox:AddSlider("CustomZ", {
    Text = "Custom Z",
    Min = -10000,
    Max = 10000,
    Default = 0,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Custom.Z = v
    end
})

--====================================================================--
--========================= UP / DOWN ================================--
--====================================================================--

AntiAimBox:AddSlider("UpAmount", {
    Text = "Up Amount",
    Min = 1,
    Max = 10000,
    Default = 100,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Up.Amount = v
    end
})

AntiAimBox:AddSlider("DownAmount", {
    Text = "Down Amount",
    Min = 1,
    Max = 10000,
    Default = 100,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Down.Amount = v
    end
})

--====================================================================--
--========================= VELOCITY MULTIPLY ========================--
--====================================================================--

AntiAimBox:AddInput("VelWalk", {
    Text = "Vel Walk",
    Default = "1.5",
    Numeric = true,
    Finished = true,
    Placeholder = "1.5",
    Callback = function(v)
        getgenv().matcha.AntiLock.VelMultiply.Walk = tonumber(v) or 1.5
    end
})

AntiAimBox:AddInput("VelJump", {
    Text = "Vel Jump",
    Default = "1.0",
    Numeric = true,
    Finished = true,
    Placeholder = "1.0",
    Callback = function(v)
        getgenv().matcha.AntiLock.VelMultiply.Jump = tonumber(v) or 1.0
    end
})

--====================================================================--
--========================= LOOKVEC / REVERSE ========================--
--====================================================================--

AntiAimBox:AddSlider("LookVecAmt", {
    Text = "LookVec Amount",
    Min = 1,
    Max = 10000,
    Default = 500,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.LookVec.Amount = v
    end
})

AntiAimBox:AddSlider("ReverseAmt", {
    Text = "Reverse Amount",
    Min = 1,
    Max = 10000,
    Default = 50,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Reverse.Amount = v
    end
})

AntiAimBox:AddDropdown("ReverseType", {
    Values = { "CFrame", "Velocity" },
    Default = "CFrame",
    Multi = false,
    Text = "Reverse Type",
    Callback = function(v)
        getgenv().matcha.AntiLock.Reverse.Type = v
    end
})

--====================================================================--
--========================= CONFUSION ================================--
--====================================================================--

AntiAimBox:AddSlider("ConfusionAmt", {
    Text = "Confusion Amount",
    Min = 1,
    Max = 10000,
    Default = 5,
    Rounding = 0,
    Callback = function(v)
        getgenv().matcha.AntiLock.Confusion.Amount = v
    end
})
-- === DESYNC LOGIC (Heartbeat) ===
RunService.Heartbeat:Connect(function()
    if not getgenv().matcha.Desync.Enabled or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = hrp.CFrame
    local pos = old.Position

    if getgenv().matcha.Desync.Mode == "Destroy Cheaters" then
        pos = Vector3.new(9e9, 1, 1)
    elseif getgenv().matcha.Desync.Mode == "Underground" then
        pos = pos - Vector3.new(0, 12, 0)
    elseif getgenv().matcha.Desync.Mode == "Void Spam" then
        pos = math.random(1,2) == 1 and old.Position or Vector3.new(math.random(10000,50000), math.random(10000,50000), math.random(10000,50000))
    elseif getgenv().matcha.Desync.Mode == "Void" then
        pos = pos + Vector3.new(math.random(-444444,444444), math.random(-444444,444444), math.random(-44444,44444))
    end

    hrp.CFrame = CFrame.new(pos)
    workspace.CurrentCamera.CameraSubject = desync_setback
    RunService.RenderStepped:Wait()
    desync_setback.CFrame = old * CFrame.new(0, hrp.Size.Y/2 + 0.5, 0)
    hrp.CFrame = old
end)

-- === ANTI LOCK LOGIC (Heartbeat) ===
RunService.Heartbeat:Connect(function()
    if not getgenv().matcha.AntiLock.Enabled or not LocalPlayer.Character then return end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    local vel = hrp.Velocity
    local cf = hrp.CFrame
    local S = getgenv().matcha.AntiLock

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

-- === TỰ ĐỘNG RESET CAMERA KHI TẮT DESYNC HOẶC RESPAWN ===
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.1)
    resetCamera()
end)

-- Khi tắt Desync
spawn(function()
    while task.wait(0.1) do
        if not getgenv().matcha.Desync.Enabled then
            resetCamera()
        end
    end
end)
--[[local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local lp = game.Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- Danh sách animation
local animations = {
	M = "http://www.roblox.com/asset/?id=15609995579",
	N = "http://www.roblox.com/asset/?id=14352343065",
	K = "rbxassetid://115730920794562",
}

local currentTrack = nil
local currentKey = nil
local renderConnection = nil
local inputConnection = nil

-- Hàm thiết lập nhân vật
local function setup(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if not hum then return end

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)

	-- Ngắt kết nối cũ
	if renderConnection then renderConnection:Disconnect() end
	if inputConnection then inputConnection:Disconnect() end

	-- Dừng animation khi di chuyển
	renderConnection = rs.RenderStepped:Connect(function()
		if currentTrack and hum.MoveDirection.Magnitude > 0 then
			currentTrack:Stop()
			currentTrack = nil
			currentKey = nil
		end
	end)

	-- Phát animation khi nhấn phím
	inputConnection = uis.InputBegan:Connect(function(input)
		local key = input.KeyCode.Name
		local animId = animations[key]
		if animId and hum.MoveDirection.Magnitude == 0 then
			if currentTrack then
				currentTrack:Stop()
				currentTrack = nil
				currentKey = nil
			end
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local track = animator:LoadAnimation(anim)
			track:Play()
			currentTrack = track
			currentKey = key
		end
	end)
end

-- Kiểm tra character hiện tại
if lp.Character then
	setup(lp.Character)
end

-- Khi nhân vật respawn
lp.CharacterAdded:Connect(function(char)
	currentTrack = nil
	currentKey = nil
	task.wait(0.2)
	setup(char)
end)]]

pcall(function()
    local oldIndex
    local success = pcall(function()
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() and self:IsA("Mouse") and (key == "Hit" or key == "Target") then
                if getgenv().matcha.AimEnabled and getgenv().matcha.SilentAimEnabled and 
                   silentTarget and silentAimPosition and math.random(1, 100) <= getgenv().matcha.HitChance then

                    if key == "Hit" then
                        return CFrame.new(silentAimPosition)
                    elseif key == "Target" then
                        return silentTarget.Character:FindFirstChild(getgenv().matcha.HitPart) or silentTarget.Character.HumanoidRootPart
                    end
                end
            end
            return oldIndex(self, key)
        end)
    end)
    if not success then warn("[matcha] Silent Aim hook failed") end
end)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
	Default = Library.KeybindFrame.Visible,
	Text = "Open Keybind Menu",
	Callback = function(value)
		Library.KeybindFrame.Visible = value
	end,
})
MenuGroup:AddToggle("ShowCustomCursor", {
	Text = "Custom Cursor",
	Default = true,
	Callback = function(Value)
		Library.ShowCustomCursor = Value
	end,
})
MenuGroup:AddDropdown("NotificationSide", {
	Values = { "Left", "Right" },
	Default = "Right",

	Text = "Notification Side",

	Callback = function(Value)
		Library:SetNotifySide(Value)
	end,
})
MenuGroup:AddDropdown("DPIDropdown", {
	Values = { "50%", "75%", "100%", "125%", "150%", "175%", "200%" },
	Default = "100%",

	Text = "DPI Scale",

	Callback = function(Value)
		Value = Value:gsub("%%", "")
		local DPI = tonumber(Value)

		Library:SetDPIScale(DPI)
	end,
})
MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", { Default = "RightShift", NoUI = true, Text = "Menu keybind" })

--// Rejoin & Server Hop Buttons
MenuGroup:AddButton({
	Text = "Rejoin Server",
	Tooltip = "Rejoin the current game server",
	Func = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId, game.Players.LocalPlayer)
	end,
})

MenuGroup:AddButton({
	Text = "Server Hop",
	Tooltip = "Join a new random server",
	Func = function()
		local HttpService = game:GetService("HttpService")
		local TeleportService = game:GetService("TeleportService")
		local PlaceId = game.PlaceId
		local Servers = {}
		
		local Success, Response = pcall(function()
			return HttpService:JSONDecode(
				game:HttpGet(
					"https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
				)
			)
		end)

		if Success and Response and Response.data then
			for _, Server in ipairs(Response.data) do
				if type(Server) == "table" and Server.playing < Server.maxPlayers and Server.id ~= game.JobId then
					table.insert(Servers, Server.id)
				end
			end
		end

		if #Servers > 0 then
			TeleportService:TeleportToPlaceInstance(PlaceId, Servers[math.random(1, #Servers)], game.Players.LocalPlayer)
		else
			Library:Notify({
				Title = "Server Hop",
				Description = "No available servers found!",
				Time = 4,
			})
		end
	end,
})

MenuGroup:AddButton("Unload", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

ThemeManager:SetFolder("MyScriptHub")
SaveManager:SetFolder("Matcha/Universal")
SaveManager:SetSubFolder("Universal") 

SaveManager:BuildConfigSection(Tabs["UI Settings"])

ThemeManager:ApplyToTab(Tabs["UI Settings"])

SaveManager:LoadAutoloadConfig()

Library:Notify({ Title = "matcha.tea", Description = "Thank you for using matcha.tea", Time = 5 })
