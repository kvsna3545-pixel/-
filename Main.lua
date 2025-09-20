local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local TweenService = game:GetService("TweenService")
local colors = {Color3.fromRGB(0, 170, 255), Color3.fromRGB(255, 100, 255)}
local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true)

local function applyBluePinkGlow(frame)
    if frame:FindFirstChild("GlowStroke") then return end
    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 3
    stroke.Color = colors[1]
    stroke.Parent = frame

    local tweenIndex = 1
    local function tweenColor()
        local nextIndex = tweenIndex % #colors + 1
        local tween = TweenService:Create(stroke, tweenInfo, {Color = colors[nextIndex]})
        tween:Play()
        tween.Completed:Connect(function()
            tweenIndex = nextIndex
            tweenColor()
        end)
    end
    tweenColor()
end

local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local flying = false
local noclip = false
local vertical = 0
local speedFly = 140
local speedWalk = 16
local bv

local autoJump = false

local autoTeleporting = false
local autoTeleportConnection

local selectedPlayerName = ""

-- UI --
local gui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
gui.Name = "FlyGui"
gui.ResetOnSpawn = false

local mainPage = Instance.new("Frame", gui)
mainPage.Size = UDim2.new(0, 240, 0, 620)
mainPage.Position = UDim2.new(0, 100, 0, 100)
mainPage.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
mainPage.Active = true
mainPage.Draggable = true

applyBluePinkGlow(mainPage)

-- เพิ่ม Label "Script by kvsna3545" บน UI
local titleLabel = Instance.new("TextLabel", mainPage)
titleLabel.Size = UDim2.new(1, 0, 0, 30)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 30
titleLabel.Text = "Script by kvsna3545"
titleLabel.BorderSizePixel = 0

local function createBtn(text, parent, y, color)
	local btn = Instance.new("TextButton", parent)
	btn.Size = UDim2.new(1, 0, 0, 40)
	btn.Position = UDim2.new(0, 0, 0, y)
	btn.Text = text
	btn.BackgroundColor3 = color
	btn.TextColor3 = Color3.new(1,1,1)
	btn.Font = Enum.Font.Gotham
	btn.TextSize = 18
	return btn
end

local flyBtn = createBtn("เปิดบิน", mainPage, 30, Color3.fromRGB(0, 170, 255))
local upBtn = createBtn("ขึ้น (กดค้าง)", mainPage, 80, Color3.fromRGB(100, 200, 100))
local downBtn = createBtn("ลง (กดค้าง)", mainPage, 130, Color3.fromRGB(200, 100, 100))
local noclipBtn = createBtn("เปิดทะลุ 100%", mainPage, 180, Color3.fromRGB(160, 120, 250))
local autoJumpBtn = createBtn("เปิด Auto Jump", mainPage, 230, Color3.fromRGB(255, 100, 180))

local teleportLabel = Instance.new("TextLabel", mainPage)
teleportLabel.Size = UDim2.new(1, 0, 0, 30)
teleportLabel.Position = UDim2.new(0, 0, 0, 280)
teleportLabel.Text = "วาร์ปผู้เล่น:"
teleportLabel.BackgroundTransparency = 1
teleportLabel.TextColor3 = Color3.fromRGB(255,255,255)
teleportLabel.Font = Enum.Font.Gotham
teleportLabel.TextSize = 18

local dropdown = Instance.new("TextButton", mainPage)
dropdown.Size = UDim2.new(1, -40, 0, 40)
dropdown.Position = UDim2.new(0, 0, 0, 320)
dropdown.Text = "เลือกผู้เล่น"
dropdown.Font = Enum.Font.Gotham
dropdown.TextSize = 18
dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
dropdown.AutoButtonColor = true

-- ฟังก์ชันลาก UI (รองรับมือถือและเมาส์)
local function makeDraggable(frame)
    local dragging = false
    local dragStartPos
    local frameStartPos

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or
           input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStartPos = input.Position
            frameStartPos = frame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    frame.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStartPos
            local newX = frameStartPos.X.Offset + delta.X
            local newY = frameStartPos.Y.Offset + delta.Y

            -- กำหนดให้ตำแหน่งไม่เกินขอบจอ (อันนี้ปรับได้ตามต้องการ)
            if newX < 0 then newX = 0 end
            if newY < 0 then newY = 0 end
            if newX > workspace.CurrentCamera.ViewportSize.X - frame.AbsoluteSize.X then
                newX = workspace.CurrentCamera.ViewportSize.X - frame.AbsoluteSize.X
            end
            if newY > workspace.CurrentCamera.ViewportSize.Y - frame.AbsoluteSize.Y then
                newY = workspace.CurrentCamera.ViewportSize.Y - frame.AbsoluteSize.Y
            end

            frame.Position = UDim2.new(0, newX, 0, newY)
        end
    end)
end

-- สร้าง UI
local function createUI()
    if ScreenGui then ScreenGui:Destroy() end

    ScreenGui = Instance.new("ScreenGui")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = player:WaitForChild("PlayerGui")

    -- หน้าต่างหลัก (เปิด)
    mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 200, 0, 100)
    mainFrame.Position = UDim2.new(0.5, -100, 0.8, -50)
    mainFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    mainFrame.Active = true
    mainFrame.Parent = ScreenGui

    local titleLabel = Instance.new("TextLabel", mainFrame)
    titleLabel.Size = UDim2.new(1, 0, 0.4, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "Auto Jump"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 22

    local toggleBtn = Instance.new("TextButton", mainFrame)
    toggleBtn.Size = UDim2.new(1, 0, 0.6, 0)
    toggleBtn.Position = UDim2.new(0, 0, 0.4, 0)
    toggleBtn.Text = autoJump and "ON" or "OFF"
    toggleBtn.BackgroundColor3 = autoJump and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleBtn.Font = Enum.Font.SourceSansBold
    toggleBtn.TextSize = 20

    toggleBtn.MouseButton1Click:Connect(function()
        autoJump = not autoJump
        toggleBtn.Text = autoJump and "ON" or "OFF"
        toggleBtn.BackgroundColor3 = autoJump and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
    end)

    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0.2, 0, 0.4, 0)
    closeBtn.Position = UDim2.new(0.8, 0, 0, 0)
    closeBtn.Text = "X"
    closeBtn.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.TextSize = 18

    closeBtn.MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        miniFrame.Visible = true
        miniFrame.Position = mainFrame.Position
    end)

    makeDraggable(mainFrame)

    -- กล่องเล็กตอนปิด
    miniFrame = Instance.new("Frame")
    miniFrame.Size = UDim2.new(0, 50, 0, 50)
    miniFrame.Position = UDim2.new(0.5, -25, 0.8, -50)
    miniFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    miniFrame.Active = true
    miniFrame.Visible = false
    miniFrame.Parent = ScreenGui

    local miniBtn = Instance.new("TextButton", miniFrame)
    miniBtn.Size = UDim2.new(1, 0, 1, 0)
    miniBtn.Text = "+"
    miniBtn.BackgroundTransparency = 1

    miniBtn.MouseButton1Click:Connect(function()
        miniFrame.Visible = false
        mainFrame.Visible = true
        mainFrame.Position = miniFrame.Position
    end)

    makeDraggable(miniFrame)
end

-- ระบบ Auto Jump (มือถือ)
RunService.Heartbeat:Connect(function()
    if autoJump and player.Character then
        local hum = player.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- จับเหตุการณ์รีสปอน
player.CharacterAdded:Connect(function(char)
    humanoid = char:WaitForChild("Humanoid")
    createUI()
end)

-- เริ่มตอนแรก
humanoid = (player.Character or player.CharacterAdded:Wait()):WaitForChild("Humanoid")
createUI()

local dropdownList = Instance.new("ScrollingFrame", mainPage)
dropdownList.Size = UDim2.new(1, -40, 0, 140)
dropdownList.Position = UDim2.new(0, 0, 0, 365)
dropdownList.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
dropdownList.BorderSizePixel = 1
dropdownList.Visible = false
dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
dropdownList.ScrollBarThickness = 6

local UIListLayout = Instance.new("UIListLayout", dropdownList)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 2)

local teleportBtn = createBtn("วาร์ปไป", mainPage, 510, Color3.fromRGB(80, 150, 255))
local toggleAutoTeleportBtn = createBtn("▶ เริ่มวาร์ปรัวๆ", mainPage, 560, Color3.fromRGB(100, 255, 100))

local speedLabel = Instance.new("TextLabel", mainPage)
speedLabel.Size = UDim2.new(1, 0, 0, 30)
speedLabel.Position = UDim2.new(0, 0, 0, 610)
speedLabel.Text = "เดินเร็ว: " .. speedWalk .. "  |  บินเร็ว: " .. speedFly
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.fromRGB(255,255,255)
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextSize = 16

local flySpeedBox = Instance.new("TextBox", mainPage)
flySpeedBox.Size = UDim2.new(1, -80, 0, 30)
flySpeedBox.Position = UDim2.new(0, 0, 0, 645)
flySpeedBox.PlaceholderText = "ตั้งค่าความเร็วบิน"
flySpeedBox.Text = tostring(speedFly)
flySpeedBox.Font = Enum.Font.Gotham
flySpeedBox.TextSize = 16
flySpeedBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
flySpeedBox.TextColor3 = Color3.fromRGB(0, 0, 0)

local flySetBtn = Instance.new("TextButton", mainPage)
flySetBtn.Size = UDim2.new(0, 80, 0, 30)
flySetBtn.Position = UDim2.new(1, -80, 0, 645)
flySetBtn.Text = "ตั้งค่า"
flySetBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
flySetBtn.TextColor3 = Color3.new(1,1,1)
flySetBtn.Font = Enum.Font.Gotham
flySetBtn.TextSize = 18

local walkSpeedBox = Instance.new("TextBox", mainPage)
walkSpeedBox.Size = UDim2.new(1, -80, 0, 30)
walkSpeedBox.Position = UDim2.new(0, 0, 0, 685)
walkSpeedBox.PlaceholderText = "ตั้งค่าความเร็วเดิน"
walkSpeedBox.Text = tostring(speedWalk)
walkSpeedBox.Font = Enum.Font.Gotham
walkSpeedBox.TextSize = 16
walkSpeedBox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
walkSpeedBox.TextColor3 = Color3.fromRGB(0, 0, 0)

local walkSetBtn = Instance.new("TextButton", mainPage)
walkSetBtn.Size = UDim2.new(0, 80, 0, 30)
walkSetBtn.Position = UDim2.new(1, -80, 0, 685)
walkSetBtn.Text = "ตั้งค่า"
walkSetBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
walkSetBtn.TextColor3 = Color3.new(1,1,1)
walkSetBtn.Font = Enum.Font.Gotham
walkSetBtn.TextSize = 18

local closeBtn = createBtn("ปิด UI", mainPage, -60, Color3.fromRGB(170, 50, 5))

-- ฟังก์ชันอัพเดตรายชื่อผู้เล่นใน dropdown
local function updateDropdownList()
	-- ลบของเก่า
	for _, child in pairs(dropdownList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local players = Players:GetPlayers()
	for _, p in ipairs(players) do
		if p ~= player then
			local btn = Instance.new("TextButton", dropdownList)
			btn.Size = UDim2.new(1, 0, 0, 30)
			btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			btn.TextColor3 = Color3.fromRGB(0, 0, 0)
			btn.Font = Enum.Font.Gotham
			btn.TextSize = 16
			btn.Text = p.Name

			btn.MouseButton1Click:Connect(function()
				selectedPlayerName = p.Name
				dropdown.Text = selectedPlayerName
				dropdownList.Visible = false
			end)
		end
	end

	local randomBtn = Instance.new("TextButton", dropdownList)
	randomBtn.Size = UDim2.new(1, 0, 0, 30)
	randomBtn.BackgroundColor3 = Color3.fromRGB(200, 200, 255)
	randomBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	randomBtn.Font = Enum.Font.Gotham
	randomBtn.TextSize = 16
	randomBtn.Text = "สุ่ม"

	randomBtn.MouseButton1Click:Connect(function()
		selectedPlayerName = "สุ่ม"
		dropdown.Text = "สุ่ม"
		dropdownList.Visible = false
	end)

	local listCount = #Players:GetPlayers() - 1 + 1
	dropdownList.CanvasSize = UDim2.new(0, 0, 0, listCount * 32)
end

dropdown.MouseButton1Click:Connect(function()
	dropdownList.Visible = not dropdownList.Visible
	if dropdownList.Visible then
		updateDropdownList()
	end
end)

-- ฟังก์ันวาร์ป
local function teleportTo(targetName)
	if targetName:lower() == "สุ่ม" then
		local candidates = {}
		for _, p in pairs(Players:GetPlayers()) do
			if p ~= player and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
				table.insert(candidates, p)
			end
		end
		if #candidates == 0 then return end
		local randomPlayer = candidates[math.random(1, #candidates)]
		local targetRoot = randomPlayer.Character.HumanoidRootPart
		root.CFrame = targetRoot.CFrame
	else
		for _, targetPlayer in pairs(Players:GetPlayers()) do
			if targetPlayer.Name:lower():sub(1, #targetName) == targetName:lower() and targetPlayer ~= player then
				local targetChar = targetPlayer.Character
				if targetChar and targetChar:FindFirstChild("HumanoidRootPart") then
					local targetRoot = targetChar.HumanoidRootPart
					root.CFrame = targetRoot.CFrame
				end
				break
			end
		end
	end
end

teleportBtn.MouseButton1Click:Connect(function()
	if selectedPlayerName == "" then
		dropdown.Text = "เลือกผู้เล่น"
		return
	end
	teleportTo(selectedPlayerName)
end)

toggleAutoTeleportBtn.MouseButton1Click:Connect(function()
	if not autoTeleporting then
		if selectedPlayerName == "" then
			dropdown.Text = "เลือกผู้เล่น"
			return
		end

		autoTeleporting = true
		toggleAutoTeleportBtn.Text = "■ หยุดวาร์ปรัวๆ"
		autoTeleportConnection = RunService.Heartbeat:Connect(function()
			teleportTo(selectedPlayerName)
		end)
	else
		autoTeleporting = false
		toggleAutoTeleportBtn.Text = "▶ เริ่มวาร์ปรัวๆ"
		if autoTeleportConnection then
			autoTeleportConnection:Disconnect()
			autoTeleportConnection = nil
		end
	end
end)

-- ปุ่มอื่นๆ
flyBtn.MouseButton1Click:Connect(function()
	flying = not flying
	if flying then
		humanoid.PlatformStand = true
		if not bv or not bv.Parent then
			bv = Instance.new("BodyVelocity")
			bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
			bv.Velocity = Vector3.new(0, 0, 0)
			bv.Parent = root
		end
		flyBtn.Text = "off บิน"
	else
		humanoid.PlatformStand = false
		if bv and bv.Parent then
			bv:Destroy()
			bv = nil
		end
		vertical = 0
		flyBtn.Text = "Enable บิน"
	end
end)

upBtn.MouseButton1Down:Connect(function() vertical = 1 end)
upBtn.MouseButton1Up:Connect(function() vertical = 0 end)
downBtn.MouseButton1Down:Connect(function() vertical = -1 end)
downBtn.MouseButton1Up:Connect(function() vertical = 0 end)

noclipBtn.MouseButton1Click:Connect(function()
	noclip = not noclip
	noclipBtn.Text = noclip and "off ทะลุ 100%" or "Enable เปิดทะลุ 100%"
end)

autoJumpBtn.MouseButton1Click:Connect(function()
	autoJump = not autoJump
	if autoJump then
		autoJumpBtn.Text = "off Auto Jump"
		autoJumpBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	else
		autoJumpBtn.Text = "Enable Auto Jump"
		autoJumpBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 180)
	end
end)

flySetBtn.MouseButton1Click:Connect(function()
	local num = tonumber(flySpeedBox.Text)
	if num and num > 0 then
		speedFly = num
		flySpeedBox.Text = tostring(speedFly)
		speedLabel.Text = "เดินเร็ว: " .. speedWalk .. "  |  บินเร็ว: " .. speedFly
	else
		flySpeedBox.Text = "ใส่เลข"
	end
end)

walkSetBtn.MouseButton1Click:Connect(function()
	local num = tonumber(walkSpeedBox.Text)
	if num and num > 0 then
		speedWalk = num
		if humanoid then
			humanoid.WalkSpeed = speedWalk
		end
		walkSpeedBox.Text = tostring(speedWalk)
		speedLabel.Text = "เดินเร็ว: " .. speedWalk .. "  |  บินเร็ว: " .. speedFly
	else
		walkSpeedBox.Text = "ใส่เลข"
	end
end)

local function noclipOn()
	for _, part in pairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CanCollide = false
		end
	end
end

player.CharacterAdded:Connect(function(c)
	char = c
	humanoid = char:WaitForChild("Humanoid")
	root = char:WaitForChild("HumanoidRootPart")
	humanoid.WalkSpeed = speedWalk
end)

RunService.Stepped:Connect(function()
	if flying and bv and root then
		local move = humanoid.MoveDirection * speedFly
		local y = vertical * speedFly
		bv.Velocity = Vector3.new(move.X, y, move.Z)
	end

	if noclip then
		noclipOn()
	end
end)

RunService.Heartbeat:Connect(function()
	if autoJump and humanoid and humanoid.Health > 0 then
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end
end)

local openUIPosition = UDim2.new(0, 10, 0, 10) -- เก็บตำแหน่งปุ่มเล็ก

closeBtn.MouseButton1Click:Connect(function()
	if mainPage.Visible then
		mainPage.Visible = false
		-- สร้างปุ่มเล็กเพื่อเปิด UI
		if not gui:FindFirstChild("OpenUIButton") then
			local openUI = Instance.new("TextButton", gui)
			openUI.Name = "Open UI"
			openUI.Size = UDim2.new(0, 50, 0, 50)
			openUI.Position = openUIPosition -- ใช้ตำแหน่งที่เก็บไว้
			openUI.Text = "+"
			openUI.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
			openUI.TextColor3 = Color3.new(1,1,1)
			openUI.Font = Enum.Font.Gotham
			openUI.TextSize = 36
			openUI.AutoButtonColor = true

			openUI.MouseButton1Click:Connect(function()
				mainPage.Visible = true
				openUI:Destroy()
			end)

			-- ทำให้ปุ่มเปิด UI ลากได้ และอัพเดตตำแหน่ง
			local dragging = false
			local dragStartPos
			local startPos

			openUI.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or
				   input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStartPos = input.Position
					startPos = openUI.Position

					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
							openUIPosition = openUI.Position -- อัพเดตตำแหน่งตอนลากเสร็จ
						end
					end)
				end
			end)

			openUI.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local delta = input.Position - dragStartPos
					local newX = startPos.X.Offset + delta.X
					local newY = startPos.Y.Offset + delta.Y

					-- กำหนดให้ไม่ออกนอกจอ
					local maxX = workspace.CurrentCamera.ViewportSize.X - openUI.AbsoluteSize.X
					local maxY = workspace.CurrentCamera.ViewportSize.Y - openUI.AbsoluteSize.Y
					if newX < 0 then newX = 0 end
					if newY < 0 then newY = 0 end
					if newX > maxX then newX = maxX end
					if newY > maxY then newY = maxY end

					openUI.Position = UDim2.new(0, newX, 0, newY)
				end
			end)
		end
	end
end)

-- แสดงข้อความ กลางจอ 5วิ ตอนเริ่มรันสคริปต์
task.spawn(function()
    local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
    screenGui.ResetOnSpawn = false

    local label = Instance.new("TextLabel", screenGui)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    label.BackgroundTransparency = 0
    label.Text = "Script by kvsna3545"
    label.Font = Enum.Font.GothamBold
    label.TextSize = 100
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0,0,0)
    label.TextWrapped = true
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextXAlignment = Enum.TextXAlignment.Center

    wait(3)
    label:Destroy()
end)
