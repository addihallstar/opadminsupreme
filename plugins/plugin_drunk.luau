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
	add_command: (names: {string}, description: string, args: {command_arg_definition}, fn: (vars: {[string]: any}, ...any) -> ()) -> (),
	notify: (log: string, text: string, log_type: number?) -> (),
	get_maid: () -> maid,
	get_stuff: () -> stuff,
	get_cmd_library: () -> command_library,
	get_hook_library: () -> hook_lib,
	config: any
}

local plugin = {
	name = 'drunk',
	version = '1.0',
	author = 'rez',
	description = 'beer',

	init = function(api: plugin_api)
		local stuff = api.get_stuff()
		local maid = api.get_maid()
		local cam = workspace.CurrentCamera

		local shared_vars = {
			drunk = false,
			intensity = 1,
			original_fov = 70
		}

		local function yes()
			shared_vars.drunk = true
			shared_vars.original_fov = cam.FieldOfView

			local time_offset = 0
			local wobble_offset = 0

			maid.add('drunk_camera', game:GetService('RunService').RenderStepped, function(dt)
				if not shared_vars.drunk then return end

				time_offset = time_offset + dt
				wobble_offset = wobble_offset + dt * 0.7

				local intensity = shared_vars.intensity
				local roll = math.sin(time_offset * 1.3) * 0.08 * intensity
				local pitch = math.sin(time_offset * 0.9) * 0.03 * intensity
				local yaw = math.sin(time_offset * 0.5) * 0.02 * intensity

				cam.CFrame = cam.CFrame * CFrame.Angles(pitch, yaw, roll)
				cam.FieldOfView = shared_vars.original_fov + math.sin(wobble_offset * 2) * 5 * intensity
			end)

			maid.add('drunk_movement', game:GetService('RunService').Heartbeat, function(dt)
				if not shared_vars.drunk then return end

				local char = stuff.owner_char
				if not char then return end

				local hum = char:FindFirstChildOfClass('Humanoid')
				if not hum then return end

				local intensity = shared_vars.intensity
				local random_speed = stuff.default_ws + math.sin(tick() * 3) * 4 * intensity
				hum.WalkSpeed = math.max(random_speed, 4)
			end)

			api.notify('drunk', 'enabled', 1)
		end

		local function no()
			shared_vars.drunk = false
			maid.remove('drunk_camera')
			maid.remove('drunk_movement')
			cam.FieldOfView = shared_vars.original_fov

			local char = stuff.owner_char
			if char then
				local hum = char:FindFirstChildOfClass('Humanoid')
				if hum then
					hum.WalkSpeed = stuff.default_ws
				end
			end

			api.notify('drunk', 'sobered up', 1)
		end

		api.add_command({'drunk'}, 'toggle drunk mode', {
			{'intensity', 'number'}
		}, function(vars, intensity)
			shared_vars.intensity = math.clamp(tonumber(intensity) or 1, 0.1, 3)

			if shared_vars.drunk then
				no()
			else
				yes()
			end
		end)

		api.add_command({'sober'}, 'disable drunk mode', {}, function(vars)
			no()
		end)

		return true
	end
}

return plugin
