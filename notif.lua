--// services & shortcuts
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local insert, find, remove = table.insert, table.find, table.remove
local format = string.format

local newInstance = Instance.new
local fromRGB = Color3.fromRGB

local notificationPositions = {
    ["Middle"]      = UDim2.new(0.5, -118, 0.58, 0), -- centered + slightly down
    ["MiddleRight"] = UDim2.new(0.85, 0,   0.70, 0),
    ["MiddleLeft"]  = UDim2.new(0.01, 0,   0.70, 0),

    ["Top"]     = UDim2.new(0.445, 0, 0.007, 0),
    ["TopLeft"] = UDim2.new(0.06,  0, 0.001, 0),
    ["TopRight"]= UDim2.new(0.80,  0, 0.001, 0),
}

--// helpers
local function protectScreenGui(screenGui)
    -- supports common executors; falls back to CoreGui
    local ok, _ = pcall(function()
        if syn and syn.protect_gui then
            syn.protect_gui(screenGui)
            screenGui.Parent = CoreGui
        elseif gethui then
            screenGui.Parent = gethui()
        else
            screenGui.Parent = CoreGui
        end
    end)
    if not ok then
        screenGui.Parent = CoreGui
    end
end

local function createObject(className, properties)
    local instance = newInstance(className)
    for k, v in next, properties do
        instance[k] = v
    end
    return instance
end

local function fadeObject(object, onTweenCompleted)
    local tweenInfo = TweenService:Create(
        object,
        TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        {
            TextTransparency = 1,
            TextStrokeTransparency = 1
        }
    )
    if typeof(onTweenCompleted) == "function" then
        tweenInfo.Completed:Connect(onTweenCompleted)
    end
    tweenInfo:Play()
end

--// module
local notifications = {}

do
    function notifications.new(settings)
        assert(settings, "missing argument #1 in function notifications.new(settings)")
        assert(typeof(settings) == "table",
            format("expected table for argument #1 in function notifications.new(settings), got %s", typeof(settings))
        )

        local notificationSettings = {
            ui = {
                notificationsFrame = nil,
                notificationsFrame_UIListLayout = nil
            },
            -- sensible defaults
            NotificationPosition = "Middle",
            NotificationLifetime = 3, -- seconds
            TextColor = fromRGB(255, 255, 255),
            TextSize = 14,
            TextStrokeTransparency = 0.5,
            TextStrokeColor = fromRGB(0, 0, 0),
            TextFont = Enum.Font.GothamSemibold,
        }

        for k, v in next, settings do
            notificationSettings[k] = v
        end

        setmetatable(notificationSettings, { __index = notifications })
        return notificationSettings
    end

    function notifications:SetNotificationLifetime(number)
        assert(number, "missing argument #1 in function SetNotificationLifetime(number)")
        assert(typeof(number) == "number",
            format("expected number for argument #1 in function SetNotificationLifetime, got %s", typeof(number))
        )
        self.NotificationLifetime = number
    end

    function notifications:SetTextColor(color3)
        assert(color3, "missing argument #1 in function SetTextColor(Color3)")
        assert(typeof(color3) == "Color3",
            format("expected Color3 for argument #1 in function SetTextColor, got %s", typeof(color3))
        )
        self.TextColor = color3
    end

    function notifications:SetTextSize(number)
        assert(number, "missing argument #1 in function SetTextSize(number)")
        assert(typeof(number) == "number",
            format("expected number for argument #1 in function SetTextSize, got %s", typeof(number))
        )
        self.TextSize = number
    end

    function notifications:SetTextStrokeTransparency(number)
        assert(number, "missing argument #1 in function SetTextStrokeTransparency(number)")
        assert(typeof(number) == "number",
            format("expected number for argument #1 in function SetTextStrokeTransparency, got %s", typeof(number))
        )
        self.TextStrokeTransparency = number
    end

    function notifications:SetTextStrokeColor(color3)
        assert(color3, "missing argument #1 in function SetTextStrokeColor(Color3)")
        assert(typeof(color3) == "Color3",
            format("expected Color3 for argument #1 in function SetTextStrokeColor, got %s", typeof(color3))
        )
        self.TextStrokeColor = color3
    end

    function notifications:SetTextFont(font)
        assert(font, "missing argument #1 in function SetTextFont(Font|string)")
        if typeof(font) == "EnumItem" and font.EnumType == Enum.Font.EnumType then
            self.TextFont = font
        elseif typeof(font) == "string" then
            -- allow "Gotham", "GothamBold", etc.
            local ok, enumFont = pcall(function() return Enum.Font[font] end)
            self.TextFont = ok and enumFont or self.TextFont
        else
            error(format("expected Enum.Font or string for SetTextFont, got %s", typeof(font)))
        end
    end

    function notifications:BuildNotificationUI()
        if getgenv().notifications_screenGui then
            pcall(function() getgenv().notifications_screenGui:Destroy() end)
            getgenv().notifications_screenGui = nil
        end

        local screenGui = createObject("ScreenGui", {
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            ResetOnSpawn = false,
            Name = "notifications_screenGui"
        })
        protectScreenGui(screenGui)
        getgenv().notifications_screenGui = screenGui

        self.ui.notificationsFrame = createObject("Frame", {
            Name = "notificationsFrame",
            Parent = screenGui,
            BackgroundColor3 = fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Position = notificationPositions[self.NotificationPosition] or notificationPositions["Middle"],
            Size = UDim2.new(0, 236, 0, 215)
        })

        self.ui.notificationsFrame_UIListLayout = createObject("UIListLayout", {
            Name = "notificationsFrame_UIListLayout",
            Parent = self.ui.notificationsFrame,
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            VerticalAlignment = Enum.VerticalAlignment.Top,
            FillDirection = Enum.FillDirection.Vertical
        })
    end

    function notifications:Notify(text)
        assert(self.ui and self.ui.notificationsFrame, "Call :BuildNotificationUI() before :Notify()")
        local notification = createObject("TextLabel", {
            Name = "notification",
            Parent = self.ui.notificationsFrame,
            BackgroundColor3 = fromRGB(255, 255, 255),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 222, 0, 16),
            Text = tostring(text or ""),
            Font = self.TextFont,
            TextColor3 = self.TextColor,
            TextSize = self.TextSize,
            TextStrokeColor3 = self.TextStrokeColor,
            TextStrokeTransparency = self.TextStrokeTransparency,
            TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center,
            RichText = true, -- Enable RichText support
            TextScaled = false
        })

        task.delay(self.NotificationLifetime, function()
            if notification and notification.Parent then
                fadeObject(notification, function()
                    if notification then
                        notification:Destroy()
                    end
                end)
            end
        end)
    end
end

return notifications
