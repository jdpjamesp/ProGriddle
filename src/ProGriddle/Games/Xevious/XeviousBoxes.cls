/* The boxes things can be hit in, from the design (XeviousArt:Box...), for each air enemy and ground target. Every thing sits in a slot
   of 16 x 16 pixels (the place the game gives it); a picture smaller than that (the Midge and the Swift are 12 x 12) is centred in
   the slot, and the box is placed within it. The enemies keep to one sprite for their box on every frame, as the design says. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousBoxes FINAL:

    /* The sprite an air enemy's box and look are taken from (its first frame). */
    METHOD PUBLIC STATIC XeviousPicture AirPicture(INPUT poKind AS XeviousAir):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN XeviousPicture:Whirl1.
            WHEN XeviousAir:Torkan THEN RETURN XeviousPicture:SkateFlat.
            WHEN XeviousAir:GiddoSpario THEN RETURN XeviousPicture:Kite1.
            WHEN XeviousAir:Kapi THEN RETURN XeviousPicture:Glint1.
            WHEN XeviousAir:Jara THEN RETURN XeviousPicture:Midge1.
            WHEN XeviousAir:Zakato THEN RETURN XeviousPicture:Wisp2.
            WHEN XeviousAir:Terrazi THEN RETURN XeviousPicture:Swift1.
            WHEN XeviousAir:Bacura THEN RETURN XeviousPicture:Anvil1.
            OTHERWISE UNDO, THROW NEW GridException("No picture for air enemy " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* The sprite a ground target is drawn from. */
    METHOD PUBLIC STATIC XeviousPicture GroundPicture(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:Barra THEN RETURN XeviousPicture:Cairn.
            WHEN XeviousGround:Zolbak THEN RETURN XeviousPicture:Dish.
            WHEN XeviousGround:Logram THEN RETURN XeviousPicture:Burr.
            WHEN XeviousGround:Derota THEN RETURN XeviousPicture:Bastion.
            WHEN XeviousGround:Grobda THEN RETURN XeviousPicture:Beetle1.
            WHEN XeviousGround:GaruBarra THEN RETURN XeviousPicture:Henge.
            WHEN XeviousGround:GaruZakato THEN RETURN XeviousPicture:HiveClosed.
            WHEN XeviousGround:Sol THEN RETURN XeviousPicture:Spire.
            WHEN XeviousGround:Flag THEN RETURN XeviousPicture:Pennant1.
            OTHERWISE UNDO, THROW NEW GridException("No picture for ground target " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* How far in from the left and top of its slot a picture of the given size sits (a 12 x 12 picture sits 2 in). */
    METHOD PUBLIC STATIC INTEGER SlotOffset(INPUT poPicture AS XeviousPicture):
        RETURN XeviousMotion:Div(16 - XeviousArt:Width(poPicture), 2).
    END METHOD.

    /* The box of an air enemy in its slot: left, top, width and height. */
    METHOD PUBLIC STATIC INTEGER AirLeft(INPUT poKind AS XeviousAir):
        RETURN SlotOffset(AirPicture(poKind)) + XeviousArt:BoxX(AirPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER AirTop(INPUT poKind AS XeviousAir):
        RETURN SlotOffset(AirPicture(poKind)) + XeviousArt:BoxY(AirPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER AirWidth(INPUT poKind AS XeviousAir):
        RETURN XeviousArt:BoxWidth(AirPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER AirHeight(INPUT poKind AS XeviousAir):
        RETURN XeviousArt:BoxHeight(AirPicture(poKind)).
    END METHOD.

    /* The box of a ground target in its slot. */
    METHOD PUBLIC STATIC INTEGER GroundLeft(INPUT poKind AS XeviousGround):
        RETURN SlotOffset(GroundPicture(poKind)) + XeviousArt:BoxX(GroundPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GroundTop(INPUT poKind AS XeviousGround):
        RETURN SlotOffset(GroundPicture(poKind)) + XeviousArt:BoxY(GroundPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GroundWidth(INPUT poKind AS XeviousGround):
        RETURN XeviousArt:BoxWidth(GroundPicture(poKind)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GroundHeight(INPUT poKind AS XeviousGround):
        RETURN XeviousArt:BoxHeight(GroundPicture(poKind)).
    END METHOD.

END CLASS.
