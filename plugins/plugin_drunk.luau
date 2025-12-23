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

		local function start_drunk()
			shared_vars.drunk = true
			shared_vars.original_fov = cam.FieldOfView

			local time_offset = 0
			local wobble_offset = 0

			maid.add('drunk_camera', game:GetService('RunService').RenderStepped:Connect(function(dt)
				if not shared_vars.drunk then return end

				time_offset = time_offset + dt
				wobble_offset = wobble_offset + dt * 0.7

				local intensity = shared_vars.intensity
				local roll = math.sin(time_offset * 1.3) * 0.08 * intensity
				local pitch = math.sin(time_offset * 0.9) * 0.03 * intensity
				local yaw = math.sin(time_offset * 0.5) * 0.02 * intensity

				cam.CFrame = cam.CFrame * CFrame.Angles(pitch, yaw, roll)
				cam.FieldOfView = shared_vars.original_fov + math.sin(wobble_offset * 2) * 5 * intensity
			end))

			maid.add('drunk_movement', game:GetService('RunService').Heartbeat:Connect(function(dt)
				if not shared_vars.drunk then return end

				local char = stuff.owner_char
				if not char then return end

				local hum = char:FindFirstChildOfClass('Humanoid')
				if not hum then return end

				local intensity = shared_vars.intensity
				local random_speed = stuff.default_ws + math.sin(tick() * 3) * 4 * intensity
				hum.WalkSpeed = math.max(random_speed, 4)
			end))

			api.notify('drunk', 'enabled', 1)
		end

		local function stop_drunk()
			shared_vars.drunk = false
			maid:remove('drunk_camera')
			maid:remove('drunk_movement')
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
				stop_drunk()
			else
				start_drunk()
			end
		end)

		api.add_command({'sober'}, 'disable drunk mode', {}, function(vars)
			stop_drunk()
		end)

		return true
	end
}

return plugin
