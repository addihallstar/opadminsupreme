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
	name = 'slopalert',
	version = '1.2',
	author = 'rez',
	description = 'slop detection software',

	init = function(api)
		local maid = api.get_maid()

		local shared_vars = {
			active = false,
			hint = nil,
			scroll_position = 1
		}

		local full_text = ('slop warning ⚠ slop alert ⚠ slop detected ⚠ slop detection software ⚠ '):rep(50)
		local display_length = 250

		local function get_chars(str)
			local chars = {}
			local i = 1
			while i <= #str do
				local byte = string.byte(str, i)
				local char_len = 1
				if byte >= 240 then
					char_len = 4
				elseif byte >= 224 then
					char_len = 3
				elseif byte >= 192 then
					char_len = 2
				end
				table.insert(chars, string.sub(str, i, i + char_len - 1))
				i = i + char_len
			end
			return chars
		end

		local chars = get_chars(full_text)

		local function get_display_text(start_pos, length)
			local result = {}
			local count = 0
			local pos = start_pos
			while count < length and pos <= #chars do
				table.insert(result, chars[pos])
				count = count + 1
				pos = pos + 1
				if pos > #chars then
					pos = 1
				end
			end
			return table.concat(result)
		end

		local function yes()
			if shared_vars.active then return end
			shared_vars.active = true
			shared_vars.scroll_position = 1

			local hint = Instance.new('Hint')
			hint.Parent = workspace
			shared_vars.hint = hint

			hint.Text = get_display_text(1, display_length)

			task.spawn(function()
				while shared_vars.active and shared_vars.hint and shared_vars.hint.Parent do
					task.wait(0.1)
					
					shared_vars.scroll_position = shared_vars.scroll_position + 1

					if shared_vars.scroll_position > #chars then
						shared_vars.scroll_position = 1
					end

					if shared_vars.hint and shared_vars.hint.Parent then
						shared_vars.hint.Text = get_display_text(shared_vars.scroll_position, display_length)
					end
				end
			end)
		end

		local function no()
			if not shared_vars.active then return end
			shared_vars.active = false

			if shared_vars.hint then
				pcall(game.Destroy, shared_vars.hint)
				shared_vars.hint = nil
			end

			api.notify('slopalert', 'slop detection disabled', 1)
		end

		api.add_command({'slopalert', 'slop'}, 'enable slop detection software', {}, yes)
		api.add_command({'unslopalert', 'unslop'}, 'disable slop detection software', {}, no)

		return true
	end
}

return plugin
