# FootballManager: rules of the original, as the port will follow them

These are the rules and numbers of the 1982 BASIC game, written in our own words from a read of its published listing (`ftblmgr.bas`, line numbers in brackets are the listing's own). The listing was read through a converted web rendering that has a few damaged lines, so **check any number against the raw file before relying on it** (marked "check" below). The port is written from this page, not copied from the listing.

The name lists are at the end of this page.

## Shape of the game
- 4 divisions of 16 clubs, 64 in all (1 is the top). The player starts in division 4 (8947 to 8953).
- Division multiplier `d2 = 5 - division` (1 in division 4 up to 4 in division 1) scales money.
- **Set up** (8900 to 8990): manager name (20 characters), pick a club, level 1 to 7 (Beginner, Novice, Average, Good, Expert, Super Expert, Genius), the squad is **dealt at random**: 12 of the pool of 24 (the first 11 drawn start, the 12th is the reserve), with no choice and no say over positions, and the manager picks a kit colour, black or white (the other side wears the other).
- **Weekly loop** (100 to 199): menu, the match, the money report (8000), the season end check (8100), one transfer offer (8700). Menu: sell, loan, repay, status, level, change names, save, continue.

## Fixtures and season
- League: each other club once, 15 matches, home and away alternating from home (8 home, 7 away). The other clubs play 7 random pairings a week, scored by the rule below (not a real schedule).
- FA Cup: a cup match every third fixture while the club is still in (fixtures 2, 5, 8 and so on), 8 rounds. The season ends when 15 league matches and the cup are done.
- Points: win 3, draw 1. Table order: points, goal difference, goals for.
- Other clubs' scores: `INT(points per game + RND * 4)` for each side.

## Players
- Pool of 24 named players: 1 to 8 defenders, 9 to 16 midfielders, 17 to 24 forwards. A club owns at most 16 (a purchase is blocked at 16).
- Skill 1 to 5, energy 1 to 20, value `skill * 5000 * d2`. All three are **re-rolled for every player at each season reset**. Skill does not change in a season.
- Before each fixture (except the first of a season): a starter loses 1 energy, a reserve or injured player gains 10 (kept within 1 to 20). Each owned player has a **1 in 20 chance of injury** each fixture (injured players miss that fixture, cannot be picked or sold). Injury does not depend on energy.

## Team numbers
Five numbers each side, 1 to 20: **Energy** (sum of the starters' energy divided by 11, whole number), **Morale**, **Defence**, **Midfield**, **Attack** (sums of the starters' skill in each block; only starters count).
- **Opposition**, league: `INT(RND 1 to 14 + level + the opponent's points / this fixture number)`. Cup: `INT(RND 1 to 16 + level + (own slot - 1)/16 - ((opponent slot - 1)/16 + 1))`. Clamped 1 to 20.
- **Morale** starts at 10 each season. After a league match: win `a + INT((20 - a)/2)`, loss `INT(a/2)`, draw unchanged. (Cup matches apply the change twice, which looks unintended: decision below.)

## The match (5000 to 5110 and the pitch routines)
- For each of the five numbers in turn, roll 1 to 100. **Player attack** if `roll + 5 * (own - opposition) >= 75`; **opposition attack** if `roll + 5 * (opposition - own) >= 75`. That is a chance of `(26 + 5d) / 100` for a difference of `d`, clamped 0 to 1. Each event gives that side two attacks on the pitch. If the score is still 0 to 0 after the five rounds, each side gets one more attack.
- **An attack on the pitch**: the ball is dribbled 1, 3 or 5 steps (equal chance), 2 columns a step toward the goal, with a vertical drift that depends on the ball's row. If the next cell holds a player the ball moves into it: a defender turns it back, a team mate lets it run on, the keeper's cell is a save. The keeper stands on a diagonal in front of goal (rows 8 to 13) and steps toward the ball. On leaving the pitch it is a goal if it passes through the goal mouth (columns 7 to 14 or 17 to 24, rows 5 to 13, with a corner exception), otherwise no goal. **This is what the highlights will show.**
- A cup draw is replayed with home and away swapped until there is a winner.

## Money
- Starts at nothing: cash and loan are never set, so the first week's costs go into the loan.
- **Gate** (to the club, every fixture, whatever the result): league home `g` (5000 * d2 at a season start); after a league win, home or away, `g = g + INT((10000 * d2 - g) / 10)`, after a loss, home or away, `g = g - INT(g/10)` (not below 1000), a draw leaves it. League away `(17 - opponent's league position) * 500 * d2`. Cup home `g`; cup away `(5 - opponent's division) * 10000`; semi-final 50000, final 100000.
- **Weekly costs**: wages `sum of skill * 100 * d2` over every player owned, ground rent `500 * d2`, interest `INT(loan / 100)`. Cash below zero is turned into loan.
- **Loan**: allowed while `loan <= 250000 * d2` (check: the listing line is damaged). Repay needs the cash. **Going over the limit ends the game** (8060), the only way to lose.
- **Season end prize** `(17 - position) * 5000 * d2`. Top 3 promoted (from divisions 2 to 4), bottom 3 relegated (from divisions 1 to 3, none from 4).
- There is **no ground improvement feature** in the listing.

## Transfers
- After each match one random player not owned is offered. A bid is accepted if `k * bid >= 5 * value` for a random `k` from 1 to 10 (60 percent at the value, 80 percent at twice, 100 percent at five times). A refusal raises the value by a fifth. A signing becomes a reserve and has his value reset to `skill * 5000 * d2`.
- Selling: the offer is `INT(value * (RND * 5 + 8) / 10)`, from 0.8 to just under 1.3 times the value. Accepting sells the player. **Refusing: one chance in three nothing happens, two in three the player is injured.**

## Known quirks, and what we do about them (decisions for you)
1. Cup matches change morale twice (5200 to 5220, then 4350 to 4360). Faithful: keep it. Fix: once.
2. Fewer than 11 starters may be fielded, and energy still divides by 11.
3. The managerial rating is computed but never shown.
4. Starting cash and loan are zero, so the first money report shows debt immediately.
5. A refused sale can injure the player.
6. Some game over and loan limit messages are blank in the converted listing: we write our own text.

By default the port **keeps every quirk** (it is a faithful port) and each is a named setting-free constant in `FootballRules` so one can be changed later.

## Names (listing lines 9030 to 9260)

The raw file has two damaged spots in the player data (a missing quote before Neal, and Hunt split over two lines), fixed here.

**Players** (index order, 1 to 8 defenders, 9 to 16 midfielders, 17 to 24 forwards): P.Parkes, D.Watson, P.Neal, A.Martin, K.Sansom, M.Mills, R.Osman, S.Foster; B.Robson, G.Hoddle, G.Rix, S.Hunt, G.Owen, R.Moses, B.Talbot, S.McCall; C.Regis, P.Withe, T.Morley, P.Barnes, E.Gates, K.Reeves, K.Keegan, G.Shaw. These are the surnames of real players of 1982, so they are a decision for the owner.

**Clubs** (the 16 of each division, slot order):
- Division 1: Arsenal, Aston V., Brighton, Coventry, Everton, Ipswich, Liverpool, Luton, Man.City, Man.Utd, Norwich, Notts.F., Swansea, Spurs, Watford, West Ham.
- Division 2: Blackburn, Bolton, Cambridge, Charlton, Chelsea, Crystal P., Derby Co., Fulham, Grimsby, Leeds, Middlesbro, Newcastle, Oldham, Q.P.R., Rotherham, Sheff.Wed.
- Division 3: Bradford, Brentford, Bristol R., Cardiff, Doncaster, Exeter, Lincoln, Millwall, Newport, Orient, Oxford, Plymouth, Preston, Reading, Southend, Walsall.
- Division 4: Blackpool, Bury, Colchester, Crewe, Darlington, Halifax, Hartlepool, Hereford, Hull, Mansfield, Port Vale, Rochdale, Scunthorpe, Stockport, Torquay, York City.

Club names are at most 10 characters and player names at most 9, so the screens need no more width than that.

## The pitch of the port (as built in `PitchAttack`)

The pitch is 32 columns by 22 rows of cells. The original draws it in perspective, so each goal line is a diagonal: the ball leaves through the left goal where column plus row falls under 22, and through the right goal where column minus row goes over 9. A goal is a ball that leaves between rows 5 and 13 and columns 7 to 14 (left) or 17 to 24 (right), except by the corner at column 7 or 24, row 13 when it is drifting up. The home side (team 1) attacks the right goal, the away side the left. A match has at most 22 attacks (two for each of 5 numbers for each side, then one each if 0 to 0). A ball struck two columns at a time can skip over a one cell wide player, as in the original. One thing is not the original's: a ball that has not left the pitch after 40 steps counts as wide, so an attack always ends. The port's tests pin all of this.
