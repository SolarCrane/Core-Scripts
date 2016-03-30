local ICON_SIZE = 48
local ICON_SPACING = 52
local PIXELS_PER_STUD = 64

local SLOT_BORDER_SIZE = 0
local SLOT_BORDER_HOVER_SIZE = 4
local SLOT_BORDER_COLOR = Color3.new(90/255, 142/255, 233/255)

local HOPPERBIN_ANGLE = math.rad(-45)
local HOPPERBIN_ROTATION = CFrame.Angles(HOPPERBIN_ANGLE, 0, 0)
local HOPPERBIN_OFFSET = Vector3.new(0, 0, -5)

local HEALTHBAR_SPACE = 10
local HEALTHBAR_WIDTH = 80
local HEALTHBAR_HEIGHT = 3

local Tools = {}
local ToolsList = {}

local BackpackScript = {}
local topbarEnabled = false

local player = game.Players.LocalPlayer
local currentHumanoid = nil
local CoreGui = game:GetService('CoreGui')

local hopperbinPart = Instance.new("Part", workspace.CurrentCamera)
hopperbinPart.Transparency = 1
hopperbinPart.CanCollide = false
hopperbinPart.Anchored = true
hopperbinPart.Name = "GUI"
local hopperbinGUI = Instance.new("SurfaceGui", CoreGui)
hopperbinGUI.Adornee = hopperbinPart
hopperbinGUI.ToolPunchThroughDistance = 1000
hopperbinGUI.Name = "HopperBinGUI"
local toolsFrame = Instance.new("Frame", hopperbinGUI)
toolsFrame.Size = UDim2.new(1, 0, 0, ICON_SIZE)
toolsFrame.Position = UDim2.new(0, 0, 0, HEALTHBAR_SPACE)
toolsFrame.BackgroundTransparency = 1

local healthbarBack = Instance.new("Frame", hopperbinGUI)
healthbarBack.BackgroundColor3 = Color3.new(1, 1, 1)
healthbarBack.BorderSizePixel = 0
healthbarBack.Name = "HealthbarBack"
local healthbarFront = Instance.new("Frame", healthbarBack)
healthbarFront.BorderSizePixel = 0
healthbarFront.Size = UDim2.new(1, 0, 1, 0)
healthbarFront.Position = UDim2.new(0, 0, 0, 0)
healthbarFront.BackgroundColor3 = Color3.new(0, 1, 0)
healthbarFront.Name = "HealthbarFront"

local GREEN_COLOR = Color3.new(0.2, 1, 0.2)
local RED_COLOR = Color3.new(1, 0.2, 0.2)
local YELLOW_COLOR = Color3.new(1, 1, 0.2)

local verticalRange = math.rad(0)
local horizontalRange = math.rad(0)

local backpackEnabled = true
local healthbarEnabled = true

local function UpdateLayout()
	local width, height = 100, 100
	local borderSize = (ICON_SPACING - ICON_SIZE) / 2	
	
	local x = borderSize
	local y = 0
	for _, tool in ipairs(ToolsList) do
		local slot = Tools[tool]
		if slot then
			slot.icon.Position = UDim2.new(0, x, 0, y)
			x = x + ICON_SPACING
		end
	end
	
	width = #ToolsList * ICON_SPACING
	height = ICON_SIZE + HEALTHBAR_SPACE
	
	hopperbinGUI.CanvasSize = Vector2.new(width, height)
	hopperbinPart.Size = Vector3.new(width / PIXELS_PER_STUD, height / PIXELS_PER_STUD, 1)	

	healthbarBack.Position = UDim2.new(0.5, -HEALTHBAR_WIDTH / 2, 0, (HEALTHBAR_SPACE - HEALTHBAR_HEIGHT) / 2)
	healthbarBack.Size = UDim2.new(0, HEALTHBAR_WIDTH, 0, HEALTHBAR_HEIGHT)
	
	verticalRange = math.atan(hopperbinPart.Size.Y / (2 * HOPPERBIN_OFFSET.Z)) + math.rad(30) * 2
	horizontalRange = math.atan(hopperbinPart.Size.X / (2 * HOPPERBIN_OFFSET.Z)) - math.rad(20) * 2
end

local function UpdateHealth(humanoid)
	local percentHealth = humanoid.Health / humanoid.MaxHealth
	if percentHealth ~= percentHealth then
		percentHealth = 1
		healthbarFront.BackgroundColor3 = YELLOW_COLOR
	elseif percentHealth > 0.25  then		
		healthbarFront.BackgroundColor3 = GREEN_COLOR
	else
		healthbarFront.BackgroundColor3 = RED_COLOR
	end
	healthbarFront.Size = UDim2.new(percentHealth, 0, 1, 0)
end

local function SetTransparency(transparency)
	for i, v in pairs(Tools) do
		v.icon.BackgroundTransparency = transparency + 0.5
		v.icon.ImageTransparency = transparency
	end

	healthbarBack.BackgroundTransparency = transparency
	healthbarFront.BackgroundTransparency = transparency
end

local function AddTool(tool)
	if Tools[tool] then
		return
	end

	local slot = {}
	Tools[tool] = slot
	table.insert(ToolsList, tool)
	
	slot.tool = tool
	slot.icon = Instance.new("ImageButton", toolsFrame)
	slot.icon.Size = UDim2.new(0, ICON_SIZE, 0, ICON_SIZE)
	slot.icon.BackgroundColor3 = Color3.new(0, 0, 0)
	slot.icon.BorderSizePixel = SLOT_BORDER_SIZE
	slot.icon.BorderColor3 = SLOT_BORDER_COLOR
	slot.icon.Image = tool.TextureId
	
	slot.icon.MouseButton1Click:connect(function()
		if not player.Character then return end
		local humanoid = player.Character:FindFirstChild("Humanoid")
		if not humanoid then return end
		
		local in_backpack = tool.Parent == player.Backpack
		humanoid:UnequipTools()
		if in_backpack then
			humanoid:EquipTool(tool)
		end
	end)
	slot.OnEnter = function()
		slot.icon.BorderSizePixel = SLOT_BORDER_HOVER_SIZE
	end
	slot.OnLeave = function()
		slot.icon.BorderSizePixel = SLOT_BORDER_SIZE
	end
--	slot.icon.MouseEnter:connect(slot.OnEnter)
--	slot.icon.MouseLeave:connect(slot.OnLeave)
	
	UpdateLayout()
end

local humanoidChangedEvent = nil
local humanoidAncestryChangedEvent = nil
local function RegisterHumanoid(humanoid)
	currentHumanoid = humanoid
	if humanoidChangedEvent then
		humanoidChangedEvent:disconnect()
		humanoidChangedEvent = nil
	end
	if humanoidAncestryChangedEvent then
		humanoidAncestryChangedEvent:disconnect()
		humanoidAncestryChangedEvent = nil
	end
	if humanoid then
		humanoidChangedEvent = humanoid.HealthChanged:connect(function() UpdateHealth(humanoid) end)
		humanoidAncestryChangedEvent = humanoid.AncestryChanged:connect(function(child, parent) 
			if child == humanoid and parent ~= player.Character then
				RegisterHumanoid(nil)
			end
		end)
		UpdateHealth(humanoid)
	end
end

local function OnChildAdded(child)
	if child:IsA("Tool") or child:IsA("HopperBin") then
		AddTool(child)
	end
	if child:IsA("Humanoid") and child.Parent == player.Character then
		RegisterHumanoid(child)
	end
end

local function RemoveTool(tool)
	if not Tools[tool] then
		return
	end
	Tools[tool].icon:Destroy()
	for i, v in ipairs(ToolsList) do
		if v == tool then
			table.remove(ToolsList, i)
			break
		end
	end
	Tools[tool] = nil
	UpdateLayout()
end

local function OnChildRemoved(child)
	if child:IsA("Tool") or child:IsA("HopperBin") then
		if Tools[child] then
			if child.Parent ~= player:FindFirstChild("Backpack") and child.Parent ~= player.Character then
				RemoveTool(child)
			end
		end
	end
end

local function OnCharacterAdded(character)
	local backpack = player:WaitForChild("Backpack")

	for i, v in ipairs(character:GetChildren()) do
		if v:IsA("Humanoid") then
			RegisterHumanoid(v)
			break
		end
	end

	for tool, v in pairs(Tools) do
		RemoveTool(tool)
	end
	Tools = {}
	ToolsList = {}
	
	character.ChildAdded:connect(OnChildAdded)
	character.ChildRemoved:connect(OnChildRemoved)
	hopperbinGUI.Parent = CoreGui
	
	for i, v in ipairs(backpack:GetChildren()) do
		OnChildAdded(v)
	end
	
	backpack.ChildAdded:connect(OnChildAdded)
	backpack.ChildRemoved:connect(OnChildRemoved)
end

player.CharacterAdded:connect(OnCharacterAdded)
if player.Character then
	spawn(function() OnCharacterAdded(player.Character) end)
end

local zeroVector = Vector3.new(0, 0, 0)
local horizontalRotation = CFrame.new()
game:GetService("RunService"):BindToRenderStep("HopperBin3D", Enum.RenderPriority.Last.Value, function()
	if not (backpackEnabled or healthbarEnabled) then
		return
	end
	local cameraCFrame = workspace.CurrentCamera:GetRenderCFrame()
	local cameraLook = cameraCFrame.lookVector
	local cameraHorizontalVector = Vector3.new(cameraLook.X, 0, cameraLook.Z).unit

	local cameraPitchAngle = math.asin(cameraLook.Y)
	if cameraPitchAngle > math.rad(-25) then
		local cameraHorizontalRotation = CFrame.new(zeroVector, cameraHorizontalVector)
		horizontalRotation = cameraHorizontalRotation
	end
	
	local position = workspace.CurrentCamera.CFrame.p	

	local verticalError = math.abs((cameraPitchAngle - HOPPERBIN_ANGLE) / verticalRange)
	local horizontalError = math.acos(cameraHorizontalVector:Dot(horizontalRotation.lookVector)) / horizontalRange
	
	SetTransparency(math.max(verticalError, horizontalError))
	
	local hopperbinVector = HOPPERBIN_ROTATION:vectorToWorldSpace(HOPPERBIN_OFFSET)
	hopperbinVector = horizontalRotation:vectorToWorldSpace(hopperbinVector)
	hopperbinPart.CFrame = CFrame.new(position + hopperbinVector, position)
end)

local cursor = Instance.new("ImageLabel", hopperbinGUI)
cursor.Image = "rbxasset://textures/Cursors/Gamepad/Pointer.png"
cursor.Size = UDim2.new(0, 8, 0, 8)
cursor.BackgroundTransparency = 1
cursor.ZIndex = 2

local uis = game:GetService("UserInputService")

game:GetService("RunService"):BindToRenderStep("Cursor3D", Enum.RenderPriority.Last.Value, function()
	if not backpackEnabled then
		return
	end
	if not player.Character then
		return
	end

	local cframe = workspace.CurrentCamera:GetRenderCFrame()
	local ray = Ray.new(cframe.p, cframe.lookVector * 999)
	local ignoreList = { player.Character }
	local part, endpoint = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)

	cursor.Visible = false
	if part ~= hopperbinPart then
		return
	end
	cursor.Visible = true
	
	local localEndpoint = part:GetRenderCFrame():pointToObjectSpace(endpoint)
	local x = ((localEndpoint.X / part.Size.X) * 1) + 0.5
	local y = ((localEndpoint.Y / part.Size.Y) * 1) + 0.5
	x = 1 - x
	y = 1 - y
	cursor.Position = UDim2.new(x, -cursor.AbsoluteSize.x * 0.5, y, -cursor.AbsoluteSize.y * 0.5)
	
	--REMOVE THIS WHEN GUI MOUSELEAVE/MOUSEENTER ARE FIXED
	local px = cursor.AbsolutePosition.X + cursor.AbsoluteSize.X * 0.5
	local py = cursor.AbsolutePosition.Y + cursor.AbsoluteSize.Y * 0.5
	for i, v in pairs(Tools) do
		v.OnLeave()
		local ix = px - v.icon.AbsolutePosition.X
		local iy = py - v.icon.AbsolutePosition.Y
		if ix > 0 and ix < v.icon.AbsoluteSize.X and iy > 0 and iy < v.icon.AbsoluteSize.Y then
			v.OnEnter()
		end
	end
	------------------------------------------------------

	uis.MouseBehavior = Enum.MouseBehavior.LockCenter
	uis.MouseIconEnabled = false
end)

local function OnHotbarEquip(actionName, state, obj)
	if not backpackEnabled then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	if not currentHumanoid then
		return
	end
	if state ~= Enum.UserInputState.Begin then
		return
	end
	if #ToolsList == 0 then
		return
	end
	local current = 0
	for i, v in pairs(ToolsList) do
		if v.Parent == character then
			current = i
		end
	end
	currentHumanoid:UnequipTools()
	if obj.KeyCode == Enum.KeyCode.ButtonR1 then
		current = current + 1
		if current > #ToolsList then
			current = 1
		end
	else
		current = current - 1
		if current < 1 then
			current = #ToolsList
		end
	end
	currentHumanoid:EquipTool(ToolsList[current])
end

local function OnCoreGuiChanged(coreGuiType, enabled)
	-- Check for enabling/disabling the whole thing
	if coreGuiType == Enum.CoreGuiType.Backpack or coreGuiType == Enum.CoreGuiType.All then
		backpackEnabled = enabled
		if enabled then
			game:GetService("ContextActionService"):BindCoreAction("HotbarEquip2", OnHotbarEquip, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
			toolsFrame.Parent = hopperbinGUI --TODO: UPDATE TO NEW PARENT WHEN AVAILABLE
		else
			game:GetService("ContextActionService"):UnbindCoreAction("HotbarEquip2")
			toolsFrame.Parent = nil
		end
	end

	if coreGuiType == Enum.CoreGuiType.Health or coreGuiType == Enum.CoreGuiType.All then
		healthbarEnabled = enabled
		if enabled then
			healthbarBack.Parent = hopperbinGUI
		else
			healthbarBack.Parent = nil
		end
	end
end

local StarterGui = game:GetService("StarterGui")
StarterGui.CoreGuiChangedSignal:connect(OnCoreGuiChanged)
OnCoreGuiChanged(Enum.CoreGuiType.Backpack, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack))
OnCoreGuiChanged(Enum.CoreGuiType.Backpack, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All))

OnCoreGuiChanged(Enum.CoreGuiType.Health, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Health))
OnCoreGuiChanged(Enum.CoreGuiType.Health, StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.All))

return BackpackScript