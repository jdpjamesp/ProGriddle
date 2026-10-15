/* The saved sound settings: sound.on and sound.volume, applied to a player, and the switch the games' inputs use. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundSettingsTests:

    DEFINE PRIVATE VARIABLE mPlayer   AS RecordingSoundPlayer NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings       NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildSettings():
        mPlayer = NEW RecordingSoundPlayer().
        mSettings = NEW MemorySettings().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNothingSavedSoundIsOnAtTheDefaultVolume():
        mPlayer:Muted = TRUE.
        mPlayer:Volume = 3.
        SoundSettings:Apply(mPlayer, mSettings).
        Assert:IsFalse(mPlayer:Muted).
        Assert:Equals(50, mPlayer:Volume).
        Assert:Equals(50, SoundSettings:DefaultVolume()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SavedSettingsMuteThePlayerAndSetTheVolume():
        mSettings:SetLogical("sound.on", FALSE).
        mSettings:SetInteger("sound.volume", 20).
        SoundSettings:Apply(mPlayer, mSettings).
        Assert:IsTrue(mPlayer:Muted).
        Assert:Equals(20, mPlayer:Volume).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVolumeOutsideZeroToOneHundredIsHeldToTheNearestEnd():
        mSettings:SetInteger("sound.volume", 500).
        SoundSettings:Apply(mPlayer, mSettings).
        Assert:Equals(100, mPlayer:Volume).
        mSettings:SetInteger("sound.volume", -4).
        SoundSettings:Apply(mPlayer, mSettings).
        Assert:Equals(0, mPlayer:Volume).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToggleSwitchesTheSoundSavesTheChoiceAndSaysWhatItDid():
        Assert:Equals("Sound off", SoundSettings:Toggle(mPlayer, mSettings)).
        Assert:IsTrue(mPlayer:Muted).
        Assert:IsFalse(mSettings:GetLogical("sound.on", TRUE)).
        Assert:Equals("Sound on", SoundSettings:Toggle(mPlayer, mSettings)).
        Assert:IsFalse(mPlayer:Muted).
        Assert:IsTrue(mSettings:GetLogical("sound.on", FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANeededPlayerOrSettingsThatIsMissingThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            SoundSettings:Apply(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SoundSettings:Apply(mPlayer, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SoundSettings:Toggle(?, mSettings).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SoundSettings:Toggle(mPlayer, ?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

END CLASS.
