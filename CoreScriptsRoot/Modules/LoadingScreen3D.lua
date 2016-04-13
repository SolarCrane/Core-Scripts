-- LoadingScreen3D.lua --
-- Written by Kip Turner, copyright ROBLOX 2016 --


local GUI_DISTANCE_FROM_CAMERA = 6
local VERTICAL_SCREEN_PERCENT = 1/3
local HORIZONTAL_SCREEN_PERCENT = 1/3
local SECOND_TO_FADE = 2.5
local ROTATIONS_PER_SECOND = 0.5
local TEXT_SCROLL_SPEED = 25

local BACKGROUND_COLOR3 = Color3.new(1,1,1)
local TEXT_COLOR3 = Color3.new(0,0,0)

local CoreGui = game:GetService('CoreGui')
local RunService = game:GetService('RunService')
local MarketPlaceService = game:GetService('MarketplaceService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedFirst = game:GetService('ReplicatedFirst')
local GuiService = game:GetService('GuiService')

local RobloxGui = CoreGui:WaitForChild("RobloxGui")
local Util = require(RobloxGui.Modules.Settings.Utility)


local function FadeElements(element, newValue, duration)
	duration = duration or 0.5
	if element == nil then return end
	if element:IsA('ImageLabel') or element:IsA('ImageButton') then
		Util:TweenProperty(element, 'ImageTransparency', element.ImageTransparency, newValue, duration, Util:GetEaseInOutQuad())
	end
	if element:IsA('GuiObject') then
		Util:TweenProperty(element, 'BackgroundTransparency', element.BackgroundTransparency, newValue, duration, Util:GetEaseInOutQuad())
	end
	if element:IsA('TextLabel') or element:IsA('TextBox') or element:IsA('TextButton') then
		Util:TweenProperty(element, 'TextTransparency', element.TextTransparency, newValue, duration, Util:GetEaseInOutQuad())
	end
	for _, child in pairs(element:GetChildren()) do
		FadeElements(child, newValue, duration)
	end
end


local GameInfoProvider = {}
do
	local LoadingFinishedSignal = Instance.new('BindableEvent')
	GameInfoProvider.Finished = false
	GameInfoProvider.GameAssetInfo = nil
	GameInfoProvider.LoadingFinishedEvent = LoadingFinishedSignal.Event
	
	function GameInfoProvider:GetGameName()
		if self.GameAssetInfo ~= nil then
			return self.GameAssetInfo.Name
		else
			return ''
		end
	end

	function GameInfoProvider:GetCreatorName()
		if self.GameAssetInfo ~= nil then
			return self.GameAssetInfo.Creator.Name
		else
			return ''
		end
	end

	function GameInfoProvider:IsReady()
		return self.Finished
	end

	function GameInfoProvider:LoadAssetsAsync()
		spawn(function()
			while game.PlaceId <= 0 do
				wait()
			end

			-- load game asset info
			local success, result = pcall(function()
				self.GameAssetInfo = MarketPlaceService:GetProductInfo(game.PlaceId)
			end)
			if not success then
				print("LoadingScript->GameInfoProvider:LoadAssets:", result)
			end
			self.Finished = true
			LoadingFinishedSignal:Fire()
		end)
	end
end




local LoadingScreen = {}

local renderStepGUID = game:GetService("HttpService"):GenerateGUID() .. "LoadingGui3D"

local surfaceGuiAdorn = Util:Create'Part'
{
	Name = "LoadingGui";
	Transparency = 1;
	CanCollide = false;
	Anchored = true;
	Archivable = false;
	FormFactor = Enum.FormFactor.Custom;
	RobloxLocked = true;
	Parent = workspace.CurrentCamera;
}

local loadingSurfaceGui = Util:Create'SurfaceGui'
{
	Name = "LoadingSurfaceGui";
	Adornee = surfaceGuiAdorn;
	ToolPunchThroughDistance = 1000;
	CanvasSize = Vector2.new(500, 500);
	Archivable = false;
	Parent = CoreGui;
	-- Parent = surfaceGuiAdorn;
}


local function CreateInformationFrame(titleText, imageTexture)
	local container = Util:Create'ImageLabel'
	{
		Name = 'Background';
		Size = UDim2.new(1,0,1,0);
		Image = 'rbxasset://textures/ui/LoadingScreen/BackgroundLight.png';
		ImageColor3 = BACKGROUND_COLOR3;
		ScaleType = Enum.ScaleType.Slice;
		SliceCenter = Rect.new(70,70,110,110);
		BackgroundTransparency = 1;
		Parent = loadingSurfaceGui;
	}

	local title = Util:Create'TextLabel'
	{
		Name = 'TitleText';
		Text = titleText;
		BackgroundTransparency = 1;
		Font = Enum.Font.SourceSans;
		FontSize = Enum.FontSize.Size60;
		Position = UDim2.new(0.5,0,0.2,0);
		TextColor3 = TEXT_COLOR3;
		Parent = container;
	}

	local image = Util:Create'ImageLabel'
	{
		Name = 'Image';
		Size = UDim2.new(0.25,0,0.25,0);
		Position = UDim2.new(0.5 - (0.25/2), 0, 0.45 - (0.25/2), 0);
		Image = imageTexture;
		BackgroundTransparency = 1;
		Parent = container;
	}
	return container, title, image
end

local spinnerRotation = 0
----------- LOADING FRAME -----------
local loadingContainer, loadingText, spinnerImage = CreateInformationFrame('Loading...', 'rbxasset://textures/ui/LoadingScreen/LoadingSpinner.png')

local gameNameText = Util:Create'TextLabel'
{
	Name = 'GameNameText';
	Text = '';
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	FontSize = Enum.FontSize.Size60;
	Size = UDim2.new(0.9, 0, 0.1, 0);
	Position = UDim2.new(0.05,0,0.65,0);
	TextColor3 = TEXT_COLOR3;
	ClipsDescendants = true;
	Parent = loadingContainer;
}


local creatorTextContainer = Util:Create'Frame'
{
	Name = 'CreatorTextContainer';
	Size = UDim2.new(0.9, 0, 0.1, 0);
	Position = UDim2.new(0.05,0,0.77,0);
	BackgroundTransparency = 1;
	ClipsDescendants = true;
	Parent = loadingContainer;
}

local creatorTextPosition = 0
local creatorText = Util:Create'TextLabel'
{
	Name = 'CreatorText';
	Text = '';
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	FontSize = Enum.FontSize.Size42;
	Size = UDim2.new(1, 0, 1, 0);
	TextColor3 = TEXT_COLOR3;
	Parent = creatorTextContainer;
}
----------- END LOADING FRAME -----------

----------- ERROR FRAME -----------
local errorContainer, errorText, errorImage = CreateInformationFrame('Error', 'rbxasset://textures/ui/ErrorIconSmall.png')
errorContainer.Visible = false

local errorDescriptionText = Util:Create'TextLabel'
{
	Name = 'ErrorDescriptionText';
	Text = '';
	BackgroundTransparency = 1;
	Font = Enum.Font.SourceSans;
	FontSize = Enum.FontSize.Size42;
	TextColor3 = TEXT_COLOR3;
	Position = UDim2.new(0,0,0.7,0);
	Size = UDim2.new(1, 0, 0.3, 0);
	TextWrapped = true;
	Parent = errorContainer;
}
----------- END ERROR FRAME -----------

----------- TELEPORT FRAME -----------
local teleportContainer, teleportText, teleportImage = CreateInformationFrame('Teleporting...', 'rbxasset://textures/ui/LoadingScreen/LoadingSpinner.png')
teleportContainer.Visible = false
----------- END TELEPORT FRAME -----------

local function ScreenDimsAtDepth(depth)
	local camera = workspace.CurrentCamera
	if camera then
		local aspectRatio = camera.ViewportSize.x / camera.ViewportSize.y
		local studHeight = 2 * depth * math.tan(math.rad(camera.FieldOfView/2))
		local studWidth = studHeight * aspectRatio

		return Vector2.new(studWidth, studHeight)
	end
	return Vector2.new(0,0)
end

local CleanedUp = false
local freeze = true
delay(2.5, function()
	freeze = false
end)
local function UpdateLayout(delta)
	local screenDims = ScreenDimsAtDepth(GUI_DISTANCE_FROM_CAMERA)

	surfaceGuiAdorn.Size = Vector3.new(screenDims.x * HORIZONTAL_SCREEN_PERCENT, screenDims.y * VERTICAL_SCREEN_PERCENT, 1)
	local camera = workspace.CurrentCamera
	if camera then
		surfaceGuiAdorn.Parent = camera
	end


	if creatorText.TextBounds.X < creatorTextContainer.AbsoluteSize.X then
		creatorText.Position = UDim2.new(0, 0, 0, 0)
		creatorText.Size = UDim2.new(1, 0, 1, 0)
	elseif delta ~= nil then
		creatorText.Size = UDim2.new(0, creatorText.TextBounds.X, 1, 0)
		if not freeze then
			local newX = (creatorTextPosition - delta * TEXT_SCROLL_SPEED)
			if newX + creatorText.AbsoluteSize.X < creatorTextContainer.AbsoluteSize.X then
				freeze = true
				spawn(function()
					Util:TweenProperty(creatorText, 'TextTransparency', creatorText.TextTransparency, 1, 1, Util:GetEaseInOutQuad())
					wait(1.5)
					if CleanedUp then return end
					creatorTextPosition = 0
					Util:TweenProperty(creatorText, 'TextTransparency', creatorText.TextTransparency, 0, 1, Util:GetEaseInOutQuad())
					wait(1.5)
					freeze = false
				end)
			else
				creatorTextPosition = newX
			end
		end
		creatorText.Position = UDim2.new(0, creatorTextPosition, 0, 0)
	end

	if not gameNameText.TextFits then
		gameNameText.Size = UDim2.new(0.9, 0, 0.3, 0)
		gameNameText.Position = UDim2.new(0.05,0,0.5,0)
		gameNameText.TextScaled = true
		gameNameText.TextWrapped = true

		spinnerImage.Position = UDim2.new(0.5 - (0.25/2), 0, 0.225, 0)
		loadingText.Position = UDim2.new(0.5,0,0.15,0)
	end

end


local function CleanUp()
	if CleanedUp then return end
	CleanedUp = true
	surfaceGuiAdorn.Parent = nil
	RunService:UnbindFromRenderStep(renderStepGUID)
end

local function OnGameInfoLoaded()
	local creatorName = GameInfoProvider:GetCreatorName()
	if creatorName and creatorName ~= '' then
		creatorName = string.format("By %s", tostring(creatorName))
	end
	gameNameText.Text = GameInfoProvider:GetGameName()
	creatorText.Text = creatorName
end

local function OnReplicatingFinished()
	if game:IsLoaded() or game.Loaded:wait() then
		if not CleanedUp then
			FadeElements(loadingSurfaceGui, 1, SECOND_TO_FADE)
			wait(SECOND_TO_FADE)
			CleanUp()
		end
	end
end

local function OnDefaultLoadingGuiRemoved()
	if not CleanedUp then
		FadeElements(loadingSurfaceGui, 1, SECOND_TO_FADE)
		wait(SECOND_TO_FADE)
		CleanUp()
	end
end


local function UpdateSurfaceGuiPosition()
	local camera = workspace.CurrentCamera
	if camera then
		local cameraCFrame = camera.CFrame
		local cameraLook = cameraCFrame.lookVector
		local cameraHorizontalVector = Vector3.new(cameraLook.X, 0, cameraLook.Z).unit
		local cameraRenderCFrame = camera:GetRenderCFrame()

		surfaceGuiAdorn.CFrame = CFrame.new(cameraRenderCFrame.p + cameraHorizontalVector * GUI_DISTANCE_FROM_CAMERA, cameraRenderCFrame.p)
	end
end

local function OnErrorMessage(newMsg)
	errorDescriptionText.Text = newMsg
	if newMsg ~= '' then
		loadingContainer.Visible = false
		errorContainer.Visible = true
		teleportContainer.Visible = false
	end
end

local function OnUiMessage(msgType, newMsg)
	if msgType == Enum.UiMessageType.UiMessageInfo then
		teleportText.Text = newMsg
		if newMsg ~= '' then
			loadingContainer.Visible = false
			errorContainer.Visible = false
			teleportContainer.Visible = true
		end
	elseif msgType == Enum.UiMessageType.UiMessageError then
		OnErrorMessage(newMsg)
	end
end

do
	local lastUpdate = tick()
	RunService:BindToRenderStep(renderStepGUID, Enum.RenderPriority.Last.Value, function()
		local now = tick()
		local delta = now - lastUpdate

		UpdateSurfaceGuiPosition()
		UpdateLayout(delta)

		local rotation = delta * ROTATIONS_PER_SECOND * 360
		spinnerRotation = spinnerRotation + rotation
		spinnerImage.Rotation = spinnerRotation
		teleportImage.Rotation = spinnerRotation

		lastUpdate = now
	end)
	UpdateSurfaceGuiPosition()
	UpdateLayout()
end

GameInfoProvider:LoadAssetsAsync()
if GameInfoProvider:IsReady() then
	OnGameInfoLoaded()
end
GameInfoProvider.LoadingFinishedEvent:connect(OnGameInfoLoaded)


if ReplicatedFirst:IsFinishedReplicating() then
	OnReplicatingFinished()
else
	ReplicatedFirst.FinishedReplicating:connect(OnReplicatingFinished)
end

if ReplicatedFirst:IsDefaultLoadingGuiRemoved() then
	OnDefaultLoadingGuiRemoved()
else
	ReplicatedFirst.RemoveDefaultLoadingGuiSignal:connect(OnDefaultLoadingGuiRemoved)
end

GuiService.UiMessageChanged:connect(OnUiMessage)
OnUiMessage(Enum.UiMessageType.UiMessageInfo, GuiService:GetUiMessage())

GuiService.ErrorMessageChanged:connect(function()
	OnErrorMessage(GuiService:GetErrorMessage())
end)
OnErrorMessage(GuiService:GetErrorMessage())

return LoadingScreen

