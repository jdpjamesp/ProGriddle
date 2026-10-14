# Accessibility

ProGriddle games should be playable by as many people as possible. This page says what the framework does today, where it falls short, and what to do when you build a game so it does not get worse. It is a short, honest list rather than a promise of full compliance: the board is drawn as a bitmap, so a screen reader cannot read it.

## What works today

- **The Cookoff.** Each game button has an accessible name (the game's title, plus "(playing)" while it runs), so a screen reader can read the list of games and move between them with Tab.
- **Keyboard first.** `GameWindow` gives every game keys for its common actions: Space to start or pause, S or Right arrow to step, R or F2 for a new game, + and - or Up and Down for speed, P to pause a real time game. Every game's page lists its own keys.
- **Adjustable speed.** Steppable games have a speed slider and keys, and Space Invaders has a speed percentage, so the pace is not fixed to the arcade's.
- **Pausing.** Real time games can be paused at any moment.
- **Shape as well as colour.** Minesweeper draws numbers, a flag and a mine as glyphs, and does not rely on colour alone to tell a cell's state.
- **One place for colours.** Each game keeps its colours in one class (a `Palette` enum and a `...Look` class), so a high contrast or colour blind friendly set is a change to one file, not a hunt through the game.

## Known gaps

- The board itself has no accessible description, so a screen reader user cannot read it. A game's status (score, level, game over) is shown in the window title and status bar, which is the best place to look.
- Several games lean on colour as the main signal, and there is no ready made colour blind palette yet.
- Keyboard play has not been checked for every game, and some actions may be mouse only.

If one of these stops you playing, please [open an issue](https://github.com/jdpjamesp/ProGriddle/issues/new/choose). Contributions that close a gap are very welcome.

## When you build a game

- Give every action a key, and list it on the game's page. A mouse gesture may be a shortcut, never the only way.
- Never use colour alone for something the player must know. Add a glyph, a shape or a text line in the status bar.
- Pick colours with good contrast between neighbouring values and the background, and keep them in one `Palette` enum and one `Look` class.
- Offer a speed control for anything real time, and a pause.
- Put what is happening (score, level, win, loss) in text, in the status bar or the window title.
- Give any new control an `AccessibleName` and a sensible Tab order. The board (`GridView`) is deliberately not a tab stop, so keys go to the game.
- Do not flash large areas of the board: nothing should flash more than three times in any one second.

## Testing it

Run the game with the keyboard only, once with the display set to a high contrast Windows theme, and once with a colour blindness simulator over a screenshot (the smoke tests save screenshots to `build/screenshots`). Narrator should read the Cookoff buttons.
