/* The saved sound settings, shared by every game that has sound: sound.on (true or false, true when nothing is saved) and
   sound.volume (0 to 100, 50 when nothing is saved). Apply puts them on a player when a game is built, Toggle is the Sound
   command and the M key of a game's input. Both the keys are the same for every game, so sound is one choice for the whole
   framework. Reading never fails: a volume outside 0 to 100 is held to the nearest end. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundSettings FINAL:

    /* The volume when none is saved. */
    METHOD PUBLIC STATIC INTEGER DefaultVolume():
        RETURN 50.
    END METHOD.

    /* Mutes the player if sound.on is false and gives it the volume of sound.volume. */
    METHOD PUBLIC STATIC VOID Apply(INPUT poPlayer AS ISoundPlayer, INPUT poSettings AS ISettings):
        DEFINE VARIABLE volume AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poPlayer) OR NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Sound settings need a player and settings").
        volume = poSettings:GetInteger("sound.volume", DefaultVolume()).
        poPlayer:Volume = MINIMUM(100, MAXIMUM(0, volume)).
        poPlayer:Muted = NOT poSettings:GetLogical("sound.on", TRUE).
    END METHOD.

    /* Switches the sound on or off, saves the choice as sound.on and returns the notice to show, "Sound on" or "Sound off". */
    METHOD PUBLIC STATIC CHARACTER Toggle(INPUT poPlayer AS ISoundPlayer, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poPlayer) OR NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Sound settings need a player and settings").
        poPlayer:Muted = NOT poPlayer:Muted.
        poSettings:SetLogical("sound.on", NOT poPlayer:Muted).
        RETURN "Sound " + (IF poPlayer:Muted THEN "off" ELSE "on").
    END METHOD.

END CLASS.
