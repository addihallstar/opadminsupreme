# opadmin

another admin script yes, currently we have 293 commands
16000 lines op

## features

- **plugin support** - load custom plugins from urls with auto-reload on rejoin.
- **targeting** - flexible player targeting.
- **visuals** - esp (npcs, items, players), tracers (npcs, items, players), crosshair, fov circle, bullet tracers, hit sounds (slop), and more.
- **combat** - aimbot, silent aim, rageaim, triggerbot, hitbox expand, antiaim (useless) and more.
- **movement** - fly, noclip, speed, infinite jump, teleport, click tp, teleport tool, cframewalkspeed, noclip and more.
- **bypasses** - decent bypasses for most movement/visual/combat commands. (you have to set bypass arg to true if the command has one)
- **cool stuff** - flingaura, partfling, parttrap, partwalkfling, blackhole, partrain, partcontrol, punchfling, f3xnuke, f3xblackhole, f3xbuild, f3xtrap. (very fun yes)

## running

execute with any script executor:

```lua
loadstring(game:HttpGet('https://raw.githubusercontent.com/addihallstar/opadminsupreme/refs/heads/main/opadmin_new.lua'))()
```

## usage

open command bar (press ] / RightBracket ) or use the chat with '!' prefix and type commands

> **note:** you don't need to use the prefix if typing into the command bar

use `!cmds` to list all available commands.

## targeting

commands that accept players support these selectors:

> **note:** all selectors (except partial name matching) should start with `@`, `#`, `$`, or `*`

### basic selectors

| selector | description |
|-|-|
| `@me` / `@self` / `@s` / `@m` | yourself |
| `@everyone` / `@all` / `@e` / `@a` | all players |
| `@others` / `@other` / `@o` | everyone except you |
| `@random` / `@rand` / `@r` | random player |
| `@view` / `@v` | the player you are currently viewing with `view` command |

### team-based selectors

| selector | description |
|-|-|
| `@team` / `@teammates` / `@allies` / `@t` | players on your team (excluding yourself) |
| `@enemies` / `@enemy` | players not on your team (excluding yourself) |
| `#teamname` | players on a specific team (partial matching) |

### relationship selectors

| selector | description |
|-|-|
| `@friends` / `@friend` | your roblox friends in the server |
| `@nonfriends` / `@notfriends` / `@strangers` | players who aren't your friends |

### state-based selectors

| selector | description |
|-|-|
| `@armed` / `@hastool` | players currently holding a tool |
| `@unarmed` / `@notool` | players not holding a tool |
| `@grounded` / `@onground` | players standing on solid ground |
| `@moving` | players with horizontal movement speed > 1 |

### visibility selectors

| selector | description |
|-|-|
| `@onscreen` / `@screen` | players visible on your screen |
| `@offscreen` | players not visible on your screen |
| `@facing` / `@lookingat` | players looking towards you |

### health selectors

| selector | description |
|-|-|
| `@lowhp` / `@lowhealth` / `@weak` | players with ≤30% health |
| `@fullhp` / `@fullhealth` | players with full health |

### account age selectors

| selector | description |
|-|-|
| `@newest` / `@new` | player with youngest account (under 1 year) |
| `@oldest` / `@old` / `@veteran` | player with oldest account |

### special prefixes

| prefix | description | example |
|-|-|-|
| `#` | team name matching | `#red` - all players on a team containing 'red' |
| `$` | user id matching | `$12345678` - player with that exact user id |
| `*` | pattern matching (contains) | `*pro` - all players with 'pro' in their name |
| *(none)* | partial name matching | `john` - first player whose name starts with 'john' |

### examples

```
!murder @everyone (the command doesn't exist it just for the funny)
!to @nearest
!orbit @random
!fling @enemies
!f3xtrap @nonfriends
!nuke @others
!partfling #Lobby
!view $13371337
!parttrap *monkey
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
