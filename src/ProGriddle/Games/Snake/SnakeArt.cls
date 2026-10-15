/* The shapes of Snake in the "Lantern Glass" look (docs/design/snake-art.md), as tone map Tiles at two sizes: 16 x 16 for
   boards up to 20 cells across and 8 x 8 for bigger ones. The head (facing East, with and without the tongue), the straight
   body, the corner (joining East and South), the tail (body on the West) and the four frames of the food. They are turned
   to face the right way with Tile:Turned and coloured by the painter (see SnakeLook:Tones for the colour rows). The head uses
   the named colours A (eye), B (pupil) and T (tongue), the food S (stem), G (leaf) and W (white). The tiles are made once,
   when the class is first used. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeArt FINAL:

    /* 1 to 9 at 16 pixels, 10 to 18 at 8: head, head_tongue, body_straight, body_corner, tail, food_0 to food_3 */
    DEFINE PRIVATE STATIC VARIABLE sTiles AS Tile NO-UNDO EXTENT 18.

    CONSTRUCTOR STATIC SnakeArt():
        sTiles[1] = NEW Tile("................/555555555555..../1111112223335.../11111222AA335.../11111222AB3445../11112222333445../11122223334445../12222233334445../22222333344445../22223333444445../22333344444445../33333444AB4445../33344444AA445.../3444444444445.../555555555555..../................").   /* head, 16 */
        sTiles[2] = NEW Tile("................/555555555555..../1111112223335.../11111222AA335.../11111222AB3445../11112222333445../11122223334445.T/12222233334445T./22222333344445T./22223333444445.T/22333344444445../33333444AB4445../33344444AA445.../3444444444445.../555555555555..../................").   /* head_tongue, 16 */
        sTiles[3] = NEW Tile("................/................/5555555555555555/1111111111111111/1111111111111111/2222222222222222/2222222112222222/2222222442222222/3333333443333333/3333333333333333/4444444444444444/4444444444444444/4444444444444444/5555555555555555/................/................").   /* body_straight, 16 */
        sTiles[4] = NEW Tile("................/................/............5555/..........555111/........55111111/.......551111122/......5111112222/.....51111122222/....551112222333/....511124433333/...5111124433444/...5111223334444/..55112223344444/..51112233444455/..5112223344455./..511222334445..").   /* body_corner, 16 */
        sTiles[5] = NEW Tile("................/................/55............../11555.........../111111555......./22222111115...../22222222222115../2222222222222222/3333333333333334/33333334444445../44444444445...../444444555......./44555.........../55............../................/................").   /* tail, 16 */
        sTiles[6] = NEW Tile("........S......./........S.GG..../........SGGGG.../........S......./.....555555...../....51112235..../...5111122345.../...5111223345.../...5112223345.../...5222233445.../...5223334445.../...5333344445.../....53444445..../.....554455...../.......55......./................").   /* food_0, 16 */
        sTiles[7] = NEW Tile("........S......./........S.GG..../........SGGGG.../......55S5....../....55112255..../...5511122355.../...5111122335.../..511112233445../..511122233445../..512222334445../..522233344445../..553333444455../...5334444445.../....54444445..../.....555555...../................").   /* food_1, 16 */
        sTiles[8] = NEW Tile("........S......./........S.GG..../........SGGGG.../.....555S55...../....51112225..../...5111122335.../..511112223345../..511112233345../..511122233445../..512222334445../..522233344445../..522333444445../..553334444455../...5544444455.../....55544555..../......5555......").   /* food_2, 16 */
        sTiles[9] = NEW Tile("........S......./........S.GG..../........SGGGG.../......55S5....../....W5112255..../...WWW1122355.../...5W11122335.../..511112233445../..511122233445../..512222334445../..522233344445../..553333444455../...5334444445.../....54444445..../.....555555...../................").   /* food_3, 16 */
        sTiles[10] = NEW Tile("555555../1112A35./1122335./1223345./2233445./3334445./3444A45./555555..").   /* head, 8 */
        sTiles[11] = NEW Tile("555555../1112A35./1122335./1223345T/2233445T/3334445./3444A45./555555..").   /* head_tongue, 8 */
        sTiles[12] = NEW Tile("......../55555555/22222222/22242222/33334333/44444444/55555555/........").   /* body_straight, 8 */
        sTiles[13] = NEW Tile("......../.....555/....5111/...11122/..512233/.5112344/.5123445/.512345.").   /* body_corner, 8 */
        sTiles[14] = NEW Tile("......../55....../21115.../22222225/33333445/44445.../55....../........").   /* tail, 8 */
        sTiles[15] = NEW Tile("....SG../....SG../...55.../..5125../.512345./..5345../..5555../........").   /* food_0, 8 */
        sTiles[16] = NEW Tile("....SG../....SG../..5555../.511235./.512345./.523445./..5445../...55...").   /* food_1, 8 */
        sTiles[17] = NEW Tile("....SG../...5SG../..5125../.511235./.512345./.523345./.554455./..5555..").   /* food_2, 8 */
        sTiles[18] = NEW Tile("....SG../....SG../..5555../.5W1235./.512345./.523445./..5445../...55...").   /* food_3, 8 */
    END CONSTRUCTOR.

    /* The head, facing East. Throws GridException for a size that is not 16 or 8. */
    METHOD PUBLIC STATIC Tile Head(INPUT piSize AS INTEGER):
        RETURN Pick(piSize, 1).
    END METHOD.

    /* The head with its tongue out, facing East. */
    METHOD PUBLIC STATIC Tile HeadTongue(INPUT piSize AS INTEGER):
        RETURN Pick(piSize, 2).
    END METHOD.

    /* A straight piece of body, horizontal. */
    METHOD PUBLIC STATIC Tile BodyStraight(INPUT piSize AS INTEGER):
        RETURN Pick(piSize, 3).
    END METHOD.

    /* A corner of the body, joining East and South. */
    METHOD PUBLIC STATIC Tile BodyCorner(INPUT piSize AS INTEGER):
        RETURN Pick(piSize, 4).
    END METHOD.

    /* The tail: the body is on its West and the tip points East. */
    METHOD PUBLIC STATIC Tile Tail(INPUT piSize AS INTEGER):
        RETURN Pick(piSize, 5).
    END METHOD.

    /* A frame of the food, 0 to 3 (3 has the glint). Throws GridException for any other frame. */
    METHOD PUBLIC STATIC Tile Food(INPUT piSize AS INTEGER, INPUT piFrame AS INTEGER):
        IF piFrame = ? OR piFrame < 0 OR piFrame > 3 THEN UNDO, THROW NEW GridException("A food frame is 0 to 3, not " + STRING(piFrame)).
        RETURN Pick(piSize, 6 + piFrame).
    END METHOD.

    METHOD PRIVATE STATIC Tile Pick(INPUT piSize AS INTEGER, INPUT piIndex AS INTEGER):
        IF piSize = 16 THEN RETURN sTiles[piIndex].
        IF piSize = 8 THEN RETURN sTiles[piIndex + 9].
        UNDO, THROW NEW GridException("A Snake tile is 16 or 8 pixels, not " + STRING(piSize)).
    END METHOD.

END CLASS.
