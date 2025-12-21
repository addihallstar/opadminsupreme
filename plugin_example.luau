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
	notify: (title: string, text: string, duration: number?) -> (),
	get_maid: () -> maid,
	get_stuff: () -> stuff,
	get_cmd_library: () -> command_library,
	get_hook_library: () -> hook_lib
}

local plugin = {
	name = 'flips',
	version = '1.0',
	author = 'pro',
	description = 'adds flips to opadmin',

	init = function(api: plugin_api)
		local stuff = api.get_stuff()
		local maid = api.get_maid()
		local run_service = game:GetService('RunService')

		local shared_vars = {
			flipping = false,
			original_autorotate = true
		}

		local function do_flip(direction: string, speed: number, flips: number)
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
			shared_vars.original_autorotate = humanoid.AutoRotate
			humanoid.AutoRotate = false

			local total_rotation = 360 * flips
			local duration = total_rotation / (speed * 60)

			local start_time = tick()
			local start_cframe = hrp.CFrame

			local rotation_axis
			local angle_multiplier = 1

			if direction == 'back' then
				rotation_axis = start_cframe.RightVector
				angle_multiplier = 1
			elseif direction == 'front' then
				rotation_axis = start_cframe.RightVector
				angle_multiplier = -1
			elseif direction == 'left' then
				rotation_axis = start_cframe.LookVector
				angle_multiplier = 1
			elseif direction == 'right' then
				rotation_axis = start_cframe.LookVector
				angle_multiplier = -1
			end

			maid.add('flip_loop', run_service.RenderStepped, function()
				if not shared_vars.flipping then return end

				local new_character = stuff.owner_char
				if not new_character then
					shared_vars.flipping = false
					maid.remove('flip_loop')
					return
				end

				local new_hrp = new_character:FindFirstChild('HumanoidRootPart')
				local new_humanoid = new_character:FindFirstChildOfClass('Humanoid')
				if not new_hrp or not new_humanoid then
					shared_vars.flipping = false
					maid.remove('flip_loop')
					return
				end

				local elapsed = tick() - start_time
				local progress = math.clamp(elapsed / duration, 0, 1)

				local eased_progress = 1 - math.pow(1 - progress, 2)
				local current_angle = math.rad(total_rotation * eased_progress) * angle_multiplier

				local rotation = CFrame.fromAxisAngle(rotation_axis, current_angle)
				local rotated_cframe = start_cframe * rotation

				new_hrp.CFrame = CFrame.new(new_hrp.Position) * (rotated_cframe - rotated_cframe.Position)

				if new_humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					new_humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
					new_humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
				end

				if progress >= 1 then
					shared_vars.flipping = false
					new_humanoid.AutoRotate = shared_vars.original_autorotate
					new_humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
					new_humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
					maid.remove('flip_loop')

					local flip_name = direction == 'left' or direction == 'right' 
						and `{direction} sideflip` 
						or `{direction}flip`
					api.notify('flip', `completed {flips} {flip_name}{flips > 1 and 's' or ''}`, 2)
				end
			end)
		end

		api.add_command({'backflip', 'bflip'}, 'do a backflip', {
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, speed, flips)
			do_flip('back', speed or 8, flips or 1)
		end)

		api.add_command({'frontflip', 'fflip'}, 'do a frontflip', {
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, speed, flips)
			do_flip('front', speed or 8, flips or 1)
		end)

		api.add_command({'sideflip', 'sflip'}, 'do a sideflip', {
			{'direction', 'string'},
			{'speed', 'number'},
			{'flips', 'number'}
		}, function(vars, direction, speed, flips)
			direction = (direction or 'left'):lower()
			if direction ~= 'left' and direction ~= 'right' then
				return api.notify('flip', 'direction must be left or right', 2)
			end
			do_flip(direction, speed or 8, flips or 1)
		end)

		api.add_command({'stopflip', 'unflip'}, 'stops current flip', {}, function(vars)
			if not shared_vars.flipping then
				return api.notify('flip', 'not flipping', 2)
			end

			shared_vars.flipping = false
			maid.remove('flip_loop')

			local character = stuff.owner_char
			if character then
				local humanoid = character:FindFirstChildOfClass('Humanoid')
				if humanoid then
					humanoid.AutoRotate = shared_vars.original_autorotate
					humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
					humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
				end
			end

			api.notify('flip', 'flip stopped', 2)
		end)

		return true
	end
}

return plugin
