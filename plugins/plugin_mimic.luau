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
	name = 'mimic',
	version = '1.0',
	author = 'rez',
	description = 'copy everything they do',

	init = function(api)
		local stuff = api.get_stuff()
		local maid = api.get_maid()
		local players = game:GetService('Players')
		local run_service = game:GetService('RunService')

		local shared_vars = {
			active = false,
			target = nil,
			offset = Vector3.new(3, 0, 0),
			delay_buffer = {},
			delay_time = 0.5,
			copy_jumps = true,
			copy_anims = true,
			last_jump_time = 0
		}

		local function yes(target_player)
			shared_vars.active = true
			shared_vars.target = target_player
			shared_vars.delay_buffer = {}

			local target_char = target_player.Character
			if not target_char then
				api.notify('mimic', 'target has no character', 2)
				return
			end

			maid.add('mimic_record', run_service.Heartbeat, function(dt)
				if not shared_vars.active or not shared_vars.target then return end

				local t_char = shared_vars.target.Character
				if not t_char then return end

				local t_hrp = t_char:FindFirstChild('HumanoidRootPart')
				local t_hum = t_char:FindFirstChildOfClass('Humanoid')
				if not t_hrp or not t_hum then return end

				local record = {
					time = tick(),
					cframe = t_hrp.CFrame,
					velocity = t_hrp.AssemblyLinearVelocity,
					jump = t_hum.Jump,
					move_dir = t_hum.MoveDirection,
					state = t_hum:GetState()
				}

				table.insert(shared_vars.delay_buffer, record)

				while #shared_vars.delay_buffer > 0 and 
					  tick() - shared_vars.delay_buffer[1].time > shared_vars.delay_time + 1 do
					table.remove(shared_vars.delay_buffer, 1)
				end
			end)

			maid.add('mimic_apply', run_service.RenderStepped, function(dt)
				if not shared_vars.active then return end

				local char = stuff.owner_char
				if not char then return end

				local hrp = char:FindFirstChild('HumanoidRootPart')
				local hum = char:FindFirstChildOfClass('Humanoid')
				if not hrp or not hum then return end

				local target_time = tick() - shared_vars.delay_time
				local best_record = nil
				local best_diff = math.huge

				for _, record in shared_vars.delay_buffer do
					local diff = math.abs(record.time - target_time)
					if diff < best_diff then
						best_diff = diff
						best_record = record
					end
				end

				if best_record then
					local target_pos = best_record.cframe.Position + shared_vars.offset
					local target_cframe = CFrame.new(target_pos) * best_record.cframe.Rotation

					hrp.CFrame = hrp.CFrame:Lerp(target_cframe, dt * 15)
					hrp.AssemblyLinearVelocity = best_record.velocity

					if shared_vars.copy_jumps and best_record.state == Enum.HumanoidStateType.Jumping then
						if tick() - shared_vars.last_jump_time > 0.5 then
							hum:ChangeState(Enum.HumanoidStateType.Jumping)
							shared_vars.last_jump_time = tick()
						end
					end
				end
			end)

			api.notify('mimic', 'now mimicking ' .. target_player.Name, 1)
		end

		local function no()
			shared_vars.active = false
			shared_vars.target = nil
			shared_vars.delay_buffer = {}
			maid.remove('mimic_record')
			maid.remove('mimic_apply')
			api.notify('mimic', 'stopped mimicking', 1)
		end

		api.add_command({'mimic', 'shadow', 'copy'}, 'copy someone's movement', {
			{'player', 'player'},
			{'delay', 'number'}
		}, function(vars, targets, delay)
			if not targets or #targets == 0 then
				if shared_vars.active then
					stop_mimic()
				else
					api.notify('mimic', 'player not found', 2)
				end
			end

			local target = targets[1]
			if not target then
				api.notify('mimic', 'player not found', 2)
				return
			end

			shared_vars.delay_time = math.clamp(tonumber(delay) or 0.5, 0.1, 3)

			if shared_vars.active then
				no()
			end

			yes(target)
		end)

		api.add_command({'unmimic', 'unshadow', 'uncopy'}, 'stop mimicking', {}, function(vars)
			no()
		end)

		api.add_command({'mimicoffset'}, 'set offset from target', {
			{'offset', 'vec3'}
		}, function(vars, offset)
			shared_vars.offset = offset or Vector3.new(3, 0, 0)
			api.notify('mimic', 'offset updated', 1)
		end)

		return true
	end
}

return plugin
