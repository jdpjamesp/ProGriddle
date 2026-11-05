/* The colours of Centipede, in one place (as CentipedeRules holds the numbers). The look is neon on night blue: a pink
   mushroom that darkens as it is shot, a cyan one when a scorpion has poisoned it, a green centipede with a lime head. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeLook FINAL:

    /* The 0xRRGGBB number of a colour. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS CentipedeTint):
        CASE poTint:
            WHEN CentipedeTint:Night THEN RETURN 0x0B0E1A.
            WHEN CentipedeTint:Strip THEN RETURN 0x070912.
            WHEN CentipedeTint:StripRule THEN RETURN 0x2A3563.
            WHEN CentipedeTint:Zone THEN RETURN 0x10172B.
            WHEN CentipedeTint:ZoneRule THEN RETURN 0x1F2B52.
            WHEN CentipedeTint:Text THEN RETURN 0xF2F5FF.
            WHEN CentipedeTint:Label THEN RETURN 0x7F93D6.
            WHEN CentipedeTint:Dim THEN RETURN 0x56648F.
            WHEN CentipedeTint:Gold THEN RETURN 0xFFD84D.
            WHEN CentipedeTint:Warn THEN RETURN 0xFF5470.
            WHEN CentipedeTint:Cap4 THEN RETURN 0xFF4FA3.
            WHEN CentipedeTint:Cap3 THEN RETURN 0xE03F94.
            WHEN CentipedeTint:Cap2 THEN RETURN 0xB02F78.
            WHEN CentipedeTint:Cap1 THEN RETURN 0x7C2058.
            WHEN CentipedeTint:CapShine THEN RETURN 0xFFB3D9.
            WHEN CentipedeTint:Stem THEN RETURN 0xE8DCC0.
            WHEN CentipedeTint:PoisonCap THEN RETURN 0x35F2C2.
            WHEN CentipedeTint:PoisonDark THEN RETURN 0x1C9C82.
            WHEN CentipedeTint:PoisonShine THEN RETURN 0xC8FFF0.
            WHEN CentipedeTint:BodyMain THEN RETURN 0x3FE06E.
            WHEN CentipedeTint:BodyLight THEN RETURN 0x9BFFB5.
            WHEN CentipedeTint:BodyDeep THEN RETURN 0x127A38.
            WHEN CentipedeTint:HeadMain THEN RETURN 0xC8FF4D.
            WHEN CentipedeTint:HeadLight THEN RETURN 0xEFFFA6.
            WHEN CentipedeTint:Eye THEN RETURN 0xFF2D4D.
            WHEN CentipedeTint:Leg THEN RETURN 0x2C9E52.
            WHEN CentipedeTint:Ship THEN RETURN 0x4FD8FF.
            WHEN CentipedeTint:ShipLight THEN RETURN 0xC9F3FF.
            WHEN CentipedeTint:ShipDeep THEN RETURN 0x1F7FA6.
            WHEN CentipedeTint:Flame THEN RETURN 0xFF9A3C.
            WHEN CentipedeTint:Shot THEN RETURN 0xFFF27A.
            WHEN CentipedeTint:ShotTail THEN RETURN 0xFFB02E.
            WHEN CentipedeTint:FleaMain THEN RETURN 0xFF9A3C.
            WHEN CentipedeTint:FleaLight THEN RETURN 0xFFD08A.
            WHEN CentipedeTint:SpiderMain THEN RETURN 0xB46CFF.
            WHEN CentipedeTint:SpiderLight THEN RETURN 0xE0C2FF.
            WHEN CentipedeTint:SpiderLeg THEN RETURN 0x7B3FC7.
            WHEN CentipedeTint:ScorpionMain THEN RETURN 0xFF4D4D.
            WHEN CentipedeTint:ScorpionLight THEN RETURN 0xFFA0A0.
            WHEN CentipedeTint:Spark THEN RETURN 0xFFE9A8.
            WHEN CentipedeTint:Flash THEN RETURN 0xFFFFFF.
            WHEN CentipedeTint:Plate THEN RETURN 0x161E3D.
            WHEN CentipedeTint:TitleTop THEN RETURN 0xC8FF4D.
            WHEN CentipedeTint:TitleBottom THEN RETURN 0x2FCB60.
            WHEN CentipedeTint:Outline THEN RETURN 0x05070F.
            OTHERWISE UNDO, THROW NEW GridException("Centipede has no colour for " + STRING(poTint)).
        END CASE.
    END METHOD.

    /* The cap of a mushroom with piHp hit points left (1 to 4), or the poisoned cap. Throws GridException for any other number. */
    METHOD PUBLIC STATIC INTEGER CapColour(INPUT piHp AS INTEGER, INPUT plPoisoned AS LOGICAL):
        IF piHp = ? OR piHp < 1 OR piHp > 4 THEN UNDO, THROW NEW GridException("A mushroom has 1 to 4 hit points, not " + STRING(piHp)).
        IF plPoisoned THEN RETURN Colour(IF piHp >= 3 THEN CentipedeTint:PoisonCap ELSE CentipedeTint:PoisonDark).
        CASE piHp:
            WHEN 4 THEN RETURN Colour(CentipedeTint:Cap4).
            WHEN 3 THEN RETURN Colour(CentipedeTint:Cap3).
            WHEN 2 THEN RETURN Colour(CentipedeTint:Cap2).
            OTHERWISE RETURN Colour(CentipedeTint:Cap1).
        END CASE.
    END METHOD.

END CLASS.
