/* The chain that the Blast Buddies window is made of, without the window: a game with a computer player, the painter, the window's
   renderer and a grid view in direct colour, played for a while. What the painter draws must be what the view holds, and a long game must
   go on without an error. (Under prowin -b: the view can be built and read, but nothing ticks.) */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.BuddiesWindowChainTests:

    @Test.
    METHOD PUBLIC VOID TheViewHoldsThePictureAndALongGameGoesOnWithoutAnError():
        DEFINE VARIABLE bank    AS SoundBank           NO-UNDO.
        DEFINE VARIABLE player  AS WaveOutPlayer       NO-UNDO.
        DEFINE VARIABLE sound   AS SoundRenderer       NO-UNDO.
        DEFINE VARIABLE inp     AS BlastBuddiesInput   NO-UNDO.
        DEFINE VARIABLE rnd     AS SeededRandom        NO-UNDO.
        DEFINE VARIABLE keyList AS CHARACTER           NO-UNDO INITIAL "Left,Right,Up,Down,Return,Space".
        DEFINE VARIABLE k       AS CHARACTER           NO-UNDO.
        DEFINE VARIABLE g       AS BlastBuddiesGame    NO-UNDO.
        DEFINE VARIABLE p       AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE v       AS GridView            NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER             NO-UNDO.
        DEFINE VARIABLE bad     AS INTEGER             NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER             NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER             NO-UNDO.
        g = BlastBuddiesFactory:CreateWithTitle(NEW SeededRandom(3), NEW BuddySetup(2, 3, 1, Theme:Meadow, BuddySkill:Hard)).
        g:Brain = NEW SimulatingBrain(NEW SeededRandom(4), BuddySkill:Hard).
        v = NEW GridView().
        v:DirectColor = TRUE.
        v:ShowGridLines = FALSE.
        v:FitToWindow = TRUE.
        p = NEW BlastBuddiesPainter(NEW WinFormsGridRenderer(v, "view"), g, NEW SeededRandom(5)).
        p:SkipUnchanged = TRUE.
        bank = NEW SoundBank().
        BuddySounds:Fill(bank).
        player = NEW WaveOutPlayer(bank).
        sound = NEW SoundRenderer(p, NEW BuddyCues(), player).
        inp = NEW BlastBuddiesInput(g, NEW MemorySettings(), player).
        rnd = NEW SeededRandom(9).
        g:StartMatch().
        DO i = 1 TO 5000:
            IF i MODULO 5 = 0 THEN DO:
                k = ENTRY(rnd:NextInt(6) + 1, keyList).
                IF rnd:NextInt(2) = 0 THEN inp:HandleKey(k).
                ELSE inp:ReleaseKey(k).
                inp:StatusText.
                inp:TakeNotice().
            END.
            g:Tick(16).
            IF i MODULO 3 = 0 THEN sound:Render(g:Grid, g).
            IF g:IsOver THEN g:Initialise().
            IF g:Phase = BuddyPhase:Title THEN g:StartMatch().
        END.
        p:Render(g:Grid, g).
        DO y = 0 TO 239:
            DO x = 0 TO 383:
                IF v:PixelAt(x, y) <> p:Canvas:ColourAt(x, y) THEN bad = bad + 1.
            END.
        END.
        Assert:Equals(0, bad).
        player:Dispose().
        bank:Dispose().
        p:Dispose().
        v:ReleaseResources().
        g:Dispose().
    END METHOD.

END CLASS.
