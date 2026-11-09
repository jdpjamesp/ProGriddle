# FootballManager: art and screen design brief

Written for: a designer (Claude Desktop) who will produce the look of the game. It is a brief, not a spec: the numbers under "The hard limits" are fixed, the rest is a starting point and you should push back where you have a better idea.

## What this is

ProGriddle is a framework for grid based games written in OpenEdge ABL. We have built Life, Minesweeper, Battleships, Tetris, 2048, Snake, Space Invaders, Asteroids, Centipede, Xevious, Rogue, Cuber, Blast Buddies and FOR EACH. The next game is a **football (soccer) management game**, in the spirit of the 1982 home computer classic: you run a small club from the bottom division, pick a team each week from a squad of 16, watch the match as a short run of highlights you cannot influence, then deal with the money (gate receipts, wages, transfers, a bank loan) and try to climb to the top division and win the cup.

**Working title: FootballManager.** The **rules, the screens and the club and player names are those of the original** (the rules and numbers are in `docs/design/footballmanager-rules.md`, the names are in its lists). This is a **faithful remake**, not a reinvention.

### Faithful to the original, shown as C64 style highlights (please read twice)

The target is **the original game as you would remember it, made to look good in 2026**:

- **Keep the original's shape**: the same menus and the same order of screens (set up, menu, pick the team, the match, the money report, the table, the transfer offer), the same five team numbers (Energy, Morale, Defence, Midfield, Attack), the same four divisions of 16 clubs, the same text style of lists and tables. A player of the 1982 game should feel at home at once.
- **Show the match as highlights**, as the C64 version did: the ball runs up a pitch, the shot is shown close up in the goal mouth, and the keeper dives. The classic **isometric goal mouth** view is welcome, drawn fresh.
- **Improve the picture, not the game.** Cleaner pixels, richer colour, proper tables, small icons, a little juice (a goal celebration, a ball that trails). No new features and no new screens beyond those listed here.
- **A twist of style is yours to propose** where it does not change the screens. For example: a **teletext** or **terminal green** look, a **matchday programme**, or a **warm club office**. Pick one idea and hold it.
- The tone is a loving remake: **warm, clear, chunky pixels, a little humour**.

## How the picture is made (please read, it decides what is possible)

The game draws on a **pixel canvas** (the same one Space Invaders, Centipede, Xevious and Cuber use): a grid of pixels, each pixel one flat 24 bit colour, shown scaled up with hard nearest neighbour edges. Sprites are drawn over a background that is already coloured. Most of this game is **screens of text and tables**, so the background and the pixel text carry most of the design.

### The hard limits

- The canvas is **320 columns by 240 rows**, shown at 3x (960 x 720) where the screen is tall enough, else 2x. A different size is allowed if you ask for it and say why (a table of 16 rows with names needs width). **Every detail must still read at 2x.**
- **No anti-aliasing and no blending.** A pixel is one colour and a later draw replaces an earlier one. Transparency is a pixel you leave out. A soft shadow or glow is made of extra pixels in dimmer colours.
- **Sprite sizes.**
  - **Match figures** (the little players on the highlight pitch): **8 wide by 12 high**, two kits (home and away), a goalkeeper in a third colour, a referee in a fourth. Facing: **left and right** (design right, the game mirrors for left). If your shading would look wrong mirrored, give the left frames too.
  - **The ball**: **5 x 5**, plus a 3 frame spin if you want one.
  - **Goal mouth close up**: a picture **96 x 64** (goal, net, a keeper who can dive left, centre or right, a ball that can arrive at nine places), see section 3.
  - **Portraits or badges**: a club **badge of 16 x 16** (design **8 different badges** that the game assigns to the clubs, we draw the name in text) and optionally a **player face of 24 x 24** (design **6 to 10 faces** that are reused).
  - Everything else (backgrounds, panels, icons, the HUD) is not hit by anything and can be any size that fits.
- **Cheap per frame.** A match is 22 figures, a ball and a few particles (single pixels, or lines of 2 or 3), so up to about **40 particles** is fine. Screens that are only text and panels cost nothing. A full screen effect that changes every pixel every frame is not affordable.
- **Text is made of pixels too.** We have a **5 x 7 capital letter font** (digits and basic punctuation included), drawn at 1x, 2x or 3x, in one colour or a vertical gradient, with an optional one pixel dark outline. **Lower case is not available**, so names and labels are CAPITALS. If you want a smaller or a lower case font for the tables, give its glyph bitmaps (a 4 x 6 or a 3 x 5 digit font would help the dense tables).
- **Colours must be told apart by more than hue** (see `docs/accessibility.md`): **home and away kits** must differ in pattern (stripes, a sash, a hoop) as well as colour, **energy and morale bars** must differ by length and a marker as well as colour, and **money in credit and in debt** must differ by a sign or a symbol as well as colour.

### The sprite format we will use

A sprite is rows of characters, one per pixel, with a legend. `.` is transparent. Give frames as separate blocks named `Figure run right 1`, `Figure run right 2` and so on.

Use the **tone format** of the Snake and Tetris art: for a part that is recoloured or shaded (a kit), the rows use `1` (highlight), `2` (light), `3` (base), `4` (shade), `5` (edge), and a colour table gives the five hex values for tones 1 to 5 for each colour row (home shirt, away shirt, keeper, referee, and so on). Anything with its own fixed colour (skin, a boot, the ball) uses letters `A` to `H` with their own hex values in the legend. Keep each sprite's legend to **16 colours or fewer**, and say so if you need more. Look at `docs/design/snake-art.md` section 0 for how that file lays it out: we paste the result into code with no decisions left.

## The rules, so the screens make sense

The game logic is **the original's, kept as it is**; the full rules and every number are in `docs/design/footballmanager-rules.md`. What matters for the art:

- **The league.** Four divisions of 16 clubs (64 clubs). You start in the **fourth**. A season is **15 league matches** (each other club once, home and away alternating) plus an **8 round FA Cup** that you stay in until you lose. Win 3 points, draw 1. At the end of the season the **top 3 are promoted and the bottom 3 are relegated**, and you get prize money for your position.
- **The squad** is **16 players at most**, drawn from a pool of **24 named players** (8 defenders, 8 midfielders, 8 forwards). Each has a **name**, a **position**, a **skill from 1 to 5**, an **energy from 1 to 20** and a state (fit or injured). A starting 11 plus a reserve are picked, and the week's other players rest. **Energy falls by one for a player who plays and rises by ten for one who rests.** Injured players cannot be picked or sold.
- **Picking the team.** The player picks **11 players**. The team shows five numbers beside the opponent's, **Energy, Morale, Defence, Midfield, Attack**, each from 1 to 20, so the screen is a **two column comparison** of five bars.
- **The match** is decided by those five numbers against the opponent's, with luck, and **the player cannot affect it**. It is played as a series of **attacks**: a ball is dribbled up the pitch toward a goal, may be blocked by a defender, may be saved by the keeper, or goes in. Each attack is **one highlight**: the pitch view with the ball running, then a **goal mouth close up** for the shot. Up to about **12 attacks** happen in a match, so a match is **20 to 40 seconds** of highlights, with a skip key. The score, the club names and the running attack count are always on view.
- **The week.** One week is one fixture: **menu** (sell players, loan, repay, status, change level, save), **pick the team**, **the match**, **the result and the money report** (gate, wages, rent, interest, the balance), **the table**, then **one transfer offer**. A **status bar** shows the week, the division, the cash, the loan and the morale.
- **Money.** The player earns **gate receipts** every fixture (more after wins at home, less after defeats, a payment from the opposition's standing when away), pays a **weekly wage bill** for every player owned, a **ground rent** and **1% a week interest** on a bank loan. There is a loan limit per division (250,000 times 1 to 4, rising as you go up). **Going over the loan limit ends the game.** There are **no ground improvements** in this game.
- **Transfers.** After each match **one player** from the pool who is not yours is offered, with a name, a position, a skill and a value. The player types a **bid**, and the club accepts or refuses (a refusal raises the price by a fifth). The player may also **sell** a squad member to an offer of the club's choosing. Show **one player at a time**, not a list.
- **The cup.** 8 rounds against clubs from lower and then higher divisions, the last two the **semi-final** and the **final**, with big gate receipts. A draw is replayed. Show it as **a round number and a name of the round** (a bracket is not needed).
- **Game ending.** The only failure is **going over the loan limit** (the manager is sacked). There is no final win: the game goes on for as many seasons as the player likes, and the table and the **trophy cabinet** (seasons won, cups won) are the reward.

## What we need from you

### 1. Art direction and palette
A name and a one paragraph idea for the look, and a **palette** as a table of names and hex values: the background, panels and borders, the text (normal, dim, highlighted, warning), the table (stripes, your club's row, promotion and relegation zones), the pitch (two greens for mowing stripes, lines), the kits (home, away, keeper, referee, each with 5 tones), the ball, the goal and net, the stands and crowd, the money colours (credit, debt) and the energy and morale bars.

It should be a **sibling of the other games, but its own thing** (and **true to the feel of the original**: a table heavy, text led look). The nearest ones are Lantern Glass (Tetris and Snake: dark navy, one amber lamp, glassy jewel colours), Space Invaders (neon pink, violet and cyan on indigo), Moonlit Bed (Centipede), Skylark (Xevious), Dusk Lamps (Cuber) and the ASCII look of Rogue. Please do not reuse those palettes. Say which colours are the same on purpose across things (for example "everything that costs you money has the same red").

### 2. The scenery
- **The match pitch**: drawn once as the background (a mown grass pattern, the lines, the two penalty areas and the centre circle, the goals, a strip of stand and crowd above and below). Show it seen from the side at a slight angle, or from above, your choice. **The ball runs on a grid of cells**, we suggest **32 columns by 20 rows of cells of 8 by 8 pixels** (256 x 160), with the two goals at the ends, and the 22 figures standing on cells. Say if another size suits the look better, and say how a cell maps to a point on the pitch.
- **The goal mouth** close up, shown after the ball reaches the end of an attack: the goal frame, the net (a pattern, with a **ripple** frame for a goal), the grass in front, the crowd behind. The game has already decided the result (**goal, saved, blocked or wide**), so the picture only has to show it: the keeper **dives to one of nine places** (a 3 by 3 grid of target points) and the ball arrives at a point that is **inside the net, in the keeper's hands, or outside the frame**. Design **3 poses** (ready, dive left, dive right) plus the ball at a given point.
- **The menu backdrops**: a panel style (border, title bar, a row highlight, a scroll arrow), one **backdrop for the title** and a **neutral backdrop for the table screens**. These can be rich, but darker and less saturated than the text so numbers stay readable.
- **The stands and crowd** (a strip of 8 pixel high coloured dots that can cheer: 2 frames).

### 3. Sprites (frame lists, with the sizes above)

| Sprite | Size | Frames and notes |
|---|---|---|
| Figure, standing | 8 x 12 | right, in each of the 4 kits |
| Figure, running | same | right, 4 frames (the game mirrors for left) |
| Figure, kicking | same | right, 2 frames |
| Figure, celebrating | same | arms up, 2 frames |
| Goalkeeper, ready, diving, saved | same, a larger diving pose of up to 12 x 12 | ready (2), dive left (2), dive right (2), got it (1) |
| Referee | 8 x 12 | standing, running (2) |
| Ball | 5 x 5 | rolling (2), in the air (1), a shadow (1) |
| Goal mouth keeper | up to 24 x 32 | ready, dive left, dive right, high dive left, high dive right (the close up) |
| Goal mouth ball | up to 10 x 10 | 3 sizes as it comes at the viewer, and the net ripple (3 frames) |
| Badges | 16 x 16 | 8 different club badges |
| Faces | 24 x 24 | 6 to 10 faces, reused |
| Position icons | 8 x 8 | goalkeeper, defender, midfielder, forward |
| State icons | 8 x 8 | injured (a plaster or a cross), suspended (a card), tired, in form |
| Bars | any | energy and morale: empty, full, and a marker, in 3 warning levels |
| Money icons | 8 x 8 | coin, bank, loan, stadium, wage packet |
| Trophy | about 32 x 32 | the league cup, plus a smaller one for the cabinet |
| Cursor | 8 x 8 | a pointing hand or an arrow, 2 frames |
| Event icons | 8 x 8 | goal, yellow card, red card, substitution, injury, whistle |

Two points: **every frame must fit its size** (or you say how much it overhangs), and the frame lists above are a **minimum**. If a figure needs an anticipation frame, add it and say where it would be used.

### 4. Screen layouts on the canvas
Give each screen as a list of "this text or sprite, in this colour, at this x and y" (origin at the top left), with the **font and its scale**:

- **Title / attract screen**: the name, a hint line (the controls), a blinking PRESS SPACE, and a short intro (a few frames of figures running a ball in, a kick, a goal). A short animation is welcome (the game can play a sequence of frames on a timer; say how many pixels of the picture change).
- **New game** (three short screens): the manager's name (up to 20 characters), **pick a club** (a list of 16 per page, 4 pages, one for each division), the **level** from 1 to 7 (Beginner, Novice, Average, Good, Expert, Super Expert, Genius), and **the kit colour** (black or white). The 12 starting players are dealt at random, so the game only shows the squad.
- **Status bar** (on every screen): week, division, bank, loan, and the club's name.
- **The squad screen**: 16 rows of name, position icon, skill (1 to 5, with a bar or stars), energy (1 to 20 with a bar), state icon, value. A cursor and a way to mark who is picked.
- **The pick the team screen**: the squad with the picked marks, the five team numbers (Defence, Midfield, Attack, Energy, Morale) as bars, and the formation (4-4-2 or similar, drawn as a small pitch of dots).
- **The fixtures and results** screen: this week's fixtures with last week's results.
- **The league table**: a table of 16 rows (position, badge, name, played, won, drawn, lost, goals, points), with promotion and relegation zone markers and your club highlighted. Give the **column x positions** and the font.
- **The match screen**: the pitch with 22 figures, the ball, the score bar (clubs, score, minute), a **ticker** line for the last event, and the **goal mouth close up** shown for each chance. Give the layout of the pitch and the score bar, and the **positions of the 22 figures** in a standard formation.
- **Half time and full time**: a result panel with the scorers and a stats bar (shots, chances).
- **The money screen**: gate receipts, wages, interest, other, balance, a loan and repay control, a **small graph or ten week bar chart** of the balance (a pixel bar chart is fine).
- **The transfer offer**: one player (name, position, skill, value), a **bid** control and a **result of the bid** panel (accepted, refused, price up).
- **Sell a player**: pick one of yours and the offer shown (accept or refuse).
- **The cup round** screen (the round's name and the drawn club), the **end of season** screen (position, prize money, promoted, relegated or neither), the **sacked** screen (loan limit passed), the **paused** screen, and the **trophy cabinet**.
- Anything that makes the first five seconds feel special.

### 5. Effects (tell us which are worth it)
Ideas we think are affordable: a short sparkle and a ripple of the net on a goal, the crowd jumping on a goal, the ball trailing 3 dim pixels, a screen shake of the **goal mouth only**, a flashing ticker on a red card, a counting up animation for money (the digits rolling), a bar that pulses when energy is low, a coin shower when the bank moves into profit, a lit star on the table for promotion. Say which you want, which you would drop and what you would add.

## Later screens, so your style can cover them

Only the first screens need finished art now, but **please show one sketch or a short list for each of these** so the look holds together:

- **Divisions**: how the look changes for each of the 4 divisions (a coloured header, a different stand, a different badge border), so the player feels the climb.
- **A bigger ground**: the stand picture at 3 sizes (small, medium, large).
- **A European or friendly match** (optional, for a later version): a banner and a different pitch.
- **A manager's office** (optional): a one screen start page with a desk, a phone and a calendar.

## Before you hand it back (checks)

- Every screen reads at 2x, and the numbers in the tables stay readable.
- Home and away kits, the energy and morale bars and the money states are told apart by shape and pattern as well as colour (run a colour blindness simulator over your preview).
- The player's club row stands out in every table.
- Every figure, icon and badge fits its size, and the origin (for a figure, **the middle of its feet**) is stated for each.
- The ball can always be seen, on the grass, in the air and against the crowd.
- Nothing needs a full screen change every frame.
- Every colour is in the palette table, and every pixel of every sprite is either `.` or in a legend.
- Text has good contrast on every background it sits on.

## How to give it back

One markdown file, **`docs/design/footballmanager-art.md`**, starting with the art direction and the palette, then: the panel styles and scenery as fenced blocks (named, with sizes and legends), every sprite as a fenced block (named, with its size, its origin, its legend and the colour table for tone maps), the animation recipes (frames, timings in milliseconds, how many pixels move), each screen as a list of "this text or sprite, in this colour, at this x and y" with the final column and row positions of the tables, and the effects list with a one line recipe each. Aim for something we can paste into code with no further decisions.

Also give **preview images** drawn at 3x with nearest neighbour scaling: `docs/design/footballmanager-preview.png` (the match screen part way through, with a goal mouth chance inset), the **league table** and **squad** screens (`footballmanager-preview-table.png`, `footballmanager-preview-squad.png`) and, if you can, the title screen (`footballmanager-preview-title.png`). If you want to try a variant, give two and say which you prefer. Say if anything in your design needs a rule of the game to change.

## Context

- **The rules and the code**: nothing exists yet. The rules above are what we plan to build, and **the game follows the original's rules and numbers** (see the rules file), so design for amounts up to **7 digits** and a minus sign. The game is **turn based** (a week at a time) with a short **real time** match highlight, and everything is plain integer arithmetic on small tables, so the screens are drawn from the game's state each time.
- **The nearest house style.** The Cookoff window (the launcher) is dark navy `0A0E16` with an orange accent. The other games' art is in `docs/design/` (`tetris-art.md`, `snake-art.md`, `space-invaders-art.md`, `asteroids-art.md`, `moonpatch-art.md`, `skylark-art.md`, `cuber-art.md`, with previews beside them). Look at `snake-art.md` for how a finished file looks and what level of detail is the right one. **Rogue** is the nearest game for dense screens of text.
- **Sound** is built separately, in the same spirit as the others (chiptune style), so you do not need to design for sound.
