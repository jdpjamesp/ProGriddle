/* The silent sound player and the recording double that tests use in its place: the ISoundPlayer contract. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundPlayerTests:

    @Test.
    METHOD PUBLIC VOID TheSilentPlayerPlaysNothingAndSaysItIsNotWorking():
        DEFINE VARIABLE oPlayer AS ISoundPlayer NO-UNDO.
        oPlayer = NEW NullSoundPlayer().
        oPlayer:Play(1).
        Assert:IsFalse(oPlayer:Working).
        oPlayer:Dispose().
        oPlayer:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnyPlayerRemembersItsMuteAndItsVolumeAndStartsLoud():
        DEFINE VARIABLE oPlayer AS ISoundPlayer NO-UNDO.
        oPlayer = NEW NullSoundPlayer().
        Assert:IsFalse(oPlayer:Muted).
        Assert:Equals(100, oPlayer:Volume).
        oPlayer:Muted = TRUE.
        oPlayer:Volume = 35.
        Assert:IsTrue(oPlayer:Muted).
        Assert:Equals(35, oPlayer:Volume).
        oPlayer = NEW RecordingSoundPlayer().
        Assert:IsFalse(oPlayer:Muted).
        Assert:Equals(100, oPlayer:Volume).
        oPlayer:Volume = 0.
        Assert:Equals(0, oPlayer:Volume).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVolumeOutsideZeroToOneHundredThrowsGridExceptionWhateverThePlayer():
        DEFINE VARIABLE oPlayer AS ISoundPlayer NO-UNDO.
        DEFINE VARIABLE thrown  AS INTEGER      NO-UNDO.
        oPlayer = NEW NullSoundPlayer().
        DO ON ERROR UNDO, THROW:
            oPlayer:Volume = 101.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oPlayer:Volume = -1.
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        oPlayer = NEW RecordingSoundPlayer().
        DO ON ERROR UNDO, THROW:
            oPlayer:Volume = 101.
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
        Assert:Equals(100, oPlayer:Volume).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRecordingPlayerListsTheCuesInOrderAndSkipsThemWhileMuted():
        DEFINE VARIABLE oPlayer AS RecordingSoundPlayer NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        Assert:Equals("", oPlayer:Played).
        oPlayer:Play(3).
        oPlayer:Play(1).
        oPlayer:Muted = TRUE.
        oPlayer:Play(2).
        oPlayer:Muted = FALSE.
        oPlayer:Play(1).
        Assert:Equals("3,1,1", oPlayer:Played).
        Assert:Equals(3, oPlayer:PlayCount).
        oPlayer:Forget().
        Assert:Equals("", oPlayer:Played).
        Assert:Equals(0, oPlayer:PlayCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRecordingPlayerNotesThatItWasDisposedAndWorks():
        DEFINE VARIABLE oPlayer AS RecordingSoundPlayer NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        Assert:IsTrue(oPlayer:Working).
        Assert:IsFalse(oPlayer:Disposed).
        oPlayer:Working = FALSE.
        Assert:IsFalse(oPlayer:Working).
        oPlayer:Dispose().
        Assert:IsTrue(oPlayer:Disposed).
    END METHOD.

END CLASS.
