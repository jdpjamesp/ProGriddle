/* The rack of invaders: where they start, which one moves each frame, how a pass ends, and the drop and
   turn round at the edge. The top row of pictures starts at row 40 in these tests. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvaderRackTests:

    DEFINE PRIVATE VARIABLE mRack AS InvaderRack NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildRack():
        mRack = NEW InvaderRack().
        mRack:Reset(40).
    END METHOD.

    /* Makes n steps and returns the number of the last invader that moved. */
    METHOD PRIVATE INTEGER Steps(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE latest AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            latest = mRack:Step().
        END.
        RETURN latest.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mRack:X(piIndex).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    /* ---- the start ---- */

    @Test.
    METHOD PUBLIC VOID AFreshRackHasFiftyFiveLiveInvadersGoingRight():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(55, mRack:AliveCount).
        DO i = 0 TO 54:
            Assert:IsTrue(mRack:Alive(i)).
        END.
        Assert:Equals(1, mRack:Direction).
        Assert:IsFalse(mRack:Dropping).
        Assert:Equals(0, mRack:Pose).
        Assert:Equals(0, mRack:Passes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInvadersStartSixteenCellsApartWithEachPictureCentredInItsSlot():
        /* the squid is 8 wide, so it sits 4 in from its slot, the crab (11) and the octopus (12) 2 in */
        Assert:Equals(28, mRack:X(0)).
        Assert:Equals(40, mRack:Y(0)).
        Assert:Equals(44, mRack:X(1)).
        Assert:Equals(26, mRack:X(11)).
        Assert:Equals(56, mRack:Y(11)).
        Assert:Equals(26, mRack:X(33)).
        Assert:Equals(88, mRack:Y(33)).
        Assert:Equals(26, mRack:X(44)).
        Assert:Equals(104, mRack:Y(44)).
        Assert:Equals(186, mRack:X(54)).
        Assert:Equals(104, mRack:Y(54)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRowsAreSquidCrabsAndOctopuses():
        Assert:Equals(0, InvaderRack:KindOf(5)).
        Assert:Equals(1, InvaderRack:KindOf(11)).
        Assert:Equals(1, InvaderRack:KindOf(32)).
        Assert:Equals(2, InvaderRack:KindOf(33)).
        Assert:Equals(2, InvaderRack:KindOf(54)).
        Assert:Equals(0, InvaderRack:RowOf(10)).
        Assert:Equals(4, InvaderRack:RowOf(54)).
        Assert:Equals(10, InvaderRack:ColumnOf(54)).
        Assert:Equals(0, InvaderRack:ColumnOf(44)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachKindHasItsWidthAndItsPoints():
        Assert:Equals(8, InvaderRack:WidthOfKind(0)).
        Assert:Equals(11, InvaderRack:WidthOfKind(1)).
        Assert:Equals(12, InvaderRack:WidthOfKind(2)).
        Assert:Equals(30, InvaderRack:PointsOfKind(0)).
        Assert:Equals(20, InvaderRack:PointsOfKind(1)).
        Assert:Equals(10, InvaderRack:PointsOfKind(2)).
        Assert:Equals(8, mRack:WidthOf(3)).
        Assert:Equals(12, mRack:WidthOf(50)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFieldAndTheSpacingAreTheArcadesOwn():
        Assert:Equals(5, InvaderRack:Rows()).
        Assert:Equals(11, InvaderRack:Columns()).
        Assert:Equals(55, InvaderRack:Total()).
        Assert:Equals(16, InvaderRack:Pitch()).
        Assert:Equals(8, InvaderRack:SpriteHeight()).
        Assert:Equals(24, InvaderRack:FirstSlotX()).
        Assert:Equals(8, InvaderRack:LeftLimit()).
        Assert:Equals(216, InvaderRack:RightLimit()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadIndexOrKindIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Assert:IsTrue(Refused(-1)).
        Assert:IsTrue(Refused(55)).
        Assert:IsTrue(Refused(?)).
        DO ON ERROR UNDO, THROW:
            InvaderRack:KindOfRow(5).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvaderRack:WidthOfKind(3).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvaderRack:PointsOfKind(-1).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    /* ---- one invader a step ---- */

    @Test.
    METHOD PUBLIC VOID TheBottomLeftInvaderMovesFirstTwoCellsToTheRight():
        Assert:Equals(44, mRack:Step()).
        Assert:Equals(26, mRack:OldX).
        Assert:Equals(104, mRack:OldY).
        Assert:Equals(28, mRack:X(44)).
        Assert:Equals(104, mRack:Y(44)).
        Assert:Equals(26, mRack:X(33)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBottomRowMovesLeftToRightThenTheRowAbove():
        Assert:Equals(44, mRack:Step()).
        Assert:Equals(45, mRack:Step()).
        Assert:Equals(46, Steps(1)).
        Assert:Equals(54, Steps(8)).
        Assert:Equals(33, mRack:Step()).
        /* the rest of row 3, then row 2 left to right, ending on its last invader */
        Assert:Equals(32, Steps(21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APassIsEndedByTheLastInvaderAndTheTopRightOneIsLast():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 54:
            mRack:Step().
            Assert:IsFalse(mRack:PassEnded).
        END.
        Assert:Equals(10, mRack:Step()).
        Assert:IsTrue(mRack:PassEnded).
        Assert:Equals(1, mRack:Passes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenAPassEndsTheWalkingPoseChangesAndEveryoneHasMovedTwoCells():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Steps(55).
        Assert:Equals(1, mRack:Pose).
        DO i = 0 TO 54:
            Assert:Equals(INTEGER(InvaderRack:FirstSlotX() + InvaderRack:ColumnOf(i) * 16 + TRUNCATE((16 - mRack:WidthOf(i)) / 2, 0) + 2), mRack:X(i)).
        END.
        Steps(55).
        Assert:Equals(0, mRack:Pose).
        Assert:Equals(2, mRack:Passes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DeadInvadersAreSkippedSoAPassGetsShorterAndTheRackSpeedsUp():
        mRack:Kill(44).
        mRack:Kill(45).
        Assert:Equals(46, mRack:Step()).
        Assert:Equals(54, Steps(8)).
        Assert:Equals(33, mRack:Step()).
        /* 53 live invaders, so the pass ends at the 53rd step */
        Assert:Equals(10, Steps(43)).
        Assert:IsTrue(mRack:PassEnded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastInvaderMovesEveryStepAndEveryStepIsAPass():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 53:
            mRack:Kill(i).
        END.
        Assert:Equals(1, mRack:AliveCount).
        Assert:Equals(54, mRack:Step()).
        Assert:IsTrue(mRack:PassEnded).
        Assert:Equals(54, mRack:Step()).
        Assert:Equals(54, mRack:Step()).
        Assert:Equals(3, mRack:Passes).
        Assert:Equals(192, mRack:X(54)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StepGivesMinusOneWhenNoInvaderIsAlive():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 54:
            mRack:Kill(i).
        END.
        Assert:Equals(0, mRack:AliveCount).
        Assert:Equals(-1, mRack:Step()).
        Assert:IsFalse(mRack:PassEnded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnInvaderShotInTheMiddleOfAPassDoesNotUpsetTheOrder():
        Steps(3).
        mRack:Kill(47).
        Assert:Equals(48, mRack:Step()).
        mRack:Kill(49).
        Assert:Equals(50, mRack:Step()).
    END METHOD.

    /* ---- the edge ---- */

    @Test.
    METHOD PUBLIC VOID TheRackKeepsGoingRightUntilTheRightmostInvaderTouchesTheEdgeThenDrops():
        /* the rightmost octopus is at x 186 and 12 wide: it touches 216 after 9 steps of 2 cells */
        Steps(55 * 8).
        Assert:IsFalse(mRack:Dropping).
        Assert:Equals(1, mRack:Direction).
        Steps(55).
        Assert:Equals(9, mRack:Passes).
        Assert:Equals(204, mRack:X(54)).
        Assert:IsTrue(mRack:Dropping).
        Assert:Equals(-1, mRack:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDropPassMovesEveryoneEightCellsDownAndNotSideways():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Steps(55 * 9).
        Assert:IsTrue(mRack:Dropping).
        Assert:Equals(44, mRack:Step()).
        Assert:Equals(112, mRack:Y(44)).
        Assert:Equals(44, mRack:OldX).
        Assert:Equals(mRack:OldX, mRack:X(44)).
        Steps(54).
        Assert:IsFalse(mRack:Dropping).
        DO i = 0 TO 54:
            Assert:Equals(40 + InvaderRack:RowOf(i) * 16 + 8, mRack:Y(i)).
        END.
        Assert:Equals(10, mRack:Passes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheDropTheRackGoesLeftAndAnotherPassIsNotADrop():
        Steps(55 * 10).
        Assert:IsFalse(mRack:Dropping).
        Assert:Equals(-1, mRack:Direction).
        Assert:Equals(44, mRack:Step()).
        Assert:Equals(42, mRack:X(44)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRackTurnsAtTheLeftEdgeToo():
        /* 9 passes right, a drop, then left: the leftmost octopus (x 26 + 18 = 44 then 2 less per pass) must
           reach 8 or less: it gets to 8 after 18 passes, so pass 28 overall ends it */
        Steps(55 * 28).
        Assert:IsTrue(mRack:Dropping).
        Assert:Equals(1, mRack:Direction).
        Assert:Equals(8, mRack:X(44)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheOutsideColumnsAreGoneTheRackTravelsFurther():
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        /* with the last column shot away the rightmost octopus is in column 9, at x 170 and 12 wide, which
           touches the edge after 17 steps of 2 cells instead of 9 */
        DO r = 0 TO 4:
            mRack:Kill(r * 11 + 10).
        END.
        Steps(50 * 16).
        Assert:IsFalse(mRack:Dropping).
        Steps(50).
        Assert:IsTrue(mRack:Dropping).
        Assert:Equals(17, mRack:Passes).
    END METHOD.

    /* ---- shooting and looking ---- */

    @Test.
    METHOD PUBLIC VOID KillingCountsDownAndAKilledInvaderCannotBeKilledAgain():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        mRack:Kill(7).
        Assert:Equals(54, mRack:AliveCount).
        Assert:IsFalse(mRack:Alive(7)).
        DO ON ERROR UNDO, THROW:
            mRack:Kill(7).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadInvaderKeepsItsLastPlace():
        mRack:Step().
        mRack:Kill(44).
        Assert:Equals(28, mRack:X(44)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLowestInAColumnIsTheBottomOneThenTheOneAboveItAndSoOn():
        Assert:Equals(44, mRack:LowestInColumn(0)).
        mRack:Kill(44).
        Assert:Equals(33, mRack:LowestInColumn(0)).
        mRack:Kill(33).
        mRack:Kill(22).
        mRack:Kill(11).
        Assert:Equals(0, mRack:LowestInColumn(0)).
        mRack:Kill(0).
        Assert:Equals(-1, mRack:LowestInColumn(0)).
        Assert:Equals(54, mRack:LowestInColumn(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadColumnIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mRack:LowestInColumn(11).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mRack:LowestInColumn(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBottomIsTheRowJustBelowTheLowestLivePicture():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(112, mRack:Bottom()).
        DO i = 44 TO 54:
            mRack:Kill(i).
        END.
        Assert:Equals(96, mRack:Bottom()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBottomIsMinusOneWhenNoneIsAlive():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 54:
            mRack:Kill(i).
        END.
        Assert:Equals(-1, mRack:Bottom()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AtFindsTheLiveInvaderWhosePictureCoversACell():
        Assert:Equals(0, mRack:At(28, 40)).
        Assert:Equals(0, mRack:At(35, 47)).
        Assert:Equals(-1, mRack:At(36, 40)).
        Assert:Equals(-1, mRack:At(28, 48)).
        Assert:Equals(44, mRack:At(26, 104)).
        Assert:Equals(54, mRack:At(197, 111)).
        mRack:Kill(0).
        Assert:Equals(-1, mRack:At(28, 40)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetPutsEverythingBackAtTheNewHeight():
        Steps(55 * 9 + 10).
        mRack:Kill(3).
        mRack:Reset(72).
        Assert:Equals(55, mRack:AliveCount).
        Assert:Equals(1, mRack:Direction).
        Assert:IsFalse(mRack:Dropping).
        Assert:Equals(0, mRack:Pose).
        Assert:Equals(0, mRack:Passes).
        Assert:Equals(72, mRack:Y(0)).
        Assert:Equals(28, mRack:X(0)).
        Assert:Equals(44, mRack:Step()).
    END METHOD.

END CLASS.
