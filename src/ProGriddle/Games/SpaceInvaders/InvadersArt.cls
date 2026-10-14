/* The pictures of Space Invaders, as text (see Sprite for the format). They are the arcade shapes with the
   arcade's eye holes and lights filled in as a second tone, so a look can colour them. The sprites are made
   once, when the class is first used, and handed out again and again, so drawing one never allocates.

   This class is the place to change the art: replace a picture here and nothing else needs to know, provided
   its size stays the same (the invaders are 8, 11 and 12 wide and 8 high, the cannon 13 x 8, the saucer 16 x 7,
   a shield 22 x 16, a bomb 3 x 7 and the shot 1 x 4, because the rules use those boxes). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersArt FINAL:

    {ProGriddle/Games/SpaceInvaders/Art.i}

    &SCOPED-DEFINE PICTURES 45

    DEFINE PRIVATE STATIC VARIABLE sSprites AS Sprite NO-UNDO EXTENT 45.

    CONSTRUCTOR STATIC InvadersArt():
        DEFINE VARIABLE sRaw AS CHARACTER NO-UNDO EXTENT 45.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        sRaw[1] = "...++.../..####../.######./##+##+##/########/..*..*../.*.**.*./*.*..*.*".
        sRaw[2] = "...++.../..####../.######./##+##+##/########/.*.**.*./*.*..*.*/*......*".
        sRaw[3] = "..+.....+../...#...#.../..#######../.##+###+##./###########/*.#######.*/*.#.....#.*/...**.**...".
        sRaw[4] = "..+.....+../*..#...#..*/*.#######.*/*##+###+##*/###########/.#########./..*.....*../.*.......*.".
        sRaw[5] = "....++++..../.##########./############/###++##++###/############/...**..**.../..**.**.**../**........**".
        sRaw[6] = "....++++..../.##########./############/###++##++###/############/..***..***../.**..**..**./..**....**..".
        sRaw[7] = "......+....../.....#+#...../.....#+#...../.###########./#############/#############/#############/*************".
        sRaw[8] = ".....######...../...##########.../..############../.##+##+##+##+##./################/..***..**..***../...*........*...".
        sRaw[9] = "....##############..../...################.../..##################../.####################./######################/######################/######################/######################/######################/######################/######################/######################/#######........#######/######..........######/#####............#####/#####............#####".
        sRaw[10] = ".*./***/.#./#.#/.#./###/.+.".
        sRaw[11] = "***/.*./#.#/.#./###/.#./+.+".
        sRaw[12] = ".*./*.*/.#./###/.#./#.#/.+.".
        sRaw[13] = "*.*/.*./###/.#./#.#/.#./+++".
        sRaw[14] = ".*./+++/.#./.#./.#./.#./.+.".
        sRaw[15] = ".*./.*./.#./+++/.#./.#./.+.".
        sRaw[16] = ".*./.*./.#./.#./.#./+++/.+.".
        sRaw[17] = ".*./.*./.#./+++/.#./.#./.+.".
        sRaw[18] = ".*./..*/.#./#../.#./..#/.+.".
        sRaw[19] = "..*/.*./#../.#./..#/.#./+..".
        sRaw[20] = ".*./*../.#./..#/.#./#../.+.".
        sRaw[21] = "*../.*./..#/.#./#../.#./..+".
        sRaw[22] = "+/#/#/#".
        sRaw[23] = "......+....../.#....+....#./..#..+++..#../...#+++++#.../...#+++++#.../..#..+++..#../.#....+....#./......+......".
        sRaw[24] = "..#.......#../#...#...#...#/...+.....+.../.#.........#./.#.........#./...+.....+.../#...#...#...#/..#.......#..".
        sRaw[25] = ".*....#...*...../....*..#....*.../.#...+...+..#.../...#..+++..#..*./*...+++++++..#../..#.++#+#++.#.*./.*..#.####.#..../...*#########...".
        sRaw[26] = "................/..*.......*...../.....*...*....*./.*..#....*.#..../...*.#*..*..#.*./..#.*..##..*.#../.*.##.*##*.##.*./..###########...".
        sRaw[27] = "#..##..#/.#.++.#./..#++#../###++###/###++###/..#++#../.#.++.#./#..##..#".
        sRaw[28] = ".#.++.#./#.####.#/.######./..####..".
        sRaw[29] = "..#.#../.#####./#######/.#####./..###..".
        sRaw[30] = ".#..#../#######/.#####./#######/..###..".
        sRaw[31] = "..###../#######/.#####./.#.#.#./..#.#..".
        sRaw[32] = "..###../.#####./#######/.#####./..#.#../.#...#.".
        sRaw[33] = ".#####./#######/#######/.#####./#.###.#/..#.#..".
        sRaw[34] = "..#.#../.#####./#######/#######/.#.#.#./...#...".
        sRaw[35] = ".*.........*./............./*...........*/............./............./*...........*/............./.*.........*.".
        sRaw[36] = "...*....#....*../.#....*..*....#./....#.+++.#...../*..#.+++++.#..*./..#.+++++++.#.../.*.#.+++++.#.*../...#.#+++#.#..../..*#########*...".
        sRaw[37] = "................/................/.*..........*.../................/....*......*..../..*....**....*../.....#.**.#...../..##.######.##..".
        sRaw[38] = "*......*/.*....*./......../...++.../...++.../......../.*....*./*......*".
        sRaw[39] = "*......*/.*.**.*./..#..#../.#.##.#.".
        sRaw[40] = ".....######...../...##########.../..############../.###+##+##+##+#./################/..***..**..***../...*........*...".
        sRaw[41] = "......+....../.....+.+...../.....+.+...../.+++++++++++./+...........+/+...........+/+...........+/+++++++++++++".
        sRaw[42] = ".....+...../....###..../.#########./###########/###########/***********".
        sRaw[43] = ".#...#./#..+..#/..#.#../.#...#./#.....#".
        sRaw[44] = "......./#.....#/...+.../#.....#/.......".
        sRaw[45] = "+/#/#/#/*/*".
        DO i = 1 TO {&PICTURES}:
            sSprites[i] = NEW Sprite(sRaw[i]).
        END.
    END CONSTRUCTOR.

    /* The picture with a number from Art.i. */
    METHOD PUBLIC STATIC Sprite Picture(INPUT piArt AS INTEGER):
        IF piArt = ? OR piArt < 1 OR piArt > {&PICTURES} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A picture is 1 to &1, not &2", {&PICTURES}, piArt)).
        RETURN sSprites[piArt].
    END METHOD.

    /* How many pictures there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN {&PICTURES}.
    END METHOD.

    /* An invader: kind 0 the squid, 1 the crab, 2 the octopus, in pose 0 or 1. */
    METHOD PUBLIC STATIC Sprite Invader(INPUT piKind AS INTEGER, INPUT piPose AS INTEGER):
        IF piKind = ? OR piKind < 0 OR piKind > 2 THEN
            UNDO, THROW NEW GridException("An invader kind is 0, 1 or 2, not " + STRING(piKind)).
        IF piPose = ? OR piPose < 0 OR piPose > 1 THEN
            UNDO, THROW NEW GridException("An invader pose is 0 or 1, not " + STRING(piPose)).
        RETURN sSprites[{&ART-SQUID0} + piKind * 2 + piPose].
    END METHOD.

    /* A bomb: type 0 the rolling one, 1 the plunger, 2 the squiggly one, in a frame from 0 to 3. */
    METHOD PUBLIC STATIC Sprite Bomb(INPUT piType AS INTEGER, INPUT piFrame AS INTEGER):
        IF piType = ? OR piType < 0 OR piType > 2 THEN
            UNDO, THROW NEW GridException("A bomb type is 0, 1 or 2, not " + STRING(piType)).
        RETURN sSprites[{&ART-BOMB-ROLL0} + piType * 4 + (IF piFrame = ? THEN 0 ELSE piFrame MODULO 4)].
    END METHOD.

    /* A mark that eats into a shield: kind 0 for the player's shot (from below), 1 for a bomb (from
       above), in a variant from 0 to 2. */
    METHOD PUBLIC STATIC Sprite Chip(INPUT piKind AS INTEGER, INPUT piVariant AS INTEGER):
        IF piKind = ? OR piKind < 0 OR piKind > 1 THEN
            UNDO, THROW NEW GridException("A chip kind is 0 or 1, not " + STRING(piKind)).
        RETURN sSprites[{&ART-CHIP-SHOT0} + piKind * 3 + (IF piVariant = ? THEN 0 ELSE piVariant MODULO 3)].
    END METHOD.

END CLASS.
