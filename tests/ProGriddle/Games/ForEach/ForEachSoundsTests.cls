/* The sounds of FOR EACH: every cue has a recipe that makes real sound, the seven loops (the five alarms and the two drones) are the recipes
   that start with @, every cue has a volume from 1 to 100, and Fill puts every cue in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesRealSound():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE recipe AS CHARACTER NO-UNDO.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            recipe = ForEachSounds:Recipe(ForEachCue:GetEnum(i)).
            IF recipe BEGINS "@" THEN recipe = SUBSTRING(recipe, 2).
            oSynth:Make(recipe, 100, OUTPUT mData).
            loud = 0.
            DO j = 1 TO GET-SIZE(mData):
                IF ABSOLUTE(GET-BYTE(mData, j) - 128) > 20 THEN loud = loud + 1.
            END.
            Assert:IsTrue(loud > 100).
            SET-SIZE(mData) = 0.
        END.
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAlarmsAndTheTwoDronesAreTheLoopsAndNothingElseIs():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE loops AS INTEGER NO-UNDO.
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            IF ForEachSounds:Recipe(ForEachCue:GetEnum(i)) BEGINS "@" THEN loops = loops + 1.
        END.
        Assert:Equals(7, loops).
        Assert:IsTrue(ForEachSounds:Recipe(ForEachCue:Alarm1) BEGINS "@").
        Assert:IsTrue(ForEachSounds:Recipe(ForEachCue:ReturningLoop) BEGINS "@").
        Assert:IsFalse(ForEachSounds:Recipe(ForEachCue:Death) BEGINS "@").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundredAndTheLoopsSitUnderTheRest():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:GetEnum(i)) >= 1).
            Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:GetEnum(i)) <= 100).
        END.
        Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:Alarm3) < ForEachSounds:VolumeOf(ForEachCue:Death)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesEveryCueInABank():
        DEFINE VARIABLE oBank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        oBank = NEW SoundBank().
        ForEachSounds:Fill(oBank).
        Assert:Equals(15, oBank:Count).
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            Assert:IsTrue(oBank:Has(i)).
        END.
        FINALLY:
            IF VALID-OBJECT(oBank) THEN oBank:Dispose().
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCueThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE cue    AS ForEachCue NO-UNDO.
        DO ON ERROR UNDO, THROW:
            ForEachSounds:Recipe(cue).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
