# opadmin

another admin script yes, currently we have 245 commands

## features

- **plugin support** - load custom plugins from urls with auto-reload on rejoin
- **targeting** - flexible player targeting (me, all, others, random, teamamtes, enemies, nearest, currently viewing, partial matching)
- **visuals** - esp, tracers, crosshair, fov circle, bullter tracers, hit sounds (slop), and more
- **combat** - aimbot, silent aim, rageaim, triggerbot, hitbox expand
- **movement** - fly, noclip, speed, infinite jump, teleport
- **bypasses** - decent bypasses for most movement/visual/combat commands (you have to set bypass arg to true if the command have one)
- **cool stuff** - flingaura, partfling, parttrap, partwalkfling, blackhole, partrain, partcontrol (very fun yes)

## running

execute with any script executor:

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/addihallstar/opadminsupreme/refs/heads/main/opadmin_new.lua'))()
```

## usage

open command bar (press 0 on your numpad or use the chat with prefix "!") and type commands

note: you don't need to use the prefix if typing into the command bar

use `!cmds` to list all available commands.

## targeting

commands that accept players support these selectors:

note: all selectors (expect partial name matching) should start with @

| selector | description |
|-|-|
| `@me/@s/@m` | yourself |
| `@everyone/@all/@e/@a` | all players |
| `@others/@other/@o` | everyone except you |
| `@view/@v` | the player you are currently viewing with `view` command |
| `@random/@rand/@r` | random player |
| `@nearest/@n` | closest player to you |
| `@team` | players on your team |
| `@enemies` | every player except players on your team |
| `playername` | partial name matching |

examples:
```
!kill others
!to nearest
!orbit random
!partfling enemies
```

## plugins

extend functionality with custom plugins. see [plugin documentation](PLUGINS.md) for details.

### quick start

```lua
local plugin = {
    name = 'hi plugin',
    version = '1.0',
    author = 'you',
    description = 'does something cool',
    
    init = function(api)
        api.add_command({'hi'}, 'hi command', {}, function(vars)
            api.notify('hi', 'bye (evil)', 1)
        end)
        return true
    end
}

return plugin
```

load with:
```
!pluginload <url to the plugin source>
```

## configuration

settings persist automatically. configure with `settings` command:

```
!settings save
!settings load
!settings reset
!settings get open_keybind
!settings set open_keybind Z
!settings list
```

to change prefix/open keybind fast:

```
!prefix .
!openbind Z
```

## credits for some commands
- [Fred (formerly E God)](https://github.com/TheEGodOfficial) for the [punch tool](https://github.com/TheEGodOfficial/E-Super-Punch)
- [x114](https://github.com/x114) for the [automatic chat translator](https://github.com/x114/RobloxScripts/blob/main/UpdatedChatTranslator)
- [InfernusScripts](https://github.com/InfernusScripts) for the [remote spy](https://github.com/InfernusScripts/Ketamine)
- [Chillz](https://github.com/AZYsGithub) for the [dex++](https://github.com/AZYsGithub/DexPlusPlus)
- maybe some other people i forgot about sorry
