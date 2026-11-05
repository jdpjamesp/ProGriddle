# Skylark: art and screen design, "First Light"

Designer's answer to `xevious-art-brief.md`. Everything here is meant to be pasted into code with no further decisions. Section 9 lists what I decided and the questions the code will still have to answer.

**One change to the brief, on purpose.** The brief asks for a faithful port of a 1982 arcade game. This design keeps the genre, the screen shape, the rules and the feel the brief describes (a vertical scroller over forests, rivers, roads and lines cut in the land, a rapid gun for the air and a bomb on a sight for the ground, hidden targets, a boss core behind four shields, an area bonus), but every name, ship, enemy, target, boss, tile and screen in it is an original design. Each original thing takes the role of one line of the brief's tables (section 3.2), so the rules, timings and point values in the brief map across one to one. Working title: **Skylark**; the ship is the **Lark**.

Previews, all made from the data in this file:

- `skylark-preview.png` (3x): in game, area 3, green land, a wave of Whirls, the sight locked on a Cairn, a bomb on its way, a ground burst with its light on the land, haze, shadows, bullets with bloom.
- `skylark-preview-title.png` (3x): the title over the land, the logo, the land line that lights up, the roll call.
- `skylark-preview-area.png` (2x): the area start marker and the end of area bonus.
- `skylark-preview-over.png` (2x): game over and the pause.
- `skylark-themes.png` (2x): the same moment in four moods across both ground families.
- `skylark-sprites.png` (4x): every sprite in this file. `skylark-tiles.png` (4x): every tile in both families and the three land line designs. `skylark-breakup.png` (6x): the Lark breaking up.
- `skylark-colour-check.png` (2x): the game screen and every danger colour on every ground, as drawn and through deuteranopia, protanopia and tritanopia.

Every grid, tile and preview is made by one small script (`skylark-generator/`, see 9.10), so the pictures and the text cannot disagree.

## 0. Read this first

- The canvas is **224 x 288**: a **16 row score strip** (rows 0 to 15), the **playfield, 224 x 256** (rows 16 to 271) and a **16 row lives strip** (rows 272 to 287). Origin top left; one cell of this file is one canvas cell, shown at 3x (2x on small screens) with nearest neighbour scaling, on the direct colour `PixelCanvas`.
- **Ground**: 14 x 16 tiles of 16 x 16 on screen, plus one row coming in at the top. The map scrolls down the screen by one cell per frame at the normal speed (a tile every 16 frames).
- **Sprite format**: a grid of letters, one line a row. `.` is transparent. Each letter is a named colour from the legend under the grid (section 1). No sprite uses more than 8 colours.
- **Placing**: a sprite is drawn centred on its thing's position: top left at `(x - width / 2, y - height / 2)`. The **box** in each note is in the sprite's own cells, from its top left; where no box is given it is the whole sprite.
- **Facing**: everything faces up the screen as drawn. The Beetle is the one thing that turns: draw it by whole quarter turns (rotate the grid), never by a mirror, so the light stays on the upper left.
- **Light**: from the upper left, always. Every shadow falls down and to the right.
- **Time**: every effect is a function of the frame count since the thing started (60 frames a second), as in Tetris and Snake. Section 4 gives each one.

## 1. Art direction and palette

**First Light.** A survey flight at dawn over a quiet land. The land is soft and matte, in greens and ochres that sit close together so it never fights the action; everything that matters is crisper and more saturated than the land: the Lark is pale and cool, enemies in the air are plum and steel with one green eye, things on the ground are rust and stone with the same green eye, and the only pink in the game is the enemy bullet. The modern part is in the light, not in the detail: a slow haze above the land, a warm glow thrown by explosions, a one cell bloom round shots and the sight, real shadows on the ground. The pixels stay hard edged and the palette stays at 63 colours.

Shared on purpose:

- **Hot** (`FF3D8E`) is every enemy bullet and nothing else. Pink does not occur in the land, so a bullet reads on every ground; its white core (`Hot Core`) carries it where pink alone is weak (on Meadow and Road, see 8).
- **Eye** (`7CFFB4`) is on every enemy, air and ground, and is the Citadel core (the same value is `Core`). Green eye means it can be killed. The **Anvil** has no eye and no plum: it is all iron, the one thing that cannot be killed.
- **Flash** and **Zap** are the same white: the start of every explosion and the player's shot.
- **Glow Light** and **Dawn Top** are the same: the light of explosions and the top of the title gradient. **Haze** and **Foam** are the same pale blue.
- **Signal** is the warning lights on targets, the yellow of fire, and the score.
- The **sight** is one colour (Sight, or Sight Lock when locked) with a one cell **Ink** keyline, which is what makes it read over foam, ochre and forest alike.

**Land**

| Name | Hex | Used for |
|---|---|---|
| Meadow | `6E9A52` | open ground, green areas |
| Meadow Light | `8DB466` | grass tufts, the lit side of ground detail |
| Meadow Dark | `4F7840` | ground speckle, the dark side of tufts |
| Ochre | `C2A260` | open ground, dry areas |
| Ochre Light | `DEC283` | the lit side of dry ground detail, the land lines |
| Ochre Dark | `977A44` | dry ground speckle, the banks of rivers |
| Earth | `6B5236` | bare earth, the road verges, the floor of the land lines |
| Pad | `A9A493` | the stone pads that installations stand on (joints in Stone Dark) |

**Forest**

| Name | Hex | Used for |
|---|---|---|
| Canopy | `2F6440` | the forest roof |
| Canopy Light | `4A8A52` | the lit crowns of trees |
| Canopy Dark | `1F4630` | between the crowns |
| Understory | `13301F` | the dark rim where forest meets open ground |

**Water**

| Name | Hex | Used for |
|---|---|---|
| River | `3C78A8` | river and lake water |
| River Light | `72AAD2` | ripples, the lit glint lines |
| River Dark | `2A5680` | deep water, the shaded bank edge |
| Foam | `D8ECF4` | the white edge where water meets the bank, the sparkle |

**Road**

| Name | Hex | Used for |
|---|---|---|
| Road | `8C877C` | the road surface |
| Road Edge | `5D594F` | the road kerb and the bridge rails |
| Road Line | `EDE3C4` | the dashed centre line |

**The player**

| Name | Hex | Used for |
|---|---|---|
| Hull | `F2F5F8` | the Lark: the lit hull, the bright edge of the wings |
| Hull Mid | `B4C2D2` | the Lark: the hull |
| Hull Dark | `64738C` | the Lark: the shaded hull, the keel |
| Hull Ink | `2A3448` | the Lark: the outline cells and the engine bells |
| Glass | `46D6EE` | the Lark: the canopy (also Zap Glow is its sibling) |
| Wing Mark | `F2A33A` | the Lark: the orange wing marks, the pennant |
| Flame | `FF9A3A` | the thruster flame |
| Flame Hot | `FFF2A8` | the thruster core, the bomb core |
| Zap | `FFFFFF` | the player shot core |
| Zap Glow | `8AF0FF` | the player shot bloom, the hi-score |
| Sight | `B6FFE6` | the sight, normal |
| Sight Lock | `FF4A4A` | the sight over a ground target |

**Air enemies**

| Name | Hex | Used for |
|---|---|---|
| Plum | `7C4EAE` | air enemies: the body |
| Plum Light | `B88EE4` | air enemies: the lit edge |
| Plum Dark | `472A6E` | air enemies: the shade |
| Steel | `D2D0E2` | air enemies: the metal trim |
| Eye | `7CFFB4` | the glowing eye on every enemy, air and ground |
| Iron | `3C3C4C` | the Anvil, the one thing that cannot be killed |
| Iron Light | `8E8EA6` | the Anvil: the lit rim |
| Iron Edge | `1C1C26` | the Anvil: the outline and the bolt holes |

**Ground targets**

| Name | Hex | Used for |
|---|---|---|
| Stone | `D4CBB6` | ground targets: the lit stone |
| Stone Mid | `9E947E` | ground targets: the stone |
| Stone Dark | `5E5646` | ground targets: the shade |
| Rust | `C4583A` | ground targets: the painted panels |
| Rust Light | `EC8C5C` | ground targets: the lit paint |
| Rust Dark | `7C3022` | ground targets: the dark paint, the barrels |
| Signal | `FFD64A` | warning lights, the fire yellow, the score |

**Danger**

| Name | Hex | Used for |
|---|---|---|
| Hot | `FF3D8E` | every enemy bullet, nothing else is this colour |
| Hot Core | `FFE4F0` | the centre of an enemy bullet |

**Explosions**

| Name | Hex | Used for |
|---|---|---|
| Flash | `FFFFFF` | the first frame of every explosion (same value as Zap) |
| Fire | `FF8A2A` | the body of a fire ball |
| Fire Dark | `C8402A` | the outer flame |
| Smoke | `5C4C48` | smoke and flying debris |
| Scorch | `2C231B` | the burnt ground left behind |
| Scorch Edge | `4D3E2C` | the ragged rim of a scorch |
| Glow Light | `FFE2A6` | the light an explosion throws on the land (a tint) |

**Boss**

| Name | Hex | Used for |
|---|---|---|
| Shell | `6C7C98` | the Citadel: the hull |
| Shell Light | `AEBED6` | the Citadel: the lit plates |
| Shell Dark | `3A4560` | the Citadel: the shade and the seams |
| Core | `7CFFB4` | the Citadel core (same value as Eye, on purpose) |
| Core Dark | `1E7A5C` | the Citadel core: the ring round the eye |

**Text and strip**

| Name | Hex | Used for |
|---|---|---|
| Strip | `0D1522` | the score and lives strips, the pause veil |
| Ink | `0A1018` | outlines of text, the shadow tint |
| Text | `F4EFE2` | all ordinary text |
| Text Dim | `8A95AA` | labels and second rank text |
| Dawn Top | `FFE2A6` | the title gradient: the top (same value as Glow Light) |
| Dawn Low | `F2764E` | the title gradient: the bottom |
| Haze | `D8ECF4` | the parallax haze, a tint (same value as Foam) |

That is 67 names and 63 distinct values (the limit is 64).

The enum `XeviousTint` in the brief becomes one member per name above, in this order (spaces dropped: `MeadowLight`, `HullInk`, ...). Tints (shadow, haze, light, the mood of an area) are passes that mix the cell under them toward a named colour by a fixed amount; they are not palette entries of their own.

## 2. The ground

### 2.1 How the tiles fit

A tile is 16 x 16 letters. The letters are kept abstract so that **one tile serves both ground families**:

| Letter | Green family | Dry family |
|---|---|---|
| `g` | Meadow `6E9A52` | Ochre `C2A260` |
| `l` | Meadow Light `8DB466` | Ochre Light `DEC283` |
| `d` | Meadow Dark `4F7840` | Ochre Dark `977A44` |
| `e` | Earth `6B5236` | the same |
| `p` | Pad `A9A493` | the same |
| `s` | Stone Dark `5E5646` | the same |
| `c` | Canopy `2F6440` | the same |
| `k` | Canopy Light `4A8A52` | the same |
| `n` | Canopy Dark `1F4630` | the same |
| `u` | Understory `13301F` | the same |
| `w` | River `3C78A8` | the same |
| `r` | River Light `72AAD2` | the same |
| `v` | River Dark `2A5680` | the same |
| `f` | Foam `D8ECF4` | the same |
| `a` | Road `8C877C` | the same |
| `b` | Road Edge `5D594F` | the same |
| `y` | Road Line `EDE3C4` | the same |
| `h` | Ochre Light `DEC283` | the same |

The joins:

- **Open ground** (`open_1` to `open_3`) joins anything. Pick a variant by a hash of the tile's map position, so the land never repeats in a way the eye catches.
- **Forest** is a corner set. Each map **corner** (the point where four tiles meet) is forest or not; a tile is chosen by its four corners (nw, ne, sw, se). Fifteen tiles cover every case (`forest_nw` ... `forest_full`; all four corners open is open ground). Two tiles side by side share the two corners on their join, so the edge always meets: the check in section 8 found every possible pair agreeing on all 16 cells of the join. The rim of the forest is lit (Canopy Light) where the open ground is above or left of it and dark (Understory) where it is below or right, and the ground just below and right of the trees is a shade darker, so the forest stands up off the land. `forest_full_2` is the same roof with the crowns moved 5 cells; use it for a third of the full tiles.
- **Rivers** and **roads** are path tiles: the water or the road meets the **middle 8 cells** of each edge it leaves by (`river_ne` leaves by the north and east edges). A river is 8 cells of water with Foam at its edge and an Earth bank outside that; bends are quarter circles. A road is 6 cells of Road, a Road Edge cell each side and an Earth verge; its centre line is dashed 4 on, 4 off, in step across tiles because the dash pattern is counted from the tile's own edge.
- **Bridges** are where a road crosses a river (`bridge_ns`: road north to south over a river east to west).
- **Pads** (`pad`) are open ground with a stone slab. The bigger installations stand on one.
- **Land lines** are 32 x 32 designs cut into open ground, made of four tiles each, quartered nw, ne, sw, se. Their lines are Ochre Light with an Earth cell below and right, in both families.
- There is **no sea or void** at the edge: the map is 14 tiles wide and fills the screen.

### 2.2 The tiles

#### open_1 (16 x 16)

Joins anything on every side.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
gggggdgggggggglg
ggggggglggggggdg
gggggggldggggggg
ggggggglggggllgg
gggggggdlgggddgg
ggggggggdggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
gglggggggggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### open_2 (16 x 16)

Joins anything on every side.

```
gggggggggggggggg
gggggdgggglggggg
ggglggggggdggggg
gggdgggggggggggg
ggggllgdgggggggg
ggggddgggggggggg
gggggggggggggggg
glllglllgldlglll
gdgdgggggglgggdg
dggggdggggdggggg
dgggggdgggggglgg
gglggggggggggdgg
ggdgdggggggggggg
gggggggglggggggg
ggggggggdggggggg
gggggggggggggggg
```

#### open_3 (16 x 16)

Joins anything on every side.

```
ggdgggggggggggdg
gggggggggggggggg
ggggggggggdglggg
ggggggggggggeggg
gggglggggggggggg
ggggeggglggggggg
ggglggggdggggglg
ggldgggggglglgdg
ggdgggggggdgdlgg
ggggggggggglgdgg
ggggggggggldgggg
gglggggglgeelggg
ggdgggggdgggdggg
gggggglggggggdgg
ggggggdggggggggg
gggggggggggggggg
```

#### forest_se (16 x 16)

Corners se are forest; an edge joins a tile whose two corners on that edge match.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
gggggdgggggggglg
ggggggglggggggdg
gggggggldggggggg
ggggggglggggllgg
gggggggdlgggddud
ggggggggdggdggdk
gglggggggggggguc
ggdggggggggukudk
ggggggggguddkckn
gglggggggdkkkkcn
gglgggggukccccnn
ggdgggggdkcccnnc
ggggggggkcnnnnck
```

#### forest_sw (16 x 16)

Corners sw are forest; an edge joins a tile whose two corners on that edge match.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
gggggdgggggggglg
ggggggglggggggdg
gggggggldggggggg
ggggggglggggllgg
gggggggdlgggddgg
kudgggggdggdgggg
kudgudgggggggggg
cudkuudggggggggg
cckudkudgggggggg
nccnkuddgggdgggg
nnnnckuudggggggg
cknncududggggggg
kkcnnckudggggggg
```

#### forest_swse (16 x 16)

Corners sw/se are forest; an edge joins a tile whose two corners on that edge match.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
gggggdgggggggglg
ggggggglggggggdg
gggggggldggggggg
ggggudglgggudlgg
gudgddgdluddkkud
kududkududukcuck
kkkcknuddudkudkc
cccccnnkknknnkcc
ccccnnnnnnckkcnn
nccnnckkcnckkkcn
nnnnckkkccccccnn
cknnckkccccccnnc
kkcnncccccnnnnck
```

#### forest_ne (16 x 16)

Corners ne are forest; an edge joins a tile whose two corners on that edge match.

```
gdggggggkkkcnnck
ggggggggukkccnck
ggggggggduuccnck
gggggdgggdduunnc
ggggggglgguddknn
gggggggldgddkukk
ggggggglggguudkk
gggggggdlggduuuu
ggggggggdggddddd
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
gglggggggggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### forest_nese (16 x 16)

Corners ne/se are forest; an edge joins a tile whose two corners on that edge match.

```
gdggggggkkkcnnck
gggggggukkkccnck
gggggggdkkcccnck
gggggdggkcccnnnc
ggggggglucccnnnn
gggggggudknnnckk
gggggggddkcnckkk
gggggggdkccnckkc
ggggggggucnncccc
gglggguddknnnccc
ggdgggddunnnnncc
gggggggudkckkcnn
gglggggddkckkkcn
gglggguukcccccnn
ggdgggddkccccnnc
ggggggggkcnnnnck
```

#### forest_nesw (16 x 16)

Corners ne/sw are forest; an edge joins a tile whose two corners on that edge match.

```
gdggggggkkkcnnck
gggggggukkkccnck
gggggggdkkcccnck
gggggdggkcccnnnc
gggggggluccunnnn
gggggududkudkukk
gggguudddkuuudkk
gudgdddduuddkkuu
kudgguuddduuuudd
kkkkududggddddud
ccccukududguuddd
cccudkuududdddgg
nccnkuddddudgggg
nnnnckkkudddgggg
cknnckkuddgggggg
kkcnnccudggggggg
```

#### forest_neswse (16 x 16)

Corners ne/sw/se are forest; an edge joins a tile whose two corners on that edge match.

```
gdggggggkkkcnnck
gggggggkkkkccnck
gggggguckkcccnck
gggggddkccccnnnc
ggggggknccccnnnn
gggudkckkcnnnckk
gggdkckkkccnckkk
gkkknckkcccnckkc
kkcnncccccnncccc
kkccnnccccnnnccc
cccccnnccnnnnncc
ccccnnnnnnckkcnn
nccnnckkcnckkkcn
nnnnckkkccccccnn
cknnckkccccccnnc
kkcnncccccnnnnck
```

#### forest_nw (16 x 16)

Corners nw are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnnudggggggg
ckkkccnudggggggg
ckkccuuddggggggg
cccuudddgggggglg
ncudddglggggggdg
nududggldggggggg
udddudglggggllgg
uudgddgdlgggddgg
dddgggggdggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
gglggggggggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### forest_nwse (16 x 16)

Corners nw/se are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnnudggggggg
ckkkccnuudgggggg
ckkcccuddudggggg
cccccuduuddggglg
ncccududuudgggdg
nncududududggggg
nnudkudddududlgg
ukuuudddluddkkud
duddduududukcuck
gddgududdddkudkc
ggduuuddukunnkcc
gggdduuududkkcnn
gglggddddkkkkkcn
gglggguukcccccnn
ggdgggddkccccnnc
ggggggggkcnnnnck
```

#### forest_nwsw (16 x 16)

Corners nw/sw are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnnudggggggg
ckkkccncudgggggg
ckkcccuududggggg
cccccududddggglg
nccccnuddgggggdg
nnccnudududggggg
nnnnncuddddgllgg
cknnnudududgddgg
kkcnncudddddgggg
kkccnnudgggggggg
cccccnnkudgggggg
ccccnnnududggggg
nccnnckuddddgggg
nnnnckkkudgggggg
cknnckkuddgggggg
kkcnnccudggggggg
```

#### forest_nwswse (16 x 16)

Corners nw/sw/se are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnnudggggggg
ckkkccncudgggggg
ckkcccnckudggggg
cccccnnccudggglg
nccccnnnccudggdg
nnccnnckkcudgggg
nnnnnckkkcckudud
cknnnckkcccnckud
kkcnncccccnnccck
kkccnnccccnnnccc
cccccnnccnnnnncc
ccccnnnnnnckkcnn
nccnnckkcnckkkcn
nnnnckkkccccccnn
cknnckkccccccnnc
kkcnncccccnnnnck
```

#### forest_nwne (16 x 16)

Corners nw/ne are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnncckkcnnck
ckkkccnckkkccnck
ckkcccnckkcccnck
cccccnncccccnnnc
nccccnnnccccnnnn
nncunnckkcnnnckk
nnudkuukkcuuckkk
ukuuudduuudduuuu
duddduuddduddddd
gddgududggddggud
ggdgddddggggggdd
gggggggggggggggg
gglggggggggdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### forest_nwnese (16 x 16)

Corners nw/ne/se are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnncckkcnnck
ckkkccnckkkccnck
ckkcccnckkcccnck
cccccnncccccnnnc
nccccnnnccccnnnn
nnccnnckkcnnnckk
nnnnnckkkccnckkk
ukunnckkcccnckkc
duduncccccnncccc
guddknccccnnnccc
gdduunnccnnnnncc
gggddkunnnckkcnn
gglggudkcnckkkcn
gglggdukccccccnn
ggdgggducccccnnc
gggggggdkcnnnnck
```

#### forest_nwnesw (16 x 16)

Corners nw/ne/sw are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnncckkcnnck
ckkkccnckkkccnck
ckkcccnckkcccnck
cccccnncccccnnnc
nccccnnnccccnnnn
nnccnnckkcnnnckk
nnnnnckkkccnckkk
cknnnckkcccnckuu
kkcnncccccnnuudd
kkccnnccccnuddud
cccccnnccnuuuddd
ccccnnnnnuddddgg
nccnnckkcnudgggg
nnnnckkkcuddgggg
cknnckkcuddggggg
kkcnnccuddgggggg
```

#### forest_full (16 x 16)

Corners nw/ne/sw/se are forest; an edge joins a tile whose two corners on that edge match.

```
nckkcnncckkcnnck
ckkkccnckkkccnck
ckkcccnckkcccnck
cccccnncccccnnnc
nccccnnnccccnnnn
nnccnnckkcnnnckk
nnnnnckkkccnckkk
cknnnckkcccnckkc
kkcnncccccnncccc
kkccnnccccnnnccc
cccccnnccnnnnncc
ccccnnnnnnckkcnn
nccnnckkcnckkkcn
nnnnckkkccccccnn
cknnckkccccccnnc
kkcnncccccnnnnck
```

#### forest_full_2 (16 x 16)

A variant of forest_full (the crowns shifted 5 cells).

```
nncckkcnncknckkc
cnckkkccnckckkkc
cnckkcccnckckkcc
nncccccnnncccccc
nnnccccnnnnncccc
nckkcnnnckknnccn
ckkkccnckkknnnnn
ckkcccnckkccknnn
cccccnncccckkcnn
nccccnnnccckkccn
nnccnnnnnccccccc
nnnnnckkcnnccccn
ckkcnckkkcnnccnn
kkkccccccnnnnnnc
kkccccccnnccknnc
cccccnnnnckkkcnn
```

#### river_ns (16 x 16)

Water meets the middle 8 cells of the N/S edges.

```
gdeffwrvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvrwffelg
ggeffwwrvwwffedg
ggeffrwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwrffegg
ggeffwwvrwwffegg
ggeffwrvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvrwffegg
ggeffwwrvwwffegg
ggeffrwvvwwffegg
ggeffwwvvwwffegg
```

#### river_ew (16 x 16)

Water meets the middle 8 cells of the E/W edges.

```
gdgggggggggggggg
gggggggggggggggg
eeeeeeeeeeeeeeee
ffffffffffffffff
ffffffffffffffff
wwwwwrwwwwwwwwrw
wwwrwwwwwwwwrwww
vrvvvvvvvvrvvvvv
vvvvvvvvrvvvvvvv
wwwwwwrwwwwwwwwr
wwwwrwwwwwwwwrww
ffffffffffffffff
ffffffffffffffff
eeeeeeeeeeeeeeee
ggdggggggggggggg
gggggggggggggggg
```

#### river_ne (16 x 16)

Water meets the middle 8 cells of the N/E edges.

```
gdeffwrvvwwwfegg
ggeffwwvvwwwfedg
ggdefwwvvvwrffee
ggdefwwvvrwwwfff
ggdefwwrvvvwwwww
gggdefwwwvvvwwrw
gggdeffwwvvvrvww
ggggdefwwwrvvvvv
ggggdeefwwwwvvvv
gglggdeeffwwwwwr
ggdgggdeeffwwrww
gggggggddeefffff
gglggggggddeeeff
gglggggggggdddee
ggdggggggggggggg
gggggggggggggggg
```

#### river_nw (16 x 16)

Water meets the middle 8 cells of the N/W edges.

```
gdefwwrvvwwffegg
gdefwwwvvwwffegg
eeffwwvvvwwfedgg
fffwwwvvvrwfedlg
wwwwwvvrwwwfeddg
wwwwvrvwwwfedggg
wwvrvvvwwffellgg
vrvvvwwwwfedddgg
vvvvwwwwfeedgggg
wwwwwwffeedggggg
wwwwwffeedgggggg
fffffeeddggggggg
ffeeeddggggdgggg
eelddggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### river_se (16 x 16)

Water meets the middle 8 cells of the S/E edges.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggdddee
gggggdgggddeeeff
gggggggldeefffff
ggggggdeeffwwwrw
gggggdeeffwwrwww
ggggdeefwwrwvvvv
ggggdefwrwwvvvvv
ggldeffwwvvvvvwr
ggddefwwwvvvwrww
ggdefwwwvvvrwwww
gglefwwvvrwwwfff
gglefwwrvvwwffee
ggeffrwvvwwwfedg
ggeffwwvvwwwfegg
```

#### river_sw (16 x 16)

Water meets the middle 8 cells of the S/W edges.

```
gdgggggggggggggg
gggggggggggggggg
eedddggggggggggg
ffeeeddggggggglg
fffffeeldgggggdg
wwwwwffeedgggggg
wwwrwwffeedgllgg
vrvvwwwwfeedddgg
vvvvvwwwwfedgggg
wwvvvvrwwffedggg
wwwwrvvwwwfedggg
wwrwwvvvwwwfedgg
fffwwwvvvrwfedgg
eeffwwvrvwwfedgg
gdefwrwvvwwffegg
ggefwwwvvwwffegg
```

#### river_ns_2 (16 x 16)

A variant of river_ns.

```
ggeffwwvvwwffegg
ggeffwwvvwrffegg
ggeffwwvrwwffegg
ggeffwrvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvrwffegg
gleffwwrvwwffell
gdeffrwvvwwffedg
dgeffwwvvwwffegg
dgeffwwvvwrffegg
ggeffwwvrwwffegg
ggeffwrvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvrwffegg
```

#### river_ns_3 (16 x 16)

A variant of river_ns.

```
ggeffwwvvrwffedg
ggeffwwrvwwffegg
ggeffrwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwrffegg
ggeffwwvrwwffegg
ggeffwrvvwwffelg
ggeffwwvvwwffedg
ggeffwwvvwwffegg
ggeffwwvvrwffegg
ggeffwwrvwwffegg
ggeffrwvvwwffegg
ggeffwwvvwwffegg
ggeffwwvvwrffegg
ggeffwwvrwwffegg
ggeffwrvvwwffegg
```

#### road_ns (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/S edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
gggebaayaaabeglg
gggebaayaaabegdg
gggebaaaaaabeggg
gggebaaaaaabllgg
gggebaaaaaabddgg
gggebaaaaaabeggg
gglebaayaaabeggg
ggdebaayaaabeggg
gggebaayaaabeggg
gglebaayaaabeggg
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_ew (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the E/W edges.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
eeeeedeeeeeeeele
bbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
ayyyyaaaayyyyaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbb
eeleeeeeeeedeeee
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### road_ne (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/E edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
gggebaayaaabeele
gggebaaaaaabbbbb
gggebaaaaaaaaaaa
gggebaaaaaaaaaaa
gggebaaaaaaayaaa
gggebaaaaaaaaaaa
gglebaaaaaaaaaaa
ggdgebaaaaaaaaaa
ggggeebbbbbbbbbb
gglgggeeeeedeeee
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### road_nw (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/W edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
eeeebaayaaabeglg
bbbbbaaaaaabegdg
aaaaaaaaaaabeggg
aaaaaaaaaaabllgg
ayyyaaaaaaabddgg
aaaaaaaaaaabeggg
aaaaaaaaaaabeggg
aaaaaaaaaabegggg
bbbbbbbbbbeegggg
eeleeeeeeegdgggg
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### road_se (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the S/E edges.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
gggggdeeeeeeeele
ggggeebbbbbbbbbb
ggggebaaaaaaaaaa
gggebaaaaaaaaaaa
gggebaaaaaaayaaa
gggebaaaaaaaaaaa
gglebaaaaaaaaaaa
ggdebaaaaaaaaaaa
gggebaaaaaabbbbb
gglebaayaaabeeee
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_sw (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the S/W edges.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
eeeeedeeeegggglg
bbbbbbbbbbeeggdg
aaaaaaaaaabegggg
aaaaaaaaaaabllgg
ayyyaaaaaaabddgg
aaaaaaaaaaabeggg
aaaaaaaaaaabeggg
aaaaaaaaaaabeggg
bbbbbaaaaaabeggg
eelebaayaaabeggg
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_t_e (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/S/E edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
gggebaayaaabeele
gggebaaaaaabbbbb
gggebaaaaaaaaaaa
gggebaaaaaaaaaaa
gggebaaaaaaayaaa
gggebaaaaaaaaaaa
gglebaaaaaaaaaaa
ggdebaaaaaaaaaaa
gggebaaaaaabbbbb
gglebaayaaabeeee
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_t_w (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/S/W edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
eeeebaayaaabeglg
bbbbbaaaaaabegdg
aaaaaaaaaaabeggg
aaaaaaaaaaabllgg
ayyyaaaaaaabddgg
aaaaaaaaaaabeggg
aaaaaaaaaaabeggg
aaaaaaaaaaabeggg
bbbbbaaaaaabeggg
eelebaayaaabeggg
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_t_n (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the E/W/N edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
eeeebaayaaabeele
bbbbbaaaaaabbbbb
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
ayyyaaaaaaaayaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbb
eeleeeeeeeedeeee
gglggggggggggggg
ggdggggggggggggg
gggggggggggggggg
```

#### road_t_s (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the E/W/S edges.

```
gdgggggggggggggg
gggggggggggggggg
gggggggggggggggg
eeeeedeeeeeeeele
bbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
ayyyaaaaaaaayaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
bbbbbaaaaaabbbbb
eelebaayaaabeeee
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### road_cross (16 x 16)

Road meets the middle 8 cells (6 road, 2 edge) of the N/S/E/W edges.

```
gdgebaaaaaabeggg
gggebaayaaabeggg
gggebaayaaabeggg
eeeebaayaaabeele
bbbbbaaaaaabbbbb
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
ayyyaaaaaaaayaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
bbbbbaaaaaabbbbb
eelebaayaaabeeee
gglebaaaaaabeggg
ggdebaaaaaabeggg
gggebaaaaaabeggg
```

#### bridge_ns (16 x 16)

A road going N/S over a river going E/W.

```
gggbaaaaaaaabggg
gggbaaayaaaabggg
eeebaaayaaaabeee
ffbbaaayaaaabbff
fffbaaayaaaabfff
wwwbaaaaaaaabwww
wwwbaaaaaaaabwww
vwvbaaaaaaaabvvv
vvvbaaaaaaaabvvv
wwwbaaayaaaabwww
wwwbaaayaaaabwww
fffbaaayaaaabfff
ffbbaaayaaaabbff
eeebaaaaaaaabeee
gggbaaaaaaaabggg
gggbaaaaaaaabggg
```

#### bridge_ew (16 x 16)

A road going E/W over a river going N/S.

```
ggeffwwvvwwffegg
ggeffwwwvwwffegg
ggebfwwvvwwfbegg
bbbbbbbbbbbbbbbb
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
ayyyyaaaayyyyaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
aaaaaaaaaaaaaaaa
bbbbbbbbbbbbbbbb
ggebfwwvvwwfbegg
ggeffwwvvwwffegg
ggeffwwvvwwffegg
```

#### pad (16 x 16)

Joins open ground on every side; the base of every ground installation.

```
gdgggggggggggggg
glllllllllllllsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glsssssssssssssg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
glpppppsppppppsg
gssssssssssssssg
ggdddddddddddddd
```

### 2.3 The land lines (32 x 32 each, four tiles)

#### lines_spiral (32 x 32)

A spiral of two and a half turns. Cut it into `lines_spiral_nw`, `_ne`, `_sw` and `_se`.

```
gdgggggggggggggggdgggggggggggggg
gggggggggggggggggggggggggggggggg
gggggggggggggggggggggggggggggggg
gggggdgggggggglggggggdgggggggglg
ggggggglggggggdhhhheggglggggggdg
gggggggldgghhhhhhhhhhheldggggggg
ggghheglgghhhhhhhhhhhhhhegggllgg
gghhhegdlhhhheeeeeeehhhhheggddgg
gghhhegghhheegggggggeehhhhedgggg
gghhegghhheggggggglgggehhhhegggg
ghhhegghheggghhhhhhhhegehhhheggg
ghhegghhhegghhhhhhhhhhegehhheggg
ghhegghhegghhhheeeehhhhegehheggg
ghhegghhegghhheggglehhhegghhhegg
ghhegghhegghheggggdgehhheghhhegg
ghhegghhegghheggghheghhhegehhegg
ghhegghhegghhhegghhegehhegghhegg
ghhegghhegghhhhehhhegghhegghhegg
ghhegghhhegehhhhhhheghhhegghhegg
ghhhedhhheggehhhhhegghhegghhhelg
ghhhegehhheggeeeeegghhhegghhegdg
gehhheghhhheggggggghhhhedhhheggg
gghhhegehhhhheggghhhhhelghhhelgg
ggehhhedeehhhhhhhhhhhegdhhheddgg
ggghhhhedgeehhhhhhheegghhhhegggg
gglehhhhegggeeeeeeeggghhhheggggg
ggdgehhhhhegggggggdgghhhhegggggg
gggggeehhhhheggggghhhhhheggggggg
gglggggehhhhhhhhhhhhhheegggdgggg
gglgggggeeehhhhhhhhheegggggggggg
ggdggggggggeeeeeeeeegggggggggggg
gggggggggggggggggggggggggggggggg
```

#### lines_sunwheel (32 x 32)

A ring with eight rays and a dot in the middle. Cut it into `lines_sunwheel_nw`, `_ne`, `_sw` and `_se`.

```
gdgggggggggggggggdgggggggggggggg
gggggggggggggggggggggggggggggggg
gggggggggghheggggggghheggggggggg
gggggdgggghheglggggghheggggggglg
ggggggglgghhegdggggghhelggggggdg
gggggggldghhheggggghhheldggggggg
ggggggglggehheggggghheglggggllgg
gggggggdlgghheggggghhegdlgggddgg
ggggggggdggehhhhhhhhegggdggdgggg
gglgggggggghhhhhhhhhhegggggggggg
gghhhheggghhhheeeehhhheggghhhheg
gghhhhhhehhhheggggehhhhehhhhhheg
ggeeehhhhhhheggggglehhhhhhheeegg
gglggeeehhhegghhhhegehhheeeggggg
ggdggggghhegghhhhhhegehheggggggg
gggggggghhegghhhhhhegghheggggggg
gdgggggghhegghhhhhhegghheggggggg
gggggggghhegghhhhhhegghheggggggg
gggggggghhhegehhhhegghhheggggggg
ggggghhhhhhhegeeeegghhhhhhhegglg
gghhhhhhehhhhedgggghhhhehhhhhheg
gghhhheedehhhheggghhhheleehhhheg
ggeeeeglggehhhhhhhhhheglggeeeegg
gggggggdlggehhhhhhhheggdlgggddgg
ggggggggdgghheeeeeehheggdggdgggg
gglgggggggghhegggglhhegggggggggg
ggdggggggghhheggggdhhheggggggggg
gggggggggghheggggggehheggggggggg
gglggggggghheggggglghheggggdgggg
gglggggggghheggggglghheggggggggg
ggdgggggggeeggggggdgeegggggggggg
gggggggggggggggggggggggggggggggg
```

#### lines_lark (32 x 32)

The game's own mark: a bird from above with swept wings and a forked tail. It is also the mark that lights up on the title screen. Cut it into `lines_lark_nw`, `_ne`, `_sw` and `_se`.

```
gdgggggggggggggggdgggggggggggggg
gggggggggggggggggggggggggggggggg
ggggggggggggggghhegggggggggggggg
gggggdgggggggglhhheggdgggggggglg
ggggggglgggggghhhhegggglggggggdg
gggggggldggggghhhheggggldggggggg
ggggggglgggglhhhhhheggglggggllgg
gggggggdlggghhhhehhheggdlgggddgg
ggggggggdghhhhheghhhhhegdggdgggg
gglggggghhhhhheggehhhhhheggggggg
ggdggghhhhheeeggggeeehhhhheggggg
ggghhhhhhheggggggggggeehhhhhhegg
gghhhhhhhhhhhheggghhhhhhhhhhhheg
gghhhhhhhhhhhheggghhhhhhhhhhhheg
ggeeeeeeeeeehheggghheeeeeeeeeegg
gggggggggggghheggghheggggggggggg
gdgggggggggghhheghhheggggggggggg
ggggggggggggehheghhheggggggggggg
ggggggggggggghheghhegggggggggggg
gggggdggggggghheghhegdgggggggglg
ggggggglgggghhheghhhegglggggggdg
gggggggldggghhheghhheggldggggggg
ggggggglggghhheggehhheglggggllgg
gggggggdlgghhhhhhhhhhegdlgggddgg
ggggggggdghhhhhhhhhhhhegdggdgggg
gglggggggghhhhhhhhhhhheggggggggg
ggdgggggghhhhheeeehhhhhegggggggg
ggggggggghhhheggggehhhhegggggggg
gglgggggghhheggggglehhhegggdgggg
gglggggggeeegggggglgeeeggggggggg
ggdgggggggggggggggdggggggggggggg
gggggggggggggggggggggggggggggggg
```

### 2.4 The 16 areas

Each area uses one ground family, one mood and its own mix of features. The mood is a tint of the whole ground (and nothing above it) by the amount in the table; it costs one mix per ground cell, done once when a tile row is drawn, not every frame.

| Mood | Tint | Amount | Feel |
|---|---|---|---|
| dawn | Glow Light | 10% | warm first light |
| day | none | 0% | no tint |
| haze | Haze | 14% | pale, the far land softer |
| dusk | Dawn Low | 10% | red low sun |
| storm | Ink | 18% | dark, the bullets and the sight stand out more |

| Area | Ground | Mood | The land |
|---|---|---|---|
| 1 | dry | dawn | Open ochre plain, a lone road, the first land lines. Light and calm. |
| 2 | green | dawn | Meadow and the first forests, a river from the left. |
| 3 | green | day | Forest blocks cut by roads; Dishes along the roads. |
| 4 | dry | day | Wide land lines (all three designs), Bastions on pads. |
| 5 | green | day | A broad river with bridges; Beetles on the roads. |
| 6 | dry | haze | Long forest belts across a dry plain, the first Citadel. |
| 7 | green | haze | Meadow with many pads: an installation field. |
| 8 | dry | dusk | River country: two rivers, few roads. |
| 9 | green | dusk | Deep forest, roads only, Hives in clearings. |
| 10 | dry | dusk | Land lines everywhere, the spiral field. |
| 11 | green | day | A second dawn: meadow, rivers, a calm stretch then a Citadel. |
| 12 | dry | haze | Badlands: ochre with earth scars, Henges. |
| 13 | green | storm | Forest under storm light, Burr nests. |
| 14 | dry | storm | The road maze: crossings and Beetles. |
| 15 | green | dusk | Everything at once, two Citadels. |
| 16 | dry | dawn | The way home: the land lines again, bigger, and the last Citadel. |

After area 16 the loop starts again at area 1 with the same looks. `skylark-themes.png` shows the four moods.

## 3. Sprites

### 3.1 The Lark and its weapons

The Lark: a small swept wing survey craft, pale hull, cyan canopy, orange wing marks, two engine bells. Original to this game.

#### lark (16 x 16)

The Lark, level flight. Facing up, lit from the upper left. Box 12 x 12 at (2, 2), a little inside the wings so a graze is forgiven.

Legend: `D` Hull Dark `64738C`, `G` Glass `46D6EE`, `K` Hull Ink `2A3448`, `M` Hull Mid `B4C2D2`, `O` Wing Mark `F2A33A`, `W` Hull `F2F5F8`.

```
................
.......KK.......
......KWMK......
......KGGK......
.....KWGGMK.....
.....KWMDMK.....
....KKWMDMKK....
...KWKWMDMKMK...
..KWWKWMDMKMMK..
.KWOWKWMDMKMOMK.
KWWOWWWMDMMMOMMK
KWWWWKWMDMKMMMMK
.KKKKKDMDDKKKKK.
.....KDKKDK.....
......K..K......
................
```

#### lark_bank_left (16 x 16)

Moving left: the left wing folds in and darkens, the right wing turns its top to the light. Same box.

Legend: `D` Hull Dark `64738C`, `G` Glass `46D6EE`, `K` Hull Ink `2A3448`, `M` Hull Mid `B4C2D2`, `O` Wing Mark `F2A33A`, `W` Hull `F2F5F8`.

```
................
.......KK.......
......KWWK......
......KGGK......
.....KWGGWK.....
.....KWMWWK.....
....KKWMWWKK....
...KMKWMWWKWK...
..KMMKWMWWKWWK..
..KOMKWMWWKWOWK.
..KOMWWMWWWWOWWK
..KMMKWMWWKWWWWK
..KKKKDMWMKKKKK.
.....KDKKMK.....
......K..K......
................
```

#### lark_bank_right (16 x 16)

Moving right: the mirror of lark_bank_left, with the light kept on the upper left. Same box.

Legend: `D` Hull Dark `64738C`, `G` Glass `46D6EE`, `K` Hull Ink `2A3448`, `M` Hull Mid `B4C2D2`, `O` Wing Mark `F2A33A`, `W` Hull `F2F5F8`.

```
................
.......KK.......
......KWMK......
......KGGK......
.....KWGGMK.....
.....KWMDMK.....
....KKWMDMKK....
...KWKWMDMKDK...
..KWWKWMDMKDDK..
.KWOWKWMDMKDOK..
KWWOWWWMDMMDOK..
KWWWWKWMDMKDDK..
.KKKKKDMDDKKKK..
.....KDKKDK.....
......K..K......
................
```

#### flame_1 (16 x 3)

Thruster, frame 1 of 2 (4 frames each). Drawn with its top left at the Lark's top left + (0, 13), so the flames sit under the two engine bells.

Legend: `F` Flame `FF9A3A`, `Y` Flame Hot `FFF2A8`.

```
......Y..Y......
......F..F......
................
```

#### flame_2 (16 x 3)

Thruster, frame 2 of 2. While the Lark moves up the flame stays on frame 2.

Legend: `F` Flame `FF9A3A`, `Y` Flame Hot `FFF2A8`.

```
......Y..Y......
......Y..Y......
.....F.FF.F.....
```

#### zap (3 x 6)

The Zapper shot. Box 1 x 4 at (1, 0): the core only. The glow cells are the bloom and never collide.

Legend: `G` Zap Glow `8AF0FF`, `Z` Zap `FFFFFF`.

```
.Z.
GZG
GZG
.Z.
.G.
.G.
```

#### bomb_1 (7 x 7)

Bomb in flight, frame 1 of 3 (3 frames each, looping 1 2 3 2). It has no box: a bomb only acts where it lands.

Legend: `O` Wing Mark `F2A33A`, `Y` Flame Hot `FFF2A8`.

```
.......
.......
..OOO..
..OYO..
..OOO..
.......
.......
```

#### bomb_2 (7 x 7)

Bomb, frame 2.

Legend: `O` Wing Mark `F2A33A`, `Y` Flame Hot `FFF2A8`.

```
.......
..OOO..
.OYYYO.
.OYYYO.
.OYYYO.
..OOO..
.......
```

#### bomb_3 (7 x 7)

Bomb, frame 3: the ring opens out, the core shrinks. The last 4 frames before it lands it stays on this frame.

Legend: `O` Wing Mark `F2A33A`, `Y` Flame Hot `FFF2A8`.

```
..OOO..
.O...O.
O..Y..O
O.YYY.O
O..Y..O
.O...O.
..OOO..
```

#### bomb_shadow (5 x 3)

The bomb's shadow: a tint pass (Ink at 35%), not a colour. It slides from under the Lark to the sight while the bomb flies, so the player can see where it will land.

Legend: `S` Ink `0A1018`.

```
.SSS.
SSSSS
.SSS.
```

#### sight (15 x 15)

The sight, normal. One colour (Sight) with an Ink keyline one cell wide, so it reads over foam, ochre and forest alike. The centre cell (7, 7) is the aim point. The bomb's blast box is 16 x 16 centred on that cell.

Legend: `S` Sight `B6FFE6`, `k` Ink `0A1018`.

```
kkkk.......kkkk
kSSSk..k..kSSSk
kSkk..kSk..kkSk
kSk...kSk...kSk
.k.....k.....k.
...............
.kk....k....kk.
kSSk..kSk..kSSk
.kk....k....kk.
...............
.k.....k.....k.
kSk...kSk...kSk
kSkk..kSk..kkSk
kSSSk..k..kSSSk
kkkk.......kkkk
```

#### sight_lock (15 x 15)

The sight over a ground target: the same cells in Sight Lock. It also gets the bloom (section 5).

Legend: `S` Sight Lock `FF4A4A`, `k` Ink `0A1018`.

```
kkkk.......kkkk
kSSSk..k..kSSSk
kSkk..kSk..kkSk
kSk...kSk...kSk
.k.....k.....k.
...............
.kk....k....kk.
kSSk..kSk..kSSk
.kk....k....kk.
...............
.k.....k.....k.
kSk...kSk...kSk
kSkk..kSk..kkSk
kSSSk..k..kSSSk
kkkk.......kkkk
```

### 3.2 Who is who

Each original thing takes the role of one line of the brief's tables, so the rules, timings and points in the brief apply to it unchanged. Points are the brief's starting figures.

| Ours | Role in the brief | Kind | Points | Looks like |
|---|---|---|---|---|
| Whirl | the spinning ring, first wave | air | 30 | a three bladed seed spinner, plum, steel hub, green eye |
| Skate | the diving disc | air | 50 | a flat ray glider |
| Kite | the flipping diamond that fires as it turns | air | 10 | a diamond kite on steel spars |
| Glint | the mirror that flips, reflects, then dives | air | 1000 | a long hexagonal mirror shard |
| Midge | the small wiggler, hard to hit | air | 150 | a small plum dragonfly with steel wings |
| Wisp | the orb that appears near you and bursts into bullets | air | 300 | a green glow in a plum cage |
| Swift | the fast darts in formation | air | 100 | a swallow shaped dart, nose down |
| Anvil | the indestructible plate | air | 0 or 1000 | a heavy iron hexagon with six bolts |
| Cairn | the basic ground target | ground | 10 | three stepped stone rings with a rust band |
| Dish | the dome beside the road | ground | 20 | a dish aerial on a footing |
| Burr | the ball turret | ground | 100 | a rust ball with eight spines |
| Bastion | the larger turret | ground | 200 | a square bunker with corner lights |
| Beetle | the small tank | ground | 200 | a crawler on two tracks |
| Henge | the large tough target | ground | 300 | eight standing stones round a pit |
| Hive | the ground launcher | ground | 400 | a domed silo that opens; Wisps rise from it |
| Spire | the hidden tower | ground | 2000 | a stepped needle with a signal tip |
| Pennant | the hidden flag (extra life) | ground | 1 life | an orange pennant on a pole |
| Citadel | the boss: a core behind four shields | boss | 4000 | a round fortress of eight plates, a green core; four curved shield plates |

### 3.3 Air enemies

All plum and steel with the green eye, lit from the upper left. Shadows: see section 5.

#### whirl_1 (16 x 16)

Whirl, frame 1 of 4 (the blades 0 degrees on). 3 frames each, so it turns once in 12 frames and looks like a seed spinning down.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
........PP......
.......DPL......
.......DPL......
......DPPL......
......DPLL......
......PPL.......
......SSSS......
......SEESPD....
...LLLSEESPDD...
.LLLPPSSSSPPD...
PPPPPPPD..LPPD..
.PDDDD.....LPP..
...........LLPP.
.............L..
................
................
```

#### whirl_2 (16 x 16)

Whirl, frame 2 of 4 (30 degrees).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
................
............P...
..........DPPL..
........DDPPL...
.......DDPPLL...
.......PPPL.....
PLLLL.SSSS......
PPPPLLSEES......
.DDPPPSEESD.....
...DDPSSSSP.....
........LPPD....
........LPPD....
........LLPD....
.........LPD....
.........LPP....
..........P.....
```

#### whirl_3 (16 x 16)

Whirl, frame 3 of 4 (60 degrees).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
................
................
..L.............
.PPLL...........
..PPL.....DDDDP.
..DPPL..DPPPPPPP
...DPPSSSSPPLLL.
...DDPSEESLLL...
....DPSEES......
......SSSS......
.......LPP......
......LLPD......
......LPPD......
......LPD.......
......LPD.......
......PP........
```

#### whirl_4 (16 x 16)

Whirl, frame 4 of 4 (90 degrees).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
.....P..........
....PPL.........
....DPL.........
....DPLL........
....DPPL........
....DPPL........
.....PSSSSPDD...
.....DSEESPPPDD.
......SEESLLPPPP
......SSSS.LLLLP
.....LPPP.......
...LLPPDD.......
...LPPDD........
..LPPD..........
...P............
................
```

#### skate_flat (16 x 16)

Skate, gliding (also its frame when it turns back up and leaves). Box 14 x 8 at (1, 4).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
................
................
.......DD.......
......DLLD......
.....DLLLLD.....
...DDLLPPLLDD...
.DDLLPPEEPPLLDD.
DLLLPPPPPPPPLLLD
DPPPPPDPPDPPPPPD
.DDPPDDPPDDPPDD.
...DD.DPPD.DD...
.......DD.......
.......SD.......
.......SD.......
........D.......
................
```

#### skate_dive (16 x 16)

Skate, diving: the wing tips sweep back one row and go dark. Box 14 x 8 at (1, 4).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
................
................
.......DD.......
......DLLD......
.....DLLLLD.....
....DLLPPLLD....
...DLPPEEPPLD...
.DDDPPPPPPPPDDD.
DDDDPPDPPDPPDDDD
DPPPPDDPPDDPPPPD
.DDPD.DPPD.DPDD.
...D...DD...D...
.......SD.......
.......SD.......
........D.......
................
```

#### skate_rise (16 x 16)

Skate, pulling out: the wing tips lift one row and catch the light. Box 14 x 8 at (1, 4).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
................
................
.......DD.......
......DLLD......
...D.DLLLLD.D...
.DDLDLLPPLLDLDD.
DLLLLPPEEPPLLLLD
DLLLPPPPPPPPLLLD
.DDLPPDPPDPPLDD.
...DPDDPPDDPD...
....D.DPPD.D....
.......DD.......
.......SD.......
.......SD.......
........D.......
................
```

#### kite_1 (16 x 16)

Kite, frame 1 of 4: face on, the eye open. It fires as it reaches frame 3. Box 10 x 12 at (3, 1).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
.......S........
......LSP.......
.....LLSPP......
....LLLSPPP.....
...LLLLSPPPP....
..LLLLESEPPPP...
.SSSSSSSSSSSSS..
..PPPPESELLLL...
...PPPPSLLLL....
....PPPSLLL.....
.....PPSLL......
......PSL.......
.......S........
.......S........
.......D........
........D.......
```

#### kite_2 (16 x 16)

Kite, frame 2 of 4: turning. It fires as it reaches frame 3. Box 10 x 12 at (3, 1).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
.......S........
.......S........
......LSP.......
......LSP.......
.....LLSPP......
....LLESEPP.....
....SSSSSSS.....
....PPESELL.....
.....PPSLL......
.....PPSLL......
......PSL.......
......PSL.......
.......S........
.......S........
.......D........
........D.......
```

#### kite_3 (16 x 16)

Kite, frame 3 of 4: edge on: a stick. It fires as it reaches frame 3. Box 10 x 12 at (3, 1).

Legend: `D` Plum Dark `472A6E`, `S` Steel `D2D0E2`.

```
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......S........
.......D........
........D.......
```

#### kite_4 (16 x 16)

Kite, frame 4 of 4: its back: no eye. It fires as it reaches frame 3. Box 10 x 12 at (3, 1).

Legend: `D` Plum Dark `472A6E`, `S` Steel `D2D0E2`.

```
.......S........
.......S........
......DSD.......
......DSD.......
.....DDSDD......
....DDDSDDD.....
....SSSSSSS.....
....DDDSDDD.....
.....DDSDD......
.....DDSDD......
......DSD.......
......DSD.......
.......S........
.......S........
.......D........
........D.......
```

#### glint_1 (16 x 16)

Glint, frame 1 of 4: face on: a mirror with a white glare. Box 12 x 12 at (2, 2) on every frame (it is the same mirror).

Legend: `P` Plum `7C4EAE`, `S` Steel `D2D0E2`, `W` Flash `FFFFFF`.

```
................
....PPPPPPPP....
....PSSSSSSP....
...PSSSSSSSSP...
...PSSSSSSSSP...
..PPSSSSSSSWPP..
..PSSSSSSSWWSP..
..PSSSSSSWWSSP..
..PSSSSWWSSSSP..
..PSSSWWSSSSSP..
..PPSWWSSSSSPP..
...PWWSSSSSSP...
...PWSSSSSSSP...
....PSSSSSSP....
....PPPPPPPP....
................
```

#### glint_2 (16 x 16)

Glint, frame 2 of 4: tipping. Box 12 x 12 at (2, 2) on every frame (it is the same mirror).

Legend: `P` Plum `7C4EAE`, `S` Steel `D2D0E2`, `W` Flash `FFFFFF`.

```
................
................
................
................
................
...PPPPPPPPPP...
...PSSSSSSWWP...
..PSSSSSSWWSSP..
..PSSSSWWSSSSP..
...PSSWWSSSSP...
...PPPPPPPPPP...
................
................
................
................
................
```

#### glint_3 (16 x 16)

Glint, frame 3 of 4: edge on: a line. Box 12 x 12 at (2, 2) on every frame (it is the same mirror).

Legend: `S` Steel `D2D0E2`.

```
................
................
................
................
................
................
................
.SSSSSSSSSSSSSS.
.SSSSSSSSSSSSSS.
................
................
................
................
................
................
................
```

#### glint_4 (16 x 16)

Glint, frame 4 of 4: its plum back. Box 12 x 12 at (2, 2) on every frame (it is the same mirror).

Legend: `D` Plum Dark `472A6E`, `P` Plum `7C4EAE`.

```
................
................
................
................
................
...DDDDDDDDDD...
...DPPPPPPPPD...
..DPPPPPPPPPPD..
..DPPPPPPPPPPD..
...DPPPPPPPPD...
...DDDDDDDDDD...
................
................
................
................
................
```

#### midge_1 (12 x 12)

Midge, wings up. 12 x 12. 2 frames each. Box 4 x 8 at (4, 2): only the body, which is why it is hard to hit.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
............
....S..S....
...SS..SS...
..SSS.LSSS..
...SSPLSS...
.....PE.....
....SPPS....
...SSPDSS...
..SSS.DSSS..
......D.....
......D.....
............
```

#### midge_2 (12 x 12)

Midge, wings down.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
............
............
............
.....LL.....
.SSSSPLSSSS.
..SSSPEPSS..
.....PP.....
..SSSPDSSS..
.SSSS.DSSSS.
......D.....
......D.....
............
```

#### wisp_1 (16 x 16)

Wisp, arriving: a spark where it will be (no box yet, 8 frames). Box 10 x 10 at (3, 3) on frames 2 and 3.

Legend: `E` Eye `7CFFB4`, `W` Flash `FFFFFF`.

```
................
................
................
................
................
.......EE.......
.......WW.......
.....EWWWWE.....
.....EWWWWE.....
.......WW.......
.......EE.......
................
................
................
................
................
```

#### wisp_2 (16 x 16)

Wisp, whole, the cage turning slowly (swap with frame 3 every 6 frames). Box 10 x 10 at (3, 3) on frames 2 and 3.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `G` Core Dark `1E7A5C`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `W` Flash `FFFFFF`.

```
................
................
.......LD.......
.....DLLDDL.....
....DGGPPGGD....
...LGGEEEEGGD...
...DGEEEEEEGL...
..DDPEEWWEEPLL..
..LLPEEWWEEPDD..
...LGEEEEEEGD...
...DGGEEEEGGL...
....DGGPPGGD....
.....LDDLLD.....
.......DL.......
................
................
```

#### wisp_3 (16 x 16)

Wisp, about to burst: the cage glows, 12 frames, then the ring of bullets. Box 10 x 10 at (3, 3) on frames 2 and 3.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `W` Flash `FFFFFF`.

```
................
.......LD.......
....DDLLDDLL....
...DDEEPPEELD...
..LLEEEEEEEEDD..
..LEEEEEEEEEED..
..DEEEEEEEEEEL..
.DDPEEEWWEEEPLL.
.LLPEEEWWEEEPDD.
..LEEEEEEEEEED..
..DEEEEEEEEEEL..
..DDEEEEEEEELL..
...DLEEPPEEDD...
....LLDDLLDD....
.......DL.......
................
```

#### swift_1 (12 x 12)

Swift, wings in. 12 x 12, nose down, rushing the Lark. 2 frames each. Box 6 x 8 at (3, 3).

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
............
.L........L.
.LP......PL.
..LP....PL..
..LPP..PPL..
...LPPPPL...
...DPEEPD...
....DPPD....
....DPPD....
.....DD.....
.....SS.....
.....S......
```

#### swift_2 (12 x 12)

Swift, wings out.

Legend: `D` Plum Dark `472A6E`, `E` Eye `7CFFB4`, `L` Plum Light `B88EE4`, `P` Plum `7C4EAE`, `S` Steel `D2D0E2`.

```
............
............
L..........L
LP........PL
.LPP....PPL.
..LPPPPPPL..
...DPEEPD...
....DPPD....
....DPPD....
.....DD.....
.....SS.....
......S.....
```

#### anvil_1 (16 x 16)

Anvil, frame 1 of 6 (0 degrees). Iron only: no Plum, no Eye. The dark, heavy, unlit look says it cannot be killed. 4 frames each. Box 12 x 14 at (2, 1) on every frame, so shots stop on it even edge on.

Legend: `I` Iron `3C3C4C`, `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
.......JJ.......
.....JJIIJJ.....
....JJIKKIKK....
..JJIIIKKIIIKK..
..JKKIIIIIIKKK..
..JKKIIIIIIKKK..
..JIIIIJJIIIIK..
..JIIIIJJIIIIK..
..JKKIIIIIIKKK..
..KKKIIIIIIKKK..
..KKIIIKKIIIKK..
....KKIKKIKK....
.....KKIIKK.....
.......KK.......
................
```

#### anvil_2 (16 x 16)

Anvil, frame 2 of 6 (30 degrees). 

Legend: `I` Iron `3C3C4C`, `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
.......JJ.......
......JIIJ......
....JJIKKIKK....
...JIIIKKIIIK...
...JKKIIIIKKK...
...JKKIIIIKKK...
...JIIIJJIIIK...
...JIIIJJIIIK...
...JKKIIIIKKK...
...KKKIIIIKKK...
...KIIIKKIIIK...
....KKIKKIKK....
......KIIK......
.......KK.......
................
```

#### anvil_3 (16 x 16)

Anvil, frame 3 of 6 (60 degrees). 

Legend: `I` Iron `3C3C4C`, `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
................
.......JJ.......
......JKKK......
.....JIKKIK.....
.....KKIIKK.....
.....KKIIKK.....
.....IIJJII.....
.....IIJJII.....
.....KKIIKK.....
.....KKIIKK.....
.....KIKKIK.....
......KKKK......
.......KK.......
................
................
```

#### anvil_4 (16 x 16)

Anvil, frame 4 of 6 (90 degrees). 

Legend: `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
.......JK.......
................
```

#### anvil_5 (16 x 16)

Anvil, frame 5 of 6 (120 degrees). 

Legend: `I` Iron `3C3C4C`, `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
................
.......JJ.......
......JIIK......
.....JKKKKK.....
.....IIIIII.....
.....IIIIII.....
.....KKKKKK.....
.....KKKKKK.....
.....IIIIII.....
.....IIIIII.....
.....KKKKKK.....
......KIIK......
.......KK.......
................
................
```

#### anvil_6 (16 x 16)

Anvil, frame 6 of 6 (150 degrees). 

Legend: `I` Iron `3C3C4C`, `J` Iron Light `8E8EA6`, `K` Iron Edge `1C1C26`.

```
................
.......JJ.......
......JIIJ......
....JJIIIIKK....
...JKKKKKKKKK...
...JIIIIIIIIK...
...JIIIIIIIIK...
...JKKKKKKKKK...
...JKKKKKKKKK...
...JIIIIIIIIK...
...KIIIIIIIIK...
...KKKKKKKKKK...
....KKIIIIKK....
......KIIK......
.......KK.......
................
```

#### bullet_1 (5 x 5)

Enemy bullet, frame 1 of 2 (2 frames each). Box 3 x 3 at (1, 1). Every enemy shot in the game is this, in Hot.

Legend: `C` Hot Core `FFE4F0`, `H` Hot `FF3D8E`.

```
.....
..H..
.HCH.
..H..
.....
```

#### bullet_2 (5 x 5)

Enemy bullet, frame 2: the flare. Same box.

Legend: `C` Hot Core `FFE4F0`, `H` Hot `FF3D8E`.

```
..H..
.HCH.
HCCCH
.HCH.
..H..
```

### 3.4 Ground targets and what is left of them

Rust and stone with the green eye. A scorch is drawn **on the ground layer** where the target stood (it scrolls with the land, it is not a sprite with a life of its own), and it is drawn the frame the burst starts, so the burst covers the change.

#### cairn (16 x 16)

Cairn: three stepped rings of stone with a rust band and a green eye on top. Box 12 x 12 at (2, 2).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`, `S` Stone `D4CBB6`.

```
................
......MMMM......
.....MMMMMM.....
....MMLLLMMM....
...MMSSSRRMMM...
..MMSEESSRRMMD..
.MMLSEEESSRQMDD.
.MMLSSESSSRQMDD.
.MMLRSSSSRRQMDD.
.MMMRRSSRRRMMDD.
..MMMRRRRRMMMD..
...MMMQQQMMMM...
....MMMMMMMM....
.....DDDDDD.....
......DDDD......
................
```

#### dish (16 x 16)

Dish: a dish aerial on a square footing. Stands beside the road. Box 12 x 12 at (2, 2).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`, `S` Stone `D4CBB6`.

```
................
................
..MMMMMMMMMMDD..
..MMSSSQSSSMDD..
..MSQQQQRRRMDD..
..SSQQQRRRRMMD..
..SQQQRERRLLMD..
..SQQRRERLLLMD..
..SSRRRRLLLMMD..
..MSRRRLLLLMDD..
..MMSMMLMMMMDD..
..MMMMMDMMMMDD..
..DDDDDDDDDDDD..
..DDDDDDDDDDDD..
................
................
```

#### burr (16 x 16)

Burr: a ball turret with eight spines. Its eye is the muzzle. Box 10 x 10 at (3, 3).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `L` Rust Light `EC8C5C`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`, `S` Stone `D4CBB6`.

```
.......S........
.......S........
..SS...S...SS...
..SS.LLLRR.SD...
....LLLLLRR.....
...LLLLLRRRQ....
...LLLEEERRQ....
SSSLLLEEERQQDDD.
...RLREEERQQ....
...RRRRRRQQQ....
....RRRQQQQ.....
..SS.QQQQQ.DD...
..SD...D...DD...
.......D........
.......D........
................
```

#### bastion (16 x 16)

Bastion: a square bunker, a signal light at each corner, an armoured hatch with a green sight and a gun slot pointing down at the Lark. Box 14 x 14 at (1, 1).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `K` Ink `0A1018`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `R` Rust `C4583A`, `S` Stone `D4CBB6`, `Y` Signal `FFD64A`.

```
DDDDDDDDDDDDDDDD
DYSSSSSSSSSSSSYD
DSSMMMMMMMMMMMMD
DSMMDDDDDDDDMMMD
DSMDLLLLLLLRDMMD
DSMDLRRRRRRRDMMD
DSMDLRKEEKRRDMMD
DSMDLRKEEKRRDMMD
DSMDLRRKKRRRDMMD
DSMDLRRRRRRRDMMD
DSMDRDDDDDDDDMMD
DSMMMMMKKMMMMMMD
DSMMMMMKKMMMMMMD
DMMMMMMKKMMMMMMD
DYMMMMMMMMMMMMYD
DDDDDDDDDDDDDDDD
```

#### beetle_1 (16 x 16)

Beetle, frame 1 of 2 (track links move every 4 frames). Facing up; it is drawn turned by quarter turns to face its way along the road. Box 12 x 14 at (2, 1).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `K` Ink `0A1018`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`.

```
................
..MMD......MMD..
..MMD......MMD..
..KKKLKEEKRKKK..
..MMLLKEEKRQMD..
..MMLLLLLRRRMD..
..KKLLLLLRRRKK..
..MMLLLLRRRQMD..
..MMLLLRRRRQMD..
..KKRRRRRRQQKK..
..MMRRRRRQQQMD..
..MMQRRQQQQQMD..
..KKKQQQQQQKKK..
..MMD......MMD..
..MMD......MMD..
................
```

#### beetle_2 (16 x 16)

Beetle, frame 2. Box 12 x 14 at (2, 1).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `K` Ink `0A1018`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`.

```
................
..MMD......MMD..
..KKK......KKK..
..MMDLKEEKRMMD..
..MMLLKEEKRQMD..
..KKLLLLLRRRKK..
..MMLLLLLRRRMD..
..MMLLLLRRRQMD..
..KKLLLRRRRQKK..
..MMRRRRRRQQMD..
..MMRRRRRQQQMD..
..KKQRRQQQQQKK..
..MMDQQQQQQMMD..
..MMD......MMD..
..KKK......KKK..
................
```

#### henge (16 x 16)

Henge: the tough one, eight standing stones round a dark pit. Box 14 x 14 at (1, 1).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `K` Ink `0A1018`, `M` Stone Mid `9E947E`, `S` Stone `D4CBB6`.

```
.......DD.......
......DSSD......
...DS..SS..SD...
..DSSMMMMMMSMD..
..SSSMDDDDMMMM..
...MMDKKKKDMM...
.D.MDKKKKKKDM.D.
DSSMDKKEEKKDMMMD
DSSMDKKEEKKDMMMD
.D.MDKKKKKKDM.D.
...MMDKKKKDMM...
..SSMMDDDDMMMM..
..DMMMMMMMMMMD..
...DM..MM..MD...
......DMMD......
.......DD.......
```

#### hive_closed (16 x 16)

Hive, closed. Box 14 x 14 at (1, 1).

Legend: `D` Stone Dark `5E5646`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `R` Rust `C4583A`, `S` Stone `D4CBB6`.

```
................
.....SSSSMM.....
...SSSSSSMMMD...
..SSSSDDDDMMMD..
..SSDDLQQLDDMD..
.SSSDLLQQLRDMDD.
.SSDLLLQQRRRDDD.
.SSDQQQQQQQQDDD.
.SSDQQQQQQQQDDD.
.MMDLLRQQRRRDDD.
.MMMDRRQQRRDDDD.
..MMDDRQQRDDDD..
..DMMMDDDDDDDD..
...DDDDDDDDDD...
.....DDDDDD.....
................
```

#### hive_open (16 x 16)

Hive, open: shown for 20 frames before a Wisp rises out of it. Box 14 x 14 at (1, 1).

Legend: `D` Stone Dark `5E5646`, `E` Eye `7CFFB4`, `K` Ink `0A1018`, `M` Stone Mid `9E947E`, `Q` Rust Dark `7C3022`, `S` Stone `D4CBB6`.

```
................
.....SSSSMM.....
...SSSSSSMMMD...
..SSSSDDDDMMMD..
..SSDDQQQQDDMD..
.SSSDQKKKKQDMDD.
.SSDQKKEEKKQDDD.
.SSDQKEEEEKQDDD.
.SSDQKEEEEKQDDD.
.MMDQKKEEKKQDDD.
.MMMDQKKKKQDDDD.
..MMDDQQQQDDDD..
..DMMMDDDDDDDD..
...DDDDDDDDDD...
.....DDDDDD.....
................
```

#### cairn_scorch (16 x 16)

What is left of the Cairn: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
.....Z.ZZ.Z.....
....ZZXXXX.Z....
...ZZXZXXZX.Z...
....XXXXXXXXZZ..
..ZXZXXXXXXXXZ..
..XXXXXZXXXXXD.Z
ZXXXXXXXXXXDXXZ.
ZXXXXXXXXXXXXXX.
ZZXXXXXXXZXXXDXZ
.XXXXXXZXXXXXDXZ
.ZXXZXXXXXXXXD.Z
..ZXXXXXZXZXX.Z.
...ZXZXXZXXZZ...
....ZXXXXXX.Z...
....Z.XXXZ......
.......Z.ZZ.....
```

#### dish_scorch (16 x 16)

What is left of the Dish: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
................
...ZZZZ..Z.ZZ.Z.
.ZXZXXZXXZXXZX..
.ZXXXXXDXXXXXD..
..XXZXXXXXXXXD..
..XXXDXZXXXXXD..
..XXDXXXXXXXXXZ.
.ZXXDXXXXXXXXXZ.
.ZXXXXXXXZXXXD..
..XXXXXZXXXXXD..
.ZXXZXXXXXXXXD..
..XXXXXXZXZXXXZ.
.ZXDDZDDZDXZDXZ.
.ZXXDXXXXXXXDDZ.
..Z.Z..Z.Z..ZZ..
................
```

#### burr_scorch (16 x 16)

What is left of the Burr: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
.......XZ.......
...ZZ.ZX...ZZ...
.ZXZZ.ZX.Z.XZ...
.ZXXZXXXXX.XXZ..
..Z.ZXXXXXXZ.Z..
..ZXXXXZXXXX....
Z..XXXXXXXXD..Z.
XXXXXXXXXXXXXXX.
ZZ.XXXXXXZXXZZ.Z
..ZXXXXZXXDD....
.ZZ.ZXXXXXD.ZZ..
..XX.DXXZDZDX...
.ZXDZZZDZZ.ZD...
.Z..Z.ZX....ZZ..
.......X........
.......Z........
```

#### bastion_scorch (16 x 16)

What is left of the Bastion: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
DXXXXDXXDXZDXXXX
DXXZXZXXXXXXXXXX
ZXXZXXZXXZXXZXXX
XXXXXXXDDXXXXXXD
XXXXZXXXXXXXXXXX
XXXXXXXZXXXXXXXX
DXXXXXDXXDXXXXZX
XXXXXXXXXXXXXXXX
XZXXXXXDXZXXDXXD
XXXXXXXZXXXXXXXD
XXXXZDXXXXDXXXXZ
DXXXXXXXZXZXXXXX
DXXXXZXDZXXZXXZX
ZXXXXXXXXXXXXXXX
XXXXXXXXXZXXXXXD
XZDXXXXDXXDXZDXX
```

#### beetle_scorch (16 x 16)

What is left of the Beetle: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
..Z..Z....ZZ.Z..
..XZDZ.....XXXZ.
.ZXZD.ZZ.Z.XZX..
.ZXXXXXXXXXXXD..
..XXZXXXXXXDXD..
..XXXXXZXXXXXD..
..XXXXXXXXXXXXZ.
.ZXXXXXXXXXXXXZ.
.ZXXXXXXXZXXXD..
..DXXXXZXXDDXD..
.ZXXZXXXXXDXXD..
..XXXXXXZDZDXXZ.
.ZXDDZDDZDXZDXZ.
.ZXXD.Z..Z.XXDZ.
..XXD......XXD..
.ZZ.Z.....Z.ZZ..
```

#### henge_scorch (16 x 16)

What is left of the Henge: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
.....Z.XD.Z.....
...ZZZDXXX.ZZ...
.ZZZX.ZXXZ.XZ...
.ZXXXXXXXXXXXD..
..XXZXXXDXXXXX..
..ZXXDXZDXXXXZ.Z
ZX.XDXDXXDXDX.Z.
XXXXDXXXXXXXXXXX
XZXXDXXXXZXXXXXD
.XZXXXXZXXDDXZXZ
.ZZXZDXXXXDXXZ.Z
..XXXXXXZDZXXXZ.
.ZXXXZXXZXXZXXZ.
.Z.XX.ZXXZ.XDZZ.
..Z.Z.XXXZ..ZZ..
.......DXZZ.....
```

#### hive_scorch (16 x 16)

What is left of the Hive: drawn on the ground layer where it stood, stays until it scrolls off.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
.....Z.ZZ.ZZ....
...ZZZXXXXXZZ...
.ZZZXXZXXZXXZ...
.ZXXXXXDDXXXXD..
..XXZXXXDXDDXD.Z
.XXXXXXZDXXXXDXZ
ZXXXXXXXXXXXXXZ.
ZXXXDXXDXXXXXXX.
ZZXXDXXDXZXXDDXZ
.XXXXXXZXXXXXDXZ
.XXXZXXXXXXXXDXZ
Z.XXXDXXZXZDXXZ.
.ZXXXZDDZDXZDXZ.
.Z.XDXXXXXXXDZZ.
..Z.ZXXXXZX.ZZ..
....Z..Z.ZZ.....
```

#### spire (16 x 16)

Spire, revealed: drawn for 24 frames, then it bursts (ground burst) and leaves spire_scorch. Box 12 x 12 at (2, 2), the same box the bomb has to hit while it is hidden.

Legend: `D` Stone Dark `5E5646`, `L` Rust Light `EC8C5C`, `M` Stone Mid `9E947E`, `R` Rust `C4583A`, `S` Stone `D4CBB6`, `Y` Signal `FFD64A`.

```
.....MMMMMM.....
....MMMSSMMM....
...MMMSSSSMMM...
..MMMSSSSSSMDD..
.MMMSSSLLSSMDDD.
MMMSSSLLLLMMMDDD
MMSSSLLLLRRMMMDD
MSSSLLLYYRRRMMMD
MSSSLLLYYRRRMMMD
MMSSSLRRRRRMMMDD
MMMSSMRRRRMMMDDD
.MMMMMMRRMMMDDD.
..MDDMMMMMMDDD..
...DDDMMMMDDD...
....DDDMMDDD....
.....DDDDDD.....
```

#### spire_flicker (16 x 16)

Spire, the flicker: every other row, all Stone. Drawn on 2 frames out of every 16 while the sight's centre cell is inside its box.

Legend: `S` Stone `D4CBB6`, `Y` Signal `FFD64A`.

```
.....SSSSSS.....
................
...SSSSSSSSSS...
................
.SSSSSSSSSSSSSS.
................
SSSSSSSSSSSSSSSS
................
SSSSSSSYYSSSSSSS
................
SSSSSSSSSSSSSSSS
................
..SSSSSSSSSSSS..
................
....SSSSSSSS....
................
```

#### spire_scorch (16 x 16)

What is left of the Spire.

Legend: `D` Smoke `5C4C48`, `X` Scorch `2C231B`, `Z` Scorch Edge `4D3E2C`.

```
.....XXXXXZZ....
...ZXZXXXXXXZ...
.ZZZXXZXXZXXZ...
.ZXXXXXXXXXXXD.Z
.XXXZXXXXXXXXDXZ
XXXXXXXZXXXXXDXX
XXXXXXXXXXXXXXZX
XXXXXXXXXXXXXXXX
XZXXXXXXXZXXXXXD
XXXXXXXZXXXXXXXD
XXXXZXXXXXXXXDXZ
ZXXXXXXXZXZXXXX.
ZZXDDZXXZXXZDXZ.
.Z.XDXXXXXXXDZZ.
..Z.DXXXXZXXZZ..
....ZXXDXXD.Z...
```

#### pennant_1 (16 x 16)

Pennant, frame 1 of 2 (8 frames each). It appears where the hidden spot was bombed and waits; flying over it collects it. Box 10 x 14 at (3, 1).

Legend: `D` Stone Dark `5E5646`, `M` Stone Mid `9E947E`, `O` Wing Mark `F2A33A`, `S` Stone `D4CBB6`, `W` Hull `F2F5F8`.

```
................
.....D..........
.....DOOOO......
.....DOWWOOO....
.....DOOOOWWOO..
.....DOWWOOOO...
.....DOOOO......
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
....DDD.........
...SSMMM........
................
```

#### pennant_2 (16 x 16)

Pennant, frame 2.

Legend: `D` Stone Dark `5E5646`, `M` Stone Mid `9E947E`, `O` Wing Mark `F2A33A`, `S` Stone `D4CBB6`, `W` Hull `F2F5F8`.

```
................
.....D..........
.....DOOO.......
.....DOWWOOOO...
.....DOOOWWOOOO.
.....DOWWOOO....
.....DOO........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
.....D..........
....DDD.........
...SSMMM........
................
```

### 3.5 The Citadel

A round fortress of eight plates with a green core, 32 x 32, with four curved shield plates round it (north, east, south, west, each 1 cell off the rim). It is drawn on the ground layer's side of the shadows (it flies low) but bombs and shots both reach it: the shields are hit by the Zapper, the core only by the Blaster.

#### citadel_core (32 x 32)

The Citadel core, 32 x 32. The bomb has to land in the core box, 10 x 10 at (11, 11). The plates take no damage.

Legend: `A` Shell Light `AEBED6`, `B` Shell `6C7C98`, `C` Shell Dark `3A4560`, `E` Core `7CFFB4`, `G` Core Dark `1E7A5C`, `K` Ink `0A1018`, `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................................
................................
................................
...........CCCAACACCC...........
.........CCAAAAACAAAACC.........
........CAAAYAAACAAYABBC........
......CCAAAYAAAACAAAYBBBCC......
......CCAAAAAAAACAAABBBBCC......
.....CAACAAAAACCCCAAABBCBBC.....
....CAAAACAACKKKKKKCCCCBBBBC....
....CAAAAACCKKGGGGKKCCCBBBBC....
...CAAYAAACKGGGEEGGGKCCCBYBBC...
...CAYAAACKGGEEEEEEGGKCCBBYCC...
...CAAAAAKKGEEEEEEEEGKKCCCCCC...
...AAAAACKGGEEWWWWEEGGKCCCCCC...
...CCCCCCKGEEEWWWWEEEGKCCCCCC...
...AAAAACKGEEEWWWWEEEGKCCCCCC...
...AAAAACKGGEEWWWWEEGGKCCCCCC...
...CAAAAAKKGEEEEEEEEGKKCCCCCC...
...CAYAAACKGGEEEEEEGGKCCCCYCC...
...CAAYBACCKGGGEEGGGKCCCCYCCC...
....CBBBBCCCKKGGGGKKCCCCCCCC....
....CBBBBCCCCKKKKKKCCCCCCCCC....
.....CBBCBBCCCCCCCCCCCCCCCC.....
......CCBBBBBCCCCCCCCCCCCC......
......CCBBBYBCCCCCCCYCCCCC......
........CBBBYCCCCCCYCCCC........
.........CCBCCCCCCCCCCC.........
...........CCCCCCCCCC...........
................................
................................
................................
```

#### citadel_core_hit (32 x 32)

The core, hit: the eye goes white for 2 frames, then the Citadel breaks up (section 4).

Legend: `A` Shell Light `AEBED6`, `B` Shell `6C7C98`, `C` Shell Dark `3A4560`, `G` Core Dark `1E7A5C`, `K` Ink `0A1018`, `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................................
................................
................................
...........CCCAACACCC...........
.........CCAAAAACAAAACC.........
........CAAAYAAACAAYABBC........
......CCAAAYAAAACAAAYBBBCC......
......CCAAAAAAAACAAABBBBCC......
.....CAACAAAAACCCCAAABBCBBC.....
....CAAAACAACKKKKKKCCCCBBBBC....
....CAAAAACCKKGGGGKKCCCBBBBC....
...CAAYAAACKGGGWWGGGKCCCBYBBC...
...CAYAAACKGGWWWWWWGGKCCBBYCC...
...CAAAAAKKGWWWWWWWWGKKCCCCCC...
...AAAAACKGGWWWWWWWWGGKCCCCCC...
...CCCCCCKGWWWWWWWWWWGKCCCCCC...
...AAAAACKGWWWWWWWWWWGKCCCCCC...
...AAAAACKGGWWWWWWWWGGKCCCCCC...
...CAAAAAKKGWWWWWWWWGKKCCCCCC...
...CAYAAACKGGWWWWWWGGKCCCCYCC...
...CAAYBACCKGGGWWGGGKCCCCYCCC...
....CBBBBCCCKKGGGGKKCCCCCCCC....
....CBBBBCCCCKKKKKKCCCCCCCCC....
.....CBBCBBCCCCCCCCCCCCCCCC.....
......CCBBBBBCCCCCCCCCCCCC......
......CCBBBYBCCCCCCCYCCCCC......
........CBBBYCCCCCCYCCCC........
.........CCBCCCCCCCCCCC.........
...........CCCCCCCCCC...........
................................
................................
................................
```

#### shield_n (16 x 12)

A shield plate, the north one. East, south and west are this turned 1, 2 and 3 quarter turns clockwise. Each sits 1 cell off the core's rim. A shield is an air target: Zapper hits crack it.

Legend: `A` Shell Light `AEBED6`, `B` Shell `6C7C98`, `C` Shell Dark `3A4560`, `K` Ink `0A1018`, `Y` Signal `FFD64A`.

```
......CCCC......
...CCCBBBBCCC...
.CCAAABYYBBCCCC.
CAAAAABYYBBCCCCC
AAAAAABBBBBCCCCC
AAAAAKKKKKKCCCCC
AAAKK......KKCCC
AAKK........KKCC
AKK..........KKC
AK............KC
K..............K
K..............K
```

#### shield_n_cracked (16 x 12)

The plate after its first hit: dark cracks, two white sparks. The second hit breaks it off (section 4).

Legend: `A` Shell Light `AEBED6`, `B` Shell `6C7C98`, `C` Shell Dark `3A4560`, `K` Ink `0A1018`, `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
......CCCC......
...CCCBBBBCCC...
.CCAAABYYBWKCCC.
CAAAKABYYBKCCCCC
AAAAAKBBBBKCCCCC
AAAAAKWKKKKCCCCC
AAAKK......KKCCC
AAKK........KKCC
AKK..........KKC
AK............KC
K..............K
K..............K
```

### 3.6 Explosions

#### air_boom_1 (16 x 16)

Air explosion, frame 1 of 5 (4 frames each, 20 frames in all).

Legend: `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................
................
................
................
.....YYYYYY.....
....YYWWWWYY....
....YWWWWWWY....
....YWWWWWWY....
....YWWWWWWY....
....YWWWWWWY....
....YYWWWWYY....
.....YYYYYY.....
................
................
................
................
```

#### air_boom_2 (16 x 16)

Air explosion, frame 2 of 5 (4 frames each, 20 frames in all).

Legend: `F` Fire `FF8A2A`, `R` Fire Dark `C8402A`, `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................
.....RRR.RR.....
.....FFFFFFR....
...RFFFYYFFF....
..RFFYYYYYYFFR..
.RFFYYYYYYYYFFR.
.RFFYYWWWWYYFFR.
.RFYYYWWWWYYYFR.
..FYYYWWWWYYYF..
..FFYYWWWWYYFFR.
..FFYYYYYYYYFFR.
..RFFYYYYYYFF...
....FFFYYFFF....
.....FFFFFFR....
.....R..R.......
................
```

#### air_boom_3 (16 x 16)

Air explosion, frame 3 of 5 (4 frames each, 20 frames in all).

Legend: `F` Fire `FF8A2A`, `R` Fire Dark `C8402A`, `Y` Signal `FFD64A`.

```
........R.......
....R.RRRR.R....
....RRRFRFFRR...
...RRRRRRFRRR...
..RFRYFFYYYRRF..
..RRFFYFFFFFRRR.
.RFRFYF.YFFFRFR.
.RRRYF.YYYYFRRR.
.FRFFY...YFYRFR.
.RRRFYFYYFFFRRR.
..RRFFFFYFFFFFR.
..RRRFYFFFFRRR..
...RFFFRFRRFR...
....FRRRRRFR....
....R.RRFF.R....
................
```

#### air_boom_4 (16 x 16)

Air explosion, frame 4 of 5 (4 frames each, 20 frames in all).

Legend: `R` Fire Dark `C8402A`, `S` Smoke `5C4C48`.

```
................
....S.RSSSSS....
...R.S..SS.RS...
...SSRSSSS.S.S..
.SRRSS.....SSR..
.SR.S......RR.S.
..SS........RR..
.S.S.........SS.
.S.R........RRR.
.S.S........SR..
.SR.S......SSSR.
...S.S....SSRS..
..S.SSR...SRSS..
...RRS..S..R....
.....RS.SSSR....
................
```

#### air_boom_5 (16 x 16)

Air explosion, frame 5 of 5 (4 frames each, 20 frames in all).

Legend: `S` Smoke `5C4C48`.

```
......S.S.......
.....S..SS......
....S...........
...S......SSS...
...S............
.SS.........SS..
.............S.S
..S..........S..
.SS...........SS
...............S
.S..........S.S.
.S.S........S...
...S........S...
..S.....S....S..
.........SSS....
.......S........
```

#### ground_boom_1 (32 x 32)

Ground burst, frame 1 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................................
................................
................................
................................
................................
................................
................................
................................
................................
.............YYYYYY.............
............YYYYYYYY............
...........YYYWWWWYYY...........
..........YYWWWWWWWWYY..........
.........YYYWWWWWWWWYYY.........
.........YYWWWWWWWWWWYY.........
.........YYWWWWWWWWWWYY.........
.........YYWWWWWWWWWWYY.........
.........YYWWWWWWWWWWYY.........
.........YYYWWWWWWWWYYY.........
..........YYWWWWWWWWYY..........
...........YYYWWWWYYY...........
............YYYYYYYY............
.............YYYYYY.............
................................
................................
................................
................................
................................
................................
................................
................................
................................
```

#### ground_boom_2 (32 x 32)

Ground burst, frame 2 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `F` Fire `FF8A2A`, `R` Fire Dark `C8402A`, `W` Flash `FFFFFF`, `Y` Signal `FFD64A`.

```
................................
................................
................................
................................
................................
.............FFFFFF.............
..........FFFFFFFFFFFR..........
.........FFFRRFFFFRFFFR.........
........FFFFFYYYYYYRFFFF........
.......FFFFYYYYYYYYYYRFFF.......
......FFFFYYYYYYYYYYYYFFFF......
......FFFYYYYYYYYYYYYYYFFF......
......FFFYYYYYWWWWYYYYYFFF......
.....FFFYYYYYWWWWWWYYYYYFFF.....
.....FFFYYYYWWWWWWWWYYYYFFF.....
.....FFFYYYYWWWWWWWWYYYYFFF.....
.....FFFYYYYWWWWWWWWYYYYFFF.....
.....FFFYYYYWWWWWWWWYYYYFFF.....
.....FFFYYYYYWWWWWWYYYYYFFF.....
......FFRYYYYYWWWWYYYYYFFF......
......FRFYYYYYYYYYYYYYYFRF......
......FRFFYYYYYYYYYYYYFFFF......
.......FFFFYYYYYYYYYYFFFF.......
........FFFFFYYYYYYFFFFF........
.........FFFFFFRFFFFFFF.........
..........FFFFFFFFFFFF..........
.............FRFFFF.............
................................
................................
................................
................................
................................
```

#### ground_boom_3 (32 x 32)

Ground burst, frame 3 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `F` Fire `FF8A2A`, `R` Fire Dark `C8402A`, `Y` Signal `FFD64A`.

```
................................
................................
................................
................................
........RRFR........RRRR........
........RRRFR......RRRRF........
........RFRRRR....RRRRRR........
........RRRRRFFFFFFRRFRR........
........RFRFFFFFFFFFFFRR........
.........FFFFFFFFFFFFFR.........
.........FFFFFFFFFFFFFF.........
........FFFFFFYYYYFFFFFF........
........FFFFYYYYYYYYFFFF........
....RFRFFFFFYYYYYYYYFFFFFRRR....
...RFRRFFFFYYYYYYYYYYFFFFRRRF...
..FRRRRFFFFYYYYYYYYYYFFFFRRRRR..
..FRRRRFFFFYYYYYYYYYYFFFFRRRRR..
...RRFRFFFFYYYYYYYYYYFFFFRRRR...
....RRRFFFFFYYYYYYYYFFFFFRRR....
........FFFFYYYYYYYYFFFF........
........FFFFFFYYYYFFFFFF........
.........FFFFFFFFFFFFFF.........
.........RFFFFFFFFFFFFF.........
........RRRFFFFFFFFFFFRR........
........RRRRRFFFFFFRRRRR........
........RFRRFR....FFFRRR........
........RRRRR......FRRRR........
........RRRR........RRFR........
................................
................................
................................
................................
```

#### ground_boom_4 (32 x 32)

Ground burst, frame 4 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `F` Fire `FF8A2A`, `R` Fire Dark `C8402A`, `S` Smoke `5C4C48`.

```
................................
................................
.................S.S............
...........S........S...........
..........SSSR.RSRS.SS.S........
.........SRR.RRRRRR.RS..........
.........RR.SRRSRRRRR.R.........
........SRRRR..S.RR..SRR.S......
.....S..R.RR.RRRRSR.RRS.RSSS....
....S..RR.SR.SSRRRRSSRS.RR......
...SSSR.R.RRRSFFFF.SRSSRSS..S...
...S.RR.RSR.FFFFFRRRRRSRRR..S...
...S.S.RR.RFFFFFFFFRFRRR.RS.S...
..SSR.RS..RFRRFFFRFRFSRRSRSSS...
....RRS.SRFRRRFRRRFFFFRSRRR.....
.....RRRSRRRRRFRFFFRRF.RRSRR....
....RSRRRSRFFFRFRRRFRRRRRR.R....
....RS.R.RFRRFFFFFRRRR..RR..S...
.....S.R.S.RFRFFFRFRF.RRSRSRS...
...S.RSRR.RFFRRRFFFFFRSRRRR.....
.....RSRRSRRRFFFFRFR...RSS......
.....SRSRR.R.SRRRR.S.RRRSR..S...
......R.SRRRSRRSRRRRRS...R......
.....S.RSRRR.R.RS.SRS.RSS.......
.......S..RSSRR.SSRS.R.RS.......
........SR.SRRRRSSRR.RRS........
.........SRSR.RRRSSSS..S........
.............RRRR.R..S..........
.............SS.....S...........
................S...............
................................
................................
```

#### ground_boom_5 (32 x 32)

Ground burst, frame 5 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `R` Fire Dark `C8402A`, `S` Smoke `5C4C48`.

```
................................
..............S..S.S............
................................
................................
................S...............
............S...................
.............SR.S........S......
....S......RR.S.S..SR..S........
....S....SSS.SS.S..SR...........
...S.........S.SS...S..S....S...
.....S..S..S..S.SSSS...S........
.......S..SSSS..S..SS.S.S.......
.......S.SR..S...S......S.S.....
....S..S.SSR..RRS.S..SS.SSS.....
...S..S.S..SS..RSS.SSR..SR......
.......SS.S..SSS..S.S...SS......
.......S.....S.SSS.S....SS......
....SSSSS.S.S....R.....SSR....S.
......SSS.SRSS.......RSS.S......
.SSS....S..SRS..SS.S.S.S........
....S...SSS....S..R.SRS...SS.S..
.........S..S.RRS.SS...RS..S....
..........SSR..S.SSR..SS........
...S............S..SS.S.........
........S..S.S.S.RSS....S.......
.....S....S...SS.S.........S....
.....................S..........
....................S...........
..................S...S.........
....................S...........
..............S.................
................................
```

#### ground_boom_6 (32 x 32)

Ground burst, frame 6 of 6 (5 frames each, 30 frames in all). Centred on the target. Frame 1 is also when the scorch is laid on the ground layer, under the burst.

Legend: `S` Smoke `5C4C48`.

```
................................
................................
................S...............
.............S..................
................................
..................SS............
.......S.....S...S..S..S........
.......S...........S............
.........SS.S............S......
....S..................S..S.....
...........S..........S.........
....S......S..........S.........
.....SS...................S.....
........S....................S..
....S.....................S.S...
......................SSS.......
...........................SS...
........S.......................
...........................S....
..S.....S..................SS...
...S....S.......................
.........S..S......S......S.....
.....S.SS........S..S..S........
....S..........S......S.........
.......................S.SS.....
..........S...S.................
.....................S..S.......
..........S.S....S...S..........
................S...............
................................
................................
................................
```

### 3.7 The Lark breaking up

The Lark is cut into four pieces (below; each grid is the whole 16 x 16 with only that piece's cells kept). Over **90 frames** (1.5 seconds) each piece moves by its drift times frames / 4 cells, starting from its start offset. From frame 12 each cell is mixed toward Smoke by `min(1, 1.4 x frame / 90)`; a cell is dropped when `((x * 7 + y * 11) mod 10) / 10` is below `frame / 90`, so the pieces crumble rather than blink out. The air explosion plays over the middle for its first 20 frames. See `skylark-breakup.png`.

| Piece | Start offset | Drift (cells a frame x 4) |
|---|---|---|
| nose | (0, -1) | (0.0, -0.6) |
| wing_left | (-1, 0) | (-0.7, 0.2) |
| wing_right | (1, 0) | (0.7, 0.2) |
| tail | (0, 1) | (0.0, 0.5) |

#### lark_piece_nose (16 x 16)

Legend: as `lark`.

```
................
.......KK.......
......KWMK......
......KGGK......
.....KWGGMK.....
.....KWMDMK.....
.....KWMDMK.....
................
................
................
................
................
................
................
................
................
```

#### lark_piece_wing_left (16 x 16)

Legend: as `lark`.

```
................
................
................
................
................
................
................
...KWK..........
..KWWK..........
.KWOWK..........
KWWOWW..........
KWWWWK..........
.KKKKK..........
................
................
................
```

#### lark_piece_wing_right (16 x 16)

Legend: as `lark`.

```
................
................
................
................
................
................
................
..........KMK...
..........KMMK..
..........KMOMK.
..........MMOMMK
..........KMMMMK
..........KKKKK.
................
................
................
```

#### lark_piece_tail (16 x 16)

Legend: as `lark`.

```
................
................
................
................
................
................
................
......WMDM......
......WMDM......
......WMDM......
......WMDM......
......WMDM......
......DMDD......
......DKKD......
......K..K......
................
```

## 4. Animation recipes (frames at 60 a second)

| Thing | Recipe |
|---|---|
| Lark | Level when not moving sideways. `lark_bank_left` or `_right` from the first frame of sideways movement; back to level 4 frames after it stops. |
| Flame | `flame_1` and `flame_2` swap every 4 frames; `flame_2` only while moving up. |
| Zap | No frames. Moves 6 cells a frame. Bloom: Zap Glow at 30% on the cells round it. |
| Bomb | Frames 1 2 3 2, 3 frames each, until the last 4 frames, which stay on 3. Moves from the Lark to the sight in 32 frames in a straight line (it is a lob seen from above: it grows by nothing, the shadow tells the story). The shadow starts under the Lark and reaches the sight on the same frame. |
| Sight | Normal or locked; locked is decided every frame. Locked gets a bloom of Sight Lock at 30%. |
| Whirl | 4 frames, 3 frames each (a turn in 12 frames). |
| Skate | flat while gliding; dive while going down the screen faster than the land; rise for 8 frames as it pulls out. |
| Kite | 1 2 3 4 3 2, 6 frames each; it fires on the frame it reaches 3. |
| Glint | 1 2 3 4 3 2, 5 frames each while it reflects (shots that hit on frame 1 are reflected), then frame 3 (edge on) for its dive. |
| Midge | 1 2, 2 frames each. |
| Wisp | 1 for 8 frames (no box), then 2 and 3 swapping every 6 frames, then 3 for the last 12 frames before the ring of bullets. |
| Swift | 1 2, 3 frames each. |
| Anvil | 6 frames, 4 frames each (a half turn in 24; frames 1 to 6 then 1 again, as the plate is the same both ways round). |
| Bullet | 1 2, 2 frames each. Bloom: Hot at 40%. |
| Beetle | 1 2, 4 frames each while moving; stays on its frame when it stops. |
| Hive | closed; open for the 20 frames before a Wisp leaves it, then closed. |
| Spire | hidden: nothing is drawn. While the sight centre is in its box: `spire_flicker` on frames where `frame mod 16` is 0 or 1. Bombed: `spire` for 24 frames, then a ground burst and `spire_scorch`. |
| Pennant | 1 2, 8 frames each, until collected or scrolled off. |
| Citadel | core: still. Hit: `citadel_core_hit` 2 frames, then ground bursts at the core and at the four plate sockets, 6 frames apart, and the scorch of the core (`henge_scorch` doubled to 32 x 32) is left on the ground. |
| Shields | whole; after the first hit `shield_n_cracked`; the second hit breaks it off: it drifts out from the core at 1 cell a frame for 30 frames, its cells mixed toward Smoke by frame / 30, with an air explosion at its middle on the first frame. |
| Air explosion | 5 frames, 4 frames each. |
| Ground burst | 6 frames, 5 frames each. Light on the land for its first 8 frames (section 5). |
| Area marker | see 5.2. |

## 5. Motion and finish (the modern part)

Drawing order, back to front: ground tiles (with mood), scorches, ground targets, explosion light, ground shadows, bomb shadow, haze, sight, bomb, air enemies, ground bursts and air explosions, bullets, shots, the Lark and its flame, the strips, words.

| Effect | What | Cost |
|---|---|---|
| Haze | Clouds above the land: soft lumps (an ellipse with a wobbling rim) drawn as a tint of Haze at 22%; the rim is every other cell (a checker), which reads as soft at 3x with no blending. They move down at 1.25 times the land's speed and drift sideways 1 cell every 64 frames, so the land seems to slide under them. 2 or 3 on screen. | about 2000 tint cells a frame at most (a fixed cost, like the ground) |
| Explosion light | Ground bursts and the Citadel throw light on the land under them: three rings of Glow Light, 30% inside 8 cells, 20% to 16, 10% to 24, all scaled by `1 - frame / 8`, for 8 frames. Drawn on the ground only, so it warms the land and not the sprites. | up to 1800 tint cells for 8 frames per burst; at most 2 at once |
| Bloom | A one cell halo round bullets (Hot, 40%), shots (Zap Glow, 30%) and the locked sight (Sight Lock, 30%): the 4 neighbour cells of the sprite outline, tinted. | about 12 cells a bullet, well inside the particle budget |
| Shadows | Everything in the air casts its outline on the ground as a tint of Ink at 35%: the Lark offset (+6, +10), air enemies (+4, +6), the bomb (its own shadow sprite). Ground targets cast none (their shade is drawn in). | one tint per sprite cell |
| Scanlines | Optional, off by default (`skylark.scanlines`): every odd canvas row mixed toward Ink by 12%. It costs the whole field, so it is the one pass worth switching off on a slow machine. | 28672 tints a frame when on |

## 6. Screens

### 6.1 The strips

- **Top** (rows 0 to 15, Strip with an Ink line on row 15): `SCORE` in Text Dim at (6, 1), the score in Signal after it; `HI` in Text Dim at (128, 1), the hi-score in Zap Glow after it. One quiet line; the second line is left empty on purpose.
- **Bottom** (rows 272 to 287): one mini Lark (7 x 7, below) per spare life from (6, 276), 10 cells apart; `AREA 03` in Text, right aligned 6 cells from the edge.

#### mini_lark (7 x 7)

Legend: as `lark` (`K` Hull Ink, `W` Hull, `M` Hull Mid, `G` Glass, `O` Wing Mark).

```
...K...
..KWK..
..KGK..
.KWWMK.
KWOWMOK
KKWWMKK
..K.K..
```

- All words are the 5 x 7 font. Big words (titles, AREA, GAME OVER) are 3x or 4x in the dawn gradient (Dawn Top to Dawn Low, top to bottom) with an Ink outline one cell wide; ordinary words are 1x in Text or Text Dim; numbers that matter (score, bonus) are Signal.

### 6.2 Area start (`skylark-preview-area.png`, left)

The land keeps scrolling. A band 30 rows tall across the middle of the field (from row 120), the land under it mixed toward Strip by 80%, with a Wing Mark line on its top and bottom rows. `AREA 4` at 3x in the dawn gradient, centred. A short bar of Flash, 24 cells long, runs along the top line left to right and along the bottom line right to left at 6 cells a frame (the sweep). The band is up for 120 frames: it opens from its middle line to full height over the first 10 and closes over the last 10.

### 6.3 End of area bonus (`skylark-preview-area.png`, right)

A panel 192 x 160 (from (16, 56)), the land under it mixed toward Strip by 82%, Wing Mark lines top and bottom. `AREA 3 CLEAR` at 2x in the dawn gradient. Three lines (label in Text Dim, value in Text, right aligned): ground targets destroyed of all on the area, the percentage, Spires found. A bar of one 5 x 5 square per ground target, two rows of 24: the squares light in Signal one every 3 frames as the count goes up, the rest stay Stone Dark. Then `BONUS` at 2x and the bonus in Signal, which counts up with the squares.

### 6.4 Title (`skylark-preview-title.png`)

The land of area 1 scrolls slowly under an Ink veil of 55%. The **lark land line** in the land is drawn in Dawn Top instead of its usual colour, as if lit by the sun: the logo grows from it. `SKYLARK` at 4x in the dawn gradient with an Ink outline, then three horizon lines (Dawn Low 150 long, Wing Mark 110, Dawn Top 60), like a sunrise. The roll call: `AIR` and `GROUND` in Text Dim, five of each with their points in Signal (the Anvil's points are a `?`, a hint at the trick). `PUSH FIRE` at 2x in Text, blinking 40 frames on, 20 off.

### 6.5 Game over and pause (`skylark-preview-over.png`)

- **Game over**: the land stops, an Ink veil of 50%, `GAME OVER` at 3x in the dawn gradient with an Ink outline, the area reached and its percentage in Text Dim under it. 4 seconds, then the title.
- **Pause**: everything freezes, a Strip veil of 60% over the field (the strips stay bright), `PAUSED` at 3x in Text with an Ink outline, `P TO PLAY ON` in Text Dim.

The words are drawn by the painter, not the window banner (as in Tetris and Snake). The font has no `%` or `/`, so the screens say `PCT` and `OF` (9.6).

## 7. Budgets

- Sprites: the busiest moment in the in game preview has 24 sprites; a heavy wave (8 Whirls, 12 bullets, 4 ground targets, the sight, the bomb, 2 shots, the Lark, 2 explosions) is about 32, inside the 60.
- Particles: the breakup is 4 pieces (sprites, not particles); bloom is about 12 tint cells a bullet. Nothing else uses particles, so the 100 particle cells are free for the code (smoke trails, sparks off the Anvil).
- Tints a frame: shadows (about 150 x the number of air things), haze (up to 2000), explosion light (up to 1800 a burst, 2 at once), bloom (about 12 each). The mood tint is paid once per tile row, not per frame.

## 8. Checks (run by the generator)

- Limits: all passed (every sprite at most 8 colours plus transparent, 16 x 16 at most except the Citadel core and the ground bursts at 32 x 32, every tile 16 x 16 and at most 8 colours in either family, the palette at most 64 distinct values).
- Forest joins: of every pair of forest tiles that may sit side by side, the worst agrees on 16 of the 16 cells of the join.
- Contrast (WCAG ratio, luminance only) of the things that must be seen, against each ground:

| Thing | Meadow | Ochre | Canopy | River | Road | Foam | Earth |
|---|---|---|---|---|---|---|---|
| Hot | 1.0 | 1.4 | 2.1 | 1.4 | 1.1 | 2.7 | 2.2 |
| Hot Core | 2.7 | 2.0 | 5.8 | 4.0 | 3.0 | 1.0 | 6.1 |
| Ink | 5.8 | 7.8 | 2.7 | 4.0 | 5.3 | 15.7 | 2.6 |
| Sight | 2.9 | 2.1 | 6.1 | 4.1 | 3.1 | 1.1 | 6.4 |
| Sight Lock | 1.0 | 1.4 | 2.1 | 1.4 | 1.1 | 2.7 | 2.2 |
| Zap | 3.3 | 2.4 | 7.0 | 4.7 | 3.6 | 1.2 | 7.3 |
| Zap Glow | 2.5 | 1.9 | 5.3 | 3.6 | 2.7 | 1.1 | 5.5 |
| Plum | 1.8 | 2.4 | 1.2 | 1.2 | 1.7 | 4.8 | 1.2 |
| Rust | 1.3 | 1.8 | 1.6 | 1.1 | 1.2 | 3.6 | 1.7 |
| Hull | 3.0 | 2.2 | 6.4 | 4.3 | 3.3 | 1.1 | 6.7 |
| Iron | 3.3 | 4.4 | 1.6 | 2.3 | 3.0 | 8.9 | 1.5 |

How to read it: Hot and Sight Lock are pure colour (about 1 to 2 against the land in brightness), which is why neither is ever drawn alone. A bullet is a Hot ring round a Hot Core and gets a Hot bloom; the sight always has its Ink keyline (Ink is 2.6 or better on every ground, and much better on the light ones where Sight is weakest). Under the three colour blindness simulations (`skylark-colour-check.png`) the bullet stays the lightest small thing on the land, the locked sight goes dark where the normal sight is light (so the change still reads, by brightness), and plum enemies stay apart from green land in all three.

## 9. What I decided and why, and open questions

1. Original designs throughout, as said at the top. The genre, layout and rules are the brief's; the look and every character are new.
2. Strips: the brief says 224 x 256 plus a score strip with the lives at the bottom. I made the canvas 224 x 288, a 16 row strip above and below, so the playfield is the full 224 x 256.
3. Two ground families instead of 16 palettes: green and dry share every tile through three letters, and the 16 areas differ by family, mood tint and features. That keeps the palette at 63 and makes 16 distinct looks.
4. The sight has an Ink keyline. The brief says one colour; I kept one colour for the sight itself and added the keyline because no single colour reads over foam, ochre and dark forest at once.
5. The bomb has no fall animation in size, only the pulse and the shadow sliding to the sight: from straight above a falling thing does not shrink much, and the shadow makes the landing point plain.
6. The font has no `%` or `/`. The screens say `PCT` and `OF`. If the font gets those two glyphs later, use them.
7. The Citadel takes Zapper hits on its shields and Blaster hits on its core. If the rules want the shields to need bombs too, the art does not change.
8. Scorch marks belong to the ground layer, not the sprite list, so they cost nothing per frame once laid.
9. **Names in code.** The brief puts the art in `XeviousArt`, `XeviousLook`, `XeviousTint` and `XeviousTiles` and the rules in `XeviousRules`. Since the game is not that game, I suggest `SkylarkArt`, `SkylarkLook`, `SkylarkTint`, `SkylarkTiles`, `SkylarkRules` and a `Games/Skylark` folder. Open: your call.
10. The generator is in `docs/design/skylark-generator/` (Python 3 and Pillow). `python run_all.py` writes this file and every picture into `docs/design`. It does not yet write the ABL classes: the brief says a script like `tools/gen-foreach-art.py` will, once the code is started.
11. Open: should the Anvil trick (1000 points for enough hits in a row) show anything? I would flash its rim (Iron Light to Flash) on each hit of a run, so the player learns the trick exists. Not drawn yet.
12. Open: the hidden Pennant spot and the hidden Spire spot have no tell at all, as the brief asks. If they should, a single cell of Ochre Light in the ground tile under them would be the gentlest hint.

## 10. Sprite index

| Sprite | Size | Group |
|---|---|---|
| `lark` | 16 x 16 | player |
| `lark_bank_left` | 16 x 16 | player |
| `lark_bank_right` | 16 x 16 | player |
| `flame_1` | 16 x 3 | player |
| `flame_2` | 16 x 3 | player |
| `zap` | 3 x 6 | player |
| `bomb_1` | 7 x 7 | player |
| `bomb_2` | 7 x 7 | player |
| `bomb_3` | 7 x 7 | player |
| `bomb_shadow` | 5 x 3 | player |
| `sight` | 15 x 15 | player |
| `sight_lock` | 15 x 15 | player |
| `whirl_1` | 16 x 16 | air |
| `whirl_2` | 16 x 16 | air |
| `whirl_3` | 16 x 16 | air |
| `whirl_4` | 16 x 16 | air |
| `skate_flat` | 16 x 16 | air |
| `skate_dive` | 16 x 16 | air |
| `skate_rise` | 16 x 16 | air |
| `kite_1` | 16 x 16 | air |
| `kite_2` | 16 x 16 | air |
| `kite_3` | 16 x 16 | air |
| `kite_4` | 16 x 16 | air |
| `glint_1` | 16 x 16 | air |
| `glint_2` | 16 x 16 | air |
| `glint_3` | 16 x 16 | air |
| `glint_4` | 16 x 16 | air |
| `midge_1` | 12 x 12 | air |
| `midge_2` | 12 x 12 | air |
| `wisp_1` | 16 x 16 | air |
| `wisp_2` | 16 x 16 | air |
| `wisp_3` | 16 x 16 | air |
| `swift_1` | 12 x 12 | air |
| `swift_2` | 12 x 12 | air |
| `anvil_1` | 16 x 16 | air |
| `anvil_2` | 16 x 16 | air |
| `anvil_3` | 16 x 16 | air |
| `anvil_4` | 16 x 16 | air |
| `anvil_5` | 16 x 16 | air |
| `anvil_6` | 16 x 16 | air |
| `bullet_1` | 5 x 5 | air |
| `bullet_2` | 5 x 5 | air |
| `cairn` | 16 x 16 | ground |
| `dish` | 16 x 16 | ground |
| `burr` | 16 x 16 | ground |
| `bastion` | 16 x 16 | ground |
| `beetle_1` | 16 x 16 | ground |
| `beetle_2` | 16 x 16 | ground |
| `henge` | 16 x 16 | ground |
| `hive_closed` | 16 x 16 | ground |
| `hive_open` | 16 x 16 | ground |
| `cairn_scorch` | 16 x 16 | scorch |
| `dish_scorch` | 16 x 16 | scorch |
| `burr_scorch` | 16 x 16 | scorch |
| `bastion_scorch` | 16 x 16 | scorch |
| `beetle_scorch` | 16 x 16 | scorch |
| `henge_scorch` | 16 x 16 | scorch |
| `hive_scorch` | 16 x 16 | scorch |
| `spire` | 16 x 16 | ground |
| `spire_flicker` | 16 x 16 | ground |
| `spire_scorch` | 16 x 16 | scorch |
| `pennant_1` | 16 x 16 | ground |
| `pennant_2` | 16 x 16 | ground |
| `citadel_core` | 32 x 32 | boss |
| `citadel_core_hit` | 32 x 32 | boss |
| `shield_n` | 16 x 12 | boss |
| `shield_n_cracked` | 16 x 12 | boss |
| `air_boom_1` | 16 x 16 | boom |
| `air_boom_2` | 16 x 16 | boom |
| `air_boom_3` | 16 x 16 | boom |
| `air_boom_4` | 16 x 16 | boom |
| `air_boom_5` | 16 x 16 | boom |
| `ground_boom_1` | 32 x 32 | boom |
| `ground_boom_2` | 32 x 32 | boom |
| `ground_boom_3` | 32 x 32 | boom |
| `ground_boom_4` | 32 x 32 | boom |
| `ground_boom_5` | 32 x 32 | boom |
| `ground_boom_6` | 32 x 32 | boom |

