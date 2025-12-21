export type maid = {
	_tasks: {[string]: {task: any, type: string}},
	_protected: {[string]: {task: any, type: string}},
	add: (self: maid, name: string?, task: any, important: number?) -> (),
	remove: (self: maid, name: string) -> boolean,
	remove_protected: (self: maid, name: string) -> boolean,
	clean: (self: maid, keep_protected: boolean?) -> (),
	get: (self: maid, name: string) -> any?,
	exists: (self: maid, name: string) -> boolean
}


export type hook = {
	namecall: (self: any, ...any) -> any,
	index: (self: any, key: any) -> any,
	functions: {[any]: (...any) -> any}
}

export type hook_lib = {
	active_hooks: {[string]: {any}},
	presets: {[string]: () -> hook},
	create_hook: (name: string, hooks: {[string]: () -> any}) -> hook,
	destroy_hook: (name: string) -> (),
	toggle_hook: (name: string, enabled: boolean) -> ()
}


export type stuff = {
	ver: string,
	empty_function: () -> (),
	destroy: (object: any) -> (),
	clone: (object: any) -> any,
	connect: (object: any, callback: any) -> any,
	disconnect: (object: any) -> (),
	owner: Player,
	owner_char: Model,
	ui: ScreenGui,
	open_keybind: Enum.KeyCode,
	chat_prefix: string,
	rawrbxget: (object: any, key: any) -> any,
	rawrbxset: (object: any, key: any, value: any) -> (),
	default_ws: number,
	default_jp: number,
	is_mobile: boolean,
	is_console: boolean,
	highlights: {Highlight},
	target: Model?,
	active_notifications: {any},
	max_notifications: number,
	velocity_history: {Vector3},
	ping_samples: {number},
	ui_notifications_template: TextLabel,
	ui_notifications_main_container: Frame,
	ui_cmdlist: Frame?,
	ui_cmdlist_template: TextLabel,
	ui_cmdlist_commandlist: ScrollingFrame,
	update_keybinds: () -> (),
	frame_times: {number},
	last_frame_time: number,
	avg_fps: number,
	avg_ping: number
}


export type command_argument = {
	string
}

export type command_vararg = {
	['...']: string
}

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


export type plugin_api = {
	add_command: (names: {string}, description: string, args: {string}, fn: () -> ()) -> (),
	notify: (text: string, level: number) -> (),
	get_maid: () -> maid,
	get_stuff: () -> stuff,
	get_cmd_library: () -> cmd_lib,
	gey_hook_libraty: () -> hook_lib
}

local plugin = {
	name = 'flips',
	version = '1.0',
	author = 'pro',
	description = 'adds flips to opadmin',

	init = function(api: plugin_api)
		local stuff = api.get_stuff()
		local maid = api.get_maid()

		api.add_command({'backflip', 'bflip'}, 'do a backflip', {
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, speed, flips)
			local character = stuff.owner_char
			if not character then
				return api.notify('no character found', 2)
			end

			local humanoid = character:FindFirstChildOfClass('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not humanoid or not hrp then
				return api.notify('missing humanoid or rootpart', 2)
			end

			if vars.flipping then
				return api.notify('already flipping', 2)
			end

			vars.flipping = true
			speed = speed or 8
			flips = flips or 1

			local total_rotation = 360 * flips
			local rotation_speed = speed * 60
			local duration = total_rotation / rotation_speed

			local original_autorotate = humanoid.AutoRotate
			humanoid.AutoRotate = false

			local start_time = tick()
			local start_cframe = hrp.CFrame
			local rotation_axis = start_cframe.RightVector

			maid.add('backflip_loop', game:GetService('RunService').RenderStepped, function()
				if not vars.flipping then return end

				local elapsed = tick() - start_time
				local progress = math.clamp(elapsed / duration, 0, 1)

				local eased_progress = 1 - math.pow(1 - progress, 2)
				local current_angle = math.rad(total_rotation * eased_progress)

				local new_cframe = start_cframe * CFrame.fromAxisAngle(rotation_axis, -current_angle)
				hrp.CFrame = CFrame.new(hrp.Position) * (new_cframe - new_cframe.Position)

				if progress >= 1 then
					vars.flipping = false
					humanoid.AutoRotate = original_autorotate
					maid.remove('backflip_loop')
					api.notify(`completed {flips} backflip{flips > 1 and 's' or ''}`, 1)
				end
			end)
		end)

		api.add_command({'frontflip', 'fflip'}, 'do a frontflip', {
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, speed, flips)
			local character = stuff.owner_char
			if not character then
				return api.notify('no character found', 2)
			end

			local humanoid = character:FindFirstChildOfClass('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not humanoid or not hrp then
				return api.notify('missing humanoid or rootpart', 2)
			end

			if vars.flipping then
				return api.notify('already flipping', 2)
			end

			vars.flipping = true
			speed = speed or 8
			flips = flips or 1

			local total_rotation = 360 * flips
			local rotation_speed = speed * 60
			local duration = total_rotation / rotation_speed

			local original_autorotate = humanoid.AutoRotate
			humanoid.AutoRotate = false

			local start_time = tick()
			local start_cframe = hrp.CFrame
			local rotation_axis = start_cframe.RightVector

			maid.add('frontflip_loop', game:GetService('RunService').RenderStepped, function()
				if not vars.flipping then return end

				local elapsed = tick() - start_time
				local progress = math.clamp(elapsed / duration, 0, 1)

				local eased_progress = 1 - math.pow(1 - progress, 2)
				local current_angle = math.rad(total_rotation * eased_progress)

				local new_cframe = start_cframe * CFrame.fromAxisAngle(rotation_axis, current_angle)
				hrp.CFrame = CFrame.new(hrp.Position) * (new_cframe - new_cframe.Position)

				if progress >= 1 then
					vars.flipping = false
					humanoid.AutoRotate = original_autorotate
					maid.remove('frontflip_loop')
					api.notify(`completed {flips} frontflip{flips > 1 and 's' or ''}`, 1)
				end
			end)
		end)

		api.add_command({'sideflip', 'sflip'}, 'do a sideflip', {
			{'direction', 'string'},
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, direction, speed, flips)
			local character = stuff.owner_char
			if not character then
				return api.notify('no character found', 2)
			end

			local humanoid = character:FindFirstChildOfClass('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not humanoid or not hrp then
				return api.notify('missing humanoid or rootpart', 2)
			end

			if vars.flipping then
				return api.notify('already flipping', 2)
			end

			vars.flipping = true
			direction = (direction or 'left'):lower()
			speed = speed or 8
			flips = flips or 1

			local total_rotation = 360 * flips
			local rotation_speed = speed * 60
			local duration = total_rotation / rotation_speed

			local original_autorotate = humanoid.AutoRotate
			humanoid.AutoRotate = false

			local start_time = tick()
			local start_cframe = hrp.CFrame
			local rotation_axis = start_cframe.LookVector
			local direction_mult = direction == 'right' and 1 or -1

			maid.add('sideflip_loop', game:GetService('RunService').RenderStepped, function()
				if not vars.flipping then return end

				local elapsed = tick() - start_time
				local progress = math.clamp(elapsed / duration, 0, 1)

				local eased_progress = 1 - math.pow(1 - progress, 2)
				local current_angle = math.rad(total_rotation * eased_progress) * direction_mult

				local new_cframe = start_cframe * CFrame.fromAxisAngle(rotation_axis, current_angle)
				hrp.CFrame = CFrame.new(hrp.Position) * (new_cframe - new_cframe.Position)

				if progress >= 1 then
					vars.flipping = false
					humanoid.AutoRotate = original_autorotate
					maid.remove('sideflip_loop')
					api.notify(`completed {flips} {direction} sideflip{flips > 1 and 's' or ''}`, 1)
				end
			end)
		end)

		api.add_command({'stopflip', 'unflip'}, 'stops current flip', {}, function(vars)
			local backflip_vars = api.get_cmd_library().get_variable_storage('backflip')
			local frontflip_vars = api.get_cmd_library().get_variable_storage('frontflip')
			local sideflip_vars = api.get_cmd_library().get_variable_storage('sideflip')

			local stopped = false

			if backflip_vars and backflip_vars.flipping then
				backflip_vars.flipping = false
				maid.remove('backflip_loop')
				stopped = true
			end

			if frontflip_vars and frontflip_vars.flipping then
				frontflip_vars.flipping = false
				maid.remove('frontflip_loop')
				stopped = true
			end

			if sideflip_vars and sideflip_vars.flipping then
				sideflip_vars.flipping = false
				maid.remove('sideflip_loop')
				stopped = true
			end

			if stopped then
				local character = stuff.owner_char
				if character then
					local humanoid = character:FindFirstChildOfClass('Humanoid')
					if humanoid then
						humanoid.AutoRotate = true
					end
				end
				api.notify('flip stopped', 1)
			else
				api.notify('not flipping', 2)
			end
		end)

		return true
	end
}

return plugin
