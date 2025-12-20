# opadmin plugin documentation

guide on how to create plugins for opadmin.

## plugin structure

plugins are lua scripts that return a table with the following fields:

```lua
local plugin = {
    name = 'best plugin eva',       -- required, unique identifier
    version = '1.0',                -- optional, version string
    author = 'nerd',                -- optional, creator name
    description = 'what it does',   -- optional, short description
    
    init = function(api)
        -- ur code
        return true
    end
}

return plugin
```

## api reference

the `init` function receives an `api` table with these functions:

| function | description |
|-|-|
| `api.add_command(names, description, args, fn)` | registers a new command |
| `api.notify(title, message, type)` | shows a notification |
| `api.get_maid()` | returns the maid (cleanup utility) |
| `api.get_stuff()` | returns shared variables (owner, flags, etc.) |
| `api.get_hook_library()` | returns the hook library (utility to manage hooks) |
| `api.get_cmd_library()` | returns the command library (utility to manage commands) |
| `api.config` | access to config system |

### notification types

| type | meaning |
|-|-|
| `1` | success (white) |
| `2` | error (red) |
| `3` | warning (yellow) |
| `4` | info (blue) |

## adding commands

```lua
api.add_command(
    {'commandname', 'alias1', 'alias2'},  -- names/aliases
    'description of what it does',        -- description
    {                                     -- arguments
        {'arg1', 'string'},
        {'arg2', 'number'},
        {'arg3', 'boolean'},
        -- arg_name: string, arg_type: string, hidden: boolean?
        -- all arg_types supported: number, boolean (bool), string, player, vector3 (vec3), color3 (color), cframe, table (array)
        -- player arg accepts a string and returns a player instance or nil
    },

    function(vstorage, arg1, arg2, arg3)
        -- command code
    end
)
```

### vstorage

first argument passed to command function. persistent storage table unique to each command. useful when a command needs to access data from a different command or for toggle logic:

```lua
function(vstorage)
    vstorage.enabled = not vstorage.enabled
    api.notify('cmd', vstorage.enabled and 'enabled' or 'disabled', 1)
end
```

## examples

### basic command

```lua
local plugin = {
    name = 'greeter',
    version = '1.0',
    author = 'you',
    description = 'greets players',
    
    init = function(api)
        api.add_command(
            {'greet', 'hello'},
            'sends a greeting',
            {{'player', 'player'}},
            function(vars, player)
                if not player then
                    api.notify('greet', 'player not found', 2)
                    return
                end
                local cmd_lib = api.get_cmd_library()
                cmd_lib.execute('say', `hello, {player.DisplayName}!`)
                api.notify('greet', 'greeted ' .. player.Name, 1)
            end
        )
        return true
    end
}

return plugin
```

### using stuff table

```lua
local plugin = {
    name = 'teleporter',
    version = '1.0',
    author = 'you',
    description = 'teleport command',
    
    init = function(api)
        local stuff = api.get_stuff()
        
        api.add_command(
            {'tpto'},
            'teleport to a player',
            {{'player', 'player'}},
            function(vars, target)
                if not target or not target.Character then
                    api.notify('tp', 'invalid target', 2)
                    return
                end
                
                local owner_char = stuff.owner_char
                if not owner_char then return end

                local target_char = target.Character
                if not target_char then return end

                owner_char:PivotTo(target_char:GetPivot())
                api.notify('tp', 'teleported to ' .. target.Name, 1)
            end
        )
        return true
    end
}

return plugin
```

## loading plugins

### from url
using github as an example the file could be hosted on any website
```
pluginload https://raw.githubusercontent.com/user/repo/main/plugin.lua
```

### commands

| command | description |
|-|-|
| `pluginload <url>` | load a plugin from url |
| `pluginunload <name>` | unload a plugin |
| `pluginreload <name>` | reload a plugin |
| `plugininfo <name>` | show plugin info |

## notes

- plugins auto-save and reload on rejoin
- plugin names are case-insensitive
- commands from unloaded plugins are automatically removed
- use `vstorage` for state, not upvalues (prevents memory leaks on reload)
- always return `true` from `init` on success
