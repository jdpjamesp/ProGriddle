USING OpenEdge.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsFleetsTests:

    @Test.
    METHOD PUBLIC VOID TheSizesAreInPickerOrderSmallestFirst():
        Assert:Equals("Tiny,Small,Classic,Large,Huge", BattleshipsFleets:Names()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachSizeHasItsBoardAndFleet():
        Assert:Equals(6, BattleshipsFleets:SideOf("Tiny")).
        Assert:Equals("3,2,2", BattleshipsFleets:FleetOf("Tiny")).
        Assert:Equals(8, BattleshipsFleets:SideOf("Small")).
        Assert:Equals("4,3,3,2", BattleshipsFleets:FleetOf("Small")).
        Assert:Equals(10, BattleshipsFleets:SideOf("Classic")).
        Assert:Equals("5,4,3,3,2", BattleshipsFleets:FleetOf("Classic")).
        Assert:Equals(12, BattleshipsFleets:SideOf("Large")).
        Assert:Equals("5,4,4,3,3,2,2", BattleshipsFleets:FleetOf("Large")).
        Assert:Equals(15, BattleshipsFleets:SideOf("Huge")).
        Assert:Equals("6,5,4,4,3,3,3,2,2", BattleshipsFleets:FleetOf("Huge")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BiggerBoardsGetMoreAndLongerShips():
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE previous AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevMax  AS INTEGER NO-UNDO.
        DEFINE VARIABLE prevSide AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(BattleshipsFleets:Names()):
            Assert:IsTrue(NUM-ENTRIES(BattleshipsFleets:FleetOf(ENTRY(i, BattleshipsFleets:Names()))) >= previous).
            Assert:IsTrue(INTEGER(ENTRY(1, BattleshipsFleets:FleetOf(ENTRY(i, BattleshipsFleets:Names())))) >= prevMax).
            Assert:IsTrue(BattleshipsFleets:SideOf(ENTRY(i, BattleshipsFleets:Names())) > prevSide).
            previous = NUM-ENTRIES(BattleshipsFleets:FleetOf(ENTRY(i, BattleshipsFleets:Names()))).
            prevMax = INTEGER(ENTRY(1, BattleshipsFleets:FleetOf(ENTRY(i, BattleshipsFleets:Names())))).
            prevSide = BattleshipsFleets:SideOf(ENTRY(i, BattleshipsFleets:Names())).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoShipIsShorterThanTwoAndEveryFleetIsUnderAFifthOfItsBoard():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE sizeName  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE fleet AS CHARACTER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(BattleshipsFleets:Names()):
            sizeName = ENTRY(i, BattleshipsFleets:Names()).
            fleet = BattleshipsFleets:FleetOf(sizeName).
            DO j = 1 TO NUM-ENTRIES(fleet):
                Assert:IsTrue(INTEGER(ENTRY(j, fleet)) >= 2).
                Assert:IsTrue(INTEGER(ENTRY(j, fleet)) <= BattleshipsFleets:SideOf(sizeName)).
            END.
            Assert:IsTrue(BattleshipsFleets:CellsOf(sizeName) * 5 < BattleshipsFleets:SideOf(sizeName) * BattleshipsFleets:SideOf(sizeName)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CellsOfAddsTheFleetUp():
        Assert:Equals(17, BattleshipsFleets:CellsOf("Classic")).
        Assert:Equals(7, BattleshipsFleets:CellsOf("Tiny")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CanonicalFixesTheCaseAndRejectsUnknownNames():
        Assert:Equals("Classic", BattleshipsFleets:Canonical("classic")).
        Assert:Equals("", BattleshipsFleets:Canonical("Gigantic")).
        Assert:Equals("", BattleshipsFleets:Canonical(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NameForFindsTheStandardSizeFromABoardAndFleet():
        Assert:Equals("Classic", BattleshipsFleets:NameFor(10, "5,4,3,3,2")).
        Assert:Equals("", BattleshipsFleets:NameFor(10, "5,4,3")).
        Assert:Equals("", BattleshipsFleets:NameFor(11, "5,4,3,3,2")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID SideOfAnUnknownSizeThrows():
        BattleshipsFleets:SideOf("Gigantic").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID FleetOfAnUnknownSizeThrows():
        BattleshipsFleets:FleetOf("Gigantic").
    END METHOD.

END CLASS.
