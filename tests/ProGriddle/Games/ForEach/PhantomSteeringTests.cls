/* How a phantom picks its way at a tile. Standing on a tile and heading some way, it looks at the neighbours it may enter (never
   the one behind it), and takes the one whose tile is nearest, in a straight line, to the target. A tie goes to up, then left,
   then down, then right. Two things change that: some tiles forbid turning up (when the rule is on), and only a phantom that may
   use the door can go through the door or into the lobby. A rolled back phantom picks one of the open ways at random instead. A
   dead end sends it back the way it came. The mazes are seven tiles square crosses, the middle at column 3 row 3. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.PhantomSteeringTests:

    DEFINE PRIVATE VARIABLE mCross   AS MazeMap NO-UNDO.
    DEFINE PRIVATE VARIABLE mNoUp    AS MazeMap NO-UNDO.
    DEFINE PRIVATE VARIABLE mDoorway AS MazeMap NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildMazes():
        /* a plus: four arms of two tiles round the middle (3, 3) */
        mCross = NEW MazeMap(ForEachKit:Pipes("#######|###_###|###_###|#__P__#|###_###|###_###|#######")).
        /* the same, with the middle a tile where phantoms may not turn up */
        mNoUp = NEW MazeMap(ForEachKit:Pipes("#######|###_###|###_###|#__U__#|###_###|###P###|#######")).
        /* a corridor along the top, a door below its middle and a lobby floor under that */
        mDoorway = NEW MazeMap(ForEachKit:Pipes("#####|#_P_#|##-##|#===#|#####")).
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE dir   AS MazeDir NO-UNDO.
        DEFINE VARIABLE other AS MazeDir NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = PhantomSteering:Choose(?, 3, 3, MazeDir:Right, 0, 0, FALSE, FALSE).
                WHEN 2 THEN other = PhantomSteering:Choose(mCross, 3, 3, dir, 0, 0, FALSE, FALSE).
                WHEN 3 THEN other = PhantomSteering:Choose(mCross, 3, 9, MazeDir:Right, 0, 0, FALSE, FALSE).
                WHEN 4 THEN other = PhantomSteering:ChooseAtRandom(mCross, 3, 3, dir, NEW FixedPick(0)).
                WHEN 5 THEN other = PhantomSteering:ChooseAtRandom(mCross, 3, 3, MazeDir:Right, ?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomTakesTheOpenWayNearestTheTarget():
        /* the target is far above: up is nearest */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Right, 3, -10, FALSE, FALSE)).
        /* far below: down */
        Assert:Equals(MazeDir:Down, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Left, 3, 20, FALSE, FALSE)).
        /* far to the right, heading right: keep going */
        Assert:Equals(MazeDir:Right, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Right, 30, 3, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomNeverTurnsRoundEvenWhenTheTargetIsBehindIt():
        /* heading right with the target far left: left is not allowed, and up and down are equally far, so up wins the tie */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Right, -30, 3, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATieGoesToUpThenLeftThenDownThenRight():
        /* every neighbour is one tile from a target in the middle; heading down rules out up, so left wins */
        Assert:Equals(MazeDir:Left, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Down, 3, 3, FALSE, FALSE)).
        /* heading left rules out right, so up wins */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Left, 3, 3, FALSE, FALSE)).
        /* heading up rules out down, so up wins */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Up, 3, 3, FALSE, FALSE)).
        /* heading right rules out left, so up wins */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Right, 3, 3, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTileItJudgesByIsTheNeighbourNotTheTileItStandsOn():
        /* target at the tile just right of the middle: right is nearest, however far up and down it could go */
        Assert:Equals(MazeDir:Right, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Down, 4, 3, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadEndSendsThePhantomBackTheWayItCame():
        /* at the top of the upper arm heading up there is only a wall ahead and to both sides */
        Assert:Equals(MazeDir:Down, PhantomSteering:Choose(mCross, 3, 1, MazeDir:Up, 3, -10, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileThatForbidsTurningUpIsIgnoredUnlessTheRuleIsOn():
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mNoUp, 3, 3, MazeDir:Right, 3, -10, FALSE, FALSE)).
        Assert:Equals(MazeDir:Right, PhantomSteering:Choose(mNoUp, 3, 3, MazeDir:Right, 3, -10, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNoUpRuleOnlyStopsUpOnTheTilesThatForbidIt():
        /* on an ordinary tile of the other maze, the rule changes nothing */
        Assert:Equals(MazeDir:Up, PhantomSteering:Choose(mCross, 3, 3, MazeDir:Right, 3, -10, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyAPhantomThatMayUseTheDoorCanGoThroughIt():
        /* the target is inside the lobby; with the door shut to it the phantom can only go on to the right */
        Assert:Equals(MazeDir:Right, PhantomSteering:Choose(mDoorway, 2, 1, MazeDir:Right, 2, 3, FALSE, FALSE)).
        Assert:Equals(MazeDir:Down, PhantomSteering:Choose(mDoorway, 2, 1, MazeDir:Right, 2, 3, FALSE, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARolledBackPhantomPicksAnOpenWayAtRandomInTheOrderUpLeftDownRight():
        /* heading right in the plus the ways are up, down and right */
        Assert:Equals(MazeDir:Up, PhantomSteering:ChooseAtRandom(mCross, 3, 3, MazeDir:Right, NEW FixedPick(0))).
        Assert:Equals(MazeDir:Down, PhantomSteering:ChooseAtRandom(mCross, 3, 3, MazeDir:Right, NEW FixedPick(1))).
        Assert:Equals(MazeDir:Right, PhantomSteering:ChooseAtRandom(mCross, 3, 3, MazeDir:Right, NEW FixedPick(2))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARolledBackPhantomMayTurnUpEvenWhereTheOthersMayNot():
        Assert:Equals(MazeDir:Up, PhantomSteering:ChooseAtRandom(mNoUp, 3, 3, MazeDir:Right, NEW FixedPick(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARolledBackPhantomInADeadEndTurnsRound():
        Assert:Equals(MazeDir:Down, PhantomSteering:ChooseAtRandom(mCross, 3, 1, MazeDir:Up, NEW FixedPick(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASteeringCallNeedsAMazeADirectionATileInTheMazeAndARandomSource():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
        Assert:IsTrue(ThrowsGridException(5)).
    END METHOD.

END CLASS.
