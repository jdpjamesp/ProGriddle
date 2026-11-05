# Rogue

An ASCII dungeon crawler after the 1980 original. You are an `@` in a dungeon of 26 levels of rooms and corridors. Find the Amulet of Yendor on the 26th level and climb back out with it. Along the way there are 26 kinds of monster (one for each letter A to Z), potions, scrolls, wands and rings whose names are unknown until you find out what they do, armour and weapons, traps, secret doors, hunger and a dark that gets deeper. Turn based, played from the keyboard on a screen of 80 x 24 characters in an 8 x 14 pixel font, with a movement scheme of your choice (vi keys or the number pad). Playable now. (The rules follow the original closely and are not yet de-branded.)

## Playing it

From the repository root, or from the Cookoff (`cookoff.bat`), where it has a green button of its own on the Adventure tab:

```
"C:\Progress\OpenEdge\bin\prowin.exe" -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-rogue.p"
```

Optional entries after the program name: a settings file (`default` for `%APPDATA%\ProGriddle\settings.json`), a number of seconds after which the window closes by itself, and a seed for the dungeon. The window is the shape of the screen (up to 2 pixels to a pixel where there is room) and the picture scales to fill it.

### Controls

| Input | What it does |
|---|---|
| `h` `j` `k` `l` `y` `u` `b` `n` (vi keys) | Move west, south, north, east and the four diagonals. With Shift: run |
| Number pad, arrow keys, Home, End, Page Up, Page Down | The same moves, in either setting. With Shift: run |
| Walk into a monster | Fight it |
| `.` or `5` | Rest a turn |
| `s` | Search for secret doors and hidden traps next to you |
| `,` | Pick up what is under you (walking onto something picks it up by itself) |
| `>` and `<` | Down the stairs, and up them (only once you hold the amulet) |
| `i` | Show the pack. Any key closes it |
| `q` `r` `e` | Quaff a potion, read a scroll, eat |
| `w` `W` `T` | Wield a weapon, wear armour, take armour off |
| `P` `R` | Put on a ring, remove a ring |
| `d` `t` `z` | Drop, throw (with a direction), zap a wand (with a direction) |
| `M` `D` | The messages so far, and what you have discovered |
| `?` | The help screen |
| `Q` | Give up |
| Escape | Give up a question (which thing? which way?) |
| Enter, F2 or the New game button | A new game (when one has ended) |
| The **Keys** button | Switch between the vi keys and the number pad and arrows (kept as `rogue.keys`) |

A command that needs a thing asks "Quaff what?" and shows the pack: answer with the letter. One that needs a direction asks "In what direction?": answer with any movement key (a vi letter, an arrow or a number pad key).

With the number pad setting the letters `h j k l y u b n` are plain letters and move nothing. While the game is asking which thing, letters are always pack letters (the pack runs from `a` to `w`, and `h` to `n` are among them) in both settings.

### The rules

The rules are those of the original, with the numbers a little softened where the original is cruel.

- **The dungeon.** A level is a 3 x 3 board of cells. Each holds a room of a random size (4 to 18 squares across), or, for up to four cells, no room but a single square where corridors meet. Corridors join the cells, first by a spanning tree (so every room can be reached) and then with some extra loops. Doors are sometimes secret (more often on deeper levels): search with `s`. From the second level on, rooms may be dark, more and more of them the deeper you go: a dark room shows only the squares next to you. Traps are hidden until you step on one or find it by searching. Going up or down makes a whole new level (the old one is not kept).
- **You.** 12 hit points, strength 16, a full stomach and the original's kit: a food ration, +1 ring mail (worn), a +1,+1 mace (wielded), a +1 bow and some arrows. You gain a level at 10, 20, 40, 80 ... experience points (a die of 10 hit points more each time), and hit points come back with time (faster with level and a ring of regeneration). Armour class is lower the better: 10 with nothing on.
- **Fights.** A blow lands when a twenty sided die plus the attacker's bonus reaches 20 minus the attacker's level minus the target's armour class. A monster has one blow for each set of dice in its damage list (a dragon has three). Sleeping and held monsters are easier to hit. You throw things with `t`: darts, shuriken, daggers, spears, and arrows from a wielded bow.
- **Monsters.** `A` aquator (rusts armour), `B` bat (flutters), `C` centaur, `D` dragon (breathes fire down a clear line), `E` emu, `F` venus flytrap (holds you and squeezes harder each turn), `G` griffin, `H` hobgoblin, `I` ice monster (freezes you), `J` jabberwock, `K` kestrel, `L` leprechaun (steals gold), `M` medusa (confuses), `N` nymph (steals an item), `O` orc, `P` phantom (invisible), `Q` quagga, `R` rattlesnake (weakens you), `S` snake, `T` troll (heals), `U` ur-vile, `V` vampire (drains hit points), `W` wraith (drains a level), `X` xeroc, `Y` yeti, `Z` zombie. The deeper the level, the higher in the alphabet (by the original's order `KEBSHIROZLCQANYFTWPXUMVGJD`) the monsters, with a chance of a weaker or stronger one. Monsters sleep until you come near (a ring of stealth helps) unless they are mean.
- **Unknown things.** Every game gives each of the 14 potions a colour, each of the 14 scrolls a title made of nonsense, each of the 14 wands a metal and each of the 14 rings a stone, all different and all new each game. Using a thing, or a scroll of identify, teaches its kind, and it is called by its real name from then on (`D` lists them). The potions are confusion, hallucination, poison, gain strength, see invisible, healing, monster detection, magic detection, raise level, extra healing, haste self, restore strength, blindness and levitation. The scrolls are identify, enchant armor, enchant weapon, remove curse, monster confusion, teleportation, magic mapping, sleep, hold monster, create monster, scare monster, food detection, aggravate monsters and protect armor. The wands are light, invisibility, lightning, fire, cold, polymorph, magic missile, haste monster, slow monster, drain life, nothing, teleport away, teleport to and cancellation. The rings are protection, add strength, sustain strength, searching, see invisible, adornment, aggravate monster, dexterity, increase damage, regeneration, slow digestion, teleportation, stealth and maintain armor. Weapons, armour and rings can be cursed (a minus): a cursed thing cannot be taken off once it is on, until a scroll of remove curse.
- **Hunger.** Each turn costs a point of the 2000 in your stomach. You are told when you are Hungry (under 300), Weak (150) and Faint (50: now and then you collapse), and at 0 you starve. A food ration puts back 1800.
- **The score** is your gold, and, if you climb out with the amulet, what everything you carry is worth too. The ten best games are kept (`rogue.scores`) and shown when a game ends.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `rogue.keys` | `vi` or `numpad` (the Keys button changes it) | `vi` |
| `rogue.scores` | The ten best games (kept by the game) | none |

The window also saves its position as `rogue.window.x` and `y`. Its size is always worked out from the picture.

## How it uses the framework

| Part | Used here |
|---|---|
| Archetype | Turn based: `RogueGame` implements `ITurnBasedGame` on `AbstractGame`, and every move is a command token given to `Command` |
| Grid | Eight layers on an `ArrayStore` (`LevelMap`): terrain, room, seen, view, trap, found, item and mon |
| Picture | `RoguePainter` draws on a `PixelCanvas` of 640 x 336 pixels (80 x 24 characters of 8 x 14) with an `AsciiPen`, and hands it to `WinFormsGridRenderer` in direct colour, scaled by `GridView:FitToWindow` |
| Font | `AsciiFont`, every printable ASCII character as an 8 x 14 bitmap plus joined wall pieces and a floor dot, generated by `tools/gen-ascii-font.ps1` from Consolas. `AsciiPen` turns a glyph in a colour into a `PixelStamp` the first time and copies it from then on |
| Controller | `TurnController`: the game changes only when a command is given |
| Window | The generic `GameWindow`, told about the game through `RogueInput`, which implements `IGameInput` and the new `IModifierKeys` (the window tells it whether Shift is down before each key, which `>` `<` and the capital letters need) |
| Settings | `JsonFileSettings`, read by the input and the scores |
| Sound | None (the game is silent) |

Source: `src/ProGriddle/Games/Rogue/`. The composition root is `run/run-rogue.p`.

| Class | Job |
|---|---|
| `RogueGame` | The game: commands, prompts, the screens, stairs, running, the turn |
| `RogueWorld` | Everything there is: map, hero, pack, monsters, things on the floor, messages |
| `Dungeon`, `LevelMap` | Building a level, and typed access to its layers |
| `Sight`, `Chase` | What the hero can see, and the steps a monster takes to get to the hero |
| `Fighting`, `MonsterTurns` | The rules of a blow, the specials of the odd monsters, and what a monster does on its turn |
| `Gear`, `Magic`, `Throwing`, `Exploring`, `Upkeep` | Wearing and carrying, potions and scrolls and wands and traps, throwing, searching, and hunger and healing |
| `Item`, `Items`, `Pack`, `ItemText`, `Disguises` | A thing, making things, the pack, the words for a thing, and the unknown names of a game |
| `Weapons`, `Armours`, `Foods`, `Potions`, `Scrolls`, `Wands`, `Rings`, `Traps`, `Bestiary` | The tables: names, chances, worth, and the numbers of the fights |
| `Dice`, `WeightedPick` | `2d4` and "pick by chance", both through the random source |
| `RogueInput`, `RogueKeys`, `RogueScores`, `RogueHelp` | The keys and buttons, the key to token mapping, the ten best games, the help text |
| `RoguePainter`, `RogueLook`, `RogueTint` | The picture, and the colours by name |

## Tests

All under `tests/ProGriddle/Games/Rogue/`, about 465 of them: the tables, the builder (many seeds and depths, and that every room can be reached), the world, sight, the chase, fights and every special monster, gear, every potion, scroll, wand and trap, throwing, hunger and healing, the game's commands and prompts end to end, the keys, the input, the scores and the painter by pixel. A test builds a scene by hand with `ClearLevel`, `CarveRoom`, `PlaceHero`, `AddMonster` and `DropOnFloor`, and drives it with a `ScriptedRandom` that always says the same number (`"19"` for the best rolls, `"0"` for the worst), so a fight comes out the same way every time.

Run them with `powershell -NoProfile -ExecutionPolicy Bypass -File tools/run-tests.ps1 -Folder "Games/Rogue"`.

`tools/preview-rogue.p` draws a scenario (the start, a run about the level, the pack, the help, a deep dark level, the messages, a question, a death) into a BMP file with no window and no keyboard, so the look can be checked from a script:

```
_progres -b -T "%TEMP%\ProGriddle" -p tools/preview-rogue.p -param "7|explore|rogue.bmp"
```

## Design notes

- **Tokens, not keys.** `RogueGame:Command` takes a token, not a key: `"q"` for quaff, `"S-w"` for a capital W (string comparison in ABL ignores case, so a shifted letter has to look different), `"4"` for west on the number pad, `"run4"` for running west. `RogueKeys` turns a key and the Shift state into a token, and in vi mode the letters `h j k l y u b n` become directions there, so the game itself never knows about vi. A different front end (a mouse, say) only needs to speak tokens.
- **One world, rules as static helpers.** `RogueWorld` holds all the state and each part of the rules (`Fighting`, `Magic`, `Gear`) is a static class that works on a world, so each can be tried on a small scene.
- **A level is rebuilt, not kept.** As in the original, a new level is generated every time you go up or down, so the game has no level to save and the same stairs never lead to the same place twice.
- **Safe with any random source.** The tests use a source that says one number for ever, so every loop that waits for a lucky roll (picking a different start room, laying a trap, making a scroll title different from the others) has a way out.
- **Cost.** A picture takes about 70 milliseconds, and a turn about 30 to 60 with monsters awake (the chase map is a search of the whole level, made only when a monster is awake). Running is capped at 60 steps.
