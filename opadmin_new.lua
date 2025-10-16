if rawequal(game:IsLoaded(), false) then
	game.Loaded:Wait()
end

setfpscap = setfpscap or function() end
setfps = setfps or function() end
getgenv = getgenv or function() return shared end
fireproximityprompt = fireproximityprompt or function() end
firetouchinterest = firetouchinterest or function() end
setclipboard = setclipboard or function() end
saveinstance = saveinstance or function() end
hookmetamethod = hookmetamethod or function() end
getloadedmodules = getloadedmodules or function() return {} end
decompile = decompile or function() return '' end
getnamecallmethod = getnamecallmethod or function() return '' end
checkcaller = checkcaller or function() return false end
syn = syn or {}
sethiddenproperty = sethiddenproperty or function() end

if getgenv().opadmin_loaded then
	return warn('opadmin is already loaded')
end;getgenv().opadmin_loaded = true


local services = {
	core_gui = game:GetService('CoreGui'),
	debris = game:GetService('Debris'),
	tween_service = game:GetService('TweenService'),
	players = game:GetService('Players'),
	run_service = game:GetService('RunService'),
	starter_player = game:GetService('StarterPlayer'),
	teleport_service = game:GetService('TeleportService'),
	text_chat_service = game:GetService('TextChatService'),
	lighting = game:GetService('Lighting'),
	user_input_service = game:GetService('UserInputService'),
	replicated_storage = game:GetService('ReplicatedStorage'),
	http = game:GetService('HttpService'),
	gui_service = game:GetService('GuiService'),
	virt_user = game:GetService('VirtualUser'),
	marketplace_service = game:GetService('MarketplaceService'),
}

local stuff = {
	empty_function = function() end,

	destroy = game.Destroy,
	clone = game.Clone,
	connect = game.Changed.Connect,
	disconnect = nil,
	owner = services.players.LocalPlayer,
	owner_char = services.players.LocalPlayer.Character or services.players.LocalPlayer.CharacterAdded:Wait(),
	ui = (workspace:FindFirstChild('opadmin_ui') and workspace.opadmin_ui or game:GetObjects('rbxassetid://131430979206692')[1]):Clone(),
	open_keybind = _G.opadmin_open_keybind or Enum.KeyCode.Quote,

	rawrbxget = nil,
	rawrbxset = nil,

	default_ws = nil, default_jp = nil,

	is_mobile = services.user_input_service.TouchEnabled and not services.user_input_service.KeyboardEnabled,

	highlights = {},
	active_notifications = {},
	max_notifications = 10,
	ui_notifications_template = nil,
	ui_notifications_main_container = nil,
	ui_cmdlist = nil,
	ui_cmdlist_template = nil,
	ui_cmdlist_commandlist = nil,

}
if not stuff.ui then
	return warn('opadmin ui failed to load')
end

local get_plrs = function(exclude)
	local plrs = {}
	for _, plr in next, services.players:GetPlayers() do
		if plr ~= exclude then
			table.insert(plrs, plr)
		end
	end
	return plrs
end

local get_plr = function(name)
	if not name then
		return {}
	end

	local lower_name = name:lower()
	local all_plrs = get_plrs()

	if lower_name == '@random' or lower_name == '@rand' or lower_name == '@r' then
		return {all_plrs[math.random(#all_plrs)]}
	elseif lower_name == '@self' or lower_name == '@me' or lower_name == '@s' or lower_name == '@m' then
		return {stuff.owner}
	elseif lower_name == '@everyone' or lower_name == '@all' or lower_name == '@e' or lower_name == '@a' then
		return all_plrs		
	elseif lower_name == '@others' or lower_name == '@other' or lower_name == '@o' then
		local others = {}
		for _, plr in next, all_plrs do
			if plr ~= stuff.owner then
				table.insert(others, plr)
			end
		end
		return others
	elseif lower_name == '@view' or lower_name == '@v' then
		return {services.players:GetPlayerFromCharacter(workspace.CurrentCamera.CameraSubject.Parent)}
	end

	lower_name = lower_name:gsub('%s', '')
	for _, plr in next, all_plrs do
		if plr.Name:lower():match(lower_name) or plr.DisplayName:lower():match('^' .. lower_name) then
			return {plr}
		end
	end

	return nil
end

local hwait = function(sig)
	return services.run_service[sig and tostring(sig) or 'Heartbeat']:Wait()
end

local protect_gui = function(gui)
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	elseif services.core_gui:FindFirstChild('RobloxGui') then
		stuff.rawrbxset(gui, 'Parent', services.core_gui.RobloxGui)
	else
		stuff.rawrbxset(gui, 'Parent', services.core_gui)
	end
end

local hypernull;hypernull = function(fn, ...)
	if(coroutine.status(task.spawn(hypernull,fn,...)) == 'dead')then return end
	fn(...)
end

local predict_movement = function(player, future)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild('HumanoidRootPart')
	local humanoid = char:FindFirstChild('Humanoid')
	if not (hrp and humanoid) then return end

	local move_dir = humanoid.MoveDirection
	if move_dir == Vector3.zero then
		return hrp.CFrame
	end

	return hrp.CFrame + move_dir * future
end

local network_check = function(part)
	return part.ReceiveAge == 0
end

local get_closest_part = function()
	local best_part, smallest_mag
	local head_pos = stuff.owner_char.Head.Position

	for _, v in pairs(workspace:GetDescendants()) do
		if v:IsA('BasePart') and not v.Anchored and #v:GetConnectedParts() < 2 then
			if not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') and not v:IsDescendantOf(stuff.owner_char) then
				local mag = (head_pos - v.Position).Magnitude
				if not smallest_mag or mag < smallest_mag then
					smallest_mag, best_part = mag, v
				end
			end
		end
	end

	return best_part
end

local get_closest_player = function(fov)
	local mouse = stuff.owner:GetMouse()
	local closest_player, closest_distance = nil, fov

	for _, plr in pairs(get_plrs()) do
		if plr ~= stuff.owner and plr.Character and plr.Character:FindFirstChild('Head') then
			local head = plr.Character.Head
			local screen_pos, on_screen = workspace.CurrentCamera:WorldToScreenPoint(head.Position)

			if on_screen then
				local mouse_distance = (Vector2.new(mouse.X, mouse.Y) - Vector2.new(screen_pos.X, screen_pos.Y)).Magnitude

				if mouse_distance < closest_distance then
					closest_distance = mouse_distance
					closest_player = plr
				end
			end
		end
	end

	return closest_player
end

local remove_notification = function(notification_data)
	if notification_data.removing then
		return
	end
	notification_data.removing = true

	for i, notif in ipairs(stuff.active_notifications) do
		if notif == notification_data then
			table.remove(stuff.active_notifications, i)
			break
		end
	end

	local tween_info = TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tween = services.tween_service:Create(notification_data.label, tween_info, {
		BackgroundTransparency = 1,
		TextTransparency = 1
	})

	tween:Play()
	tween.Completed:Connect(function()
		notification_data.label:Destroy()
	end)
end

local notify = function(log, text, log_type)
	if #stuff.active_notifications >= stuff.max_notifications then
		remove_notification(stuff.active_notifications[1])
	end

	local text_label = stuff.ui_notifications_template:Clone()
	local tween_info = TweenInfo.new(.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	text_label.Parent = stuff.ui_notifications_main_container
	text_label.Visible = true
	text_label.TextColor3 =
		log_type == 1 and text_label.TextColor3 or
		log_type == 2 and Color3.fromRGB(227, 112, 144) or
		log_type == 3 and Color3.fromRGB(227, 212, 144) or
		log_type == 4 and Color3.fromRGB(127, 212, 244) or
		text_label.TextColor3

	text_label.Text = ` [{tostring(log) or '?'}] {text} `
	text_label.BackgroundTransparency = 1
	text_label.TextTransparency = 1

	services.tween_service:Create(text_label, tween_info, {
		BackgroundTransparency = .1,
		TextTransparency = 0
	}):Play()

	local notification_data = {
		label = text_label,
		created_at = tick(),
		timer = nil,
		removing = false
	}

	table.insert(stuff.active_notifications, notification_data)

	task.delay(4, function()
		remove_notification(notification_data)
	end)
end

local str_to_type = function(str, t)
	if not t then
		return str
	end

	if t == 'number' then
		return tonumber(str)
	elseif t == 'boolean' or t == 'bool' then
		local lower = str:lower()
		if lower == 'true' or lower == '1' or lower == 'yes' or lower == 'on' then
			return true
		elseif lower == 'false' or lower == '0' or lower == 'no' or lower == 'off' then
			return false
		end
		return nil
	elseif t == 'string' then
		return tostring(str)
	elseif t == 'player' then
		return get_plr(str)
	elseif t == 'vector3' or t == 'vec3' then
		local parts = {}
		for num in str:gmatch('[^,]+') do
			local n = tonumber(num:match('^%s*(.-)%s*$'))
			if n then
				table.insert(parts, n)
			end
		end
		if #parts == 3 then
			return Vector3.new(parts[1], parts[2], parts[3])
		end
		return nil
	elseif t == 'color3' or t == 'color' then
		if str == 'team' then
			return 'team'
		end

		local hex = str:match('^#?(%x+)$')
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
		for num in str:gmatch('[^,]+') do
			local n = tonumber(num:match('^%s*(.-)%s*$'))
			if n then
				table.insert(parts, n)
			end
		end
		if #parts == 3 then
			if parts[1] <= 1 and parts[2] <= 1 and parts[3] <= 1 then
				return Color3.new(parts[1], parts[2], parts[3])
			else
				return Color3.fromRGB(parts[1], parts[2], parts[3])
			end
		end

		return nil
	elseif t == 'cframe' then
		local parts = {}
		for num in str:gmatch('[^,]+') do
			local n = tonumber(num:match('^%s*(.-)%s*$'))
			if n then
				table.insert(parts, n)
			end
		end
		if #parts >= 3 then
			return CFrame.new(parts[1], parts[2], parts[3])
		end
		return nil
	elseif t == 'table' or t == 'array' then
		local result = {}
		for item in str:gmatch('[^,]+') do
			table.insert(result, item:match('^%s*(.-)%s*$'))
		end
		return result
	end

	notify('args', `invalid type '{t}' for string '{str}' - replacing with nil`, 2)
	return nil
end

local get_move_vector = function(speed)
	speed = speed or 1

	if stuff.is_mobile then
		local control_module = require(stuff.owner.PlayerScripts:WaitForChild('PlayerModule'):WaitForChild('ControlModule'))
		local direction = control_module:GetMoveVector()
		return Vector3.new(
			direction.X * speed,
			direction.Y * speed,
			direction.Z * speed
		)
	else
		if services.user_input_service:GetFocusedTextBox() ~= nil then 
			return Vector3.zero 
		end

		local direction = Vector3.new(0, 0, 0)
		if services.user_input_service:IsKeyDown(Enum.KeyCode.W) then
			direction += Vector3.new(0, 0, -1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.A) then
			direction += Vector3.new(-1, 0, 0)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.S) then
			direction += Vector3.new(0, 0, 1)
		end
		if services.user_input_service:IsKeyDown(Enum.KeyCode.D) then
			direction += Vector3.new(1, 0, 0)
		end

		return Vector3.new(
			direction.X * speed,
			direction.Y * speed,
			direction.Z * speed
		)
	end
end

local maid;maid = {
	_tasks = {},
	_protected = {},
	_cleaner = nil,

	add = function(name, task_or_signal, fn, important)
		if maid._tasks[name] then
			maid.remove(name)
		end

		local task
		local task_type

		if typeof(task_or_signal) == 'RBXScriptSignal' and fn then
			task = stuff.connect(task_or_signal, fn)
			task_type = 'connection'
		elseif typeof(task_or_signal) == 'RBXScriptConnection' then
			task = task_or_signal
			task_type = 'connection'
		elseif typeof(task_or_signal) == 'Instance' then
			task = task_or_signal
			task_type = 'instance'
		elseif typeof(task_or_signal) == 'thread' then
			task = task_or_signal
			task_type = 'thread'
		else
			warn(`[maid] unknown task type: {typeof(task_or_signal)}`)
			return
		end

		if important == 1 then
			maid._protected[name] = {task = task, type = task_type}
		else
			maid._tasks[name] = {task = task, type = task_type}
		end
	end,

	remove = function(name)
		local task_data = maid._tasks[name]

		if task_data then
			maid._cleanup_task(task_data)
			maid._tasks[name] = nil
			return true
		end

		return false
	end,

	remove_protected = function(name)
		local task_data = maid._protected[name]

		if task_data then
			maid._cleanup_task(task_data)
			maid._protected[name] = nil
			return true
		end

		return false
	end,

	_cleanup_task = function(task_data)
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
			end
		end)
	end,

	clean = function(keep_protected)
		for name, task_data in pairs(maid._tasks) do
			maid._cleanup_task(task_data)
		end

		table.clear(maid._tasks)
		maid._tasks = {}

		if not keep_protected then
			for name, task_data in pairs(maid._protected) do
				maid._cleanup_task(task_data)
			end
			table.clear(maid._protected)
			maid._protected = {}
		end
	end,

	get = function(name)
		local task_data = maid._tasks[name] or maid._protected[name]
		return task_data and task_data.task or nil
	end
}

do
	local con = stuff.connect(game.Changed, stuff.empty_function)
	stuff.disconnect = con.Disconnect
	pcall(stuff.disconnect, con)

	xpcall(function() return game[''] end, function() stuff.rawrbxget = debug.info(2, 'f') end)
	xpcall(function() game[''] = nil end, function() stuff.rawrbxset = debug.info(2, 'f') end)

	stuff.default_ws = stuff.owner_char:WaitForChild('Humanoid').WalkSpeed or services.starter_player.CharacterWalkSpeed
	pcall(function()
		stuff.default_jp = stuff.owner_char:WaitForChild('Humanoid').JumpPower or services.starter_player.CharacterJumpPower
	end)

	maid._cleaner = stuff.connect(services.run_service.Heartbeat, function()
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
	end, true)

	maid.add('clean_highlights', services.run_service.Stepped, function()
		for _, plr in pairs(get_plrs()) do
			local highlight = stuff.highlights[plr]
			if highlight and not (highlight.Adornee and highlight.Adornee:IsDescendantOf(workspace)) then
				pcall(stuff.destroy, highlight)
				stuff.highlights[plr] = nil
			end
		end
	end, true)
end

local cmd_library;cmd_library = {
	_commands = {},
	_command_map = {},

	add = function(names, description, args, fn)
		local cmd_data = {
			names = names,
			description = description,
			args = args,
			fn = fn,
			variable_storage = {}
		}

		if cmd_library._command_map[names[1]:lower()] then
			warn(`command '{names[1]}' already exists`)
		end

		table.insert(cmd_library._commands, cmd_data)

		for _, name in ipairs(names) do
			cmd_library._command_map[name:lower()] = cmd_data
		end

		return cmd_data
	end,

	find = function(name)
		return cmd_library._command_map[name:lower()]
	end,

	remove = function(name)
		local cmd_data = cmd_library._command_map[name:lower()]
		if not cmd_data then
			return false
		end

		for _, cmd_name in ipairs(cmd_data.names) do
			cmd_library._command_map[cmd_name:lower()] = nil
		end

		for i, cmd in ipairs(cmd_library._commands) do
			if cmd == cmd_data then
				table.remove(cmd_library._commands, i)
				break
			end
		end

		return true
	end,

	get_variable_storage = function(name)
		local cmd_data = cmd_library._command_map[name:lower()]
		return cmd_data and cmd_data.variable_storage
	end,

	find_similar = function(name)
		local similar = {}
		local search = name:lower()

		for cmd_name in pairs(cmd_library._command_map) do
			if cmd_name:sub(1, #search) == search then
				table.insert(similar, cmd_name)
			end
		end

		return similar
	end,

	execute = function(name, ...) 
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

		for i, arg_def in ipairs(cmd_data.args) do
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
	end,

	clear = function()
		cmd_library._commands = {}
		cmd_library._command_map = {}
	end,

	help = function(name)
		if name then
			local cmd_data = cmd_library._command_map[name:lower()]
			if cmd_data then
				return {
					names = cmd_data.names,
					description = cmd_data.description,
					args = cmd_data.args
				}
			end
		else
			local help_list = {}
			for _, cmd in ipairs(cmd_library._commands) do
				table.insert(help_list, {
					names = cmd.names,
					description = cmd.description,
					args = cmd.args
				})
			end
			return help_list
		end
	end
}

-- c1: movement
cmd_library.add({'speed', 'walkspeed', 'ws'}, 'sets your walkspeed to [speed]', {
	{'speed', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, speed, bypass)
	notify('walkspeed', speed and `walkspeed set to {speed}` or `walkspeed set to default ({stuff.default_ws})`, 1)

	if bypass then
		hypernull(stuff.rawrbxset, stuff.owner_char:WaitForChild('Humanoid'), 'WalkSpeed', speed or stuff.default_ws)
	else
		stuff.rawrbxset(stuff.owner_char:WaitForChild('Humanoid'), 'WalkSpeed', speed or stuff.default_ws)
	end
end)

cmd_library.add({'jumppower', 'jp'}, 'sets your jumppower to [power]', {
	{'power', 'number'},
	{'bypass_mode', 'boolean'}
}, function(vstorage, power, bypass)
	notify('jumppower', power and `jumppower set to {power}` or `jumppower set to default ({stuff.default_jp})`, 1)

	local humanoid = stuff.owner_char:WaitForChild('Humanoid')
	if bypass then
		hypernull(stuff.rawrbxset, humanoid, 'UseJumpPower', true)
		hypernull(stuff.rawrbxset, humanoid, 'JumpPower', power or stuff.default_jp)
	else
		stuff.rawrbxset(humanoid, 'UseJumpPower', true)
		stuff.rawrbxset(humanoid, 'JumpPower', power or stuff.default_jp)
	end
end)

cmd_library.add({'loopjumppower', 'loopjp'}, 'sets your jumppower to [power] in a loop', {
	{'power', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, power, et)

	if et and vstorage.enabled then
		cmd_library.execute('unloopjp')
		return
	end

	notify('loopjumppower', power and `looping jumppower set to {power}` or `looping jumppower set to default ({stuff.default_jp})`, 1)

	vstorage.enabled = true
	vstorage.old_power = stuff.rawrbxget(stuff.owner_char.Humanoid, 'JumpPower')

	maid.add('loopjp', services.run_service.Heartbeat, function()
		local hum = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		pcall(stuff.rawrbxset, hum, 'UseJumpPower', true)
		pcall(stuff.rawrbxset, hum, 'JumpPower', power or stuff.default_jp)
	end)
end)

cmd_library.add({'unloopjumppower', 'unloopjp'}, 'disables loopjumppower', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopjumppower')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopjp')
		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'JumpPower', vstorage.old_power or stuff.default_jp)
		notify('loopjumppower', 'loop jumppower disabled', 1)
	else
		notify('loopjumppower', 'loop jumppower is already disabled', 2)
	end
end)

cmd_library.add({'loopwalkspeed', 'loopws'}, 'sets your walkspeed to [speed] in a loop', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)

	if et and vstorage.enabled then
		cmd_library.execute('unloopws')
		return
	end

	notify('loopwalkspeed', speed and `looping walkspeed set to {speed}` or `looping walkspeed set to default ({stuff.default_ws})`, 1)

	vstorage.enabled = true
	vstorage.old_speed = stuff.rawrbxget(stuff.owner_char.Humanoid, 'WalkSpeed')

	maid.add('loopws', services.run_service.Heartbeat, function()
		pcall(stuff.rawrbxset, stuff.rawrbxget(stuff.owner_char, 'Humanoid'), 'WalkSpeed', speed or stuff.default_ws)
	end)
end)

cmd_library.add({'unloopwalkspeed', 'unloopws'}, 'disables loopwalkspeed', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('loopwalkspeed')

	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('loopws')
		pcall(stuff.rawrbxset, stuff.owner_char.Humanoid, 'WalkSpeed', vstorage.old_speed or stuff.default_ws)
		notify('loopwalkspeed', 'loop walkspeed disabled', 1)
	else
		notify('loopwalkspeed', 'loop walkspeed is already disabled', 2)
	end
end)

cmd_library.add({'fly', 'cframefly'}, 'enable flight', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
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

		if vstorage.part then
			pcall(stuff.destroy, vstorage.part)
			vstorage.part = nil
		end

		notify('fly', 'disabled flight', 1)
	else
		notify('fly', 'flight is already disabled', 2)
	end
end)

cmd_library.add({'bfly', 'bypassfly'}, 'bypass flight', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unbypassfly')
		return
	end

	local fly_vstorage = cmd_library.get_variable_storage('fly')
	if fly_vstorage.enabled then
		return notify('bfly', 'disable normal fly first', 2)
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('bfly', 'bypass flight already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 1
	notify('bfly', 'bypass flight enabled, when you disable bfly you will teleport to the part', 1)

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

cmd_library.add({'unbfly', 'disablebfly', 'stopbfly'}, 'disable bypass flight', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('bfly')

	if not vstorage.enabled then
		return notify('bfly', 'bypass flight is already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('bypassfly_connection')

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

cmd_library.add({'airwalk', 'airw', 'float'}, 'turns on airwalk', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unairwalk')
		return
	end

	if vstorage.enabled then
		return notify('airwalk', 'airwalk already enabled', 2)
	end

	vstorage.enabled = true
	notify('airwalk', 'enabled airwalk', 1)

	local air_walk_part = Instance.new('Part', workspace)
	stuff.rawrbxset(air_walk_part, 'Size', Vector3.new(7, 2, 3))
	stuff.rawrbxset(air_walk_part, 'Transparency', 1)
	stuff.rawrbxset(air_walk_part, 'Anchored', true)
	stuff.rawrbxset(air_walk_part, 'CanCollide', true)
	stuff.rawrbxset(air_walk_part, 'Name', tostring(services.http:GenerateGUID()))
	vstorage.air_walk_part = air_walk_part

	maid.add('air_walk', services.run_service.Heartbeat, function()
		if vstorage.enabled and air_walk_part and stuff.rawrbxget(air_walk_part, 'Parent') then
			pcall(function()
				local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
				local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
				stuff.rawrbxset(air_walk_part, 'CFrame', hrp_cf + Vector3.new(0, -4, 0))
			end)
		else
			maid.remove('air_walk')
			pcall(stuff.destroy, air_walk_part)
			vstorage.air_walk_part = nil
			vstorage.enabled = false
		end
	end)
end)

cmd_library.add({'unairwalk', 'unairw', 'unfloat'}, 'turns off airwalk', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('airwalk')

	if vstorage.air_walk_part then
		vstorage.enabled = false
		maid.remove('air_walk')

		pcall(stuff.destroy, vstorage.air_walk_part)
		vstorage.air_walk_part = nil

		notify('airwalk', 'disabled airwalk', 1)
	else
		notify('airwalk', 'airwalk is already disabled', 2)
	end
end)

cmd_library.add({'to', 'goto'}, 'teleport infront of the target', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('goto', 'player not found', 2)
	end

	for _, target in pairs(targets) do
		local target_char = target.Character
		if not target_char or not target_char:FindFirstChild('HumanoidRootPart') then
			notify('goto', `player {target.Name} does not have a rootpart | skipping`, 3)
			continue
		end

		hypernull(function()
			local target_hrp = stuff.rawrbxget(target_char, 'HumanoidRootPart')
			local target_cf = stuff.rawrbxget(target_hrp, 'CFrame')
			stuff.owner_char:PivotTo(target_cf * CFrame.new(0, 3, -3))
		end)

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

		task.delay(0, function()
			cooldown = false
		end)

		if stuff.rawrbxget(hum, 'FloorMaterial') == Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
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
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('uncframespeed')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('cframespeed', 'cframe speed already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 2
	notify('cframespeed', `cframe speed enabled with speed {vstorage.speed}`, 1)

	pcall(function()
		maid.remove('cframe_speed')
	end)

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
	notify('cframespeed', 'cframe speed disabled', 1)
end)

cmd_library.add({'bypasscframespeed', 'bypasscfspeed', 'bypasscfws', 'bcframespeed', 'bcfspeed', 'bcfws'}, 'speeds you up without changing the walkspeed (bypass)', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unbypasscframespeed')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('bypasscframespeed', 'bypass cframe speed already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 2
	notify('bypasscframespeed', `bypass cframe speed enabled with speed {vstorage.speed}`, 1)

	pcall(function()
		maid.remove('bypass_cframe_speed')
	end)

	maid.add('bypass_cframe_speed', services.run_service.Heartbeat, function()
		pcall(function()
			local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
			local move_direction = stuff.rawrbxget(humanoid, 'MoveDirection')

			if move_direction.Magnitude > 0 then
				hypernull(function()
					local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
					local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
					stuff.rawrbxset(hrp, 'CFrame', hrp_cf + move_direction * vstorage.speed)
				end)
			end
		end)
	end)
end)

cmd_library.add({'unbypasscframespeed', 'unbypasscfspeed', 'unbypasscfws', 'unbcframespeed', 'unbcfspeed', 'unbcfws'}, 'stop bypass cframe speed', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('bypasscframespeed')

	if not vstorage.enabled then
		return notify('bypasscframespeed', 'bypass cframe speed already disabled', 2)
	end

	vstorage.enabled = false
	maid.remove('bypass_cframe_speed')
	notify('bypasscframespeed', 'bypass cframe speed disabled', 1)
end)

-- c2: utility

cmd_library.add({'netless', 'net'}, 'makes scripts more stable', {}, function(vstorage)
	if vstorage.enabled then
		return notify('netless', 'netless already enabled', 2)
	end
	
	vstorage.enabled = true
	for _, v in stuff.owner_char:GetDescendants() do
		if v:IsA('BasePart') and v.Name ~= 'HumanoidRootPart' then
			local name = v.Name
			maid.add(name..'_netless', services.run_service.Heartbeat, function()
				if not vstorage.enabled then 
					return maid.remove(name..'_netless')
				end
				
				stuff.rawrbxset(v, 'Velocity', Vector3.new(-30, 0, 0))
			end)
		end
	end
end)

cmd_library.add({'unnetless', 'unnet'}, 'disables netless', {}, function()
	local vstorage = cmd_library.get_variable_storage('netless')
	if not vstorage.enabled then
		return notify('netless', 'netless already disabled', 2)
	end
	vstorage.enabled = false
end)

cmd_library.add({'tptool', 'tpt'}, 'gives you the tp tool', {}, function()
	notify('tptool', 'giving tptool',1)

	local tptool = Instance.new('Tool')
	tptool.Name = 'tp tool'
	tptool.RequiresHandle = false
	tptool.Activated:Connect(function()
		local pos = stuff.owner:GetMouse().Hit.Position
		pos = pos + Vector3.new(0,1.5,0)
		stuff.owner_char:PivotTo(CFrame.new(pos))
	end)
	tptool.Parent = stuff.owner.Backpack
end)

cmd_library.add({'clicktp', 'ctp'}, 'click to teleport (hold left alt and press lmb to teleport)', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('clicktp', 'click teleport enabled', 1)

		maid.add('clicktp', services.user_input_service.InputBegan, function(input, processed)
			if processed then return end

			if input.UserInputType == Enum.UserInputType.MouseButton1 and services.user_input_service:IsKeyDown(Enum.KeyCode.LeftAlt) then
				local mouse = stuff.owner:GetMouse()
				local target = mouse.Hit

				if target then
					local char = stuff.owner.Character
					local hrp = char and char:FindFirstChild('HumanoidRootPart')

					if hrp then
						stuff.rawrbxset(hrp, 'CFrame', target + Vector3.new(0, 4, 0))
					end
				end
			end
		end)
	else
		notify('clicktp', 'click teleport disabled', 1)
		maid.remove('clicktp')
	end
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
			for _, id in ipairs(source_ids) do
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

				task.wait()
				stuff.rawrbxset(sframe, 'CanvasPosition', Vector2.new(0, sframe.AbsoluteCanvasSize.Y))
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

		for _, cmd_info in ipairs(all_commands) do
			local newframe = stuff.clone(stuff.ui_cmdlist_template)
			newframe.Visible = true
			newframe.Parent = stuff.ui_cmdlist_commandlist
			newframe.TextWrapped = true
			newframe.AutomaticSize = Enum.AutomaticSize.Y

			local names_str = table.concat(cmd_info.names, ', ')

			local args_str = ''
			if cmd_info.args and #cmd_info.args > 0 then
				local arg_parts = {}
				for _, arg_data in ipairs(cmd_info.args) do
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

cmd_library.add({'loadposition', 'loadpos'}, 'load the position saved with savepos', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('savepos')
	if vstorage.pos then
		hypernull(function()
			stuff.owner_char:PivotTo(vstorage.pos)
		end)
		notify('loadpos', 'loaded position', 1)
	else
		notify('loadpos', 'you haven\'t saved a position using saveposition', 2)
	end
end)

cmd_library.add({'illusion', 'deathrespawn', 'drespawn', 'dr'}, 'makes you respawn at the position where you died', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unillusion')
		return
	end
	if vstorage.enabled then
		return notify('deathrespawn', 'death respawn already enabled', 2)
	end

	vstorage.enabled = true
	notify('deathrespawn', 'enabled death respawn', 1)

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
				hypernull(function()
					stuff.owner_char:PivotTo(death_pos)
				end)
				if health > 1 then
					has_died = false
				end
			end
		end)
	end)
end)

cmd_library.add({'unillusion', 'undeathrespawn', 'undrespawn', 'undr'}, 'disable death respawn', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('deathrespawn')

	if not vstorage.enabled then
		return notify('deathrespawn', 'death respawn not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('death_respawn')
	notify('deathrespawn', 'disabled death respawn', 1)
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

	for _, v in ipairs(workspace:GetDescendants()) do
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
				for _, v in ipairs(stuff.owner_char:GetChildren()) do
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

cmd_library.add({'serverhop', 'shop'}, 'hops to a different server', {}, function(vstorage)
	notify('serverhop', 'attempting to server hop', 1)

	local success, result = pcall(function()
		local url = `https://games.roblox.com/v1/games/{game.PlaceId}/servers/Public?sortOrder=Asc&limit=100`
		local response = game:HttpGet(url)
		return services.http:JSONDecode(response)
	end)

	if success and result and result.data then
		for _, server in pairs(result.data) do
			if server.id ~= game.JobId and server.playing < server.maxPlayers then
				services.teleport_service:TeleportToPlaceInstance(game.PlaceId, server.id, stuff.owner)
				return
			end
		end
	end

	notify('serverhop', 'could not find a different server', 2)
end)

cmd_library.add({'thirdp', '3rdp', 'thirdperson'}, 'forces your camera to be third person', {}, function(vstorage)
	notify('thirdperson', 'now third-person', 1)

	stuff.rawrbxset(stuff.owner, 'CameraMaxZoomDistance', 128)
	stuff.rawrbxset(stuff.owner, 'CameraMode', Enum.CameraMode.Classic)
end)

cmd_library.add({'countcommands', 'countcmds'}, 'counts the commands very useful yes', {}, function(vstorage)
	notify('countcommands', `{#cmd_library._commands} commands`, 1)
end)

cmd_library.add({'disabletouchevent', 'disablete'}, 'disables the touched event of all parts using it', {}, function(vstorage)
	if vstorage.enabled then
		return notify('disablete', 'touch event already disabled', 2)
	end

	vstorage.enabled = true
	notify('disablete', 'successfully eradicated touched event', 1)

	pcall(function()
		maid.remove('disable_touch_event')
	end)

	maid.add('disable_touch_event', services.run_service.Heartbeat, function()
		local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
		local health = stuff.rawrbxget(humanoid, 'Health')

		if health < 1 then
			maid.remove('disable_touch_event')
			vstorage.enabled = false
			for _, v in ipairs(workspace:GetDescendants()) do
				pcall(function() stuff.rawrbxset(v, 'CanTouch', true) end)
			end
			return
		end
	end)

	for _, v in ipairs(workspace:GetDescendants()) do
		pcall(function() stuff.rawrbxset(v, 'CanTouch', false) end)
	end
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

cmd_library.add({'hitbox', 'torsosize'}, 'makes rootpart hitbox bigger', {
	{'size', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, size, et)
	if et and vstorage.enabled then
		cmd_library.execute('unhitbox')
		return
	end
	size = size or 10

	if vstorage.enabled then
		return notify('hitbox', 'hitbox already enabled', 2)
	end

	vstorage.enabled = true
	notify('hitbox', `hitbox size set to {size}`, 1)

	pcall(function()
		maid.remove('hitbox_connection')
	end)

	maid.add('hitbox_connection', services.run_service.Heartbeat, function()
		for _, plr in pairs(services.players:GetPlayers()) do
			if plr ~= stuff.owner and plr.Character then
				local head = plr.Character:FindFirstChild('HumanoidRootPart')
				if head then
					stuff.rawrbxset(head, 'Size', Vector3.new(size, size, size))
					stuff.rawrbxset(head, 'Transparency', 0.75)
					stuff.rawrbxset(head, 'BrickColor', BrickColor.random())
					stuff.rawrbxset(head, 'CanCollide', false)
				end
			end
		end
	end)
end)

cmd_library.add({'unhitbox', 'untorsosize'}, 'resets rootpart hitbox', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('hitbox')

	if not vstorage.enabled then
		return notify('hitbox', 'hitbox not enabled', 2)
	end

	vstorage.enabled = false
	notify('hitbox', 'hitbox reset', 1)
	maid.remove('hitbox_connection')

	for _, plr in pairs(services.players:GetPlayers()) do
		if plr.Character and plr ~= stuff.owner then
			local head = plr.Character:FindFirstChild('HumanoidRootPart')
			if head then
				stuff.rawrbxset(head, 'Size', Vector3.new(2, 1, 1))
				stuff.rawrbxset(head, 'Transparency', 1)
			end
		end
	end
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
		services.virt_user:CaptureController()
		services.virt_user:ClickButton2(Vector2.new())
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

cmd_library.add({'stopreplag', 'srl'}, 'sets IncomingReplicationLag to -1', {}, function(vstorage)
	settings():GetService('NetworkSettings').IncomingReplicationLag = -1
	stuff.stopreplag = true 
	notify('stopreplag', 'incoming replication lag set to -1', 1)
end)

cmd_library.add({'freecam', 'fcam'}, 'detach camera from character', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unfreecam')
		return
	end
	if vstorage.enabled and vstorage.speed == speed then
		return notify('freecam', 'freecam already enabled', 2)
	end

	vstorage.enabled = true
	vstorage.speed = speed or 1
	notify('freecam', 'freecam enabled', 1)

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	vstorage.old_subject = stuff.rawrbxget(cam, 'CameraSubject')
	vstorage.old_parent = stuff.rawrbxget(stuff.owner_char, 'Parent')

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	vstorage.old_speed = stuff.rawrbxget(humanoid, 'WalkSpeed')

	local flight_part = Instance.new('Part', workspace)
	vstorage.part = flight_part

	stuff.rawrbxset(humanoid, 'WalkSpeed', 0)
	stuff.rawrbxset(flight_part, 'CFrame', stuff.owner_char:GetPivot())
	stuff.rawrbxset(flight_part, 'Anchored', true)
	stuff.rawrbxset(flight_part, 'Transparency', 1)
	stuff.rawrbxset(flight_part, 'CanCollide', false)
	stuff.rawrbxset(cam, 'CameraSubject', flight_part)
	stuff.rawrbxset(stuff.owner_char, 'Parent', nil)

	maid.add('freecam', services.run_service.Heartbeat, function()
		pcall(function()
			local old_pos = stuff.rawrbxget(flight_part, 'Position')
			local cam_cframe = stuff.rawrbxget(cam, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', CFrame.lookAt(old_pos, cam_cframe * CFrame.new(0, 0, -250).Position))

			local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			stuff.rawrbxset(hrp, 'AssemblyLinearVelocity', Vector3.zero)

			local offset = get_move_vector(vstorage.speed)
			local current_cf = stuff.rawrbxget(flight_part, 'CFrame')
			stuff.rawrbxset(flight_part, 'CFrame', current_cf * CFrame.new(offset))
		end)
	end)
end)

cmd_library.add({'unfreecam', 'unfcam'}, 'reattach camera to character', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('freecam')

	if not vstorage.enabled then
		return notify('freecam', 'freecam not enabled', 2)
	end

	vstorage.enabled = false
	notify('freecam', 'freecam disabled', 1)

	maid.remove('freecam')

	local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
	stuff.rawrbxset(stuff.owner_char, 'Parent', vstorage.old_parent)
	stuff.rawrbxset(cam, 'CameraType', Enum.CameraType.Custom)

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	stuff.rawrbxset(humanoid, 'WalkSpeed', vstorage.old_speed or stuff.default_ws)
	stuff.rawrbxset(cam, 'CameraSubject', vstorage.old_subject or humanoid)

	if vstorage.part then
		pcall(stuff.destroy, vstorage.part)
		vstorage.part = nil
	end
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
		if part:IsA('BasePart') then
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

	print(...)

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

cmd_library.add({'revive'}, 'attempts to stop oneshots', {}, function(vstorage)
	if vstorage.enabled then
		return notify('revive', 'revive already enabled', 2)
	end

	notify('revive', 'activated revive', 1)
	vstorage.enabled = true

	local humanoid = stuff.rawrbxget(stuff.owner_char, 'Humanoid')
	local old_health = stuff.rawrbxget(humanoid, 'Health')

	local invalid_states = {
		[Enum.HumanoidStateType.FallingDown] = true,
		[Enum.HumanoidStateType.Swimming] = true,
		[Enum.HumanoidStateType.Seated] = true,
		[Enum.HumanoidStateType.Jumping] = true,
		[Enum.HumanoidStateType.Freefall] = true
	}

	maid.add('revive_state', services.run_service.Heartbeat, function()
		if not vstorage.enabled then
			maid.remove('revive_state')
			return
		end
		pcall(function()
			if not invalid_states[humanoid:GetState()] then
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
		end)
	end)

	maid.add('revive_health_update', services.run_service.Heartbeat, function()
		if vstorage.enabled then
			local health = stuff.rawrbxget(humanoid, 'Health')
			if health > 0 then
				old_health = health
			end
		end
	end)

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	stuff.rawrbxset(humanoid, 'RequiresNeck', false)
	stuff.rawrbxset(humanoid, 'BreakJointsOnDeath', false)

	maid.add('revive', humanoid:GetPropertyChangedSignal('Health'), function()
		if not vstorage.enabled then
			maid.remove('revive')
			return
		end

		local current_health = stuff.rawrbxget(humanoid, 'Health')
		humanoid:ChangeState(Enum.HumanoidStateType.Running)

		if old_health > current_health then
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
			stuff.rawrbxset(humanoid, 'Parent', services.replicated_storage)
			local stored_humanoid = services.replicated_storage:FindFirstChild('Humanoid')
			if stored_humanoid then
				stuff.rawrbxset(stored_humanoid, 'Parent', stuff.owner_char)
			end
		else
			old_health = current_health
		end
	end)
end)

cmd_library.add({'unrevive'}, 'disables revive', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('revive')

	if not vstorage.enabled then
		return notify('revive', 'revive not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('revive')
	maid.remove('revive_state')
	maid.remove('revive_health_update')
	notify('revive', 'revive disabled', 1)
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

cmd_library.add({'netlag'}, 'glitches netless/reanimation users', {
	{'player', 'player'}
}, function(vstorage, targets)
	if not targets or #targets == 0 then
		return notify('netlag', 'no player specified', 2)
	end

	vstorage.connections = vstorage.connections or {}

	for _, target in ipairs(targets) do
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
		for _, target in ipairs(targets) do
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

	for _, plr in ipairs(players) do
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
			stuff.owner_char:PivotTo(predict_movement(target, 20))
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
				local predicted_cf = predict_movement(target, ((target_ws * 68.75) / 100))
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

cmd_library.add({'carpetfling'}, 'flings player using carpet animation and hip height', {
	{'player', 'player'},
	{'power', 'number'}
}, function(vstorage, targets, power)
	if not targets or #targets == 0 then
		return notify('fling2', 'no player specified', 2)
	end

	power = power or 1000

	for _, target in ipairs(targets) do
		if target == stuff.owner then
			notify('fling2', 'cannot fling yourself', 2)
			continue
		end

		if not target.Character or not target.Character:FindFirstChild('HumanoidRootPart') then
			notify('fling2', `{target.Name} has no character`, 2)
			continue
		end

		local char = stuff.owner.Character
		if not char or not char:FindFirstChild('HumanoidRootPart') or not char:FindFirstChild('Humanoid') then
			return notify('fling2', 'your character is missing parts', 2)
		end

		local hrp = char.HumanoidRootPart
		local humanoid = char.Humanoid
		local old_cf = stuff.rawrbxget(hrp, 'CFrame')
		local old_hip_height = stuff.rawrbxget(humanoid, 'HipHeight')

		local target_torso = target.Character:FindFirstChild('Torso') or 
			target.Character:FindFirstChild('LowerTorso') or 
			target.Character:FindFirstChild('HumanoidRootPart')

		if not target_torso then
			notify('fling2', `{target.Name} has no torso`, 2)
			continue
		end

		local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
		stuff.rawrbxset(workspace.CurrentCamera, 'CameraSubject', target.Character.Humanoid)

		local carpet_anim = Instance.new('Animation')
		stuff.rawrbxset(carpet_anim, 'AnimationId', 'rbxassetid://282574440')
		local carpet_track = humanoid:LoadAnimation(carpet_anim)
		carpet_track:Play(0.1, 1, 1)

		notify('fling2', `flinging {target.Name} with power {power}`, 1)

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

cmd_library.add({'rocket', 'launch'}, 'launches you like a rocket', {
	{'power', 'number'}
}, function(vstorage, power)
	power = power or 100
	notify('rocket', `launching with power {power}`, 1)

	local bv = Instance.new('BodyVelocity')
	stuff.rawrbxset(bv, 'MaxForce', Vector3.new(math.huge, math.huge, math.huge))
	stuff.rawrbxset(bv, 'Velocity', Vector3.new(0, power, 0))

	hypernull(function()
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		stuff.rawrbxset(bv, 'Parent', hrp)
	end)

	services.debris:AddItem(bv, 0.5)
end)

-- c4: character

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

cmd_library.add({'noclip'}, 'walk through stuff', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('clip')
		return
	end
	if vstorage.enabled then
		return notify('noclip', 'noclip already enabled', 2)
	end

	vstorage.enabled = true
	notify('noclip', 'noclip enabled', 1)

	maid.add('noclip_connection', services.run_service.Stepped, function()
		if stuff.owner_char then
			for _, part in pairs(stuff.owner_char:GetDescendants()) do
				if part:IsA('BasePart') then
					stuff.rawrbxset(part, 'CanCollide', false)
				end
			end
		end
	end)
end)

cmd_library.add({'clip'}, 'stop walking through stuff', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('noclip')

	if not vstorage.enabled then
		return notify('noclip', 'noclip is not enabled', 2)
	end

	vstorage.enabled = false
	maid.remove('noclip_connection')
	notify('noclip', 'disabled noclip', 1)

	for _, v in pairs(stuff.owner_char:GetChildren()) do
		if v:IsA('BasePart') then
			stuff.rawrbxset(v, 'CanCollide', true)
		end
	end

	if stuff.owner_char and stuff.owner_char:FindFirstChild('HumanoidRootPart') then
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
		stuff.rawrbxset(hrp, 'CFrame', hrp_cf + Vector3.new(0, 3, 0))
	end
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

cmd_library.add({'spin', 'spinbot'}, 'spins your character', {
	{'speed', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, speed, et)
	if et and vstorage.enabled then
		cmd_library.execute('unspin')
		return
	end

	if vstorage.enabled and vstorage.speed == speed then
		return notify('spin', 'spin is already enabled', 2)
	end

	vstorage.speed = speed or 20
	vstorage.enabled = true
	notify('spin', `spinning at speed {vstorage.speed}`, 1)

	local spin_part = Instance.new('BodyAngularVelocity')
	stuff.rawrbxset(spin_part, 'Name', 'spin_velocity')

	hypernull(function()
		local hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
		stuff.rawrbxset(spin_part, 'Parent', hrp)
	end)

	hypernull(function()
		stuff.rawrbxset(spin_part, 'MaxTorque', Vector3.new(0, math.huge, 0))
		stuff.rawrbxset(spin_part, 'AngularVelocity', Vector3.new(0, vstorage.speed, 0))
	end)

	vstorage.spin_part = spin_part
end)

cmd_library.add({'unspin', 'unspinbot'}, 'stops spinning your character', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('spin')

	if not vstorage.enabled then
		return notify('spin', 'spin is not enabled', 2)
	end

	notify('spin', 'stopped spinning', 1)
	vstorage.enabled = false

	if vstorage.spin_part then
		pcall(stuff.destroy, vstorage.spin_part)
		vstorage.spin_part = nil
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

cmd_library.add({'freegamepass', 'freegp'}, 'makes the client think that you own every gamepass and in the group', {}, function(vstorage)
	vstorage.enabled = not vstorage.enabled

	if vstorage.enabled then
		notify('freegamepass', 'free gamepass enabled', 1)

		vstorage.old_namecall = hookmetamethod(game, '__namecall', function(self, ...)
			local args = {...}
			local method = getnamecallmethod()

			if vstorage.enabled and checkcaller and not checkcaller() then
				if self == game:GetService('MarketplaceService') then
					if method == 'UserOwnsGamePassAsync' then
						return true
					elseif method == 'PlayerOwnsAsset' then
						return true
					elseif method == 'GetProductInfo' then
						local result = vstorage.old_namecall(self, ...)
						if result then
							result.IsOwned = true
						end
						return result
					end
				end

				if method == 'IsInGroup' and self:IsA('Player') then
					return true
				end
			end

			return vstorage.old_namecall(self, ...)
		end)

		vstorage.old_index = hookmetamethod(game, '__index', function(self, key)
			if vstorage.enabled and checkcaller and not checkcaller() then
				if self:IsA('Player') and (key == 'MembershipType' or key == 'Membership') then
					return Enum.MembershipType.Premium
				end
			end

			return vstorage.old_index(self, key)
		end)
	else
		notify('freegamepass', 'free gamepass disabled', 1)
		vstorage.enabled = false
	end
end)

cmd_library.add({'unfreegamepass', 'unfreegp'}, 'disables free gamepass', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('freegamepass')

	if not vstorage or not vstorage.enabled then
		return notify('freegamepass', 'free gamepass not enabled', 2)
	end

	vstorage.enabled = false
	notify('freegamepass', 'free gamepass disabled', 1)
end)

cmd_library.add({'aimbot'}, 'aims at nearest player', {
	{'fov', 'number'},
	{"aimrange","number"},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, fov_size,aim_range, et)
	if et and vstorage.enabled then
		cmd_library.execute('unaimbot')
		return
	end

	if vstorage.enabled then
		return notify('aimbot', 'aimbot already enabled', 2)
	end
	local aimbotenabled = false
	vstorage.enabled = true
	vstorage.fov = fov_size or 200
	vstorage.aimrange = aim_range or 300
	notify('aimbot', `aimbot enabled with fov {vstorage.fov}`..((not stuff.is_mobile and ', press G to enable') or ''), 1)
	if not stuff.is_mobile then
		maid.add("aimbot_g_enable",services.user_input_service.InputBegan,function(r,g)
			if r.KeyCode.Name:upper() == "G" and g == false then
				aimbotenabled = not aimbotenabled
				notify("aimbot",((aimbotenabled and "enabled") or "disabled"),1)
			end
		end)
	end
	maid.add('aimbot', services.run_service.RenderStepped, function()
		local target = get_closest_player(vstorage.fov)

		if target and target.Character and target.Character:FindFirstChild('Head') and (not target.Team or target.Team ~= stuff.owner.Team) and (stuff.owner_char:FindFirstChild('Head').Position-target.Character:FindFirstChild('Head').Position).Magnitude <= vstorage.aimrange then
			if not stuff.is_mobile and aimbotenabled or stuff.is_mobile == true then
				local cam = stuff.rawrbxget(workspace, 'CurrentCamera')
				local cam_cf = stuff.rawrbxget(cam, 'CFrame')
				local target_head = stuff.rawrbxget(target.Character, 'Head')
				local target_pos = stuff.rawrbxget(target_head, 'Position')
				stuff.rawrbxset(cam, 'CFrame', CFrame.new(cam_cf.Position, target_pos))
			end
		end
	end)
end)

cmd_library.add({'unaimbot'}, 'disables aimbot', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('aimbot')

	if not vstorage.enabled then
		return notify('aimbot', 'aimbot not enabled', 2)
	end

	vstorage.enabled = false
	notify('aimbot', 'aimbot disabled', 1)
	maid.remove('aimbot')
	maid.remove('aimbot_g_enable')
end)

cmd_library.add({'silentaim'}, 'silent aim at nearest player', {
	{'fov', 'number'},
	{'wallbang', 'boolean'},
	{'aim_range', 'number'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, fov_size,wallbang,aim_range, et)
	if et and vstorage.enabled then
		cmd_library.execute('unsilentaim')
		return
	end

	if vstorage.enabled then
		return notify('silentaim', 'silent aim already enabled', 2)
	end

	vstorage.aimrange = aim_range or 300
	vstorage.enabled = true
	vstorage.fov = fov_size or 200
	vstorage.wallbang = wallbang or true

	notify('silentaim', `silent aim enabled with fov {vstorage.fov}`, 1)

	local get_target = function()
		local mouse = stuff.owner:GetMouse()
		local mouse_pos = Vector2.new(mouse.X, mouse.Y)
		local cam = stuff.rawrbxget(workspace, 'CurrentCamera')

		local closest_player = nil
		local closest_distance = vstorage.fov

		for _, plr in pairs(services.players:GetPlayers()) do
			if plr ~= stuff.owner and (not plr.Team or plr.Team ~= stuff.owner.Team) and (stuff.owner_char:FindFirstChild('Head').Position-plr.Character:FindFirstChild('Head').Position).Magnitude <= vstorage.aimrange then
				if plr.Character and plr.Character:FindFirstChild('Head') then
					local head = plr.Character.Head
					local head_pos = stuff.rawrbxget(head, 'Position')
					local screen_pos, on_screen = cam:WorldToViewportPoint(head_pos)

					if on_screen and screen_pos.Z > 0 then
						local screen_2d = Vector2.new(screen_pos.X, screen_pos.Y)
						local distance = (mouse_pos - screen_2d).Magnitude

						if distance < closest_distance then
							if vstorage.wallbang then
								closest_distance = distance
								closest_player = plr
							else
								local cam_pos = stuff.rawrbxget(cam, 'CFrame').Position
								local ray = Ray.new(cam_pos, (head_pos - cam_pos).Unit * (head_pos - cam_pos).Magnitude)

								if ray then
									local hit_part = ray.Instance
									if hit_part:IsDescendantOf(plr.Character) then
										closest_distance = distance
										closest_player = plr
									end
								else
									closest_distance = distance
									closest_player = plr
								end
							end
						end
					end
				end
			end
		end

		return closest_player
	end

	if not vstorage.already_used then
		vstorage.already_used = true
		vstorage.old_index = hookmetamethod(game, '__index', function(self, key)
			if vstorage.enabled and checkcaller and not checkcaller() then
				if self:IsA('Mouse') and (key == 'Hit' or key == 'Target') then
					local target = get_target()

					if target and target.Character and target.Character:FindFirstChild('Head') then
						if key == 'Hit' then
							local head = stuff.rawrbxget(target.Character, 'Head')
							return stuff.rawrbxget(head, 'CFrame')
						elseif key == 'Target' then
							return stuff.rawrbxget(target.Character, 'Head')
						end
					end
				end
			end

			return vstorage.old_index(self, key)
		end)
	end 

	--vstorage.old_namecall = hookmetamethod(game, '__namecall', function(self, ...)
	--	local args = {...}
	--	local method = getnamecallmethod()

	--	if vstorage.enabled and checkcaller and not checkcaller() then
	--		local target = get_target()

	--		if target and target.Character and target.Character:FindFirstChild('Head') then
	--			local head = stuff.rawrbxget(target.Character, 'Head')
	--			local head_pos = stuff.rawrbxget(head, 'Position')

	--			if method == 'Raycast' and self == workspace then
	--				if args[1] and typeof(args[1]) == 'Vector3' and args[2] and typeof(args[2]) == 'Vector3' then
	--					args[2] = (head_pos - args[1]).Unit * args[2].Magnitude
	--					return vstorage.old_namecall(self, unpack(args))
	--				end
	--			elseif (method == 'FindPartOnRay' or method == 'FindPartOnRayWithIgnoreList' or method == 'FindPartOnRayWithWhitelist') and self == workspace then
	--				if args[1] and typeof(args[1]) == 'Ray' then
	--					args[1] = Ray.new(args[1].Origin, (head_pos - args[1].Origin).Unit * 999)
	--					return vstorage.old_namecall(self, unpack(args))
	--				end
	--			elseif method == 'ScreenPointToRay' and self:IsA('Camera') then
	--				local cam_cf = stuff.rawrbxget(self, 'CFrame')
	--				return Ray.new(cam_cf.Position, (head_pos - cam_cf.Position).Unit)
	--			elseif method == 'ViewportPointToRay' and self:IsA('Camera') then
	--				local cam_cf = stuff.rawrbxget(self, 'CFrame')
	--				return Ray.new(cam_cf.Position, (head_pos - cam_cf.Position).Unit)
	--			end
	--		end
	--	end

	--	return vstorage.old_namecall(self, ...)
	--end)
end)

cmd_library.add({'clickmouse', 'click'}, 'clicks your mouse', {}, function(vstorage)
	services.virt_user:ClickButton1(Vector2.new(stuff.owner:GetMouse().X,stuff.owner:GetMouse().Y),workspace.CurrentCamera.CFrame)
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
	for _, cmd_name in ipairs(similar) do
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
	for bind_id, bind_data in pairs(bind_vs.binds) do
		if bind_data.key == key:upper() then
			maid.remove(bind_id)
			bind_vs.binds[bind_id] = nil
			removed = true
		end
	end

	if removed then
		notify('unbind', `unbound key {key:upper()}`, 1)
	else
		notify('unbind', `no binds found for key {key:upper()}`, 2)
	end
end)

cmd_library.add({'unsilentaim'}, 'disables silent aim', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('silentaim')

	if not vstorage.enabled then
		return notify('silentaim', 'silent aim not enabled', 2)
	end

	vstorage.enabled = false
	notify('silentaim', 'silent aim disabled', 1)
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
	for _, part in ipairs(workspace:GetDescendants()) do
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
			for _, plr in ipairs(services.players:GetPlayers()) do
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

	for _, part in ipairs(workspace:GetDescendants()) do
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
			stuff.rawrbxset(part, 'CFrame', stuff.rawrbxget(target_hrp, 'CFrame'))
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

		for _, v in ipairs(workspace:GetDescendants()) do
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

cmd_library.add({'partwalkfling', 'pwalkfling', 'partwalkf', 'pwalkf', 'pwf'}, 'partfling on walkfling', {
	{'player', 'player'},
	{'torso_mode', 'boolean'}
}, function(vstorage, targets, torso_mode)
	if not targets or #targets == 0 then
		targets = {stuff.owner}
	end

	notify('partwalkfling', 'fetching all parts, your character will be reset', 1)

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
			for _, plr in ipairs(services.players:GetPlayers()) do
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

		for _, part in ipairs(workspace:GetDescendants()) do
			if part:IsA('BasePart') and is_valid_part(part) then
				table.insert(parts, part)
			end
		end

		local desc_added_conn = workspace.DescendantAdded:Connect(function(part)
			if part:IsA('BasePart') and is_valid_part(part) then
				table.insert(parts, part)
			end
		end)

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

-- c6: visual

cmd_library.add({'esp', 'playeresp', 'toggleesp'}, 'toggles esp', {
	{'color', 'color3'}
}, function(vstorage, color)
	vstorage.enabled = not vstorage.enabled
	vstorage.team = color == 'team'

	if not vstorage.team then
		local parsed = color
		if parsed then
			vstorage.color = parsed
		end
	end

	vstorage.color = vstorage.color or Color3.fromRGB(176, 126, 215)

	if vstorage.enabled then
		notify('esp', 'esp enabled', 1)
	else
		notify('esp', 'esp disabled', 1)

		for _, plr in pairs(services.players:GetPlayers()) do
			if plr.Character then
				local hrp = plr.Character:FindFirstChild('HumanoidRootPart')
				if hrp then
					local esp_gui = hrp:FindFirstChild('BillboardGui')
					if esp_gui then
						pcall(stuff.destroy, esp_gui)
					end
				end

				if stuff.highlights[plr] then
					pcall(stuff.destroy, stuff.highlights[plr])
					stuff.highlights[plr] = nil
				end
			end
		end
	end
end)

maid.add('esp_update', services.run_service.RenderStepped, function()
	local esp_vs = cmd_library.get_variable_storage('esp')
	if not esp_vs.enabled then return end

	for _, plr in pairs(services.players:GetPlayers()) do
		local char = plr.Character
		if plr ~= stuff.owner and char and char:FindFirstChild('HumanoidRootPart') then
			local hrp = char.HumanoidRootPart
			local humanoid = char:FindFirstChildOfClass('Humanoid')

			local esp_billboard = hrp:FindFirstChild('BillboardGui')
			if not esp_billboard then
				esp_billboard = Instance.new('BillboardGui')
				stuff.rawrbxset(esp_billboard, 'Size', UDim2.new(100, 0, 100, 0))
				stuff.rawrbxset(esp_billboard, 'StudsOffset', Vector3.new(0, 0, 0))
				stuff.rawrbxset(esp_billboard, 'AlwaysOnTop', true)
				stuff.rawrbxset(esp_billboard, 'MaxDistance', math.huge)
				stuff.rawrbxset(esp_billboard, 'Parent', hrp)
				stuff.rawrbxset(esp_billboard, 'ClipsDescendants', false)

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
				stuff.rawrbxset(tool_label, 'TextWrapped', true)
				stuff.rawrbxset(tool_label, 'Parent', box_frame)
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

			local color = esp_vs.team and 
				(plr.Team == stuff.owner.Team and Color3.fromRGB(143, 255, 130) or Color3.fromRGB(255, 130, 130)) or 
				esp_vs.color

			stuff.rawrbxset(top, 'BackgroundColor3', color)
			stuff.rawrbxset(bottom, 'BackgroundColor3', color)
			stuff.rawrbxset(left, 'BackgroundColor3', color)
			stuff.rawrbxset(right, 'BackgroundColor3', color)

			stuff.rawrbxset(name_label, 'Text', plr.Name)
			stuff.rawrbxset(name_label, 'TextColor3', color)

			local owner_hrp = stuff.rawrbxget(stuff.owner_char, 'HumanoidRootPart')
			local owner_pos = stuff.rawrbxget(owner_hrp, 'Position')
			local hrp_pos = stuff.rawrbxget(hrp, 'Position')
			local distance = math.floor((owner_pos - hrp_pos).Magnitude)
			stuff.rawrbxset(distance_label, 'Text', `[{distance}m]`)
			stuff.rawrbxset(distance_label, 'TextColor3', Color3.fromRGB(200, 200, 200))

			local tool_names = {}
			for _, tool in pairs(char:GetChildren()) do
				if tool:IsA('Tool') then
					local tool_name = stuff.rawrbxget(tool, 'Name')
					table.insert(tool_names, tool_name)
				end
			end

			local backpack_tools = {}
			local backpack = plr:FindFirstChild('Backpack')
			if backpack then
				for _, tool in pairs(backpack:GetChildren()) do
					if tool:IsA('Tool') then
						local tool_name = stuff.rawrbxget(tool, 'Name')
						table.insert(backpack_tools, tool_name)
					end
				end
			end

			local tool_text = #tool_names > 0 and table.concat(tool_names, '\n') or ''
			if #backpack_tools > 0 and #tool_names == 0 then
				tool_text = table.concat(backpack_tools, '\n')
			end
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

			local highlight = stuff.highlights[plr]
			if not highlight then
				highlight = Instance.new('Highlight')
				stuff.rawrbxset(highlight, 'Adornee', char)
				stuff.rawrbxset(highlight, 'FillColor', color)
				stuff.rawrbxset(highlight, 'FillTransparency', 0.75)
				stuff.rawrbxset(highlight, 'OutlineColor', color)
				stuff.rawrbxset(highlight, 'OutlineTransparency', 0.5)
				stuff.rawrbxset(highlight, 'DepthMode', Enum.HighlightDepthMode.AlwaysOnTop)
				stuff.rawrbxset(highlight, 'Parent', workspace)
				stuff.highlights[plr] = highlight
			else
				stuff.rawrbxset(highlight, 'FillColor', color)
				stuff.rawrbxset(highlight, 'OutlineColor', color)
			end
		end
	end
end, true)

cmd_library.add({'tracers', 'toggletracers'}, 'toggles tracers', {
	{'color', 'color3'}
}, function(vstorage, color)
	vstorage.enabled = not vstorage.enabled
	vstorage.team = color == 'team'

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
		notify('tracers', 'tracers enabled', 1)

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

	for _, plr in pairs(services.players:GetPlayers()) do
		if plr ~= stuff.owner then
			local line = tracers_vs.lines and tracers_vs.lines[plr]
			if not line then
				line = Instance.new('Frame')
				stuff.rawrbxset(line, 'BorderSizePixel', 0)
				stuff.rawrbxset(line, 'ZIndex', 9999)
				stuff.rawrbxset(line, 'Parent', tracers_vs.gui)
				tracers_vs.lines = tracers_vs.lines or {}
				tracers_vs.lines[plr] = line
			end

			seen[plr] = true

			local char = plr.Character
			local hrp = char and char:FindFirstChild('HumanoidRootPart')
			if hrp then
				local hrp_cf = stuff.rawrbxget(hrp, 'CFrame')
				local hrp_size = stuff.rawrbxget(hrp, 'Size')
				local target = (hrp_cf * CFrame.new(0, -hrp_size.Y / 2, 0)).Position
				local vec, on_screen = cam:WorldToViewportPoint(target)

				if on_screen and vec.Z > 0 then
					local color = tracers_vs.team and 
						(plr.Team == stuff.owner.Team and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)) or 
						tracers_vs.color

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
	end

	if tracers_vs.lines then
		for plr, line in pairs(tracers_vs.lines) do
			if not seen[plr] and line then
				stuff.rawrbxset(line, 'Visible', false)
			end
		end
	end
end, true)

cmd_library.add({'fullbright', 'fb'}, 'overrides lighting properties', {}, function(vstorage)
	hypernull(function()
		stuff.rawrbxset(services.lighting, 'Brightness', 10)
		stuff.rawrbxset(services.lighting, 'ClockTime', 14.5)
		stuff.rawrbxset(services.lighting, 'FogEnd', 10000)
		stuff.rawrbxset(services.lighting, 'GlobalShadows', true)
		stuff.rawrbxset(services.lighting, 'OutdoorAmbient', Color3.fromRGB(255, 255, 255))
	end)

	notify('fullbright', 'lighting properties set', 1)
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

cmd_library.add({'fogend', 'fog'}, 'sets fog end distance', {
	{'distance', 'number'}
}, function(vstorage, distance)
	distance = distance or 100000
	notify('fogend', `fog end set to {distance}`, 1)
	stuff.rawrbxset(services.lighting, 'FogEnd', distance)
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

cmd_library.add({'showfov'}, 'shows fov circle', {
	{'fov', 'number'},
	{'color', 'color3'},
	{'enable_toggling', 'boolean', 'hidden'}
}, function(vstorage, fov, color, et)
	fov = fov or 200
	
	if et and vstorage.enabled then
		cmd_library.execute('hidefov')
		return
	end

	if vstorage.enabled and vstorage.fov == fov then
		return notify('showfov', 'fov circle already enabled', 2)
	end

	vstorage.fov = fov

	local fov_circle = vstorage.circle
	if fov_circle then
		stuff.destroy(fov_circle)
		vstorage.circle = nil
	end

	vstorage.enabled = true
	notify('showfov', `fov circle enabled with radius {fov}`, 1)

	local fov_circle = Instance.new('ScreenGui')
	stuff.rawrbxset(fov_circle, 'Name', 'fov_circle')
	stuff.rawrbxset(fov_circle, 'IgnoreGuiInset', true)
	stuff.rawrbxset(fov_circle, 'ResetOnSpawn', false)
	pcall(protect_gui, fov_circle)
	vstorage.circle = fov_circle

	local circle = Instance.new('ImageLabel')
	stuff.rawrbxset(circle, 'Image', 'rbxassetid://10131954007')
	stuff.rawrbxset(circle, 'Size', UDim2.new(0, fov, 0, fov))
	stuff.rawrbxset(circle, 'Position', UDim2.new(0.5, 0, 0.5, 0))
	stuff.rawrbxset(circle, 'BackgroundTransparency', 1)
	stuff.rawrbxset(circle, 'ImageColor3', color and color or Color3.fromRGB(176, 126, 215))
	stuff.rawrbxset(circle, 'ImageTransparency', 0)
	stuff.rawrbxset(circle, 'AnchorPoint', Vector2.new(0.5, 0.5))
	stuff.rawrbxset(circle, 'Parent', fov_circle)
end)

cmd_library.add({'hidefov'}, 'hides fov circle', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('showfov')

	if not vstorage.enabled then
		return notify('showfov', 'fov circle not enabled', 2)
	end

	vstorage.enabled = false
	notify('showfov', 'fov circle disabled', 1)

	local fov_circle = vstorage.circle
	if fov_circle then
		stuff.destroy(fov_circle)
		vstorage.circle = nil
	end
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
	vstorage.health = stuff.rawrbxget(humanoid, 'Health')
	vstorage.max_health = stuff.rawrbxget(humanoid, 'MaxHealth')

	notify('stopdamage', 'damage prevention enabled', 1)

	vstorage.old_newindex = hookmetamethod(game, '__newindex', function(self, key, value)
		if vstorage.enabled and checkcaller and not checkcaller() then
			if self == humanoid or (self:IsA('Humanoid') and self == stuff.owner_char:FindFirstChildOfClass('Humanoid')) then
				if key == 'Health' then
					if value > vstorage.health then
						vstorage.health = value
						return vstorage.old_newindex(self, key, value)
					else
						return
					end
				elseif key == 'MaxHealth' then
					vstorage.max_health = value
					vstorage.health = value
					return vstorage.old_newindex(self, key, value)
				end
			end
		end

		return vstorage.old_newindex(self, key, value)
	end)

	vstorage.old_namecall = hookmetamethod(game, '__namecall', function(self, ...)
		local args = {...}
		local method = getnamecallmethod()

		if vstorage.enabled and checkcaller and not checkcaller() then
			if self == humanoid or (self:IsA('Humanoid') and self == stuff.owner_char:FindFirstChildOfClass('Humanoid')) then
				if method == 'TakeDamage' then
					return
				elseif method == 'ChangeState' then
					if args[1] == Enum.HumanoidStateType.Dead then
						return
					end
				end
			end
		end

		return vstorage.old_namecall(self, ...)
	end)
end)

cmd_library.add({'unstopdamage', 'unstopd'}, 'disables damage prevention', {}, function(vstorage)
	local vstorage = cmd_library.get_variable_storage('stopdamage')

	if not vstorage or not vstorage.enabled then
		return notify('stopdamage', 'damage prevention not enabled', 2)
	end

	vstorage.enabled = false
	notify('stopdamage', 'damage prevention disabled', 1)
end)

cmd_library.add({'clientgodmode', 'cgodmode'}, 'sets your health to NaN', {{'enable_toggling', 'boolean', 'hidden'}}, function(vstorage, et)
	if et and vstorage.enabled then
		cmd_library.execute('unclientgodmode')
		return
	end
	
	if vstorage.enabled then
		return notify('clientgodmode', 'godmode already enabled', 1)
	end
	
	local humanoid = stuff.owner_char:FindFirstChildOfClass('Humanoid')
	if not humanoid then
		notify('clientgodmode', 'your character doesnt have a humanoid', 2)
	end
	
	vstorage.enabled = true
	
	stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
	stuff.rawrbxset(humanoid, 'Health', 0/0)
	maid.add('godmode', humanoid:GetPropertyChangedSignal('Health'), function()
		if stuff.rawrbxget(humanoid, 'Health') ~= 0/0 or stuff.rawrbxget(humanoid, 'MaxHealth') ~= 0/0 then
			stuff.rawrbxset(humanoid, 'MaxHealth', 0/0)
			stuff.rawrbxset(humanoid, 'Health', 0/0)
		end
	end)
	
	notify('clientgodmode', 'godmode enabled', 1)
end)

cmd_library.add({'unclientgodmode', 'uncgodmode'}, 'disables client godmode', {}, function(_)
	local vstorage = cmd_library.get_variable_storage('godmode')
	
	if vstorage.enabled then
		vstorage.enabled = false
		maid.remove('godmode')
	else
		notify('clientgodmode', 'godmode already disabled', 1)
	end
end)

cmd_library.add({'seatbring', 'sbring'}, 'bring a player using a seat tool', {
	{'player', 'player'}
}, function(vstorage, targets)
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
			local predicted_pos = predict_movement(target, 9)
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
local ui_notifications_template = ui_notifications_main_container.template

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

	maid.add('cmdbox_focuslost', ui_cmdbox_inputbox.FocusLost, function(enter)
		tween_ui(ui_cmdbox_main_container, 0.15, {Position = pos_closed}, false)
		open = false

		if enter then
			local text = ui_cmdbox_inputbox.Text
			local args = text:split(' ')
			local cmd = args[1]
			table.remove(args, 1)

			cmd_library.execute(cmd, unpack(args))
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
