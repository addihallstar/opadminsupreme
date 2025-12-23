export type maid = {
	_tasks: {[string]: {task: any, type: string}},
	_protected: {[string]: {task: any, type: string}},
	_cleaner: RBXScriptConnection?,
	add: (name: string, task_or_signal: any, fn: ((...any) -> any)?, important: number?) -> (),
	remove: (name: string) -> boolean,
	remove_protected: (name: string) -> boolean,
	_cleanup_task: (task_data: {task: any, type: string}?) -> (),
	clean: (keep_protected: boolean?) -> (),
	get: (name: string) -> any?,
	exists: (name: string) -> boolean
}

export type hook = {
	namecall: ((self: any, ...any) -> any)?,
	index: ((self: any, key: any) -> any)?,
	newindex: ((self: any, key: any, value: any) -> (boolean | any)?)?,
	functions: {[(...any) -> any]: (old: (...any) -> any, ...any) -> any}?
}

export type hook_data = {
	hooks: {[string]: any},
	function_hooks: {[(...any) -> any]: (...any) -> any},
	enabled: boolean
}

export type hook_lib = {
	active_hooks: {[string]: hook_data},
	presets: {[string]: (...any) -> hook},
	create_hook: (name: string, hooks: hook) -> hook_data,
	destroy_hook: (name: string) -> (),
	toggle_hook: (name: string, enabled: boolean) -> ()
}

export type notification_data = {
	label: TextLabel,
	created_at: number,
	removing: boolean
}

export type velocity_entry = {
	vel: Vector3,
	time: number
}

export type last_command_data = {
	name: string,
	args: {any}
}

export type stuff = {
	ver: string,
	empty_function: () -> (),
	destroy: (object: any) -> (),
	clone: (object: any) -> any,
	connect: (object: RBXScriptSignal, callback: (...any) -> ()) -> RBXScriptConnection,
	disconnect: ((connection: RBXScriptConnection) -> ())?,
	server_endpoint: BindableFunction?,
	owner: Player,
	owner_char: Model,
	ui: ScreenGui?,
	open_keybind: Enum.KeyCode?,
	chat_prefix: string?,
	sim_range_reset: boolean,
	last_command: last_command_data?,
	rawrbxget: ((object: any, key: any) -> any)?,
	rawrbxset: ((object: any, key: any, value: any) -> ())?,
	default_ws: number,
	default_jp: number,
	is_mobile: boolean,
	is_console: boolean,
	highlights: {[Player]: Highlight},
	target: Model?,
	active_notifications: {notification_data},
	max_notifications: number,
	velocity_history: {[string]: {velocity_entry}},
	ping_samples: {number},
	ui_notifications_template: TextLabel?,
	ui_notifications_main_container: Frame?,
	ui_cmdlist: Frame?,
	ui_cmdlist_template: TextLabel?,
	ui_cmdlist_commandlist: ScrollingFrame?,
	update_keybinds: (() -> ())?,
	frame_times: {number},
	last_frame_time: number,
	avg_fps: number,
	avg_ping: number
}

export type command_argument = {string}

export type command_vararg = {['...']: string}

export type command_arg_definition = command_argument | command_vararg

export type command_data = {
	names: {string},
	description: string,
	args: {command_arg_definition},
	fn: (variable_storage: {[string]: any}, ...any) -> (),
	variable_storage: {[string]: any},
	plugin: string?,
	created_at: number
}

export type command_help = {
	names: {string},
	description: string,
	args: {command_arg_definition},
	plugin: string?
}

export type plugin_input = {
	version: string?,
	author: string?,
	description: string?,
	data: {[string]: any}?
}

export type plugin = {
	name: string,
	version: string,
	author: string,
	description: string,
	commands: {command_help},
	loaded: boolean,
	data: {[string]: any}
}

export type plugin_info = {
	name: string,
	version: string,
	author: string,
	description: string,
	command_count: number,
	loaded: boolean
}

export type parsed_command = {
	cmd: string,
	args: {string}
}

export type command_library = {
	_commands: {command_data},
	_command_map: {[string]: command_data},
	_plugins: {[string]: plugin},
	_on_command_added: ((cmd: command_data) -> ())?,
	_on_command_removed: ((cmd: command_data) -> ())?,
	parse_command: (input: string) -> {parsed_command},
	add: (names: {string}, description: string, args: {command_arg_definition}, fn: (variable_storage: {[string]: any}, ...any) -> ()) -> command_data?,
	register_plugin: (plugin_name: string, plugin_data: plugin_input) -> (plugin?, string?),
	add_plugin_command: (plugin_name: string, names: {string}, description: string, args: {command_arg_definition}, fn: (variable_storage: {[string]: any}, ...any) -> ()) -> (command_data?, string?),
	get_plugins: () -> {plugin_info},
	remove_plugin: (plugin_name: string) -> (boolean, string?),
	find: (name: string) -> command_data?,
	remove: (name: string) -> boolean,
	get_variable_storage: (name: string) -> {[string]: any}?,
	find_similar: (name: string) -> {string},
	execute: (name: string, ...any) -> boolean,
	clear: () -> (),
	help: ((name: string) -> command_help?) & (() -> {command_help})
}

export type bind_data = {
	key: string,
	command: string,
	args: {any}?
}

export type config = {
	file_name: string,
	current_game_id: string,
	default_settings: {[string]: any},
	current_settings: {[string]: any},
	load: () -> boolean,
	save: () -> boolean,
	get: (key: string) -> any?,
	set: (key: string, value: any) -> boolean,
	reset: (key: string?) -> boolean,
	get_game_binds: () -> {[string]: bind_data},
	set_game_binds: (game_binds: {[string]: bind_data}) -> boolean,
	apply: () -> ()
}

export type plugin_api = {
	add_command: (names: {string}, description: string, args: {command_arg_definition}, fn: (vars: {[string]: any}, ...any) -> ()) -> (),
	notify: (log: string, text: string, log_type: number?) -> (),
	get_maid: () -> maid,
	get_stuff: () -> stuff,
	get_cmd_library: () -> command_library,
	get_hook_library: () -> hook_lib,
	config: config
}

local plugin = {
	name = 'drunk',
	version = '1.2',
	author = 'rez',
	description = 'uhh idk yes drunk thing yes',

	init = function(api: plugin_api)
		local stuff = api.get_stuff()
		local maid = api.get_maid()
		local cam = workspace.CurrentCamera
		local lighting = game:GetService('Lighting')
		local run_service = game:GetService('RunService')

		local shared_vars = {
			drunk = false,
			intensity = 1,
			original_fov = 70,
			time = 0,
			stumble_timer = 0,
			stumble_impulse = Vector3.zero,
			blur = nil,
			color = nil,
			double_vision = nil,
			hiccup_timer = 0,
			sway_offset = CFrame.new(),
			blackout_alpha = 0,
			blackout_frame = nil
		}

		local function yo()
			local blur = Instance.new('BlurEffect')
			blur.Name = '_drunk_blur'
			blur.Size = 0
			blur.Parent = lighting
			shared_vars.blur = blur

			local color = Instance.new('ColorCorrectionEffect')
			color.Name = '_drunk_color'
			color.Brightness = 0
			color.Contrast = 0
			color.Saturation = 0
			color.TintColor = Color3.new(1, 1, 1)
			color.Parent = lighting
			shared_vars.color = color

			local ui = stuff.ui
			if ui then
				local blackout = Instance.new('Frame')
				blackout.Name = '_drunk_blackout'
				blackout.Size = UDim2.new(1, 0, 1, 0)
				blackout.Position = UDim2.new(0, 0, 0, 0)
				blackout.BackgroundColor3 = Color3.new(0, 0, 0)
				blackout.BackgroundTransparency = 1
				blackout.BorderSizePixel = 0
				blackout.ZIndex = 999
				blackout.Parent = ui
				shared_vars.blackout_frame = blackout
			end
		end

		local function nah()
			if shared_vars.blur then
				shared_vars.blur:Destroy()
				shared_vars.blur = nil
			end
			if shared_vars.color then
				shared_vars.color:Destroy()
				shared_vars.color = nil
			end
			if shared_vars.blackout_frame then
				shared_vars.blackout_frame:Destroy()
				shared_vars.blackout_frame = nil
			end
		end

		local function yes()
			shared_vars.drunk = true
			shared_vars.original_fov = cam.FieldOfView
			shared_vars.time = 0
			shared_vars.stumble_timer = math.random() * 2 + 1
			shared_vars.hiccup_timer = math.random() * 4 + 2
			shared_vars.blackout_alpha = 0

			yo()

			maid.add('drunk_camera', run_service.RenderStepped, function(dt)
				if not shared_vars.drunk then return end

				shared_vars.time = shared_vars.time + dt
				local t = shared_vars.time
				local intensity = shared_vars.intensity

				local base_sway_x = math.sin(t * 0.3) * 0.015 + math.sin(t * 0.7 + 2.1) * 0.008
				local base_sway_y = math.sin(t * 0.25 + 1.5) * 0.01 + math.cos(t * 0.5) * 0.006
				local base_roll = math.sin(t * 0.2) * 0.02 + math.sin(t * 0.45 + 0.8) * 0.012

				local head_bob_x = math.sin(t * 1.2) * 0.003
				local head_bob_y = math.sin(t * 2.4) * 0.002

				local target_sway = CFrame.Angles(
					(base_sway_x + head_bob_x) * intensity,
					(base_sway_y + head_bob_y) * intensity,
					base_roll * intensity
				)

				shared_vars.sway_offset = shared_vars.sway_offset:Lerp(target_sway, dt * 3)
				cam.CFrame = cam.CFrame * shared_vars.sway_offset

				local fov_pulse = math.sin(t * 0.4) * 2 + math.sin(t * 0.15) * 3
				cam.FieldOfView = shared_vars.original_fov + fov_pulse * intensity

				if shared_vars.blur then
					local blur_base = 3 + math.sin(t * 0.6) * 2 + math.sin(t * 1.1) * 1
					shared_vars.blur.Size = blur_base * intensity
				end

				if shared_vars.color then
					local hue_shift = math.sin(t * 0.3) * 0.03 * intensity
					local sat_shift = math.sin(t * 0.5 + 1) * 0.15 * intensity
					shared_vars.color.TintColor = Color3.new(
						1 + hue_shift,
						1 - hue_shift * 0.3,
						1 - hue_shift * 0.5
					)
					shared_vars.color.Saturation = -0.2 * intensity + sat_shift
					shared_vars.color.Contrast = 0.1 * intensity
					shared_vars.color.Brightness = math.sin(t * 0.8) * 0.02 * intensity
				end

				shared_vars.blackout_alpha = math.lerp(shared_vars.blackout_alpha, 0, dt * 2)
				if shared_vars.blackout_frame then
					shared_vars.blackout_frame.BackgroundTransparency = 1 - shared_vars.blackout_alpha
				end
			end)

			maid.add('drunk_movement', run_service.Heartbeat, function(dt)
				if not shared_vars.drunk then return end

				local char = stuff.owner_char
				if not char then return end

				local hrp = char:FindFirstChild('HumanoidRootPart')
				local hum = char:FindFirstChildOfClass('Humanoid')
				if not hum or not hrp then return end

				local intensity = shared_vars.intensity

				shared_vars.stumble_timer = shared_vars.stumble_timer - dt
				shared_vars.hiccup_timer = shared_vars.hiccup_timer - dt

				if shared_vars.stumble_timer <= 0 then
					shared_vars.stumble_timer = 2 + math.random() * 4

					if hum.MoveDirection.Magnitude > 0.1 then
						local stumble_power = 8 * intensity
						local angle = math.random() * math.pi * 2
						shared_vars.stumble_impulse = Vector3.new(
							math.cos(angle) * stumble_power,
							0,
							math.sin(angle) * stumble_power
						)

						if math.random() < 0.3 * intensity then
							shared_vars.blackout_alpha = 0.3 + math.random() * 0.2 * intensity
						end
					end
				end

				if shared_vars.hiccup_timer <= 0 then
					shared_vars.hiccup_timer = 3 + math.random() * 6

					local hiccup_force = Vector3.new(0, 15 * intensity, 0)
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + hiccup_force

					shared_vars.sway_offset = shared_vars.sway_offset * CFrame.Angles(0.05 * intensity, 0, 0)
				end

				if shared_vars.stumble_impulse.Magnitude > 0.5 then
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + shared_vars.stumble_impulse * dt * 10
					shared_vars.stumble_impulse = shared_vars.stumble_impulse * (1 - dt * 3)
				else
					shared_vars.stumble_impulse = Vector3.zero
				end

				local t = shared_vars.time
				local drift = Vector3.new(
					math.sin(t * 0.4) * 0.5,
					0,
					math.cos(t * 0.35 + 1) * 0.5
				) * intensity

				if hum.MoveDirection.Magnitude > 0.1 then
					hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + drift
				end

				local speed_variance = math.sin(t * 0.6) * 2 * intensity
				hum.WalkSpeed = math.max(stuff.default_ws * 0.7 + speed_variance, stuff.default_ws * 0.5)
			end)

			api.notify('drunk', 'things are getting fuzzy...', 1)
		end

		local function no()
			shared_vars.drunk = false
			maid.remove('drunk_camera')
			maid.remove('drunk_movement')

			cam.FieldOfView = shared_vars.original_fov
			nah()

			local char = stuff.owner_char
			if char then
				local hum = char:FindFirstChildOfClass('Humanoid')
				if hum then
					hum.WalkSpeed = stuff.default_ws
				end
			end

			api.notify('drunk', 'sobered up', 1)
		end

		api.add_command({'drunk'}, 'enable drunk thing', {
			{'intensity', 'number'}
		}, function(vars, intensity)
			shared_vars.intensity = math.clamp(tonumber(intensity) or 1, 0.1, 2)

			if shared_vars.drunk then
				no()
			else
				yes()
			end
		end)

		api.add_command({'sober'}, 'disable drunk thing', {}, function(vars)
			if shared_vars.drunk then
				no()
			end
		end)

		return true
	end
}

return plugin
