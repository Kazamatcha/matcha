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
local Services = {
    Workspace = game:GetService("Workspace"),
    Players = game:GetService("Players"),
    ReplicatedStorage = game:GetService("ReplicatedStorage"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    HttpService = game:GetService("HttpService"),
    StarterGui = game:GetService("StarterGui"),
    CoreGui = game:GetService("CoreGui"),
    VirtualInputManager = game:GetService("VirtualInputManager"),
}
local AkaliNotif = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kinlei/Dynissimo/main/Scripts/AkaliNotif.lua"))();
local Notify = AkaliNotif.Notify;
local Players = Services.Players
local RunService = Services.RunService
local UserInputService = Services.UserInputService
local Workspace = Services.Workspace
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
-- Aimbot Config
getgenv().matcha = getgenv().matcha or {}
getgenv().matcha = {
    ToggleAimbot = false,
    ToggleAimbot1 = false,
    StickyAim = false,
    HitChance = 100,
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
    SmoothMouse = 7,
    NotifySelect = false,
    Target = nil,
    SelectedTarget = nil,
    FOVSize = 100,
    FOVFilled = false,
    FOVFilledColor = Color3.fromRGB(50, 50, 50),
    FOVOutline = false,
    FOVOutlineColor = Color3.fromRGB(255, 255, 255),
    FOVThickness = 2,
    UseFOV = false,
    targeting = false
}
local lastLockedTarget = nil
local Stats = game:GetService("Stats")
local lastNotifiedTarget = nil
local targeting = false
-- MainRemote Auto Finder
local possibleRemotes = { "MAINEVENT", "MainEvent", "Remote", "Bullets", "MainRemotes", "Packages" }
local function getMainRemote()
    if Services.ReplicatedStorage:FindFirstChild("MainEvent") then return Services.ReplicatedStorage.MainEvent end
    if Services.ReplicatedStorage:FindFirstChild("MAINEVENT") then return Services.ReplicatedStorage.MAINEVENT end
    if Services.ReplicatedStorage:FindFirstChild("Remote") then return Services.ReplicatedStorage.Remote end
    if Services.ReplicatedStorage:FindFirstChild("Bullets") then return Services.ReplicatedStorage.Bullets end
    
    local mainRemotes = Services.ReplicatedStorage:FindFirstChild("MainRemotes")
    if mainRemotes and mainRemotes:FindFirstChild("MainRemoteEvent") then return mainRemotes.MainRemoteEvent end
    
    local packages = Services.ReplicatedStorage:FindFirstChild("Packages")
    if packages then
        local knit = packages:FindFirstChild("Knit")
        if knit then
            local toolService = knit.Services:FindFirstChild("ToolService")
            if toolService and toolService.RE:FindFirstChild("UpdateAim") then
                return toolService.RE.UpdateAim
            end
        end
    end
    return nil
end
local MainRemote = getMainRemote()

-- Vars
local lockedTarget = nil
local targetLockEnabled = false
local autoSelectEnabled = false
local onlyWhenDieEnabled = false
local useFOVCircle = false
local tracerEnabled = false
local highlightEnabled = false
local shootEnabled = false
local hiddenBulletsEnabled = false

local aliveCheckEnabled = false
local wallCheckEnabled = false
local teamCheckEnabled = false
local friendCheckEnabled = false

local fovSize = 150
local fovTrans = 0.8
local fovInlineColor = Color3.fromRGB(255, 0, 0)
local fovOutlineColor = Color3.fromRGB(0, 0, 0)
local tracerColor = Color3.fromRGB(255, 0, 0)
local tracerType = "Normal"
local highlightFill = Color3.fromRGB(255, 0, 0)
local highlightOutline = Color3.fromRGB(0, 0, 0)
local targetPartName = "Head"

-- Drawing + Highlight
local fovCircle = Drawing.new("Circle")
fovCircle.Thickness = 1
fovCircle.NumSides = 60
fovCircle.Filled = false
fovCircle.Radius = fovSize
fovCircle.Color = fovInlineColor
fovCircle.Transparency = fovTrans

local fovOutline = Drawing.new("Circle")
fovOutline.Thickness = 3
fovOutline.NumSides = 60
fovOutline.Filled = false
fovOutline.Radius = fovSize
fovOutline.Color = fovOutlineColor
fovOutline.Transparency = fovTrans

local tracerLine = Drawing.new("Line")
tracerLine.Thickness = 2
tracerLine.Color = tracerColor

local targetHighlight = nil

-- Clean khi player leave/die
local function clearTarget()
    lockedTarget = nil
    if targetHighlight then targetHighlight:Destroy() targetHighlight = nil end
    tracerLine.Visible = false
end

Players.PlayerRemoving:Connect(function(plr)
    if plr == lockedTarget then clearTarget() end
end)

-- Validate + Render
RunService.RenderStepped:Connect(function()
    if not lockedTarget or not lockedTarget.Character or not lockedTarget.Character:FindFirstChild("HumanoidRootPart") or lockedTarget.Character.Humanoid.Health <= 0 then
        clearTarget()
    end

    -- FOV
    local mousePos = UserInputService:GetMouseLocation()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local fovPos = UserInputService.TouchEnabled and center or mousePos

    if targetLockEnabled and useFOVCircle then
        fovCircle.Position = fovPos
        fovCircle.Radius = fovSize
        fovCircle.Color = fovInlineColor
        fovCircle.Transparency = fovTrans
        fovCircle.Visible = true

        fovOutline.Position = fovPos
        fovOutline.Radius = fovSize
        fovOutline.Color = fovOutlineColor
        fovOutline.Transparency = fovTrans
        fovOutline.Visible = true
    else
        fovCircle.Visible = false
        fovOutline.Visible = false
    end

    -- Tracer + Highlight
    if lockedTarget and tracerEnabled then
        local hrp = lockedTarget.Character.HumanoidRootPart
        local screen, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if onScreen then
            local toPos
            if tracerType == "Normal" then
                toPos = UserInputService.TouchEnabled and center or mousePos
            else
                local myHrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myHrp then
                    local myScreen = Camera:WorldToViewportPoint(myHrp.Position)
                    toPos = Vector2.new(myScreen.X, myScreen.Y)
                end
            end
            if toPos then
                tracerLine.From = Vector2.new(screen.X, screen.Y)
                tracerLine.To = toPos
                tracerLine.Color = tracerColor
                tracerLine.Visible = true
            end
        else
            tracerLine.Visible = false
        end
    else
        tracerLine.Visible = false
    end

    if lockedTarget and highlightEnabled then
        if not targetHighlight or not targetHighlight.Parent then
            targetHighlight = Instance.new("Highlight")
            targetHighlight.Adornee = lockedTarget.Character
            targetHighlight.Parent = lockedTarget.Character
            targetHighlight.FillColor = highlightFill
            targetHighlight.OutlineColor = highlightOutline
            targetHighlight.FillTransparency = 0.4
            targetHighlight.OutlineTransparency = 0
        end
    elseif targetHighlight then
        targetHighlight:Destroy()
        targetHighlight = nil
    end
end)
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
local function canSeeTarget(target, partName)
    if not target or not target.Character or not target.Character:FindFirstChild(partName) then return false end
    local camera = Camera
    local targetPart = target.Character[partName]
    local rayOrigin = camera.CFrame.Position
    local rayDirection = (targetPart.Position - rayOrigin).Unit * 10000
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true
    local raycastResult = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    return raycastResult == nil or (raycastResult.Instance and raycastResult.Instance:IsDescendantOf(target.Character))
end

local function GetClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = getgenv().matcha.UseFOV and getgenv().matcha.FOVSize or math.huge
    local mousePos = UserInputService:GetMouseLocation()
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
                            if table.find(getgenv().matcha.CheckSelect, "Check Wall") and not canSeeTarget(player, "HumanoidRootPart") then valid = false end
                            if table.find(getgenv().matcha.CheckSelect, "Check Alive") and not isAlive(player) then valid = false end
                            if table.find(getgenv().matcha.CheckSelect, "Check Team") and player.Team == LocalPlayer.Team then valid = false end
                            if table.find(getgenv().matcha.CheckSelect, "Check Friend") then valid = false end

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
                Notify({
                    Title = "Matcha | Best",
                    Description = "Selected Target: " .. getgenv().matcha.Target.DisplayName .. " (@" .. getgenv().matcha.Target.Name .. ")",
                    Duration = 3
                })
                lastNotifiedTarget = getgenv().matcha.Target
            end
        else
            targeting = false
        end
    else
        getgenv().matcha.Target = nil
        getgenv().matcha.SelectedTarget = nil
        lastNotifiedTarget = nil
    end
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

-- Prediction Tables
local Blatant = {{50, 0.12758545757236864},{60, 0.12593338424986178},{70, 0.1416310605747206},{80, 0.1441481061236737},{90, 0.14306050263254388},{100, 0.14698413210558095},{110, 0.14528324362031425},{120, 0.14556534594403},{130, 0.14614337395777216},{140, 0.14645603036905414},{150, 0.14736848095666674},{160, 0.14696985547996216},{170, 0.14718530231216217},{180, 0.1471532933015037},{190, 0.1471212842908452},{200, 0.14708927528018672},{210, 0.14705726626952823},{220, 0.14702525725886974},{230, 0.14699324824821125},{240, 0.14696123923755276},{250, 0.14692923022689427},{260, 0.14689722121623578},{270, 0.1468652122055773},{280, 0.1468332031949188},{290, 0.1468011941842603},{300, 0.1467691851736018}}
local predictionTable = {{0, 0.1332},{10, 0.1234555},{20, 0.12435},{30, 0.124123},{40, 0.12766},{50, 0.128643},{60, 0.1264236},{70, 0.12533},{80, 0.1321042},{90, 0.1421951},{100, 0.134143},{105, 0.141199},{110, 0.142199},{125, 0.15465},{130, 0.12399},{135, 0.1659921},{140, 0.1659921},{145, 0.129934},{150, 0.1652131},{155, 0.125333},{160, 0.1223333},{165, 0.1652131},{170, 0.16863},{175, 0.16312},{180, 0.1632},{185, 0.16823},{190, 0.18659},{205, 0.17782},{215, 0.16937},{225, 0.176332}}

local function updatePredictionValue()
    if not getgenv().matcha.AutoPrediction then return end
    local ping = getPing()
    local pred = 0.13

    if getgenv().matcha.AutoPredMode == "0-225" then
        for _, entry in ipairs(predictionTable) do
            if ping < entry[1] then pred = entry[2] break end
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
            if ping < entry[1] then pred = entry[2] break end
        end
    -- Thêm các mode khác tương tự...
    elseif getgenv().matcha.AutoPredMode == "matcha" then
        pred = CalculateAutoPrediction(getgenv().matcha.SelectedTarget)
    end

    getgenv().matcha.PredictionX = pred
    getgenv().matcha.PredictionY = pred
end
-- Target Checks
local function isValidTarget(plr)
    if not plr or plr == LocalPlayer or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") or plr.Character.Humanoid.Health <= 0 then return false end
    local char = plr.Character

    if aliveCheckEnabled then
        local be = char:FindFirstChild("BodyEffects")
        local ko = be and be:FindFirstChild("K.O") and be["K.O"].Value
        local grabbed = char:FindFirstChild("GRABBING_CONSTRAINT")
        if ko or grabbed then return false end
    end

    if teamCheckEnabled and plr.Team == LocalPlayer.Team then return false end
    if friendCheckEnabled and LocalPlayer:IsFriendsWith(plr.UserId) then
        return false
    end

    if wallCheckEnabled then
        local ray = Ray.new(Camera.CFrame.Position, char.HumanoidRootPart.Position - Camera.CFrame.Position)
        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {LocalPlayer.Character, Camera})
        if hit and not hit:IsDescendantOf(char) then return false end
    end

    return true
end

local function selectClosest()
    local closest = nil
    local bestDist = useFOVCircle and fovSize or 99999
    local screenCenter = UserInputService.TouchEnabled and Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2) or UserInputService:GetMouseLocation()

    for _, plr in Players:GetPlayers() do
        if isValidTarget(plr) then
            local head = plr.Character:FindFirstChild("Head") or plr.Character.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                if dist < bestDist then
                    bestDist = dist
                    closest = plr
                end
            end
        end
    end

    lockedTarget = closest
end

-- Auto Select Loop
local autoConn
local function toggleAutoSelect(state)
    autoSelectEnabled = state
    if state then
        autoConn = RunService.Heartbeat:Connect(function()
            if not autoSelectEnabled then autoConn:Disconnect() return end
            if lockedTarget and lockedTarget.Character and lockedTarget.Character.Humanoid.Health > 0 and onlyWhenDieEnabled then return end
            selectClosest()
        end)
    else
        if autoConn then autoConn:Disconnect() end
        lockedTarget = nil
    end
end

local shootConn
local function toggleShoot(state)
    shootEnabled = state
    if state then
        shootConn = RunService.Heartbeat:Connect(function()
            if not shootEnabled or not lockedTarget or not MainRemote then return end
           
            if not isAlive(lockedTarget) then return end
            if not isValidTarget(lockedTarget) then return end
            
            local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
            local handle = tool and tool:FindFirstChild("Handle")
            if not handle then return end
            
            local tPart = lockedTarget.Character:FindFirstChild(targetPartName)
            if not tPart then return end
            
            -- AUTO PREDICTION: Pos + Velocity * 0.3s (Da Hood bullet time exact)
            local velocity = tPart.AssemblyLinearVelocity
            local predictedPos = tPart.Position + (velocity * 0.3)
            
            local fromPos = handle.Position
            local toPos = predictedPos
            
            if hiddenBulletsEnabled then
                fromPos = fromPos - Vector3.new(0, 10, 0)
                toPos = predictedPos - Vector3.new(0, 10, 0)
            end
            
            MainRemote:FireServer("ShootGun", handle, fromPos, toPos, tPart, Vector3.new(0, 0, -1))
        end)
    else
        if shootConn then shootConn:Disconnect() end
    end
end
-- UI
local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Kazamatcha/library/refs/heads/main/mithi"))()

local window = library:window({name = "Matcha", suffix = ".lol"})
window:seperator({name = "Main"})

local rageTab, legitTab = window:tab({name = "Main", tabs = {"Rage", "Legit"}})

local page = rageTab:sub_tab({size = 25}) 

-- LEFT COLUMN
local leftCol = page:column({})
local aimSec = leftCol:section({name = "Target System", default = true})

local targetLockT = aimSec:toggle({name = "Target Lock", seperator = true, callback = function(v) targetLockEnabled = v if not v then clearTarget() end end})
local ts = targetLockT:settings({})
ts:toggle({name = "Check Alive", callback = function(v) aliveCheckEnabled = v end})
ts:toggle({name = "Check Wall", callback = function(v) wallCheckEnabled = v end})
ts:toggle({name = "Check Team", callback = function(v) teamCheckEnabled = v end})
ts:toggle({name = "Check Friend", callback = function(v) friendCheckEnabled = v end})
ts:keybind({name = "Lock Key", callback = function()
    if not targetLockEnabled then return end
    if lockedTarget then lockedTarget = nil else selectClosest() end
end})

local autoT = aimSec:toggle({name = "Auto Select", seperator = true, callback = toggleAutoSelect})
local autoS = autoT:settings({})
autoS:toggle({name = "Only When Current Dies", callback = function(v) onlyWhenDieEnabled = v end})

local fovT = aimSec:toggle({name = "FOV Circle", seperator = true, callback = function(v) useFOVCircle = v end})
local fovS = fovT:settings({})
fovS:colorpicker({name = "Inline", callback = function(c) fovInlineColor = c end})
fovS:colorpicker({name = "Outline", callback = function(c) fovOutlineColor = c end})
fovS:slider({name = "Size", min = 10, max = 800, default = 150, callback = function(v) fovSize = v end})
fovS:slider({name = "Transparency", min = 0, max = 1, interval = 0.05, default = 0.8, callback = function(v) fovTrans = v end})

local tracerT = aimSec:toggle({name = "Tracer", seperator = true, callback = function(v) tracerEnabled = v end})
local tracerS = tracerT:settings({})
tracerS:colorpicker({name = "Color", callback = function(c) tracerColor = c end})
tracerS:dropdown({name = "Type", items = {"Normal", "HumanoidRootPart"}, default = "Normal", callback = function(v) tracerType = v end})

local hlT = aimSec:toggle({name = "Highlight", seperator = true, callback = function(v) highlightEnabled = v end})
local hlS = hlT:settings({})
hlS:colorpicker({name = "Fill", callback = function(c) highlightFill = c end})
hlS:colorpicker({name = "Outline", callback = function(c) highlightOutline = c end})

-- RIGHT COLUMN
local rightCol = page:column({})
local shootSec = rightCol:section({name = "Rage Shoot", default = true})

shootSec:dropdown({name = "Target Part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}, default = "Head", callback = function(v) targetPartName = v end})

local shootT = shootSec:toggle({name = "Shoot Target", seperator = true, callback = toggleShoot})
local shootS = shootT:settings({})
shootS:toggle({name = "Hidden Bullets", callback = function(v) hiddenBulletsEnabled = v end})
local stompEnabled = false
getgenv().lastPosition = nil

local desync_setback = Instance.new("Part")
desync_setback.Name = "Spoofer"
desync_setback.Size = Vector3.new(2, 2, 1)
desync_setback.Transparency = 1
desync_setback.Anchored = true
desync_setback.CanCollide = false
desync_setback.Parent = Services.Workspace

local function resetCamera()
    if LocalPlayer.Character and LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            Services.Workspace.CurrentCamera.CameraSubject = hum
        end
    end
end
local RapidFireEnabled = false
local originalCooldowns = {}

local utility = {}
utility.get_gun = function()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Ammo") then 
            return tool 
        end
    end
end
utility.rapid = function(tool)
    pcall(function() tool:Activate() end)
end

getgenv().is_firing = false

-- Input handling for spam activate
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local gun = utility.get_gun()
        if RapidFireEnabled and gun and not getgenv().is_firing then
            getgenv().is_firing = true
            task.spawn(function()
                while getgenv().is_firing do
                    utility.rapid(gun)
                    task.wait(0.01)
                end
            end)
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        getgenv().is_firing = false
    end
end)

-- Hook cooldown upvalues
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool and tool:FindFirstChild("GunScript") then
        for _, connection in ipairs(getconnections(tool.Activated)) do
            local func = connection.Function
            if func then
                local funcInfo = debug.getinfo(func)
                for i = 1, funcInfo.nups do
                    local c, n = debug.getupvalue(func, i)
                    if type(c) == "number" then
                        if not originalCooldowns[i] then
                            originalCooldowns[i] = c
                        end
                        debug.setupvalue(func, i, RapidFireEnabled and 0.00000000000000000001 or originalCooldowns[i])
                    end
                end
            end
        end
    end
end)
-- Auto stomp loop
local stompConn
local function toggleStomp(state)
    stompEnabled = state
    if state then
        stompConn = RunService.Heartbeat:Connect(function()
            if not stompEnabled or not lockedTarget or lockedTarget == LocalPlayer then return end
            local char = lockedTarget.Character
            if not char then return end
            local bodyEffects = char:FindFirstChild("BodyEffects")
            if not bodyEffects then return end
            local isKO = bodyEffects:FindFirstChild("K.O") and bodyEffects["K.O"].Value
            local isSDeath = bodyEffects:FindFirstChild("SDeath") and bodyEffects["SDeath"].Value
            local upperTorso = char:FindFirstChild("UpperTorso")
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end

            if isKO and not isSDeath then
                spawn(function()
                    local oldCFrame = myRoot.CFrame
                    if not getgenv().lastPosition then getgenv().lastPosition = oldCFrame end
                    local tp = upperTorso.Position + Vector3.new(0, 4, 0)
                    myRoot.CFrame = CFrame.new(tp)
                    if MainRemote then MainRemote:FireServer("Stomp") end
                    -- Desync NON-BLOCK
                    local cam = Workspace.CurrentCamera
                    cam.CameraSubject = desync_setback
                    RunService.RenderStepped:Wait()
                    desync_setback.CFrame = oldCFrame * CFrame.new(0, myRoot.Size.Y/2 + 0.5, 0)
                    myRoot.CFrame = oldCFrame
                    resetCamera()
                end)
            elseif isSDeath and getgenv().lastPosition then
                myRoot.CFrame = getgenv().lastPosition
                getgenv().lastPosition = nil
                resetCamera()
            end
        end)
    else
        if stompConn then stompConn:Disconnect() end
        if getgenv().lastPosition then
            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myRoot then myRoot.CFrame = getgenv().lastPosition end
            getgenv().lastPosition = nil
            resetCamera()
        end
    end
end

shootSec:toggle({
    name = "Auto Stomp Target",
    seperator = true,
    callback = toggleStomp
})
shootSec:toggle({
    name = "Rapid Fire",
    seperator = true,
    callback = function(v)
        RapidFireEnabled = v
        if not v and getgenv().is_firing then
            getgenv().is_firing = false
        end
    end
})
-- Silent Aim Vars
local silentAimEnabled = false
local silentPrediction = 0
local silentPreviousPrediction = 0
local silentHitPart = "Head"
local silentFOVEnabled = false
local silentFOVSize = 100
local silentFOVColor = Color3.fromRGB(255, 255, 255)
local silentOutlineColor = Color3.fromRGB(255, 0, 0)
local silentWallCheck = false
local silentTeamCheck = false
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
-- Aimbot FOV
local aimbotFovFill = Drawing.new("Circle")
aimbotFovFill.Filled = true
aimbotFovFill.Transparency = 0.5
aimbotFovFill.Color = getgenv().matcha.FOVFilledColor
aimbotFovFill.Thickness = 1
aimbotFovFill.NumSides = 100
aimbotFovFill.Visible = false

local aimbotFovOutline = Drawing.new("Circle")
aimbotFovOutline.Filled = false
aimbotFovOutline.Transparency = 1
aimbotFovOutline.Color = getgenv().matcha.FOVOutlineColor
aimbotFovOutline.Thickness = getgenv().matcha.FOVThickness
aimbotFovOutline.NumSides = 100
aimbotFovOutline.Visible = false
-- Functions
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

local function getAimPos()
    if UserInputService.TouchEnabled then
        return Vector2.new(Workspace.CurrentCamera.ViewportSize.X / 2, Workspace.CurrentCamera.ViewportSize.Y / 2)
    end
    return UserInputService:GetMouseLocation()
end

local function getClosestTarget()
    local camera = Workspace.CurrentCamera
    local aimPos = getAimPos()
    local closest, closestDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and isAlive(plr) then
            if silentTeamCheck and plr.Team == LocalPlayer.Team then continue end
            local partName = silentHitPart == "Torso" and "UpperTorso" or silentHitPart
            local targetPart = plr.Character:FindFirstChild(partName)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPos).Magnitude
                    local visible = true
                    if silentWallCheck then
                        local rayParams = RaycastParams.new()
                        rayParams.FilterType = Enum.RaycastFilterType.Exclude
                        rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                        local ray = Workspace:Raycast(camera.CFrame.Position, (targetPart.Position - camera.CFrame.Position).Unit * 1000, rayParams)
                        if ray and not ray.Instance:IsDescendantOf(plr.Character) then visible = false end
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
		local pred = silentPrediction
		local predPos = targetPart.Position + root.AssemblyLinearVelocity * pred
		if freefall and silentJumpOffset ~= 0 then predPos = predPos + Vector3.new(0, silentJumpOffset, 0) end
		if idx == "Hit" then return CFrame.new(predPos) elseif idx == "Target" then return targetPart end
	end
	return oldIndex(self, idx)
end)
setreadonly(mt, true)

-- Update loop
RunService.Heartbeat:Connect(function()
    local silentMousePos = getAimPos()
    if silentFOVEnabled then
        silentFOVCircle.Position = silentMousePos
        silentOutlineCircle.Position = silentMousePos
    end
    if not silentAimEnabled then return end
    lockedTarget = getClosestTarget()
end)

-- Triggerbot Vars
local triggerEnabled = false
local triggerFOV = 20
local triggerDelay = 0
local triggerOnlyTarget = false
local triggerChecks = { Team = false, Friend = false, KO = true, Grab = true, Wall = true, Knife = true }
local HitParts = {
    "Head", "HumanoidRootPart", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand", "LeftUpperLeg", "RightUpperLeg",
    "LeftLowerLeg", "RightLowerLeg", "LeftFoot", "RightFoot",
    "Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg"
}

-- Triggerbot Functions
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

local function isValidTriggerTarget(plr)
    if plr == LocalPlayer then return false end
    if triggerChecks.Team and plr.Team == LocalPlayer.Team then return false end
    if triggerChecks.Friend and LocalPlayer:IsFriendsWith(plr.UserId) then return false end
    if triggerChecks.KO and isKO(plr) then return false end
    local char = plr.Character
    if char then
        local grabbed = char:FindFirstChild("GRABBING_CONSTRAINT")
        if triggerChecks.Grab and grabbed then return false end
    end
    if triggerChecks.Knife and isHoldingKnife() then return false end
    return isAlive(plr)
end

local function distToCursor(part)
    local camera = Workspace.CurrentCamera
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
        Services.VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.Begin, touchPos)
        task.wait(triggerDelay)
        Services.VirtualInputManager:SendTouchEvent(0, Enum.UserInputState.End, touchPos)
    else
        if mouse1press and mouse1release then
            mouse1press()
            task.wait(triggerDelay)
            mouse1release()
        else
            local vim = Services.VirtualInputManager
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

-- Triggerbot Loop
RunService.RenderStepped:Connect(function()
    if triggerEnabled then
        local part = GetBestTargetPart()
        if part and distToCursor(part) <= triggerFOV then
            local camera = Workspace.CurrentCamera
            local origin = camera.CFrame.Position
            local direction = (part.Position - origin)
            local rayParams = RaycastParams.new()
            rayParams.FilterType = Enum.RaycastFilterType.Exclude
            rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
            local result = Workspace:Raycast(origin, direction, rayParams)
            if triggerChecks.Wall and (not result or result.Instance:IsDescendantOf(part.Parent)) then
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

local triggerandsilent = legitTab:sub_tab({size = 6}) 
local page2 = legitTab:sub_tab({size = 25}) 
local leftCol2 = triggerandsilent:column({})
local rightCol2 = page2:column({})
local rightColtrig = triggerandsilent:column({})
local silentSec = leftCol2:section({name = "Silent Aim", default = true})

local silentT = silentSec:toggle({name = "Silent Aim", seperator = true, callback = function(v) silentAimEnabled = v if not v then lockedTarget = nil end end})
local silentS = silentT:settings({})
silentS:keybind({name = "Toggle Key", callback = function() silentAimEnabled = not silentAimEnabled if not silentAimEnabled then lockedTarget = nil end end})
silentS:toggle({name = "Check Team", callback = function(v) silentTeamCheck = v end})
silentS:toggle({name = "Check Wall", callback = function(v) silentWallCheck = v end})
silentS:textbox({name = "Prediction", default = "0", numeric = true, callback = function(v) local num = tonumber(v) if num and num >= 0 and num <= 0.2 then silentPrediction = num end end})
silentS:dropdown({name = "Hit Part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}, default = "Head", callback = function(v) silentHitPart = v end})
silentS:toggle({name = "FOV Circle", callback = function(v) silentFOVEnabled = v silentFOVCircle.Visible = v silentOutlineCircle.Visible = v end})
silentS:colorpicker({name = "FOV Color", callback = function(c) silentFOVColor = c silentFOVCircle.Color = c end})
silentS:colorpicker({name = "Outline Color", callback = function(c) silentOutlineColor = c silentOutlineCircle.Color = c end})
silentS:slider({name = "FOV Size", min = 1, max = 1000, default = 100, callback = function(v) silentFOVSize = v silentFOVCircle.Radius = v silentOutlineCircle.Radius = v + 1 end})
silentS:textbox({name = "Jump Offset", default = "0", numeric = true, callback = function(v) silentJumpOffset = tonumber(v) or 0 end})
silentS:toggle({name = "Use Air Part", callback = function(v) useAirPart = v end})
silentS:dropdown({name = "Air Hit Part", items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso"}, default = "Head", callback = function(v) silentAirPart = v end})

local triggerSec = rightColtrig:section({name = "Triggerbot", default = true})
local triggerT = triggerSec:toggle({name = "Triggerbot", seperator = true, callback = function(v) triggerEnabled = v end})
local triggerS = triggerT:settings({})
triggerS:keybind({name = "Toggle Key", callback = function() triggerEnabled = not triggerEnabled end})
triggerS:toggle({name = "Only Target", callback = function(v) triggerOnlyTarget = v end})
triggerS:toggle({name = "Check Team", callback = function(v) triggerChecks.Team = v end})
triggerS:toggle({name = "Check Friend", callback = function(v) triggerChecks.Friend = v end})
triggerS:toggle({name = "Check KO", callback = function(v) triggerChecks.KO = v end})
triggerS:toggle({name = "Check Grab", callback = function(v) triggerChecks.Grab = v end})
triggerS:toggle({name = "Check Wall", callback = function(v) triggerChecks.Wall = v end})
triggerS:toggle({name = "Check Knife", callback = function(v) triggerChecks.Knife = v end})
triggerS:slider({name = "FOV", min = 1, max = 200, default = 20, callback = function(v) triggerFOV = v end})
triggerS:slider({name = "Delay", min = 0, max = 0.5, default = 0, interval = 0.01, callback = function(v) triggerDelay = v end})
-- ===== AIMBOT MAIN LOOP =====
RunService.RenderStepped:Connect(function()
    updatePredictionValue()
    if not ToggleAimbot1 then return end 

    local mousePos = UserInputService:GetMouseLocation()
    local centerPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local fovPosition = mousePos

    if getgenv().matcha.SortType == "near mouse" then
        fovPosition = mousePos
    elseif getgenv().matcha.SortType == "near center" then
        fovPosition = centerPos
    elseif getgenv().matcha.SortType == "near character" then
        fovPosition = UserInputService.TouchEnabled and centerPos or mousePos
    end

    -- Update FOV
    aimbotFovFill.Position = fovPosition
    aimbotFovFill.Radius = getgenv().matcha.FOVSize
    aimbotFovFill.Visible = getgenv().matcha.FOVFilled
    aimbotFovFill.Color = getgenv().matcha.FOVFilledColor

    aimbotFovOutline.Position = fovPosition
    aimbotFovOutline.Radius = getgenv().matcha.FOVSize
    aimbotFovOutline.Visible = getgenv().matcha.FOVOutline
    aimbotFovOutline.Color = getgenv().matcha.FOVOutlineColor
    aimbotFovOutline.Thickness = getgenv().matcha.FOVThickness

    -- Update Target (NON-STICKY)
    if not getgenv().matcha.StickyAim then
        getgenv().matcha.Target = GetClosestPlayer()
        getgenv().matcha.SelectedTarget = getgenv().matcha.Target
    end

    local target = getgenv().matcha.SelectedTarget
    if not target or not targeting or not getgenv().matcha.ToggleAimbot then return end

    local hitPartName = getgenv().matcha.HitPart == "Torso (R6)" and "Torso" or getgenv().matcha.HitPart
    local targetPart = target.Character:FindFirstChild(hitPartName) or target.Character.HumanoidRootPart

    -- Closest Part
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

    -- Air Part
    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    local inFreefall = targetHum and targetHum:GetState() == Enum.HumanoidStateType.Freefall
    if getgenv().matcha.AirPartEnabled and inFreefall then
        local airPartName = getgenv().matcha.AirPart == "Torso (R6)" and "Torso" or getgenv().matcha.AirPart
        targetPart = target.Character:FindFirstChild(airPartName) or targetPart
    end

    -- Prediction + Resolver
    local velocity = targetPart.AssemblyLinearVelocity
    if getgenv().matcha.Resolver then
        local humanoid = targetPart.Parent:FindFirstChild("Humanoid")
        local hrp = target.Character:FindFirstChild("HumanoidRootPart")
        if getgenv().matcha.ResolverMethod == "move direction" and humanoid then
            velocity = humanoid.MoveDirection * humanoid.WalkSpeed
        elseif getgenv().matcha.ResolverMethod == "lookvector" then
            velocity = targetPart.CFrame.LookVector * getgenv().matcha.PredictionX * 100
        end
    end

    local predictionOffset = velocity * getgenv().matcha.PredictionX
    local basePosition = targetPart.Position + Vector3.new(0, inFreefall and getgenv().matcha.JumpOffset or getgenv().matcha.Offset, 0)
    local aimPosition = basePosition + predictionOffset

    if not ToggleAimbot then return end 
    if getgenv().matcha.AimMethod == "camera" then
        local goalCFrame = CFrame.new(Camera.CFrame.Position, aimPosition)
        if getgenv().matcha.SmoothingEnabled then
            Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, getgenv().matcha.Smooth)
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
end)
-- Aimbot Section (Right Column)
local aimbotSec = rightCol2:section({name = "Aimbot", default = true})

local aimbotT = aimbotSec:toggle({name = "Aimbot", seperator = true, callback = function(v) getgenv().matcha.ToggleAimbot1 = v end})
local aimS = aimbotT:settings({})

aimS:keybind({
    name = "Target Key",
    callback = function(v)
        local m = getgenv().matcha
        
        -- Nếu Aimbot1 bật và StickyAim tắt => chỉ set giá trị ToggleAimbot1
        if m.ToggleAimbot1 and not m.StickyAim then
            m.ToggleAimbot = v

        -- Nếu Aimbot1 bật và StickyAim cũng bật => gọi toggleTarget
        elseif m.ToggleAimbot1 and m.StickyAim then
            toggleTarget()
        end
    end
})
aimS:toggle({name = "Sticky Aim", callback = function(v) getgenv().matcha.StickyAim = v end})
aimS:toggle({name = "Notify Select Target", callback = function(v) getgenv().matcha.NotifySelect = v end})

aimS:dropdown({name = "Aimbot Method", items = {"camera", "mouse"}, default = "camera", callback = function(v) getgenv().matcha.AimMethod = v end})
aimS:dropdown({name = "Sort Type", items = {"near mouse", "near center", "near character"}, default = "near mouse", callback = function(v) getgenv().matcha.SortType = v end})

aimS:dropdown({name = "Check Select", items = {"Check Wall", "Check Alive", "Check Team", "Check Friend"}, multi = true, default = {}, callback = function(v) getgenv().matcha.CheckSelect = v end})

aimS:toggle({name = "Aim Distance Check", callback = function(v) getgenv().matcha.AimDistanceCheck = v end})
aimS:slider({name = "Aim Distance", min = 1, max = 1000, default = 250, callback = function(v) getgenv().matcha.AimDistance = v end})

aimS:toggle({name = "Health Check", callback = function(v) getgenv().matcha.HealthCheck = v end})
aimS:slider({name = "Health Threshold", min = 1, max = 100, default = 50, callback = function(v) getgenv().matcha.HealthThreshold = v end})
-- === CÁC CÀI ĐẶT NÂNG CAO (KHÔNG VÀO SETTINGS) ===
aimbotSec:toggle({
    name = "Resolver",
    callback = function(v) getgenv().matcha.Resolver = v end
})
aimbotSec:dropdown({
    name = "Resolver Method",
    items = {"move direction", "lookvector", "combined"},
    default = "move direction",
    callback = function(v) getgenv().matcha.ResolverMethod = v end
})

aimbotSec:toggle({
    name = "Auto Prediction",
    callback = function(v) getgenv().matcha.AutoPrediction = v end
})
aimbotSec:dropdown({
    name = "Auto Pred Mode",
    items = {"0-225", "Calculation", "AdvanceCalculation", "Blatant", "50-290", "10-190", "10-1000", "5-500", "drax", "110-140", "matcha"},
    default = "0-225",
    callback = function(v) getgenv().matcha.AutoPredMode = v end
})

aimbotSec:textbox({
    name = "Prediction X",
    default = "0.13",
    numeric = true,
    callback = function(v)
        local num = tonumber(v)
        if num and num >= 0 and num <= 1 then
            getgenv().matcha.PredictionX = num
        end
    end
})

aimbotSec:textbox({
    name = "Prediction Y",
    default = "0.13",
    numeric = true,
    callback = function(v)
        local num = tonumber(v)
        if num and num >= 0 and num <= 1 then
            getgenv().matcha.PredictionY = num
        end
    end
})

aimbotSec:dropdown({
    name = "Hit Part",
    items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso (R6)"},
    default = "Head",
    callback = function(v) getgenv().matcha.HitPart = v end
})

aimbotSec:toggle({name = "Closest Part", callback = function(v) getgenv().matcha.ClosestPart = v end})

aimbotSec:textbox({name = "Offset", default = "0", numeric = true, callback = function(v) getgenv().matcha.Offset = tonumber(v) or 0 end})
aimbotSec:textbox({name = "Jump Offset", default = "0", numeric = true, callback = function(v) getgenv().matcha.JumpOffset = tonumber(v) or 0 end})

aimbotSec:toggle({name = "Air Part Enabled", callback = function(v) getgenv().matcha.AirPartEnabled = v end})
aimbotSec:dropdown({
    name = "Air Part",
    items = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso (R6)"},
    default = "Head",
    callback = function(v) getgenv().matcha.AirPart = v end
})

aimbotSec:toggle({name = "Smoothing", default = true, callback = function(v) getgenv().matcha.SmoothingEnabled = v end})
aimbotSec:slider({name = "Smooth", min = 0, max = 1, default = 0.5, decimals = 0.01, callback = function(v) getgenv().matcha.Smooth = v end})
aimbotSec:slider({name = "Smooth Mouse", min = 1, max = 20, default = 7, callback = function(v) getgenv().matcha.SmoothMouse = v end})
aimbotSec:dropdown({
    name = "Smooth Method",
    items = {"Linear", "Exponential", "Sine", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Back", "Cubic"},
    default = "Linear",
    callback = function(v) getgenv().matcha.SmoothMethod = v end
})

-- FOV Settings
aimbotSec:toggle({name = "FOV Filled", callback = function(v) getgenv().matcha.FOVFilled = v end})
aimbotSec:colorpicker({name = "FOV Filled Color", callback = function(c) getgenv().matcha.FOVFilledColor = c end})
aimbotSec:toggle({name = "FOV Outline", callback = function(v) getgenv().matcha.FOVOutline = v end})
aimbotSec:colorpicker({name = "FOV Outline Color", callback = function(c) getgenv().matcha.FOVOutlineColor = c end})
aimbotSec:slider({name = "FOV Size", min = 10, max = 800, default = 100, callback = function(v) getgenv().matcha.FOVSize = v end})
aimbotSec:slider({name = "FOV Thickness", min = 1, max = 5, default = 2, callback = function(v) getgenv().matcha.FOVThickness = v end})
library:init_config(window)
Notify({
Description = "Thank you for using matcha.tea";
Title = "Matcha | Best";
Duration = 5;
});
