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
        VAR INTEGER i.
        VAR INTEGER j.
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER loud.
        VAR CHARACTER recipe.
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
        VAR INTEGER i.
        VAR INTEGER loops.
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
        VAR INTEGER i.
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:GetEnum(i)) >= 1).
            Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:GetEnum(i)) <= 100).
        END.
        Assert:IsTrue(ForEachSounds:VolumeOf(ForEachCue:Alarm3) < ForEachSounds:VolumeOf(ForEachCue:Death)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesEveryCueInABank():
        VAR SoundBank oBank.
        VAR INTEGER i.
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
        VAR INTEGER thrown.
        VAR ForEachCue cue.
        DO ON ERROR UNDO, THROW:
            ForEachSounds:Recipe(cue).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
