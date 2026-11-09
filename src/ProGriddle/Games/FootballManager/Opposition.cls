/* Who the manager plays and how strong they are. A league match is against the club in slot DivisionBase + the match number (the manager's own slot is taken by the 16th club instead), an F.A. Cup round against a club of the right band of 8 slots (round 1 the bottom eight of the fourth division, up to the final against the top eight). The opposition's five numbers are drawn at random, shifted by the skill level and by how good the club is. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Opposition FINAL:

    METHOD PRIVATE STATIC INTEGER Roll(INPUT poRandom AS IRandom, INPUT piMost AS INTEGER):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("The opposition needs a random source").
        RETURN poRandom:NextInt(piMost) + 1.
    END METHOD.

    /* The slot of the club met in the league match the world is up to (LeagueMatch, 1 to 15, already counted). */
    METHOD PUBLIC STATIC INTEGER LeagueSlot(INPUT poWorld AS FootballWorld):
        VAR INTEGER slot.
        IF poWorld:LeagueMatch < 1 OR poWorld:LeagueMatch > FootballRules:LeagueMatches() THEN
            UNDO, THROW NEW GridException("There is no league match " + STRING(poWorld:LeagueMatch)).
        slot = poWorld:DivisionBase + poWorld:LeagueMatch.
        IF slot = poWorld:Slot THEN slot = poWorld:DivisionBase + FootballRules:ClubsPerDivision().
        RETURN slot.
    END METHOD.

    /* The slot of the club drawn for the cup round the world is up to (CupRound, 1 to 8, already counted): any club of the band of eight slots for that round except the manager's own. */
    METHOD PUBLIC STATIC INTEGER CupSlot(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        VAR INTEGER band.
        VAR INTEGER slot.
        IF poWorld:CupRound < 1 OR poWorld:CupRound > FootballRules:CupRounds() THEN
            UNDO, THROW NEW GridException("There is no cup round " + STRING(poWorld:CupRound)).
        band = (FootballRules:CupRounds() - poWorld:CupRound) * 8.
        IF poWorld:Slot > band AND poWorld:Slot <= band + 8 THEN
        DO:
            /* seven to choose from: skip over the manager's own slot */
            slot = band + Roll(poRandom, 7).
            IF slot >= poWorld:Slot THEN slot = slot + 1.
        END.
        ELSE slot = band + Roll(poRandom, 8).
        RETURN slot.
    END METHOD.

    /* One of the opposition's five numbers, drawn for a match of pkKind against the club in slot piOpponent, kept between 1 and 20. Call it once for each of the five. A league number is 1 to 14 plus the level plus the club's points a match so far; a cup number is 1 to 16 plus the level plus how far up the divisions the manager's club is, minus how far up the other is. */
    METHOD PUBLIC STATIC INTEGER Number(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom, INPUT poKind AS FixtureKind, INPUT piOpponent AS INTEGER):
        VAR DECIMAL n.
        CASE poKind:
            WHEN FixtureKind:League THEN
            DO:
                IF poWorld:LeagueMatch < 1 THEN UNDO, THROW NEW GridException("A league number needs a league match").
                n = Roll(poRandom, 14) + poWorld:Level + poWorld:PointsOf(piOpponent - poWorld:DivisionBase) / poWorld:LeagueMatch.
            END.
            OTHERWISE
                n = Roll(poRandom, 16) + poWorld:Level + (poWorld:Slot - 1) / 16 - ((piOpponent - 1) / 16 + 1).
        END CASE.
        RETURN MAXIMUM(1, MINIMUM(FootballRules:MaxEnergy(), INTEGER(TRUNCATE(n, 0)))).
    END METHOD.

END CLASS.
