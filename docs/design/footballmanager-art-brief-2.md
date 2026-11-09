# Football Manager: art revision brief (round 2)

Written for: the designer (Claude Desktop), who delivered `footballmanager-art.md` ("Chalk and Floodlights"). The look, the board, the badges, the sprites and the screens are liked. This note lists what changes now that the owner has decided to stay as close to the original game as possible. Everything not mentioned stays as delivered.

## Decisions

1. **The name is Football Manager** (not Gaffer). Use it on the title and in the files. The cup is the **F.A. Cup**, written as the original writes it.
2. **Club and player names are the original's**, in `footballmanager-rules.md` (section "Names"): 64 clubs of at most 10 characters, 24 players of at most 9. Use them in every preview. The 8 badges are reused across the clubs, so give the mapping you prefer (for example by slot).
3. **The pitch is the original's, not a flat one.** The original draws the pitch in perspective, as a slanted parallelogram: each goal line is a diagonal, and the ball runs on a grid of **32 columns by 22 rows**. The rules in `footballmanager-rules.md` ("The pitch of the port") and the tests depend on it, so the picture has to follow it. Please redraw the match view so that:
   - the pitch is a 32 x 22 grid of cells, with the **left goal line on the diagonal where column + row = 22** and the **right goal line on the diagonal where column - row = 9**, and the touchlines at row 0 and row 21;
   - the goals are the stretches of those diagonals between **rows 5 and 13**, at columns 7 to 14 (left) and 17 to 24 (right);
   - only **seven figures** are on the pitch in an attack, not 22: three attackers (one dribbling the ball), three defenders and a keeper. Give a layout and the cell to pixel mapping for the 32 x 22 grid, and the ball's path along it (it moves two columns at a time, with a trail);
   - the keeper stands on a diagonal in front of the goal (column + row = 23 at the left, the mirror at the right) and steps along it toward the ball.
4. **The squad is dealt at random**: remove the "pick 12 players" screen. Replace it with a **kit colour** screen (black or white, the other side wears the other), and show the squad on the squad screen. Kits: the manager's side wears the chosen colour, the opposition the other, rather than home stripes and an away hoop (keep patterns so the sides differ by more than colour).
5. **Stay with the original's extras only**: no half time, no scorers, no cards or substitutes (drop those icons). Keep the goal mouth close-up, the one thing we add (as the C64 version had), and keep the blocked shot on the pitch with no close-up.
6. The red loan warning above 80% of the limit is not in the original: drop it.

## How to give it back

Update `docs/design/footballmanager-art.md`, the generator and the previews as before. The code will read the same file, so keep sprite names stable where nothing changes, and give the final cell to pixel numbers for the 32 x 22 pitch.
