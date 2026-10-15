# Sound

Games can have sound effects: 8 bit, mono, made from short recipes at start up, with no sound files. Tetris and Snake have it today, in the soft, warm voice of their Lantern Glass look. A game that has no sound is unchanged, and a machine with no sound device just stays quiet.

Sound is on by default. The M key (or the Sound button) switches it on and off in any game that has it, and the choice is saved.

## How it fits together

```
 run/run-<game>.p      builds the bank, the player and the renderer, and disposes them in the right order
    |
 ProGriddle.Games.<Game>   <Game>Cue (enum), <Game>Cues (when), <Game>Sounds (what it sounds like)
    |
 ProGriddle.UI.Audio       WaveOutPlayer and WinMm.p: the only layer that talks to Windows sound
    |
 ProGriddle.Engine         ToneSynth, SoundBank, ISoundPlayer, NullSoundPlayer, ICueSource, SoundRenderer, SoundSettings
```

A game and its painter know nothing about sound. The pieces are:

| Piece | What it does |
|---|---|
| `ToneSynth` | Turns a recipe into 8 bit unsigned mono sound at 11025 Hz in a `MEMPTR`, with integer maths only |
| `SoundBank` | Keeps the made sounds by cue number (1 to 64) and frees their memory in `Dispose` |
| `ISoundPlayer` | `Play(cue)`, `Muted`, `Volume` (0 to 100), `Working` and `Dispose`. Play never waits and never fails |
| `NullSoundPlayer` | The silent player, the default |
| `ICueSource` | One per game. `Poll(game)` says which cues are new since the last look, most important first, and `GroupOf(cue)` gives each cue a priority group |
| `SoundRenderer` | An `IGridRenderer` that wraps the real one. After every change of the picture it polls the cue source, plays the new cues (only the first cue of each priority group, so a lock and a clear in one moment make one sound) and draws |
| `SoundSettings` | Reads `sound.on` and `sound.volume` onto a player (`Apply`) and switches the sound (`Toggle`) |
| `WaveOutPlayer` | The Windows player (layer `ProGriddle.UI.Audio`) |

The controller already redraws whenever a game says something changed, so the `SoundRenderer` needs no change to any game or controller: the composition root hands the controller the sound renderer in place of the painter.

## Recipes

A recipe is a comma separated list of parts played one after another. A part is `spec:ms` or `spec:ms:decay`.

| Spec | Sound |
|---|---|
| `440` | A square wave at 440 Hz (20 to 5000) |
| `880>440` | A square wave sliding from 880 to 440 Hz over the part |
| `t440`, `t880>440` | The same as a triangle wave: softer, so the Lantern Glass games use it |
| `n` | Noise |
| `r` | A rest, silence |

`ms` is how long the part lasts (1 to 5000) and `decay` the percentage of its swing it loses by its end (0 to 100, 50 when left out). Every part rises over a few milliseconds from silence and falls back to it, so there is no click. The same recipe always gives the same bytes (the noise register starts from a fixed value). A recipe that cannot be read throws `GridException`.

`"t523:60:30,t659:60:30,t784:110:70"` is three rising soft notes. The synthesiser uses whole numbers for the phase of the wave and the slide of the pitch, so it needs no division but one for the swing of each sample: about 3 ms for every 1000 samples (a second is 11025). Making all six sounds of Tetris at start up takes about 140 ms.

## The Windows player

`WaveOutPlayer` plays through the `waveOut` calls of `winmm.dll`, with no files and no callbacks. It keeps a pool of 8 voices (a `waveOut` handle each): two sounds on one handle queue one behind the other, while sounds on separate handles are mixed, so up to 8 sounds overlap. A voice that has finished is noticed the next time something plays, by the done flag of its buffer's header. If all 8 are busy the new sound is dropped (counted in `Dropped`). A play costs about 1.4 ms, measured, so it is safe on the UI thread. The volume is set on each voice with `waveOutSetVolume`, so changing it does not remake any sound.

If no voice opens (no sound card, a remote session) `Working` is false and every call is silent. A game's input offers the Sound command and the M key only while the player is working.

`ProGriddle/UI/Audio/WinMm.p` is the one procedure file in the framework: an `EXTERNAL` procedure cannot be declared inside a class, so the winmm calls live in a small persistent procedure that the player runs and calls. It holds nothing but the wave format.

Rejected on the way: MCI (`mciSendString`) blocks the UI thread for 85 to 138 ms on every play, and `System.Media.SoundPlayer` plays one sound at a time for the whole process, with no mixing.

Memory: the bank owns the sounds and the player owns its headers. The player only borrows the bank, so **dispose the player first** (which stops the sounds, since the device reads them from the bank's memory), then the bank. Both free everything in `Dispose`, with a destructor as a safety net.

## Settings

| Key | Meaning | Default |
|---|---|---|
| `sound.on` | `false` for no sound. The Sound command and the M key switch it and save it | `true` |
| `sound.volume` | 0 to 100, held to that range. The volume of the whole player, on top of how loud each cue was made | 50 |

The keys are shared by every game with sound.

## Adding sound to a game

1. Write the cue enum, for example `PongCue`, with explicit numbers from 1 (`DEFINE ENUM Hit = 1 Miss Win.`). `INTEGER(PongCue:Hit)` is the number the player and the bank use.
2. Write `PongSounds`: a recipe and a volume for each cue, and `Fill(bank)`. Keep every sound in this one place, as the art and look classes keep the picture. Test that every cue has a recipe that makes sound.
3. Write `PongCues` implementing `ICueSource`. Compare the game's counters (a score, a count of pieces, whether it is over) with the ones last seen: a counter is better than an event time, because two events in the same millisecond are still two. Notice a new game (a serial number that goes up) and take its state without a sound. Test it with a real game driven by hand.
4. In the game's input add the second constructor taking an `ISoundPlayer` (the old one passes a `NullSoundPlayer`), `Sound:M` in `CommandNames` while the player works, and `SoundSettings:Toggle` in `Perform`.
5. In the run file: `SoundBank`, `PongSounds:Fill`, `WaveOutPlayer`, `SoundSettings:Apply`, a `SoundRenderer` around the painter and the controller built on that, and the disposal in `FINALLY`.

## Tests

| Test class | What it proves |
|---|---|
| `ToneSynthTests` | The count and the size of the samples, silence at both ends, a square wave's two levels, volume, decay, slides that shorten or lengthen the cycle, a fixed pitch's cycle, the triangle, rests, noise, the same recipe giving the same bytes, bad recipes, the build time |
| `SoundBankTests` | Defining, replacing, size and address, `Dispose` and refills, the errors |
| `SoundPlayerTests` | The silent player and the recording double |
| `SoundRendererTests` | Passing the picture on, playing the polled cues in order, one cue per priority group, polling while muted, the errors |
| `SoundSettingsTests` | The saved settings on a player, the switch, the errors |
| `WaveOutPlayerTests` | The real player with silent sounds at volume 0: a sound started and seen to finish, nine sounds on eight voices, mute, disposal. They need a sound device and say nothing when there is none |
| `TetrisCuesTests`, `SnakeCuesTests` | Each event of a real game reported once and in order, a new game forgetting the old one, the priority groups, the whole chain to a recording player |
| `TetrisSoundsTests`, `SnakeSoundsTests` | Every cue has a recipe that makes sound and the bank fills |

The window smoke tests (`tools/gui-smoke-*.ps1`) cannot hear, so they prove only that a window with a sound device opens, plays and closes cleanly. What the sounds are like is checked by ear.
