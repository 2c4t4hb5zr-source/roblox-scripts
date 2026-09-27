local function label(text, y, height)
    return make("TextLabel", {
        BackgroundTransparency = 1, Position = UDim2.fromOffset(16, y),
        Size = UDim2.new(1, -32, 0, height or 24), Font = Enum.Font.Gotham,
        TextSize = 14, TextColor3 = Color3.fromRGB(226, 233, 245),
        TextXAlignment = Enum.TextXAlignment.Left, Text = text,
    }, panel)
end
local function button(text, position, size)
    local result = make("TextButton", {
        Position = position, Size = size, Text = text, Font = Enum.Font.GothamBold,
        TextSize = 13, TextColor3 = Color3.fromRGB(235, 242, 255),
        BackgroundColor3 = Color3.fromRGB(43, 56, 79), BorderSizePixel = 0,
    }, panel)
    make("UICorner", {CornerRadius = UDim.new(0, 8)}, result)
    return result
end

local heading = label("SURVIVAL HUD", 12, 28)
heading.Font = Enum.Font.GothamBold
heading.Size = UDim2.fromOffset(178, 28)
heading.Active = true
local close = button("X", UDim2.new(1, -42, 0, 12), UDim2.fromOffset(28, 28))
local health = label("Health: waiting for character", 54)
local track = make("Frame", {
    Position = UDim2.fromOffset(16, 84), Size = UDim2.new(1, -32, 0, 7),
    BackgroundColor3 = Color3.fromRGB(43, 50, 66), BorderSizePixel = 0,
}, panel)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, track)
local fill = make("Frame", {
    Size = UDim2.fromScale(0, 1), BorderSizePixel = 0,
    BackgroundColor3 = Color3.fromRGB(75, 213, 162),
}, track)
make("UICorner", {CornerRadius = UDim.new(1, 0)}, fill)
local speed = label("Movement: -- studs/s", 100)
local height = label("World height: -- studs", 128)
local timer = label("Stopwatch: 00:00.0", 164)
local start = button("Start", UDim2.fromOffset(16, 204), UDim2.fromOffset(118, 34))
local reset = button("Reset", UDim2.fromOffset(146, 204), UDim2.fromOffset(118, 34))

local connections = {}
local alive = true
local function connect(signal, callback)
    connections[#connections + 1] = signal:Connect(callback)
end
connect(gui.Destroying, function()
    alive = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
end)
connect(close.Activated, function() gui:Destroy() end)

local running = false
local elapsed = 0
local startedAt = 0
connect(start.Activated, function()
    if running then
        elapsed = elapsed + os.clock() - startedAt
    else
        startedAt = os.clock()
    end
    running = not running
    start.Text = running and "Pause" or "Start"
end)
connect(reset.Activated, function()
    elapsed = 0
    startedAt = os.clock()
end)

-- Drag only the title so clicking the controls does not move the panel.
local dragging, dragOrigin, panelOrigin, dragInput
connect(heading.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging, dragOrigin, panelOrigin, dragInput = true, input.Position, panel.Position, input
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == dragInput then dragging = false end
end)
connect(UserInputService.WindowFocusReleased, function() dragging = false end)
connect(UserInputService.InputChanged, function(input)
    if not dragging then return end
    if input ~= dragInput and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    local delta = input.Position - dragOrigin
    local viewport = gui.AbsoluteSize
    local x = panelOrigin.X.Scale * viewport.X + panelOrigin.X.Offset + delta.X
    local y = panelOrigin.Y.Scale * viewport.Y + panelOrigin.Y.Offset + delta.Y
    panel.Position = UDim2.fromOffset(
        math.clamp(x, 0, math.max(0, viewport.X - panel.AbsoluteSize.X)),
        math.clamp(y, 0, math.max(0, viewport.Y - panel.AbsoluteSize.Y))
    )
end)

local accumulated = 0
connect(RunService.Heartbeat, function(dt)
    if not alive then return end
    accumulated = accumulated + dt
    if accumulated < 0.1 then return end
    accumulated = 0
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if humanoid then
        local fraction = math.clamp(humanoid.Health / math.max(humanoid.MaxHealth, 1), 0, 1)
        health.Text = string.format("Health: %.0f / %.0f", humanoid.Health, humanoid.MaxHealth)
        fill.Size = UDim2.fromScale(fraction, 1)
        fill.BackgroundColor3 = fraction < 0.3 and Color3.fromRGB(255, 100, 112)
            or Color3.fromRGB(75, 213, 162)
    else
        health.Text = "Health: waiting for character"
        fill.Size = UDim2.fromScale(0, 1)
    end
    if root and root:IsA("BasePart") then
        local velocity = root.AssemblyLinearVelocity
        speed.Text = string.format("Movement: %.1f studs/s", Vector3.new(velocity.X, 0, velocity.Z).Magnitude)
        height.Text = string.format("World height: %.1f studs", root.Position.Y)
    else
        speed.Text, height.Text = "Movement: -- studs/s", "World height: -- studs"
    end
    local seconds = elapsed + (running and os.clock() - startedAt or 0)
    timer.Text = string.format("Stopwatch: %02d:%04.1f", math.floor(seconds / 60), seconds % 60)
end)