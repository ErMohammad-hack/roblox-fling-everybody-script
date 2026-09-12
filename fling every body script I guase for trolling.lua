-- so evil dude make it better uf you want 
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

local SETTINGS = {
    MIN_CONTACT_DELAY = 0.05,
}

local isTeleporting = false
local isFlinging = false
local dragEnabled = true
local dragging, dragInput, dragStart, startPos

local function startWalkFling()
    local character = LocalPlayer.Character
    if not character then return end
    
    local Root = character:FindFirstChild("HumanoidRootPart")
    local Humanoid = character:FindFirstChild("Humanoid")
    
    if not Root or not Humanoid then return end
    
    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    Humanoid.BreakJointsOnDeath = false
    
    task.spawn(function()
        while isFlinging and Humanoid do
            Humanoid.Health = math.huge
            Humanoid.MaxHealth = math.huge
            task.wait()
        end
    end)
    
    Root.CanCollide = false
    Humanoid:ChangeState(11)
    
    task.spawn(function()
        while isFlinging and Root and Root.Parent do
            RunService.Heartbeat:Wait()
            local vel = Root.Velocity
            Root.Velocity = vel * 99999999 + Vector3.new(0, 99999999, 0)
            
            RunService.RenderStepped:Wait()
            Root.Velocity = vel
            RunService.Stepped:Wait()
            Root.Velocity = vel + Vector3.new(0, 0.1, 0)
        end
        if Root then Root.CanCollide = true end
    end)
end

local function performRapidTeleport()
    local character = LocalPlayer.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    local allPlayers = Players:GetPlayers()
    for _, targetPlayer in ipairs(allPlayers) do
        if not isTeleporting then break end
        if targetPlayer ~= LocalPlayer then
            local targetChar = targetPlayer.Character
            local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")

            if targetRoot then
                rootPart.CFrame = targetRoot.CFrame
                task.wait(SETTINGS.MIN_CONTACT_DELAY)
            end
        end
    end
end

local function startTeleportLoop()
    task.spawn(function()
        while isTeleporting do
            performRapidTeleport()
            task.wait() 
        end
    end)
end

local function setupDraggable(guiObject)
    guiObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = guiObject.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    guiObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end

        if dragging and dragInput then
            local delta = input.Position - dragStart
            guiObject.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X, 
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GUI"
    screenGui.ResetOnSpawn = false 
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 180, 0, 120)
    mainFrame.Position = UDim2.new(0.5, -90, 0.5, -60)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 10)
    uiCorner.Parent = mainFrame

    local tpButton = Instance.new("TextButton")
    tpButton.Size = UDim2.new(0, 150, 0, 30)
    tpButton.Position = UDim2.new(0.5, -75, 0.2, 0)
    tpButton.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
    tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpButton.Text = "FAST TP: OFF"
    tpButton.Font = Enum.Font.GothamBold
    tpButton.TextSize = 14
    tpButton.Parent = mainFrame

    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 6)
    tpCorner.Parent = tpButton

    local flingButton = Instance.new("TextButton")
    flingButton.Size = UDim2.new(0, 150, 0, 30)
    flingButton.Position = UDim2.new(0.5, -75, 0.5, 0)
    flingButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    flingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flingButton.Text = "FLING: OFF"
    flingButton.Font = Enum.Font.GothamBold
    flingButton.TextSize = 14
    flingButton.Parent = mainFrame

    local flingCorner = Instance.new("UICorner")
    flingCorner.CornerRadius = UDim.new(0, 6)
    flingCorner.Parent = flingButton

    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Text = "-"
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = 12
    closeButton.Parent = mainFrame

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeButton

    setupDraggable(mainFrame)

    tpButton.MouseButton1Click:Connect(function()
        isTeleporting = not isTeleporting
        if isTeleporting then
            tpButton.Text = "FAST TP: ON"
            tpButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
            startTeleportLoop()
        else
            tpButton.Text = "FAST TP: OFF"
            tpButton.BackgroundColor3 = Color3.fromRGB(50, 0, 0)
        end
    end)

    flingButton.MouseButton1Click:Connect(function()
        isFlinging = not isFlinging
        if isFlinging then
            flingButton.Text = "FLING: ON"
            flingButton.BackgroundColor3 = Color3.fromRGB(150, 100, 0)
            startWalkFling()
        else
            flingButton.Text = "FLING: OFF"
            flingButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        end
    end)

    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    if isFlinging then
        task.wait(1)
        startWalkFling()
    end
end)

createUI()
