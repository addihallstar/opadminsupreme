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
	name = 'flips',
	version = '1.1',
	author = 'pro',
	description = 'adds flips to opadmin',

	init = function(api: plugin_api)
		local stuff = api.get_stuff()

		local shared_vars = {
			flipping = false
		}

		local h = 0.0174533

		local function do_flip(direction: string)
			local character = stuff.owner_char
			if not character then
				return api.notify('flip', 'no character found', 2)
			end

			local humanoid = character:FindFirstChildOfClass('Humanoid')
			local hrp = character:FindFirstChild('HumanoidRootPart')
			if not humanoid or not hrp then
				return api.notify('flip', 'missing humanoid or rootpart', 2)
			end

			if shared_vars.flipping then
				return api.notify('flip', 'already flipping', 2)
			end

			shared_vars.flipping = true
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait()
			humanoid.Sit = true
			local angle_x, angle_z = 0, 0

			if direction == 'back' then
				angle_x = h
			elseif direction == 'front' then
				angle_x = -h
			elseif direction == 'left' then
				angle_z = -h
			elseif direction == 'right' then
				angle_z = h
			end

			for i = 1, 360 do
				task.delay(i / 720, function()
					if not shared_vars.flipping then return end

					local char = stuff.owner_char
					if not char then
						shared_vars.flipping = false
						return
					end

					local hum = char:FindFirstChildOfClass('Humanoid')
					local root = char:FindFirstChild('HumanoidRootPart')
					if not hum or not root then
						shared_vars.flipping = false
						return
					end

					hum.Sit = true
					root.CFrame = root.CFrame * CFrame.Angles(angle_x, 0, angle_z)
				end)
			end

			task.delay(0.55, function()
				shared_vars.flipping = false

				local char = stuff.owner_char
				if char then
					local hum = char:FindFirstChildOfClass('Humanoid')
					if hum then
						hum.Sit = false
					end
				end
			end)
		end

		api.add_command({'backflip', 'bflip'}, 'do a backflip', {}, function(vars)
			do_flip('back')
		end)

		api.add_command({'frontflip', 'fflip'}, 'do a frontflip', {}, function(vars)
			do_flip('front')
		end)

		api.add_command({'sideflip', 'sflip'}, 'do a sideflip', {
			{'direction', 'string'}
		}, function(vars, direction)
			direction = (direction or 'left'):lower()
			if direction ~= 'left' and direction ~= 'right' then
				return api.notify('flip', 'direction must be left or right', 2)
			end
			do_flip(direction)
		end)

		return true
	end
}

return plugin
