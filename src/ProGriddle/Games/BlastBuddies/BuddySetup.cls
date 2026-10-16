/* What a Blast Buddies game is made of: how many teams (2 to 4), how many buddies each (3 or 4), how many of the last teams the computer
   plays (0 up to one less than the teams, so a person always plays the first), and the look of the land. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddySetup FINAL:

    DEFINE PUBLIC PROPERTY Teams AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY BuddiesEach AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY ComputerTeams AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY LandTheme AS Theme NO-UNDO GET. PRIVATE SET.

    /* How well the computer plays. */
    DEFINE PUBLIC PROPERTY Skill AS BuddySkill NO-UNDO GET. PRIVATE SET.

    /* True when every new map picks its own look at random (LandTheme is then only what the picker shows). */
    DEFINE PUBLIC PROPERTY RandomTheme AS LOGICAL NO-UNDO GET. PRIVATE SET.

    /* A game against a computer of Normal skill. */
    CONSTRUCTOR PUBLIC BuddySetup(INPUT piTeams AS INTEGER, INPUT piBuddiesEach AS INTEGER, INPUT piComputerTeams AS INTEGER, INPUT poTheme AS Theme):
        THIS-OBJECT(piTeams, piBuddiesEach, piComputerTeams, poTheme, BuddySkill:Normal).
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC BuddySetup(INPUT piTeams AS INTEGER, INPUT piBuddiesEach AS INTEGER, INPUT piComputerTeams AS INTEGER, INPUT poTheme AS Theme, INPUT poSkill AS BuddySkill):
        THIS-OBJECT(piTeams, piBuddiesEach, piComputerTeams, poTheme, poSkill, FALSE).
    END CONSTRUCTOR.

    CONSTRUCTOR PUBLIC BuddySetup(INPUT piTeams AS INTEGER, INPUT piBuddiesEach AS INTEGER, INPUT piComputerTeams AS INTEGER, INPUT poTheme AS Theme, INPUT poSkill AS BuddySkill,
                                  INPUT plRandomTheme AS LOGICAL):
        RandomTheme = plRandomTheme.
        IF piTeams < 2 OR piTeams > 4 THEN UNDO, THROW NEW GridException("A game has 2 to 4 teams, not " + STRING(piTeams)).
        IF piBuddiesEach < 3 OR piBuddiesEach > 4 THEN UNDO, THROW NEW GridException("A team has 3 or 4 buddies, not " + STRING(piBuddiesEach)).
        IF piComputerTeams < 0 OR piComputerTeams >= piTeams THEN UNDO, THROW NEW GridException("The computer plays 0 to " + STRING(piTeams - 1) + " teams").
        IF NOT VALID-OBJECT(poTheme) THEN UNDO, THROW NEW GridException("A game needs a theme").
        IF NOT VALID-OBJECT(poSkill) THEN UNDO, THROW NEW GridException("A game needs a skill for the computer").
        Skill = poSkill.
        Teams = piTeams.
        BuddiesEach = piBuddiesEach.
        ComputerTeams = piComputerTeams.
        LandTheme = poTheme.
    END CONSTRUCTOR.

    /* Two teams of three, a person against the computer, on the meadow. */
    METHOD PUBLIC STATIC BuddySetup Default():
        RETURN NEW BuddySetup(2, 3, 1, Theme:Meadow).
    END METHOD.

END CLASS.
