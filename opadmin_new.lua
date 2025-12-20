if not game:IsLoaded() then
	game.Loaded:Wait()
end

setfpscap = setfpscap or function() end
setfps = setfps or function() end
fireproximityprompt = fireproximityprompt or function() end
firetouchinterest = firetouchinterest or nil
setclipboard = setclipboard or function() end
saveinstance = saveinstance or function() end
hookmetamethod = hookmetamethod or function() end
getloadedmodules = getloadedmodules or nil
decompile = decompile or function() return '' end
getnamecallmethod = getnamecallmethod or function() return '' end
checkcaller = checkcaller or nil
syn = syn or {}
sethiddenproperty = sethiddenproperty or function() end
set_hidden_property = sethiddenproperty or function() end
set_hidden_prop = sethiddenproperty or function() end
hookfunction = hookfunction or function() end
getrawmetatable = getrawmetatable or function() return {} end
mouse1click = mouse1click or nil
writefile = writefile or function() end
isfile = isfile or function() return false end
readfile = readfile or function() return '' end
getgenv = getgenv or function() return {} end
cloneref = cloneref or function(v) return v end
gethui = gethui or function() return cloneref(game:GetService('CoreGui')) end
setreadonly = setreadonly or function() end
newcclosure = newcclosure or function(f) return f end
Drawing = Drawing or {}

local env = getgenv() or shared or _G

env['opadmin'] = env['opadmin'] or {}
if env['opadmin'].i then return end
env['opadmin'].i = true

local services = {
	core_gui = gethui(),
	debris = cloneref(game:GetService('Debris')),
	tween_service = cloneref(game:GetService('TweenService')),
	players = cloneref(game:GetService('Players')),
	run_service = cloneref(game:GetService('RunService')),
	starter_player = cloneref(game:GetService('StarterPlayer')),
	teleport_service = cloneref(game:GetService('TeleportService')),
	text_chat_service = cloneref(game:GetService('TextChatService')),
	lighting = cloneref(game:GetService('Lighting')),
	user_input_service = cloneref(game:GetService('UserInputService')),
	replicated_storage = cloneref(game:GetService('ReplicatedStorage')),
	http = cloneref(game:GetService('HttpService')),
	gui_service = cloneref(game:GetService('GuiService')),
	marketplace_service = cloneref(game:GetService('MarketplaceService')),
	network_client = cloneref(game:GetService('NetworkClient')),
	sound_service = cloneref(game:GetService('SoundService')),
	workspace = cloneref(game:GetService('Workspace')),
	stats = cloneref(game:GetService('Stats'))
}

local stuff = {
	ver = 'dudu-is-gay',

	empty_function = function() end,
	destroy = game.Destroy,
	clone = game.Clone,
	connect = game.Changed.Connect,
	disconnect = nil,

	owner = services.players.LocalPlayer,
	owner_char = nil,

	ui = nil,
	open_keybind = nil,
	chat_prefix = nil,

	rawrbxget = nil,
	rawrbxset = nil,

	default_ws = 16,
	default_jp = 50,

	is_mobile = services.user_input_service.TouchEnabled and not services.user_input_service.KeyboardEnabled,
	is_console = services.gui_service:IsTenFootInterface(),

	highlights = {},
	target = nil,
	active_notifications = {},
	max_notifications = 10,
	velocity_history = {},
	ping_samples = {},

	ui_notifications_template = nil,
	ui_notifications_main_container = nil,
	ui_cmdlist = nil,
	ui_cmdlist_template = nil,
	ui_cmdlist_commandlist = nil,
	update_keybinds = nil,

	frame_times = {},
	last_frame_time = 0,
	avg_fps = 60,
	avg_ping = 0
}

stuff.owner_char = stuff.owner.Character or stuff.owner.CharacterAdded:Wait()

stuff.ui = (workspace:FindFirstChild('opadmin_ui') and workspace.opadmin_ui or game:GetObjects('rbxassetid://121800440973428')[1])
if stuff.ui then
	stuff.ui = stuff.ui:Clone()
else
	return warn('[opadmin] ui failed to load')
end

local function get_plrs(exclude)
	local plrs = {}
	for _, plr in services.players:GetPlayers() do
		if plr ~= exclude then
			table.insert(plrs, plr)
		end
	end
	return plrs
end

local function get_plr(name)
	if not name then return {} end

	local lower_name = name:lower()
	local all_plrs = get_plrs()

	local special_selectors;special_selectors = {
		['@random'] = function() return {all_plrs[math.random(#all_plrs)]} end,
		['@rand'] = function() return {all_plrs[math.random(#all_plrs)]} end,
		['@r'] = function() return {all_plrs[math.random(#all_plrs)]} end,
		['@self'] = function() return {stuff.owner} end,
		['@me'] = function() return {stuff.owner} end,
		['@s'] = function() return {stuff.owner} end,
		['@m'] = function() return {stuff.owner} end,
		['@everyone'] = function() return all_plrs end,
		['@all'] = function() return all_plrs end,
		['@e'] = function() return all_plrs end,
		['@a'] = function() return all_plrs end,
		['@others'] = function()
			local others = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					table.insert(others, plr)
				end
			end
			return others
		end,
		['@other'] = function() return special_selectors['@others']() end,
		['@o'] = function() return special_selectors['@others']() end,
		['@view'] = function()
			local subject = workspace.CurrentCamera.CameraSubject
			if subject and subject.Parent then
				return {services.players:GetPlayerFromCharacter(subject.Parent)}
			end
			return {}
		end,
		['@v'] = function() return special_selectors['@view']() end,
		['@nearest'] = function()
			local owner_hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if not owner_hrp then return {} end

			local nearest, nearest_dist = nil, math.huge
			for _, plr in all_plrs do
				if plr ~= stuff.owner and plr.Character then
					local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
					if hrp then
						local dist = (owner_hrp.Position - hrp.Position).Magnitude
						if dist < nearest_dist then
							nearest_dist = dist
							nearest = plr
						end
					end
				end
			end
			return nearest and {nearest} or {}
		end,
		['@n'] = function() return special_selectors['@nearest']() end,
		['@enemies'] = function()
			local enemies = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner then
					if not plr.Team or plr.Team ~= stuff.owner.Team then
						table.insert(enemies, plr)
					end
				end
			end
			return enemies
		end,
		['@team'] = function()
			local teammates = {}
			for _, plr in all_plrs do
				if plr ~= stuff.owner and plr.Team and plr.Team == stuff.owner.Team then
					table.insert(teammates, plr)
				end
			end
			return teammates
		end
	}

	if special_selectors[lower_name] then
		return special_selectors[lower_name]()
	end

	lower_name = lower_name:gsub('%s', '')
	for _, plr in all_plrs do
		if plr.Name:lower():match('^' .. lower_name) or plr.DisplayName:lower():match('^' .. lower_name) then
			return {plr}
		end
	end

	for _, plr in all_plrs do
		if plr.Name:lower():find(lower_name, 1, true) or plr.DisplayName:lower():find(lower_name, 1, true) then
			return {plr}
		end
	end

	return nil
end

local function hwait(sig)
	return services.run_service[sig and tostring(sig) or 'Heartbeat']:Wait()
end

local function protect_gui(gui)
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	elseif services.core_gui:FindFirstChild('RobloxGui') then
		stuff.rawrbxset(gui, 'Parent', services.core_gui.RobloxGui)
	else
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	end
end

local function lerp_color(c1, c2, t)
	return Color3.new(
		math.lerp(c1.R, c2.R, t),
		math.lerp(c1.G, c2.G, t),
		math.lerp(c1.B, c2.B, t))
end

local function get_rainbow(speed, saturation, value)
	return Color3.fromHSV((tick() * (speed or 1)) % 1, saturation or 1, value or 1)
end

local function deep_copy(t)
	if type(t) ~= 'table' then return t end
	local copy = {}
	for k, v in pairs(t) do
		copy[deep_copy(k)] = deep_copy(v)
	end
	return copy
end

local function update_performance_stats()
	local now = tick()
	local dt = now - stuff.last_frame_time
	stuff.last_frame_time = now

	table.insert(stuff.frame_times, dt)
	if #stuff.frame_times > 60 then
		table.remove(stuff.frame_times, 1)
	end

	local sum = 0
	for _, t in stuff.frame_times do
		sum = sum + t
	end
	stuff.avg_fps = #stuff.frame_times / sum

	local ping = stuff.owner:GetNetworkPing()
	table.insert(stuff.ping_samples, ping)
	if #stuff.ping_samples > 30 then
		table.remove(stuff.ping_samples, 1)
	end

	local ping_sum = 0
	for _, p in stuff.ping_samples do
		ping_sum = ping_sum + p
	end
	stuff.avg_ping = (ping_sum / #stuff.ping_samples) * 1000
end

local function quick_predict_position(player, future)
	local char = player.Character
	if not char then return end
	if future == nil  then
		future  = ((char:FindFirstChildOfClass("Humanoid").WalkSpeed * 68.75) / 100)
	end

	local hrp = char:FindFirstChild('HumanoidRootPart')
	local humanoid = char:FindFirstChild('Humanoid')
	if not (hrp and humanoid) then return end

	local move_dir = humanoid.MoveDirection
	if move_dir == Vector3.zero then
		return hrp.CFrame
	end

	return hrp.CFrame + move_dir * future
end

local function predict_position(target, options)
	options = options or {}

	local base_time = options.time or 0.1
	local use_velocity = options.velocity ~= false
	local use_movedir = options.movedir ~= false
	local use_ping = options.ping ~= false
	local use_acceleration = options.acceleration or false
	local fallback_speed = options.fallback_speed or 16

	local character, part

	if typeof(target) == 'Instance' then
		if target:IsA('Model') then
			character = target
			part = target:FindFirstChild('HumanoidRootPart') or target:FindFirstChild('Head')
		elseif target:IsA('BasePart') then
			part = target
			character = target:FindFirstAncestorOfClass('Model')
		end
	end

	if not part then return nil end

	local base_position = part.Position
	local prediction_time = base_time

	if use_ping then
		prediction_time = prediction_time + stuff.owner:GetNetworkPing()
	end

	if prediction_time <= 0 then return base_position end

	local velocity = Vector3.zero
	local weight_total = 0

	if use_velocity and character then
		local hrp = character:FindFirstChild('HumanoidRootPart')
		if hrp then
			local assembly_vel = hrp.AssemblyLinearVelocity
			local horizontal_vel = Vector3.new(assembly_vel.X, 0, assembly_vel.Z)

			if horizontal_vel.Magnitude > 0.5 then
				velocity = velocity + horizontal_vel * 2
				weight_total = weight_total + 2
			end
		end
	end

	if use_movedir and character then
		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if humanoid then
			local move_dir = humanoid.MoveDirection
			if move_dir.Magnitude > 0.1 then
				local walk_speed = humanoid.WalkSpeed or fallback_speed
				velocity = velocity + move_dir.Unit * walk_speed
				weight_total = weight_total + 1
			end
		end
	end

	if use_acceleration and character then
		local hrp = character:FindFirstChild('HumanoidRootPart')
		if hrp then
			local storage_key = tostring(character:GetDebugId())
			local history = stuff.velocity_history[storage_key] or {}

			local current_vel = hrp.AssemblyLinearVelocity
			local current_time = tick()

			table.insert(history, {vel = current_vel, time = current_time})

			while #history > 10 do
				table.remove(history, 1)
			end

			stuff.velocity_history[storage_key] = history

			if #history >= 3 then
				local oldest = history[1]
				local newest = history[#history]
				local dt = newest.time - oldest.time

				if dt > 0.05 then
					local acceleration = (newest.vel - oldest.vel) / dt
					local accel_horizontal = Vector3.new(acceleration.X, 0, acceleration.Z)

					if accel_horizontal.Magnitude < 100 then
						velocity = velocity + accel_horizontal * prediction_time * 0.5
						weight_total = weight_total + 0.5
					end
				end
			end
		end
	end

	if weight_total > 0 then
		velocity = velocity / weight_total
	end

	local predicted = base_position + velocity * prediction_time

	local max_prediction_distance = options.max_offset or (fallback_speed * prediction_time * 2)
	local offset = predicted - base_position
	if offset.Magnitude > max_prediction_distance then
		predicted = base_position + offset.Unit * max_prediction_distance
	end

	return predicted, velocity, prediction_time
end

local function get_target_part(character, part_name)
	if not character then return nil end

	local part_lookup = {
		head = {'Head'},
		torso = {'UpperTorso', 'Torso', 'LowerTorso'},
		hrp = {'HumanoidRootPart'},
		chest = {'UpperTorso', 'Torso'},
		pelvis = {'LowerTorso', 'Torso'},
		legs = {'LeftUpperLeg', 'RightUpperLeg', 'Left Leg', 'Right Leg'},
		arms = {'LeftUpperArm', 'RightUpperArm', 'Left Arm', 'Right Arm'}
	}

	local names = part_lookup[part_name:lower()] or part_lookup.head
	for _, name in names do
		local part = character:FindFirstChild(name)
		if part then return part end
	end

	return character:FindFirstChild('Head') or character:FindFirstChild('HumanoidRootPart')
end

local function is_valid_target(player, ignore_team)
	if not player or player == stuff.owner then return false end
	if not ignore_team and player.Team and player.Team == stuff.owner.Team then return false end

	local char = player.Character
	if not char then return false end

	local hum = char:FindFirstChildOfClass('Humanoid')
	if not hum or hum.Health <= 0 then return false end
	if char:FindFirstChildOfClass('ForceField') then return false end

	return true
end

local function has_line_of_sight(origin, target_pos, ignore_character)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {stuff.owner_char, ignore_character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, target_pos - origin, params)
	return result == nil
end

local function network_check(part)
	return part.ReceiveAge == 0
end

local function get_closest_part()
	local best_part, smallest_mag
	local head = stuff.owner_char and stuff.owner_char:FindFirstChild('Head')
	if not head then return nil end

	local head_pos = head.Position

	for _, v in workspace:GetDescendants() do
		if v:IsA('BasePart') and not v.Anchored and #v:GetConnectedParts() < 2 then
			if not v.Parent:FindFirstChildOfClass('Humanoid') and 
				not v.Parent.Parent:FindFirstChildOfClass('Humanoid') and 
				not v:IsDescendantOf(stuff.owner_char) then
				local mag = (head_pos - v.Position).Magnitude
				if not smallest_mag or mag < smallest_mag then
					smallest_mag, best_part = mag, v
				end
			end
		end
	end

	return best_part
end

local function fov_to_radius(fov)
	local viewport_size = workspace.CurrentCamera.ViewportSize
	return math.tan(math.rad(fov / 2)) * (viewport_size.Y / 2)
end

local function get_move_vector(speed)
	speed = speed or 1

	if stuff.is_mobile then
		local success, control_module = pcall(function()
			return require(stuff.owner.PlayerScripts:WaitForChild('PlayerModule'):WaitForChild('ControlModule'))
		end)
		if success and control_module then
			local direction = control_module:GetMoveVector()
			return direction * speed
		end
		return Vector3.zero
	else
		if services.user_input_service:GetFocusedTextBox() ~= nil then
			return Vector3.zero
		end

		local direction = Vector3.zero
		if services.user_input_service:IsKeyDown(Enum.KeyCode.W) then
			direction = direction + Vector3.new(0, 0, -1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.A) then
			direction = direction + Vector3.new(-1, 0, 0)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.S) then
			direction = direction + Vector3.new(0, 0, 1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.D) then
			direction = direction + Vector3.new(1, 0, 0)
		end

		return direction * speed
	end
end

local function remove_notification(notification_data)
	if notification_data.removing then return end
	notification_data.removing = true

	for i, notif in ipairs(stuff.active_notifications) do
		if notif == notification_data then
			table.remove(stuff.active_notifications, i)
			break
		end
	end

	local tween_info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tween = services.tween_service:Create(notification_data.label, tween_info, {
		BackgroundTransparency = 1,
		TextTransparency = 1,
		Position = notification_data.label.Position + UDim2.new(0.1, 0, 0, 0)
	})

	tween:Play()
	tween.Completed:Connect(function()
		notification_data.label:Destroy()
	end)
end

local function notify(log, text, log_type)
	if #stuff.active_notifications >= stuff.max_notifications then
		remove_notification(stuff.active_notifications[1])
	end

	local text_label = stuff.ui_notifications_template:Clone()
	local tween_info = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	text_label.Parent = stuff.ui_notifications_main_container
	text_label.Visible = true

	local colors = {
		[1] = Color3.fromRGB(239, 225, 255), -- success
		[2] = Color3.fromRGB(227, 112, 144), -- error
		[3] = Color3.fromRGB(227, 212, 144), -- warning
		[4] = Color3.fromRGB(127, 212, 244), -- info
	}

	text_label.TextColor3 = colors[log_type] or colors[1]
	text_label.Text = ` [{tostring(log) or '?'}] {text} `
	text_label.BackgroundTransparency = 1
	text_label.TextTransparency = 1
	text_label.Position = text_label.Position - UDim2.new(0.1, 0, 0, 0)

	services.tween_service:Create(text_label, tween_info, {
		BackgroundTransparency = 0.1,
		TextTransparency = 0,
		Position = text_label.Position + UDim2.new(0.1, 0, 0, 0)
	}):Play()

	local notification_data = {
		label = text_label,
		created_at = tick(),
		removing = false
	}

	table.insert(stuff.active_notifications, notification_data)

	task.delay(4, function()
		remove_notification(notification_data)
	end)
end

local function str_to_type(str, t)
	if not t then return str end

	local converters;converters = {
		number = function(s) return tonumber(s) end,

		boolean = function(s)
			local lower = s:lower()
			if lower == 'true' or lower == '1' or lower == 'yes' or lower == 'on' then
				return true
			elseif lower == 'false' or lower == '0' or lower == 'no' or lower == 'off' then
				return false
			end
			return nil
		end,

		bool = function(s) return converters.boolean(s) end,

		string = function(s) return tostring(s) end,

		player = function(s) return get_plr(s) end,

		vector3 = function(s)
			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end
			if #parts == 3 then
				return Vector3.new(parts[1], parts[2], parts[3])
			end
			return nil
		end,

		vec3 = function(s) return converters.vector3(s) end,

		color3 = function(s)
			if s == 'team' then return 'team' end
			if s == 'rainbow' then return 'rainbow' end

			local hex = s:match('^#?(%x+)$')
			if hex then
				if #hex == 3 then
					local r = tonumber(hex:sub(1, 1):rep(2), 16)
					local g = tonumber(hex:sub(2, 2):rep(2), 16)
					local b = tonumber(hex:sub(3, 3):rep(2), 16)
					return Color3.fromRGB(r, g, b)
				elseif #hex == 6 then
					local r = tonumber(hex:sub(1, 2), 16)
					local g = tonumber(hex:sub(3, 4), 16)
					local b = tonumber(hex:sub(5, 6), 16)
					return Color3.fromRGB(r, g, b)
				end
			end

			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end
			if #parts == 3 then
				if parts[1] <= 1 and parts[2] <= 1 and parts[3] <= 1 then
					return Color3.new(parts[1], parts[2], parts[3])
				else
					return Color3.fromRGB(parts[1], parts[2], parts[3])
				end
			end

			return nil
		end,

		color = function(s) return converters.color3(s) end,

		cframe = function(s)
			local parts = {}
			for num in s:gmatch('[^,]+') do
				local n = tonumber(num:match('^%s*(.-)%s*$'))
				if n then table.insert(parts, n) end
			end
			if #parts >= 3 then
				return CFrame.new(parts[1], parts[2], parts[3])
			end
			return nil
		end,

		table = function(s)
			local result = {}
			for item in s:gmatch('[^,]+') do
				table.insert(result, item:match('^%s*(.-)%s*$'))
			end
			return result
		end,

		array = function(s) return converters.table(s) end
	}

	if converters[t] then
		return converters[t](str)
	end

	notify('args', `invalid type '{t}' for string '{str}'`, 2)
	return nil
end

local maid = {
	_tasks = {},
	_protected = {},
	_cleaner = nil
}

function maid.add(name, task_or_signal, fn, important)
	if maid._tasks[name] then
		maid.remove(name)
	elseif maid._protected[name] then
		if important then
			maid.remove_protected(name)
		else
			warn(`[maid] tried to overwrite protected task {name}`)
			return
		end
	end

	local task_obj, task_type

	if typeof(task_or_signal) == 'RBXScriptSignal' and fn then
		task_obj = stuff.connect(task_or_signal, fn)
		task_type = 'connection'
	elseif typeof(task_or_signal) == 'RBXScriptConnection' then
		task_obj = task_or_signal
		task_type = 'connection'
	elseif typeof(task_or_signal) == 'Instance' then
		task_obj = task_or_signal
		task_type = 'instance'
	elseif typeof(task_or_signal) == 'thread' then
		task_obj = task_or_signal
		task_type = 'thread'
	elseif typeof(task_or_signal) == 'function' then
		task_obj = task_or_signal
		task_type = 'function'
	else
		warn(`[maid] unknown task type: {typeof(task_or_signal)}`)
		return
	end

	local storage = important == 1 and maid._protected or maid._tasks
	storage[name] = {task = task_obj, type = task_type}
end

function maid.remove(name)
	local task_data = maid._tasks[name]
	if task_data then
		maid._cleanup_task(task_data)
		maid._tasks[name] = nil
		return true
	end
	return false
end

function maid.remove_protected(name)
	local task_data = maid._protected[name]
	if task_data then
		maid._cleanup_task(task_data)
		maid._protected[name] = nil
		return true
	end
	return false
end

function maid._cleanup_task(task_data)
	if not task_data then return end

	pcall(function()
		if task_data.type == 'connection' then
			local conn = task_data.task
			if typeof(conn) == 'RBXScriptConnection' and conn.Connected then
				stuff.disconnect(conn)
			end
		elseif task_data.type == 'instance' then
			local inst = task_data.task
			if typeof(inst) == 'Instance' and inst.Parent then
				pcall(stuff.destroy, inst)
			end
		elseif task_data.type == 'thread' then
			local thread = task_data.task
			if coroutine.status(thread) ~= 'dead' then
				task.cancel(thread)
			end
		elseif task_data.type == 'function' then
			pcall(task_data.task)
		end
	end)
end

function maid.clean(keep_protected)
	for name, task_data in pairs(maid._tasks) do
		maid._cleanup_task(task_data)
	end
	table.clear(maid._tasks)

	if not keep_protected then
		for name, task_data in pairs(maid._protected) do
			maid._cleanup_task(task_data)
		end
		table.clear(maid._protected)
	end
end

function maid.get(name)
	local task_data = maid._tasks[name] or maid._protected[name]
	return task_data and task_data.task or nil
end

function maid.exists(name)
	return maid._tasks[name] ~= nil or maid._protected[name] ~= nil
end

do
	local con = stuff.connect(game.Changed, stuff.empty_function)
	stuff.disconnect = con.Disconnect
	pcall(stuff.disconnect, con)

	stuff.rawrbxset = function(obj, key, value)
		obj[key] = value
	end
	stuff.rawrbxget = function(obj, key)
		return obj[key]
	end -- got rid of them because doesnt work on low unc

	local hum = stuff.owner_char:WaitForChild('Humanoid', 10)
	if hum then
		stuff.default_ws = hum.WalkSpeed or services.starter_player.CharacterWalkSpeed
		pcall(function()
			stuff.default_jp = hum.JumpPower or services.starter_player.CharacterJumpPower
		end)
	end

	maid._cleaner = stuff.connect(services.run_service.Heartbeat, function()
		update_performance_stats()

		for name, task_data in pairs(maid._tasks) do
			if task_data.type == 'connection' then
				local conn = task_data.task
				if typeof(conn) == 'RBXScriptConnection' and not conn.Connected then
					maid._tasks[name] = nil
				end
			elseif task_data.type == 'instance' then
				local inst = task_data.task
				if typeof(inst) == 'Instance' and not inst.Parent then
					maid._tasks[name] = nil
				end
			end
		end
	end)

	maid.add('local_character_added', stuff.owner.CharacterAdded, function(character)
		stuff.owner_char = character

		local hum = character:WaitForChild('Humanoid', 10)
		if hum then
			stuff.default_ws = hum.WalkSpeed
			pcall(function()
				stuff.default_jp = hum.JumpPower
			end)
		end
	end, 1)

	maid.add('clean_highlights', services.run_service.Stepped, function()
		for plr, highlight in pairs(stuff.highlights) do
			if highlight and not (highlight.Adornee and highlight.Adornee:IsDescendantOf(workspace)) then
				pcall(stuff.destroy, highlight)
				stuff.highlights[plr] = nil
			end
		end
	end, 1)
end

local cmd_library = {
	_commands = {},
	_command_map = {},
	_plugins = {}
}

function cmd_library.parse_command(input)
	if type(input) ~= 'string' then return {} end

	local commands = {}
	for raw_cmd in input:gmatch('[^;]+') do
		raw_cmd = raw_cmd:match('^%s*(.-)%s*$')
		if raw_cmd ~= '' then
			local parts = {}
			for part in raw_cmd:gmatch('%S+') do
				parts[#parts + 1] = part
			end
			if #parts > 0 then
				local cmd = parts[1]
				table.remove(parts, 1)
				commands[#commands + 1] = {cmd = cmd, args = parts}
			end
		end
	end

	return commands
end

function cmd_library.add(names, description, args, fn)
	local primary_name = names[1]:lower()

	if cmd_library._command_map[primary_name] then
		return error(`command '{names[1]}' already exists`, 0)
	end

	local cmd_data = {
		names = names,
		description = description,
		args = args,
		fn = fn,
		variable_storage = {},
		plugin = nil,
		created_at = tick()
	}

	table.insert(cmd_library._commands, cmd_data)

	for _, name in names do
		cmd_library._command_map[name:lower()] = cmd_data
	end

	return cmd_data
end

function cmd_library.register_plugin(plugin_name, plugin_data)
	if cmd_library._plugins[plugin_name:lower()] then
		return nil, 'plugin already registered'
	end

	cmd_library._plugins[plugin_name:lower()] = {
		name = plugin_name,
		version = plugin_data.version or '1.0.0',
		author = plugin_data.author or 'unknown',
		description = plugin_data.description or '',
		commands = {},
		loaded = true,
		data = plugin_data.data or {}
	}

	notify('plugin', `plugin '{plugin_name}' registered`, 1)
	return cmd_library._plugins[plugin_name:lower()]
end

function cmd_library.add_plugin_command(plugin_name, names, description, args, fn)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		return nil, 'plugin not found'
	end

	local cmd_data = cmd_library.add(names, description, args, fn)
	if cmd_data then
		cmd_data.plugin = plugin_name
		table.insert(plugin.commands, {
			names = names,
			description = description,
			args = args
		})
	end

	return cmd_data
end

function cmd_library.get_plugins()
	local plugins = {}
	for name, plugin in pairs(cmd_library._plugins) do
		table.insert(plugins, {
			name = plugin.name,
			version = plugin.version,
			author = plugin.author,
			description = plugin.description,
			command_count = #plugin.commands,
			loaded = plugin.loaded
		})
	end
	return plugins
end

function cmd_library.remove_plugin(plugin_name)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		return false, 'plugin not found'
	end

	for i = #cmd_library._commands, 1, -1 do
		local cmd = cmd_library._commands[i]
		if cmd.plugin and cmd.plugin:lower() == plugin_name:lower() then
			for _, name in ipairs(cmd.names) do
				cmd_library._command_map[name:lower()] = nil
			end
			table.remove(cmd_library._commands, i)
		end
	end

	cmd_library._plugins[plugin_name:lower()] = nil
	notify('plugin', `plugin '{plugin_name}' removed`, 1)
	return true
end

function cmd_library.find(name)
	return cmd_library._command_map[name:lower()]
end

function cmd_library.remove(name)
	local cmd_data = cmd_library._command_map[name:lower()]
	if not cmd_data then return false end

	for _, cmd_name in cmd_data.names do
		cmd_library._command_map[cmd_name:lower()] = nil
	end

	for i, cmd in cmd_library._commands do
		if cmd == cmd_data then
			table.remove(cmd_library._commands, i)
			break
		end
	end

	return true
end

function cmd_library.get_variable_storage(name)
	local cmd_data = cmd_library._command_map[name:lower()]
	return cmd_data and cmd_data.variable_storage
end

function cmd_library.find_similar(name)
	local similar = {}
	local search = name:lower()

	for cmd_name in cmd_library._command_map do
		if cmd_name:sub(1, #search) == search then
			table.insert(similar, cmd_name)
		elseif cmd_name:find(search, 1, true) then
			table.insert(similar, cmd_name)
		end
	end

	return similar
end

function cmd_library.execute(name, ...)
	if not name or name == '' then
		notify('cmd', 'no command specified', 2)
		return false
	end

	local cmd_data = cmd_library._command_map[name:lower()]

	if not cmd_data then
		local similar = cmd_library.find_similar(name)
		if #similar > 0 then
			notify('cmd', `couldn't find '{name}'. did you mean: {table.concat(similar, ', ')}?`, 2)
		else
			notify('cmd', `couldn't find command '{name}'`, 2)
		end
		return false
	end

	local vargs = {...}
	local fvargs = {}

	local has_varargs = false
	local vararg_type = nil
	local vararg_start_idx = 1

	for i, arg_def in cmd_data.args do
		if type(arg_def) == 'table' and arg_def['...'] then
			has_varargs = true
			vararg_type = arg_def['...']
			vararg_start_idx = i
			break
		end
	end

	if has_varargs then
		for i = 1, vararg_start_idx - 1 do
			if vargs[i] then
				local arg_type = cmd_data.args[i] and cmd_data.args[i][2] or nil
				local converted = str_to_type(vargs[i], arg_type)
				table.insert(fvargs, converted)
			end
		end

		for i = vararg_start_idx, #vargs do
			local converted = str_to_type(vargs[i], vararg_type)
			table.insert(fvargs, converted)
		end
	else
		for i, arg in ipairs(vargs) do
			local arg_type = cmd_data.args[i] and cmd_data.args[i][2] or nil
			local converted = str_to_type(arg, arg_type)
			table.insert(fvargs, converted)
		end
	end

	task.spawn(function()
		local success, err = xpcall(function()
			cmd_data.fn(cmd_data.variable_storage, unpack(fvargs))
		end, function(msg)
			return debug.traceback(msg, 2)
		end)

		if not success then
			notify('cmd', `error in '{name}': {tostring(err):match("[^\n]*")}`, 2)
			warn(`command '{name}' failed:`, err)
		end
	end)

	return true
end

function cmd_library.clear()
	cmd_library._commands = {}
	cmd_library._command_map = {}
	cmd_library._plugins = {}
end

function cmd_library.help(name)
	if name then
		local cmd_data = cmd_library._command_map[name:lower()]
		if cmd_data then
			return {
				names = cmd_data.names,
				description = cmd_data.description,
				args = cmd_data.args,
				plugin = cmd_data.plugin
			}
		end
	else
		local help_list = {}
		for _, cmd in cmd_library._commands do
			table.insert(help_list, {
				names = cmd.names,
				description = cmd.description,
				args = cmd.args,
				plugin = cmd.plugin
			})
		end
		return help_list
	end
end

local config = {
	file_name = 'opadmin_settings.json',
	current_game_id = tostring(game.PlaceId),
	default_settings = {
		open_keybind = env['opadmin'].opadmin_open_keybind and env['opadmin'].opadmin_open_keybind.Name or "KeypadZero",
		chat_prefix = "!",
		aliases = {},
		binds = {},
		auto_plugins = {}
	},
	current_settings = {}
}

function config.load()
	if readfile and isfile then
		if isfile(config.file_name) then
			local success, result = pcall(function()
				return services.http:JSONDecode(readfile(config.file_name))
			end)

			if success and result then
				config.current_settings = result

				for key, default_value in pairs(config.default_settings) do
					if config.current_settings[key] == nil then
						config.current_settings[key] = default_value
					end
				end

				return true
			end
		end
	end

	config.current_settings = deep_copy(config.default_settings)
	return false
end

function config.save()
	if writefile then
		local success = pcall(function()
			writefile(config.file_name, services.http:JSONEncode(config.current_settings))
		end)
		return success
	end
	return false
end

function config.get(key)
	return config.current_settings[key]
end

function config.set(key, value)
	config.current_settings[key] = value
	return config.save()
end

function config.reset(key)
	if key then
		config.current_settings[key] = config.default_settings[key]
	else
		config.current_settings = deep_copy(config.default_settings)
	end
	return config.save()
end

function config.get_game_binds()
	local binds = config.get('binds') or {}
	if not binds[config.current_game_id] then
		binds[config.current_game_id] = {}
		config.set('binds', binds)
	end
	return binds[config.current_game_id]
end

function config.set_game_binds(game_binds)
	local binds = config.get('binds') or {}
	binds[config.current_game_id] = game_binds
	return config.set('binds', binds)
end

function config.apply()
	local settings = config.current_settings

	if settings.open_keybind then
		if settings.open_keybind:len() == 1 then
			settings.open_keybind = settings.open_keybind:upper()
		end
		stuff.open_keybind = Enum.KeyCode[settings.open_keybind] or Enum.KeyCode.Quote
	end

	if settings.chat_prefix then
		stuff.chat_prefix = settings.chat_prefix
	end

	if settings.aliases then
		for alias, command in pairs(settings.aliases) do
			local cmd_data = cmd_library._command_map[command:lower()]
			if cmd_data then
				table.insert(cmd_data.names, alias)
				cmd_library._command_map[alias:lower()] = cmd_data
			end
		end
	end

	local game_binds = config.get_game_binds()
	if game_binds then
		for bind_id, bind_data in pairs(game_binds) do
			local keycode = Enum.KeyCode[bind_data.key]
			if keycode and cmd_library._command_map[bind_data.command:lower()] then
				maid.add(bind_id, services.user_input_service.InputBegan, function(input, processed)
					if input.KeyCode == keycode and not processed then
						cmd_library.execute(bind_data.command, unpack(bind_data.args or {}))
					end
				end)
			end
		end
	end
end

config.load()
config.apply()

local hook_lib = {
	active_hooks = {},
	presets = {}
}

function hook_lib.create_hook(name, hooks)
	if hook_lib.active_hooks[name] then
		hook_lib.destroy_hook(name)
	end

	local hook_data = {
		hooks = {},
		enabled = true
	}

	if hooks.namecall and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_namecall = hookmetamethod(game, '__namecall', newcclosure(function(self, ...)
				if hook_data.enabled and checkcaller and not checkcaller() then
					local result = hooks.namecall(self, ...)
					if result ~= nil then
						return result
					end
				end
				return hook_data.hooks.old_namecall(self, ...)
			end))
		end)
	end

	if hooks.index and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_index = hookmetamethod(game, '__index', newcclosure(function(self, key)
				if hook_data.enabled and checkcaller and not checkcaller() then
					local result = hooks.index(self, key)
					if result ~= nil then
						return result
					end
				end
				return hook_data.hooks.old_index(self, key)
			end))
		end)
	end

	if hooks.newindex and hookmetamethod then
		pcall(function()
			hook_data.hooks.old_newindex = hookmetamethod(game, '__newindex', newcclosure(function(self, key, value)
				if hook_data.enabled and checkcaller and not checkcaller() then
					local result = hooks.newindex(self, key, value)
					if result == false then
						return
					end
				end
				return hook_data.hooks.old_newindex(self, key, value)
			end))
		end)
	end

	hook_lib.active_hooks[name] = hook_data
	return hook_data
end

function hook_lib.destroy_hook(name)
	local hook_data = hook_lib.active_hooks[name]
	if hook_data then
		hook_data.enabled = false
		hook_lib.active_hooks[name] = nil
	end
end

function hook_lib.toggle_hook(name, enabled)
	local hook_data = hook_lib.active_hooks[name]
	if hook_data then
		hook_data.enabled = enabled
	end
end

hook_lib.presets.antikick = function(player)
	return {
		namecall = function(self, ...)
			local method = getnamecallmethod()

			if self == player and (method == 'Kick' or method == 'Destroy' or method == 'Remove') then
				notify('antikick', `blocked {method} attempt`, 3)
				return nil
			end

			if self == services.teleport_service and (method == 'Teleport' or method == 'TeleportAsync') then
				notify('antikick', `blocked teleport attempt`, 3)
				return nil
			end
		end
	}
end

hook_lib.presets.freegamepass = function()
	return {
		namecall = function(self, ...)
			local method = getnamecallmethod()

			if self == services.marketplace_service then
				if method == 'UserOwnsGamePassAsync' or method == 'PlayerOwnsAsset' then
					return true
				end
			end

			if self:IsA('Player') then
				if method == 'IsInGroup' then
					return true
				elseif method == 'GetRankInGroup' then
					return 255
				end
			end
		end
	}
end

stuff.chat_prefix = config.get('chat_prefix') or '!'


-- c1: movement

cmd_library.add({'speed', 'walkspeed', 'ws'}, 'sets your walkspeed to [speed]', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, speed, bypass)
	speed = speed or stuff.default_ws
	notify('walkspeed', `walkspeed set to {speed}`, 1)

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('walkspeed_bypass', hook_lib.presets.property_spoof(humanoid, {WalkSpeed = humanoid.WalkSpeed}))
	end

	stuff.rawrbxset(stuff.owner_char.Humanoid, 'WalkSpeed', speed)
end)

cmd_library.add({'jumppower', 'jp'}, 'sets your jumppower to [power]', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, power, bypass)
	power = power or stuff.default_jp
	notify('jumppower', `jumppower set to {power}`, 1)

	local humanoid = stuff.owner_char.Humanoid

	if bypass then
		hook_lib.create_hook('jumppower_bypass', hook_lib.presets.property_spoof(humanoid, {
			JumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50,
			JumpHeight = not humanoid.UseJumpPower and humanoid.JumpHeight or 7.2,
			UseJumpPower = true
		}))
	end

	stuff.rawrbxset(humanoid, 'UseJumpPower', true)
	stuff.rawrbxset(humanoid, 'JumpPower', power)
end)

cmd_library.add({'loopjumppower', 'loopjp'}, 'sets your jumppower to [power] in a loop', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, power, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unloopjp')
		return
	end

	power = power or stuff.default_jp
	notify('loopjumppower', `looping jumppower set to {power}`, 1)

	vstorage.enabled = true
	vstorage.old_power = stuff.rawrbxget(stuff.owner_char.Humanoid, 'JumpPower')

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('loopjp_bypass', hook_lib.presets.property_spoof(humanoid, {
			JumpPower = humanoid.UseJumpPower and humanoid.JumpPower or 50,
			JumpHeight = not humanoid.UseJumpPower and humanoid.JumpHeight or 7.2,
			UseJumpPower = true
		}))
	end

	maid.add('loopjp', services.run_service.Heartbeat, function()
		local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		pcall(stuff.rawrbxset, hum, 'UseJumpPower', true)
		pcall(stuff.rawrbxset, hum, 'JumpPower', power)
	end)
end)

cmd_library.add({'unloopjumppower', 'unloopjp'}, 'disables loopjumppower', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopjumppower')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopjp')
		hook_lib.destroy_hook('loopjp_bypass')

		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'JumpPower', vstorage.old_power or stuff.default_jp)
		notify('loopjumppower', 'loop jumppower disabled', 1)
	else
		notify('loopjumppower', 'loop jumppower is already disabled', 2)
	end
end)

cmd_library.add({'loopwalkspeed', 'loopws'}, 'sets your walkspeed to [speed] in a loop', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unloopws')
		return
	end

	speed = speed or stuff.default_ws
	notify('loopwalkspeed', `looping walkspeed set to {speed}`, 1)

	vstorage.enabled = true
	vstorage.old_speed = stuff.rawrbxget(stuff.owner_char.Humanoid, 'WalkSpeed')

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		hook_lib.create_hook('loopws_bypass', hook_lib.presets.property_spoof(humanoid, {WalkSpeed = vstorage.old_speed}))
	end

	maid.add('loopws', services.run_service.Heartbeat, function()
		pcall(stuff.rawrbxset, stuff.rawrbxget(stuff.owner_char, 'Humanoid'), 'WalkSpeed', speed)
	end)
end)

cmd_library.add({'unloopwalkspeed', 'unloopws'}, 'disables loopwalkspeed', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopwalkspeed')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopws')
		hook_lib.destroy_hook('loopws_bypass')

		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'WalkSpeed', vstorage.old_speed or stuff.default_ws)
		notify('loopwalkspeed', 'loop walkspeed disabled', 1)
	else
		notify('loopwalkspeed', 'loop walkspeed is already disabled', 2)
	end
end)

cmd_library.add({'fly', 'cframefly'}, 'enable flight', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if speed == nil then
		speed = 1
	end

	if vstorage.enabled and vstorage.speed == speed then
		if et then
			cmd_library.execute('unfly')
			return
		else
			return notify('fly', 'already flying', 2)
		end
	end

	vstorage.enabled = true
	vstorage.speed = speed or 1
	notify('fly', `enabled flight{vstorage.speed ~= 1 and ` with speed {vstorage.speed}` or ''}`, 1)

	local flight_part = Instance.new('Part', workspace)
	vstorage.part = flight_part

	stuff.rawrbxset(flight_part, 'CFrame', stuff.owner_char:GetPivot())
	stuff.rawrbxset(flight_part, 'Anchored', true)
	stuff.rawrbxset(flight_part, 'Transparency', 1)
	stuff.rawrbxset(flight_part, 'CanCollide', false)

	if bypass then
		local humanoid = stuff.owner_char.Humanoid
		local hrp = stuff.owner_char.HumanoidRootPart

		hook_lib.create_hook('fly_bypass', {
			namecall = function(self, ...)
				local method = getnamecallmethod()
				if self == humanoid then
					if method == 'GetState' then
						return Enum.HumanoidStateType.Running
					elseif method == 'ChangeState' then
						local args = {...}
						if args[1] ~= Enum.HumanoidStateType.Running then
							return nil
						end
					end
				end
			end,
			index = function(self, key)
				if self == hrp and key == 'Velocity' then
					return Vector3.zero
				end
			end
		})
	end

	maid.add('flight', services.run_service.Heartbeat, function()
		pcall(function()
			local old_pos = stuff.rawrbxget(flight_part, 'Position')
			local cam_cframe = stuff.rawrbxget(workspace.CurrentCamera, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', CFrame.lookAt(old_pos, cam_cframe * CFrame.new(0, 0, -250).Position))

			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
			stuff.owner_char:PivotTo(stuff.rawrbxget(flight_part, 'CFrame'))

			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.zero)

			local offset = get_move_vector(vstorage.speed)
			local current_cf = stuff.rawrbxget(flight_part, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', current_cf * CFrame.new(offset))
		end)
	end)
end)

cmd_library.add({'unfly', 'disablefly', 'stopfly'}, 'disable flight', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('fly')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('flight')
		hook_lib.destroy_hook('fly_bypass')

		if vstorage.part then
			pcall(stuff.destroy, vstorage.part)
			vstorage.part = nil
		end

		notify('fly', 'disabled flight', 1)
	else
		notify('fly', 'flight is already disabled', 2)
	end
end)

cmd_library.add({'vehiclecontrol', 'vcontrol', 'vctrl', 'carcontrol'}, 'gives you more control over vehicles (modes = speed, flight)', {
	{'mode', 'string'},
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, mode, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unvehiclecontrol')
		return
	end

	if vstorage.enabled then
		return notify('vehiclecontrol', 'vehicle control already enabled', 2)
	end

	local valid_modes = {'speed', 'flight'}
	mode = mode and mode:lower() or 'speed'

	if not table.find(valid_modes, mode) then
		return notify('vehiclecontrol', `invalid mode '{mode}'. valid modes: {table.concat(valid_modes, ', ')}`, 2)
	end

	vstorage.enabled = true
	vstorage.mode = mode
	vstorage.accel_mult = math.clamp((speed or 25) / 1000, 0.001, 0.09)
	vstorage.brake_mult = 0.15
	vstorage.flight_speed = speed or 3
	vstorage.max_velocity = 500

	notify('vehiclecontrol', `vehicle control enabled | mode: {vstorage.mode} | speed: {vstorage.mode == 'velocity' and vstorage.accel_mult * 1000 or vstorage.flight_speed}`, 1)

	local character = stuff.owner.Character
	if not character then
		return notify('vehiclecontrol', 'character not found', 2)
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		return notify('vehiclecontrol', 'humanoid not found', 2)
	end

	local function get_vehicle_from_seat(seat)
		return seat:FindFirstAncestorWhichIsA('Model')
	end

	if vstorage.mode == 'speed' then
		maid.add('vehiclecontrol_accel', services.run_service.Heartbeat, function()
			local seat_part = stuff.rawrbxget(humanoid, 'SeatPart')
			if not seat_part or not seat_part:IsA('VehicleSeat') then return end

			local move_vector = get_move_vector(1)
			local current_velocity = stuff.rawrbxget(seat_part, 'AssemblyLinearVelocity')
			local current_speed = current_velocity.Magnitude

			if move_vector.Z < 0 then
				if current_speed < vstorage.max_velocity then
					stuff.rawrbxset(seat_part, 'AssemblyLinearVelocity', current_velocity * Vector3.new(1 + vstorage.accel_mult, 1, 1 + vstorage.accel_mult))
				end
			elseif move_vector.Z > 0 then
				stuff.rawrbxset(seat_part, 'AssemblyLinearVelocity', current_velocity * Vector3.new(1 - vstorage.brake_mult, 1, 1 - vstorage.brake_mult))
			end
		end)

		maid.add('vehiclecontrol_stop', services.user_input_service.InputBegan, function(input, processed)
			if processed then return end
			if input.KeyCode == Enum.KeyCode.X then
				local seat_part = stuff.rawrbxget(humanoid, 'SeatPart')
				if seat_part and seat_part:IsA('VehicleSeat') then
					stuff.rawrbxset(seat_part, 'AssemblyLinearVelocity', Vector3.zero)
					stuff.rawrbxset(seat_part, 'AssemblyAngularVelocity', Vector3.zero)
					notify('vehiclecontrol', 'vehicle stopped', 3)
				end
			end
		end)

	elseif vstorage.mode == 'flight' then
		maid.add('vehiclecontrol_flight', services.run_service.Stepped, function()
			local seat_part = stuff.rawrbxget(humanoid, 'SeatPart')
			if not seat_part or not seat_part:IsA('VehicleSeat') then return end

			local vehicle = get_vehicle_from_seat(seat_part)
			if not vehicle then return end

			stuff.rawrbxset(character, 'Parent', vehicle)

			if not vehicle.PrimaryPart then
				if seat_part.Parent == vehicle then
					vehicle.PrimaryPart = seat_part
				else
					vehicle.PrimaryPart = vehicle:FindFirstChildWhichIsA('BasePart')
				end
			end

			local primary_cf = vehicle:GetPrimaryPartCFrame()
			local camera = stuff.rawrbxget(workspace, 'CurrentCamera')
			local camera_cf = stuff.rawrbxget(camera, 'CFrame')
			local move_vector = get_move_vector(vstorage.flight_speed)

			local new_cf = CFrame.new(primary_cf.Position, primary_cf.Position + camera_cf.LookVector) * 
				CFrame.new(move_vector.X, (services.user_input_service:IsKeyDown(Enum.KeyCode.E) and vstorage.flight_speed / 2) or 
					(services.user_input_service:IsKeyDown(Enum.KeyCode.Q) and -vstorage.flight_speed / 2) or 0, move_vector.Z)

			vehicle:SetPrimaryPartCFrame(new_cf)
			stuff.rawrbxset(seat_part, 'AssemblyLinearVelocity', Vector3.zero)
			stuff.rawrbxset(seat_part, 'AssemblyAngularVelocity', Vector3.zero)
		end)
	end

	local reset_triggered = false

	maid.add('vehiclecontrol_died', humanoid.Died, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('unvehiclecontrol')
	end)

	maid.add('vehiclecontrol_char_added', stuff.owner.CharacterAdded, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('unvehiclecontrol')
	end)
end)

cmd_library.add({'unvehiclecontrol', 'unvcontrol', 'unvctrl'}, 'disables vehicle control', {}, function(vstorage)
	local vehiclecontrol_vs = cmd_library.get_variable_storage('vehiclecontrol')

	if not vehiclecontrol_vs or not vehiclecontrol_vs.enabled then
		return notify('vehiclecontrol', 'vehicle control not enabled', 2)
	end

	vehiclecontrol_vs.enabled = false

	maid.remove('vehiclecontrol_accel')
	maid.remove('vehiclecontrol_stop')
	maid.remove('vehiclecontrol_flight')
	maid.remove('vehiclecontrol_died')
	maid.remove('vehiclecontrol_char_added')

	local character = stuff.owner.Character
	if character then
		stuff.rawrbxset(character, 'Parent', workspace)
	end

	notify('vehiclecontrol', 'vehicle control disabled', 1)
end)

cmd_library.add({'bfly', 'bypassfly'}, 'bypass flight', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unbypassfly')
		return
	end

	local fly_vstorage = cmd_library.get_variable_storage('fly')
	if fly_vstorage.enabled then
		return notify('bfly', 'disable normal fly first', 2)
	end

	if vstorage.enabled then
		return notify('bfly', 'bypass flight already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 1
	vstorage.bypass = bypass
	notify('bfly', `bypass flight enabled{bypass and ' (hook bypass)' or ''} | when disabled you will teleport to the part`, 1)

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	vstorage.old_subject = stuff.rawrbxget(cam, 'CameraSubject')

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	vstorage.old_speed = stuff.rawrbxget(humanoid, 'WalkSpeed')

	local flight_part = Instance.new('Part', workspace)
	vstorage.part = flight_part
	vstorage.old_parent = stuff.rawrbxget(stuff.owner_char, 'Parent')

	stuff.rawrbxset(stuff.owner_char, 'Parent', nil)
	stuff.rawrbxset(flight_part, 'CFrame', stuff.owner_char:GetPivot())
	stuff.rawrbxset(flight_part, 'Anchored', true)
	stuff.rawrbxset(flight_part, 'Transparency', 0.5)
	stuff.rawrbxset(flight_part, 'CanCollide', false)
	stuff.rawrbxset(cam, 'CameraSubject', flight_part)

	if bypass then
		local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')

		hook_lib.create_hook('bfly_bypass', {
			index = function(self, key)
				if self == stuff.owner_char and key == 'Parent' then
					return vstorage.old_parent or workspace
				end

				if self == cam and key == 'CameraSubject' then
					return vstorage.old_subject or humanoid
				end

				if self == flight_part then
					if key == 'Parent' then
						return nil
					end
				end

				if self == hrp then
					if key == 'Position' or key == 'position' then
						return stuff.rawrbxget(flight_part, 'Position')
					elseif key == 'CFrame' or key == 'cframe' then
						return stuff.rawrbxget(flight_part, 'CFrame')
					elseif key == 'Velocity' or key == 'velocity' then
						return Vector3.zero
					elseif key == 'AssemblyLinearVelocity' then
						return Vector3.zero
					end
				end

				if self == humanoid then
					if key == 'FloorMaterial' then
						return Enum.Material.Plastic
					elseif key == 'Jump' then
						return false
					end
				end
			end,

			newindex = function(self, key, value)
				if self == stuff.owner_char and key == 'Parent' then
					if value ~= nil then
						return false
					end
				end

				if self == cam and key == 'CameraSubject' then
					if value ~= flight_part then
						return false
					end
				end

				if self == flight_part then
					if key == 'Parent' and value == nil then
						return false
					end
					if key == 'CFrame' or key == 'Position' then
						return false
					end
				end
			end,

			namecall = function(self, ...)
				local method = getnamecallmethod()
				local args = {...}

				if self == stuff.owner_char then
					if method == 'GetPivot' then
						return stuff.rawrbxget(flight_part, 'CFrame')
					elseif method == 'IsDescendantOf' or method == 'IsAncestorOf' then
						if args[1] == workspace or args[1] == game then
							return true
						end
					end
				end

				if self == hrp then
					if method == 'GetPropertyChangedSignal' then
						if args[1] == 'Position' or args[1] == 'CFrame' or args[1] == 'Velocity' then
							return Instance.new('BindableEvent').Event
						end
					end
				end

				if self == workspace then
					if method == 'FindFirstChild' or method == 'FindFirstChildOfClass' or method == 'FindFirstChildWhichIsA' then
						if args[1] == flight_part.Name or flight_part:IsA(args[1] or '') then
							return nil
						end
					end
				end
			end
		})

		if hookfunction then
			vstorage.get_descendants_hook = hookfunction(game.GetDescendants, function(self)
				if vstorage.enabled and self == workspace then
					local descendants = game.GetDescendants(self)
					local filtered = {}
					for _, descendant in descendants do
						if descendant ~= flight_part then
							table.insert(filtered, descendant)
						end
					end
					return filtered
				end
				return game.GetDescendants(self)
			end)

			vstorage.get_children_hook = hookfunction(game.GetChildren, function(self)
				if vstorage.enabled and self == workspace then
					local children = game.GetChildren(self)
					local filtered = {}
					for _, child in children do
						if child ~= flight_part then
							table.insert(filtered, child)
						end
					end
					return filtered
				end
				return game.GetChildren(self)
			end)
		end
	end

	maid.add('bypassfly_connection', services.run_service.Heartbeat, function()
		pcall(function()
			local old_pos = stuff.rawrbxget(flight_part, 'Position')
			local cam_cframe = stuff.rawrbxget(cam, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', CFrame.lookAt(old_pos, cam_cframe * CFrame.new(0, 0, -250).Position))

			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.zero)

			local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			hum:ChangeState(Enum.HumanoidStateType.Running)

			local offset = get_move_vector(vstorage.speed)
			local current_cf = stuff.rawrbxget(flight_part, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', current_cf * CFrame.new(offset))
		end)
	end)
end)

cmd_library.add({'unbfly', 'disablebfly', 'stopbfly', 'unbypassfly'}, 'disable bypass flight', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('bfly')

	if not vstorage.enabled then
		return notify('bfly', 'bypass flight is already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('bypassfly_connection')

	if vstorage.bypass then
		hook_lib.destroy_hook('bfly_bypass')

		if vstorage.get_descendants_hook then
			vstorage.get_descendants_hook = nil
		end
		if vstorage.get_children_hook then
			vstorage.get_children_hook = nil
		end
	end

	if vstorage.part then
		maid.add('bfly_slop', services.run_service.Heartbeat, function()
			stuff.rawrbxset(stuff.owner_char, 'Parent', vstorage.old_parent)
			stuff.owner_char:PivotTo(stuff.rawrbxget(vstorage.part, 'CFrame'))
		end)
		task.delay(0.5, function()
			maid.remove('bfly_slop')
			pcall(stuff.destroy, vstorage.part)
			vstorage.part = nil
		end)
	end

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	stuff.rawrbxset(cam, 'CameraType', Enum.CameraType.Custom)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'WalkSpeed', vstorage.old_speed or stuff.default_ws)
	stuff.rawrbxset(cam, 'CameraSubject', vstorage.old_subject or humanoid)

	notify('bfly', 'disabled bypass flight', 1)
end)

cmd_library.add({'airwalk', 'airw', 'float'}, 'turns on airwalk', {
	{'height', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, height, et)
	if et and vstorage.enabled then
		cmd_library.execute('unairwalk')
		return
	end

	if vstorage.enabled then
		return notify('airwalk', 'airwalk already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.height = height or -4
	vstorage.height_offset = 0
	notify('airwalk', 'enabled airwalk | Q/E: down/up, R: reset offset', 1)

	local air_walk_part = Instance.new('Part', workspace)
	stuff.rawrbxset(air_walk_part, 'Size', Vector3.new(7, 2, 3))
	stuff.rawrbxset(air_walk_part, 'Transparency', 1)
	stuff.rawrbxset(air_walk_part, 'Anchored', true)
	stuff.rawrbxset(air_walk_part, 'CanCollide', true)
	stuff.rawrbxset(air_walk_part, 'Name', tostring(services.http:GenerateGUID()))
	vstorage.air_walk_part = air_walk_part

	maid.add('airwalk_input', services.user_input_service.InputBegan, function(input, processed)
		if processed then return end

		if input.KeyCode == Enum.KeyCode.E then
			vstorage.height_offset = vstorage.height_offset + 0.125
		elseif input.KeyCode == Enum.KeyCode.Q then
			vstorage.height_offset = vstorage.height_offset - 0.125
		elseif input.KeyCode == Enum.KeyCode.R then
			vstorage.height_offset = 0
		end
	end)
	task.spawn(function()
		repeat
			task.wait(1/120)
			pcall(function()
				local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
				local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
				stuff.rawrbxset(air_walk_part, 'CFrame', hrp_cf + Vector3.new(0, vstorage.height + vstorage.height_offset, 0))
			end)
		until vstorage.enabled == false or vstorage.air_walk_part == nil or vstorage.air_walk_part:IsDescendantOf(game) == false
		if vstorage.air_walk_part == nil and vstorage.enabled == true or vstorage.air_walk_part:IsDescendantOf(game) == false and vstorage.enabled == true then
			cmd_library.execute("unairwalk")
		end
		maid.remove('air_walk')
		maid.remove('airwalk_input')
		pcall(stuff.destroy, air_walk_part)
		vstorage.air_walk_part = nil
		vstorage.enabled = false
	end)

	maid.add('airwalk_died', stuff.owner_char.Humanoid.Died, function()
		cmd_library.execute('unairwalk')
	end)

	maid.add('airwalk_char_added', stuff.owner.CharacterAdded, function()
		if vstorage.enabled then
			cmd_library.execute('unairwalk')
		end
	end)
end)

cmd_library.add({'unairwalk', 'unairw', 'unfloat'}, 'turns off airwalk', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('airwalk')

	if not vstorage.enabled then
		return notify('airwalk', 'airwalk is already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('airwalk_input')
	maid.remove('airwalk_died')
	maid.remove('airwalk_char_added')

	if vstorage.air_walk_part then
		pcall(stuff.destroy, vstorage.air_walk_part)
		vstorage.air_walk_part = nil
	end

	notify('airwalk', 'disabled airwalk', 1)
end)

cmd_library.add({'to', 'goto'}, 'teleport infront of the target', {
	{'player', 'player'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, targets, bypass)
	if not targets or #targets == 0 then
		return notify('goto', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		local target_char = target.Character
		if not target_char or not target_char:FindFirstChild('HumanoidRootPart') then
			notify('goto', `player {target.Name} does not have a rootpart | skipping`, 3)
			continue
		end

		if bypass then
			local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if hrp then
				local hrp_cframe = hrp.CFrame
				local target_hrp = stuff.rawrbxget(target_char, 'HumanoidRootPart')
				local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')

				hook_lib.create_hook('goto_bypass', {
					newindex = function(self, key, value)
						if self == hrp and (key == 'CFrame' or key == 'Position') then
							return false
						end
					end,
					index = function(self, key)
						if self == hrp and key == 'CFrame' then
							return hrp_cframe
						elseif self == hrp and key == 'Position' then
							return hrp_cframe.Position
						end
					end
				})

				stuff.owner_char:PivotTo(target_cf * CFrame.new(0, 3, -3))

				task.wait(0.1)
				hook_lib.destroy_hook('goto_bypass')
			end
		else
			local target_hrp = stuff.rawrbxget(target_char, 'HumanoidRootPart')
			local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
			stuff.owner_char:PivotTo(target_cf * CFrame.new(0, 3, -3))
		end

		notify('goto', `teleported to {target.Name}`, 1)
	end
end)

cmd_library.add({'follow', 'chase'}, 'lock onto another player instantly', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('follow', 'target not found', 2)
	end

	local target = targets[1]

	if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
		return notify('follow', 'target does not have a character', 2)
	end

	if vstorage.target then
		return notify('follow', `already following {vstorage.target.Name}, use 'unfollow' first`, 2)
	end

	vstorage.target = target
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')

	maid.add('follow_connection', services.run_service.RenderStepped, function()
		if not vstorage.target or not vstorage.target.Character or not vstorage.target.Character:FindFirstChild('HumanoidRootPart') then
			return
		end

		pcall(function()
			local target_hrp = stuff.rawrbxget(vstorage.target.Character, 'HumanoidRootPart')
			local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')

			stuff.rawrbxset(hrp, 'CFrame', target_cf)
			stuff.rawrbxset(hrp, 'Velocity', Vector3.zero)
			stuff.rawrbxset(hrp, 'RotVelocity', Vector3.zero)
		end)
	end)

	notify('follow', `now following {target.Name}`, 1)
end)

cmd_library.add({'unfollow', 'stopfollow'}, 'stop following', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('follow')

	if vstorage.target then
		maid.remove('follow_connection')
		notify('follow', `stopped following {vstorage.target.Name}`, 1)
		vstorage.target = nil
	else
		notify('follow', 'you are not following anyone', 2)
	end
end)

cmd_library.add({'infjump', 'infinitejump'}, 'infinite jump', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('uninfjump')
		return
	end
	if vstorage.enabled then
		return notify('infjump', 'infinite jump already enabled', 2)
	end

	vstorage.enabled = true
	notify('infjump', 'enabled infinite jump', 1)

	local cooldown = false
	pcall(function()
		maid.remove('infinite_jump')
	end)

	maid.add('infinite_jump', services.user_input_service.JumpRequest, function()
		if cooldown == true then return end
		local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		cooldown = true

		task.delay(0.3, function()
			cooldown = false
		end)

		if stuff.rawrbxget(hum, 'FloorMaterial') == Enum.Material.Air then
			maid.add("current_spam_running_state",game:GetService("RunService").Heartbeat,function()
				hum:ChangeState(Enum.HumanoidStateType.Running)
			end)
			task.delay(0.025,function()
				maid.remove("current_spam_running_state")
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end)
		end
	end)
end)

cmd_library.add({'uninfjump', 'uninfinitejump'}, 'disable infinite jump', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('infjump')

	if not vstorage.enabled then
		return notify('infjump', 'infinite jump already disabled', 2)
	end

	vstorage.enabled = false
	notify('infjump', 'disabled infinite jump', 1)
	maid.remove('infinite_jump')
end)

cmd_library.add({'swim', 'swimmode'}, 'swim in the air', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)

	if et and vstorage.enabled then
		cmd_library.execute('unswim')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('swim', 'swim is already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or stuff.default_ws
	notify('swim', 'enabled swim', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local old_gravity = stuff.rawrbxget(workspace, 'Gravity')
	vstorage.old_gravity = old_gravity
	stuff.rawrbxset(workspace, 'Gravity', old_gravity / 10)

	local states = {
		Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
		Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
		Enum.HumanoidStateType.Swimming
	}

	for _, state in pairs(states) do
		humanoid:SetStateEnabled(state, false)
	end

	humanoid:ChangeState(Enum.HumanoidStateType.Swimming)

	vstorage.old_speed = stuff.rawrbxget(humanoid, 'WalkSpeed')
	stuff.rawrbxset(humanoid, 'WalkSpeed', vstorage.speed)
end)

cmd_library.add({'unswim', 'unswimmode', 'stopswim'}, 'stop swimming in the air', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('swim')

	if not vstorage.enabled then
		return notify('swim', 'swim is already disabled', 2)
	end

	vstorage.enabled = false
	notify('swim', 'disabled swim', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(workspace, 'Gravity', vstorage.old_gravity or 196.2)

	local states = {
		Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.FallingDown,
		Enum.HumanoidStateType.Flying, Enum.HumanoidStateType.Freefall,
		Enum.HumanoidStateType.GettingUp, Enum.HumanoidStateType.Jumping,
		Enum.HumanoidStateType.Landed, Enum.HumanoidStateType.Physics,
		Enum.HumanoidStateType.PlatformStanding, Enum.HumanoidStateType.Ragdoll,
		Enum.HumanoidStateType.Running, Enum.HumanoidStateType.RunningNoPhysics,
		Enum.HumanoidStateType.Seated, Enum.HumanoidStateType.StrafingNoPhysics,
		Enum.HumanoidStateType.Swimming
	}

	for _, state in pairs(states) do
		humanoid:SetStateEnabled(state, true)
	end

	humanoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)

	if vstorage.old_speed then
		stuff.rawrbxset(humanoid, 'WalkSpeed', vstorage.old_speed)
	end
end)

cmd_library.add({'orbit'}, 'orbit around a player', {
	{'player', 'player'},
	{'distance', 'number'},
	{'speed', 'number'}
}, function(vstorage, targets, distance, speed)
	if not targets or #targets == 0 then
		return notify('orbit', 'player not found', 2)
	end

	local target = targets[1]
	if vstorage.target then
		return notify('orbit', `already orbiting {vstorage.target.Name}, use unorbit first`, 2)
	end

	vstorage.target = target
	vstorage.distance = distance or 10
	vstorage.speed = speed or 2
	vstorage.angle = 0

	notify('orbit', `now orbiting {target.Name}`, 1)

	maid.add('orbit_connection', services.run_service.Heartbeat, function(dt)
		pcall(function()
			if vstorage.target and vstorage.target.Character and vstorage.target.Character:FindFirstChild('HumanoidRootPart') then
				vstorage.angle = (vstorage.angle + dt * vstorage.speed) % (2 * math.pi)
				local offset = CFrame.Angles(0, vstorage.angle, 0) * CFrame.new(0, 0, vstorage.distance)
				local target_hrp = stuff.rawrbxget(vstorage.target.Character, 'HumanoidRootPart')
				local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
				stuff.owner_char:PivotTo(target_cf * offset)
			end
		end)
	end)
end)

cmd_library.add({'unorbit'}, 'stop orbiting', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('orbit')

	if vstorage.target then
		notify('orbit', `stopped orbiting {vstorage.target.Name}`, 1)
		vstorage.target = nil
		maid.remove('orbit_connection')
	else
		notify('orbit', 'you are not orbiting anyone', 2)
	end
end)

cmd_library.add({'tpwalk', 'teleportwalk'}, 'teleport when walking', {
	{'multiplier', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, multiplier, et)
	if et and vstorage.enabled then
		cmd_library.execute('untpwalk')
		return
	end

	if vstorage.enabled then
		return notify('tpwalk', 'tpwalk already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.multiplier = multiplier or 3
	vstorage.last_tp = 0
	vstorage.next_delay = math.random(10, 100) / 100
	notify('tpwalk', `tpwalk enabled with multiplier {vstorage.multiplier}`, 1)

	pcall(function()
		maid.remove('tpwalk')
	end)

	maid.add('tpwalk', services.run_service.Heartbeat, function()
		pcall(function()
			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			local move_direction = stuff.rawrbxget(humanoid, 'MoveDirection')

			if move_direction.Magnitude > 0 then
				local current_time = os.clock()

				if current_time - vstorage.last_tp >= vstorage.next_delay then
					stuff.owner_char:TranslateBy(move_direction * vstorage.multiplier)
					vstorage.last_tp = current_time
					vstorage.next_delay = math.random(10, 80) / 100
				end
			end
		end)
	end)
end)

cmd_library.add({'untpwalk', 'unteleportwalk'}, 'disables tpwalk', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('tpwalk')

	if not vstorage.enabled then
		return notify('tpwalk', 'tpwalk not enabled', 2)
	end

	vstorage.enabled = false
	notify('tpwalk', 'tpwalk disabled', 1)
	maid.remove('tpwalk')
end)

cmd_library.add({'tpcoords', 'tpc'}, 'teleport to coordinates', {
	{'x', 'number'},
	{'y', 'number'},
	{'z', 'number'}
}, function(vstorage, x, y, z_coord)
	x = x or 0
	y = y or 0
	z_coord = z_coord or 0

	notify('tpcoords', `teleporting to {x}, {y}, {z_coord}`, 1)
	stuff.owner_char:PivotTo(CFrame.new(x, y, z_coord))
end)

cmd_library.add({'walkto', 'pathfind'}, 'walks to a player', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('walkto', 'player not found', 2)
	end

	local target = targets[1]
	if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
		return notify('walkto', `{target.Name} has no character`, 2)
	end

	notify('walkto', `walking to {target.Name}`, 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local target_hrp = stuff.rawrbxget(target.Character, 'HumanoidRootPart')
	local target_pos = stuff.rawrbxget(target_hrp, 'Position')
	humanoid:MoveTo(target_pos)
end)

cmd_library.add({'stopwalkto', 'stoppath'}, 'stops walking', {}, function(vstorage)
	notify('walkto', 'stopped walking', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local hrp_pos = stuff.rawrbxget(hrp, 'Position')
	humanoid:MoveTo(hrp_pos)
end)

cmd_library.add({'cframespeed', 'cfspeed', 'cfws'}, 'speeds you up without changing the walkspeed', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('uncframespeed')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('cframespeed', 'cframe speed already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 2
	vstorage.bypass = bypass
	notify('cframespeed', `cframe speed enabled with speed {vstorage.speed}{bypass and ' (bypass)' or ''}`, 1)

	pcall(maid.remove, 'cframe_speed')

	local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
	local hrp_cframe = stuff.rawrbxget(hrp, 'CFrame')

	if bypass then
		if hrp then
			hook_lib.create_hook('cframespeed_bypass', {
				newindex = function(self, key, value)
					if self == hrp and (key == 'CFrame' or key == 'Position') then
						return false
					end
				end,
				index = function(self, key)
					if self == hrp and key == 'CFrame' then
						return hrp_cframe
					elseif self == hrp and key == 'Position' then
						return hrp_cframe.Position
					end
				end
			})
		end
	end

	maid.add('cframe_speed', services.run_service.Heartbeat, function()
		pcall(function()
			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			local move_direction = stuff.rawrbxget(humanoid, 'MoveDirection')

			if move_direction.Magnitude > 0 then
				local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
				local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
				stuff.rawrbxset(hrp, 'CFrame', hrp_cf + move_direction * vstorage.speed)
			end
		end)
	end)
end)

cmd_library.add({'uncframespeed', 'uncfspeed', 'uncfws'}, 'stop cframe speed', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('cframespeed')

	if not vstorage.enabled then
		return notify('cframespeed', 'cframe speed already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('cframe_speed')

	if vstorage.bypass then
		hook_lib.destroy_hook('cframespeed_bypass')
	end

	notify('cframespeed', 'cframe speed disabled', 1)
end)

-- c2: utility

cmd_library.add({'pluginload', 'pload'}, 'load a plugin from url', {
	{'url', 'string'}
}, function(vars, url)
	local success, content = pcall(function()
		return game:HttpGet(url, true)
	end)

	if not success then
		notify('plugin', `failed to fetch plugin from url: {content}`, 2)
		return
	end

	local success2, plugin_module = pcall(loadstring, content)
	if not success2 then
		notify('plugin', `failed to load plugin script: {plugin_module}`, 2)
		return
	end

	local success3, plugin_data = pcall(plugin_module)
	if not success3 then
		notify('plugin', `plugin execution error: {plugin_data}`, 2)
		return
	end

	if type(plugin_data) ~= 'table' then
		notify('plugin', 'plugin must return a table', 2)
		return
	end

	if not plugin_data.name then
		notify('plugin', 'plugin missing name field', 2)
		return
	end

	if not plugin_data.init or type(plugin_data.init) ~= 'function' then
		notify('plugin', 'plugin missing init function', 2)
		return
	end

	local plugin, err = cmd_library.register_plugin(plugin_data.name, {
		version = plugin_data.version,
		author = plugin_data.author,
		description = plugin_data.description,
		data = plugin_data
	})

	if not plugin then
		notify('plugin', `failed to register plugin: {err}`, 2)
		return
	end

	local success4, err2 = pcall(plugin_data.init, {
		add_command = function(names, description, args, fn)
			return cmd_library.add_plugin_command(plugin_data.name, names, description, args, fn)
		end,
		notify = notify,
		get_maid = function() return maid end,
		get_stuff = function() return stuff end,
		get_cmd_library = function() return cmd_library end,
		config = config
	})

	if not success4 then
		cmd_library.remove_plugin(plugin_data.name)
		notify('plugin', `plugin initialization failed: {err2}`, 2)
		return
	end

	notify('plugin', `plugin '{plugin_data.name}' loaded successfully`, 1)

	local auto_plugins = config.get('auto_plugins') or {}
	auto_plugins[plugin_data.name] = url
	config.set('auto_plugins', auto_plugins)
end)

cmd_library.add({'pluginunload', 'punload'}, 'unload a plugin', {
	{'plugin_name', 'string'}
}, function(vars, plugin_name)
	local success, err = cmd_library.remove_plugin(plugin_name)
	if success then
		notify('plugin', `plugin '{plugin_name}' unloaded`, 1)

		local auto_plugins = config.get('auto_plugins') or {}
		auto_plugins[plugin_name] = nil
		config.set('auto_plugins', auto_plugins)
	else
		notify('plugin', `failed to unload plugin: {err}`, 2)
	end
end)

cmd_library.add({'pluginreload', 'preload'}, 'reload a plugin', {
	{'plugin_name', 'string'}
}, function(vars, plugin_name)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		notify('plugin', `plugin '{plugin_name}' not found`, 2)
		return
	end

	local url = nil
	local auto_plugins = config.get('auto_plugins') or {}
	url = auto_plugins[plugin_name]

	if not url then
		notify('plugin', `no url saved for plugin '{plugin_name}'. use pluginload instead.`, 3)
		return
	end

	cmd_library.remove_plugin(plugin_name)
	cmd_library.execute('pluginload', url)
end)

cmd_library.add({'plugininfo', 'pinfo'}, 'show plugin information', {
	{'plugin_name', 'string'}
}, function(vars, plugin_name)
	local plugin = cmd_library._plugins[plugin_name:lower()]
	if not plugin then
		notify('plugin', `plugin '{plugin_name}' not found`, 2)
		return
	end

	notify('plugin', `{plugin.name} (v{plugin.version}, by {plugin.author}) loaded {#plugin.commands} commands`, 4)
	if plugin.description and plugin.description ~= '' then
		notify(plugin.name, plugin.description, 1)
	end

	if #plugin.commands > 0 then
		notify('plugin', 'command list:', 4)
		for _, cmd in plugin.commands do
			notify('plugin', `{table.concat(cmd.names, ', ')} - {cmd.description}`, 1)
		end
	end
end)

cmd_library.add({'freemouse'}, 'unlocks your mouse cursor', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('freemouse', 'free mouse enabled', 1)

		maid.add('freemouse', services.run_service.RenderStepped, function()
			services.user_input_service.MouseBehavior = Enum.MouseBehavior.Default
		end)
	else
		notify('freemouse', 'free mouse disabled', 1)
		maid.remove('freemouse')
	end
end)

cmd_library.add({'fpscap', 'maxfps', 'unlockfps'}, 'sets fps cap', {
	{'fps', 'number'}
}, function(vstorage, fps)
	fps = fps or 999

	if setfpscap then
		setfpscap(fps)
		notify('fpscap', `fps cap set to {fps}`, 1)
	elseif setfps then
		setfps(fps)
		notify('fpscap', `fps cap set to {fps}`, 1)
	else
		notify('fpscap', 'executor does not support fps cap', 2)
	end
end)

cmd_library.add({'interact', 'touchnearby', 'autocollect'}, 'automatically interacts with nearby items', {
	{'range', 'number'},
	{'filter', 'string'}
}, function(vstorage, range, filter)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		vstorage.range = range or 50
		vstorage.filter = filter
		notify('interact', `interact enabled | range: {vstorage.range}`, 1)

		maid.add('interact', services.run_service.Heartbeat, function()
			local character = stuff.owner.Character
			if not character or not character:FindFirstChild('HumanoidRootPart') then return end

			local hrp = character.HumanoidRootPart
			local hrp_pos = stuff.rawrbxget(hrp, 'Position')

			for _, item in pairs(workspace:GetDescendants()) do
				if item:IsA('Part') or item:IsA("BasePart") or item:IsA("MeshPart") or item:IsA("UnionOperation") or item.Name:lower():find('coin') or item.Name:lower():find('cash') or item.Name:lower():find('money') or item.Name:lower():find('orb') or item.Name:lower():find('gem') then
					if not vstorage.filter or item.Name:lower():find(vstorage.filter:lower()) or filter:lower() == "tool" and item.Parent.ClassName == "Tool" and item.Parent.Parent == workspace then
						local item_pos = stuff.rawrbxget(item, 'Position')
						if (hrp_pos - item_pos).Magnitude <= vstorage.range then
							if firetouchinterest then
								firetouchinterest(hrp, item, 0)
								firetouchinterest(hrp, item, 1)
							else
								stuff.rawrbxset(hrp, 'CFrame', CFrame.new(item_pos))
								task.wait(.05)
								stuff.rawrbxset(hrp, 'CFrame', CFrame.new(hrp_pos))
							end
						end
					end
				end
			end
		end)
	else
		notify('interact', 'interact disabled', 1)
		maid.remove('interact')
	end
end)

cmd_library.add({'leave'}, 'leaves the server', {}, function()
	pcall(function()
		game:Shutdown()
	end)
	game:GetService("Players").LocalPlayer:Destroy()
end)

cmd_library.add({'clickmouse', 'click'}, 'clicks your mouse', {}, function(vstorage)
	--services.virt_user:ClickButton1(Vector2.new(0,0),workspace.CurrentCamera.CFrame)
	mouse1click()
end)

cmd_library.add({'aliases', 'listalias', 'showaliases'}, 'lists all aliases', {}, function(vstorage)
	local aliases = config.get('aliases') or {}

	if next(aliases) == nil then
		return notify('aliases', 'no aliases found', 2)
	end

	local alias_list = {}
	for alias, command in pairs(aliases) do
		table.insert(alias_list, `{alias} -> {command}`)
	end

	table.sort(alias_list)
	notify('aliases', `aliases:\n{table.concat(alias_list, '\n')}`, 1)
end)

cmd_library.add({'addalias', 'alias', 'setalias'}, 'creates a command alias', {
	{'alias', 'string'},
	{'command', 'string'}
}, function(vstorage, alias, command)
	if not alias or not command then
		return notify('addalias', 'missing alias or command', 2)
	end

	alias = alias:lower()
	command = command:lower()

	if cmd_library._command_map[alias] then
		return notify('addalias', `'{alias}' is already a command`, 2)
	end

	local similar = cmd_library.find_similar(command)
	local matched = false
	for _, cmd_name in similar do
		if cmd_name:lower() == command then
			matched = true
			break
		end
	end

	if not matched then
		if #similar > 0 then
			return notify('addalias', `command '{command}' not found. did you mean: {table.concat(similar, ', ')}?`, 2)
		else
			return notify('addalias', `command '{command}' not found`, 2)
		end
	end

	local cmd_data = cmd_library._command_map[command]
	if cmd_data then
		table.insert(cmd_data.names, alias)
		cmd_library._command_map[alias] = cmd_data
	end

	local aliases = config.get('aliases') or {}
	aliases[alias] = command
	config.set('aliases', aliases)

	notify('addalias', `created alias '{alias}' for command '{command}'`, 1)
end)

cmd_library.add({'removealias', 'unalias', 'deletealias'}, 'removes a command alias', {
	{'alias', 'string'}
}, function(vstorage, alias)
	if not alias then
		return notify('removealias', 'no alias specified', 2)
	end

	alias = alias:lower()

	local aliases = config.get('aliases') or {}

	if not aliases[alias] then
		return notify('removealias', `alias '{alias}' not found`, 2)
	end

	local command = aliases[alias]
	local cmd_data = cmd_library._command_map[command]

	if cmd_data then
		for i, name in cmd_data.names do
			if name == alias then
				table.remove(cmd_data.names, i)
				break
			end
		end
		cmd_library._command_map[alias] = nil
	end

	aliases[alias] = nil
	config.set('aliases', aliases)

	notify('removealias', `removed alias '{alias}'`, 1)
end)

cmd_library.add({'clearaliases', 'removeallaliases'}, 'clears all aliases', {}, function(vstorage)
	local aliases = config.get('aliases') or {}

	if next(aliases) == nil then
		return notify('clearaliases', 'no aliases to clear', 2)
	end

	local count = 0
	for alias, command in pairs(aliases) do
		local cmd_data = cmd_library._command_map[command]
		if cmd_data then
			for i, name in cmd_data.names do
				if name == alias then
					table.remove(cmd_data.names, i)
					break
				end
			end
			cmd_library._command_map[alias] = nil
		end
		count = count + 1
	end

	config.set('aliases', {})
	notify('clearaliases', `cleared {count} alias(es)`, 1)
end)

cmd_library.add({'bind', 'keybind', 'bindkey'}, 'binds a command to a key', {
	{'key', 'string'},
	{'command', 'string'},
	{'...', 'string'}
}, function(vstorage, key, command, ...)
	if not key or not command then
		return notify('bind', 'missing key or command', 2)
	end

	local keycode = Enum.KeyCode[key:upper()]
	if not keycode then
		return notify('bind', `invalid key '{key}'`, 2)
	end

	local similar = cmd_library.find_similar(command:lower())
	local matched = false
	for _, cmd_name in similar do
		if cmd_name:lower() == command:lower() then
			matched = true
			break
		end
	end

	if not matched then
		if #similar > 0 then
			return notify('bind', `command '{command}' not found. did you mean: {table.concat(similar, ', ')}?`, 2)
		else
			return notify('bind', `command '{command}' not found`, 2)
		end
	end

	local args = {...}
	vstorage.binds = vstorage.binds or {}

	local bind_id = `keybind_{key:upper()}_{command:lower()}`

	if vstorage.binds[bind_id] then
		maid.remove(bind_id)
	end

	vstorage.binds[bind_id] = {
		key = key:upper(),
		command = command:lower(),
		args = args
	}

	maid.add(bind_id, services.user_input_service.InputBegan, function(input, processed)
		if input.KeyCode == keycode and not processed then
			cmd_library.execute(command:lower(), unpack(args))
		end
	end)

	local game_binds = config.get_game_binds()
	game_binds[bind_id] = {
		key = key:upper(),
		command = command:lower(),
		args = args
	}
	config.set_game_binds(game_binds)

	notify('bind', `bound {key:upper()} to {command} {#args > 0 and `with {#args} args` or ''}`, 1)
end)

cmd_library.add({'unbind', 'unkeybind', 'unbindkey'}, 'unbinds a key', {
	{'key', 'string'}
}, function(vstorage, key)
	if not key then
		return notify('unbind', 'no key specified', 2)
	end

	local bind_vs = cmd_library.get_variable_storage('bind')
	if not bind_vs or not bind_vs.binds then
		return notify('unbind', 'no binds exist', 2)
	end

	local removed = false
	local game_binds = config.get_game_binds()

	for bind_id, bind_data in pairs(bind_vs.binds) do
		if bind_data.key == key:upper() then
			maid.remove(bind_id)
			bind_vs.binds[bind_id] = nil
			game_binds[bind_id] = nil
			removed = true
		end
	end

	if removed then
		config.set_game_binds(game_binds)
		notify('unbind', `unbound key {key:upper()}`, 1)
	else
		notify('unbind', `no binds found for key {key:upper()}`, 2)
	end
end)

cmd_library.add({'listbinds', 'binds', 'showbinds'}, 'lists all keybinds for current game', {}, function(vstorage)
	local bind_vs = cmd_library.get_variable_storage('bind')
	if not bind_vs or not bind_vs.binds or next(bind_vs.binds) == nil then
		return notify('listbinds', 'no binds exist for this game', 2)
	end

	local bind_list = {}
	for bind_id, bind_data in ipairs(bind_vs.binds) do
		local args_str = #bind_data.args > 0 and ` {table.concat(bind_data.args, ' ')}` or ''
		table.insert(bind_list, `{bind_data.key}: {bind_data.command}{args_str}`)
	end

	table.sort(bind_list)
	notify('listbinds', `keybinds:\n{table.concat(bind_list, '\n')}`, 1)
end)

cmd_library.add({'clearbinds', 'unbindall'}, 'clears all keybinds for current game', {}, function(vstorage)
	local bind_vs = cmd_library.get_variable_storage('bind')
	if not bind_vs or not bind_vs.binds then
		return notify('clearbinds', 'no binds exist', 2)
	end

	local count = 0
	for bind_id, _ in ipairs(bind_vs.binds) do
		maid.remove(bind_id)
		count = count + 1
	end

	bind_vs.binds = {}
	config.set_game_binds({})

	notify('clearbinds', `cleared {count} keybind(s)`, 1)
end)

cmd_library.add({'dupetools', 'clonetools'}, 'duplicates your tools', {
	{'amount', 'number'}
}, function(vstorage, amount)
	amount = amount or 1

	if not stuff.owner_char or not stuff.owner_char:FindFirstChild('HumanoidRootPart') then
		return notify('dupetools', 'character not found', 2)
	end

	notify('dupetools', `duplicating tools {amount} time(s)`, 1)

	local function get_handle_tools(player)
		player = player or stuff.owner
		local tools = {}

		if player.Character then
			for _, item in player.Character:GetChildren() do
				if item:IsA('BackpackItem') and item:FindFirstChild('Handle') then
					table.insert(tools, item)
				end
			end
		end

		if player.Backpack then
			for _, item in player.Backpack:GetChildren() do
				if item:IsA('BackpackItem') and item:FindFirstChild('Handle') then
					table.insert(tools, item)
				end
			end
		end

		return tools
	end

	local original_position = stuff.rawrbxget(stuff.owner_char.HumanoidRootPart, 'CFrame')
	local collected_tools = {}
	local temp_position = CFrame.new(math.random(-200000, 200000), 200000, math.random(-200000, 200000))

	for iteration = 1, amount do
		local char = stuff.owner_char
		if not char then 
			notify('dupetools', 'character lost, stopping', 2)
			break 
		end

		local humanoid = char:FindFirstChild('Humanoid')
		local hrp = char:FindFirstChild('HumanoidRootPart')

		if not humanoid or not hrp then 
			notify('dupetools', 'humanoid or hrp missing, stopping', 2)
			break 
		end

		task.wait(0.1)

		pcall(char.PivotTo, char, temp_position)

		task.wait(0.1)
		stuff.rawrbxset(hrp, 'Anchored', true)

		pcall(stuff.owner.ClearCharacterAppearance, stuff.owner)

		task.wait(0.1)

		local current_tools = get_handle_tools(stuff.owner)

		if #current_tools == 0 then
			notify('dupetools', 'no tools found to duplicate', 2)
			stuff.rawrbxset(hrp, 'Anchored', false)
			break
		end

		for _, tool in current_tools do
			task.spawn(function()
				pcall(function()
					for i = 1, 25 do
						stuff.rawrbxset(tool, 'Parent', char)
						if tool:FindFirstChild('Handle') then
							stuff.rawrbxset(tool.Handle, 'Anchored', true)
						end
						task.wait()
					end

					task.wait(0.05)

					for i = 1, 5 do
						stuff.rawrbxset(tool, 'Parent', workspace)
						task.wait()
					end

					if tool:FindFirstChild('Handle') then
						table.insert(collected_tools, tool.Handle)
					end
				end)
			end)
		end

		task.wait(0.3)

		pcall(function()
			stuff.rawrbxset(humanoid, 'Health', 0)
		end)

		local new_char = stuff.owner.CharacterAdded:Wait()
		new_char:WaitForChild('Humanoid')
		new_char:WaitForChild('HumanoidRootPart')

		task.wait(0.2)

		if iteration == amount then
			pcall(function()
				new_char:PivotTo(original_position)
			end)
		else
			pcall(function()
				new_char:PivotTo(temp_position)
			end)
		end

		task.wait(0.1)

		if iteration == amount or iteration % 5 == 0 then
			local new_hrp = new_char:FindFirstChild('HumanoidRootPart')
			if not new_hrp then continue end

			if firetouchinterest then
				for _, handle in collected_tools do
					task.spawn(function()
						pcall(function()
							if handle and handle:IsDescendantOf(workspace) then
								stuff.rawrbxset(handle, 'Anchored', false)
								task.wait()
								firetouchinterest(handle, new_hrp, 1)
								task.wait()
								firetouchinterest(handle, new_hrp, 0)
							end
						end)
					end)
				end
			else
				for _, handle in collected_tools do
					task.spawn(function()
						pcall(function()
							if handle and handle:IsDescendantOf(workspace) then
								local original_can_collide = stuff.rawrbxget(handle, 'CanCollide')
								stuff.rawrbxset(handle, 'CanCollide', false)
								stuff.rawrbxset(handle, 'Anchored', false)

								for i = 1, 15 do
									local hrp_cf = stuff.rawrbxget(new_hrp, 'CFrame')
									stuff.rawrbxset(handle, 'CFrame', hrp_cf)
									task.wait()
								end

								stuff.rawrbxset(handle, 'CanCollide', original_can_collide)
							end
						end)
					end)
				end
			end

			task.wait(0.3)
			table.clear(collected_tools)
		end

		temp_position = temp_position * CFrame.new(10, math.random(-5, 5), 0)

		notify('dupetools', `iteration {iteration}/{amount} complete`, 1)
	end

	notify('dupetools', 'tool duplication complete', 1)
end)

cmd_library.add({'settings'}, 'manage settings', {
	{'action', 'string'},
	{'key', 'string'},
	{'value', 'string'}
}, function(vstorage, action, key, value)
	action = action and action:lower()

	if action == 'save' then
		if config.save() then
			notify('settings', 'settings saved successfully', 1)
		else
			notify('settings', 'failed to save settings', 2)
		end
	elseif action == 'load' then
		if config.load() then
			config.apply()
			notify('settings', 'settings loaded successfully', 1)
		else
			notify('settings', 'failed to load settings', 2)
		end
	elseif action == 'reset' then
		config.reset(key)
		config.apply()
		notify('settings', key and `reset setting '{key}'` or 'reset all settings', 1)
	elseif action == 'get' then
		if key then
			local val = config.get(key)
			notify('settings', `{key}: {tostring(val)}`, 4)
		else
			notify('settings', 'no key specified', 2)
		end
	elseif action == 'set' then
		if key and value then
			local parsed_value = value
			if value:lower() == 'true' then
				parsed_value = true
			elseif value:lower() == 'false' then
				parsed_value = false
			elseif tonumber(value) then
				parsed_value = tonumber(value)
			elseif key == 'open_keybind' then
				parsed_value = tostring(value):upper()
				if Enum.KeyCode[parsed_value] then
					stuff.open_keybind = Enum.KeyCode[parsed_value]
				else
					notify("settings","invalid value",1)
					return
				end
			end
			config.set(key, parsed_value)
			notify('settings', `set {key} to {tostring(parsed_value)}`, 1)
		else
			notify('settings', 'key and value required', 2)
		end
	elseif action == 'list' then
		for k, v in pairs(config.current_settings) do
			notify('settings', `{k}: {tostring(v)}`, 4)
			task.wait(0.1)
		end
	else
		notify('settings', 'usage: settings <save/load/reset/get/set/list> [key] [value]', 3)
	end
end)

cmd_library.add({'prefix', 'changeprefix', 'setprefix'}, 'changes the chat command prefix', {
	{'new_prefix', 'string'}
}, function(vstorage, new_prefix)
	if not new_prefix or new_prefix == '' then
		return notify('prefix', `current prefix: '{stuff.chat_prefix or '!'}'`, 4)
	end

	stuff.chat_prefix = new_prefix

	config.set('chat_prefix', stuff.chat_prefix)
	notify('prefix', `chat prefix changed to '{stuff.chat_prefix}'`, 1)
end)

cmd_library.add({'openbind', 'setopenbind'}, 'changes the command bar open keybind', {
	{'key', 'string'}
}, function(vstorage, key)
	if not key then
		return notify('openbind', 'no key specified', 2)
	end

	local keycode = Enum.KeyCode[key:gsub("^%l", string.upper)]
	if not keycode then
		return notify('openbind', `invalid keycode '{key}'`, 2)
	end

	config.set('open_keybind', keycode.Name)
	stuff.open_keybind = keycode
	notify('openbind', `command bar keybind changed to {keycode.Name}`, 1)

	stuff.update_keybind()
end)

cmd_library.add({'netless', 'net'}, 'enables netless for your character (prevents parts from falling)', {
	{'hat_velocity', 'vec3'},
	{'body_velocity', 'vec3'},
}, function(vstorage, hat_vel, body_vel)
	if vstorage.enabled then
		return notify('netless', 'netless already enabled', 2)
	end

	hat_vel = hat_vel or Vector3.new(-17.7, 0, -17.7)
	body_vel = body_vel or Vector3.new(-17.7, 0, -17.7)

	vstorage.enabled = true
	notify('netless', `netless enabled with hat velocity {tostring(hat_vel)} and body velocity {tostring(body_vel)}`, 1)

	local sethidden = sethiddenproperty or set_hidden_property or set_hidden_prop

	if sethidden then
		maid.add('netless_simradius', services.run_service.Stepped, function()
			pcall(function()
				sethidden(stuff.owner, 'SimulationRadius', math.huge)
				sethidden(stuff.owner, 'MaximumSimulationRadius', math.huge)
				stuff.rawrbxset(stuff.owner, 'MaximumSimulationRadius', math.huge)
			end)
		end)
	end

	maid.add('netless_velocity', services.run_service.Heartbeat, function()
		local char = stuff.owner_char
		if not char then return end

		for _, part in pairs(char:GetChildren()) do
			if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
				stuff.rawrbxset(part, 'AssemblyLinearVelocity', body_vel)
			elseif part:IsA('Accessory') and part:FindFirstChild('Handle') then
				stuff.rawrbxset(part.Handle, 'AssemblyLinearVelocity', hat_vel)
			end
		end
	end)

	maid.add('netless_nocollide', services.run_service.Stepped, function()
		local char = stuff.owner_char
		if not char then return end

		for _, part in pairs(char:GetDescendants()) do
			if part:IsA('BasePart') then
				stuff.rawrbxset(part, 'CanCollide', false)
			end
		end
	end)
end)

cmd_library.add({'unnetless'}, 'disables netless', {}, function(vstorage)
	local netless_vs = cmd_library.get_variable_storage('netless')

	if not netless_vs or not netless_vs.enabled then
		return notify('netless', 'netless not enabled', 2)
	end

	netless_vs.enabled = false
	notify('netless', 'netless disabled', 1)

	maid.remove('netless_simradius')
	maid.remove('netless_velocity')
	maid.remove('netless_nocollide')
end)

cmd_library.add({'clicktp', 'ctp'}, 'click to teleport (hold left alt and press lmb to teleport)', {
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unclicktp')
		return
	end

	vstorage.enabled = not vstorage.enabled
	vstorage.bypass = bypass

	if vstorage.enabled then
		notify('clicktp', `click teleport enabled{bypass and ' (bypass)' or ''}`, 1)

		if bypass then
			hook_lib.create_hook('clicktp_bypass', {
				newindex = function(self, key, value)
					if vstorage.is_teleporting then
						local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
						if self == hrp and (key == 'CFrame' or key == 'Position') then
							return false
						end
					end
				end,
				index = function(self, key)
					if vstorage.is_teleporting then
						local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
						if self == hrp and key == 'CFrame' then
							return vstorage.ccframe or hrp.CFrame
						elseif self == hrp and key == 'Position' then
							return vstorage.ccframe.Position or hrp.CFrame.Position
						end
					end
				end
			})
		end

		maid.add('clicktp', services.user_input_service.InputBegan, function(input, processed)
			if processed then return end

			if input.UserInputType == Enum.UserInputType.MouseButton1 and services.user_input_service:IsKeyDown(Enum.KeyCode.LeftAlt) then
				local mouse = stuff.owner:GetMouse()
				local target = mouse.Hit

				if target then
					local char = stuff.owner_char
					local hrp = char and char:FindFirstChild('HumanoidRootPart')

					if hrp then
						vstorage.is_teleporting = true
						vstorage.ccframe = hrp.CFrame
						stuff.rawrbxset(hrp, 'CFrame', target + Vector3.new(0, 4, 0))
						task.wait(0.1)
						vstorage.is_teleporting = false
					end
				end
			end
		end)
	else
		notify('clicktp', 'click teleport disabled', 1)
		maid.remove('clicktp')

		if vstorage.bypass then
			hook_lib.destroy_hook('clicktp_bypass')
		end
	end
end)

cmd_library.add({'unclicktp', 'unctp'}, 'disables click teleport', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('clicktp')

	if not vstorage.enabled then
		return notify('clicktp', 'click teleport not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('clicktp')

	if vstorage.bypass then
		hook_lib.destroy_hook('clicktp_bypass')
	end

	notify('clicktp', 'click teleport disabled', 1)
end)

cmd_library.add({'tptool', 'tpt'}, 'gives you a teleport tool', {
	{'bypass_mode', 'boolean'},
	{'cooldown', 'number'}
}, function(vstorage, bypass, cooldown)
	cooldown = cooldown or 0.5
	notify('tptool', `giving tp tool | cooldown: {cooldown}s{bypass and ' (bypass)' or ''}`, 1)

	local last_use = 0
	local is_teleporting = false
	local ccframe = stuff.owner_char:GetPivot()

	if bypass then
		hook_lib.create_hook('tptool_bypass', {
			newindex = function(self, key, value)
				if is_teleporting then
					local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
					if self == hrp and (key == 'CFrame' or key == 'Position') then
						return false
					end
				end
			end,
			index = function(self, key)
				if is_teleporting then
					local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
					if self == hrp and key == 'CFrame' then
						return ccframe or hrp.CFrame
					elseif self == hrp and key == 'Position' then
						return ccframe.Position or hrp.CFrame.Position
					end
				end
			end
		})
	end

	local tptool = Instance.new('Tool')
	stuff.rawrbxset(tptool, 'Name', 'tp tool')
	stuff.rawrbxset(tptool, 'RequiresHandle', false)
	stuff.rawrbxset(tptool, 'CanBeDropped', false)

	local billboard = Instance.new('BillboardGui')
	stuff.rawrbxset(billboard, 'Size', UDim2.new(0, 100, 0, 50))
	stuff.rawrbxset(billboard, 'AlwaysOnTop', true)
	stuff.rawrbxset(billboard, 'Enabled', false)

	local label = Instance.new('TextLabel')
	stuff.rawrbxset(label, 'Size', UDim2.new(1, 0, 1, 0))
	stuff.rawrbxset(label, 'BackgroundTransparency', 1)
	stuff.rawrbxset(label, 'TextColor3', Color3.new(1, 1, 1))
	stuff.rawrbxset(label, 'TextStrokeTransparency', 0.5)
	stuff.rawrbxset(label, 'Font', Enum.Font.Code)
	stuff.rawrbxset(label, 'TextSize', 14)
	stuff.rawrbxset(label, 'Parent', billboard)

	local ppart = Instance.new('Part')
	stuff.rawrbxset(ppart, 'Size', Vector3.zero)
	stuff.rawrbxset(ppart, 'Anchored', true)
	stuff.rawrbxset(ppart, 'CanCollide', false)
	stuff.rawrbxset(ppart, 'CanTouch', false)
	stuff.rawrbxset(ppart, 'CanQuery', false)
	stuff.rawrbxset(ppart, 'Transparency', 1)
	stuff.rawrbxset(billboard, 'Adornee', ppart)

	tptool.Equipped:Connect(function()
		stuff.rawrbxset(billboard, 'Parent', services.core_gui)
		stuff.rawrbxset(ppart, 'Parent', workspace.Terrain)

		maid.add('tptool_i', services.run_service.RenderStepped, function()
			local mouse = stuff.owner:GetMouse()
			local target = mouse.Hit

			if target then
				local pos = target.Position + Vector3.new(0, 1.5, 0)
				stuff.rawrbxset(ppart, 'CFrame', CFrame.new(pos))
				stuff.rawrbxset(billboard, 'Enabled', true)

				local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
				if hrp then
					local distance = (stuff.rawrbxget(hrp, 'Position') - pos).Magnitude
					stuff.rawrbxset(label, 'Text', `distance: {math.floor(distance)}m`)
				end
			end
		end)
	end)

	tptool.Unequipped:Connect(function()
		maid.remove('tptool_i')
		stuff.rawrbxset(billboard, 'Enabled', false)
		pcall(stuff.destroy, ppart)
		pcall(stuff.destroy, billboard)

		if bypass then
			hook_lib.destroy_hook('tptool_bypass')
		end
	end)

	tptool.Activated:Connect(function()
		local current_time = tick()
		if current_time - last_use < cooldown then
			local remaining = math.ceil((cooldown - (current_time - last_use)) * 10) / 10
			notify('tptool', `cooldown: {remaining}s`, 2)
			return
		end

		local mouse = stuff.owner:GetMouse()
		local pos = mouse.Hit.Position
		pos = pos + Vector3.new(0, 1.5, 0)

		local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
		if hrp then
			is_teleporting = true
			ccframe = hrp.CFrame
			stuff.rawrbxset(hrp, 'CFrame', CFrame.new(pos))
			last_use = current_time

			task.wait(0.1)
			is_teleporting = false
		end
	end)

	stuff.rawrbxset(tptool, 'Parent', stuff.owner.Backpack)

	vstorage.tool = tptool
end)

cmd_library.add({'test'}, 'test the status of the notification system', {}, function()
	notify('test', 'default', 1)
	notify('test', 'error', 2)
	notify('test', 'warning', 3)
	notify('test', 'info', 4)
	notify('test', 'nil', nil)
end)

cmd_library.add({'logmodules', 'getmodules', 'modules'}, 'logs all loaded modules and their information', {}, function(vstorage)
	notify('logmodules', 'scanning for loaded modules...', 1)

	if not getloadedmodules then
		return notify('logmodules', 'getloadedmodules not supported by your executor', 2)
	end

	local marketplace = game:GetService('MarketplaceService')
	local modules = getloadedmodules()

	if not modules or #modules == 0 then
		return notify('logmodules', 'no modules found', 2)
	end

	notify('logmodules', `found {#modules} loaded modules, analyzing...`, 1)

	local output = `=== found {#modules} loaded modules ===\n`
	output ..= `game: {game.Name} (placeid: {game.PlaceId})\n\n`

	local asset_ids = {}
	local module_count = 0

	for i, module in ipairs(modules) do
		module_count += 1
		local module_name = stuff.rawrbxget(module, 'Name')
		local module_path = module:GetFullName()

		local entry = `{i}. '{module_name}'\n`
		entry ..= `   path: {module_path}\n`

		local source_ids = {}
		pcall(function()
			if decompile then
				local source = decompile(module) or ''

				for id in source:gmatch('rbxassetid://(%d+)') do
					if not table.find(source_ids, id) then
						table.insert(source_ids, id)
					end
				end

				for id in source:gmatch('require%((%d+)%)') do
					if not table.find(source_ids, id) then
						table.insert(source_ids, id)
					end
				end
			end
		end)

		if #source_ids > 0 then
			entry ..= `   referenced assets: {table.concat(source_ids, ', ')}\n`
			for _, id in source_ids do
				if not table.find(asset_ids, id) then
					table.insert(asset_ids, id)
				end
			end
		end

		output ..= entry .. '\n'
	end

	if #asset_ids > 0 then
		output ..= `\n=== asset information ({#asset_ids} unique assets) ===\n\n`
		notify('logmodules', `fetching info for {#asset_ids} assets...`, 1)

		for idx, id in ipairs(asset_ids) do
			local success, asset_info = pcall(function()
				return marketplace:GetProductInfo(tonumber(id), Enum.InfoType.Asset)
			end)

			if success and asset_info then
				local creator_name = 'unknown'
				if asset_info.Creator then
					if asset_info.Creator.Name then
						creator_name = asset_info.Creator.Name
					elseif asset_info.Creator.CreatorTargetId then
						pcall(function()
							local creator_info = marketplace:GetProductInfo(asset_info.Creator.CreatorTargetId, Enum.InfoType.Asset)
							if creator_info and creator_info.Creator then
								creator_name = creator_info.Creator.Name or 'unknown'
							end
						end)
					end
				end

				local asset_entry = `{idx}. asset {id}\n`
				asset_entry ..= `   name: '{asset_info.Name}'\n`
				asset_entry ..= `   creator: {creator_name}\n`
				asset_entry ..= `   type: {asset_info.AssetTypeId or 'unknown'}\n`
				asset_entry ..= `   description: {asset_info.Description and asset_info.Description:sub(1, 100) or 'none'}...\n\n`

				output ..= asset_entry
				print(asset_entry)
			else
				local fail_entry = `{idx}. asset {id}: failed to fetch info\n\n`
				output ..= fail_entry
				print(fail_entry)
			end

			if idx % 5 == 0 then
				task.wait(1)
			end
		end
	end

	output ..= `\n=== summary ===\n`
	output ..= `total modules: {module_count}\n`
	output ..= `referenced assets: {#asset_ids}\n`

	if setclipboard then
		setclipboard(output)
		notify('logmodules', `copied info for {module_count} modules and {#asset_ids} assets to clipboard`, 1)
	else
		notify('logmodules', `logged {module_count} modules to console (setclipboard not available)`, 3)
	end

	print('\n' .. output)
end)

cmd_library.add({'rejoin', 'rj'}, 'rejoins the server', {}, function()
	notify('rejoin', 'now rejoining', 1)
	services.teleport_service:TeleportToPlaceInstance(game.PlaceId, game.JobId, stuff.owner)
end)

cmd_library.add({'chatlogs', 'cl'}, 'toggles the chatlogs', {}, function(vstorage)
	local existing_log = vstorage.existing_log

	if existing_log then
		services.text_chat_service.OnIncomingMessage = stuff.empty_function
		pcall(stuff.destroy, existing_log)
		vstorage.existing_log = nil
		vstorage.enabled = false
		notify('chatlogs', 'chatlogs disabled', 1)
		return
	end

	vstorage.enabled = true
	local chatlog = stuff.ui.opadmin_chatlogs:Clone()
	vstorage.existing_log = chatlog
	pcall(protect_gui, chatlog)
	local ui_chatlog_template = chatlog.main_container.chatlogs.log
	ui_chatlog_template.Parent = nil

	if services.text_chat_service.ChatVersion == Enum.ChatVersion.TextChatService then
		services.text_chat_service.OnIncomingMessage = function(message)
			if message.Status == Enum.TextChatMessageStatus.Success then
				local frame = chatlog:FindFirstChildOfClass('Frame')
				local sframe = frame:FindFirstChildOfClass('ScrollingFrame')
				local label = ui_chatlog_template:Clone()

				stuff.rawrbxset(label, 'Name', tostring(message.Text))
				stuff.rawrbxset(label, 'Visible', true)
				stuff.rawrbxset(label, 'Text', tostring(message.TextSource) .. ': ' .. tostring(message.Text))
				stuff.rawrbxset(label, 'Parent', sframe)
				if #chatlog.main_container.chatlogs:GetChildren() > 3 then
					task.wait()
					stuff.rawrbxset(sframe, 'CanvasPosition', Vector2.new(0, sframe.AbsoluteCanvasSize.Y))
				end
			end
		end
	end

	notify('chatlogs', 'chatlogs enabled', 1)
end)

cmd_library.add({'clearchatlogs', 'clearcl', 'ccl'}, 'clears the chatlogs', {}, function(vstorage)
	local existing_log = cmd_library.get_variable_storage('chatlogs').existing_log

	if existing_log then
		for _, log in existing_log.main_container.chatlogs:GetChildren() do
			if log:IsA('TextLabel') then
				pcall(stuff.destroy, log)
			end
		end
		return notify('chatlogs', 'chatlogs cleared', 1)
	end

	notify('chatlogs', 'chatlogs not enabled', 2)
end)

cmd_library.add({'help', 'cmds', 'commands'}, 'shows you this menu', {
	{'update_list', 'boolean'}
}, function(vstorage, update)
	if update or not vstorage.loaded_commands then
		for _, child in pairs(stuff.ui_cmdlist_commandlist:GetChildren()) do
			if child:IsA('TextLabel') and child ~= stuff.ui_cmdlist_template then
				stuff.destroy(child)
			end
		end

		vstorage.loaded_commands = true

		local all_commands = cmd_library.help()

		for _, cmd_info in all_commands do
			local newframe = stuff.clone(stuff.ui_cmdlist_template)
			newframe.Visible = true
			newframe.Parent = stuff.ui_cmdlist_commandlist
			newframe.TextWrapped = true
			newframe.AutomaticSize = Enum.AutomaticSize.Y

			local names_str = table.concat(cmd_info.names, ', ')

			local args_str = ''
			if cmd_info.args and #cmd_info.args > 0 then
				local arg_parts = {}
				for _, arg_data in cmd_info.args do
					if arg_data[3] == 'hidden' then
						continue
					end

					if arg_data['...'] then
						table.insert(arg_parts, `...: {arg_data['...']}`)
					else
						table.insert(arg_parts, `{arg_data[1]}: {arg_data[2]}`)
					end
				end
				if #arg_parts > 0 then
					args_str = ` [{table.concat(arg_parts, ', ')}]`
				end
			end

			newframe.Text = `{names_str}{args_str} - {cmd_info.description}`
		end

		notify('help', update and 'command list updated' or 'command list loaded', 1)
	end

	stuff.ui_cmdlist.Enabled = true
end)

cmd_library.add({'saveposition', 'savepos'}, 'save a position to load with loadpos', {}, function(vstorage)
	vstorage.pos = stuff.owner_char:GetPivot()
	local pos = vstorage.pos.Position
	notify('savepos', `saved position: x:{math.floor(pos.X)}, y:{math.floor(pos.Y)}, z:{math.floor(pos.Z)}`, 1)
end)

cmd_library.add({'loadposition', 'loadpos'}, 'load the position saved with savepos', {
	{'bypass_mode', 'boolean'}
}, function(vstorage, bypass)
	local savepos_vstorage = cmd_library.get_variable_storage('savepos')
	local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
	local hrp_cframe = hrp.CFrame

	if savepos_vstorage.pos then
		if bypass then
			if hrp then
				hook_lib.create_hook('loadpos_bypass', {
					newindex = function(self, key, value)
						if self == hrp and (key == 'CFrame' or key == 'Position') then
							return false
						end
					end,
					index = function(self, key)
						if self == hrp and key == 'CFrame' then
							return hrp_cframe
						elseif self == hrp and key == 'Position' then
							return hrp_cframe.Position
						end
					end
				})

				stuff.owner_char:PivotTo(savepos_vstorage.pos)

				task.wait(0.1)
				hook_lib.destroy_hook('loadpos_bypass')
			end
		else
			stuff.owner_char:PivotTo(savepos_vstorage.pos)
		end

		notify('loadpos', 'loaded position', 1)
	else
		notify('loadpos', 'you haven\'t saved a position using saveposition', 2)
	end
end)

cmd_library.add({"respawnpoint","setrespawn"},'sets your respawn point to your current location',{
	{"lasts_one_respawn","boolean"}
} ,function(vstorage,lasts1respawn)
	if vstorage.enabled ~= true then
		vstorage.enabled = true
		local cframe_set = stuff.owner_char:GetPivot()
		notify("respawnpoint","respawn point has been set",1)
		maid.add('set_respawn_point', services.run_service.Heartbeat, function()
			if stuff.owner_char:FindFirstChildOfClass("Humanoid"):GetState() == Enum.HumanoidStateType.Dead then
				if vstorage.currently_respawning ~= true then
				else
					return
				end
				vstorage.currently_respawning = true
				maid.add("currently_respawning",services.run_service.Heartbeat,function()
					if stuff.owner_char:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Dead and stuff.owner_char:FindFirstChild("Head") then
						maid.remove("currently_respawning")
						if lasts1respawn == true then
							maid.remove("set_respawn_point")
							vstorage.enabled = false
						end
						stuff.owner_char:PivotTo(cframe_set)
						maid.add("currently_respawning",services.run_service.Heartbeat, function()
							stuff.owner_char:PivotTo(cframe_set)
						end)
						task.delay(0.15,function()
							maid.remove("currently_respawning")
							vstorage.currently_respawning = false
						end)
					end
				end)
			end
		end)
	else
		pcall(function()
			maid.remove("set_respawn_point")
		end)
		vstorage.enabled = false
		notify("respawnpoint","respawn point has been removed",1)
	end
end)

cmd_library.add({'illusion', 'deathrespawn', 'drespawn', 'dr'}, 'makes you respawn at the position where you died', {
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unillusion')
		return
	end
	if vstorage.enabled then
		return notify('deathrespawn', 'death respawn already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.bypass = bypass
	notify('deathrespawn', `enabled death respawn{bypass and ' (bypass)' or ''}`, 1)

	local has_died = false
	local death_pos

	maid.add('death_respawn', services.run_service.Heartbeat, function()
		pcall(function()
			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			if not humanoid then return end

			local health = stuff.rawrbxget(humanoid, 'Health')

			if not has_died and health <= 0 then
				has_died = true
				death_pos = stuff.owner_char:GetPivot()
			elseif has_died and health > 0 then
				if vstorage.bypass then
					local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
					local hrp_cframe = hrp.CFrame
					if hrp then
						hook_lib.create_hook('deathrespawn_bypass', {
							newindex = function(self, key, value)
								if self == hrp and (key == 'CFrame' or key == 'Position') then
									return false
								end
							end,
							index = function(self, key)
								if self == hrp and key == 'CFrame' then
									return hrp_cframe
								elseif self == hrp and key == 'Position' then
									return hrp_cframe.Position
								end
							end
						})

						stuff.owner_char:PivotTo(death_pos)

						task.wait(0.1)
						hook_lib.destroy_hook('deathrespawn_bypass')
					end
				else
					stuff.owner_char:PivotTo(death_pos)
				end

				if health > 1 then
					has_died = false
				end
			end
		end)
	end)
end)

cmd_library.add({'unillusion', 'undeathrespawn', 'undrespawn', 'undr'}, 'disables death respawn', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('illusion')

	if not vstorage.enabled then
		return notify('deathrespawn', 'death respawn not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('death_respawn')

	if vstorage.bypass then
		hook_lib.destroy_hook('deathrespawn_bypass')
	end

	notify('deathrespawn', 'death respawn disabled', 1)
end)

cmd_library.add({'fakelag', 'desync'}, 'creates fake lag applied on your character', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unfakelag')
		return
	end
	if vstorage.enabled then 
		return notify('fakelag', 'fakelag is already enabled', 2) 
	end

	vstorage.enabled = true
	notify('fakelag', 'enabled fakelag', 1)

	task.spawn(function()
		while vstorage.enabled do
			pcall(function()
				local anchor_part = stuff.owner_char:FindFirstChild('UpperTorso') and stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart') or stuff.rawrbxget(stuff.owner_char, 'Torso')
				stuff.rawrbxset(anchor_part, 'Anchored', true)

				local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
				for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(track.Speed * 1.1)
				end

				stuff.rawrbxset(humanoid, 'Jump', true)
			end)

			task.wait(.1)

			pcall(function()
				local anchor_part = stuff.owner_char:FindFirstChild('UpperTorso') and stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart') or stuff.rawrbxget(stuff.owner_char, 'Torso')
				stuff.rawrbxset(anchor_part, 'Anchored', false)

				local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
				for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
					track:AdjustSpeed(track.Speed / 1.1)
				end
			end)

			task.wait(.1)
		end
	end)
end)

cmd_library.add({'unfakelag', 'undesync'}, 'disables fake lag', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('fakelag')

	if not vstorage.enabled then
		return notify('fakelag', 'fakelag is already disabled', 2)
	end

	vstorage.enabled = false
	notify('fakelag', 'disabled fakelag', 1)
end)

cmd_library.add({'antifling', 'afling', 'antif'}, 'stops other exploiters from flinging you', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('antifling', 'antifling enabled', 1)

		local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
		if hrp then
			vstorage.last_position = stuff.rawrbxget(hrp, 'CFrame')
		end
		vstorage.velocity_threshold = 100

		maid.add('antifling', services.run_service.Heartbeat, function()
			pcall(function()
				local char = stuff.owner.Character
				if char and char:FindFirstChild('HumanoidRootPart') then
					local hrp = char.HumanoidRootPart
					local velocity = stuff.rawrbxget(hrp, 'AssemblyLinearVelocity').Magnitude

					if velocity > vstorage.velocity_threshold then
						stuff.rawrbxset(hrp, 'CFrame', vstorage.last_position)
						stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.zero)
						stuff.rawrbxset(hrp, 'AssemblyAngularVelocity', Vector3.zero)
						notify('antifling', `fling prevention - {math.round(velocity)} > {vstorage.velocity_threshold}`, 4)
					else
						vstorage.last_position = stuff.rawrbxget(hrp, 'CFrame')
					end
				end

				local other_players = services.players:GetPlayers()
				table.remove(other_players, table.find(other_players, stuff.owner))

				for _, v in pairs(other_players) do
					if v.Character then
						for _, part in pairs(v.Character:GetDescendants()) do
							if part:IsA('BasePart') then
								stuff.rawrbxset(part, 'AssemblyAngularVelocity', Vector3.zero)

								if char and char:FindFirstChild('HumanoidRootPart') then
									local part_pos = stuff.rawrbxget(part, 'Position')
									local hrp_pos = stuff.rawrbxget(char.HumanoidRootPart, 'Position')
									local part_vel = stuff.rawrbxget(part, 'AssemblyLinearVelocity').Magnitude

									if (part_pos - hrp_pos).Magnitude < 10 and part_vel > 50 then
										stuff.rawrbxset(part, 'CanCollide', false)
									end
								end
							end
						end
					end
				end
			end)
		end)
	else
		notify('antifling', 'antifling disabled', 1)
		maid.remove('antifling')
	end
end)

cmd_library.add({'unantifling', 'unafling', 'unantif'}, 'disables antifling', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('antifling')

	if not vstorage.enabled then
		return notify('antifling', 'antifling is already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('antifling')
	notify('antifling', 'disabled antifling', 1)
end)

cmd_library.add({'gettools', 'tools'}, 'attempts to steal tools from others', {}, function(vstorage)
	local count = 0

	for _, v in workspace:GetDescendants() do
		if v:IsA('Tool') or v:IsA('BackpackItem') or v:IsA('HopperBin') then
			count += 1
			stuff.rawrbxset(v, 'Parent', stuff.owner.Backpack)
		end
	end

	notify('gettools', `stole {count} tools`, 1)
end)

stuff.sim_range_reset = false
cmd_library.add({'reloadnetwork', 'reloadnet', 'rnetwork', 'rnet'}, 'resets your simulationradius to 1000 and forces partfling to stop', {}, function(vstorage)
	notify('reloadnetwork', 'fetching all parts, your character will be reset', 1)

	pcall(function()
		maid.remove('part_trap_follow')
	end)

	task.spawn(function()
		stuff.sim_range_reset = true
		local old_pos = stuff.owner_char:GetPivot()

		pcall(function()
			stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
			stuff.owner_char:BreakJoints()
		end)

		task.wait(.01)
		task.wait(services.players.RespawnTime + .5)
		stuff.owner_char:PivotTo(old_pos)
		task.wait(1)
		stuff.sim_range_reset = false
	end)
end)

cmd_library.add({'antivoid', 'antiv'}, 'stops the void from killing you', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unantivoid')
		return
	end

	if vstorage.enabled then
		return notify('antivoid', 'antivoid already enabled', 2)
	end

	vstorage.enabled = true
	notify('antivoid', 'enabled antivoid', 1)

	pcall(function()
		maid.remove('anti_void_connection')
	end)

	maid.add('anti_void_connection', services.run_service.Heartbeat, function()
		pcall(function()
			local pivot_pos = stuff.owner_char:GetPivot().Position
			local destroy_height = stuff.rawrbxget(workspace, 'FallenPartsDestroyHeight')

			if pivot_pos.Y <= destroy_height + 30 then
				for _, v in stuff.owner_char:GetChildren() do
					if v:IsA('BasePart') then
						pcall(function()
							stuff.rawrbxset(v, 'Velocity', Vector3.zero)
							stuff.rawrbxset(v, 'AssemblyLinearVelocity', Vector3.zero)
						end)
					end
				end
				stuff.owner_char:PivotTo(stuff.owner_char:GetPivot() * CFrame.new(0, (destroy_height * -1) + 50, 0))
			end
		end)
	end)
end)

cmd_library.add({'unantivoid', 'unantiv'}, 'disables anti void', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('antivoid')

	if not vstorage.enabled then
		return notify('antivoid', 'antivoid not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('anti_void_connection')
	notify('antivoid', 'disabled antivoid', 1)
end)

cmd_library.add({'respawn', 'reset', 'die'}, 'reset your character', {}, function(vstorage)
	notify('respawn', 'respawning your character', 1)

	stuff.owner_char:BreakJoints()
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'Health', 0)
end)

cmd_library.add({'gravity', 'grav'}, 'sets workspace gravity value', {
	{'gravity', 'number'}
}, function(vstorage, gravity)
	gravity = gravity or 196.2
	notify('gravity', `gravity set to {gravity}`, 1)
	stuff.rawrbxset(workspace, 'Gravity', gravity)
end)

cmd_library.add({'serverhop', 'hop'}, 'teleports you to another server', {}, function(vstorage)
	notify('serverhop', 'searching for new server...', 3)

	local servers = {}
	local cursor = ''

	repeat
		local url = `https://games.roblox.com/v1/games/{game.PlaceId}/servers/Public?sortOrder=Asc&limit=100&cursor={cursor}`
		local success, result = pcall(function()
			return services.http:JSONDecode(game:HttpGet(url))
		end)

		if success and result.data then
			for _, server in pairs(result.data) do
				if server.id ~= game.JobId and server.playing < server.maxPlayers then
					table.insert(servers, server.id)
				end
			end
			cursor = result.nextPageCursor or ''
		else
			break
		end
	until cursor == '' or #servers >= 10

	if #servers > 0 then
		local random_server = servers[math.random(1, #servers)]
		notify('serverhop', 'teleporting to new server...', 1)
		services.teleport_service:TeleportToPlaceInstance(game.PlaceId, random_server, stuff.owner)
	else
		notify('serverhop', 'no servers found, rejoining current server', 2)
		services.teleport_service:Teleport(game.PlaceId, stuff.owner)
	end
end)

cmd_library.add({'thirdperson', '3rdp', 'third'}, 'forces your camera to be third person', {}, function(vstorage)
	notify('thirdperson', 'now third-person', 1)

	stuff.rawrbxset(stuff.owner, 'CameraMaxZoomDistance', 128)
	stuff.rawrbxset(stuff.owner, 'CameraMode', Enum.CameraMode.Classic)
end)

cmd_library.add({'countcommands', 'countcmds'}, 'counts the commands very useful yes', {}, function(vstorage)
	notify('countcommands', `{#cmd_library._commands} commands`, 1)
end)

cmd_library.add({'disabletouchevent', 'disablete'}, 'disables the touched event of all parts', {
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('undisablete')
		return
	end

	if vstorage.enabled then
		return notify('disablete', 'touch event already disabled', 2)
	end

	vstorage.enabled = true
	vstorage.original_states = {}
	notify('disablete', 'touch events disabled', 1)

	for _, part in workspace:GetDescendants() do
		if part:IsA('BasePart') then
			pcall(function()
				vstorage.original_states[part] = stuff.rawrbxget(part, 'CanTouch')
				stuff.rawrbxset(part, 'CanTouch', false)
			end)
		end
	end

	maid.add('disable_touch_event', workspace.DescendantAdded, function(descendant)
		if vstorage.enabled and descendant:IsA('BasePart') then
			task.wait()
			pcall(function()
				vstorage.original_states[descendant] = stuff.rawrbxget(descendant, 'CanTouch')
				stuff.rawrbxset(descendant, 'CanTouch', false)
			end)
		end
	end)

	local reset_triggered = false

	maid.add('disable_touch_event_died', stuff.owner_char.Humanoid.Died, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('undisablete')
	end)

	maid.add('disable_touch_event_char_added', stuff.owner.CharacterAdded, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('undisablete')
	end)
end)

cmd_library.add({'enabletouchevent', 'enablete'}, 're-enables touch events', {}, function(vstorage)
	local disablete_vs = cmd_library.get_variable_storage('disabletouchevent')

	if not disablete_vs or not disablete_vs.enabled then
		return notify('disablete', 'touch events not disabled', 2)
	end

	disablete_vs.enabled = false
	notify('disablete', 'touch events re-enabled', 1)

	maid.remove('disable_touch_event')
	maid.remove('disable_touch_event_died')
	maid.remove('disable_touch_event_char_added')

	for part, original_state in pairs(disablete_vs.original_states or {}) do
		if part and part.Parent then
			pcall(function()
				stuff.rawrbxset(part, 'CanTouch', original_state)
			end)
		end
	end

	disablete_vs.original_states = {}
end)

cmd_library.add({'translatechat', 'chattranslate'}, 'translates chat [WARNING: ITS A THIRD-PARTY TOOL]', {}, function()
	notify('translatechat', 'loading chat translator', 1)
	local success, err = pcall(function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/x114/RobloxScripts/main/UpdatedChatTranslator'))()
	end)
	if not success then
		notify('translatechat', 'failed to load chat translator: ' .. tostring(err), 2)
	end
end)

cmd_library.add({'remotespy', 'rspy', 'octospy'}, 'allows you to spy on remotes [WARNING: ITS A THIRD-PARTY TOOL]', {}, function()
	notify('remotespy', 'loading remote spy', 1)
	local success, err = pcall(function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/InfernusScripts/Octo-Spy/refs/heads/main/Main.lua'))()
	end)
	if not success then
		notify('remotespy', 'failed to load remote spy: ' .. tostring(err), 2)
	end
end)

cmd_library.add({'dex'}, 'dex explorer (dex++) [WARNING: ITS A THIRD-PARTY TOOL]', {}, function()
	notify('remotespy', 'loading dex', 1)
	local success, err = pcall(function()
		loadstring(game:HttpGet('https://gist.githubusercontent.com/BROgenesis/958c1fee7d8ad100da7f7d020d5d67f3/raw/8dc95caca1b46aa9f4d9dd2433f6be3d9bc69e45/Dex++'))()
	end)
	if not success then
		notify('dex', 'failed to load dex: ' .. tostring(err), 2)
	end
end)

cmd_library.add({'hitbox', 'torsosize', 'expandhitbox'}, 'makes rootpart hitbox bigger', {
	{'size', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, size, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unhitbox')
		return
	end

	size = size or 10

	if vstorage.enabled then
		return notify('hitbox', 'hitbox already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.size = size
	vstorage.bypass = bypass
	vstorage.original_properties = {}

	notify('hitbox', `hitbox size set to {size}{bypass and ' (bypass)' or ''}`, 1)

	local function store_original_properties(hrp)
		local hrp_id = tostring(hrp)
		if not vstorage.original_properties[hrp_id] then
			vstorage.original_properties[hrp_id] = {
				size = stuff.rawrbxget(hrp, 'Size'),
				transparency = stuff.rawrbxget(hrp, 'Transparency'),
				can_collide = stuff.rawrbxget(hrp, 'CanCollide'),
				brick_color = stuff.rawrbxget(hrp, 'BrickColor')
			}
		end
	end

	if bypass then
		hook_lib.create_hook('hitbox_bypass', {
			index = function(self, key)
				if self:IsA('BasePart') and self.Name == 'HumanoidRootPart' then
					local hrp_id = tostring(self)
					local original = vstorage.original_properties[hrp_id]

					if original then
						if key == 'Size' then
							return original.size
						elseif key == 'Transparency' then
							return original.transparency
						elseif key == 'CanCollide' then
							return original.can_collide
						elseif key == 'BrickColor' then
							return original.brick_color
						end
					end
				end
			end,

			newindex = function(self, key, value)
				if self:IsA('BasePart') and self.Name == 'HumanoidRootPart' then
					local hrp_id = tostring(self)

					if vstorage.original_properties[hrp_id] then
						if key == 'Size' or key == 'Transparency' or key == 'CanCollide' or key == 'BrickColor' then
							return false
						end
					end
				end
			end,

			namecall = function(self, ...)
				local method = getnamecallmethod()
				local args = {...}

				if self:IsA('BasePart') and self.Name == 'HumanoidRootPart' then
					local hrp_id = tostring(self)

					if vstorage.original_properties[hrp_id] and method == 'GetPropertyChangedSignal' then
						if args[1] == 'Size' or args[1] == 'Transparency' or args[1] == 'CanCollide' or args[1] == 'BrickColor' then
							return Instance.new('BindableEvent').Event
						end
					end
				end
			end
		})
	end

	maid.add('hitbox_connection', services.run_service.Heartbeat, function()
		for _, plr in pairs(services.players:GetPlayers()) do
			if plr ~= stuff.owner and plr.Character then
				local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
				if hrp then
					store_original_properties(hrp)

					stuff.rawrbxset(hrp, 'Size', Vector3.new(vstorage.size, vstorage.size, vstorage.size))
					stuff.rawrbxset(hrp, 'Transparency', 0.75)
					stuff.rawrbxset(hrp, 'BrickColor', BrickColor.random())
					stuff.rawrbxset(hrp, 'CanCollide', false)
				end
			end
		end
	end)

	maid.add('hitbox_player_added', services.players.PlayerAdded, function(player)
		if not vstorage.enabled then return end

		maid.add(`hitbox_char_added_{player.UserId}`, player.CharacterAdded, function(character)
			if not vstorage.enabled then return end
			if player == stuff.owner then return end

			task.wait(0.5)
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if hrp then
				store_original_properties(hrp)
			end
		end)
	end)

	for _, player in pairs(services.players:GetPlayers()) do
		if player ~= stuff.owner then
			maid.add(`hitbox_char_added_{player.UserId}`, player.CharacterAdded, function(character)
				if not vstorage.enabled then return end

				task.wait(0.5)
				local hrp = character:FindFirstChild('HumanoidRootPart')
				if hrp then
					store_original_properties(hrp)
				end
			end)
		end
	end
end)

cmd_library.add({'unhitbox', 'untorsosize', 'unexpandhitbox'}, 'disables hitbox expansion', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('hitbox')

	if not vstorage.enabled then
		return notify('hitbox', 'hitbox not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('hitbox_connection')

	if vstorage.bypass then
		hook_lib.destroy_hook('hitbox_bypass')
	end

	for hrp_id, original in pairs(vstorage.original_properties) do
		for _, player in pairs(services.players:GetPlayers()) do
			if player.Character then
				local hrp = player.Character:FindFirstChild('HumanoidRootPart')
				if hrp and tostring(hrp) == hrp_id then
					pcall(stuff.rawrbxset, hrp, 'Size', original.size)
					pcall(stuff.rawrbxset, hrp, 'Transparency', original.transparency)
					pcall(stuff.rawrbxset, hrp, 'CanCollide', original.can_collide)
					pcall(stuff.rawrbxset, hrp, 'BrickColor', original.brick_color)
				end
			end
		end
	end

	vstorage.original_properties = {}

	for _, player in pairs(services.players:GetPlayers()) do
		maid.remove(`hitbox_char_added_{player.UserId}`)
	end

	maid.remove('hitbox_player_added')

	notify('hitbox', 'hitbox disabled', 1)
end)

cmd_library.add({'age', 'accountage'}, 'shows account age', {
	{'player', 'player'}
}, function(vstorage, targets)
	targets = targets or {stuff.owner}

	for _, target in pairs(targets) do
		local days = target.AccountAge
		local creation_date = os.date('*t', os.time() - (days * 86400))

		notify('age', `{target.Name}'s account age: {math.floor(days / 365)} year(s), {math.floor((days % 365) / 30)} month(s), {(days % 365) % 30} day(s) - created on: {creation_date.month}/{creation_date.day}/{creation_date.year}`, 1)
	end
end)

cmd_library.add({'placeid', 'pid'}, 'shows place id', {}, function(vstorage)
	notify('placeid', `place id: {game.PlaceId}`, 1)
end)

cmd_library.add({'jobid', 'jid'}, 'shows job id', {}, function(vstorage)
	notify('jobid', `job id: {game.JobId}`, 1)
end)

cmd_library.add({'fps'}, 'shows current fps', {}, function(vstorage)
	local fps = math.floor(1 / services.run_service.Heartbeat:Wait())
	notify('fps', `fps: {fps}`, 1)
end)

cmd_library.add({'ping'}, 'shows your ping', {}, function(vstorage)
	local ping = stuff.owner:GetNetworkPing() * 1000
	notify('ping', `ping: {math.floor(ping)}ms`, 1)
end)

cmd_library.add({'antiafk', 'noafk'}, 'prevents afk kick', {
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, et)

	if et and vstorage.enabled then
		cmd_library.execute('unantiafk')
		return
	end

	if vstorage.enabled then
		return notify('antiafk', 'anti-afk already enabled', 2)
	end

	vstorage.enabled = true
	notify('antiafk', 'anti-afk enabled', 1)

	pcall(function()
		maid.remove('anti_afk')
	end)

	maid.add('anti_afk', stuff.owner.Idled, function()
		--services.virt_user:CaptureController()
		--services.virt_user:ClickButton2(Vector2.new())
		mouse1click()
	end)
end)

cmd_library.add({'unantiafk', 'unnoafk'}, 'disables anti-afk', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('antiafk')

	if not vstorage.enabled then
		return notify('antiafk', 'anti-afk not enabled', 2)
	end

	vstorage.enabled = false
	notify('antiafk', 'anti-afk disabled', 1)
	maid.remove('anti_afk')
end)

cmd_library.add({'datalimit'}, 'sets outgoing kb/s limit', {
	{'limit', 'number'}
}, function(vstorage, limit)
	services.network_client:SetOutgoingKBPSLimit(limit)
	notify('datalimit', `data limit set to {limit}kb/s`, 1)
end)

cmd_library.add({'stopreplag', 'srl'}, 'sets IncomingReplicationLag to -1', {}, function(vstorage)
	settings():GetService('NetworkSettings').IncomingReplicationLag = -1
	stuff.stopreplag = true 
	notify('stopreplag', 'incoming replication lag set to -1', 1)
end)

cmd_library.add({'freecam', 'fcam'}, 'frees your camera from your character', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unfreecam')
		return
	end
	if vstorage.enabled then
		return notify('freecam','freecam already enabled',1)
	end

	vstorage.enabled = true
	if tonumber(speed) then
		vstorage.speed = tonumber(speed)
	else
		vstorage.speed = 1
	end
	notify('freecam','freecam enabled',1)

	local cam = workspace.CurrentCamera
	vstorage.old_subject = cam.CameraSubject
	vstorage.old_parent = stuff.owner_char.Parent
	vstorage.old_speed = stuff.owner_char:FindFirstChildOfClass('Humanoid').WalkSpeed
	local flight_part = Instance.new('Part', workspace)
	vstorage.part = flight_part
	stuff.owner_char:FindFirstChildOfClass('Humanoid').WalkSpeed = 0
	flight_part.CFrame = stuff.owner_char:GetPivot()
	flight_part.Anchored = true
	flight_part.Transparency = 1
	flight_part.CanCollide = false
	workspace.CurrentCamera.CameraSubject = flight_part
	stuff.owner_char.Parent = nil
	local control_module = require(stuff.owner.PlayerScripts:WaitForChild('PlayerModule'):WaitForChild('ControlModule'))
	maid.add('freecam', services.run_service.Heartbeat, function()
		pcall(function()
			local old_pos = flight_part.Position
			flight_part.CFrame = CFrame.lookAt(old_pos, workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -250).Position)
			stuff.owner_char.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero

			if services.user_input_service:GetFocusedTextBox() == nil then else return end
			local direction = Vector3.new(0,0,0)
			if services.user_input_service:IsKeyDown(Enum.KeyCode.W) then
				direction += Vector3.new(0,0,-1)
			end
			if services.user_input_service:IsKeyDown(Enum.KeyCode.A) then
				direction += Vector3.new(-1,0,0)
			end
			if services.user_input_service:IsKeyDown(Enum.KeyCode.S) then
				direction += Vector3.new(0,0,1)
			end
			if services.user_input_service:IsKeyDown(Enum.KeyCode.D) then
				direction += Vector3.new(1,0,0)
			end
			local offset = Vector3.new(
				direction.X * vstorage.speed,
				direction.Y * vstorage.speed,
				direction.Z * vstorage.speed
			)

			flight_part.CFrame *= CFrame.new(offset)
		end)
	end)
end)

cmd_library.add({'unfreecam', 'unfcam'}, 'reattach camera to character', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('freecam')

	if not vstorage.enabled then
		return notify('freecam','freecam not enabled','1')
	end
	vstorage.enabled = false
	notify('freecam','freecam disabled',1)

	maid.remove('freecam')
	stuff.owner_char.Parent = vstorage.old_parent
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	stuff.owner_char:FindFirstChildOfClass('Humanoid').WalkSpeed = vstorage.old_speed or stuff.default_ws
	workspace.CurrentCamera.CameraSubject = vstorage.old_subject or stuff.owner_char:FindFirstChildOfClass('Humanoid')
	pcall(function()
		stuff.destroy(vstorage.part)
	end)
end)

cmd_library.add({'maxzoom'}, 'sets max camera zoom distance', {
	{'distance', 'number'}
}, function(vstorage, distance)
	distance = distance or 128
	notify('maxzoom', `max zoom set to {distance}`, 1)
	stuff.rawrbxset(stuff.owner, 'CameraMaxZoomDistance', distance)
end)

cmd_library.add({'minzoom'}, 'sets min camera zoom distance', {
	{'distance', 'number'}
}, function(vstorage, distance)
	distance = distance or 0.5
	notify('minzoom', `min zoom set to {distance}`, 1)
	stuff.rawrbxset(stuff.owner, 'CameraMinZoomDistance', distance)
end)

cmd_library.add({'fixcam', 'resetcam'}, 'resets camera properties', {}, function(vstorage)
	notify('fixcam', 'camera reset', 1)

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	stuff.rawrbxset(cam, 'CameraType', Enum.CameraType.Custom)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(cam, 'CameraSubject', humanoid)
	stuff.rawrbxset(cam, 'FieldOfView', 70)
	stuff.rawrbxset(stuff.owner, 'CameraMaxZoomDistance', 128)
	stuff.rawrbxset(stuff.owner, 'CameraMinZoomDistance', 0.5)
end)

cmd_library.add({'deleteplayer', 'delplayer'}, 'deletes a player\'s character client sided', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('deleteplayer', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		if target.Character then
			stuff.destroy(target.Character)
			notify('deleteplayer', `deleted {target.Name}`, 1)
		end
	end
end)

cmd_library.add({'kick'}, 'kicks a player on client side', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('kick', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		pcall(function()
			stuff.rawrbxset(target, 'Parent', nil)
		end)
		notify('kick', `kicked {target.Name}`, 1)
	end
end)

cmd_library.add({'skydive'}, 'launches you into the sky', {
	{'height', 'number'}
}, function(vstorage, height)
	height = height or 500
	notify('skydive', `launching {height} studs up`, 1)

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	if hrp then
		local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
		stuff.rawrbxset(hrp, 'CFrame', hrp_cf + Vector3.new(0, height, 0))
	end
end)

cmd_library.add({'fpsboost', 'performancemode'}, 'optimizes game for better fps', {}, function(vstorage)
	notify('fpsboost', 'applying fps boost', 1)

	for _, v in pairs(workspace:GetDescendants()) do
		pcall(function()
			if v:IsA('BasePart') then
				stuff.rawrbxset(v, 'Material', Enum.Material.SmoothPlastic)
				stuff.rawrbxset(v, 'Reflectance', 0)
			elseif v:IsA('Decal') or v:IsA('Texture') then
				stuff.destroy(v)
			elseif v:IsA('ParticleEmitter') or v:IsA('Trail') or v:IsA('Smoke') or v:IsA('Fire') or v:IsA('Sparkles') then
				stuff.destroy(v)
			elseif v:IsA('MeshPart') then
				stuff.rawrbxset(v, 'Material', Enum.Material.SmoothPlastic)
				stuff.rawrbxset(v, 'Reflectance', 0)
				stuff.rawrbxset(v, 'TextureID', '')
			elseif v:IsA('SpecialMesh') then
				stuff.rawrbxset(v, 'TextureId', '')
			end
		end)
	end

	for _, v in pairs(services.lighting:GetChildren()) do
		if not v:IsA('Sky') and not v:IsA('Atmosphere') then
			pcall(stuff.destroy, v)
		end
	end

	pcall(function()
		stuff.rawrbxset(services.lighting, 'GlobalShadows', false)
		stuff.rawrbxset(services.lighting, 'FogEnd', 100000)
		stuff.rawrbxset(services.lighting, 'Brightness', 1)
	end)

	notify('fpsboost', 'fps boost applied', 1)
end)

cmd_library.add({'copyid'}, 'copies a player\'s user id to clipboard', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('copyid', 'player not found', 2)
	end

	local target = targets[1]
	setclipboard(tostring(target.UserId))
	notify('copyid', `copied {target.Name}'s id: {target.UserId}`, 1)
end)

cmd_library.add({'copyplace'}, 'copies place id to clipboard', {}, function(vstorage)
	setclipboard(tostring(game.PlaceId))
	notify('copyplace', `copied place id: {game.PlaceId}`, 1)
end)

cmd_library.add({'copyjob'}, 'copies job id to clipboard', {}, function(vstorage)
	setclipboard(game.JobId)
	notify('copyjob', 'copied job id', 1)
end)

cmd_library.add({'coords', 'position', 'pos'}, 'shows your current position', {}, function(vstorage)
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local pos = stuff.rawrbxget(hrp, 'Position')
	notify('coords', `position: {math.floor(pos.X)}, {math.floor(pos.Y)}, {math.floor(pos.Z)}`, 1)
end)

cmd_library.add({'saveinstance', 'savegame'}, 'saves the game instance', {}, function(vstorage)
	notify('saveinstance', 'saving instance', 1)
	saveinstance(game)
end)

cmd_library.add({'zerovelocity', 'zerovel', 'novel'}, 'stops all velocity on your character', {}, function(vstorage)
	notify('zerovelocity', 'velocity stopped', 1)

	for _, part in pairs(stuff.owner_char:GetDescendants()) do
		if part:IsA('Part') or part:IsA("MeshPart") then
			stuff.rawrbxset(part, 'Velocity', Vector3.zero)
			stuff.rawrbxset(part, 'RotVelocity', Vector3.zero)
			stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.zero)
			stuff.rawrbxset(part, 'AssemblyAngularVelocity', Vector3.zero)
		end
	end
end)

cmd_library.add({'chat', 'say'}, 'says something in chat', {
	{['...'] = 'string'}
}, function(vstorage, ...)
	local message = table.concat({...}, ' ')
	if message == '' then
		return notify('chat', 'provide a message to say', 2)
	end

	notify('chat', `saying '{message}'`, 1)

	if services.text_chat_service.ChatVersion == Enum.ChatVersion.TextChatService then
		services.text_chat_service.TextChannels.RBXGeneral:SendAsync(message)
	else
		services.replicated_storage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, 'All')
	end
end)



cmd_library.add({'spamchat'}, 'spams chat with a message', {
	{'interval', 'number'}
}, function(vstorage, interval, ...)
	if vstorage.enabled then
		return notify('spamchat', 'spam chat already enabled', 2)
	end

	local message = table.concat({...}, ' ')
	if message == '' then
		return notify('spamchat', 'provide a message to spam', 2)
	end

	interval = interval or 0.5

	vstorage.enabled = true
	vstorage.message = message
	notify('spamchat', `spamming '{message}'`, 1)

	task.spawn(function()
		while task.wait(interval) and vstorage.enabled do
			if services.text_chat_service.ChatVersion == Enum.ChatVersion.TextChatService then
				pcall(function()
					services.text_chat_service.TextChannels.RBXGeneral:SendAsync(vstorage.message)
				end)
			else
				pcall(function()
					services.replicated_storage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(vstorage.message, 'All')
				end)
			end
		end
	end)
end)

cmd_library.add({'unspamchat'}, 'stops spam chat', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('spamchat')

	if not vstorage.enabled then
		return notify('spamchat', 'spam chat not enabled', 2)
	end

	vstorage.enabled = false
	notify('spamchat', 'spam chat disabled', 1)
end)

cmd_library.add({'autopickup', 'apickup'}, 'automatically picks up tools', {
	{'range', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, range, et)
	if not firetouchinterest then
		return notify('autopickup', 'firetouchinterest not found', 2)
	end

	if et and vstorage.enabled then
		cmd_library.execute('unautopickup')
		return
	end
	if vstorage.enabled then
		return notify('autopickup', 'auto pickup already enabled', 2)
	end

	range = range or 10

	vstorage.enabled = true
	notify('autopickup', 'auto pickup enabled', 1)

	maid.add('auto_pickup', services.run_service.Heartbeat, function()
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		local hrp_pos = stuff.rawrbxget(hrp, 'Position')

		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA('Tool') and v:FindFirstChild('Handle') then
				local handle_pos = stuff.rawrbxget(v.Handle, 'Position')
				if (hrp_pos - handle_pos).Magnitude <= range then
					firetouchinterest(v.Handle, hrp, 0)
					firetouchinterest(v.Handle, hrp, 1)
				end
			end
		end
	end)
end)

cmd_library.add({'unautopickup', 'unapickup'}, 'disables auto pickup', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('autopickup')

	if not vstorage.enabled then
		return notify('autopickup', 'auto pickup not enabled', 2)
	end

	vstorage.enabled = false
	notify('autopickup', 'auto pickup disabled', 1)
	maid.remove('auto_pickup')
end)

cmd_library.add({'loop'}, 'loops a command at specified interval', {
	{'interval', 'number'},
	{'command', 'string'},
	{['...'] = 'string'}
}, function(vstorage, interval, cmd_name, ...)
	if not cmd_name then
		return notify('loop', 'no command specified', 2)
	end

	interval = interval or 0.5
	local args = {...}

	local similar = cmd_library.find_similar(cmd_name:lower())
	local matched = false
	for _, name in pairs(similar) do
		if name:lower() == cmd_name:lower() then
			matched = true
			break
		end
	end

	if not matched then
		if #similar > 0 then
			return notify('loop', `command '{cmd_name}' not found. did you mean: {table.concat(similar, ', ')}?`, 2)
		else
			return notify('loop', `command '{cmd_name}' not found`, 2)
		end
	end

	vstorage.loops = vstorage.loops or {}
	local loop_id = `loop_{cmd_name:lower()}`

	if vstorage.loops[loop_id] then
		maid.remove(loop_id)
		vstorage.loops[loop_id] = nil
	end

	vstorage.loops[loop_id] = {
		command = cmd_name:lower(),
		args = args,
		interval = interval
	}

	notify('loop', `looping '{cmd_name}' every {interval}s`, 1)

	task.spawn(function()
		while vstorage.loops[loop_id] do
			cmd_library.execute(cmd_name:lower(), unpack(args))
			task.wait(interval)
		end
	end)
end)

cmd_library.add({'unloop'}, 'stops looping a command', {
	{'command', 'string'}
}, function(vstorage, cmd_name)
	local loop_vs = cmd_library.get_variable_storage('loop')

	if not loop_vs or not loop_vs.loops then
		return notify('unloop', 'no active loops', 2)
	end

	if cmd_name then
		local loop_id = `loop_{cmd_name:lower()}`
		if loop_vs.loops[loop_id] then
			loop_vs.loops[loop_id] = nil
			notify('unloop', `stopped looping '{cmd_name}'`, 1)
		else
			notify('unloop', `no loop found for '{cmd_name}'`, 2)
		end
	else
		local count = 0
		for _ in pairs(loop_vs.loops) do
			count = count + 1
		end
		loop_vs.loops = {}
		notify('unloop', `stopped {count} loops`, 1)
	end
end)

cmd_library.add({'spam'}, 'spams a command', {
	{'times', 'number'},
	{['...'] = 'string'}
}, function(vstorage, times, ...)
	times = times or 10
	local args = {...}
	local cmd_name = args[1]
	table.remove(args, 1)

	notify('spam', `spamming command '{cmd_name}' {times} times`, 1)

	for i = 1, times do
		cmd_library.execute(cmd_name, unpack(args))
		task.wait(0.1)
	end
end)

cmd_library.add({'reach'}, 'sets tool reach', {
	{'size', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, size, et)
	if et and vstorage.enabled then
		cmd_library.execute('unreach')
		return
	end
	size = size or 10

	if vstorage.enabled then
		return notify('reach', 'reach already enabled', 2)
	end

	vstorage.enabled = true
	notify('reach', `reach set to {size}`, 1)

	pcall(function()
		maid.remove('reach')
	end)

	maid.add('reach', services.run_service.Heartbeat, function()
		for _, tool in pairs(stuff.owner_char:GetChildren()) do
			if tool:IsA('Tool') and tool:FindFirstChild('Handle') then
				stuff.rawrbxset(tool.Handle, 'Size', Vector3.new(size, size, size))
				stuff.rawrbxset(tool.Handle, 'Transparency', 0.5)
			end
		end
	end)
end)

cmd_library.add({'unreach'}, 'disables reach', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('reach')

	if not vstorage.enabled then
		return notify('reach', 'reach not enabled', 2)
	end

	vstorage.enabled = false
	notify('reach', 'reach disabled', 1)
	maid.remove('reach')
end)

stuff.real_char, stuff.fakechars = nil, {}
cmd_library.add({'fakecharacter', 'fakechar', 'fc'}, 'creates a r6 fake character that you can control', {}, function(vstorage)
	notify('fakecharacter', 'creating r6 fake character', 1)

	local desc = services.players:GetHumanoidDescriptionFromUserId(stuff.owner.UserId)
	local new_character = services.players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R6)
	stuff.rawrbxset(new_character, 'Name', stuff.owner.Name)

	local humanoid = stuff.rawrbxget(new_character, 'Humanoid')
	stuff.rawrbxset(humanoid, 'DisplayName', stuff.owner.DisplayName)

	if not stuff.real_char then
		stuff.real_char = stuff.owner_char
		stuff.rawrbxset(stuff.real_char, 'Parent', nil)
	else
		table.insert(stuff.fakechars, stuff.owner_char)
	end

	new_character:PivotTo(stuff.owner_char:GetPivot())
	stuff.rawrbxset(stuff.owner, 'Character', new_character)
	stuff.owner_char = new_character
	stuff.rawrbxset(new_character, 'Parent', workspace)
end)

cmd_library.add({'r15fakecharacter', 'r15fakechar', 'r15fc'}, 'creates a r15 fake character that you can control', {}, function(vstorage)
	notify('r15fakecharacter', 'creating r15 fake character', 1)

	local desc = services.players:GetHumanoidDescriptionFromUserId(stuff.owner.UserId)
	local new_character = services.players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	stuff.rawrbxset(new_character, 'Name', stuff.owner.Name)

	local humanoid = stuff.rawrbxget(new_character, 'Humanoid')
	stuff.rawrbxset(humanoid, 'DisplayName', stuff.owner.DisplayName)

	if not stuff.real_char then
		stuff.real_char = stuff.owner_char
		stuff.rawrbxset(stuff.real_char, 'Parent', nil)
	else
		table.insert(stuff.fakechars, stuff.owner_char)
	end

	new_character:PivotTo(stuff.owner_char:GetPivot())
	stuff.rawrbxset(stuff.owner, 'Character', new_character)
	stuff.owner_char = new_character
	stuff.rawrbxset(new_character, 'Parent', workspace)
end)

cmd_library.add({'unfakecharacter', 'unfakechar', 'unfc'}, 'brings you back to your real character', {}, function(vstorage)
	if not stuff.real_char then
		return notify('unfakecharacter', 'you are not using a fake character', 2)
	end

	notify('unfakecharacter', 'returning to real character', 1)

	local current_pos = stuff.owner_char:GetPivot()

	for _, fake in pairs(stuff.fakechars) do
		pcall(stuff.destroy, fake)
	end

	if stuff.owner_char ~= stuff.real_char then
		pcall(stuff.destroy, stuff.owner_char)
	end

	stuff.rawrbxset(stuff.real_char, 'Parent', workspace)
	stuff.rawrbxset(stuff.owner, 'Character', stuff.real_char)
	stuff.owner_char = stuff.real_char
	task.wait(0.2)
	stuff.real_char:PivotTo(current_pos)

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	local humanoid = stuff.rawrbxget(stuff.real_char, 'Humanoid')
	stuff.rawrbxset(cam, 'CameraSubject', humanoid)

	for _, v in pairs(stuff.real_char:GetDescendants()) do
		if v:IsA('LocalScript') then
			stuff.rawrbxset(v, 'Enabled', false)
			stuff.rawrbxset(v, 'Enabled', true)
		end
	end

	table.clear(stuff.fakechars)
	stuff.real_char = nil
end)

cmd_library.add({"revive"},'attempts to stop oneshots',{},function(vstorage)
	notify("revive","activated revive",1)
	local pc = stuff.owner_char
	local Older;Older=pc:FindFirstChildOfClass("Humanoid").Health
	local reload = true
	task.spawn(function()
		repeat
			game:GetService("RunService").RenderStepped:Wait()
			pcall(function()
				if pc:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.FallingDown and pc:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Swimming and pc:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Seated and pc:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Jumping and  pc:FindFirstChildOfClass("Humanoid"):GetState() ~= Enum.HumanoidStateType.Freefall then
					pc:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Running)
				end
			end)
		until rawequal(reload,false)
	end)
	task.spawn(function()
		repeat
			task.wait(0.13)
			pcall(function()
				if rawequal(reload,true) then
					Older=pc:FindFirstChildOfClass("Humanoid").Health
				end
			end)
		until pc:FindFirstChildOfClass("Humanoid").Health <= 0
	end)
	local idk
	pc:FindFirstChildOfClass("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead,false)
	pc:FindFirstChildOfClass("Humanoid").RequiresNeck = false
	pc:FindFirstChildOfClass("Humanoid").BreakJointsOnDeath = false
	idk = pc:FindFirstChildOfClass("Humanoid"):GetPropertyChangedSignal("Health"):Connect(function()
		local r;r = pc:FindFirstChildOfClass("Humanoid").Health
		pc:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Running)
		if tonumber(Older)>tonumber(r) then
			pc:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Running)
			pc:FindFirstChildOfClass("Humanoid"):SetStateEnabled(Enum.HumanoidStateType.Dead,false)
			pc:FindFirstChildOfClass("Humanoid").Parent = game:GetService("ReplicatedStorage")
			game:GetService("ReplicatedStorage"):FindFirstChild("Humanoid").Parent = pc
			if r<=5 then
				idk:Disconnect()
				delay(0.02,function()
					reload = false
				end)
			end
		else
			Older = r
		end
	end)
end)

cmd_library.add({'discord', 'invite'}, 'copies the discord invite', {}, function(vstorage)
	if setclipboard then
		setclipboard('https://discord.gg/StHSWMjcnk')
		notify('discord', 'discord invite copied to clipboard', 1)
	else
		notify('discord', 'setclipboard not supported', 2)
	end
end)

cmd_library.add({'btools', 'bt'}, 'gives client-sided btools', {}, function(vstorage)
	local Clone = Instance.new('HopperBin')
	local Hammer = Instance.new('HopperBin')
	local Grab = Instance.new('HopperBin')

	stuff.rawrbxset(Clone, 'BinType', Enum.BinType.Clone)
	stuff.rawrbxset(Hammer, 'BinType', Enum.BinType.Hammer)
	stuff.rawrbxset(Grab, 'BinType', Enum.BinType.Grab)

	stuff.rawrbxset(Clone, 'Parent', stuff.owner.Backpack)
	stuff.rawrbxset(Hammer, 'Parent', stuff.owner.Backpack)
	stuff.rawrbxset(Grab, 'Parent', stuff.owner.Backpack)

	notify('btools', 'gave btools', 1)
end)

-- c3: fun/trolling

cmd_library.add({'bhop', 'bunnyhop', 'strafe'}, 'bunnyhop yes', {
	{'max_speed', 'number'},
	{'acceleration', 'number'},
	{'air_accel', 'number'},
	{'auto_hop', 'boolean'},
	{'auto_strafe', 'boolean'},
	{'scroll_jump', 'boolean'},
	{'show_speed', 'boolean'},
	{'ground_friction', 'number'}
}, function(vstorage, max_speed, acceleration, air_accel, auto_hop, auto_strafe, scroll_jump, show_speed, ground_friction)
	if vstorage.enabled then
		return notify('bhop', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.max_speed = math.clamp(max_speed or 80, 16, 300)
	vstorage.acceleration = math.clamp(acceleration or 12, 1, 100)
	vstorage.air_accel = math.clamp(air_accel or 100, 1, 500)
	vstorage.auto_hop = auto_hop ~= false
	vstorage.auto_strafe = auto_strafe or false
	vstorage.scroll_jump = scroll_jump ~= false
	vstorage.show_speed = show_speed or false
	vstorage.ground_friction = math.clamp(ground_friction or 4, 0, 20)

	vstorage.holding_jump = false
	vstorage.last_mouse_delta = 0
	vstorage.was_grounded = true
	vstorage.speed_label = nil
	vstorage.last_scroll = 0
	vstorage.scroll_queue = 0

	notify('bhop', `enabled | max: {vstorage.max_speed} | accel: {vstorage.acceleration} | air: {vstorage.air_accel} | auto hop: {vstorage.auto_hop} | auto strafe: {vstorage.auto_strafe}`, 1)

	if vstorage.show_speed then
		local gui = Instance.new('ScreenGui')
		gui.ResetOnSpawn = false
		gui.IgnoreGuiInset = true

		local label = Instance.new('TextLabel')
		label.Name = 'speed'
		label.Size = UDim2.new(0, 200, 0, 50)
		label.Position = UDim2.new(0.5, -100, 0.85, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextStrokeTransparency = 0.5
		label.TextStrokeColor3 = Color3.new(0, 0, 0)
		label.Font = Enum.Font.Code
		label.TextSize = 24
		label.Text = '0 u/s'
		label.Parent = gui

		protect_gui(gui)
		vstorage.speed_label = label
		vstorage.speed_gui = gui
	end

	local function is_grounded()
		local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
		if not hrp then return true end

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {stuff.owner_char}
		params.FilterType = Enum.RaycastFilterType.Exclude

		local result = workspace:Raycast(hrp.Position, Vector3.new(0, -3.2, 0), params)
		return result ~= nil
	end

	local function get_horizontal_speed(vel)
		return Vector3.new(vel.X, 0, vel.Z).Magnitude
	end

	local function get_move_direction()
		local camera = workspace.CurrentCamera
		local look = camera.CFrame.LookVector
		local right = camera.CFrame.RightVector

		local forward = Vector3.new(look.X, 0, look.Z)
		if forward.Magnitude > 0 then forward = forward.Unit end

		local side = Vector3.new(right.X, 0, right.Z)
		if side.Magnitude > 0 then side = side.Unit end

		local dir = Vector3.zero
		local uis = services.user_input_service

		if uis:IsKeyDown(Enum.KeyCode.W) then dir += forward end
		if uis:IsKeyDown(Enum.KeyCode.S) then dir -= forward end
		if uis:IsKeyDown(Enum.KeyCode.D) then dir += side end
		if uis:IsKeyDown(Enum.KeyCode.A) then dir -= side end

		return dir.Magnitude > 0 and dir.Unit or Vector3.zero
	end

	local function get_strafe_direction()
		local camera = workspace.CurrentCamera
		local right = camera.CFrame.RightVector
		local side = Vector3.new(right.X, 0, right.Z)
		if side.Magnitude > 0 then side = side.Unit end

		local uis = services.user_input_service
		local dir = Vector3.zero

		if uis:IsKeyDown(Enum.KeyCode.D) then dir += side end
		if uis:IsKeyDown(Enum.KeyCode.A) then dir -= side end

		return dir.Magnitude > 0 and dir.Unit or Vector3.zero
	end

	local function air_accelerate(velocity, wish_dir, wish_speed, dt)
		if wish_dir.Magnitude == 0 then return velocity end

		local current_speed = velocity:Dot(wish_dir)
		local add_speed = wish_speed - current_speed

		if add_speed <= 0 then return velocity end

		local accel_speed = vstorage.air_accel * wish_speed * dt
		if accel_speed > add_speed then
			accel_speed = add_speed
		end

		return velocity + wish_dir * accel_speed
	end

	local function ground_accelerate(velocity, wish_dir, wish_speed, dt)
		if wish_dir.Magnitude == 0 then
			local speed = velocity.Magnitude
			if speed < 0.1 then return Vector3.zero end

			local drop = speed * vstorage.ground_friction * dt
			local new_speed = math.max(speed - drop, 0)
			return velocity.Unit * new_speed
		end

		local current_speed = velocity:Dot(wish_dir)
		local add_speed = wish_speed - current_speed

		if add_speed <= 0 then return velocity end

		local accel_speed = vstorage.acceleration * wish_speed * dt
		if accel_speed > add_speed then
			accel_speed = add_speed
		end

		return velocity + wish_dir * accel_speed
	end

	maid.add('bhop_input', services.user_input_service.InputBegan, function(input, gpe)
		if gpe then return end

		if input.KeyCode == Enum.KeyCode.Space then
			vstorage.holding_jump = true
		end

		if vstorage.scroll_jump and input.UserInputType == Enum.UserInputType.MouseWheel then
			vstorage.scroll_queue += 1
			vstorage.last_scroll = tick()
		end
	end)

	maid.add('bhop_input_end', services.user_input_service.InputEnded, function(input)
		if input.KeyCode == Enum.KeyCode.Space then
			vstorage.holding_jump = false
		end
	end)

	maid.add('bhop_mouse', services.user_input_service.InputChanged, function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			vstorage.last_mouse_delta = input.Delta.X
		end
	end)

	maid.add('bhop', services.run_service.Heartbeat, function(dt)
		if not vstorage.enabled or not stuff.owner_char then return end

		local hum = stuff.owner_char:FindFirstChildOfClass('Humanoid')
		local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
		if not hum or not hrp then return end

		local grounded = is_grounded()
		local state = hum:GetState()
		local in_air = state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping

		local current_vel = hrp.AssemblyLinearVelocity
		local horizontal_vel = Vector3.new(current_vel.X, 0, current_vel.Z)
		local horizontal_speed = horizontal_vel.Magnitude

		if vstorage.speed_label then
			local color
			if horizontal_speed > vstorage.max_speed * 0.8 then
				color = Color3.fromRGB(255, 100, 100)
			elseif horizontal_speed > vstorage.max_speed * 0.5 then
				color = Color3.fromRGB(255, 255, 100)
			else
				color = Color3.fromRGB(100, 255, 100)
			end
			vstorage.speed_label.TextColor3 = color
			vstorage.speed_label.Text = string.format('%.1f u/s', horizontal_speed)
		end

		local should_jump = false

		if vstorage.auto_hop and vstorage.holding_jump then
			should_jump = true
		end

		if vstorage.scroll_jump and vstorage.scroll_queue > 0 then
			if tick() - vstorage.last_scroll < 0.3 then
				should_jump = true
				vstorage.scroll_queue -= 1
			else
				vstorage.scroll_queue = 0
			end
		end

		if should_jump and grounded and not vstorage.was_grounded then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		elseif should_jump and grounded and state ~= Enum.HumanoidStateType.Jumping then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		vstorage.was_grounded = grounded
		
		if in_air then
			local wish_dir
			local wish_speed = vstorage.max_speed * 0.1

			if vstorage.auto_strafe and math.abs(vstorage.last_mouse_delta) > 1 then
				local camera = workspace.CurrentCamera
				local right = camera.CFrame.RightVector
				local side = Vector3.new(right.X, 0, right.Z)
				if side.Magnitude > 0 then side = side.Unit end

				wish_dir = side * math.sign(vstorage.last_mouse_delta)
				wish_speed = vstorage.max_speed * 0.15
			else
				wish_dir = get_strafe_direction()

				if wish_dir.Magnitude == 0 then
					wish_dir = get_move_direction()
					wish_speed = vstorage.max_speed * 0.05
				end
			end

			local new_vel = air_accelerate(horizontal_vel, wish_dir, wish_speed, dt)
			
			local new_speed = new_vel.Magnitude
			if new_speed > vstorage.max_speed then
				new_vel = new_vel.Unit * vstorage.max_speed
			end

			hrp.AssemblyLinearVelocity = Vector3.new(new_vel.X, current_vel.Y, new_vel.Z)
		else
			local wish_dir = get_move_direction()
			local new_vel = ground_accelerate(horizontal_vel, wish_dir, vstorage.max_speed, dt)

			local new_speed = new_vel.Magnitude
			if new_speed > vstorage.max_speed then
				new_vel = new_vel.Unit * vstorage.max_speed
			end

			hrp.AssemblyLinearVelocity = Vector3.new(new_vel.X, current_vel.Y, new_vel.Z)
		end

		vstorage.last_mouse_delta *= 0.85
	end)

	maid.add('bhop_respawn', stuff.owner.CharacterAdded, function(char)
		if not vstorage.enabled then return end
		char:WaitForChild('HumanoidRootPart')
		task.wait(.1)
		vstorage.was_grounded = true
		vstorage.scroll_queue = 0
	end)
end)

cmd_library.add({'unbhop', 'unbunnyhop', 'unstrafe'}, 'disables bhop', {}, function()
	local vs = cmd_library.get_variable_storage('bhop')
	if not vs.enabled then
		return notify('bhop', 'not enabled', 2)
	end

	vs.enabled = false

	maid.remove('bhop')
	maid.remove('bhop_input')
	maid.remove('bhop_input_end')
	maid.remove('bhop_mouse')
	maid.remove('bhop_respawn')

	if vs.speed_gui then
		vs.speed_gui:Destroy()
		vs.speed_gui = nil
		vs.speed_label = nil
	end

	notify('bhop', 'disabled', 1)
end)

cmd_library.add({'copychat'}, 'copies all chat messages', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('copychat', 'chat spy enabled', 1)

		for _, plr in pairs(services.players:GetPlayers()) do
			if plr ~= stuff.owner then
				maid.add(`copychat_{plr.Name}`, plr.Chatted, function(message)
					notify('chatspy', `{plr.Name}: {message}`, 4)
				end)
			end
		end

		maid.add('copychat_playeradded', services.players.PlayerAdded, function(plr)
			if vstorage.enabled then
				maid.add(`copychat_{plr.Name}`, plr.Chatted, function(message)
					notify('chatspy', `{plr.Name}: {message}`, 4)
				end)
			end
		end)
	else
		notify('copychat', 'chat spy disabled', 1)

		for _, plr in pairs(services.players:GetPlayers()) do
			maid.remove(`copychat_{plr.Name}`)
		end

		maid.remove('copychat_playeradded')
	end
end)

cmd_library.add({'uncopychat'}, 'disables copychat', {}, function(vstorage)
	local copychat_vs = cmd_library.get_variable_storage('copychat')

	if not copychat_vs or not copychat_vs.enabled then
		return notify('copychat', 'chat spy not enabled', 2)
	end

	copychat_vs.enabled = false

	for _, plr in pairs(services.players:GetPlayers()) do
		maid.remove(`copychat_{plr.Name}`)
	end

	maid.remove('copychat_playeradded')

	notify('copychat', 'chat spy disabled', 1)
end)

cmd_library.add({'netlag'}, 'glitches netless/reanimation users', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('netlag', 'no player specified', 2)
	end

	vstorage.connections = vstorage.connections or {}

	for _, target in targets do
		if target.Character then
			local connection_id = `netlag_{target.Name}`

			if vstorage.connections[connection_id] then
				maid.remove(connection_id)
			end

			maid.add(connection_id, services.run_service.Heartbeat, function()
				if target.Character then
					for _, v in pairs(target.Character:GetDescendants()) do
						if v:IsA('BasePart') then
							pcall(sethiddenproperty, v, 'NetworkIsSleeping', false)
						end
					end
				else
					maid.remove(connection_id)
					vstorage.connections[connection_id] = nil
				end
			end)

			vstorage.connections[connection_id] = true
			notify('netlag', `netlagging {target.Name}`, 1)
		end
	end
end)

cmd_library.add({'unnetlag'}, 'stops netlagging', {
	{'player', 'player'}
}, function(vstorage, targets)
	local netlag_vs = cmd_library.get_variable_storage('netlag')

	if not netlag_vs or not netlag_vs.connections then
		return notify('netlag', 'no active netlags', 2)
	end

	if targets and #targets > 0 then
		for _, target in targets do
			local connection_id = `netlag_{target.Name}`
			if netlag_vs.connections[connection_id] then
				maid.remove(connection_id)
				netlag_vs.connections[connection_id] = nil
				notify('netlag', `stopped netlagging {target.Name}`, 1)
			end
		end
	else
		for connection_id in pairs(netlag_vs.connections) do
			maid.remove(connection_id)
		end
		netlag_vs.connections = {}
		notify('netlag', 'stopped all netlags', 1)
	end
end)

cmd_library.add({'spook', 'jumpscare'}, 'teleport in front of someone briefly', {
	{'player', 'player'},
	{'duration', 'number'}
}, function(vstorage, players, duration)
	if not players or #players == 0 then
		return notify('spook', 'no player specified', 2)
	end

	duration = duration or 0.5

	local char = stuff.owner.Character
	if not char or not char:FindFirstChild('HumanoidRootPart') then
		return notify('spook', 'character not found', 2)
	end

	local hrp = char.HumanoidRootPart
	local original_cf = stuff.rawrbxget(hrp, 'CFrame')

	for _, plr in players do
		if plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
			local target_hrp = plr.Character.HumanoidRootPart
			local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
			char:PivotTo(target_cf * CFrame.new(0, 0, -3) * CFrame.Angles(0, math.rad(180), 0))
			task.wait(duration)
			char:PivotTo(original_cf)
			notify('spook', `spooked {plr.Name}`, 1)
		end
	end
end)

cmd_library.add({'annoy'}, 'teleport spam around a player', {
	{'player', 'player'},
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, targets, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unannoy')
		return
	end

	if not targets or #targets == 0 then
		return notify('annoy', 'player not found', 2)
	end

	local target = targets[1]
	if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
		return notify('annoy', `{target.Name} has no character`, 2)
	end

	if vstorage.enabled then
		return notify('annoy', 'annoy already active, use unannoy first', 2)
	end

	vstorage.enabled = true
	vstorage.target = target
	vstorage.speed = speed or 0.1

	notify('annoy', `now annoying {target.Name}`, 1)

	local positions = {
		CFrame.new(5, 0, 0),
		CFrame.new(-5, 0, 0),
		CFrame.new(0, 5, 0),
		CFrame.new(0, -5, 0),
		CFrame.new(0, 0, 5),
		CFrame.new(0, 0, -5),
		CFrame.new(3, 3, 3),
		CFrame.new(-3, -3, -3)
	}

	local index = 1

	maid.add('annoy_connection', services.run_service.Heartbeat, function()
		if not vstorage.enabled then
			maid.remove('annoy_connection')
			return
		end

		if not vstorage.target.Character or not vstorage.target.Character:FindFirstChild('HumanoidRootPart') then
			vstorage.enabled = false
			maid.remove('annoy_connection')
			notify('annoy', 'target lost, stopping annoy', 2)
			return
		end

		local target_hrp = stuff.rawrbxget(vstorage.target.Character, 'HumanoidRootPart')
		local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')

		pcall(function()
			stuff.owner_char:PivotTo(target_cf * positions[index])
			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'Velocity', Vector3.zero)
		end)

		if tick() % vstorage.speed < 0.016 then
			index = index % #positions + 1
		end
	end)
end)

cmd_library.add({'unannoy'}, 'stops annoying', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('annoy')

	if not vstorage.enabled then
		return notify('annoy', 'annoy is not active', 2)
	end

	vstorage.enabled = false
	maid.remove('annoy_connection')
	notify('annoy', 'stopped annoying', 1)
end)

cmd_library.add({'instakillreach', 'instksreach'}, 'always applies newest damage inflicted 50 times and adds reach', {
	{'reach', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, reach, et)
	if not firetouchinterest then
		return notify('instakillreach', 'firetouchinterest not found', 2)
	end

	if et and vstorage.enabled then
		cmd_library.execute('uninstakillreach')
		return
	end
	reach = reach or 40

	local tool = stuff.owner_char:FindFirstChildOfClass('Tool') or stuff.owner.Backpack:FindFirstChildOfClass('Tool')
	if not tool then 
		return notify('instakillreach', 'equip a tool and maybe then we\'ll see', 2) 
	end

	if vstorage.enabled then
		return notify('instakillreach', 'instakillreach already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.tool = tool
	notify('instakillreach', 'enabled instakillreach', 1)

	maid.add('instks_sword_activated', tool.Activated, function()
		pcall(function()
			local tool_handle = stuff.rawrbxget(tool, 'Handle')
			local handle_pos = stuff.rawrbxget(tool_handle, 'Position')

			for _, v in pairs(workspace:GetDescendants()) do
				if (v.Name == 'HumanoidRootPart' or v.Name == 'Head') and v.Parent:FindFirstChildOfClass('Humanoid') then
					local v_pos = stuff.rawrbxget(v, 'Position')
					if (handle_pos - v_pos).Magnitude <= reach then
						for i = 1, 50 do
							firetouchinterest(v, tool_handle, 0)
							firetouchinterest(v, tool_handle, 1)
							task.wait()
						end
					end
				end
			end
		end)
	end)
end)

cmd_library.add({'uninstakillreach', 'uninstksreach'}, 'disable instakillreach', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('instakillreach')

	if not vstorage.enabled then
		return notify('instakillreach', 'instakillreach not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('instks_sword_activated')
	notify('instakillreach', 'disabled instakillreach', 1)
end)

cmd_library.add({'grabtp'}, 'only works on ink game, you also need takedown ability', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('grabtp', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		notify('grabtp', `bringing {target.Name} to you`, 1)

		local old_pos = stuff.owner_char:GetPivot()
		local takedown = stuff.owner.Backpack:FindFirstChild('Takedown') or stuff.owner_char:FindFirstChild('Takedown')

		if not takedown then
			return notify('grabtp', 'takedown ability not found', 2)
		end

		local local_humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		local target_character = target.Character

		if not target_character then
			notify('grabtp', `{target.Name} has no character`, 2)
			continue
		end

		local target_humanoid = stuff.rawrbxget(target_character, 'Humanoid')

		if stuff.rawrbxget(takedown, 'Parent') ~= stuff.owner_char then
			local_humanoid:EquipTool(takedown)
		end

		local move_direction = stuff.rawrbxget(target_humanoid, 'MoveDirection')
		if move_direction ~= Vector3.zero then
			stuff.owner_char:PivotTo(quick_predict_position(target, 20))
		else
			local target_hrp = stuff.rawrbxget(target_character, 'HumanoidRootPart')
			local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
			stuff.owner_char:PivotTo(target_cf * CFrame.new(0, 0, 3))
		end

		task.wait(1)

		local_humanoid:UnequipTools()
		stuff.owner_char:PivotTo(old_pos)
	end
end)

cmd_library.add({'mirror', 'mimic'}, 'become their mirror and copy their movements', {
	{'player', 'player'},
	{'distance', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, targets, distance, et)
	if et and vstorage.enabled then
		cmd_library.execute('unmirror')
		return
	end
	if not targets or #targets == 0 then
		return notify('mirror', 'player not found', 2)
	end

	local target = targets[1]
	if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
		return notify('mirror', `{target.Name} has no character`, 2)
	end

	if vstorage.target then
		return notify('mirror', `already mirroring {vstorage.target.Name}, use unmirror first`, 2)
	end

	vstorage.enabled = true
	vstorage.target = target
	vstorage.distance = distance or 5

	notify('mirror', `now mirroring {target.Name}`, 1)

	maid.add('mirror_connection', services.run_service.Heartbeat, function()
		pcall(function()
			if not vstorage.target or not vstorage.target.Character or not vstorage.target.Character:FindFirstChild('HumanoidRootPart') then
				maid.remove('mirror_connection')
				vstorage.target = nil
				vstorage.enabled = false
				return
			end

			local target_hrp = stuff.rawrbxget(vstorage.target.Character, 'HumanoidRootPart')
			local target_humanoid = stuff.rawrbxget(vstorage.target.Character, 'Humanoid')
			local local_humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')

			if target_humanoid and local_humanoid then
				local offset = CFrame.new(0, 0, vstorage.distance)
				local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
				local mirror_cf = target_cf * offset

				stuff.owner_char:PivotTo(mirror_cf)

				local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
				stuff.rawrbxset(hrp, 'Velocity', Vector3.zero)
				stuff.rawrbxset(hrp, 'RotVelocity', Vector3.zero)

				local target_jump = stuff.rawrbxget(target_humanoid, 'Jump')
				if target_jump then
					stuff.rawrbxset(local_humanoid, 'Jump', true)
				end

				local target_sit = stuff.rawrbxget(target_humanoid, 'Sit')
				if target_sit then
					stuff.rawrbxset(local_humanoid, 'Sit', true)
				end
			end
		end)
	end)
end)

cmd_library.add({'unmirror', 'unmimic'}, 'stop mirroring', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('mirror')

	if vstorage.target then
		notify('mirror', `stopped mirroring {vstorage.target.Name}`, 1)
		vstorage.target = nil
		vstorage.enabled = false
		maid.remove('mirror_connection')
	else
		notify('mirror', 'you are not mirroring anyone', 2)
	end
end)

cmd_library.add({'fling'}, 'uses velocity to fling people', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('fling', 'player not found', 2)
	end

	for _, target in targets do
		task.wait(.3)

		notify('fling', `now flinging {target.Name}`, 1)

		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		local target_char = target.Character

		if not target_char then
			notify('fling', `{target.Name} has no character`, 2)
			continue
		end

		local target_hrp = stuff.rawrbxget(target_char, 'HumanoidRootPart')
		local target_humanoid = stuff.rawrbxget(target_char, 'Humanoid')
		local cam = stuff.rawrbxget(workspace, 'CurrentCamera')

		local old_pos = stuff.rawrbxget(hrp, 'CFrame')
		local max_vel = Vector3.new(2500, 2500, 2500)
		local zero_vel = Vector3.zero
		local oldtick = tick()

		maid.add('velfling_connection', services.run_service.Heartbeat, function()
			local target_vel = stuff.rawrbxget(target_hrp, 'Velocity')
			if target_vel.Magnitude < 100 and tick() - oldtick < 5 then
				local target_ws = stuff.rawrbxget(target_humanoid, 'WalkSpeed')
				local predicted_cf = quick_predict_position(target, ((target_ws * 68.75) / 100))
				if predicted_cf then
					stuff.rawrbxset(hrp, 'CFrame', predicted_cf)
				end
				stuff.rawrbxset(hrp, 'Velocity', max_vel)
			else
				stuff.rawrbxset(hrp, 'Velocity', zero_vel)
				stuff.owner_char:PivotTo(old_pos)
				maid.remove('velfling_connection')
			end
		end)
	end
end)

cmd_library.add({'punchfling', 'pfling'}, 'gives you a punch fling tool', {}, function(vstorage) -- github.com/TheEGodOfficial/E-Super-Punch hi e god
	local tool = Instance.new('Tool')
	tool.Name = 'punch'
	tool.RequiresHandle = false
	tool.Parent = stuff.owner.Backpack

	vstorage.hidden_fling = false
	vstorage.movel = 0.1

	if not vstorage.fling_loop then
		vstorage.fling_loop = true
		task.spawn(function()
			local hrp, c, vel
			while vstorage.fling_loop do
				services.run_service.Heartbeat:Wait()
				if vstorage.hidden_fling then
					c = stuff.owner.Character
					hrp = c and (c:FindFirstChild('HumanoidRootPart') or c:FindFirstChild('Torso') or c:FindFirstChild('UpperTorso'))

					while vstorage.hidden_fling and not (c and c.Parent and hrp and hrp.Parent) do
						services.run_service.Heartbeat:Wait()
						c = stuff.owner.Character
						hrp = c and (c:FindFirstChild('HumanoidRootPart') or c:FindFirstChild('Torso') or c:FindFirstChild('UpperTorso'))
					end

					if vstorage.hidden_fling and hrp then
						vel = stuff.rawrbxget(hrp, 'AssemblyLinearVelocity')
						stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', vel * 10000 + Vector3.new(0, 10000, 0))
						services.run_service.RenderStepped:Wait()

						if c and c.Parent and hrp and hrp.Parent then
							stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', vel)
						end

						services.run_service.Stepped:Wait()

						if c and c.Parent and hrp and hrp.Parent then
							stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', vel + Vector3.new(0, vstorage.movel, 0))
							vstorage.movel = vstorage.movel * -1
						end
					end
				end
			end
		end)
	end

	tool.Activated:Connect(function()
		local character = stuff.owner.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if not humanoid then return end

		local anim = Instance.new('Animation')

		if humanoid.RigType == Enum.HumanoidRigType.R6 then
			anim.AnimationId = 'rbxassetid://204062532'
		else
			anim.AnimationId = 'rbxassetid://567480369'
		end

		local track = humanoid:LoadAnimation(anim)
		track:Play(0.1)

		task.spawn(function()
			vstorage.hidden_fling = true
			task.wait(2)
			vstorage.hidden_fling = false
		end)

		anim:Destroy()
	end)

	tool.AncestryChanged:Connect(function()
		if not tool.Parent then
			vstorage.fling_loop = false
			vstorage.hidden_fling = false
		end
	end)

	notify('punchfling', 'punch fling tool given', 1)
end)

cmd_library.add({'carpetfling', 'cfling'}, 'flings player using carpet animation and hip height', {
	{'player', 'player'},
	{'power', 'number'}
}, function(vstorage, targets, power)
	if not targets or #targets == 0 then
		return notify('carpetfling', 'no player specified', 2)
	end

	local is_r15 = stuff.owner_char.Humanoid.RigType == Enum.HumanoidRigType.R15
	if not is_r15 then
		return notify('carpetfling', 'only works with r15', 2)
	end

	power = power or 1000

	for _, target in targets do
		if target == stuff.owner then
			notify('carpetfling', 'cannot fling yourself', 2)
			continue
		end

		if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
			notify('carpetfling', `{target.Name} has no character`, 2)
			continue
		end

		local char = stuff.owner.Character
		if not char or not char:FindFirstChild('HumanoidRootPart') or not char:FindFirstChild('Humanoid') then
			return notify('carpetfling', 'your character is missing parts', 2)
		end

		local hrp = char.HumanoidRootPart
		local humanoid = char.Humanoid
		local old_cf = stuff.rawrbxget(hrp, 'CFrame')
		local old_hip_height = stuff.rawrbxget(humanoid, 'HipHeight')

		local target_torso = target.Character:FindFirstChild('Torso') or 
			target.Character:FindFirstChild('LowerTorso') or 
			target.Character:FindFirstChild('HumanoidRootPart')

		if not target_torso then
			notify('carpetfling', `{target.Name} has no torso`, 2)
			continue
		end

		local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
		stuff.rawrbxset(workspace.CurrentCamera, 'CameraSubject', target.Character.Humanoid)

		local carpet_anim = Instance.new('Animation')
		stuff.rawrbxset(carpet_anim, 'AnimationId', 'rbxassetid://282574440')
		local carpet_track = humanoid:LoadAnimation(carpet_anim)
		carpet_track:Play(0.1, 1, 1)

		notify('carpetfling', `flinging {target.Name} with power {power}`, 1)

		maid.add('fling2_loop', services.run_service.Heartbeat, function()
			pcall(function()
				local target_vel = stuff.rawrbxget(target_torso, 'AssemblyLinearVelocity')
				local target_pos = stuff.rawrbxget(target_torso, 'Position')

				if target_vel.Magnitude <= 28 then
					local predicted_pos = target_pos + target_vel / 2
					stuff.rawrbxset(hrp, 'CFrame', CFrame.new(predicted_pos))
				else
					stuff.rawrbxset(hrp, 'CFrame', stuff.rawrbxget(target_torso, 'CFrame'))
				end
			end)
		end)

		task.wait()
		stuff.rawrbxset(humanoid, 'HipHeight', power)

		task.wait(0.5)

		maid.remove('fling2_loop')
		stuff.rawrbxset(workspace.CurrentCamera, 'CameraSubject', char.Humanoid)
		carpet_track:Stop()
		carpet_anim:Destroy()

		task.wait(1)
		stuff.rawrbxset(humanoid, 'Health', 0)

		task.wait(services.players.RespawnTime + 0.6)

		if stuff.owner.Character and stuff.owner.Character:FindFirstChild('HumanoidRootPart') then
			stuff.rawrbxset(stuff.owner.Character.HumanoidRootPart, 'CFrame', old_cf)
		end
	end
end)

cmd_library.add({'walkfling', 'walkf'}, 'enables walkfling, credits to X', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unwalkfling')
		return
	end
	if vstorage.enabled then
		return notify('walkfling', 'walkfling is already enabled', 2)
	end

	vstorage.enabled = true
	notify('walkfling', 'walkfling enabled', 1)

	if not vstorage.alreadyused then
		vstorage.alreadyused = true

		task.spawn(function()
			local hrp, c, vel, movel = nil, nil, nil, 0.1

			while services.run_service.Heartbeat:Wait() do
				if vstorage.enabled then
					while vstorage.enabled and not (c and c.Parent and hrp and hrp.Parent) do
						services.run_service.Heartbeat:Wait()
						c = stuff.owner_char
						hrp = c:FindFirstChild('HumanoidRootPart') or c:FindFirstChild('Torso') or c:FindFirstChild('UpperTorso')
					end

					if vstorage.enabled then
						vel = stuff.rawrbxget(hrp, 'Velocity')

						stuff.rawrbxset(hrp, 'Velocity', vel * 10000 + Vector3.new(0, 10000, 0))

						services.run_service.RenderStepped:Wait()

						if c and c.Parent and hrp and hrp.Parent then
							stuff.rawrbxset(hrp, 'Velocity', vel)
						end

						services.run_service.Stepped:Wait()

						if c and c.Parent and hrp and hrp.Parent then
							stuff.rawrbxset(hrp, 'Velocity', vel + Vector3.new(0, movel, 0))
							movel = movel * -1
						end
					end
				end
			end
		end)
	end
end)

cmd_library.add({'unwalkfling', 'unwalkf'}, 'disables walkfling', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('walkf')

	if not vstorage.enabled then
		return notify('walkfling', 'walkfling not enabled', 2)
	end

	vstorage.enabled = false
	notify('walkfling', 'walkfling disabled', 1)
end)

cmd_library.add({'robang', 'bang'}, 'robang someone', {
	{'player', 'player'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, targets, et)
	if et and vstorage.enabled then
		cmd_library.execute('unrobang')
		return
	end

	if not targets or #targets == 0 then
		return notify('robang', 'player not found', 2)
	end

	local target_plr = targets[1]

	if not target_plr.Character or not target_plr.Character:FindFirstChild('Head') then
		return notify('robang', `{target_plr.Name} does not have a character or head`, 2)
	end

	if vstorage.enabled then
		return notify('robang', 'robang already active', 2)
	end

	vstorage.enabled = true
	notify('robang', `banging {target_plr.Name}`, 1)

	maid.add('ro_bang_connection', services.run_service.Stepped, function()
		pcall(function()
			if not target_plr.Character or not target_plr.Character:FindFirstChild('Head') then
				maid.remove('ro_bang_connection')
				vstorage.enabled = false
				return
			end

			local cf = CFrame.new(0, 1.5, -1.5 - math.sin(os.clock() * 15)) * CFrame.Angles(0, math.rad(180), 0)
			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			if hrp then
				stuff.rawrbxset(hrp, 'Velocity', Vector3.zero)
				stuff.rawrbxset(hrp, 'RotVelocity', Vector3.zero)
				local target_head = stuff.rawrbxget(target_plr.Character, 'Head')
				local target_head_cf = stuff.rawrbxget(target_head, 'CFrame')
				stuff.owner_char:PivotTo(target_head_cf * cf)
			end
		end)
	end)
end)

cmd_library.add({'stoprobang', 'unbang', 'endbang'}, 'stop robang', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('robang')

	if not vstorage.enabled then
		return notify('robang', 'robang not active', 2)
	end

	vstorage.enabled = false
	notify('robang', 'stopped robang', 1)
	maid.remove('ro_bang_connection')
end)

cmd_library.add({'spaz', 'seizure'}, 'makes your character spaz out', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unspaz')
		return
	end

	if vstorage.enabled then
		return notify('spaz', 'spaz already enabled', 2)
	end

	vstorage.enabled = true
	notify('spaz', 'spaz enabled', 1)

	maid.add('spaz', services.run_service.Heartbeat, function()
		pcall(function()
			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
			stuff.rawrbxset(hrp, 'CFrame', hrp_cf * CFrame.Angles(
				math.rad(math.random(-90, 90)),
				math.rad(math.random(-90, 90)),
				math.rad(math.random(-90, 90))
				))
		end)
	end)
end)

cmd_library.add({'unspaz', 'unseizure'}, 'stops spaz', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('spaz')

	if not vstorage.enabled then
		return notify('spaz', 'spaz not enabled', 2)
	end

	vstorage.enabled = false
	notify('spaz', 'spaz disabled', 1)
	maid.remove('spaz')
end)

cmd_library.add({'clone'}, 'clones your character', {}, function(vstorage)
	notify('clone', 'character cloned', 1)
	stuff.rawrbxset(stuff.owner_char, 'Archivable', true)
	local clone = stuff.clone(stuff.owner_char)
	stuff.rawrbxset(clone, 'Parent', workspace)

	for _, v in pairs(clone:GetDescendants()) do
		if v:IsA('Script') or v:IsA('LocalScript') then
			stuff.destroy(v)
		end
	end
end)

cmd_library.add({'removeclones', 'clearclones'}, 'removes all clones', {}, function(vstorage)
	notify('removeclones', 'clones removed', 1)

	for _, v in pairs(workspace:GetChildren()) do
		if v.Name == stuff.owner_char.Name and v ~= stuff.owner_char then
			stuff.destroy(v)
		end
	end
end)

cmd_library.add({'explode', 'explosion'}, 'creates explosion at your position', {
	{'size', 'number'},
	{'blast_pressure', 'number'}
}, function(vstorage, size, blastpressure)
	size = size or 10
	blastpressure = blastpressure or 500000
	notify('explode', `exploding with size {size}`, 1)

	local explosion = Instance.new('Explosion')
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local hrp_pos = stuff.rawrbxget(hrp, 'Position')
	stuff.rawrbxset(explosion, 'Position', hrp_pos - Vector3.new(0, 1, 0))
	stuff.rawrbxset(explosion, 'BlastRadius', size)
	stuff.rawrbxset(explosion, 'BlastPressure', blastpressure)
	stuff.rawrbxset(explosion, 'DestroyJointRadiusPercent', 0)
	stuff.rawrbxset(explosion, 'Parent', workspace)
end)
cmd_library.add({"wait"},"waits a specified number of seconds before running a command",{
	{"seconds","number"},
	{"command","string"},
	{['...'] = 'table'}
},function(vstorage,s,c,...)
	local arg1,arg2,arg3,arg4 = nil,nil,nil,nil
	for _, v in pairs(table.pack(...)) do
		if typeof(v) == "table" then
			if arg1 == nil then
				arg1 = v[1]
				continue
			end
			if arg2 == nil then
				arg2 = v[1]
				continue
			end
			if arg3 == nil then
				arg3 = v[1]
				continue
			end
			if arg4 == nil then
				arg4 = v[1]
				continue
			end
		end
	end
	task.delay(s,function()
		cmd_library.execute(c,arg1,arg2,arg3,arg4)
	end)
end)

cmd_library.add({'rocket', 'launch'}, 'launches you like a rocket', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, power, bypass)
	power = power or 100
	notify('rocket', `launching with power {power}{bypass and ' (bypass)' or ''}`, 1)

	local bv = Instance.new('BodyVelocity')
	stuff.rawrbxset(bv, 'MaxForce', Vector3.new(math.huge, math.huge, math.huge))
	stuff.rawrbxset(bv, 'Velocity', Vector3.new(0, power, 0))

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')

	if bypass then
		hook_lib.create_hook('rocket_bypass', {
			newindex = function(self, key, value)
				if self == bv and (key == 'Velocity' or key == 'MaxForce' or key == 'Parent') then
					return false
				end
			end,
			index = function(self, key)
				if self == bv then
					if key == 'Velocity' then
						return Vector3.zero
					elseif key == 'MaxForce' then
						return Vector3.zero
					elseif key == 'Parent' then
						return nil
					end
				end
			end
		})
	end

	stuff.rawrbxset(bv, 'Parent', hrp)

	task.delay(0.5, function()
		if bypass then
			hook_lib.destroy_hook('rocket_bypass')
		end
	end)

	services.debris:AddItem(bv, 0.5)
end)

cmd_library.add({'push', 'dash'}, 'pushes you forward', {
	{'power', 'number'},
	{"time_lasted", 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, power, timelasted, bypass)
	power = power or 100
	notify('push', `pushing forward with power {power}{bypass and ' (bypass)' or ''}`, 1)

	local bv = Instance.new('BodyVelocity')
	stuff.rawrbxset(bv, 'MaxForce', Vector3.new(math.huge, math.huge, math.huge))
	stuff.rawrbxset(bv, 'Velocity', stuff.owner_char:FindFirstChild("HumanoidRootPart").CFrame.LookVector*power)

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')

	if bypass then
		hook_lib.create_hook('push_bypass', {
			newindex = function(self, key, value)
				if self == bv and (key == 'Velocity' or key == 'MaxForce' or key == 'Parent') then
					return false
				end
			end,
			index = function(self, key)
				if self == bv then
					if key == 'Velocity' then
						return Vector3.zero
					elseif key == 'MaxForce' then
						return Vector3.zero
					elseif key == 'Parent' then
						return nil
					end
				end
			end
		})
	end

	stuff.rawrbxset(bv, 'Parent', hrp)

	task.delay(0.5, function()
		if bypass then
			hook_lib.destroy_hook('push_bypass')
		end
	end)
	if timelasted == nil then
		services.debris:AddItem(bv, 0.5)
	else
		services.debris:AddItem(bv,timelasted)
	end
end)

-- c4: character

cmd_library.add({'67'}, '67', {}, function(vstorage)
	notify('67', '67', 1)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local animator = humanoid:FindFirstChildOfClass('Animator')

	if not animator then
		animator = Instance.new('Animator')
		stuff.rawrbxset(animator, 'Parent', humanoid)
	end

	local animation = Instance.new('Animation')
	stuff.rawrbxset(animation, 'AnimationId', `rbxassetid://106367055475970`)

	local track = animator:LoadAnimation(animation)
	track:Play()
end) -- most op command

cmd_library.add({'camerainvert', 'invert', 'backwards'}, 'makes your character look opposite to camera direction', {
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('uncamerainvert')
		return
	end

	if vstorage.enabled then
		return notify('camerainvert', 'camera invert already enabled', 2)
	end

	vstorage.enabled = true
	notify('camerainvert', 'camera invert enabled', 1)

	local character = stuff.owner.Character
	if not character or not character:FindFirstChild('HumanoidRootPart') then
		return notify('camerainvert', 'character not found', 2)
	end

	local humanoid_root_part = character.HumanoidRootPart

	maid.add('camerainvert', services.run_service.Heartbeat, function()
		if not character.Parent or not humanoid_root_part.Parent then
			cmd_library.execute('uncamerainvert')
			return
		end

		local camera = stuff.rawrbxget(workspace, 'CurrentCamera')
		local camera_cf = stuff.rawrbxget(camera, 'CFrame')

		local camera_look = camera_cf.LookVector
		local inverted_look = -camera_look

		local hrp_position = stuff.rawrbxget(humanoid_root_part, 'Position')

		local new_cf = CFrame.lookAt(hrp_position, hrp_position + Vector3.new(inverted_look.X, 0, inverted_look.Z))

		stuff.rawrbxset(humanoid_root_part, 'CFrame', new_cf)
	end)
end)

cmd_library.add({'uncamerainvert', 'uninvert'}, 'disables camera invert', {}, function(vstorage)
	local camerainvert_vs = cmd_library.get_variable_storage('camerainvert')

	if not camerainvert_vs or not camerainvert_vs.enabled then
		return notify('camerainvert', 'camera invert not enabled', 2)
	end

	camerainvert_vs.enabled = false
	maid.remove('camerainvert')

	notify('camerainvert', 'camera invert disabled', 1)
end)

cmd_library.add({'nosit', 'disablesit', 'locksit'}, 'prevents your character from sitting', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('esit')
		return
	end
	if vstorage.enabled then
		return notify('nosit', 'nosit already enabled', 2)
	end

	vstorage.enabled = true
	notify('nosit', 'nosit enabled', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	stuff.rawrbxset(humanoid, 'Sit', false)
end)

cmd_library.add({'esit', 'enablesit', 'unlocksit'}, 'allows your character to sit', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('nosit')

	if not vstorage.enabled then
		return notify('nosit', 'nosit not enabled', 2)
	end

	vstorage.enabled = false
	notify('nosit', 'nosit disabled', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	stuff.rawrbxset(humanoid, 'Sit', false)
end)

cmd_library.add({'noclip', 'nc'}, 'let\'s you walk through parts (modes: normal, velocity, smart, cframe)', {
	{'mode', 'string'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, mode, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unnoclip')
		return
	end

	if vstorage.enabled then
		return notify('noclip', 'noclip already enabled', 2)
	end

	local valid_modes = {'normal', 'velocity', 'smart', 'cframe'}
	mode = mode and mode:lower() or 'smart'

	if not table.find(valid_modes, mode) then
		return notify('noclip', `invalid mode '{mode}'. valid modes: {table.concat(valid_modes, ', ')}`, 2)
	end

	vstorage.enabled = true
	vstorage.mode = mode
	vstorage.bypass = bypass
	notify('noclip', `noclip enabled | mode: {vstorage.mode}{bypass and ' (bypass)' or ''}`, 1)

	local character = stuff.owner.Character
	if not character then
		return notify('noclip', 'character not found', 2)
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if humanoid then
		vstorage.original_state = humanoid:GetStateEnabled(Enum.HumanoidStateType.Climbing)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	end

	vstorage.collision_states = {}
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA('BasePart') then
			vstorage.collision_states[part] = stuff.rawrbxget(part, 'CanCollide')
		end
	end

	if bypass then
		hook_lib.create_hook('noclip_bypass', {
			index = function(self, key)
				if self:IsA('BasePart') and self:IsDescendantOf(character) then
					if key == 'CanCollide' then
						return vstorage.collision_states[self] or true
					end
				end
			end,

			newindex = function(self, key, value)
				if self:IsA('BasePart') and self:IsDescendantOf(character) then
					if key == 'CanCollide' then
						if value ~= false then
							vstorage.collision_states[self] = value
						end
						return false
					end
				end
			end,

			namecall = function(self, ...)
				local method = getnamecallmethod()
				local args = {...}

				if self:IsA('BasePart') and self:IsDescendantOf(character) then
					if method == 'GetPropertyChangedSignal' and args[1] == 'CanCollide' then
						return Instance.new('BindableEvent').Event
					end
				end
			end
		})
	end

	if vstorage.mode == 'normal' then
		maid.add('noclip', services.run_service.Stepped, function()
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					stuff.rawrbxset(part, 'CanCollide', false)
				end
			end
		end)

	elseif vstorage.mode == 'velocity' then
		maid.add('noclip', services.run_service.Heartbeat, function()
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					stuff.rawrbxset(part, 'CanCollide', false)

					local velocity = stuff.rawrbxget(part, 'AssemblyLinearVelocity')
					if velocity.Magnitude > 0.1 then
						stuff.rawrbxset(part, 'AssemblyLinearVelocity', velocity * 1.01)
					end
				end
			end
		end)

	elseif vstorage.mode == 'smart' then
		maid.add('noclip_stepped', services.run_service.Stepped, function()
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					stuff.rawrbxset(part, 'CanCollide', false)
				end
			end
		end)

		maid.add('noclip_heartbeat', services.run_service.Heartbeat, function()
			if humanoid then
				if stuff.rawrbxget(humanoid, 'Sit') then
					stuff.rawrbxset(humanoid, 'Sit', false)
				end
			end
		end)

		maid.add('noclip_descendant', character.DescendantAdded, function(descendant)
			if descendant:IsA('BasePart') then
				vstorage.collision_states[descendant] = stuff.rawrbxget(descendant, 'CanCollide')
			end
		end)

	elseif vstorage.mode == 'cframe' then
		vstorage.saved_cframe = nil
		vstorage.is_moving = false

		local hrp = character:FindFirstChild('HumanoidRootPart')
		if not hrp then
			return notify('noclip', 'HumanoidRootPart not found', 2)
		end

		maid.add('noclip_cframe_stepped', services.run_service.Stepped, function()
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') then
					stuff.rawrbxset(part, 'CanCollide', false)
				end
			end

			if humanoid and hrp then
				local move_direction = stuff.rawrbxget(humanoid, 'MoveDirection')
				local move_magnitude = move_direction.Magnitude
				local velocity = stuff.rawrbxget(hrp, 'AssemblyLinearVelocity')
				local is_jumping = math.abs(velocity.Y) > 1

				if move_magnitude > 0.1 or is_jumping then
					vstorage.is_moving = true
					vstorage.saved_cframe = stuff.rawrbxget(hrp, 'CFrame')
				else
					if vstorage.is_moving then
						vstorage.is_moving = false
						vstorage.saved_cframe = stuff.rawrbxget(hrp, 'CFrame')
					end

					if vstorage.saved_cframe then
						stuff.rawrbxset(hrp, 'CFrame', vstorage.saved_cframe)
						stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.new(velocity.X, velocity.Y, velocity.Z) * 0.1)
						stuff.rawrbxset(hrp, 'AssemblyAngularVelocity', Vector3.zero)
					end
				end

				if stuff.rawrbxget(humanoid, 'Sit') then
					stuff.rawrbxset(humanoid, 'Sit', false)
				end
			end
		end)

		maid.add('noclip_cframe_descendant', character.DescendantAdded, function(descendant)
			if descendant:IsA('BasePart') then
				vstorage.collision_states[descendant] = stuff.rawrbxget(descendant, 'CanCollide')
			end
		end)
	end

	local reset_triggered = false

	maid.add('noclip_died', character.Humanoid.Died, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('unnoclip')
	end)

	maid.add('noclip_char_added', stuff.owner.CharacterAdded, function()
		if reset_triggered then return end
		reset_triggered = true
		cmd_library.execute('unnoclip')
	end)
end)

cmd_library.add({'unnoclip', 'unc', 'clip'}, 'disables noclip', {}, function(vstorage)
	local noclip_vs = cmd_library.get_variable_storage('noclip')

	if not noclip_vs or not noclip_vs.enabled then
		return notify('noclip', 'noclip not enabled', 2)
	end

	noclip_vs.enabled = false

	maid.remove('noclip')
	maid.remove('noclip_stepped')
	maid.remove('noclip_heartbeat')
	maid.remove('noclip_descendant')
	maid.remove('noclip_cframe_stepped')
	maid.remove('noclip_cframe_descendant')
	maid.remove('noclip_died')
	maid.remove('noclip_char_added')

	if noclip_vs.bypass then
		hook_lib.destroy_hook('noclip_bypass')
	end

	local character = stuff.owner.Character
	if character then
		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if humanoid and noclip_vs.original_state ~= nil then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, noclip_vs.original_state)
		end

		if noclip_vs.collision_states then
			for part, original_state in pairs(noclip_vs.collision_states) do
				if part and part.Parent then
					pcall(function()
						stuff.rawrbxset(part, 'CanCollide', original_state)
					end)
				end
			end
		else
			for _, part in pairs(character:GetDescendants()) do
				if part:IsA('BasePart') and part.Name ~= 'HumanoidRootPart' then
					stuff.rawrbxset(part, 'CanCollide', true)
				end
			end
		end
	end

	noclip_vs.collision_states = {}
	noclip_vs.saved_cframe = nil
	noclip_vs.is_moving = false

	notify('noclip', 'noclip disabled', 1)
end)

cmd_library.add({'freeze'}, 'freezes your character in place', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unfreeze')
		return
	end
	if vstorage.enabled then
		return notify('freeze', 'freeze already enabled', 2)
	end

	vstorage.enabled = true
	notify('freeze', 'you are now frozen', 1)

	maid.add('freeze_connection', services.run_service.Heartbeat, function()
		pcall(function()
			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'Anchored', true)
		end)
	end)
end)

cmd_library.add({'unfreeze', 'thaw'}, 'unfreezes your character', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('freeze')

	if not vstorage.enabled then
		return notify('freeze', 'freeze not enabled', 2)
	end

	vstorage.enabled = false
	notify('freeze', 'you are now unfrozen', 1)
	maid.remove('freeze_connection')

	pcall(function()
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		stuff.rawrbxset(hrp, 'Anchored', false)
	end)
end)

cmd_library.add({'sit'}, 'buckle up', {}, function(vstorage)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	if humanoid then
		local current_sit = stuff.rawrbxget(humanoid, 'Sit')
		stuff.rawrbxset(humanoid, 'Sit', not current_sit)
		notify('togglesit', `set sitting to {not current_sit}`, 1)
	end
end)

cmd_library.add({'spin'}, 'spins your character', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unspin')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('spin', 'spin is already enabled', 2)
	end

	vstorage.speed = speed or 20
	vstorage.enabled = true
	vstorage.bypass = bypass
	notify('spin', `spinning at speed {vstorage.speed}{bypass and ' (bypass)' or ''}`, 1)

	if vstorage.spin_part then
		pcall(stuff.destroy, vstorage.spin_part)
	end

	local spin_part = Instance.new('BodyAngularVelocity')
	stuff.rawrbxset(spin_part, 'Name', 'spin_velocity')

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	stuff.rawrbxset(spin_part, 'Parent', hrp)
	stuff.rawrbxset(spin_part, 'MaxTorque', Vector3.new(0, math.huge, 0))
	stuff.rawrbxset(spin_part, 'AngularVelocity', Vector3.new(0, vstorage.speed, 0))

	if bypass then
		hook_lib.create_hook('spin_bypass', {
			newindex = function(self, key, value)
				if self == spin_part and (key == 'AngularVelocity' or key == 'MaxTorque' or key == 'Parent') then
					return false
				end
			end,
			index = function(self, key)
				if self == spin_part then
					if key == 'AngularVelocity' then
						return Vector3.zero
					elseif key == 'MaxTorque' then
						return Vector3.zero
					elseif key == 'Parent' then
						return nil
					end
				end
			end
		})
	end

	local r = false
	maid.add('died', stuff.owner_char.Humanoid.Died, function()
		if r then return end
		r = true
		cmd_library.execute('unspin')
	end)

	maid.add('spin_char_added', stuff.owner.CharacterAdded, function()
		if r then return end
		r = true
		cmd_library.execute('unspin')
	end)

	vstorage.spin_part = spin_part
end)

cmd_library.add({'unspin'}, 'stops spinning your character', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('spin')

	if not vstorage.enabled then
		return notify('spin', 'spin is not enabled', 2)
	end

	notify('spin', 'stopped spinning', 1)
	vstorage.enabled = false

	maid.remove('died')
	maid.remove('spin_char_added')

	if vstorage.spin_part then
		pcall(stuff.destroy, vstorage.spin_part)
		vstorage.spin_part = nil
	end

	if vstorage.bypass then
		hook_lib.destroy_hook('spin_bypass')
	end
end)

cmd_library.add({'platformstand', 'pstand'}, 'enables platform stand', {}, function(vstorage)
	notify('platformstand', 'platform stand enabled', 1)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'PlatformStand', true)
end)

cmd_library.add({'unplatformstand', 'unpstand'}, 'disables platform stand', {}, function(vstorage)
	notify('platformstand', 'platform stand disabled', 1)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'PlatformStand', false)
end)

cmd_library.add({'enablecoreuis', 'showguis', 'enableuis'}, 'enables the coreguis', {}, function(vstorage)
	notify('enableuis', 'enabled every coregui', 1)
	game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
end)

cmd_library.add({'droptools', 'dtools'}, 'drops all tools', {}, function(vstorage)
	notify('droptools', 'tools dropped', 1)

	pcall(function()
		for _, tool in pairs(stuff.owner.Backpack:GetChildren()) do
			stuff.rawrbxset(tool, 'Parent', stuff.owner_char)
		end
		task.delay(0.15, function()
			for _, tool in pairs(stuff.owner_char:GetChildren()) do
				if tool:IsA('Tool') then
					stuff.rawrbxset(tool, 'CanBeDropped', true)
					stuff.rawrbxset(tool, 'Parent', workspace)
				end
			end
			task.delay(0.05, function()
				local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
				humanoid:UnequipTools()
			end)
		end)
	end)
end)

cmd_library.add({'equiptools', 'etools'}, 'equips all tools', {}, function(vstorage)
	notify('equiptools', 'tools equipped', 1)

	pcall(function()
		for _, tool in pairs(stuff.owner.Backpack:GetChildren()) do
			if tool:IsA('Tool') or tool:IsA('HopperBin') or tool:IsA('BackpackItem') then
				stuff.rawrbxset(tool, 'Parent', stuff.owner_char)
			end
		end
	end)
end)

cmd_library.add({'unequiptools', 'utools'}, 'unequips all tools', {}, function(vstorage)
	notify('unequiptools', 'tools unequipped', 1)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:UnequipTools()
end)

cmd_library.add({'animation', 'anim'}, 'plays an animation by id', {
	{'id', 'number'}
}, function(vstorage, id)
	if not id then
		return notify('animation', 'provide an animation id', 2)
	end

	notify('animation', `playing animation {id}`, 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local animator = humanoid:FindFirstChildOfClass('Animator')

	if not animator then
		animator = Instance.new('Animator')
		stuff.rawrbxset(animator, 'Parent', humanoid)
	end

	local animation = Instance.new('Animation')
	stuff.rawrbxset(animation, 'AnimationId', `rbxassetid://{id}`)

	local track = animator:LoadAnimation(animation)
	track:Play()
end)

cmd_library.add({'stopanimations', 'stopanim'}, 'stops all playing animations', {}, function(vstorage)
	notify('stopanimations', 'animations stopped', 1)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop()
	end
end)

cmd_library.add({'hipheight', 'hheight'}, 'sets hip height', {
	{'height', 'number'}
}, function(vstorage, height)
	height = height or 0
	notify('hipheight', `hip height set to {height}`, 1)
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'HipHeight', height)
end)

cmd_library.add({'loophipheight', 'loophheight'}, 'loops hip height', {
	{'height', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, height, et)
	if et and vstorage.enabled then
		cmd_library.execute('unloophipheight')
		return
	end

	height = height or 5

	if vstorage.enabled then
		return notify('loophipheight', 'loop hip height already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.height = height
	notify('loophipheight', `looping hip height at {height}`, 1)

	pcall(function()
		maid.remove('loop_hip_height')
	end)

	maid.add('loop_hip_height', services.run_service.Heartbeat, function()
		pcall(function()
			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			stuff.rawrbxset(humanoid, 'HipHeight', height)
		end)
	end)
end)

cmd_library.add({'unloophipheight', 'unloophheight'}, 'stops looping hip height', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loophipheight')

	if not vstorage.enabled then
		return notify('loophipheight', 'loop hip height not enabled', 2)
	end

	vstorage.enabled = false
	notify('loophipheight', 'stopped looping hip height', 1)
	maid.remove('loop_hip_height')
end)

cmd_library.add({'refresh', 'ref'}, 'respawns character at current position', {}, function(vstorage)
	notify('refresh', 'refreshing character', 1)

	local old_pos = stuff.owner_char:GetPivot()
	stuff.owner_char:BreakJoints()

	task.wait(services.players.RespawnTime + 0.1)
	stuff.owner_char:PivotTo(old_pos)
end)

cmd_library.add({'removehats', 'removeaccessories', 'rhats'}, 'removes all accessories', {}, function(vstorage)
	notify('removehats', 'accessories removed', 1)

	for _, v in pairs(stuff.owner_char:GetDescendants()) do
		if v:IsA('Accessory') then
			stuff.destroy(v)
		end
	end
end)

cmd_library.add({'size', 'scale'}, 'changes character size', {
	{'size', 'number'}
}, function(vstorage, size)
	size = size or 1
	notify('size', `size set to {size}`, 1)

	stuff.owner_char:ScaleTo(size)
end)

cmd_library.add({'invisible', 'invis'}, 'makes your character invisible for others', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('visible')
		return
	end

	if vstorage.enabled then
		return notify('invisible', 'you already are invisible', 2)
	end

	vstorage.enabled = true
	notify('invisible', 'you are now invisible', 1)

	task.spawn(function()
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		local position = stuff.rawrbxget(hrp, 'Position')
		task.wait(.1)
		stuff.owner_char:MoveTo(position + Vector3.new(0, 1000000, 0))
		task.wait(.1)
		local hrpc = stuff.clone(hrp)
		task.wait(.1)
		pcall(stuff.destroy, hrp)
		stuff.rawrbxset(hrpc, 'Parent', stuff.owner_char)
		task.delay(.2, function()
			stuff.owner_char:MoveTo(position)
		end)
	end)
end)

cmd_library.add({'visible', 'uninvis', 'uninvisible'}, 'makes your character visible', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('invisible')

	if not vstorage.enabled then
		return notify('invisible', 'you aren\'t invisible', 2)
	end

	notify('invisible', 'became visible', 1)
	vstorage.enabled = false

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local pos = stuff.rawrbxget(hrp, 'CFrame')
	local camera = stuff.rawrbxget(workspace, 'CurrentCamera')

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:ChangeState(15)
	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
	wait(services.players.RespawnTime + 0.5)
	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
	local new_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	stuff.rawrbxset(new_hrp, 'CFrame', pos)

	stuff.rawrbxset(workspace, 'CurrentCamera', camera)
end)

-- c5: exploit

cmd_library.add({'ghostmode', 'ghost', 'normalmode'}, 'makes your character appear completely normal to the client', {
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unghostmode')
		return
	end

	if vstorage.enabled then
		return notify('ghostmode', 'ghost mode already enabled', 2)
	end

	vstorage.enabled = true
	notify('ghostmode', 'ghost mode enabled - character will appear normal', 1)

	local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
	local humanoid = stuff.owner_char:FindFirstChild('Humanoid')

	if not hrp or not humanoid then
		vstorage.enabled = false
		return notify('ghostmode', 'missing humanoid or rootpart', 2)
	end

	vstorage.normal_velocity = Vector3.zero
	vstorage.normal_cframe = stuff.rawrbxget(hrp, 'CFrame')
	vstorage.normal_ws = stuff.default_ws or 16
	vstorage.normal_jp = stuff.default_jp or 50
	vstorage.normal_health = stuff.rawrbxget(humanoid, 'Health')
	vstorage.normal_max_health = stuff.rawrbxget(humanoid, 'MaxHealth')

	maid.add('ghostmode_update', services.run_service.Heartbeat, function()
		pcall(function()
			local current_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			local current_humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')

			if current_hrp then
				local actual_velocity = stuff.rawrbxget(current_hrp, 'AssemblyLinearVelocity')
				local move_dir = stuff.rawrbxget(current_humanoid, 'MoveDirection')

				if move_dir.Magnitude > 0 then
					vstorage.normal_velocity = move_dir * vstorage.normal_ws
				else
					vstorage.normal_velocity = Vector3.new(0, actual_velocity.Y, 0)
				end

				vstorage.normal_cframe = stuff.rawrbxget(current_hrp, 'CFrame')
			end

			if current_humanoid then
				local actual_health = stuff.rawrbxget(current_humanoid, 'Health')
				if actual_health > 0 then
					vstorage.normal_health = actual_health
				end
			end
		end)
	end)

	hook_lib.create_hook('ghostmode', {
		index = function(self, key)
			if self == hrp or (self:IsA('BasePart') and self.Name == 'HumanoidRootPart' and self:IsDescendantOf(stuff.owner_char)) then
				if key == 'Velocity' or key == 'velocity' then
					return vstorage.normal_velocity
				elseif key == 'AssemblyLinearVelocity' then
					return vstorage.normal_velocity
				elseif key == 'AssemblyAngularVelocity' then
					return Vector3.zero
				elseif key == 'RotVelocity' then
					return Vector3.zero
				elseif key == 'CFrame' or key == 'cframe' then
					return vstorage.normal_cframe
				elseif key == 'Position' or key == 'position' or key == 'p' then
					return vstorage.normal_cframe.Position
				elseif key == 'Orientation' then
					local x, y, z = vstorage.normal_cframe:ToOrientation()
					return Vector3.new(math.deg(x), math.deg(y), math.deg(z))
				end
			end

			if self == humanoid or (self:IsA('Humanoid') and self:IsDescendantOf(stuff.owner_char)) then
				if key == 'WalkSpeed' then
					return vstorage.normal_ws
				elseif key == 'JumpPower' then
					return vstorage.normal_jp
				elseif key == 'JumpHeight' then
					return 7.2
				elseif key == 'Health' then
					return vstorage.normal_health
				elseif key == 'MaxHealth' then
					return vstorage.normal_max_health
				elseif key == 'HipHeight' then
					return 0
				elseif key == 'UseJumpPower' then
					return true
				elseif key == 'Sit' then
					return false
				elseif key == 'PlatformStand' then
					return false
				elseif key == 'MoveDirection' then
					return stuff.rawrbxget(self, 'MoveDirection')
				end
			end

			if self:IsA('BodyMover') and self:IsDescendantOf(stuff.owner_char) then
				if key == 'Parent' then
					return nil
				end
			end
		end,

		newindex = function(self, key, value)
			if self:IsA('BodyMover') and self:IsDescendantOf(stuff.owner_char) then
				if key == 'Velocity' or key == 'MaxForce' or key == 'AngularVelocity' or key == 'MaxTorque' or key == 'Parent' then
					return false
				end
			end
		end,

		namecall = function(self, ...)
			local method = getnamecallmethod()
			local args = {...}

			if self == humanoid or (self:IsA('Humanoid') and self:IsDescendantOf(stuff.owner_char)) then
				if method == 'GetState' then
					local actual_state = stuff.rawrbxget(self, 'MoveDirection').Magnitude > 0 and Enum.HumanoidStateType.Running or Enum.HumanoidStateType.Idle
					return actual_state
				elseif method == 'GetPropertyChangedSignal' then
					if args[1] == 'WalkSpeed' or args[1] == 'JumpPower' or args[1] == 'Health' or args[1] == 'MaxHealth' then
						return Instance.new('BindableEvent').Event
					end
				end
			end

			if (self == hrp or (self:IsA('BasePart') and self.Name == 'HumanoidRootPart' and self:IsDescendantOf(stuff.owner_char))) then
				if method == 'GetVelocityAtPosition' then
					return vstorage.normal_velocity
				elseif method == 'GetPropertyChangedSignal' then
					if args[1] == 'Velocity' or args[1] == 'CFrame' or args[1] == 'Position' then
						return Instance.new('BindableEvent').Event
					end
				end
			end

			if self:IsA('BodyMover') and self:IsDescendantOf(stuff.owner_char) then
				if method == 'IsA' then
					return false
				elseif method == 'FindFirstChild' or method == 'FindFirstChildOfClass' or method == 'FindFirstChildWhichIsA' then
					return nil
				end
			end
		end
	})

	if hookfunction then
		local children_cache = {}
		vstorage.get_children_hook = hookfunction(game.GetChildren, function(self)
			if vstorage.enabled and self == hrp then
				if not children_cache[self] then
					local actual_children = game.GetChildren(self)
					local filtered = {}
					for _, child in actual_children do
						if not child:IsA('BodyMover') then
							table.insert(filtered, child)
						end
					end
					children_cache[self] = filtered
				end
				return children_cache[self]
			end
			return game.GetChildren(self)
		end)

		vstorage.get_descendants_hook = hookfunction(game.GetDescendants, function(self)
			if vstorage.enabled and self == stuff.owner_char then
				local actual_descendants = game.GetDescendants(self)
				local filtered = {}
				for _, descendant in actual_descendants do
					if not descendant:IsA('BodyMover') then
						table.insert(filtered, descendant)
					end
				end
				return filtered
			end
			return game.GetDescendants(self)
		end)
	end
end)

cmd_library.add({'unghostmode', 'unghost', 'unnormalmode'}, 'disables ghost mode', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('ghostmode')

	if not vstorage.enabled then
		return notify('ghostmode', 'ghost mode not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('ghostmode_update')
	hook_lib.destroy_hook('ghostmode')

	if vstorage.get_children_hook then
		vstorage.get_children_hook = nil
	end
	if vstorage.get_descendants_hook then
		vstorage.get_descendants_hook = nil
	end

	notify('ghostmode', 'ghost mode disabled', 1)
end)

cmd_library.add({'antikick', 'antiban'}, 'attempts to prevent kicks and bans', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('antikick', 'anti kick enabled', 1)

		hook_lib.create_hook('antikick', hook_lib.presets.antikick(stuff.owner))

		maid.add('antikick_m', services.run_service.Heartbeat, function()
			if not stuff.owner:IsDescendantOf(game) then
				stuff.rawrbxset(stuff.owner, 'Parent', services.players)
			end

			if stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
				pcall(function()
					stuff.owner_char.HumanoidRootPart:SetNetworkOwner(stuff.owner)
				end)
			end
		end)

	else
		notify('antikick', 'anti kick disabled', 1)
		vstorage.enabled = false

		hook_lib.destroy_hook('antikick')
		maid.remove('antikick_m')
	end
end)

cmd_library.add({'blackhole', 'bh'}, 'creates a black hole that attracts parts', {
	{'radius', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, radius, et)
	if vstorage.enabled and et then
		cmd_library.execute('unblackhole')
		return
	end

	if vstorage.enabled then
		notify('blackhole', 'blackhole is already enabled', 2)
	end

	vstorage.radius = radius or 10
	vstorage.angle = 1

	notify('blackhole', `black hole enabled with radius {vstorage.radius}`, 1)

	local character = stuff.owner.Character
	if not character or not character:FindFirstChild('HumanoidRootPart') then
		return notify('blackhole', 'character not found', 2)
	end

	local hrp = character.HumanoidRootPart

	local folder = Instance.new('Folder')
	stuff.rawrbxset(folder, 'Parent', workspace)

	local part = Instance.new('Part')
	stuff.rawrbxset(part, 'Parent', folder)
	stuff.rawrbxset(part, 'Anchored', true)
	stuff.rawrbxset(part, 'CanCollide', false)
	stuff.rawrbxset(part, 'Transparency', 1)

	local attachment1 = Instance.new('Attachment')
	stuff.rawrbxset(attachment1, 'Parent', part)

	vstorage.folder = folder
	vstorage.part = part
	vstorage.attachment1 = attachment1

	local sethidden = sethiddenproperty or set_hidden_property or set_hidden_prop

	if sethidden then
		maid.add('blackhole_network', services.run_service.Heartbeat, function()
			pcall(function()
				sethidden(stuff.owner, 'SimulationRadius', math.huge)
				stuff.rawrbxset(stuff.owner, 'ReplicationFocus', workspace)
			end)
		end)
	end

	local function force_part(v)
		if v:IsA('Part') and not v.Anchored and not v.Parent:FindFirstChild('Humanoid') and not v.Parent:FindFirstChild('Head') and v.Name ~= 'Handle' then
			for _, x in pairs(v:GetChildren()) do
				if x:IsA('BodyAngularVelocity') or x:IsA('BodyForce') or x:IsA('BodyGyro') or x:IsA('BodyPosition') or x:IsA('BodyThrust') or x:IsA('BodyVelocity') or x:IsA('RocketPropulsion') then
					x:Destroy()
				end
			end

			if v:FindFirstChild('Attachment') then
				v:FindFirstChild('Attachment'):Destroy()
			end
			if v:FindFirstChild('AlignPosition') then
				v:FindFirstChild('AlignPosition'):Destroy()
			end
			if v:FindFirstChild('Torque') then
				v:FindFirstChild('Torque'):Destroy()
			end

			stuff.rawrbxset(v, 'CanCollide', false)
			stuff.rawrbxset(v, 'CustomPhysicalProperties', PhysicalProperties.new(0, 0, 0, 0, 0))
			stuff.rawrbxset(v, 'Velocity', Vector3.new(14.46262424, 14.46262424, 14.46262424))

			local torque = Instance.new('Torque')
			stuff.rawrbxset(torque, 'Parent', v)
			stuff.rawrbxset(torque, 'Torque', Vector3.new(1000000, 1000000, 1000000))

			local align_position = Instance.new('AlignPosition')
			stuff.rawrbxset(align_position, 'Parent', v)

			local attachment2 = Instance.new('Attachment')
			stuff.rawrbxset(attachment2, 'Parent', v)

			stuff.rawrbxset(torque, 'Attachment0', attachment2)
			stuff.rawrbxset(align_position, 'MaxForce', math.huge)
			stuff.rawrbxset(align_position, 'MaxVelocity', math.huge)
			stuff.rawrbxset(align_position, 'Responsiveness', 500)
			stuff.rawrbxset(align_position, 'Attachment0', attachment2)
			stuff.rawrbxset(align_position, 'Attachment1', attachment1)
		end
	end

	for _, v in pairs(workspace:GetDescendants()) do
		force_part(v)
	end

	maid.add('blackhole_descendant', workspace.DescendantAdded, function(v)
		if vstorage.enabled then
			force_part(v)
		end
	end)

	maid.add('blackhole_update', services.run_service.RenderStepped, function()
		if character and hrp and hrp.Parent then
			vstorage.angle = vstorage.angle + math.rad(2)

			local offset_x = math.cos(vstorage.angle) * vstorage.radius
			local offset_z = math.sin(vstorage.angle) * vstorage.radius

			local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
			stuff.rawrbxset(attachment1, 'WorldCFrame', hrp_cf * CFrame.new(offset_x, 0, offset_z))
		end
	end)
end)

cmd_library.add({'unblackhole', 'unbh'}, 'disables black hole', {}, function(vstorage)
	local blackhole_vs = cmd_library.get_variable_storage('blackhole')

	if not blackhole_vs or not blackhole_vs.enabled then
		return notify('blackhole', 'black hole not enabled', 2)
	end

	blackhole_vs.enabled = false

	if blackhole_vs.attachment1 then
		stuff.rawrbxset(blackhole_vs.attachment1, 'WorldCFrame', CFrame.new(0, -1000, 0))
	end

	if blackhole_vs.folder then
		blackhole_vs.folder:Destroy()
	end

	maid.remove('blackhole_network')
	maid.remove('blackhole_descendant')
	maid.remove('blackhole_update')

	notify('blackhole', 'black hole disabled', 1)
end)

cmd_library.add({'togglefreegamepass', 'tfreegp', 'freegp'}, 'makes the client think that you own every gamepass and in the group', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('freegamepass', 'free gamepass enabled', 1)
		hook_lib.create_hook('freegamepass', hook_lib.presets.freegamepass())
	else
		notify('freegamepass', 'free gamepass disabled', 1)
		vstorage.enabled = false
		hook_lib.destroy_hook('freegamepass')
	end
end)

cmd_library.add({'triggerbot', 'tbot'}, 'automatically shoots when crosshair is on enemy', {
	{'delay', 'number'},
	{'head_only', 'boolean'},
	{'wallcheck', 'boolean'}
}, function(vstorage, delay, head_only, wallcheck)
	if vstorage.enabled then
		return notify('triggerbot', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.delay = math.clamp(delay or 0.02, 0, 1)
	vstorage.head_only = head_only or false
	vstorage.wallcheck = wallcheck ~= false
	vstorage.last_shot = 0

	notify('triggerbot', `enabled | delay: {vstorage.delay}s | head only: {vstorage.head_only} | wallcheck: {vstorage.wallcheck}`, 1)

	local valid_parts = {
		'Head', 'UpperTorso', 'LowerTorso', 'Torso',
		'LeftUpperArm', 'LeftLowerArm', 'LeftHand',
		'RightUpperArm', 'RightLowerArm', 'RightHand',
		'LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot',
		'RightUpperLeg', 'RightLowerLeg', 'RightFoot',
		'Left Arm', 'Right Arm', 'Left Leg', 'Right Leg'
	}

	local function is_valid_body_part(part)
		if vstorage.head_only then
			return part.Name == 'Head'
		end
		return table.find(valid_parts, part.Name) ~= nil
	end

	maid.add('triggerbot', services.run_service.Heartbeat, function()
		if not vstorage.enabled or not stuff.owner_char then return end

		local now = tick()
		if now - vstorage.last_shot < vstorage.delay then return end

		local mouse = stuff.owner:GetMouse()
		local target = mouse.Target

		if not target then return end
		if not is_valid_body_part(target) then return end

		local character = target:FindFirstAncestorOfClass('Model')
		if not character then return end

		local player = services.players:GetPlayerFromCharacter(character)
		if not is_valid_target(player) then return end

		if vstorage.wallcheck then
			local camera = workspace.CurrentCamera
			if not has_line_of_sight(camera.CFrame.Position, target.Position, character) then
				return
			end
		end

		vstorage.last_shot = now
		mouse1click()
	end)
end)

cmd_library.add({'untriggerbot', 'untbot'}, 'disables triggerbot', {}, function()
	local vs = cmd_library.get_variable_storage('triggerbot')
	if not vs.enabled then
		return notify('triggerbot', 'not enabled', 2)
	end

	vs.enabled = false
	maid.remove('triggerbot')
	notify('triggerbot', 'disabled', 1)
end)

cmd_library.add({'aimbot', 'aim'}, 'aims at nearest enemy (set prediction to "auto" or "automatic" instead of a number for automatic prediction)', {
	{'toggle_key', 'string'},
	{'fov', 'number'},
	{'max_distance', 'number'},
	{'smoothness', 'number'},
	{'target_part', 'string'},
	{'prediction', 'string'},
	{'priority', 'string'},
	{'wallcheck', 'boolean'},
	{'sticky', 'boolean'},
	{'humanize', 'boolean'}
}, function(vstorage, toggle_key, fov, max_distance, smoothness, target_part, prediction, priority, wallcheck, sticky, humanize)
	if vstorage.enabled then
		return notify('aimbot', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.active = stuff.is_mobile
	vstorage.toggle_key = toggle_key and Enum.KeyCode[toggle_key:gsub('^%l', string.upper)] or Enum.KeyCode.E
	vstorage.fov = fov or 90
	vstorage.fov_radius = fov_to_radius(vstorage.fov)
	vstorage.max_distance = max_distance or 500
	vstorage.smoothness = math.clamp(smoothness or 0.15, 0.01, 1)
	vstorage.target_part = (target_part or 'head'):lower()
	vstorage.priority = (priority or 'fov'):lower()
	vstorage.wallcheck = wallcheck ~= false
	vstorage.sticky = sticky ~= false
	vstorage.humanize = humanize or false
	vstorage.current_target = nil
	vstorage.locked_player = nil
	vstorage.last_switch = 0
	vstorage.velocity_cache = {}
	vstorage.smooth_offset = Vector2.zero

	vstorage.auto_prediction = prediction == nil or prediction == 'auto' or prediction == 'automatic'
	vstorage.base_prediction = tonumber(prediction) or 0.1
	vstorage.ping_history = {}
	vstorage.ping_avg = 0
	vstorage.ping_std = 0
	vstorage.hit_history = {}
	vstorage.miss_streak = 0
	vstorage.prediction_multiplier = 1.0
	vstorage.last_prediction_adjust = 0
	vstorage.target_velocity_history = {}
	vstorage.calculated_prediction = 0.1

	local valid_priorities = {'fov', 'distance', 'health', 'threat'}
	if not table.find(valid_priorities, vstorage.priority) then
		vstorage.priority = 'fov'
	end

	local part_lookup = {
		head = {'Head'},
		torso = {'UpperTorso', 'Torso', 'LowerTorso'},
		chest = {'UpperTorso', 'Torso'},
		pelvis = {'LowerTorso', 'Torso'},
		legs = {'LeftUpperLeg', 'RightUpperLeg', 'Left Leg', 'Right Leg'},
		arms = {'LeftUpperArm', 'RightUpperArm', 'Left Arm', 'Right Arm'},
		random = {'Head', 'UpperTorso', 'Torso', 'LeftUpperArm', 'RightUpperArm'},
		closest = nil
	}
	
	if not part_lookup[vstorage.target_part] then
		notify('rageaim', 'invalid target part, setting to closest', 3)
		vstorage.target_part = 'closest'
	end

	if not table.find({'fov', 'distance', 'speed', 'none'}, vstorage.priority) then
		notify('rageaim', 'invalid priority, setting to fov', 3)
		vstorage.priority = 'fov'
	end

	local function update_ping_stats()
		local current_ping = stuff.owner:GetNetworkPing()

		table.insert(vstorage.ping_history, {
			ping = current_ping,
			time = tick()
		})

		while #vstorage.ping_history > 60 do
			table.remove(vstorage.ping_history, 1)
		end

		local sum = 0
		for _, data in vstorage.ping_history do
			sum = sum + data.ping
		end
		vstorage.ping_avg = sum / #vstorage.ping_history

		local variance_sum = 0
		for _, data in vstorage.ping_history do
			local diff = data.ping - vstorage.ping_avg
			variance_sum = variance_sum + (diff * diff)
		end
		vstorage.ping_std = math.sqrt(variance_sum / #vstorage.ping_history)

		return current_ping
	end

	local function calculate_auto_prediction(char, current_speed)
		local current_ping = update_ping_stats()

		local ping_prediction = vstorage.ping_avg
		local jitter_compensation = vstorage.ping_std * 0.5

		local speed_factor = 1.0
		if current_speed > 0 then
			local normalized_speed = current_speed / 16
			speed_factor = 0.8 + (normalized_speed * 0.2)
			speed_factor = math.clamp(speed_factor, 0.5, 2.0)
		end

		local distance_factor = 1.0
		if char then
			local hrp = char:FindFirstChild('HumanoidRootPart')
			if hrp and stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
				local dist = (hrp.Position - stuff.owner_char.HumanoidRootPart.Position).Magnitude
				distance_factor = 1.0 + (dist / 1000) * 0.2
				distance_factor = math.clamp(distance_factor, 1.0, 1.5)
			end
		end

		local prediction = (ping_prediction + jitter_compensation) * speed_factor * distance_factor
		prediction = prediction * vstorage.prediction_multiplier
		prediction = math.clamp(prediction, 0.01, 0.5)
		vstorage.calculated_prediction = prediction

		return prediction
	end

	local function get_target_speed(char)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		if not hrp then return 0 end

		local vel = hrp.AssemblyLinearVelocity
		return Vector3.new(vel.X, 0, vel.Z).Magnitude
	end

	local function update_velocity_history(char)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		if not hrp then return nil end

		local key = tostring(char:GetDebugId())
		local now = tick()
		local current_vel = hrp.AssemblyLinearVelocity

		if not vstorage.target_velocity_history[key] then
			vstorage.target_velocity_history[key] = {
				samples = {},
				acceleration = Vector3.zero,
				last_vel = current_vel,
				last_time = now
			}
		end

		local history = vstorage.target_velocity_history[key]

		table.insert(history.samples, {
			vel = current_vel,
			time = now
		})

		while #history.samples > 10 do
			table.remove(history.samples, 1)
		end

		if #history.samples >= 2 then
			local oldest = history.samples[1]
			local newest = history.samples[#history.samples]
			local dt = newest.time - oldest.time

			if dt > 0.05 then
				history.acceleration = (newest.vel - oldest.vel) / dt
			end
		end

		history.last_vel = current_vel
		history.last_time = now

		return history
	end

	local function get_smoothed_velocity(char)
		local history = update_velocity_history(char)
		if not history or #history.samples == 0 then
			local hrp = char:FindFirstChild('HumanoidRootPart')
			return hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		end

		local weighted_vel = Vector3.zero
		local total_weight = 0

		for i, sample in history.samples do
			local weight = i / #history.samples
			weighted_vel = weighted_vel + sample.vel * weight
			total_weight = total_weight + weight
		end

		if total_weight > 0 then
			weighted_vel = weighted_vel / total_weight
		end

		return weighted_vel
	end

	local function predict_p(char, part)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hrp or not part then return part and part.Position or Vector3.zero end

		local current_speed = get_target_speed(char)
		local prediction_time

		if vstorage.auto_prediction then
			prediction_time = calculate_auto_prediction(char, current_speed)
		else
			prediction_time = vstorage.base_prediction + stuff.owner:GetNetworkPing()
		end

		local velocity = get_smoothed_velocity(char)
		local h_vel = Vector3.new(velocity.X, 0, velocity.Z)

		local move_vel = Vector3.zero
		if hum and hum.MoveDirection.Magnitude > 0.1 then
			move_vel = hum.MoveDirection.Unit * hum.WalkSpeed
		end

		local blended_vel
		if h_vel.Magnitude > 1 then
			blended_vel = h_vel * 0.65 + move_vel * 0.35
		else
			blended_vel = move_vel
		end

		local history = vstorage.target_velocity_history[tostring(char:GetDebugId())]
		local acceleration = history and history.acceleration or Vector3.zero
		local h_accel = Vector3.new(acceleration.X, 0, acceleration.Z)

		if h_accel.Magnitude > 50 then
			h_accel = h_accel.Unit * 50
		end

		local part_offset = part.Position - hrp.Position
		local predicted_hrp = hrp.Position + 
			blended_vel * prediction_time + 
			h_accel * 0.5 * prediction_time * prediction_time

		local max_offset = current_speed * prediction_time * 1.5
		max_offset = math.max(max_offset, 5)
		local offset = predicted_hrp - hrp.Position
		if offset.Magnitude > max_offset then
			predicted_hrp = hrp.Position + offset.Unit * max_offset
		end

		return predicted_hrp + part_offset
	end

	local function register_shot_result(hit)
		table.insert(vstorage.hit_history, {
			hit = hit,
			time = tick(),
			prediction = vstorage.calculated_prediction
		})

		while #vstorage.hit_history > 20 do
			table.remove(vstorage.hit_history, 1)
		end

		local now = tick()
		if now - vstorage.last_prediction_adjust < 0.5 then return end
		vstorage.last_prediction_adjust = now

		local recent_hits = 0
		local recent_shots = 0
		for _, data in vstorage.hit_history do
			if now - data.time < 3 then
				recent_shots = recent_shots + 1
				if data.hit then recent_hits = recent_hits + 1 end
			end
		end

		if recent_shots < 3 then return end

		local hit_rate = recent_hits / recent_shots

		if hit_rate < 0.3 then
			vstorage.prediction_multiplier = math.min(vstorage.prediction_multiplier * 1.1, 2.0)
		elseif hit_rate > 0.7 then
			vstorage.prediction_multiplier = math.max(vstorage.prediction_multiplier * 0.95, 0.5)
		end
	end

	local function get_part(char)
		if vstorage.target_part == 'closest' then
			local cam_pos = workspace.CurrentCamera.CFrame.Position
			local closest = nil
			local closest_dist = math.huge
			for _, p in char:GetDescendants() do
				if p:IsA('BasePart') and p.Name ~= 'HumanoidRootPart' then
					local d = (cam_pos - p.Position).Magnitude
					if d < closest_dist then
						closest_dist = d
						closest = p
					end
				end
			end
			return closest
		end

		if vstorage.target_part == 'random' then
			local valid = {}
			for _, n in part_lookup.random do
				local p = char:FindFirstChild(n)
				if p then table.insert(valid, p) end
			end
			return #valid > 0 and valid[math.random(1, #valid)] or char:FindFirstChild('Head')
		end

		local names = part_lookup[vstorage.target_part] or part_lookup.head
		for _, n in names do
			local p = char:FindFirstChild(n)
			if p then return p end
		end
		return char:FindFirstChild('Head') or char:FindFirstChild('HumanoidRootPart')
	end

	local function has_los(origin, target_pos, ignore_char)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {stuff.owner_char, ignore_char}
		params.FilterType = Enum.RaycastFilterType.Exclude

		local direction = target_pos - origin
		local result = workspace:Raycast(origin, direction, params)
		return result == nil
	end

	local function is_target_valid(plr)
		if not plr or plr == stuff.owner then return false end
		if plr.Team and plr.Team == stuff.owner.Team then return false end

		local char = plr.Character
		if not char then return false end

		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hum or hum.Health <= 0 then return false end
		if char:FindFirstChildOfClass('ForceField') then return false end

		return true
	end

	local function calculate_threat(candidate)
		local threat = 0

		threat = threat + (1 / (candidate.world_dist + 1)) * 50
		threat = threat + ((100 - candidate.health) / 100) * 20

		if candidate.has_tool then
			threat = threat + 30
		end

		local look_dir = candidate.char:FindFirstChild('HumanoidRootPart')
		if look_dir and stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
			local to_me = (stuff.owner_char.HumanoidRootPart.Position - look_dir.Position).Unit
			local their_look = look_dir.CFrame.LookVector
			local dot = to_me:Dot(their_look)
			if dot > 0.7 then
				threat = threat + 25
			end
		end

		return threat
	end

	local function ease_out_quad(t)
		return 1 - (1 - t) * (1 - t)
	end

	local function get_best_target()
		local camera = workspace.CurrentCamera
		local center = camera.ViewportSize / 2
		local cam_pos = camera.CFrame.Position
		local now = tick()

		if vstorage.sticky and vstorage.locked_player then
			if is_target_valid(vstorage.locked_player) then
				local char = vstorage.locked_player.Character
				local part = get_part(char)
				if part then
					local world_dist = (cam_pos - part.Position).Magnitude
					if world_dist <= vstorage.max_distance * 1.2 then
						if not vstorage.wallcheck or has_los(cam_pos, part.Position, char) then
							local predicted = predict_p(char, part)
							return {
								player = vstorage.locked_player,
								character = char,
								part = part,
								predicted = predicted,
								is_locked = true
							}
						end
					end
				end
			end
			vstorage.locked_player = nil
		end

		local candidates = {}

		for _, plr in services.players:GetPlayers() do
			if not is_target_valid(plr) then continue end

			local char = plr.Character
			local part = get_part(char)
			if not part then continue end

			local world_dist = (cam_pos - part.Position).Magnitude
			if world_dist > vstorage.max_distance then continue end

			local predicted = predict_p(char, part)
			local screen, visible = camera:WorldToViewportPoint(predicted)
			if not visible or screen.Z <= 0 then continue end

			local screen_dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
			if screen_dist > vstorage.fov_radius then continue end

			if vstorage.wallcheck and not has_los(cam_pos, part.Position, char) then
				continue
			end

			local hum = char:FindFirstChildOfClass('Humanoid')
			local has_tool = char:FindFirstChildOfClass('Tool') ~= nil

			local candidate = {
				player = plr,
				char = char,
				part = part,
				predicted = predicted,
				screen_dist = screen_dist,
				world_dist = world_dist,
				health = hum and hum.Health or 100,
				has_tool = has_tool
			}

			candidate.threat = calculate_threat(candidate)

			table.insert(candidates, candidate)
		end

		if #candidates == 0 then return nil end

		table.sort(candidates, function(a, b)
			if vstorage.priority == 'distance' then
				return a.world_dist < b.world_dist
			elseif vstorage.priority == 'health' then
				return a.health < b.health
			elseif vstorage.priority == 'threat' then
				return a.threat > b.threat
			end
			return a.screen_dist < b.screen_dist
		end)

		local best = candidates[1]

		if vstorage.sticky and now - vstorage.last_switch > 0.5 then
			vstorage.locked_player = best.player
			vstorage.last_switch = now
		end

		return {
			player = best.player,
			character = best.char,
			part = best.part,
			predicted = best.predicted,
			screen_dist = best.screen_dist,
			is_locked = false
		}
	end

	if not stuff.is_mobile then
		maid.add('aimbot_toggle', services.user_input_service.InputBegan, function(input, gpe)
			if gpe then return end
			if input.KeyCode == vstorage.toggle_key then
				vstorage.active = not vstorage.active
				vstorage.locked_player = nil
				notify('aimbot', vstorage.active and 'activated' or 'deactivated', 1)
			end
		end)
	end

	maid.add('aimbot_shot_detect', services.user_input_service.InputBegan, function(input, gpe)
		if gpe then return end
		if not vstorage.active or not vstorage.auto_prediction then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local target = vstorage.current_target
		if not target then return end

		task.delay(0.1, function()
			if not target or not target.Parent then return end

			local hum = target:FindFirstChildOfClass('Humanoid')
			if not hum then return end

			local current_health = hum.Health
			task.wait(0.05)
			if hum.Parent and hum.Health < current_health then
				register_shot_result(true)
			else
				register_shot_result(false)
			end
		end)
	end)

	maid.add('aimbot', services.run_service.RenderStepped, function(dt)
		if not vstorage.active or not stuff.owner_char then
			vstorage.current_target = nil
			return
		end

		local target = get_best_target()
		if not target then
			vstorage.current_target = nil
			vstorage.smooth_offset = vstorage.smooth_offset:Lerp(Vector2.zero, 0.1)
			return
		end

		vstorage.current_target = target.character

		local camera = workspace.CurrentCamera
		local goal = CFrame.lookAt(camera.CFrame.Position, target.predicted)

		local current_look = camera.CFrame.LookVector
		local goal_look = goal.LookVector
		local angle_diff = math.acos(math.clamp(current_look:Dot(goal_look), -1, 1))

		local base_smooth = vstorage.smoothness

		local dist_factor = math.clamp(target.screen_dist / vstorage.fov_radius, 0, 1)
		local adaptive_smooth = base_smooth * (0.5 + dist_factor * 0.5)

		if angle_diff < math.rad(2) then
			adaptive_smooth = adaptive_smooth * 1.5
		end

		adaptive_smooth = ease_out_quad(adaptive_smooth)

		if vstorage.humanize then
			local noise_x = math.sin(tick() * 8) * 0.002
			local noise_y = math.cos(tick() * 6) * 0.002
			vstorage.smooth_offset = vstorage.smooth_offset:Lerp(Vector2.new(noise_x, noise_y), 0.1)

			adaptive_smooth = adaptive_smooth + (math.random() - 0.5) * 0.02
			adaptive_smooth = math.clamp(adaptive_smooth, 0.01, 1)
		else
			vstorage.smooth_offset = Vector2.zero
		end

		local new_cf = camera.CFrame:Lerp(goal, adaptive_smooth)

		if vstorage.humanize and vstorage.smooth_offset.Magnitude > 0.0001 then
			new_cf = new_cf * CFrame.Angles(vstorage.smooth_offset.Y, vstorage.smooth_offset.X, 0)
		end

		camera.CFrame = new_cf
	end)

	maid.add('aimbot_cleanup', stuff.owner.CharacterAdded, function()
		vstorage.velocity_cache = {}
		vstorage.target_velocity_history = {}
		vstorage.locked_player = nil
		vstorage.ping_history = {}
		vstorage.hit_history = {}
		vstorage.prediction_multiplier = 1.0
	end)

	local key_name = tostring(vstorage.toggle_key):split('.')[3]
	local pred_str = vstorage.auto_prediction and 'auto' or tostring(vstorage.base_prediction)
	local msg = `enabled | fov: {vstorage.fov}° | smooth: {vstorage.smoothness} | prediction: {pred_str} | priority: {vstorage.priority}`
	if not stuff.is_mobile then
		msg ..= ` | toggle: {key_name}`
	end
	notify('aimbot', msg, 1)
end)

cmd_library.add({'unaimbot', 'unaim'}, 'disables aimbot', {}, function()
	local vs = cmd_library.get_variable_storage('aimbot')
	if not vs.enabled then
		return notify('aimbot', 'not enabled', 2)
	end

	vs.enabled = false
	vs.active = false
	vs.current_target = nil
	vs.locked_player = nil
	vs.velocity_cache = {}
	vs.target_velocity_history = {}
	vs.ping_history = {}
	vs.hit_history = {}
	maid.remove('aimbot')
	maid.remove('aimbot_toggle')
	maid.remove('aimbot_cleanup')
	maid.remove('aimbot_shot_detect')
	notify('aimbot', 'disabled', 1)
end)

cmd_library.add({'rageaim', 'raim', 'rage'}, 'rage aimbot with instant lock (basically aimbot with triggerbot and without smoothing yes) (set prediction to "auto" or "automatic" instead of a number for automatic prediction)', {
	{'toggle_key', 'string'},
	{'fov', 'number'},
	{'max_distance', 'number'},
	{'target_part', 'string'},
	{'prediction', 'string'},
	{'priority', 'string'},
	{'auto_fire', 'boolean'}
}, function(vstorage, toggle_key, fov, max_distance, target_part, prediction, priority, auto_fire)
	if vstorage.enabled then
		return notify('rageaim', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.active = stuff.is_mobile
	vstorage.toggle_key = toggle_key and Enum.KeyCode[toggle_key:gsub('^%l', string.upper)] or Enum.KeyCode.Q
	vstorage.fov = fov or 180
	vstorage.fov_radius = fov_to_radius(vstorage.fov)
	vstorage.max_distance = max_distance or 2000
	vstorage.target_part = (target_part or 'head'):lower()
	vstorage.priority = (priority or 'fov'):lower()
	vstorage.auto_fire = auto_fire or false
	vstorage.locked_target = nil
	vstorage.locked_player = nil
	vstorage.last_fire = 0
	vstorage.last_switch = 0

	vstorage.auto_prediction = prediction == nil or prediction == 'auto' or prediction == 'automatic'
	vstorage.base_prediction = tonumber(prediction) or 0.15
	vstorage.ping_history = {}
	vstorage.ping_avg = 0
	vstorage.ping_std = 0
	vstorage.hit_history = {}
	vstorage.prediction_multiplier = 1.0
	vstorage.last_prediction_adjust = 0
	vstorage.target_velocity_history = {}
	vstorage.calculated_prediction = 0.15

	local part_lookup = {
		head = {'Head'},
		torso = {'UpperTorso', 'Torso', 'LowerTorso'},
		pelvis = {'LowerTorso', 'Torso'},
		random = {'Head', 'UpperTorso', 'Torso'},
		closest = nil
	}
	
	if not part_lookup[vstorage.target_part] then
		notify('rageaim', 'invalid target part, setting to closest', 3)
		vstorage.target_part = 'closest'
	end
	
	if not table.find({'fov', 'distance', 'speed', 'none'}, vstorage.priority) then
		notify('rageaim', 'invalid priority, setting to fov', 3)
		vstorage.priority = 'fov'
	end

	local function update_ping_stats()
		local current_ping = stuff.owner:GetNetworkPing()

		table.insert(vstorage.ping_history, {
			ping = current_ping,
			time = tick()
		})

		while #vstorage.ping_history > 60 do
			table.remove(vstorage.ping_history, 1)
		end

		local sum = 0
		for _, data in vstorage.ping_history do
			sum = sum + data.ping
		end
		vstorage.ping_avg = sum / #vstorage.ping_history

		local variance_sum = 0
		for _, data in vstorage.ping_history do
			local diff = data.ping - vstorage.ping_avg
			variance_sum = variance_sum + (diff * diff)
		end
		vstorage.ping_std = math.sqrt(variance_sum / #vstorage.ping_history)

		return current_ping
	end

	local function get_target_speed(char)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		if not hrp then return 0 end
		local vel = hrp.AssemblyLinearVelocity
		return Vector3.new(vel.X, 0, vel.Z).Magnitude
	end

	local function calculate_auto_prediction(char, current_speed)
		update_ping_stats()

		local ping_prediction = vstorage.ping_avg
		local jitter_compensation = vstorage.ping_std * 0.5

		local speed_factor = 1.0
		if current_speed > 0 then
			local normalized_speed = current_speed / 16
			speed_factor = 0.8 + (normalized_speed * 0.25)
			speed_factor = math.clamp(speed_factor, 0.5, 2.5)
		end

		local distance_factor = 1.0
		if char then
			local hrp = char:FindFirstChild('HumanoidRootPart')
			if hrp and stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
				local dist = (hrp.Position - stuff.owner_char.HumanoidRootPart.Position).Magnitude
				distance_factor = 1.0 + (dist / 800) * 0.3
				distance_factor = math.clamp(distance_factor, 1.0, 1.8)
			end
		end

		local prediction = (ping_prediction + jitter_compensation) * speed_factor * distance_factor
		prediction = prediction * vstorage.prediction_multiplier
		prediction = math.clamp(prediction, 0.02, 0.6)

		vstorage.calculated_prediction = prediction
		return prediction
	end

	local function update_velocity_history(char)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		if not hrp then return nil end

		local key = tostring(char:GetDebugId())
		local now = tick()
		local current_vel = hrp.AssemblyLinearVelocity

		if not vstorage.target_velocity_history[key] then
			vstorage.target_velocity_history[key] = {
				samples = {},
				acceleration = Vector3.zero,
				last_vel = current_vel,
				last_time = now
			}
		end

		local history = vstorage.target_velocity_history[key]

		table.insert(history.samples, {
			vel = current_vel,
			time = now
		})

		while #history.samples > 10 do
			table.remove(history.samples, 1)
		end

		if #history.samples >= 2 then
			local oldest = history.samples[1]
			local newest = history.samples[#history.samples]
			local dt = newest.time - oldest.time

			if dt > 0.05 then
				history.acceleration = (newest.vel - oldest.vel) / dt
			end
		end

		history.last_vel = current_vel
		history.last_time = now

		return history
	end

	local function get_smoothed_velocity(char)
		local history = update_velocity_history(char)
		if not history or #history.samples == 0 then
			local hrp = char:FindFirstChild('HumanoidRootPart')
			return hrp and hrp.AssemblyLinearVelocity or Vector3.zero
		end

		local weighted_vel = Vector3.zero
		local total_weight = 0

		for i, sample in history.samples do
			local weight = i / #history.samples
			weighted_vel = weighted_vel + sample.vel * weight
			total_weight = total_weight + weight
		end

		if total_weight > 0 then
			weighted_vel = weighted_vel / total_weight
		end

		return weighted_vel
	end

	local function predict_advanced(char, part)
		local hrp = char:FindFirstChild('HumanoidRootPart')
		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hrp or not part then return part and part.Position or Vector3.zero end

		local current_speed = get_target_speed(char)
		local prediction_time

		if vstorage.auto_prediction then
			prediction_time = calculate_auto_prediction(char, current_speed)
		else
			prediction_time = vstorage.base_prediction + stuff.owner:GetNetworkPing()
		end

		local velocity = get_smoothed_velocity(char)
		local h_vel = Vector3.new(velocity.X, 0, velocity.Z)

		local move_vel = Vector3.zero
		if hum and hum.MoveDirection.Magnitude > 0.1 then
			move_vel = hum.MoveDirection.Unit * hum.WalkSpeed
		end

		local blended_vel
		if h_vel.Magnitude > 1 then
			blended_vel = h_vel * 0.7 + move_vel * 0.3
		else
			blended_vel = move_vel
		end

		local history = vstorage.target_velocity_history[tostring(char:GetDebugId())]
		local acceleration = history and history.acceleration or Vector3.zero
		local h_accel = Vector3.new(acceleration.X, 0, acceleration.Z)

		if h_accel.Magnitude > 80 then
			h_accel = h_accel.Unit * 80
		end

		local part_offset = part.Position - hrp.Position
		local predicted_hrp = hrp.Position + 
			blended_vel * prediction_time + 
			h_accel * 0.5 * prediction_time * prediction_time

		local max_offset = current_speed * prediction_time * 2
		max_offset = math.max(max_offset, 8)
		local offset = predicted_hrp - hrp.Position
		if offset.Magnitude > max_offset then
			predicted_hrp = hrp.Position + offset.Unit * max_offset
		end

		return predicted_hrp + part_offset
	end

	local function register_shot_result(hit)
		table.insert(vstorage.hit_history, {
			hit = hit,
			time = tick(),
			prediction = vstorage.calculated_prediction
		})

		while #vstorage.hit_history > 20 do
			table.remove(vstorage.hit_history, 1)
		end

		local now = tick()
		if now - vstorage.last_prediction_adjust < 0.5 then return end
		vstorage.last_prediction_adjust = now

		local recent_hits = 0
		local recent_shots = 0
		for _, data in vstorage.hit_history do
			if now - data.time < 3 then
				recent_shots = recent_shots + 1
				if data.hit then recent_hits = recent_hits + 1 end
			end
		end

		if recent_shots < 3 then return end

		local hit_rate = recent_hits / recent_shots

		if hit_rate < 0.3 then
			vstorage.prediction_multiplier = math.min(vstorage.prediction_multiplier * 1.15, 2.5)
		elseif hit_rate > 0.7 then
			vstorage.prediction_multiplier = math.max(vstorage.prediction_multiplier * 0.92, 0.4)
		end
	end

	local function get_part(char)
		if vstorage.target_part == 'closest' then
			local cam_pos = workspace.CurrentCamera.CFrame.Position
			local closest = nil
			local closest_dist = math.huge
			for _, p in char:GetDescendants() do
				if p:IsA('BasePart') then
					local d = (cam_pos - p.Position).Magnitude
					if d < closest_dist then
						closest_dist = d
						closest = p
					end
				end
			end
			return closest
		end

		if vstorage.target_part == 'random' then
			local valid = {}
			for _, n in part_lookup.random do
				local p = char:FindFirstChild(n)
				if p then table.insert(valid, p) end
			end
			return valid[math.random(1, math.max(1, #valid))]
		end

		local names = part_lookup[vstorage.target_part] or part_lookup.head
		for _, n in names do
			local p = char:FindFirstChild(n)
			if p then return p end
		end
		return char:FindFirstChild('Head')
	end

	local function has_los(origin, target_pos, ignore_char)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {stuff.owner_char, ignore_char}
		params.FilterType = Enum.RaycastFilterType.Exclude
		local result = workspace:Raycast(origin, target_pos - origin, params)
		return result == nil
	end

	local function is_target_valid(plr)
		if not plr or plr == stuff.owner then return false end
		if plr.Team and plr.Team == stuff.owner.Team then return false end

		local char = plr.Character
		if not char then return false end

		local hum = char:FindFirstChildOfClass('Humanoid')
		if not hum or hum.Health <= 0 then return false end
		if char:FindFirstChildOfClass('ForceField') then return false end

		return true
	end

	local function calculate_threat(candidate)
		local threat = 0
		threat = threat + (1 / (candidate.world_dist + 1)) * 50
		threat = threat + ((100 - candidate.health) / 100) * 20

		if candidate.has_tool then
			threat = threat + 30
		end

		local look_dir = candidate.char:FindFirstChild('HumanoidRootPart')
		if look_dir and stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
			local to_me = (stuff.owner_char.HumanoidRootPart.Position - look_dir.Position).Unit
			local their_look = look_dir.CFrame.LookVector
			local dot = to_me:Dot(their_look)
			if dot > 0.7 then
				threat = threat + 25
			end
		end

		return threat
	end

	if not stuff.is_mobile then
		maid.add('rageaim_toggle', services.user_input_service.InputBegan, function(input, gpe)
			if gpe then return end
			if input.KeyCode == vstorage.toggle_key then
				vstorage.active = not vstorage.active
				vstorage.locked_player = nil
				notify('rageaim', vstorage.active and 'activated' or 'deactivated', 1)
			end
		end)
	end

	maid.add('rageaim_shot_detect', services.user_input_service.InputBegan, function(input, gpe)
		if gpe then return end
		if not vstorage.active or not vstorage.auto_prediction then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

		local target = vstorage.locked_target
		if not target then return end

		task.delay(0.1, function()
			if not target or not target.Parent then return end

			local hum = target:FindFirstChildOfClass('Humanoid')
			if not hum then return end

			local current_health = hum.Health
			task.wait(0.05)
			if hum.Parent and hum.Health < current_health then
				register_shot_result(true)
			else
				register_shot_result(false)
			end
		end)
	end)

	maid.add('rageaim', services.run_service.RenderStepped, function()
		if not vstorage.enabled or not vstorage.active or not stuff.owner_char then return end

		local cam = workspace.CurrentCamera
		local center = cam.ViewportSize / 2
		local cam_pos = cam.CFrame.Position
		local now = tick()

		if vstorage.locked_player and is_target_valid(vstorage.locked_player) then
			local char = vstorage.locked_player.Character
			local part = get_part(char)
			if part then
				local world_dist = (cam_pos - part.Position).Magnitude
				if world_dist <= vstorage.max_distance * 1.2 then
					if has_los(cam_pos, part.Position, char) then
						local predicted = predict_advanced(char, part)
						vstorage.locked_target = char
						cam.CFrame = CFrame.lookAt(cam.CFrame.Position, predicted)

						if vstorage.auto_fire then
							if now - vstorage.last_fire > 0.05 then
								vstorage.last_fire = now
								mouse1click()
							end
						end
						return
					end
				end
			end
		end

		vstorage.locked_player = nil
		local candidates = {}

		for _, plr in services.players:GetPlayers() do
			if not is_target_valid(plr) then continue end

			local char = plr.Character
			local part = get_part(char)
			if not part then continue end

			local world_dist = (cam_pos - part.Position).Magnitude
			if world_dist > vstorage.max_distance then continue end

			local predicted = predict_advanced(char, part)
			local screen, visible = cam:WorldToViewportPoint(predicted)
			if not visible or screen.Z <= 0 then continue end

			local screen_dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
			if screen_dist > vstorage.fov_radius then continue end

			if not has_los(cam_pos, part.Position, char) then continue end

			local hum = char:FindFirstChildOfClass('Humanoid')
			local has_tool = char:FindFirstChildOfClass('Tool') ~= nil

			local candidate = {
				player = plr,
				char = char,
				part = part,
				predicted = predicted,
				screen_dist = screen_dist,
				world_dist = world_dist,
				health = hum and hum.Health or 100,
				has_tool = has_tool
			}

			candidate.threat = calculate_threat(candidate)
			table.insert(candidates, candidate)
		end

		if #candidates == 0 then
			vstorage.locked_target = nil
			return
		end

		table.sort(candidates, function(a, b)
			if vstorage.priority == 'distance' then return a.world_dist < b.world_dist end
			if vstorage.priority == 'health' then return a.health < b.health end
			if vstorage.priority == 'threat' then return a.threat > b.threat end
			return a.screen_dist < b.screen_dist
		end)

		local best = candidates[1]
		vstorage.locked_target = best.char
		vstorage.locked_player = best.player
		vstorage.last_switch = now

		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, best.predicted)

		if vstorage.auto_fire then
			if now - vstorage.last_fire > 0.05 then
				vstorage.last_fire = now
				mouse1click()
			end
		end
	end)

	maid.add('rageaim_cleanup', stuff.owner.CharacterAdded, function()
		vstorage.target_velocity_history = {}
		vstorage.locked_player = nil
		vstorage.locked_target = nil
		vstorage.ping_history = {}
		vstorage.hit_history = {}
		vstorage.prediction_multiplier = 1.0
	end)

	local key_name = tostring(vstorage.toggle_key):split('.')[3]
	local pred_str = vstorage.auto_prediction and 'auto' or tostring(vstorage.base_prediction)
	local msg = `enabled | fov: {vstorage.fov}° | prediction: {pred_str} | priority: {vstorage.priority} | auto fire: {vstorage.auto_fire}`
	if not stuff.is_mobile then
		msg ..= ` | toggle: {key_name}`
	end
	notify('rageaim', msg, 1)
end)

cmd_library.add({'unrageaim', 'unraim', 'unrage'}, 'disables rage aimbot', {}, function()
	local vs = cmd_library.get_variable_storage('rageaim')
	if not vs.enabled then
		return notify('rageaim', 'not enabled', 2)
	end

	vs.enabled = false
	vs.active = false
	vs.locked_target = nil
	vs.locked_player = nil
	vs.target_velocity_history = {}
	vs.ping_history = {}
	vs.hit_history = {}
	maid.remove('rageaim')
	maid.remove('rageaim_toggle')
	maid.remove('rageaim_cleanup')
	maid.remove('rageaim_shot_detect')
	notify('rageaim', 'disabled', 1)
end)


cmd_library.add({'antiaim', 'aa'}, 'makes your character harder to hit (modes: spin, jitter, random, sway, flip)', {
	{'mode', 'string'},
	{'speed', 'number'}
}, function(vstorage, mode, speed)
	if vstorage.enabled then
		return notify('antiaim', 'already enabled', 2)
	end

	local modes = {'spin', 'jitter', 'random', 'sway', 'flip'}
	mode = mode and mode:lower() or 'spin'

	if not table.find(modes, mode) then
		return notify('antiaim', `invalid mode. valid: {table.concat(modes, ', ')}`, 2)
	end

	vstorage.enabled = true
	vstorage.mode = mode
	vstorage.speed = math.clamp(speed or 15, 1, 50)
	vstorage.angle = 0
	vstorage.tick = 0
	vstorage.flip_state = false

	notify('antiaim', `enabled | mode: {mode} | speed: {vstorage.speed}`, 1)

	local jitter_angles = {-180, 180, -90, 90, -135, 135, -45, 45}

	local function apply_rotation()
		local hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
		if not hrp then return end

		local hum = stuff.owner_char:FindFirstChildOfClass('Humanoid')
		local move_dir = hum and hum.MoveDirection or Vector3.zero
		local base_angle = 0

		if move_dir.Magnitude > 0.1 then
			base_angle = math.atan2(-move_dir.X, -move_dir.Z)
		else
			local camera = workspace.CurrentCamera
			local look = camera.CFrame.LookVector
			base_angle = math.atan2(-look.X, -look.Z)
		end

		hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, base_angle + math.rad(vstorage.angle), 0)
	end

	maid.add('antiaim', services.run_service.Heartbeat, function(dt)
		if not vstorage.enabled or not stuff.owner_char then return end

		vstorage.tick += 1
		local interval = math.max(1, math.floor(60 / vstorage.speed))

		if vstorage.mode == 'spin' then
			vstorage.angle = (vstorage.angle + vstorage.speed * dt * 20) % 360

		elseif vstorage.mode == 'jitter' then
			if vstorage.tick % interval == 0 then
				vstorage.angle = jitter_angles[math.random(#jitter_angles)]
			end

		elseif vstorage.mode == 'random' then
			if vstorage.tick % interval == 0 then
				vstorage.angle = math.random(-180, 180)
			end

		elseif vstorage.mode == 'sway' then
			vstorage.angle = math.sin(tick() * vstorage.speed * 0.3) * 180

		elseif vstorage.mode == 'flip' then
			if vstorage.tick % interval == 0 then
				vstorage.flip_state = not vstorage.flip_state
				vstorage.angle = vstorage.flip_state and 180 or 0
			end
		end

		apply_rotation()
	end)

	maid.add('antiaim_respawn', stuff.owner.CharacterAdded, function(char)
		if not vstorage.enabled then return end
		char:WaitForChild('HumanoidRootPart')
		
		vstorage.angle = 0
		vstorage.tick = 0
	end)
end)

cmd_library.add({'unantiaim', 'unaa'}, 'disables antiaim', {}, function()
	local vs = cmd_library.get_variable_storage('antiaim')
	if not vs.enabled then
		return notify('antiaim', 'not enabled', 2)
	end

	vs.enabled = false
	maid.remove('antiaim')
	maid.remove('antiaim_respawn')
	notify('antiaim', 'disabled', 1)
end)

cmd_library.add({'silentaim', 'sa'}, 'silently redirects shots to enemies', {
	{'fov', 'number'},
	{'max_distance', 'number'},
	{'hitchance', 'number'},
	{'target_part', 'string'},
	{'sticky', 'boolean'}
}, function(vstorage, fov, max_distance, hitchance, target_part, sticky)
	if vstorage.enabled then
		return notify('silentaim', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.fov = fov or 90
	vstorage.fov_radius = fov_to_radius(vstorage.fov)
	vstorage.max_distance = max_distance or 500
	vstorage.hitchance = math.clamp(hitchance or 100, 0, 100)
	vstorage.target_part = (target_part or 'head'):lower()
	vstorage.sticky = sticky ~= false

	notify('silentaim', `enabled | fov: {vstorage.fov}° | range: {vstorage.max_distance} | hitchance: {vstorage.hitchance}% | part: {vstorage.target_part} | sticky: {vstorage.sticky}`, 1)

	local sticky_target = nil
	local frame_cache = {tick = 0, target = nil, hitchance_passed = nil}

	local function is_target_valid(char, part, cam_pos, center)
		if not char or not char.Parent or not part or not part.Parent then 
			return false, math.huge 
		end

		local part_pos = part.Position
		if (cam_pos - part_pos).Magnitude > vstorage.max_distance then 
			return false, math.huge 
		end

		local screen, visible = workspace.CurrentCamera:WorldToViewportPoint(part_pos)
		if not visible or screen.Z <= 0 then 
			return false, math.huge 
		end

		local screen_dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
		if screen_dist > vstorage.fov_radius then 
			return false, math.huge 
		end

		if not has_line_of_sight(cam_pos, part_pos, char) then 
			return false, math.huge 
		end

		return true, screen_dist
	end

	local function get_best_target()
		local now = tick()

		if (now - frame_cache.tick) < 0.016 then
			if frame_cache.hitchance_passed == false then return nil end
			return frame_cache.target
		end

		frame_cache.tick = now
		frame_cache.hitchance_passed = math.random(100) <= vstorage.hitchance

		if not frame_cache.hitchance_passed then
			frame_cache.target = nil
			return nil
		end

		local camera = workspace.CurrentCamera
		local center = camera.ViewportSize / 2
		local cam_pos = camera.CFrame.Position

		if vstorage.sticky and sticky_target then
			local part = get_target_part(sticky_target, vstorage.target_part)
			local valid = is_target_valid(sticky_target, part, cam_pos, center)

			if valid then
				frame_cache.target = {character = sticky_target, part = part}
				return frame_cache.target
			end
			sticky_target = nil
		end

		local best = nil
		local best_dist = vstorage.fov_radius

		for _, player in services.players:GetPlayers() do
			if not is_valid_target(player) then continue end

			local char = player.Character
			local part = get_target_part(char, vstorage.target_part)
			if not part then continue end

			local valid, screen_dist = is_target_valid(char, part, cam_pos, center)
			if valid and screen_dist < best_dist then
				best_dist = screen_dist
				best = {character = char, part = part}
			end
		end

		if best then
			sticky_target = best.character
		end

		frame_cache.target = best
		return best
	end

	local mouse = stuff.owner:GetMouse()

	hook_lib.create_hook('silentaim', {
		index = function(self, key)
			if not vstorage.enabled or self ~= mouse then return end

			local target = get_best_target()
			if not target then return end

			local pos = target.part.Position

			if key == 'Hit' then
				return CFrame.new(pos)
			elseif key == 'Target' then
				return target.part
			elseif key == 'X' then
				return (workspace.CurrentCamera:WorldToViewportPoint(pos)).X
			elseif key == 'Y' then
				return (workspace.CurrentCamera:WorldToViewportPoint(pos)).Y
			elseif key == 'UnitRay' then
				local origin = workspace.CurrentCamera.CFrame.Position
				return Ray.new(origin, (pos - origin).Unit)
			end
		end,

		namecall = function(self, ...)
			if not vstorage.enabled or self ~= workspace then return end

			local method = getnamecallmethod()
			local args = {...}
			local cam_pos = workspace.CurrentCamera.CFrame.Position

			if method == 'Raycast' then
				local origin, direction, params = args[1], args[2], args[3]
				if (origin - cam_pos).Magnitude > 15 then return end

				local target = get_best_target()
				if not target then return end

				local new_dir = (target.part.Position - origin).Unit * direction.Magnitude
				return workspace:Raycast(origin, new_dir, params)
			end

			local ray_methods = {
				FindPartOnRay = true,
				FindPartOnRayWithIgnoreList = true,
				FindPartOnRayWithWhitelist = true
			}

			if ray_methods[method] then
				local ray = args[1]
				if (ray.Origin - cam_pos).Magnitude > 15 then return end

				local target = get_best_target()
				if not target then return end

				local new_dir = (target.part.Position - ray.Origin).Unit * ray.Direction.Magnitude
				local new_ray = Ray.new(ray.Origin, new_dir)

				return workspace[method](workspace, new_ray, args[2], args[3], args[4])
			end
		end
	})
end)

cmd_library.add({'unsa', 'unsilentaim'}, 'disables silent aim', {}, function()
	local vs = cmd_library.get_variable_storage('silentaim')
	if not vs.enabled then
		return notify('silentaim', 'not enabled', 2)
	end

	vs.enabled = false
	hook_lib.destroy_hook('silentaim')
	notify('silentaim', 'disabled', 1)
end)

cmd_library.add({'partcontrol', 'pcontrol'}, 'networkownership goes brr', {}, function(vstorage)
	notify('partcontrol', 'fetching all parts, your character will be reset', 1)

	local camera = stuff.rawrbxget(workspace, 'CurrentCamera')
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local old_cframe = stuff.rawrbxget(hrp, 'CFrame')

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:ChangeState(15)
	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)

	wait(services.players.RespawnTime + .5)

	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
	local new_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	stuff.rawrbxset(new_hrp, 'CFrame', old_cframe)
	stuff.rawrbxset(workspace, 'CurrentCamera', camera)

	task.wait(.8)

	local found_part
	for _, part in workspace:GetDescendants() do
		pcall(function()
			local anchored = stuff.rawrbxget(part, 'Anchored')
			if not anchored and #part:GetConnectedParts() <= 1 and network_check(part) then
				found_part = part
			end
		end)
	end

	if not found_part then
		return notify('partcontrol', 'no controllable parts were found', 2)
	end

	vstorage.enabled = true
	vstorage.part = found_part
	vstorage.part_cancollide = stuff.rawrbxget(vstorage.part, 'CanCollide')

	local animate = stuff.owner_char:WaitForChild('Animate')
	if animate then
		stuff.destroy(animate)
	end

	stuff.rawrbxset(found_part, 'CFrame', stuff.owner_char:GetPivot())
	notify('partcontrol', 'found controllable part', 1)

	local velocity_offset = Vector3.new(14.46262424, 14.46262424, 14.46262424)

	task.spawn(function()
		while task.wait(3) do
			stuff.rawrbxset(found_part, 'Velocity', velocity_offset + Vector3.new(0, math.cos(tick() * 10) / 100, 0))
			stuff.owner_char:PivotTo(stuff.rawrbxget(found_part, 'CFrame'))
			local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			stuff.rawrbxset(camera, 'CameraSubject', hum)
		end
	end)

	maid.add('partcontrol', services.run_service.Heartbeat, function()
		pcall(function()
			stuff.rawrbxset(workspace, 'Gravity', 0)
			stuff.rawrbxset(workspace, 'FallenPartsDestroyHeight', -9999999)
			stuff.rawrbxset(found_part, 'CanCollide', false)
			stuff.rawrbxset(found_part, 'Velocity', Vector3.zero)

			local old_pos = stuff.rawrbxget(found_part, 'Position')
			local cam_cf = stuff.rawrbxget(camera, 'CFrame')
			stuff.rawrbxset(found_part, 'CFrame', CFrame.lookAt(old_pos, cam_cf * CFrame.new(0, 0, -250).Position))

			if not network_check(found_part) then
				stuff.rawrbxset(found_part, 'Velocity', velocity_offset)
				stuff.owner_char:PivotTo(stuff.rawrbxget(found_part, 'CFrame'))
				local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
				stuff.rawrbxset(camera, 'CameraSubject', hum)
				return
			end

			local in_attack = false
			for _, plr in services.players:GetPlayers() do
				if plr ~= stuff.owner and plr.Character and plr.Character:FindFirstChild('Head') then
					local head = stuff.rawrbxget(stuff.owner_char, 'Head')
					local head_pos = stuff.rawrbxget(head, 'Position')
					local plr_head = stuff.rawrbxget(plr.Character, 'Head')
					local plr_head_pos = stuff.rawrbxget(plr_head, 'Position')

					if (head_pos - plr_head_pos).Magnitude <= 18 then
						in_attack = true
					end
				end
			end

			stuff.rawrbxset(camera, 'CameraSubject', found_part)
			local found_pos = stuff.rawrbxget(found_part, 'Position')
			stuff.owner_char:PivotTo(CFrame.new(found_pos.X, found_pos.Y + (in_attack and 0 or -12), found_pos.Z))

			if not network_check(found_part) then
				notify('partcontrol', 'could not reposition part cframe: partcontrol cancelled', 2)
				maid.remove('partcontrol')
				return
			end

			local offset = get_move_vector(1)
			local current_cf = stuff.rawrbxget(found_part, 'CFrame')
			stuff.rawrbxset(found_part, 'CFrame', current_cf * CFrame.new(offset))
		end)
	end)
end)

cmd_library.add({'unpartcontrol', 'unpcontrol'}, 'disables part control', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('partcontrol')

	if not vstorage.enabled then
		return notify('partcontrol', 'part control not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('partcontrol')

	stuff.rawrbxset(workspace, 'Gravity', 196.2)
	stuff.rawrbxset(workspace, 'FallenPartsDestroyHeight', -500)

	if vstorage.part then
		pcall(function()
			stuff.rawrbxset(vstorage.part, 'CanCollide', vstorage.part_can_collide)
		end)
		vstorage.part = nil
	end

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(cam, 'CameraSubject', humanoid)

	notify('partcontrol', 'disabled part control', 1)
end)

cmd_library.add({'partstorm', 'pstorm', 'partrain'}, 'rain parts on a player', {
	{'player', 'player'},
	{'intensity', 'number'}
}, function(vstorage, targets, intensity)
	if not targets or #targets == 0 then
		return notify('partstorm', 'player not found', 2)
	end

	local target = targets[1]
	if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
		return notify('partstorm', `{target.Name} has no character`, 2)
	end

	if vstorage.enabled then
		return notify('partstorm', 'partstorm already active, use unpartstorm first', 2)
	end

	vstorage.enabled = true
	vstorage.intensity = intensity or 3
	vstorage.target = target

	notify('partstorm', `raining parts on {target.Name}`, 1)

	local old_cframe = stuff.owner_char:GetPivot()
	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	stuff.rawrbxset(hrp, 'CFrame', stuff.rawrbxget(hrp, 'CFrame'))
	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	stuff.rawrbxset(workspace, 'CurrentCamera', cam)
	task.wait(0.2)

	local parts = {}
	local part_limit = vstorage.intensity * 5

	for _, part in workspace:GetDescendants() do
		if part:IsA('BasePart') then
			local anchored = stuff.rawrbxget(part, 'Anchored')
			if not anchored and #part:GetConnectedParts() < 2 then
				if not part.Parent:FindFirstChildOfClass('Humanoid') and not part.Parent.Parent:FindFirstChildOfClass('Humanoid') then
					if not part:IsDescendantOf(stuff.owner_char) then
						table.insert(parts, part)
						if #parts >= part_limit then break end
					end
				end
			end
		end
	end

	if #parts == 0 then
		vstorage.enabled = false
		return notify('partstorm', 'no parts found for storm', 2)
	end

	notify('partstorm', `found {#parts} parts for storm`, 1)

	maid.add('partstorm_connection', services.run_service.Heartbeat, function()
		if not vstorage.enabled then
			maid.remove('partstorm_connection')
			return
		end

		if not vstorage.target.Character or not vstorage.target.Character:FindFirstChild('HumanoidRootPart') then
			vstorage.enabled = false
			maid.remove('partstorm_connection')
			notify('partstorm', 'target lost, stopping partstorm', 2)
			return
		end

		local target_hrp = stuff.rawrbxget(vstorage.target.Character, 'HumanoidRootPart')
		local target_pos = stuff.rawrbxget(target_hrp, 'Position')

		for i = #parts, 1, -1 do
			local part = parts[i]

			if not part:IsDescendantOf(workspace) then
				table.remove(parts, i)
				continue
			end
			if part.ReceiveAge ~= 0 then
				table.remove(parts, i)
				continue
			end
			local anchored = stuff.rawrbxget(part, 'Anchored')
			if anchored then
				table.remove(parts, i)
				continue
			end

			pcall(function()
				stuff.rawrbxset(part, 'CanCollide', true)
				stuff.rawrbxset(part, 'Velocity', Vector3.new(
					math.random(-50, 50),
					math.random(-100, 300),
					math.random(-50, 50)
					))

				local random_offset = Vector3.new(
					math.random(-20, 20),
					math.random(4, 30),
					math.random(-20, 20)
				)

				stuff.rawrbxset(part, 'CFrame', CFrame.new(target_pos + random_offset))
			end)
		end

		if #parts == 0 then
			vstorage.enabled = false
			maid.remove('partstorm_connection')
			notify('partstorm', 'partstorm ended, no more parts', 1)
		end
	end)
end)

cmd_library.add({'unpartstorm', 'unpstorm', 'unpartrain'}, 'stops the part storm', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('partstorm')

	if not vstorage.enabled then
		return notify('partstorm', 'partstorm is not active', 2)
	end

	vstorage.enabled = false
	maid.remove('partstorm_connection')
	notify('partstorm', 'partstorm stopped', 1)
end)

cmd_library.add({'partfling', 'pf', 'partf'}, 'flings someone using parts, far more undetectable and works in collisions off', {
	{'player', 'player'},
	{'velocity', 'number'}
}, function(vstorage, targets, vel)
	local velocity = vel or 2500

	local function part_fling(target)
		if not target then return end

		if target == stuff.owner then
			notify('partfling', 'cannot partfling yourself', 2)
			return
		end

		local part = get_closest_part()

		if part == nil then 
			notify('partfling', 'there is nothing to partfling with', 2)
			return 
		end

		if part:IsDescendantOf(stuff.owner_char) then
			notify('partfling', 'cannot use your own character parts for partfling', 2)
			return
		end

		local old_cframe_part = stuff.rawrbxget(part, 'CFrame')
		local old_cf = stuff.owner_char:GetPivot()
		local old_pos = stuff.rawrbxget(part, 'Position')
		local old_anchored = stuff.rawrbxget(part, 'Anchored')
		local old_can_collide = stuff.rawrbxget(part, 'CanCollide')
		local start_tick = tick()

		repeat
			stuff.owner_char:PivotTo(stuff.rawrbxget(part, 'CFrame'))
			services.run_service.RenderStepped:Wait()
		until network_check(part) == true or stuff.sim_range_reset == true or tick() - start_tick >= 5

		if network_check(part) == true then
			notify('partfling', `successfully gained part ownership and used partfling on {target.Name} with velocity {velocity}`, 1)
		else
			if stuff.sim_range_reset == false then
				notify('partfling', 'attempt to gain ownership timed out, consider using reloadnetwork', 2)
				stuff.owner_char:PivotTo(old_cf)
				return
			end
		end

		stuff.owner_char:PivotTo(old_cf)
		local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		humanoid:ChangeState(Enum.HumanoidStateType.Running)

		local target_hrp = target.Character and target.Character:FindFirstChild('HumanoidRootPart')
		if not target_hrp then 
			notify('partfling', `target {target.Name} has no HumanoidRootPart`, 2)
			return 
		end

		local target_original_pos = stuff.rawrbxget(target_hrp, 'Position')
		local fling_start_tick = tick()

		stuff.rawrbxset(part, 'Anchored', false)
		stuff.rawrbxset(part, 'CanCollide', false)
		stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.new(0, velocity * 2, 0))

		local fling_detected = false
		local max_distance_reached = 0
		local lost_ownership_tick = nil

		local function cleanup_part()
			pcall(function()
				stuff.rawrbxset(part, 'Anchored', old_anchored)
				stuff.rawrbxset(part, 'CanCollide', old_can_collide)
				stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.zero)
				stuff.rawrbxset(part, 'Position', old_pos)
				stuff.rawrbxset(part, 'CFrame', old_cframe_part)
			end)
		end

		pcall(function()
			maid.remove('partfling_connection')
		end)

		maid.add('partfling_connection', services.run_service.Heartbeat, function()
			if not target_hrp or not stuff.rawrbxget(target_hrp, 'Parent') then
				maid.remove('partfling_connection')
				cleanup_part()
				notify('partfling', `target {target.Name} no longer exists`, 2)
				return
			end

			local time_elapsed = tick() - fling_start_tick
			local current_pos = stuff.rawrbxget(target_hrp, 'Position')
			local distance_from_original = (current_pos - target_original_pos).Magnitude
			max_distance_reached = math.max(max_distance_reached, distance_from_original)

			if distance_from_original >= 100 and time_elapsed <= 1 then
				fling_detected = true
				maid.remove('partfling_connection')
				cleanup_part()
				notify('partfling', `successfully flung {target.Name} (distance: {math.floor(distance_from_original)} studs in {math.floor(time_elapsed * 100) / 100}s)`, 1)
				return
			end

			if fling_detected then
				maid.remove('partfling_connection')
				cleanup_part()
				return
			end

			if time_elapsed >= 10 then
				maid.remove('partfling_connection')
				cleanup_part()
				if max_distance_reached >= 100 then
					notify('partfling', `successfully flung {target.Name} (max distance: {math.floor(max_distance_reached)} studs)`, 1)
				else
					notify('partfling', `partfling on {target.Name} timed out (max distance: {math.floor(max_distance_reached)} studs)`, 2)
				end
				return
			end

			if network_check(part) ~= true then
				if lost_ownership_tick == nil then
					lost_ownership_tick = tick()
					cleanup_part()
				end

				local time_since_lost = tick() - lost_ownership_tick

				if time_since_lost >= 1 then
					maid.remove('partfling_connection')

					if max_distance_reached >= 100 then
						notify('partfling', `successfully flung {target.Name} (distance: {math.floor(max_distance_reached)} studs, lost ownership)`, 1)
					else
						notify('partfling', `lost ownership of part while flinging {target.Name} (only moved {math.floor(max_distance_reached)} studs)`, 2)
					end
				end
				return
			end

			stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
			stuff.rawrbxset(part, 'Anchored', false)
			stuff.rawrbxset(part, 'CanCollide', false)
			stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.new(0, velocity, 0))
			local character_of_target = target.Character
			local predicted_cf = predict_position(character_of_target)
			if predicted_cf then
				stuff.rawrbxset(part, 'CFrame', predicted_cf)
			end
		end)
	end

	if not targets or #targets == 0 then
		return notify('partfling', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		part_fling(target)
		task.wait(0.5)
	end
end)

cmd_library.add({'parttrap', 'ptrap', 'trap'}, 'trap them in a cage like a monkey', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('parttrap', 'player not found', 2)
	end

	local function get_closest_part_e(excluded)
		local best_part = nil
		local smallest_magnitude = nil
		local head = stuff.rawrbxget(stuff.owner_char, 'Head')
		local head_pos = stuff.rawrbxget(head, 'Position')

		for _, v in workspace:GetDescendants() do
			if v:IsA('BasePart') then
				local anchored = stuff.rawrbxget(v, 'Anchored')
				if not anchored and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') and not v:IsDescendantOf(stuff.owner_char) then
					local v_pos = stuff.rawrbxget(v, 'Position')
					if smallest_magnitude == nil or (head_pos - v_pos).Magnitude < smallest_magnitude then
						if #v:GetConnectedParts() < 2 and not table.find(excluded, v) then
							smallest_magnitude = (head_pos - v_pos).Magnitude
							best_part = v
						end
					end
				end
			end
		end

		return best_part
	end

	local function part_trap(target, number, excluded)
		if not target or not target.Character then return end

		local part = get_closest_part_e(excluded)

		if part == nil then 
			if number == 1 then
				notify('parttrap', 'there is nothing to parttrap with', 2)
			end
			return 
		end

		local old_cframe_part = stuff.rawrbxget(part, 'CFrame')
		local old_cf = stuff.owner_char:GetPivot()

		local start_tick = tick()
		repeat
			stuff.owner_char:PivotTo(stuff.rawrbxget(part, 'CFrame'))
			services.run_service.RenderStepped:Wait()
		until network_check(part) == true or stuff.sim_range_reset == true or tick() - start_tick >= 5

		if network_check(part) ~= true then
			if stuff.sim_range_reset == false then
				if number == 1 then
					notify('parttrap', 'attempt to gain ownership timed out, consider using reloadnetwork', 2)
				end
				stuff.owner_char:PivotTo(old_cf)
				return
			end
		end

		stuff.owner_char:PivotTo(old_cf)
		local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		humanoid:ChangeState(Enum.HumanoidStateType.Running)

		local weld_part1 = target.Character:FindFirstChild('Head')
		if number >= 2 and number ~= 6 then
			if target.Character:FindFirstChild('Torso') then
				weld_part1 = target.Character.Torso
			else
				weld_part1 = target.Character:FindFirstChild('HumanoidRootPart')
			end
		end

		if not weld_part1 then return end

		local part_test = Instance.new('Part', workspace)
		stuff.rawrbxset(part_test, 'Anchored', true)
		stuff.rawrbxset(part_test, 'Size', stuff.rawrbxget(weld_part1, 'Size'))
		stuff.rawrbxset(part_test, 'CFrame', stuff.rawrbxget(weld_part1, 'CFrame'))
		stuff.rawrbxset(part_test, 'Orientation', Vector3.new(0, 90, 0))
		stuff.rawrbxset(part_test, 'Transparency', 1)
		stuff.rawrbxset(part_test, 'CanCollide', false)

		local allowed = true
		local old_part_cframe = nil
		local recursion_done = false

		maid.add(`part_trap_connection_{number}`, services.run_service.Heartbeat, function()
			if not target or not target.Character or not target.Character:IsDescendantOf(game) or not target.Character:FindFirstChild('Humanoid') or stuff.sim_range_reset == true then
				maid.remove('part_trap_follow')
				maid.remove(`part_trap_connection_{number}`)
				pcall(stuff.destroy, part_test)

				maid.add(`removing_trap_connection_{number}`, services.run_service.Heartbeat, function()
					stuff.rawrbxset(part, 'CanCollide', true)
				end)

				task.delay(1, function()
					maid.remove(`removing_trap_connection_{number}`)
				end)
				return
			end

			local target_hum = stuff.rawrbxget(target.Character, 'Humanoid')
			local health = stuff.rawrbxget(target_hum, 'Health')
			if health <= 1 then
				maid.remove('part_trap_follow')
				maid.remove(`part_trap_connection_{number}`)
				pcall(stuff.destroy, part_test)
				return
			end

			stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)

			local move_dir = stuff.rawrbxget(target_hum, 'MoveDirection')
			local move_magnitude = move_dir.Magnitude

			if move_magnitude > 0.1 and allowed == true then
				local part_test_cf = stuff.rawrbxget(part_test, 'CFrame')

				if number == 1 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 15, 0))
				elseif number == 2 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 15, -1.5))
				elseif number == 3 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 15, 1.5))
				elseif number == 4 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(-1.5, 15, 0))
				elseif number == 5 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(1.5, 15, 0))
				elseif number >= 6 then
					stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 15, 0))
				end
			else
				if allowed == true then
					stuff.rawrbxset(part, 'Velocity', Vector3.new(14.46262424, 14.46262424, 14.46262424) + Vector3.new(0, math.cos(tick() * 10) / 100, 0))

					local part_test_cf = stuff.rawrbxget(part_test, 'CFrame')

					if number == 1 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 2, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(0, 0, 0))
					elseif number == 2 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 0.75, -1.75))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(90, 90, 0))
					elseif number == 3 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 0.5, 1.75))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(90, 90, 0))
					elseif number == 4 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(-2, 0.75, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(90, 0, 0))
					elseif number == 5 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(1.95, 0.75, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(90, 0, 0))
					elseif number == 6 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, 2, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(0, 90, 0))
					elseif number == 7 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, -2, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(0, 90, 0))
					elseif number == 8 then
						stuff.rawrbxset(part, 'CFrame', part_test_cf * CFrame.new(0, -2, 0))
						stuff.rawrbxset(part, 'Orientation', Vector3.new(0, 0, 0))
					end

					old_part_cframe = stuff.rawrbxget(part, 'CFrame')

					if not recursion_done and number < 8 then
						recursion_done = true
						table.insert(excluded, part)
						part_trap(target, number + 1, excluded)
					end

					allowed = false
				else
					stuff.rawrbxset(part, 'CFrame', old_part_cframe)
					stuff.rawrbxset(part, 'Velocity', Vector3.new(14.46262424, 14.46262424, 14.46262424) + Vector3.new(0, math.cos(tick() * 10) / 100, 0))
					stuff.rawrbxset(part, 'CanCollide', false)
				end
			end

			if part_test and weld_part1 then
				pcall(function()
					stuff.rawrbxset(part_test, 'CFrame', stuff.rawrbxget(weld_part1, 'CFrame'))
				end)
			end
		end)
	end

	for _, target in pairs(targets) do
		notify('parttrap', `attempted trap on {target.Name}`, 1)
		part_trap(target, 1, {})
		task.wait(0.5)
	end
end)


cmd_library.add({'flingaura', 'faura', 'fa'}, 'fling nearby players with parts', {
	{'radius', 'number'},
	{'torso_mode', 'boolean'}
}, function(vstorage, radius, torso_mode)
	radius = radius or 50

	notify('flingaura', 'fetching all parts, your character will be reset', 1)

	local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	local old_cframe = stuff.rawrbxget(hrp, 'CFrame')
	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	humanoid:ChangeState(15)
	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
	task.wait(services.players.RespawnTime + 0.5)

	stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
	local new_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
	stuff.rawrbxset(new_hrp, 'CFrame', old_cframe)
	stuff.rawrbxset(workspace, 'CurrentCamera', cam)
	task.wait(0.2)

	local parts = {}
	local part_index = 1

	local r = false
	maid.add('flingaura_died', stuff.owner_char.Humanoid.Died, function()
		if r then return end
		r = true
		cmd_library.execute('unflingaura')
	end)

	maid.add('flingaura_char_added', stuff.owner.CharacterAdded, function()
		if r then return end
		r = true
		cmd_library.execute('unflingaura')
	end)

	local is_player_part = function(part)
		for _, plr in services.players:GetPlayers() do
			if plr.Character and plr.Character:IsAncestorOf(part) then
				return true
			end
		end
		return false
	end

	local is_valid_part = function(part)
		local anchored = stuff.rawrbxget(part, 'Anchored')
		if anchored or is_player_part(part) or part:IsDescendantOf(stuff.owner_char) then
			return false
		end
		if part.Parent ~= workspace and (part.Parent:FindFirstChildOfClass('Humanoid') or part.Parent.Parent and part.Parent.Parent:FindFirstChildOfClass('Humanoid')) then
			return false
		end
		return #part:GetConnectedParts() < 2
	end

	for _, part in workspace:GetDescendants() do
		if part:IsA('BasePart') and is_valid_part(part) then
			table.insert(parts, part)
		end
	end

	local desc_added_conn = workspace.DescendantAdded:Connect(function(part)
		if part:IsA('BasePart') and is_valid_part(part) then
			table.insert(parts, part)
		end
	end)

	vstorage.fling_aura_conn = desc_added_conn

	task.wait(1)

	maid.add('fling_aura', services.run_service.Heartbeat, function(dt)
		if not stuff.owner_char or not new_hrp:IsDescendantOf(workspace) then
			maid.remove('fling_aura')
			desc_added_conn:Disconnect()
			return
		end

		local owner_pos = stuff.rawrbxget(new_hrp, 'Position')
		local nearby_targets = {}

		for _, player in services.players:GetPlayers() do
			if player ~= stuff.owner and player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
				local target_hrp = player.Character.HumanoidRootPart
				local target_pos = stuff.rawrbxget(target_hrp, 'Position')
				local distance = (target_pos - owner_pos).Magnitude

				if distance <= radius then
					local predicted_cf = predict_position(player)
					table.insert(nearby_targets, {player = player, hrp = target_hrp, predicted_cf = predicted_cf})
				end
			end
		end

		if #nearby_targets == 0 then
			return end

		for i = #parts, 1, -1 do
			local part = parts[i]

			if not part:IsDescendantOf(game) then
				table.remove(parts, i)
				continue
			end

			pcall(function()
				if part.ReceiveAge ~= 0 then
					return end
				local anchored = stuff.rawrbxget(part, 'Anchored')
				if anchored then
					return end

				stuff.rawrbxset(part, 'CanCollide', false)
				stuff.rawrbxset(part, 'Velocity', Vector3.new(0, 500000000000, 0))

				local target = nearby_targets[(part_index % #nearby_targets) + 1]

				if not torso_mode then
					stuff.rawrbxset(part, 'CFrame', target.predicted_cf)
				else
					local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
					if humanoid then
						humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
						stuff.rawrbxset(humanoid, 'Sit', true)
					end
					local offset_cframe = target.predicted_cf * CFrame.new(0, 0, -(17 + part.Size.Magnitude))
					stuff.rawrbxset(part, 'CFrame', offset_cframe)
					stuff.owner_char:PivotTo(offset_cframe)
				end

				part_index = part_index + 1
			end)
		end
	end)
end)

cmd_library.add({'unflingaura', 'unfaura', 'unfa'}, 'stop fling aura', {}, function(vstorage)
	maid.remove('fling_aura')
	maid.remove('flingaura_died')
	maid.remove('flingaura_char_added')
	if vstorage.fling_aura_conn then
		vstorage.fling_aura_conn:Disconnect()
		vstorage.fling_aura_conn = nil
	end
	notify('unflingaura', 'fling aura stopped', 1)
end)

cmd_library.add({'partwalkfling', 'pwalkfling', 'partwalkf', 'pwalkf', 'pwf'}, 'partfling on walkfling', {
	{'player', 'player'},
	{'torso_mode', 'boolean'}
}, function(vstorage, targets, torso_mode)
	if not targets or #targets == 0 then
		targets = {stuff.owner}
	end

	notify('partwalkfling', 'fetching all parts, your character will be reset', 1)

	local r = false
	maid.add('partwalkfling_died', stuff.owner_char.Humanoid.Died, function()
		if r then return end
		r = true
		cmd_library.execute('unpartwalkfling')
	end)

	maid.add('partwalkfling_char_added', stuff.owner.CharacterAdded, function()
		if r then return end
		r = true
		cmd_library.execute('unpartwalkfling')
	end)

	for _, target in pairs(targets) do
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		local old_cframe = stuff.rawrbxget(hrp, 'CFrame')
		local cam = stuff.rawrbxget(workspace, 'CurrentCamera')

		local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		humanoid:ChangeState(15)
		stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
		task.wait(services.players.RespawnTime + 0.5)

		if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
			notify('partwalkfling', `{target.Name} has no character`, 2)
			continue
		end

		local target_hrp = stuff.rawrbxget(target.Character, 'HumanoidRootPart')
		stuff.rawrbxset(stuff.owner, 'SimulationRadius', 1000)
		local new_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		stuff.rawrbxset(new_hrp, 'CFrame', old_cframe)
		stuff.rawrbxset(workspace, 'CurrentCamera', cam)
		task.wait(0.2)

		local parts = {}
		local cycle_duration = 3
		local distance = 18
		local cycle_progress = 0

		local is_player_part = function(part)
			for _, plr in services.players:GetPlayers() do
				if plr.Character and plr.Character:IsAncestorOf(part) then
					return true
				end
			end
			return false
		end

		local is_valid_part = function(part)
			local anchored = stuff.rawrbxget(part, 'Anchored')
			if anchored or is_player_part(part) or part:IsDescendantOf(stuff.owner_char) then
				return false
			end
			if part.Parent ~= workspace and (part.Parent:FindFirstChildOfClass('Humanoid') or part.Parent.Parent and part.Parent.Parent:FindFirstChildOfClass('Humanoid')) then
				return false
			end
			return #part:GetConnectedParts() < 2
		end

		for _, part in workspace:GetDescendants() do
			if part:IsA('BasePart') and is_valid_part(part) then
				table.insert(parts, part)
			end
		end

		local desc_added_conn = workspace.DescendantAdded:Connect(function(part)
			if part:IsA('BasePart') and is_valid_part(part) then
				table.insert(parts, part)
			end
		end)

		vstorage.partwalkfling_conn = desc_added_conn

		task.wait(1)

		maid.add('part_walkfling_'..target.Name, services.run_service.Heartbeat, function(dt)
			if not target.Character or not target_hrp:IsDescendantOf(workspace) or not target:IsDescendantOf(game) then
				maid.remove('part_walkfling_'..target.Name)
				desc_added_conn:Disconnect()
				return
			end

			for i = #parts, 1, -1 do
				local part = parts[i]

				if not part:IsDescendantOf(game) then
					table.remove(parts, i)
					continue
				end

				pcall(function()
					if part.ReceiveAge ~= 0 then return end
					local anchored = stuff.rawrbxget(part, 'Anchored')
					if anchored then return end

					stuff.rawrbxset(part, 'CanCollide', false)
					stuff.rawrbxset(part, 'Velocity', Vector3.new(0, 500000000000, 0))

					local target_hrp_pos = stuff.rawrbxget(target_hrp, 'Position')

					if not torso_mode then
						cycle_progress = (cycle_progress + dt / cycle_duration) % 1
						local alpha = 2 * math.pi * cycle_progress
						stuff.rawrbxset(part, 'CFrame', CFrame.Angles(0, alpha, 0) * CFrame.new(0, 0, distance + part.Size.Magnitude) + target_hrp_pos)
					else
						if target == stuff.owner then
							stuff.rawrbxset(part, 'CFrame', stuff.rawrbxget(target_hrp, 'CFrame'))
						else
							local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
							if humanoid then
								humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
								stuff.rawrbxset(humanoid, 'Sit', true)
							end
							local target_hrp_cf = stuff.rawrbxget(target_hrp, 'CFrame')
							local offset_cframe = target_hrp_cf * CFrame.new(0, 0, -(17 + part.Size.Magnitude))
							stuff.rawrbxset(part, 'CFrame', offset_cframe)
							stuff.owner_char:PivotTo(offset_cframe)
						end
					end
				end)
			end
		end)
	end
end)

cmd_library.add({'unpartwalkfling', 'unpwalkfling', 'unpartwalkf', 'unpwalkf', 'unpwf'}, 'stop partwalkfling', {}, function(vstorage)
	for _, player in services.players:GetPlayers() do
		maid.remove('part_walkfling_'..player.Name)
	end

	maid.remove('partwalkfling_died')
	maid.remove('partwalkfling_char_added')

	if vstorage.partwalkfling_conn then
		vstorage.partwalkfling_conn:Disconnect()
		vstorage.partwalkfling_conn = nil
	end

	notify('unpartwalkfling', 'partwalkfling stopped', 1)
end)

-- c6: visual

cmd_library.add({'btracers', 'bullettracers'}, 'enables bullet tracers when shooting', {
	{'color', 'color'},
	{'thickness', 'number'},
	{'duration', 'number'}
}, function(vstorage, color, thickness, duration)
	if vstorage.enabled then
		return notify('btracers', 'already enabled, use unbtracers to disable', 2)
	end

	vstorage.enabled = true
	vstorage.color = color or Color3.fromRGB(176, 126, 215)
	vstorage.thickness = math.clamp(thickness or 0.05, 0.05, 0.5)
	vstorage.duration = math.clamp(duration or 0.5, 0.1, 5)
	vstorage.last_click = 0

	local function trace(start_pos, end_pos)
		local distance = (end_pos - start_pos).Magnitude
		if distance < 0.1 then return end

		local cylinder = Instance.new('Part')
		cylinder.Name = 'tracer'
		cylinder.Shape = Enum.PartType.Cylinder
		cylinder.Material = Enum.Material.Neon
		cylinder.Color = vstorage.color
		cylinder.Size = Vector3.new(distance, vstorage.thickness, vstorage.thickness)
		cylinder.Anchored = true
		cylinder.CanCollide = false
		cylinder.CastShadow = false
		cylinder.Transparency = 0

		local midpoint = (start_pos + end_pos) / 2
		cylinder.CFrame = CFrame.lookAt(midpoint, end_pos) * CFrame.Angles(0, math.rad(90), 0)
		cylinder.Parent = workspace.Terrain

		local highlight = Instance.new('Highlight')
		local h, s, v = vstorage.color:ToHSV()
		highlight.FillColor = Color3.fromHSV(h, s, v * 0.5)
		highlight.FillTransparency = 0
		highlight.OutlineTransparency = 1
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.Adornee = cylinder
		highlight.Parent = services.core_gui

		task.delay(vstorage.duration, stuff.destroy, cylinder)
	end

	local function get_start_position()
		local character = stuff.owner_char
		if not character then return workspace.CurrentCamera.CFrame.Position end

		local tool = character:FindFirstChildOfClass('Tool')
		if tool then
			local handle = tool:FindFirstChild('Handle')
			if handle then
				local muzzle = handle:FindFirstChild('Muzzle') or handle:FindFirstChild('Flash') or handle:FindFirstChild('FirePoint')
				if muzzle and muzzle:IsA('Attachment') then
					return muzzle.WorldPosition
				elseif muzzle and muzzle:IsA('BasePart') then
					return muzzle.Position
				else
					return (handle.CFrame * CFrame.new(0, 0, -handle.Size.Z / 2)).Position
				end
			end
		end

		return workspace.CurrentCamera.CFrame.Position
	end

	local function on_click()
		if not vstorage.enabled then return end

		local now = tick()
		if now - vstorage.last_click < 0.05 then return end
		vstorage.last_click = now

		local character = stuff.owner_char
		if not character then return end

		local mouse = stuff.owner:GetMouse()
		local camera = workspace.CurrentCamera
		local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true

		local start_pos = get_start_position()
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
		local end_pos = result and result.Position or (ray.Origin + ray.Direction * 500)

		task.spawn(trace, start_pos, end_pos)
	end

	maid.add('btracers_click', stuff.owner:GetMouse().Button1Down, on_click)

	notify('btracers', `enabled | thickness: {vstorage.thickness} | duration: {vstorage.duration}s`, 1)
end)

cmd_library.add({'unbtracers', 'unbullettracers', 'untracers'}, 'disables bullet tracers', {}, function(vstorage)
	if not vstorage.enabled then
		return notify('btracers', 'not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('btracers_click')

	for _, part in ipairs(workspace:GetChildren()) do
		if part.Name == 'BulletTracer' then
			part:Destroy()
		end
	end

	notify('btracers', 'disabled', 1)
end)

cmd_library.add({'hitsound', 'hitmarker', 'hs'}, 'plays a sound when hitting a player', {
	{'sound_id', 'string'},
	{'volume', 'number'},
	{'pitch', 'number'}
}, function(vstorage, sound_id, volume, pitch)
	if vstorage.enabled then
		return notify('hitsound', 'already enabled, use unhitsound to disable', 2)
	end

	vstorage.enabled = true
	vstorage.sound_id = sound_id or 'rbxassetid://97643101798871'
	vstorage.volume = math.clamp(volume or 1, 0.1, 2)
	vstorage.pitch = math.clamp(pitch or 1, 0.5, 2)
	vstorage.last_click = 0

	local function is_player_part(part)
		if not part then return false end

		local character = part:FindFirstAncestorOfClass('Model')
		if not character then return false end

		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if not humanoid then return false end

		local player = services.players:GetPlayerFromCharacter(character)
		if not player then return false end

		if player == stuff.owner then return false end

		return true, player
	end

	local function play_hit_sound()
		local sound = Instance.new('Sound')
		sound.SoundId = vstorage.sound_id
		sound.Volume = vstorage.volume
		sound.PlaybackSpeed = vstorage.pitch * (0.95 + math.random() * 0.1)
		sound.Parent = workspace.CurrentCamera
		sound.PlayOnRemove = true
		pcall(stuff.destroy, sound)
	end

	local function on_click()
		if not vstorage.enabled then return end

		local now = tick()
		if now - vstorage.last_click < 0.05 then return end
		vstorage.last_click = now

		local character = stuff.owner_char
		if not character then return end

		local mouse = stuff.owner:GetMouse()
		local camera = workspace.CurrentCamera
		local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {character}
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.IgnoreWater = true

		local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)

		if result and result.Instance then
			local hit, player = is_player_part(result.Instance)
			if hit then
				play_hit_sound()
			end
		end
	end

	maid.add('hitsound_click', stuff.owner:GetMouse().Button1Down, on_click)

	notify('hitsound', `enabled | sound: {vstorage.sound_id} | volume: {vstorage.volume} | pitch: {vstorage.pitch}`, 1)
end)

cmd_library.add({'unhitsound', 'unhitmarker', 'unhs'}, 'disables hit sound', {}, function(vstorage)
	if not vstorage.enabled then
		return notify('hitsound', 'not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('hitsound_click')

	notify('hitsound', 'disabled', 1)
end)

cmd_library.add({'xray'}, 'makes walls transparent', {
	{'transparency', 'number'}
}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		vstorage.original_transparency = {}
		notify('xray', 'xray enabled', 1)

		for _, part in pairs(workspace:GetDescendants()) do
			if part:IsA('BasePart') and not part:IsDescendantOf(stuff.owner.Character) and part.Transparency < 1 then
				vstorage.original_transparency[part] = stuff.rawrbxget(part, 'Transparency')
				stuff.rawrbxset(part, 'Transparency', 0.7)
			end
		end

		maid.add('xray_descendant', workspace.DescendantAdded, function(descendant)
			if vstorage.enabled and descendant:IsA('BasePart') and not descendant:IsDescendantOf(stuff.owner.Character) then
				task.wait()
				if descendant.Transparency < 1 then
					vstorage.original_transparency[descendant] = stuff.rawrbxget(descendant, 'Transparency')
					stuff.rawrbxset(descendant, 'Transparency', 0.7)
				end
			end
		end)
	else
		notify('xray', 'xray disabled', 1)
		maid.remove('xray_descendant')

		for part, original_transparency in pairs(vstorage.original_transparency or {}) do
			if part and part.Parent then
				stuff.rawrbxset(part, 'Transparency', original_transparency)
			end
		end

		vstorage.original_transparency = {}
	end
end)

cmd_library.add({'crosshair', 'cross', 'xhair'}, 'custom crosshair', {
	{'style', 'string'},
	{'size', 'number'},
	{'thickness', 'number'},
	{'gap', 'number'},
	{'color', 'color'},
	{'outline', 'boolean'}
}, function(vstorage, style, size, thickness, gap, color, outline)
	if vstorage.enabled then
		cmd_library.execute('uncrosshair')
	end

	vstorage.enabled = true
	vstorage.style = (style or 'cross'):lower()
	vstorage.size = size or 10
	vstorage.thickness = thickness or 2
	vstorage.gap = gap or 4
	vstorage.color = color or Color3.fromRGB(176, 126, 215)
	vstorage.outline = outline ~= false
	vstorage.drawings = {}

	local center = workspace.CurrentCamera.ViewportSize / 2

	if vstorage.style == 'cross' then
		local lines = {
			{Vector2.new(center.X, center.Y - vstorage.gap - vstorage.size), Vector2.new(center.X, center.Y - vstorage.gap)},
			{Vector2.new(center.X, center.Y + vstorage.gap), Vector2.new(center.X, center.Y + vstorage.gap + vstorage.size)},
			{Vector2.new(center.X - vstorage.gap - vstorage.size, center.Y), Vector2.new(center.X - vstorage.gap, center.Y)},
			{Vector2.new(center.X + vstorage.gap, center.Y), Vector2.new(center.X + vstorage.gap + vstorage.size, center.Y)}
		}

		for i, data in lines do
			if vstorage.outline then
				local outline_line = Drawing.new('Line')
				outline_line.From = data[1]
				outline_line.To = data[2]
				outline_line.Thickness = vstorage.thickness + 2
				outline_line.Color = Color3.new(0, 0, 0)
				outline_line.Visible = true
				table.insert(vstorage.drawings, outline_line)
			end

			local line = Drawing.new('Line')
			line.From = data[1]
			line.To = data[2]
			line.Thickness = vstorage.thickness
			line.Color = vstorage.color
			line.Visible = true
			table.insert(vstorage.drawings, line)
		end
	elseif vstorage.style == 'dot' then
		if vstorage.outline then
			local outline_dot = Drawing.new('Circle')
			outline_dot.Position = center
			outline_dot.Radius = vstorage.size / 2 + 1
			outline_dot.Filled = true
			outline_dot.Color = Color3.new(0, 0, 0)
			outline_dot.Visible = true
			table.insert(vstorage.drawings, outline_dot)
		end

		local dot = Drawing.new('Circle')
		dot.Position = center
		dot.Radius = vstorage.size / 2
		dot.Filled = true
		dot.Color = vstorage.color
		dot.NumSides = 16
		dot.Visible = true
		table.insert(vstorage.drawings, dot)
	elseif vstorage.style == 'circle' then
		if vstorage.outline then
			local outline_circle = Drawing.new('Circle')
			outline_circle.Position = center
			outline_circle.Radius = vstorage.size
			outline_circle.Filled = false
			outline_circle.Thickness = vstorage.thickness + 2
			outline_circle.Color = Color3.new(0, 0, 0)
			outline_circle.NumSides = 32
			outline_circle.Visible = true
			table.insert(vstorage.drawings, outline_circle)
		end

		local circle = Drawing.new('Circle')
		circle.Position = center
		circle.Radius = vstorage.size
		circle.Filled = false
		circle.Thickness = vstorage.thickness
		circle.Color = vstorage.color
		circle.NumSides = 32
		circle.Visible = true
		table.insert(vstorage.drawings, circle)
	else
		return notify('crosshair', 'invalid style, must be one of: lines, dot, circle', 2)
	end

	notify('crosshair', `enabled | style: {vstorage.style} | size: {vstorage.size}`, 1)
end)

cmd_library.add({'uncrosshair', 'uncross', 'unxhair'}, 'disables crosshair', {}, function()
	local vs = cmd_library.get_variable_storage('crosshair')
	if not vs.enabled then
		return notify('crosshair', 'not enabled', 2)
	end

	vs.enabled = false

	for _, drawing in vs.drawings or {} do
		if drawing.Remove then drawing:Remove() end
	end
	vs.drawings = {}

	notify('crosshair', 'disabled', 1)
end)

cmd_library.add({'esp', 'playeresp', 'toggleesp'}, 'toggles esp', {
	{'color', 'color3'},
	{'include_npcs', 'boolean'}
}, function(vstorage, color, include_npcs)
	vstorage.enabled = not vstorage.enabled
	vstorage.team = color == 'team'
	vstorage.include_npcs = include_npcs or false
	vstorage.billboards = vstorage.billboards or {}

	if not vstorage.team then
		local parsed = color
		if parsed then
			vstorage.color = parsed
		end
	end

	vstorage.color = vstorage.color or Color3.fromRGB(176, 126, 215)

	if vstorage.enabled then
		notify('esp', `esp enabled{vstorage.include_npcs and ' (with npcs)' or ''}`, 1)
	else
		notify('esp', 'esp disabled', 1)

		for _, billboard in pairs(vstorage.billboards) do
			pcall(stuff.destroy, billboard)
		end

		for _, highlight in pairs(stuff.highlights) do
			pcall(stuff.destroy, highlight)
		end

		table.clear(vstorage.billboards)
		table.clear(stuff.highlights)
	end
end)

maid.add('esp_player_removing', services.players.PlayerRemoving, function(plr)
	local esp_vs = cmd_library.get_variable_storage('esp')
	if esp_vs and esp_vs.billboards and esp_vs.billboards[plr] then
		pcall(stuff.destroy, esp_vs.billboards[plr])
		esp_vs.billboards[plr] = nil
	end
	if stuff.highlights[plr] then
		pcall(stuff.destroy, stuff.highlights[plr])
		stuff.highlights[plr] = nil
	end
end, true)

maid.add('esp_update', services.run_service.RenderStepped, function()
	local esp_vs = cmd_library.get_variable_storage('esp')
	if not esp_vs or not esp_vs.enabled then return end

	local entities = {}

	for _, plr in pairs(services.players:GetPlayers()) do
		if plr ~= stuff.owner and plr.Character then
			table.insert(entities, {
				name = plr.Name,
				character = plr.Character,
				player = plr,
				is_npc = false
			})
		end
	end

	if esp_vs.include_npcs then
		for _, model in pairs(workspace:GetDescendants()) do
			if model:IsA('Model') and model:FindFirstChild('Humanoid') and model:FindFirstChild('HumanoidRootPart') then
				local is_player_char = false
				for _, plr in pairs(services.players:GetPlayers()) do
					if plr.Character == model then
						is_player_char = true
						break
					end
				end

				if not is_player_char and model ~= stuff.owner_char then
					table.insert(entities, {
						name = model.Name,
						character = model,
						player = model,
						is_npc = true
					})
				end
			end
		end
	end

	for _, entity in pairs(entities) do
		local char = entity.character
		local hrp = char:FindFirstChild('HumanoidRootPart')
		local humanoid = char:FindFirstChildOfClass('Humanoid')

		if hrp then
			local esp_billboard = esp_vs.billboards[entity.player]
			if not esp_billboard or not esp_billboard.Parent then
				if esp_billboard then
					pcall(stuff.destroy, esp_billboard)
				end

				esp_billboard = Instance.new('BillboardGui')
				stuff.rawrbxset(esp_billboard, 'Size', UDim2.new(100, 0, 100, 0))
				stuff.rawrbxset(esp_billboard, 'StudsOffset', Vector3.new(0, 0, 0))
				stuff.rawrbxset(esp_billboard, 'AlwaysOnTop', true)
				stuff.rawrbxset(esp_billboard, 'MaxDistance', math.huge)
				stuff.rawrbxset(esp_billboard, 'ClipsDescendants', false)
				stuff.rawrbxset(esp_billboard, 'Adornee', hrp)
				stuff.rawrbxset(esp_billboard, 'Parent', services.core_gui)
				esp_vs.billboards[entity.player] = esp_billboard

				local box_frame = Instance.new('Frame')
				stuff.rawrbxset(box_frame, 'Size', UDim2.new(0.048, 0, 0.072, 0))
				stuff.rawrbxset(box_frame, 'Position', UDim2.new(0.5, 0, 0.5, 0))
				stuff.rawrbxset(box_frame, 'AnchorPoint', Vector2.new(0.5, 0.5))
				stuff.rawrbxset(box_frame, 'BackgroundTransparency', 1)
				stuff.rawrbxset(box_frame, 'Parent', esp_billboard)

				local top = Instance.new('Frame')
				stuff.rawrbxset(top, 'Size', UDim2.new(1, 0, 0, 1))
				stuff.rawrbxset(top, 'Position', UDim2.new(0, 0, 0, 0))
				stuff.rawrbxset(top, 'BorderSizePixel', 0)
				stuff.rawrbxset(top, 'Parent', box_frame)

				local bottom = Instance.new('Frame')
				stuff.rawrbxset(bottom, 'Size', UDim2.new(1, 0, 0, 1))
				stuff.rawrbxset(bottom, 'Position', UDim2.new(0, 0, 1, -1))
				stuff.rawrbxset(bottom, 'BorderSizePixel', 0)
				stuff.rawrbxset(bottom, 'Parent', box_frame)

				local left = Instance.new('Frame')
				stuff.rawrbxset(left, 'Size', UDim2.new(0, 1, 1, 0))
				stuff.rawrbxset(left, 'Position', UDim2.new(0, 0, 0, 0))
				stuff.rawrbxset(left, 'BorderSizePixel', 0)
				stuff.rawrbxset(left, 'Parent', box_frame)

				local right = Instance.new('Frame')
				stuff.rawrbxset(right, 'Size', UDim2.new(0, 1, 1, 0))
				stuff.rawrbxset(right, 'Position', UDim2.new(1, -1, 0, 0))
				stuff.rawrbxset(right, 'BorderSizePixel', 0)
				stuff.rawrbxset(right, 'Parent', box_frame)

				local name_label = Instance.new('TextLabel')
				stuff.rawrbxset(name_label, 'Size', UDim2.new(1, 0, 0, 18))
				stuff.rawrbxset(name_label, 'Position', UDim2.new(0, 0, 0, -20))
				stuff.rawrbxset(name_label, 'BackgroundTransparency', 1)
				stuff.rawrbxset(name_label, 'BorderSizePixel', 0)
				stuff.rawrbxset(name_label, 'TextSize', 14)
				stuff.rawrbxset(name_label, 'Font', Enum.Font.Code)
				stuff.rawrbxset(name_label, 'TextStrokeTransparency', 0.5)
				stuff.rawrbxset(name_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
				stuff.rawrbxset(name_label, 'TextYAlignment', Enum.TextYAlignment.Bottom)
				stuff.rawrbxset(name_label, 'Parent', box_frame)

				local distance_label = Instance.new('TextLabel')
				stuff.rawrbxset(distance_label, 'Size', UDim2.new(1, 0, 0, 14))
				stuff.rawrbxset(distance_label, 'Position', UDim2.new(0, 0, 1, 2))
				stuff.rawrbxset(distance_label, 'BackgroundTransparency', 1)
				stuff.rawrbxset(distance_label, 'BorderSizePixel', 0)
				stuff.rawrbxset(distance_label, 'TextSize', 12)
				stuff.rawrbxset(distance_label, 'Font', Enum.Font.Code)
				stuff.rawrbxset(distance_label, 'TextStrokeTransparency', 0.5)
				stuff.rawrbxset(distance_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
				stuff.rawrbxset(distance_label, 'TextYAlignment', Enum.TextYAlignment.Top)
				stuff.rawrbxset(distance_label, 'Parent', box_frame)

				local health_bg = Instance.new('Frame')
				stuff.rawrbxset(health_bg, 'Size', UDim2.new(0, 3, 1, 0))
				stuff.rawrbxset(health_bg, 'Position', UDim2.new(1, 4, 0, 0))
				stuff.rawrbxset(health_bg, 'BackgroundColor3', Color3.new(0.1, 0.1, 0.1))
				stuff.rawrbxset(health_bg, 'BorderSizePixel', 0)
				stuff.rawrbxset(health_bg, 'Parent', box_frame)

				local health_bar = Instance.new('Frame')
				stuff.rawrbxset(health_bar, 'Size', UDim2.new(1, 0, 1, 0))
				stuff.rawrbxset(health_bar, 'Position', UDim2.new(0, 0, 1, 0))
				stuff.rawrbxset(health_bar, 'AnchorPoint', Vector2.new(0, 1))
				stuff.rawrbxset(health_bar, 'BackgroundColor3', Color3.fromRGB(0, 255, 0))
				stuff.rawrbxset(health_bar, 'BorderSizePixel', 0)
				stuff.rawrbxset(health_bar, 'Parent', health_bg)

				local health_text = Instance.new('TextLabel')
				stuff.rawrbxset(health_text, 'Size', UDim2.new(0, 30, 0, 14))
				stuff.rawrbxset(health_text, 'Position', UDim2.new(1, 5, 1, -14))
				stuff.rawrbxset(health_text, 'BackgroundTransparency', 1)
				stuff.rawrbxset(health_text, 'BorderSizePixel', 0)
				stuff.rawrbxset(health_text, 'TextSize', 12)
				stuff.rawrbxset(health_text, 'Font', Enum.Font.Code)
				stuff.rawrbxset(health_text, 'TextStrokeTransparency', 0.5)
				stuff.rawrbxset(health_text, 'TextStrokeColor3', Color3.new(0, 0, 0))
				stuff.rawrbxset(health_text, 'TextXAlignment', Enum.TextXAlignment.Left)
				stuff.rawrbxset(health_text, 'Parent', health_bg)

				local tool_label = Instance.new('TextLabel')
				stuff.rawrbxset(tool_label, 'Size', UDim2.new(0, 100, 0, 50))
				stuff.rawrbxset(tool_label, 'Position', UDim2.new(0, -104, 0, 0))
				stuff.rawrbxset(tool_label, 'BackgroundTransparency', 1)
				stuff.rawrbxset(tool_label, 'BorderSizePixel', 0)
				stuff.rawrbxset(tool_label, 'TextSize', 12)
				stuff.rawrbxset(tool_label, 'Font', Enum.Font.Code)
				stuff.rawrbxset(tool_label, 'TextStrokeTransparency', 0.5)
				stuff.rawrbxset(tool_label, 'TextStrokeColor3', Color3.new(0, 0, 0))
				stuff.rawrbxset(tool_label, 'TextXAlignment', Enum.TextXAlignment.Right)
				stuff.rawrbxset(tool_label, 'TextYAlignment', Enum.TextYAlignment.Top)
				stuff.rawrbxset(tool_label, 'TextWrapped', false)
				stuff.rawrbxset(tool_label, 'Parent', box_frame)
			else
				if stuff.rawrbxget(esp_billboard, 'Adornee') ~= hrp then
					stuff.rawrbxset(esp_billboard, 'Adornee', hrp)
				end
			end

			local box_frame = esp_billboard:GetChildren()[1]
			local top = box_frame:GetChildren()[1]
			local bottom = box_frame:GetChildren()[2]
			local left = box_frame:GetChildren()[3]
			local right = box_frame:GetChildren()[4]
			local name_label = box_frame:GetChildren()[5]
			local distance_label = box_frame:GetChildren()[6]
			local health_bg = box_frame:GetChildren()[7]
			local health_bar = health_bg:GetChildren()[1]
			local health_text = health_bg:GetChildren()[2]
			local tool_label = box_frame:GetChildren()[8]

			local color = esp_vs.color
			if not entity.is_npc and esp_vs.team and entity.player.Team then
				color = entity.player.Team == stuff.owner.Team and Color3.fromRGB(143, 255, 130) or Color3.fromRGB(255, 130, 130)
			elseif entity.is_npc then
				color = Color3.fromRGB(255, 255, 130)
			end

			stuff.rawrbxset(top, 'BackgroundColor3', color)
			stuff.rawrbxset(bottom, 'BackgroundColor3', color)
			stuff.rawrbxset(left, 'BackgroundColor3', color)
			stuff.rawrbxset(right, 'BackgroundColor3', color)

			local display_name = entity.name
			if entity.is_npc then
				display_name = `[NPC] {entity.name}`
			end
			stuff.rawrbxset(name_label, 'Text', display_name)
			stuff.rawrbxset(name_label, 'TextColor3', color)

			local owner_hrp = stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if owner_hrp then
				local owner_pos = stuff.rawrbxget(owner_hrp, 'Position')
				local hrp_pos = stuff.rawrbxget(hrp, 'Position')
				local distance = math.floor((owner_pos - hrp_pos).Magnitude)
				stuff.rawrbxset(distance_label, 'Text', `[{distance}m]`)
				stuff.rawrbxset(distance_label, 'TextColor3', Color3.fromRGB(200, 200, 200))
			end

			local tool_names = {}
			for _, tool in pairs(char:GetChildren()) do
				if tool:IsA('Tool') then
					local tool_name = stuff.rawrbxget(tool, 'Name')
					table.insert(tool_names, tool_name)
				end
			end

			local tool_text = #tool_names > 0 and table.concat(tool_names, '\n') or ''
			stuff.rawrbxset(tool_label, 'Text', tool_text)
			stuff.rawrbxset(tool_label, 'TextColor3', Color3.fromRGB(200, 200, 200))

			if humanoid then
				local health = stuff.rawrbxget(humanoid, 'Health')
				local max_health = stuff.rawrbxget(humanoid, 'MaxHealth')
				local health_percent = math.clamp(health / max_health, 0, 1)

				stuff.rawrbxset(health_bar, 'Size', UDim2.new(1, 0, health_percent, 0))
				stuff.rawrbxset(health_bar, 'Position', UDim2.new(0, 0, 1, 0))

				local health_color = Color3.fromRGB(
					math.floor(255 * (1 - health_percent)),
					math.floor(255 * health_percent),
					0
				)
				stuff.rawrbxset(health_bar, 'BackgroundColor3', health_color)

				stuff.rawrbxset(health_text, 'Text', math.floor(health))
				stuff.rawrbxset(health_text, 'TextColor3', health_color)
			end

			local highlight = stuff.highlights[entity.player]
			if not highlight or not highlight.Parent then
				if highlight then
					pcall(stuff.destroy, highlight)
				end

				highlight = Instance.new('Highlight')
				stuff.rawrbxset(highlight, 'Adornee', char)
				stuff.rawrbxset(highlight, 'FillColor', color)
				stuff.rawrbxset(highlight, 'FillTransparency', 0.75)
				stuff.rawrbxset(highlight, 'OutlineColor', color)
				stuff.rawrbxset(highlight, 'OutlineTransparency', 0.5)
				stuff.rawrbxset(highlight, 'DepthMode', Enum.HighlightDepthMode.AlwaysOnTop)
				stuff.rawrbxset(highlight, 'Parent', services.core_gui)
				stuff.highlights[entity.player] = highlight
			else
				if stuff.rawrbxget(highlight, 'Adornee') ~= char then
					stuff.rawrbxset(highlight, 'Adornee', char)
				end
				stuff.rawrbxset(highlight, 'FillColor', color)
				stuff.rawrbxset(highlight, 'OutlineColor', color)
			end
		end
	end
end, true)

cmd_library.add({'tracers', 'toggletracers'}, 'toggles tracers', {
	{'color', 'color3'},
	{'include_npcs', 'boolean'}
}, function(vstorage, color, include_npcs)
	vstorage.enabled = not vstorage.enabled
	vstorage.team = color == 'team'
	vstorage.include_npcs = include_npcs or false

	if not vstorage.team then
		local parsed = color
		if parsed then
			vstorage.color = parsed
		end
	end

	vstorage.color = vstorage.color or Color3.fromRGB(176, 126, 215)
	vstorage.thickness = vstorage.thickness or 1
	vstorage.transparency = vstorage.transparency or 0
	vstorage.mode = vstorage.mode or 'bottom'

	if vstorage.enabled then
		notify('tracers', `tracers enabled{vstorage.include_npcs and ' (with npcs)' or ''}`, 1)

		if not vstorage.gui then
			local gui = Instance.new('ScreenGui')
			stuff.rawrbxset(gui, 'IgnoreGuiInset', true)
			stuff.rawrbxset(gui, 'ResetOnSpawn', false)
			stuff.rawrbxset(gui, 'ZIndexBehavior', Enum.ZIndexBehavior.Global)
			pcall(protect_gui, gui)
			vstorage.gui = gui
		end

		if not vstorage.lines then
			vstorage.lines = {}
		end
	else
		notify('tracers', 'tracers disabled', 1)

		if vstorage.lines then
			for _, line in pairs(vstorage.lines) do
				if line then pcall(stuff.destroy, line) end
			end
			vstorage.lines = nil
		end

		if vstorage.gui then
			pcall(stuff.destroy, vstorage.gui)
			vstorage.gui = nil
		end
	end
end)

maid.add('tracers_playerremoving', services.players.PlayerRemoving, function(plr)
	local tracers_vs = cmd_library.get_variable_storage('tracers')
	if tracers_vs and tracers_vs.lines and tracers_vs.lines[plr] then
		pcall(stuff.destroy, tracers_vs.lines[plr])
		tracers_vs.lines[plr] = nil
	end
end, true)

maid.add('tracers_update', services.run_service.RenderStepped, function()
	local tracers_vs = cmd_library.get_variable_storage('tracers')
	if not tracers_vs.enabled or not tracers_vs.gui then return end

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	if not cam then return end

	local viewport = cam.ViewportSize

	local start_x, start_y
	if tracers_vs.mode == 'center' then
		start_x = viewport.X / 2
		start_y = viewport.Y / 2
	elseif tracers_vs.mode == 'mouse' then
		local m = services.user_input_service:GetMouseLocation()
		start_x = m.X
		start_y = m.Y
	else
		start_x = viewport.X / 2
		start_y = viewport.Y
	end

	local seen = {}
	local entities = {}

	for _, plr in pairs(services.players:GetPlayers()) do
		if plr ~= stuff.owner and plr.Character then
			table.insert(entities, {
				player = plr,
				character = plr.Character,
				is_npc = false
			})
		end
	end

	if tracers_vs.include_npcs then
		for _, model in pairs(workspace:GetDescendants()) do
			if model:IsA('Model') and model:FindFirstChild('Humanoid') and model:FindFirstChild('HumanoidRootPart') then
				local is_player_char = false
				for _, plr in pairs(services.players:GetPlayers()) do
					if plr.Character == model then
						is_player_char = true
						break
					end
				end

				if not is_player_char and model ~= stuff.owner_char then
					table.insert(entities, {
						player = model,
						character = model,
						is_npc = true
					})
				end
			end
		end
	end

	for _, entity in pairs(entities) do
		local line = tracers_vs.lines and tracers_vs.lines[entity.player]
		if not line then
			line = Instance.new('Frame')
			stuff.rawrbxset(line, 'BorderSizePixel', 0)
			stuff.rawrbxset(line, 'ZIndex', 9999)
			stuff.rawrbxset(line, 'Parent', tracers_vs.gui)
			tracers_vs.lines = tracers_vs.lines or {}
			tracers_vs.lines[entity.player] = line
		end

		seen[entity.player] = true

		local char = entity.character
		local hrp = char and char:FindFirstChild('HumanoidRootPart')
		if hrp then
			local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
			local hrp_size = stuff.rawrbxget(hrp, 'Size')
			local target = (hrp_cf * CFrame.new(0, -hrp_size.Y / 2, 0)).Position
			local vec, on_screen = cam:WorldToViewportPoint(target)

			if on_screen and vec.Z > 0 then
				local color = tracers_vs.color
				if not entity.is_npc and tracers_vs.team and entity.player.Team then
					color = entity.player.Team == stuff.owner.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
				elseif entity.is_npc then
					color = Color3.fromRGB(255, 255, 130)
				end

				local end_x = vec.X
				local end_y = vec.Y

				local dx = end_x - start_x
				local dy = end_y - start_y
				local distance = math.sqrt(dx * dx + dy * dy)
				local angle = math.deg(math.atan2(dy, dx))

				local center_x = (start_x + end_x) / 2
				local center_y = (start_y + end_y) / 2

				stuff.rawrbxset(line, 'BackgroundColor3', color)
				stuff.rawrbxset(line, 'BackgroundTransparency', tracers_vs.transparency)
				stuff.rawrbxset(line, 'Size', UDim2.new(0, distance, 0, tracers_vs.thickness))
				stuff.rawrbxset(line, 'Position', UDim2.new(0, center_x, 0, center_y))
				stuff.rawrbxset(line, 'AnchorPoint', Vector2.new(0.5, 0.5))
				stuff.rawrbxset(line, 'Rotation', angle)
				stuff.rawrbxset(line, 'Visible', true)
			else
				stuff.rawrbxset(line, 'Visible', false)
			end
		else
			stuff.rawrbxset(line, 'Visible', false)
		end
	end

	if tracers_vs.lines then
		for player, line in pairs(tracers_vs.lines) do
			if not seen[player] and line then
				stuff.rawrbxset(line, 'Visible', false)
			end
		end
	end
end, true)

cmd_library.add({'fullbright', 'fb'}, 'removes darkness', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('fullbright', 'fullbright enabled', 1)

		vstorage.original_ambient = stuff.rawrbxget(services.lighting, 'Ambient')
		vstorage.original_brightness = stuff.rawrbxget(services.lighting, 'Brightness')
		vstorage.original_outdoor_ambient = stuff.rawrbxget(services.lighting, 'OutdoorAmbient')

		stuff.rawrbxset(services.lighting, 'Ambient', Color3.new(1, 1, 1))
		stuff.rawrbxset(services.lighting, 'Brightness', 2)
		stuff.rawrbxset(services.lighting, 'OutdoorAmbient', Color3.new(1, 1, 1))

		maid.add('fullbright', services.lighting.ChildAdded, function(child)
			if vstorage.enabled then
				if child:IsA('BloomEffect') or child:IsA('BlurEffect') or child:IsA('ColorCorrectionEffect') or child:IsA('SunRaysEffect') then
					stuff.rawrbxset(child, 'Enabled', false)
				end
			end
		end)

		for _, effect in pairs(services.lighting:GetChildren()) do
			if effect:IsA('BloomEffect') or effect:IsA('BlurEffect') or effect:IsA('ColorCorrectionEffect') or effect:IsA('SunRaysEffect') then
				stuff.rawrbxset(effect, 'Enabled', false)
			end
		end
	else
		notify('fullbright', 'fullbright disabled', 1)
		maid.remove('fullbright')

		stuff.rawrbxset(services.lighting, 'Ambient', vstorage.original_ambient)
		stuff.rawrbxset(services.lighting, 'Brightness', vstorage.original_brightness)
		stuff.rawrbxset(services.lighting, 'OutdoorAmbient', vstorage.original_outdoor_ambient)
	end
end)

cmd_library.add({'view', 'spectate'}, 'spectate another player', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('view', 'target not found', 2)
	end

	local target = targets[1]
	if not target.Character or not target.Character:FindFirstChild('Humanoid') then
		return notify('view', 'target has no character', 2)
	end

	local camera = stuff.rawrbxget(workspace, 'CurrentCamera')
	local target_humanoid = stuff.rawrbxget(target.Character, 'Humanoid')
	stuff.rawrbxset(camera, 'CameraSubject', target_humanoid)
	vstorage.target = target
	vstorage.enabled = true

	notify('view', `spectating {target.Name}`, 1)
end)

cmd_library.add({'unview', 'unspectate', 'endview'}, 'stop spectating', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('view')

	if not vstorage.enabled then
		return notify('view', 'you aren\'t viewing anyone', 2)
	end

	local camera = stuff.rawrbxget(workspace, 'CurrentCamera')
	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(camera, 'CameraSubject', humanoid)
	notify('view', `stopped spectating {vstorage.target.Name}`, 1)
	vstorage.target = nil
	vstorage.enabled = false
end)

cmd_library.add({'day'}, 'sets time to day', {}, function(vstorage)
	notify('day', 'time set to day', 1)
	stuff.rawrbxset(services.lighting, 'ClockTime', 14)
end)

cmd_library.add({'night'}, 'sets time to night', {}, function(vstorage)
	notify('night', 'time set to night', 1)
	stuff.rawrbxset(services.lighting, 'ClockTime', 0)
end)

cmd_library.add({'time'}, 'sets the time of day', {
	{'time', 'number'}
}, function(vstorage, time)
	time = time or 14
	notify('time', `time set to {time}`, 1)
	stuff.rawrbxset(services.lighting, 'ClockTime', time)
end)

cmd_library.add({'nofog', 'unfog'}, 'removes fog', {}, function(vstorage)
	if vstorage.enabled then
		return notify('nofog', 'already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.original = services.lighting.FogEnd

	services.lighting.FogEnd = 100000

	notify('nofog', 'enabled', 1)
end)

cmd_library.add({'unnofog', 'fog'}, 'restores fog', {}, function()
	local vs = cmd_library.get_variable_storage('nofog')
	if not vs.enabled then
		return notify('nofog', 'not enabled', 2)
	end

	vs.enabled = false
	services.lighting.FogEnd = vs.original or 10000

	notify('nofog', 'disabled', 1)
end)

cmd_library.add({'brightness'}, 'sets brightness', {
	{'value', 'number'}
}, function(vstorage, value)
	value = value or 2
	notify('brightness', `brightness set to {value}`, 1)
	stuff.rawrbxset(services.lighting, 'Brightness', value)
end)

cmd_library.add({'fov'}, 'sets field of view', {
	{'fov', 'number'}
}, function(vstorage, value)
	value = value or 70
	notify('fov', `fov set to {value}`, 1)
	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	stuff.rawrbxset(cam, 'FieldOfView', value)
end)

cmd_library.add({'removesky'}, 'removes sky', {}, function(vstorage)
	notify('removesky', 'sky removed', 1)

	for _, v in pairs(services.lighting:GetChildren()) do
		if v:IsA('Sky') then
			stuff.destroy(v)
		end
	end
end)

cmd_library.add({'ambient'}, 'sets ambient lighting', {
	{'color', 'color3'}
}, function(vstorage, color)
	local parsed = color or Color3.fromRGB(255, 255, 255)
	notify('ambient', 'ambient set', 1)
	stuff.rawrbxset(services.lighting, 'Ambient', parsed)
end)

cmd_library.add({'outdoorambient'}, 'sets outdoor ambient', {
	{'color', 'color3'}
}, function(vstorage, color)
	local parsed = color or Color3.fromRGB(255, 255, 255)
	notify('outdoorambient', 'outdoor ambient set', 1)
	stuff.rawrbxset(services.lighting, 'OutdoorAmbient', parsed)
end)

cmd_library.add({'colorshift'}, 'sets color shift', {
	{'top', 'color3'},
	{'bottom', 'color3'}
}, function(vstorage, top, bottom)
	notify('colorshift', 'color shift set', 1)
	stuff.rawrbxset(services.lighting, 'ColorShift_Top', top or Color3.new(0, 0, 0))
	stuff.rawrbxset(services.lighting, 'ColorShift_Bottom', bottom or Color3.new(0, 0, 0))
end)

cmd_library.add({'fixlighting', 'resetlighting'}, 'resets lighting', {}, function(vstorage)
	notify('fixlighting', 'lighting reset', 1)

	stuff.rawrbxset(services.lighting, 'Ambient', Color3.fromRGB(138, 138, 138))
	stuff.rawrbxset(services.lighting, 'OutdoorAmbient', Color3.fromRGB(128, 128, 128))
	stuff.rawrbxset(services.lighting, 'ColorShift_Top', Color3.new(0, 0, 0))
	stuff.rawrbxset(services.lighting, 'ColorShift_Bottom', Color3.new(0, 0, 0))
	stuff.rawrbxset(services.lighting, 'FogColor', Color3.fromRGB(191, 191, 191))
	stuff.rawrbxset(services.lighting, 'FogEnd', 100000)
	stuff.rawrbxset(services.lighting, 'Brightness', 2)
	stuff.rawrbxset(services.lighting, 'ClockTime', 14)
end)

cmd_library.add({'showfov', 'showcircle', 'fov'}, 'shows aim circle following mouse', {
	{'fov', 'number'},
	{'color', 'color'},
	{'thickness', 'number'},
	{'segments', 'number'},
	{'outline', 'boolean'}
}, function(vstorage, fov, color, thickness, segments, outline)
	if vstorage.enabled then
		cmd_library.execute('hidefov')
	end

	vstorage.enabled = true
	vstorage.fov = fov or 90
	vstorage.color = color or Color3.fromRGB(176, 126, 215)
	vstorage.thickness = thickness or 1
	vstorage.segments = segments or 64
	vstorage.outline = outline ~= false
	vstorage.drawings = {}

	local radius = fov_to_radius(vstorage.fov)

	if vstorage.outline then
		vstorage.drawings.outline = Drawing.new('Circle')
		vstorage.drawings.outline.Filled = false
		vstorage.drawings.outline.NumSides = vstorage.segments
		vstorage.drawings.outline.Thickness = vstorage.thickness + 2
		vstorage.drawings.outline.Color = Color3.new(0, 0, 0)
		vstorage.drawings.outline.Transparency = 0.5
		vstorage.drawings.outline.Radius = radius
		vstorage.drawings.outline.Visible = true
	end

	vstorage.drawings.circle = Drawing.new('Circle')
	vstorage.drawings.circle.Filled = false
	vstorage.drawings.circle.NumSides = vstorage.segments
	vstorage.drawings.circle.Thickness = vstorage.thickness
	vstorage.drawings.circle.Color = vstorage.color
	vstorage.drawings.circle.Transparency = 1
	vstorage.drawings.circle.Radius = radius
	vstorage.drawings.circle.Visible = true

	maid.add('fov_circle', services.run_service.RenderStepped, function()
		if not vstorage.enabled then return end

		local mouse = stuff.owner:GetMouse()
		local pos = Vector2.new(mouse.X, mouse.Y)

		if vstorage.drawings.outline then
			vstorage.drawings.outline.Position = pos
		end
		vstorage.drawings.circle.Position = pos
	end)

	notify('showfov', `fov circle enabled | fov: {vstorage.fov}° | radius: {math.floor(radius)}px`, 1)
end)

cmd_library.add({'hidefov', 'hidecircle', 'unfov'}, 'hides aim circle', {}, function()
	local vs = cmd_library.get_variable_storage('showfov')

	if not vs.enabled then
		return notify('showfov', 'not enabled', 2)
	end

	vs.enabled = false
	maid.remove('fov_circle')

	if vs.drawings then
		for _, drawing in vs.drawings do
			if drawing.Remove then drawing:Remove() end
		end
		vs.drawings = nil
	end

	notify('showfov', 'disabled', 1)
end)

cmd_library.add({'trail'}, 'adds trail to character', {
	{'color', 'color3'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, color, et)
	if et and vstorage.enabled then
		cmd_library.execute('untrail')
		return
	end

	notify('trail', 'trail added', 1)

	local parsed = color or Color3.fromRGB(255, 255, 255)

	for _, part in pairs(stuff.owner_char:GetDescendants()) do
		if part:IsA('BasePart') and part.Name == 'HumanoidRootPart' then
			local trail = Instance.new('Trail')
			local a0 = Instance.new('Attachment', part)
			local a1 = Instance.new('Attachment', part)
			stuff.rawrbxset(a0, 'Position', Vector3.new(0, part.Size.Y / 2, 0))
			stuff.rawrbxset(a1, 'Position', Vector3.new(0, -part.Size.Y / 2, 0))
			stuff.rawrbxset(trail, 'Attachment0', a0)
			stuff.rawrbxset(trail, 'Attachment1', a1)
			stuff.rawrbxset(trail, 'Color', ColorSequence.new(parsed))
			stuff.rawrbxset(trail, 'Lifetime', 1)
			stuff.rawrbxset(trail, 'Parent', part)
		end
	end
end)

cmd_library.add({'untrail'}, 'removes trail from character', {}, function(vstorage)
	notify('trail', 'trail removed', 1)

	for _, v in pairs(stuff.owner_char:GetDescendants()) do
		if v:IsA('Trail') then
			stuff.destroy(v)
		end
	end
end)

-- c7: player

cmd_library.add({'antideath', 'antikill', 'autodeath'}, 'teleports away from danger when health is low', {
	{'min_health', 'number'},
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, min_health, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unantideath')
		return
	end

	if vstorage.enabled then
		return notify('antideath', 'anti-death already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.min_health = min_health or 20
	vstorage.bypass = bypass
	notify('antideath', `anti-death enabled | threshold: {vstorage.min_health} HP{bypass and ' (bypass)' or ''}`, 1)

	local function setup_antideath()
		local humanoid = stuff.owner_char:FindFirstChildOfClass('Humanoid')
		if not humanoid then return end

		vstorage.last_health = stuff.rawrbxget(humanoid, 'Health')
		vstorage.safe_position = stuff.owner_char:GetPivot()
		vstorage.damage_source = nil
		vstorage.teleport_count = 0
		vstorage.last_damage_tick = 0
		vstorage.is_escaping = false
		vstorage.last_teleport_time = 0

		if bypass then
			local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if hrp then
				hook_lib.create_hook('antideath_bypass', {
					newindex = function(self, key, value)
						if vstorage.is_escaping then
							if self == hrp and (key == 'CFrame' or key == 'Position') then
								return false
							end
							if self:IsA('BasePart') and self:IsDescendantOf(stuff.owner_char) then
								if key == 'Velocity' or key == 'AssemblyLinearVelocity' or key == 'AssemblyAngularVelocity' or key == 'RotVelocity' then
									return false
								end
							end
						end
					end,

					index = function(self, key)
						if vstorage.is_escaping and self == humanoid then
							if key == 'Health' then
								return vstorage.last_health
							end
						end
					end
				})
			end
		end

		local function find_damage_source()
			local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if not hrp then return nil end

			local hrp_pos = stuff.rawrbxget(hrp, 'Position')
			local sources = {}

			for _, plr in pairs(services.players:GetPlayers()) do
				if plr ~= stuff.owner and plr.Character and plr.Character:FindFirstChild('HumanoidRootPart') then
					local plr_hrp = plr.Character.HumanoidRootPart
					local plr_pos = stuff.rawrbxget(plr_hrp, 'Position')
					local distance = (hrp_pos - plr_pos).Magnitude

					if distance < 30 then
						local has_tool = plr.Character:FindFirstChildOfClass('Tool')
						table.insert(sources, {
							type = 'player',
							source = plr,
							name = plr.Name,
							distance = distance,
							priority = has_tool and 1 or 2
						})
					end
				end
			end

			for _, obj in pairs(workspace:GetDescendants()) do
				if obj:IsA('BasePart') and obj.Parent ~= stuff.owner_char then
					local obj_pos = stuff.rawrbxget(obj, 'Position')
					local distance = (hrp_pos - obj_pos).Magnitude
					local obj_name = obj.Name:lower()

					if (obj_name:find('kill') or obj_name:find('damage') or obj_name:find('lava') or obj_name:find('death') or obj_name:find('fire') or obj_name:find('trap')) and distance < 25 then
						table.insert(sources, {
							type = 'hazard',
							source = obj,
							name = obj.Name,
							distance = distance,
							priority = 2
						})
					end

					local velocity = stuff.rawrbxget(obj, 'AssemblyLinearVelocity')
					if velocity.Magnitude > 60 and distance < 15 then
						table.insert(sources, {
							type = 'projectile',
							source = obj,
							name = obj.Name,
							distance = distance,
							priority = 1
						})
					end
				end
			end

			table.sort(sources, function(a, b)
				if a.priority == b.priority then
					return a.distance < b.distance
				end
				return a.priority < b.priority
			end)

			return sources[1]
		end

		local function teleport_to_safety()
			local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
			if not hrp then return end

			if tick() - vstorage.last_teleport_time < 0.15 then return end
			vstorage.last_teleport_time = tick()

			vstorage.teleport_count = vstorage.teleport_count + 1
			vstorage.is_escaping = true

			local escape_pos
			local hrp_pos = stuff.rawrbxget(hrp, 'Position')

			if vstorage.damage_source then
				local source_pos

				if vstorage.damage_source.type == 'player' and vstorage.damage_source.source.Character and vstorage.damage_source.source.Character:FindFirstChild('HumanoidRootPart') then
					source_pos = stuff.rawrbxget(vstorage.damage_source.source.Character.HumanoidRootPart, 'Position')
					notify('antideath', `escaping from {vstorage.damage_source.name}`, 1)
				elseif vstorage.damage_source.source and vstorage.damage_source.source:IsA('BasePart') then
					source_pos = stuff.rawrbxget(vstorage.damage_source.source, 'Position')
					notify('antideath', `escaping from {vstorage.damage_source.type}`, 1)
				end

				if source_pos then
					local escape_direction = (hrp_pos - source_pos).Unit
					local escape_distance = vstorage.damage_source.type == 'player' and 70 or 50
					escape_pos = hrp_pos + (escape_direction * escape_distance) + Vector3.new(0, 20, 0)
				else
					escape_pos = vstorage.safe_position.Position + Vector3.new(0, 10, 0)
				end
			else
				if (vstorage.safe_position.Position - hrp_pos).Magnitude > 200 then
					local random_offset = Vector3.new(
						math.random(-80, 80),
						math.random(20, 50),
						math.random(-80, 80)
					)
					escape_pos = hrp_pos + random_offset
					notify('antideath', 'escaping to random position', 1)
				else
					escape_pos = vstorage.safe_position.Position + Vector3.new(0, 15, 0)
					notify('antideath', 'returning to safe position', 1)
				end
			end

			for i = 1, 3 do
				pcall(function()
					stuff.owner_char:PivotTo(CFrame.new(escape_pos))

					for _, part in pairs(stuff.owner_char:GetDescendants()) do
						if part:IsA('BasePart') then
							stuff.rawrbxset(part, 'Velocity', Vector3.zero)
							stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.zero)
							stuff.rawrbxset(part, 'AssemblyAngularVelocity', Vector3.zero)
							stuff.rawrbxset(part, 'RotVelocity', Vector3.zero)
						end
					end
				end)

				if i < 3 then
					task.wait(0.05)
				end
			end

			task.delay(0.8, function()
				vstorage.is_escaping = false
			end)
		end

		maid.add('antideath_health_monitor', humanoid:GetPropertyChangedSignal('Health'), function()
			if not vstorage.enabled then
				maid.remove('antideath_health_monitor')
				maid.remove('antideath_heartbeat')
				return
			end

			pcall(function()
				local current_health = stuff.rawrbxget(humanoid, 'Health')

				if current_health <= 0 then
					maid.remove('antideath_health_monitor')
					maid.remove('antideath_heartbeat')
					return
				end

				if current_health < vstorage.last_health then
					vstorage.last_damage_tick = tick()
					vstorage.damage_source = find_damage_source()

					if current_health <= vstorage.min_health then
						teleport_to_safety()
					end
				end

				vstorage.last_health = current_health
			end)
		end)

		maid.add('antideath_heartbeat', services.run_service.Heartbeat, function()
			if not vstorage.enabled then
				maid.remove('antideath_health_monitor')
				maid.remove('antideath_heartbeat')
				return
			end

			pcall(function()
				local current_health = stuff.rawrbxget(humanoid, 'Health')

				if current_health <= 0 then
					maid.remove('antideath_health_monitor')
					maid.remove('antideath_heartbeat')
					return
				end

				if current_health > vstorage.min_health + 40 and current_health >= vstorage.last_health and not vstorage.is_escaping then
					local hrp = stuff.owner_char:FindFirstChild('HumanoidRootPart')
					if hrp then
						local hrp_pos = stuff.rawrbxget(hrp, 'Position')
						if hrp_pos.Y > workspace.FallenPartsDestroyHeight + 50 then
							vstorage.safe_position = stuff.owner_char:GetPivot()
						end
					end
				end

				if tick() - vstorage.last_damage_tick < 2 and current_health <= vstorage.min_health then
					if not vstorage.is_escaping then
						local health_before = current_health
						task.wait(0.15)

						if stuff.rawrbxget(humanoid, 'Health') < health_before and stuff.rawrbxget(humanoid, 'Health') > 0 then
							vstorage.damage_source = find_damage_source()
							teleport_to_safety()
						end
					end
				end

				if tick() - vstorage.last_damage_tick > 5 then
					vstorage.teleport_count = 0
				end

				if vstorage.teleport_count >= 10 then
					notify('antideath', 'excessive damage - returning to safe spawn', 3)
					vstorage.teleport_count = 0

					local spawn = workspace:FindFirstChild('SpawnLocation') or workspace:FindFirstChildOfClass('SpawnLocation')
					if spawn then
						local spawn_cf = stuff.rawrbxget(spawn, 'CFrame')
						stuff.owner_char:PivotTo(spawn_cf + Vector3.new(0, 5, 0))
					else
						stuff.owner_char:PivotTo(CFrame.new(0, 100, 0))
					end

					for _, part in pairs(stuff.owner_char:GetDescendants()) do
						if part:IsA('BasePart') then
							stuff.rawrbxset(part, 'Velocity', Vector3.zero)
							stuff.rawrbxset(part, 'AssemblyLinearVelocity', Vector3.zero)
							stuff.rawrbxset(part, 'AssemblyAngularVelocity', Vector3.zero)
						end
					end
				end
			end)
		end)
	end

	setup_antideath()

	maid.add('antideath_character_respawn', stuff.owner.CharacterAdded, function(character)
		if not vstorage.enabled then
			maid.remove('antideath_character_respawn')
			return
		end

		task.wait(0.5)

		if vstorage.enabled then
			notify('antideath', 'reactivated after respawn', 1)
			setup_antideath()
		end
	end)
end)

cmd_library.add({'unantideath', 'unantikill', 'stopantideath'}, 'disables anti-death', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('antideath')

	if not vstorage.enabled then
		return notify('antideath', 'anti-death not enabled', 2)
	end

	vstorage.enabled = false
	notify('antideath', 'anti-death disabled', 1)

	maid.remove('antideath_health_monitor')
	maid.remove('antideath_heartbeat')
	maid.remove('antideath_character_respawn')

	if vstorage.bypass then
		hook_lib.destroy_hook('antideath_bypass')
	end
end)

cmd_library.add({'stopdamage', 'stopd'}, 'attempts to cancel the damage to your humanoid on client', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unstopdamage')
		return
	end

	if vstorage.enabled then
		return notify('stopdamage', 'stopdamage already enabled', 2)
	end

	local humanoid = stuff.owner_char:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		return notify('stopdamage', 'your character doesnt have a humanoid', 2)
	end

	vstorage.enabled = true
	vstorage.humanoid = humanoid
	vstorage.health = stuff.rawrbxget(humanoid, 'Health')
	vstorage.max_health = stuff.rawrbxget(humanoid, 'MaxHealth')

	notify('stopdamage', 'damage prevention enabled', 1)

	hook_lib.create_hook('stopdamage', {
		newindex = function(self, key, value)
			if self == vstorage.humanoid or (self:IsA('Humanoid') and self == stuff.owner_char:FindFirstChildOfClass('Humanoid')) then
				if key == 'Health' then
					if value > vstorage.health then
						vstorage.health = value
						return false
					else
						return true
					end
				elseif key == 'MaxHealth' then
					vstorage.max_health = value
					vstorage.health = value
					return false
				end
			end
		end,

		namecall = function(self, ...)
			local args = {...}
			local method = getnamecallmethod()

			if self == vstorage.humanoid or (self:IsA('Humanoid') and self == stuff.owner_char:FindFirstChildOfClass('Humanoid')) then
				if method == 'TakeDamage' then
					return true
				elseif method == 'ChangeState' then
					if args[1] == Enum.HumanoidStateType.Dead then
						return true
					end
				end
			end
		end
	})
end)

cmd_library.add({'unstopdamage', 'unstopd'}, 'disables damage prevention', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('stopdamage')

	if not vstorage or not vstorage.enabled then
		return notify('stopdamage', 'damage prevention not enabled', 2)
	end

	vstorage.enabled = false
	hook_lib.destroy_hook('stopdamage')
	notify('stopdamage', 'damage prevention disabled', 1)
end)

cmd_library.add({'clientgodmode', 'cgodmode', 'cgod', 'god'}, 'sets your health to NaN', {
	{'bypass_mode', 'boolean'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, bypass, et)
	if et and vstorage.enabled then
		cmd_library.execute('unclientgodmode')
		return
	end

	if vstorage.enabled then
		return notify('clientgodmode', 'godmode already enabled', 2)
	end

	local humanoid = stuff.owner_char:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		return notify('clientgodmode', 'your character doesnt have a humanoid', 2)
	end

	vstorage.enabled = true
	vstorage.bypass = bypass
	vstorage.humanoid = humanoid

	notify('clientgodmode', `godmode enabled{bypass and ' (bypass)' or ''}`, 1)

	if bypass then
		local health, maxhealth = humanoid.Health, humanoid.MaxHealth
		hook_lib.create_hook('godmode_bypass', {
			index = function(self, key)
				if self == vstorage.humanoid or (self:IsA('Humanoid') and self:IsDescendantOf(stuff.owner_char)) then
					if key == 'Health' then
						return health
					elseif key == 'MaxHealth' then
						return maxhealth
					end
				end
			end,

			newindex = function(self, key, value)
				if self == vstorage.humanoid or (self:IsA('Humanoid') and self:IsDescendantOf(stuff.owner_char)) then
					if key == 'Health' or key == 'MaxHealth' then
						return false
					end
				end
			end,

			namecall = function(self, ...)
				local method = getnamecallmethod()
				local args = {...}

				if self == vstorage.humanoid or (self:IsA('Humanoid') and self:IsDescendantOf(stuff.owner_char)) then
					if method == 'TakeDamage' then
						return nil
					elseif method == 'ChangeState' then
						if args[1] == Enum.HumanoidStateType.Dead then
							return nil
						end
					elseif method == 'GetPropertyChangedSignal' then
						if args[1] == 'Health' or args[1] == 'MaxHealth' then
							return Instance.new('BindableEvent').Event
						end
					end
				end
			end
		})
	end

	stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
	stuff.rawrbxset(humanoid, 'Health', 0/0)

	maid.add('godmode', humanoid:GetPropertyChangedSignal('Health'), function()
		local current_health = stuff.rawrbxget(humanoid, 'Health')
		local current_max = stuff.rawrbxget(humanoid, 'MaxHealth')

		if current_health == current_health or current_max == current_max then
			stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
			stuff.rawrbxset(humanoid, 'Health', 0/0)
		end
	end)

	maid.add('godmode_hum', humanoid.Died, function()
		local new_char = stuff.owner.CharacterAdded:Wait()
		humanoid = new_char:WaitForChild('Humanoid')
		vstorage.humanoid = humanoid

		if vstorage.enabled then
			stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
			stuff.rawrbxset(humanoid, 'Health', 0/0)

			maid.remove('godmode')
			maid.add('godmode', humanoid:GetPropertyChangedSignal('Health'), function()
				local current_health = stuff.rawrbxget(humanoid, 'Health')
				local current_max = stuff.rawrbxget(humanoid, 'MaxHealth')

				if current_health == current_health or current_max == current_max then
					stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
					stuff.rawrbxset(humanoid, 'Health', 0/0)
				end
			end)
		end
	end)
end)

cmd_library.add({'unclientgodmode', 'uncgodmode', 'uncgod', 'ungod'}, 'disables client godmode', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('clientgodmode')

	if not vstorage.enabled then
		return notify('clientgodmode', 'godmode not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('godmode')
	maid.remove('godmode_hum')

	if vstorage.bypass then
		hook_lib.destroy_hook('godmode_bypass')
	end

	if vstorage.humanoid then
		pcall(function()
			stuff.rawrbxset(vstorage.humanoid, 'MaxHealth', 100)
			stuff.rawrbxset(vstorage.humanoid, 'Health', 100)
		end)
	end

	notify('clientgodmode', 'godmode disabled', 1)
end)

cmd_library.add({'seatbring', 'sbring'}, 'bring a player using a seat tool', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not firetouchinterest then
		return notify('seatbring', 'firetouchinterest not found', 2)
	end

	if not targets or #targets == 0 then
		return notify('seatbring', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		local tool = stuff.owner_char:FindFirstChildOfClass('Tool')

		if not tool then
			notify('seatbring', 'equip a tool and maybe then we\'ll see', 3)
			repeat task.wait() until stuff.owner_char:FindFirstChildOfClass('Tool')
			tool = stuff.owner_char:FindFirstChildOfClass('Tool')
		end

		local seat = tool:FindFirstChildWhichIsA('Seat', true)
		if not seat then
			return notify('seatbring', 'tool does not have a seat', 2)
		end

		notify('seatbring', `bringing {target.Name} to you`, 1)

		local old_pos = stuff.owner_char:GetPivot()
		local start_time = tick()
		local target_char = target.Character
		if not target_char then 
			notify('seatbring', `{target.Name} has no character`, 2)
			continue 
		end

		local target_hrp = stuff.rawrbxget(target_char, 'HumanoidRootPart')
		local target_humanoid = stuff.rawrbxget(target_char, 'Humanoid')
		if not target_hrp or not target_humanoid then 
			notify('seatbring', `{target.Name} has no humanoid or rootpart`, 2)
			continue 
		end

		repeat
			local predicted_pos = predict_position(target, 9)
			if not predicted_pos then break end

			firetouchinterest(seat, target_hrp, 0)
			firetouchinterest(seat, target_hrp, 1)
			stuff.owner_char:PivotTo(predicted_pos * CFrame.new(-4, 0, 3))
			services.run_service.Heartbeat:Wait()

			firetouchinterest(seat, target_hrp, 0)
			firetouchinterest(seat, target_hrp, 1)
			stuff.owner_char:PivotTo(predicted_pos * CFrame.new(4, 0, 3))
			services.run_service.Heartbeat:Wait()
			services.run_service.Heartbeat:Wait()

			local target_sit = stuff.rawrbxget(target_humanoid, 'Sit')
		until tick() - start_time >= 4 or (seat and seat:FindFirstChild('SeatWeld')) or target_sit

		stuff.owner_char:PivotTo(old_pos)
	end
end)


-- preload

task.spawn(function()
	local auto_plugins = config.get('auto_plugins') or {}

	for plugin_name, url in auto_plugins do
		task.spawn(function()
			notify('plugin', `loading '{plugin_name}'...`, 4)
			cmd_library.execute('pluginload', url)
		end)
		task.wait(.1)
	end
end)


-- chat cmds

maid.add('owner_chatted', stuff.owner.Chatted, function(msg)
	if msg:sub(1, #(stuff.chat_prefix)) == stuff.chat_prefix then
		local commands = cmd_library.parse_command(msg:sub(#(stuff.chat_prefix) + 1))

		for _, data in commands do
			cmd_library.execute(data.cmd, unpack(data.args))
		end
	end
end, true)


-- ui

local ui_cmdbox, ui_cmdlist, ui_notifications =
	stuff.ui.opadmin_cmdbox, stuff.ui.opadmin_cmdlist, stuff.ui.opadmin_notifications

local ui_cmdbox_main_container = ui_cmdbox.main_container
local ui_cmdbox_inputbox = ui_cmdbox_main_container.inputbox
local ui_cmdbox_button = ui_cmdbox_main_container.button

local ui_cmdlist_main_container = ui_cmdlist.main_container
local ui_cmdlist_search = ui_cmdlist_main_container.search
local ui_cmdlist_close = ui_cmdlist_main_container.close
local ui_cmdlist_commandlist = ui_cmdlist_main_container.commands
local ui_cmdlist_template = ui_cmdlist_commandlist.template

local ui_notifications_main_container = ui_notifications.main_container
local ui_notifications_template = ui_notifications_main_container:WaitForChild('template')

ui_cmdlist_template.Parent = nil
ui_notifications_template.Parent = nil

local tween_ui = function(element, duration, properties, out)
	services.tween_service:Create(element, TweenInfo.new(duration, Enum.EasingStyle.Sine,
		out and Enum.EasingDirection.Out or Enum.EasingDirection.In), properties):Play()
end

do
	local open = false
	local pos_open = ui_cmdbox_main_container.Position
	local pos_closed = UDim2.new(0.5, 0, 0, -35)

	ui_cmdbox_button.Visible = stuff.is_mobile

	tween_ui(ui_cmdbox_main_container, 0.25, {Position = pos_closed}, false)

	maid.add('open_cmdbox_button', ui_cmdbox_button.MouseButton1Click, function()
		open = not open

		tween_ui(ui_cmdbox_main_container, 0.15, {Position = open and pos_open or pos_closed}, open)
		ui_cmdbox_button.Text = open and 'close' or 'open'

		if open then
			ui_cmdbox_inputbox:CaptureFocus()
		end
	end, true)

	stuff.update_keybind = function()
		maid.add('open_cmdbox_key', services.user_input_service.InputBegan, function(input, game_processed)
			if input.KeyCode == stuff.open_keybind and not game_processed and not open then
				tween_ui(ui_cmdbox_main_container, 0.15, {Position = pos_open}, true)

				open = true
				ui_cmdbox_inputbox:CaptureFocus()

				task.delay(.05, function()
					if ui_cmdbox_inputbox.Text ~= '' then
						repeat
							ui_cmdbox_inputbox.Text = ''
							hwait()
						until ui_cmdbox_inputbox.Text == ''
					end
				end)
			end
		end, true)
	end
	stuff.update_keybind()
	
	maid.add('cmdbox_focuslost', ui_cmdbox_inputbox.FocusLost, function(enter)
		tween_ui(ui_cmdbox_main_container, 0.15, {Position = pos_closed}, false)
		open = false

		if enter then
			local text = ui_cmdbox_inputbox.Text
			local commands = cmd_library.parse_command(text)

			for _, data in commands do
				cmd_library.execute(data.cmd, unpack(data.args))
			end
		end

		ui_cmdbox_inputbox.Text = ''
		ui_cmdbox_button.Text = 'open'
	end, true)

	pcall(protect_gui, ui_cmdbox)
end

do
	maid.add('cmdlist_close', ui_cmdlist_close.MouseButton1Click, function()
		ui_cmdlist.Enabled = false
	end, true)

	maid.add('cmdlist_search', ui_cmdlist_search:GetPropertyChangedSignal('Text'), function()
		local search_text = ui_cmdlist_search.Text:lower()
		ui_cmdlist_commandlist.CanvasPosition = Vector2.zero
		for _, label in pairs(ui_cmdlist_commandlist:GetChildren()) do
			if label:IsA('TextLabel') and label ~= stuff.ui_cmdlist_template then
				if search_text == '' then
					label.Visible = true
				else
					local text = label.Text:lower()

					local names_part = text:match('^%s*(.-)%s*%[') or text:match('^%s*(.-)%s*%-')

					if names_part then
						local found = false
						for name in names_part:gmatch('[^,]+') do
							local trimmed_name = name:gsub('^%s*(.-)%s*$', '%1')
							if trimmed_name:find(search_text, 1, true) then
								found = true
								break
							end
						end
						label.Visible = found
					else
						label.Visible = false
					end
				end
			end
		end
	end, true)

	maid.add('command_search_focus', ui_cmdlist_search.Focused, function()
		ui_cmdlist_search.PlaceholderText = 'type to search...'
	end, true)

	maid.add('command_search_unfocus', ui_cmdlist_search.FocusLost, function()
		if ui_cmdlist_search.Text == '' then
			ui_cmdlist_search.PlaceholderText = 'search commands'
		end
	end, true)

	ui_cmdlist.Enabled = false
	pcall(protect_gui, ui_cmdlist)
	stuff.ui_cmdlist = ui_cmdlist
	stuff.ui_cmdlist_template = ui_cmdlist_template
	stuff.ui_cmdlist_commandlist = ui_cmdlist_commandlist
end

pcall(protect_gui, ui_notifications)
stuff.ui_notifications_template = ui_notifications_template
stuff.ui_notifications_main_container = ui_notifications_main_container

notify('info', 'join the discord .gg/StHSWMjcnk', 4)
notify('info', `opadmin loaded, press [{stuff.open_keybind.Name}] to open the cmdbar`, 1)
