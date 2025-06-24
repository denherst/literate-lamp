local plr = game.Players.LocalPlayer

function modifyStats(str, weightDelta, ageDelta)
	-- Extract name, weight, and age
	local name = string.match(str, "^(.-)%s*%[") -- everything before the first [
	local weight = tonumber(string.match(str, "%[(%d+%.?%d*)%s*KG%]"))
	local age = tonumber(string.match(str, "%[Age%s+(%d+)%]"))

	-- Modify the values
	local newWeight = weight + weightDelta
	local newAge = age + ageDelta

	-- Construct new string
	local newStr = string.format("%s [%.2f KG] [Age %d]", name, newWeight, newAge)
	return newStr
end

local bluemod = (function() 
	local module = {}
	local RunService = game:GetService("RunService")
	local Camera = workspace.CurrentCamera

	do
		local function IsNotNaN(x)
			return x == x
		end
		local continued = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.x)
		while not continued do
			RunService.RenderStepped:wait()
			continued = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.x)
		end
	end

	local RootParent = Camera

	local binds = {}
	local root = Instance.new('Folder', RootParent)
	root.Name = 'neon'
	local blurlight

	blurlight = Instance.new("DepthOfFieldEffect",game:GetService("Lighting"))
	blurlight.Enabled = true
	blurlight.FarIntensity = 0
	blurlight.FocusDistance = 51.6
	blurlight.InFocusRadius = 50
	blurlight.NearIntensity = 1
	--game:GetService("Debris"):AddItem(script,0)

	local GenUid; do
		local id = 0
		function GenUid()
			id = id + 1
			return 'neon::'..tostring(id)
		end
	end

	local DrawQuad; do
		local acos, max, pi, sqrt = math.acos, math.max, math.pi, math.sqrt
		local sz = 0.2

		function DrawTriangle(v1, v2, v3, p0, p1)
			local s1 = (v1 - v2).magnitude
			local s2 = (v2 - v3).magnitude
			local s3 = (v3 - v1).magnitude
			local smax = max(s1, s2, s3)
			local A, B, C
			if s1 == smax then
				A, B, C = v1, v2, v3
			elseif s2 == smax then
				A, B, C = v2, v3, v1
			elseif s3 == smax then
				A, B, C = v3, v1, v2
			end

			local para = ( (B-A).x*(C-A).x + (B-A).y*(C-A).y + (B-A).z*(C-A).z ) / (A-B).magnitude
			local perp = sqrt((C-A).magnitude^2 - para*para)
			local dif_para = (A - B).magnitude - para

			local st = CFrame.new(B, A)
			local za = CFrame.Angles(pi/2,0,0)

			local cf0 = st

			local Top_Look = (cf0 * za).lookVector
			local Mid_Point = A + CFrame.new(A, B).LookVector * para
			local Needed_Look = CFrame.new(Mid_Point, C).LookVector
			local dot = Top_Look.x*Needed_Look.x + Top_Look.y*Needed_Look.y + Top_Look.z*Needed_Look.z

			local ac = CFrame.Angles(0, 0, acos(dot))

			cf0 = cf0 * ac
			if ((cf0 * za).lookVector - Needed_Look).magnitude > 0.01 then
				cf0 = cf0 * CFrame.Angles(0, 0, -2*acos(dot))
			end
			cf0 = cf0 * CFrame.new(0, perp/2, -(dif_para + para/2))

			local cf1 = st * ac * CFrame.Angles(0, pi, 0)
			if ((cf1 * za).lookVector - Needed_Look).magnitude > 0.01 then
				cf1 = cf1 * CFrame.Angles(0, 0, 2*acos(dot))
			end
			cf1 = cf1 * CFrame.new(0, perp/2, dif_para/2)

			if not p0 then
				p0 = Instance.new('Part')
				p0.FormFactor = 'Custom'
				p0.TopSurface = 0
				p0.BottomSurface = 0
				p0.Anchored = true
				p0.CanCollide = false
				p0.Material = 'Glass'
				p0.Size = Vector3.new(sz, sz, sz)
				local mesh = Instance.new('SpecialMesh', p0)
				mesh.MeshType = 2
				mesh.Name = 'WedgeMesh'
			end
			p0.WedgeMesh.Scale = Vector3.new(0, perp/sz, para/sz)
			p0.CFrame = cf0

			if not p1 then
				p1 = p0:clone()
			end
			p1.WedgeMesh.Scale = Vector3.new(0, perp/sz, dif_para/sz)
			p1.CFrame = cf1

			return p0, p1
		end

		function DrawQuad(v1, v2, v3, v4, parts)
			parts[1], parts[2] = DrawTriangle(v1, v2, v3, parts[1], parts[2])
			parts[3], parts[4] = DrawTriangle(v3, v2, v4, parts[3], parts[4])
		end
	end

	function module:BindFrame(frame, properties)
		if RootParent == nil then return end
		if binds[frame] then
			return binds[frame].parts
		end

		local uid = GenUid()
		local parts = {}
		local f = Instance.new('Folder', root)
		f.Name = frame.Name

		local parents = {}
		do
			local function add(child)
				if child:IsA'GuiObject' then
					parents[#parents + 1] = child
					add(child.Parent)
				end
			end
			add(frame)
		end

		local function UpdateOrientation(fetchProps)
			local zIndex = 1 - 0.05*frame.ZIndex
			local tl, br = frame.AbsolutePosition, frame.AbsolutePosition + frame.AbsoluteSize
			local tr, bl = Vector2.new(br.x, tl.y), Vector2.new(tl.x, br.y)
			do
				local rot = 0;
				for _, v in ipairs(parents) do
					rot = rot + v.Rotation
				end
				if rot ~= 0 and rot%180 ~= 0 then
					local mid = tl:lerp(br, 0.5)
					local s, c = math.sin(math.rad(rot)), math.cos(math.rad(rot))
					local vec = tl
					tl = Vector2.new(c*(tl.x - mid.x) - s*(tl.y - mid.y), s*(tl.x - mid.x) + c*(tl.y - mid.y)) + mid
					tr = Vector2.new(c*(tr.x - mid.x) - s*(tr.y - mid.y), s*(tr.x - mid.x) + c*(tr.y - mid.y)) + mid
					bl = Vector2.new(c*(bl.x - mid.x) - s*(bl.y - mid.y), s*(bl.x - mid.x) + c*(bl.y - mid.y)) + mid
					br = Vector2.new(c*(br.x - mid.x) - s*(br.y - mid.y), s*(br.x - mid.x) + c*(br.y - mid.y)) + mid
				end
			end
			DrawQuad(
				Camera:ScreenPointToRay(tl.x, tl.y, zIndex).Origin, 
				Camera:ScreenPointToRay(tr.x, tr.y, zIndex).Origin, 
				Camera:ScreenPointToRay(bl.x, bl.y, zIndex).Origin, 
				Camera:ScreenPointToRay(br.x, br.y, zIndex).Origin, 
				parts
			)
			if fetchProps then
				for _, pt in pairs(parts) do
					pt.Parent = f
				end
				for propName, propValue in pairs(properties) do
					for _, pt in pairs(parts) do
						pt[propName] = propValue
					end
				end
			end
		end

		UpdateOrientation(true)
		RunService:BindToRenderStep(uid, 2000, UpdateOrientation)

		binds[frame] = {
			uid = uid;
			parts = parts;
		}
		return binds[frame].parts
	end

	function module:Modify(frame, properties)
		local parts = module:GetBoundParts(frame)
		if parts then
			for propName, propValue in pairs(properties) do
				for _, pt in pairs(parts) do
					pt[propName] = propValue
				end
			end
		end
	end

	function module:UnbindFrame(frame)
		if RootParent == nil then return end
		local cb = binds[frame]
		if cb then
			RunService:UnbindFromRenderStep(cb.uid)
			for _, v in pairs(cb.parts) do
				v:Destroy()
			end
			binds[frame] = nil
		end
	end

	function module:HasBinding(frame)
		return binds[frame] ~= nil
	end

	function module:GetBoundParts(frame)
		return binds[frame] and binds[frame].parts
	end


	return module	
	
end)()

local uiElements = {
	["ooo"] = Instance.new("ScreenGui"),
	["Frame"] = Instance.new("Frame"),
	["UICorner"] = Instance.new("UICorner"),
	["UIStroke"] = Instance.new("UIStroke"),
	["UIGradient"] = Instance.new("UIGradient"),
	["LocalScript"] = Instance.new("LocalScript"),
	["garb"] = Instance.new("ModuleScript"),
	["TextLabel"] = Instance.new("TextLabel"),
	["TextButton"] = Instance.new("TextButton"),
	["UICorner_1"] = Instance.new("UICorner"),
	["UIPadding"] = Instance.new("UIPadding"),
	["UIStroke_1"] = Instance.new("UIStroke"),
	["TextLabel_1"] = Instance.new("TextLabel"),
	["UIPadding_1"] = Instance.new("UIPadding"),
	["watermark"] = Instance.new("TextLabel"),
	["UITextSizeConstraint"] = Instance.new("UITextSizeConstraint")
}



uiElements["ooo"].Parent = game.Players.LocalPlayer.PlayerGui

uiElements["Frame"].Parent = uiElements["ooo"]
uiElements["Frame"].Position = UDim2.new(0.375, 0, 0.37271448969841003, 0)
uiElements["Frame"].Size = UDim2.new(0.2493455559015274, 0, 0.2531645596027374, 0)
uiElements["Frame"].BackgroundColor3 = Color3.fromRGB(31, 36, 65)
uiElements["Frame"].BorderColor3 = Color3.fromRGB(0, 0, 0)
uiElements["Frame"].BorderSizePixel = 0
uiElements["Frame"].BackgroundTransparency = 0.5

bluemod:BindFrame(uiElements["Frame"], {
	Transparency = 0.98;
	BrickColor = BrickColor.new("Institutional white");
})

print("done ig")

uiElements["UICorner"].Parent = uiElements["Frame"]
uiElements["UICorner"].CornerRadius = UDim.new(0.10000000149011612, 0)

uiElements["UIStroke"].Parent = uiElements["Frame"]
uiElements["UIStroke"].Color = Color3.fromRGB(255, 255, 255)

uiElements["UIGradient"].Parent = uiElements["UIStroke"]
uiElements["UIGradient"].Rotation = -45
uiElements["UIGradient"].Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(67.00000360608101, 67.00000360608101, 67.00000360608101)), ColorSequenceKeypoint.new(1, Color3.fromRGB(221.00000202655792, 221.00000202655792, 221.00000202655792))})

uiElements["LocalScript"].Parent = uiElements["Frame"]

uiElements["garb"].Parent = uiElements["LocalScript"]

uiElements["TextLabel"].Parent = uiElements["Frame"]
uiElements["TextLabel"].Size = UDim2.new(1, 0, 0.12777778506278992, 0)
uiElements["TextLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
uiElements["TextLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
uiElements["TextLabel"].BorderSizePixel = 0
uiElements["TextLabel"].BackgroundTransparency = 1
uiElements["TextLabel"].Font = Enum.Font.Cartoon
uiElements["TextLabel"].TextScaled = true
uiElements["TextLabel"].TextColor3 = Color3.fromRGB(255, 255, 255)
uiElements["TextLabel"].TextSize = 14
uiElements["TextLabel"].Text = "@DupeSTbot | Ручной метод"
uiElements["TextLabel"].TextWrapped = true

uiElements["TextButton"].Parent = uiElements["Frame"]
uiElements["TextButton"].Position = UDim2.new(0.1706036776304245, 0, 0.38333332538604736, 0)
uiElements["TextButton"].Size = UDim2.new(0.6561679840087891, 0, 0.23888888955116272, 0)
uiElements["TextButton"].BackgroundColor3 = Color3.fromRGB(170, 85, 255)
uiElements["TextButton"].BorderColor3 = Color3.fromRGB(0, 0, 0)
uiElements["TextButton"].BorderSizePixel = 0
uiElements["TextButton"].BackgroundTransparency = 0.6000000238418579
uiElements["TextButton"].Font = Enum.Font.Cartoon
uiElements["TextButton"].TextScaled = true
uiElements["TextButton"].TextColor3 = Color3.fromRGB(255, 255, 255)
uiElements["TextButton"].TextSize = 14
uiElements["TextButton"].Text = "Дюпнуть"
uiElements["TextButton"].TextWrapped = true
uiElements["TextButton"].AutoButtonColor = true

function t()
	game:GetService("TweenService"):Create(uiElements["TextButton"], TweenInfo.new(0.3), {
		TextColor3 = Color3.fromRGB(170, 85, 255),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.1
	}):Play()
end

function b()
	game:GetService("TweenService"):Create(uiElements["TextButton"], TweenInfo.new(0.3), {
		TextColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundColor3 = Color3.fromRGB(170, 85, 255),
		BackgroundTransparency = 0.6
		
	}):Play()
end

local c = false
local gg = false
uiElements["TextButton"].MouseButton1Click:Connect(function()
	if c == true or plr.Character:FindFirstChildWhichIsA("Tool") == nil then return end
	uiElements["TextButton"].AutoButtonColor = false
	t()
	uiElements["TextButton"].Text = "Дюпаем"
	gg = true
	task.spawn(function()
		repeat
			if gg == true then
				task.wait(0.5)
			end
			uiElements["TextButton"].Text = "Дюпаем."
			if gg == true then
				task.wait(0.5)
			end
			uiElements["TextButton"].Text = "Дюпаем.."
			if gg == true then
				task.wait(0.5)
			end
			uiElements["TextButton"].Text = "Дюпаем..."
		until gg == false
	end)
	c = true
	task.wait(math.random(100,250)/100)
	gg = false
	task.wait(0.2)
	local a = plr.Character:FindFirstChildWhichIsA("Tool"):Clone()
	local n = math.random(1,2)
	local mod
	if n == 1 then
		mod = modifyStats(a.Name, math.random(-200,-50)/100,math.random(-3,-1))
	else
		mod = modifyStats(a.Name, math.random(1,200)/100,math.random(1,3))
	end
	a.Name = mod
	a.Parent = plr.Backpack
	uiElements["TextButton"].Text = "Успех!"
	task.wait(2)
	uiElements["TextButton"].Text = "Дюпнуть"
	task.wait(1)
	c = false
	b()
	uiElements["TextButton"].AutoButtonColor = true
end)

uiElements["UICorner_1"].Parent = uiElements["TextButton"]

uiElements["UIPadding"].Parent = uiElements["TextButton"]
uiElements["UIPadding"].PaddingBottom = UDim.new(0, 3)

uiElements["UIStroke_1"].Parent = uiElements["TextButton"]
uiElements["UIStroke_1"].ApplyStrokeMode = Enum.ApplyStrokeMode.Border
uiElements["UIStroke_1"].Color = Color3.fromRGB(255, 255, 255)
uiElements["UIStroke_1"].Thickness = 0.75

uiElements["TextLabel_1"].Parent = uiElements["Frame"]
uiElements["TextLabel_1"].Position = UDim2.new(-0.002624671906232834, 0, 0.8388888835906982, 0)
uiElements["TextLabel_1"].Size = UDim2.new(1, 0, 0.12777778506278992, 0)
uiElements["TextLabel_1"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
uiElements["TextLabel_1"].BorderColor3 = Color3.fromRGB(0, 0, 0)
uiElements["TextLabel_1"].BorderSizePixel = 0
uiElements["TextLabel_1"].BackgroundTransparency = 1
uiElements["TextLabel_1"].Font = Enum.Font.Cartoon
uiElements["TextLabel_1"].TextScaled = true
uiElements["TextLabel_1"].TextColor3 = Color3.fromRGB(255, 255, 255)
uiElements["TextLabel_1"].TextSize = 14
uiElements["TextLabel_1"].Text = "Не распростронять. Приватная версия"
uiElements["TextLabel_1"].TextWrapped = true

uiElements["UIPadding_1"].Parent = uiElements["TextLabel_1"]
uiElements["UIPadding_1"].PaddingLeft = UDim.new(0, 5)uiElements["UIPadding_1"].PaddingRight = UDim.new(0, 5)

uiElements["watermark"].Parent = uiElements["Frame"]
uiElements["watermark"].Position = UDim2.new(0.025885233655571938, 0, -0.14027218520641327, 0)
uiElements["watermark"].Size = UDim2.new(0.9447476267814636, 0, 1.2785457372665405, 0)
uiElements["watermark"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
uiElements["watermark"].BorderColor3 = Color3.fromRGB(0, 0, 0)
uiElements["watermark"].BorderSizePixel = 0
uiElements["watermark"].Rotation = 13
uiElements["watermark"].ZIndex = 0
uiElements["watermark"].BackgroundTransparency = 1
uiElements["watermark"].Font = Enum.Font.SourceSans
uiElements["watermark"].TextScaled = true
uiElements["watermark"].TextColor3 = Color3.fromRGB(255, 255, 255)
uiElements["watermark"].TextSize = 78
uiElements["watermark"].Text = "@DupeSTbot"
uiElements["watermark"].TextTransparency = 0.92
uiElements["watermark"].TextWrapped = true

uiElements["UITextSizeConstraint"].Parent = uiElements["watermark"]
uiElements["UITextSizeConstraint"].MaxTextSize = 78