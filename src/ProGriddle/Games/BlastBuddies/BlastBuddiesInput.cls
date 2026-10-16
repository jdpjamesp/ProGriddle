/* What a Blast Buddies window can do. All play is on the keyboard, for the buddy in turn (and only on a turn played by a person):

     Left, Right        walk (as long as the key is held), one pixel every 40 ms
     Up, Down           raise or lower the aim (as long as the key is held)
     Enter              hop; Enter twice within a quarter of a second makes a backflip
     Space              hold to build up power, let go to fire (at full power it goes by itself)

   P pauses and R or F2 starts a new game (the window's own keys). + and - make the game faster and slower, in steps of 10 percent of
   the real speed, and the speed is kept as blastbuddies.speed.

   Walking, aiming and firing are STATES, not events: a key held down is a buddy that keeps walking. The keyboard cannot be trusted to
   repeat a key while another is pressed, so this class does not use the repeats. It remembers which keys are down (HandleKey when one goes
   down, ReleaseKey when it comes up, and an empty name when the window loses focus) and tells the game the state each time. When both
   keys of a pair are down the one pressed last wins. A key that arrives again while it is down (key repeat) does nothing, so one press
   of Enter is one hop and one press of Space is one shot.

   The window offers five lists (IGameOptions), and choosing from one starts a new game with that setup, which the window keeps as
   blastbuddies.teams, .buddies, .computer, .skill and .theme: Teams 2 to 4, Buddies each 3 or 4, Computer teams None or 1 to 3 (the last
   teams are the computer's, and never all of them), Skill Easy, Normal or Hard, and Theme Meadow, Canyon, Candy or Random (a new look for every map). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesInput FINAL IMPLEMENTS IGameInput, IGameOptions:

    DEFINE PRIVATE VARIABLE mGame     AS BlastBuddiesGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings        NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mLeft     AS LOGICAL          NO-UNDO.
    DEFINE PRIVATE VARIABLE mRight    AS LOGICAL          NO-UNDO.
    DEFINE PRIVATE VARIABLE mUp       AS LOGICAL          NO-UNDO.
    DEFINE PRIVATE VARIABLE mDown     AS LOGICAL          NO-UNDO.
    DEFINE PRIVATE VARIABLE mEnter    AS LOGICAL          NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpace    AS LOGICAL          NO-UNDO.
    /* the key that went down last in each pair, 1 or -1, which wins when both are down */
    DEFINE PRIVATE VARIABLE mWalkLatest AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mAimLatest  AS INTEGER        NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            CASE mGame:Phase:
                WHEN BuddyPhase:Arrival THEN RETURN "Blast Buddies   Here they come".
                WHEN BuddyPhase:Winner THEN RETURN SUBSTITUTE("Team &1 wins   Press R for a new game", mGame:WinnerTeam).
                WHEN BuddyPhase:Draw THEN RETURN "A draw   Press R for a new game".
            END CASE.
            IF NOT VALID-OBJECT(mGame:CurrentBuddy) THEN RETURN "Blast Buddies".
            RETURN SUBSTITUTE("&1 (team &2)   Wind &3   Time &4   Power &5%   Speed &6%", mGame:CurrentBuddy:BuddyName, mGame:CurrentBuddy:Team,
                              mGame:Wind, INTEGER(TRUNCATE(mGame:TimeLeftMs / 1000, 0)), mGame:PowerPercent, mGame:SpeedPercent).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.
        SET(INPUT pcValue AS CHARACTER):
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    /* Always empty: the game draws its own words into the picture. */
    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    CONSTRUCTOR PUBLIC BlastBuddiesInput(INPUT poGame AS BlastBuddiesGame, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Blast Buddies input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Blast Buddies input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mGame:SpeedPercent = mSettings:GetInteger("blastbuddies.speed", 100).
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* A key went down. Returns true for the keys of the game, which the window then leaves alone. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        CASE pcKey:
            WHEN "Left" THEN DO:
                mLeft = TRUE.
                mWalkLatest = -1.
            END.
            WHEN "Right" THEN DO:
                mRight = TRUE.
                mWalkLatest = 1.
            END.
            WHEN "Up" THEN DO:
                mUp = TRUE.
                mAimLatest = -1.
            END.
            WHEN "Down" THEN DO:
                mDown = TRUE.
                mAimLatest = 1.
            END.
            WHEN "Return" OR WHEN "Enter" THEN DO:
                IF NOT mEnter THEN DO:
                    mEnter = TRUE.
                    IF mGame:HumanTurn THEN mGame:Jump().
                END.
                RETURN TRUE.
            END.
            WHEN "Space" THEN DO:
                IF NOT mSpace THEN DO:
                    mSpace = TRUE.
                    IF mGame:HumanTurn THEN mGame:StartCharge().
                END.
                RETURN TRUE.
            END.
            WHEN "Add" OR WHEN "Oemplus" THEN DO:
                ChangeSpeed(10).
                RETURN TRUE.
            END.
            WHEN "Subtract" OR WHEN "OemMinus" THEN DO:
                ChangeSpeed(-10).
                RETURN TRUE.
            END.
            OTHERWISE RETURN FALSE.
        END CASE.
        PassOn().
        RETURN TRUE.
    END METHOD.

    /* A key came up, or (an empty name) every key did, because the window lost the keyboard and the key ups of the keys that were down
       are never sent. Letting go of Space fires the shot being charged. */
    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? OR pcKey = "" THEN DO:
            mLeft = FALSE.
            mRight = FALSE.
            mUp = FALSE.
            mDown = FALSE.
            mEnter = FALSE.
            mSpace = FALSE.
            mWalkLatest = 0.
            mAimLatest = 0.
        END.
        ELSE CASE pcKey:
            WHEN "Left" THEN mLeft = FALSE.
            WHEN "Right" THEN mRight = FALSE.
            WHEN "Up" THEN mUp = FALSE.
            WHEN "Down" THEN mDown = FALSE.
            WHEN "Return" OR WHEN "Enter" THEN mEnter = FALSE.
            WHEN "Space" THEN DO:
                IF mSpace THEN DO:
                    mSpace = FALSE.
                    mGame:ReleaseCharge().
                END.
                RETURN.
            END.
            OTHERWISE RETURN.
        END CASE.
        PassOn().
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown Blast Buddies command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Tells the game which way to walk and which way to move the aim, if a person is playing the turn. */
    METHOD PRIVATE VOID PassOn():
        IF NOT mGame:HumanTurn THEN DO:
            mGame:SetWalk(0).
            mGame:SetAim(0).
            RETURN.
        END.
        mGame:SetWalk(IF mLeft AND mRight THEN mWalkLatest ELSE IF mLeft THEN -1 ELSE IF mRight THEN 1 ELSE 0).
        mGame:SetAim(IF mUp AND mDown THEN mAimLatest ELSE IF mUp THEN -1 ELSE IF mDown THEN 1 ELSE 0).
    END METHOD.


    /* ---- options (IGameOptions) ---- */

    DEFINE PUBLIC PROPERTY OptionCount AS INTEGER NO-UNDO
        GET():
            RETURN 5.
        END GET.

    METHOD PUBLIC CHARACTER OptionLabel(INPUT piOption AS INTEGER):
        CASE piOption:
            WHEN 1 THEN RETURN "Teams".
            WHEN 2 THEN RETURN "Buddies".
            WHEN 3 THEN RETURN "Computer".
            WHEN 4 THEN RETURN "Skill".
            WHEN 5 THEN RETURN "Land".
            OTHERWISE UNDO, THROW NEW GridException("Blast Buddies has no option " + STRING(piOption)).
        END CASE.
    END METHOD.

    METHOD PUBLIC CHARACTER OptionKey(INPUT piOption AS INTEGER):
        CASE piOption:
            WHEN 1 THEN RETURN "teams".
            WHEN 2 THEN RETURN "buddies".
            WHEN 3 THEN RETURN "computer".
            WHEN 4 THEN RETURN "skill".
            WHEN 5 THEN RETURN "theme".
            OTHERWISE UNDO, THROW NEW GridException("Blast Buddies has no option " + STRING(piOption)).
        END CASE.
    END METHOD.

    METHOD PUBLIC CHARACTER OptionNames(INPUT piOption AS INTEGER):
        CASE piOption:
            WHEN 1 THEN RETURN "2,3,4".
            WHEN 2 THEN RETURN "3,4".
            WHEN 3 THEN RETURN "None,1,2,3".
            WHEN 4 THEN RETURN "Easy,Normal,Hard".
            WHEN 5 THEN RETURN "Meadow,Canyon,Candy,Random".
            OTHERWISE UNDO, THROW NEW GridException("Blast Buddies has no option " + STRING(piOption)).
        END CASE.
    END METHOD.

    METHOD PUBLIC CHARACTER OptionValue(INPUT piOption AS INTEGER):
        CASE piOption:
            WHEN 1 THEN RETURN STRING(mGame:Setup:Teams).
            WHEN 2 THEN RETURN STRING(mGame:Setup:BuddiesEach).
            WHEN 3 THEN RETURN (IF mGame:Setup:ComputerTeams = 0 THEN "None" ELSE STRING(mGame:Setup:ComputerTeams)).
            WHEN 4 THEN RETURN STRING(mGame:Setup:Skill).
            WHEN 5 THEN RETURN (IF mGame:Setup:RandomTheme THEN "Random" ELSE STRING(mGame:Setup:LandTheme)).
            OTHERWISE UNDO, THROW NEW GridException("Blast Buddies has no option " + STRING(piOption)).
        END CASE.
    END METHOD.

    /* Chooses an item and starts a new game with it. A number of computer teams that leaves no team for a person is lowered to fit. */
    METHOD PUBLIC VOID SetOption(INPUT piOption AS INTEGER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE teams    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE buddies  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE computer AS INTEGER   NO-UNDO.
        DEFINE VARIABLE skill1   AS BuddySkill NO-UNDO.
        DEFINE VARIABLE land     AS Theme     NO-UNDO.
        DEFINE VARIABLE random1  AS LOGICAL   NO-UNDO.
        IF piOption < 1 OR piOption > 5 THEN UNDO, THROW NEW GridException("Blast Buddies has no option " + STRING(piOption)).
        IF pcValue = ? OR LOOKUP(pcValue, OptionNames(piOption)) = 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("&1 is not a choice for &2", pcValue, OptionLabel(piOption))).
        teams = mGame:Setup:Teams.
        buddies = mGame:Setup:BuddiesEach.
        computer = mGame:Setup:ComputerTeams.
        skill1 = mGame:Setup:Skill.
        land = mGame:Setup:LandTheme.
        random1 = mGame:Setup:RandomTheme.
        CASE piOption:
            WHEN 1 THEN teams = INTEGER(pcValue).
            WHEN 2 THEN buddies = INTEGER(pcValue).
            WHEN 3 THEN computer = (IF pcValue = "None" THEN 0 ELSE INTEGER(pcValue)).
            WHEN 4 THEN skill1 = (IF pcValue = "Easy" THEN BuddySkill:Easy ELSE IF pcValue = "Normal" THEN BuddySkill:Normal ELSE BuddySkill:Hard).
            OTHERWISE DO:
                random1 = (pcValue = "Random").
                IF NOT random1 THEN land = (IF pcValue = "Meadow" THEN Theme:Meadow ELSE IF pcValue = "Canyon" THEN Theme:Canyon ELSE Theme:Candy).
            END.
        END CASE.
        computer = MINIMUM(computer, teams - 1).
        mGame:Restart(NEW BuddySetup(teams, buddies, computer, land, skill1, random1)).
        mNotice = SUBSTITUTE("&1 teams of &2   Computer &3   &4", teams, buddies, OptionValue(3), skill1).
    END METHOD.

    /* Faster or slower by a number of percent, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piDelta AS INTEGER):
        mGame:SpeedPercent = MAXIMUM(10, MINIMUM(200, mGame:SpeedPercent + piDelta)).
        mSettings:SetInteger("blastbuddies.speed", mGame:SpeedPercent).
        mNotice = SUBSTITUTE("Speed &1%", mGame:SpeedPercent).
    END METHOD.

END CLASS.
