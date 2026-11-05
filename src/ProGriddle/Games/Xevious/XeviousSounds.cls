/* What the sounds of Xevious sound like, in one place (as XeviousLook is for the colours). Chiptune: a quick bright zap for the
   Zapper, a soft whistle for the bomb falling and a thud for it landing, a pop for an air kill and a heavier one for the ground,
   a rising chime for a hidden tower and a bright arpeggio for a flag, a sharp tick for enemy fire, a ping for a shot turned away,
   a metallic hit and a long collapse for the mothership, noise and a rumble for the ship, and one loop: the mothership's low hum.
   Recipes are written as ToneSynth reads them (see there); the one that starts with @ is the loop. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS XeviousCue):
        CASE poCue:
            WHEN XeviousCue:Zap THEN RETURN "1800>700:60:60".
            WHEN XeviousCue:BombDrop THEN RETURN "t900>400:140:40".
            WHEN XeviousCue:BombBurst THEN RETURN "n:40:30,m:130:80".
            WHEN XeviousCue:AirKill THEN RETURN "1100>300:80:60,n:50:60".
            WHEN XeviousCue:GroundKill THEN RETURN "n:60:30,m:200:70".
            WHEN XeviousCue:SolFound THEN RETURN "t659:60:20,t880:60:20,t1319:200:50".
            WHEN XeviousCue:FlagFound THEN RETURN "523:60:20,659:60:20,784:60:20,1047:60:20,1319:220:60".
            WHEN XeviousCue:EnemyFire THEN RETURN "t1500>1100:50:50".
            WHEN XeviousCue:Clang THEN RETURN "t2200:25:20,t1700:35:60".
            WHEN XeviousCue:BossHit THEN RETURN "t300>200:90:40,n:70:70".
            WHEN XeviousCue:BossKill THEN RETURN "n:200:20,m:300:60,t200>60:500:80".
            WHEN XeviousCue:PlayerDies THEN RETURN "n:230:20,m:620:85".
            WHEN XeviousCue:ExtraLife THEN RETURN "523:60:20,659:60:20,784:60:20,1047:220:60".
            WHEN XeviousCue:StageClear THEN RETURN "t392:70:30,t523:70:30,t659:70:30,t784:70:30,t1047:260:60".
            WHEN XeviousCue:BossLoop THEN RETURN "@110>150:160:0,150>110:160:0".
            OTHERWISE UNDO, THROW NEW GridException("Xevious has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the loop sits under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS XeviousCue):
        CASE poCue:
            WHEN XeviousCue:BossLoop THEN RETURN 28.
            WHEN XeviousCue:Zap THEN RETURN 36.
            WHEN XeviousCue:EnemyFire THEN RETURN 40.
            WHEN XeviousCue:BombDrop THEN RETURN 45.
            OTHERWISE RETURN 65.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cue AS XeviousCue NO-UNDO.
        DO i = INTEGER(XeviousCue:Zap) TO INTEGER(XeviousCue:BossLoop):
            cue = XeviousCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
