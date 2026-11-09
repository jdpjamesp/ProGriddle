/* One attack on goal, cell by cell: two hand scripted attacks (a goal and a save), the mirror for the home side, and facts that must hold for any attack the random source can deal. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.PitchAttackTests:

    VAR PRIVATE PitchAttack mAttack.

    /* The numbers of an attack drawn in the order the pitch asks for them: the attacker's row (10) and column (30), the keeper's side, the two team mates (20,18) and (22,3), the three defenders (20,12), (18,15) and (17,7), and one dribbled cell.
       The attacker dribbles to (29,10), the keeper stands at (14,9) and walks to (13,10), and the ball runs along row 10 straight through the goal mouth. */
    METHOD PRIVATE CHARACTER GoalScript():
        RETURN "6,4,0,9,17,11,2,9,11,7,14,6,6,0".
    END METHOD.

    /* The same attack from column 31, so that the ball arrives on the keeper's cell (13,10) and is saved. */
    METHOD PRIVATE CHARACTER SaveScript():
        RETURN "6,5,0,9,17,11,2,9,11,7,14,6,6,0".
    END METHOD.

    @Setup.
    METHOD PUBLIC VOID BuildAttack():
        mAttack = NEW PitchAttack().
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "team0" THEN mAttack:Run(0, NEW ScriptedRandom("0")).
                WHEN "team3" THEN mAttack:Run(3, NEW ScriptedRandom("0")).
                WHEN "random" THEN mAttack:Run(1, ?).
                WHEN "startcol" THEN mAttack:StartCol(0).
                WHEN "startrow" THEN mAttack:StartRow(8).
                WHEN "shotcol" THEN mAttack:ShotCol(0).
                WHEN "shotrow" THEN mAttack:ShotRow(8).
                WHEN "ballcol" THEN mAttack:BallCol(0).
                WHEN "ballrow" THEN mAttack:BallRow(mAttack:PathLength + 1).
                WHEN "keepercol" THEN mAttack:KeeperCol(0).
                WHEN "keeperrow" THEN mAttack:KeeperRow(mAttack:PathLength + 1).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScriptedAttackFromTheRightPlacesEveryoneWhereTheNumbersSay():
        mAttack:Run(2, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(2, mAttack:Team).
        Assert:Equals(30, mAttack:StartCol(1)).
        Assert:Equals(10, mAttack:StartRow(1)).
        Assert:Equals(20, mAttack:StartCol(2)).
        Assert:Equals(18, mAttack:StartRow(2)).
        Assert:Equals(22, mAttack:StartCol(3)).
        Assert:Equals(3, mAttack:StartRow(3)).
        Assert:Equals(20, mAttack:StartCol(4)).
        Assert:Equals(12, mAttack:StartRow(4)).
        Assert:Equals(18, mAttack:StartCol(5)).
        Assert:Equals(15, mAttack:StartRow(5)).
        Assert:Equals(17, mAttack:StartCol(6)).
        Assert:Equals(7, mAttack:StartRow(6)).
        Assert:Equals(14, mAttack:StartCol(7)).
        Assert:Equals(9, mAttack:StartRow(7)).
        Assert:Equals(29, mAttack:BallStartCol()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDribbleMovesTheAttackerAndEveryoneElseUpTheirWayOneCellForEachStep():
        mAttack:Run(2, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(1, mAttack:DribbleSteps).
        Assert:Equals(29, mAttack:ShotCol(1)).
        Assert:Equals(10, mAttack:ShotRow(1)).
        /* the team mates and defenders move a column and a row toward the middle */
        Assert:Equals(19, mAttack:ShotCol(2)).
        Assert:Equals(17, mAttack:ShotRow(2)).
        Assert:Equals(21, mAttack:ShotCol(3)).
        Assert:Equals(4, mAttack:ShotRow(3)).
        Assert:Equals(19, mAttack:ShotCol(4)).
        Assert:Equals(11, mAttack:ShotRow(4)).
        Assert:Equals(17, mAttack:ShotCol(5)).
        Assert:Equals(14, mAttack:ShotRow(5)).
        Assert:Equals(16, mAttack:ShotCol(6)).
        Assert:Equals(8, mAttack:ShotRow(6)).
        /* the keeper has not moved yet */
        Assert:Equals(14, mAttack:ShotCol(7)).
        Assert:Equals(9, mAttack:ShotRow(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBallRunsTwoColumnsAtATimeStraightIntoTheGoalMouth():
        mAttack:Run(2, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(10, mAttack:PathLength).
        Assert:Equals(28, mAttack:BallCol(1)).
        Assert:Equals(10, mAttack:BallRow(1)).
        Assert:Equals(26, mAttack:BallCol(2)).
        Assert:Equals(16, mAttack:BallCol(7)).
        Assert:Equals(12, mAttack:BallCol(9)).
        Assert:Equals(10, mAttack:BallCol(10)).
        Assert:Equals(10, mAttack:BallRow(10)).
        Assert:Equals(INTEGER(AttackOutcome:Goal), INTEGER(mAttack:Outcome)).
        Assert:IsTrue(mAttack:Scored).
        /* a goal shows the whole flight */
        Assert:Equals(10, mAttack:FlightPoints).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheKeeperStepsTowardTheBallsRowWhenItComesNear():
        mAttack:Run(2, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(14, mAttack:KeeperCol(6)).
        Assert:Equals(9, mAttack:KeeperRow(6)).
        Assert:Equals(13, mAttack:KeeperCol(7)).
        Assert:Equals(10, mAttack:KeeperRow(7)).
        Assert:Equals(13, mAttack:KeeperCol(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABallThatMeetsTheKeeperIsSavedAndIsNotAGoal():
        mAttack:Run(2, NEW ScriptedRandom(SaveScript())).
        Assert:Equals(31, mAttack:StartCol(1)).
        Assert:Equals(INTEGER(AttackOutcome:Saved), INTEGER(mAttack:Outcome)).
        Assert:IsFalse(mAttack:Scored).
        /* the ball was struck at 29 and reached the keeper's cell, column 13, on its 9th point */
        Assert:Equals(29, mAttack:BallCol(1)).
        Assert:Equals(13, mAttack:BallCol(9)).
        Assert:Equals(10, mAttack:BallRow(9)).
        /* a save shows the flight as far as the keeper, the ninth point, and not the ball coming back */
        Assert:Equals(9, mAttack:FlightPoints).
        Assert:IsTrue(mAttack:PathLength > 9).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHomeSideAttacksTheOtherGoalSoEveryColumnIsMirrored():
        mAttack:Run(1, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(1, mAttack:Team).
        Assert:Equals(1, mAttack:StartCol(1)).
        Assert:Equals(10, mAttack:StartRow(1)).
        Assert:Equals(2, mAttack:BallStartCol()).
        Assert:Equals(3, mAttack:BallCol(1)).
        Assert:Equals(21, mAttack:BallCol(10)).
        Assert:Equals(10, mAttack:BallRow(10)).
        Assert:Equals(18, mAttack:KeeperCol(7)).
        Assert:Equals(INTEGER(AttackOutcome:Goal), INTEGER(mAttack:Outcome)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningAgainReplacesTheEarlierAttack():
        mAttack:Run(2, NEW ScriptedRandom(SaveScript())).
        mAttack:Run(1, NEW ScriptedRandom(GoalScript())).
        Assert:Equals(1, mAttack:Team).
        Assert:Equals(10, mAttack:PathLength).
        Assert:Equals(INTEGER(AttackOutcome:Goal), INTEGER(mAttack:Outcome)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryAttackEndsEvenWithARandomSourceThatNeverChangesItsMind():
        VAR INTEGER n.
        VAR INTEGER team.
        DO n = 0 TO 23:
            DO team = 1 TO 2:
                mAttack:Run(team, NEW ScriptedRandom(STRING(n))).
                Assert:IsTrue(mAttack:PathLength >= 1 AND mAttack:PathLength <= 41).
                Assert:IsTrue(mAttack:Outcome <> ?).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ForAnySeedTheAttackKeepsToTheRulesOfThePitch():
        VAR INTEGER seed.
        VAR INTEGER team.
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER p.
        VAR INTEGER goals.
        VAR INTEGER saved.
        VAR INTEGER blocked.
        VAR INTEGER wide.
        VAR INTEGER lastPoint.
        DO seed = 1 TO 150:
            DO team = 1 TO 2:
                mAttack:Run(team, NEW SeededRandom(seed)).
                Assert:IsTrue(mAttack:DribbleSteps = 1 OR mAttack:DribbleSteps = 3 OR mAttack:DribbleSteps = 5).
                /* all seven stand on the pitch, each in a cell of his own, before and after the dribble */
                DO i = 1 TO 7:
                    Assert:IsTrue(mAttack:StartCol(i) >= 0 AND mAttack:StartCol(i) <= 31 AND mAttack:StartRow(i) >= 0 AND mAttack:StartRow(i) <= 21).
                    Assert:IsTrue(mAttack:ShotCol(i) >= 0 AND mAttack:ShotCol(i) <= 31 AND mAttack:ShotRow(i) >= 0 AND mAttack:ShotRow(i) <= 21).
                    DO j = i + 1 TO 7:
                        Assert:IsFalse(mAttack:StartCol(i) = mAttack:StartCol(j) AND mAttack:StartRow(i) = mAttack:StartRow(j)).
                        Assert:IsFalse(mAttack:ShotCol(i) = mAttack:ShotCol(j) AND mAttack:ShotRow(i) = mAttack:ShotRow(j)).
                    END.
                END.
                /* the keeper keeps to his diagonal (column + row is 23 in the attack's own direction) */
                lastPoint = mAttack:PathLength.
                DO p = 1 TO lastPoint:
                    IF team = 2 THEN Assert:Equals(23, mAttack:KeeperCol(p) + mAttack:KeeperRow(p)).
                    ELSE Assert:Equals(23, 31 - mAttack:KeeperCol(p) + mAttack:KeeperRow(p)).
                END.
                /* the ball is on the pitch at every point but the last */
                DO p = 1 TO lastPoint - 1:
                    Assert:IsTrue(mAttack:BallCol(p) >= 0 AND mAttack:BallCol(p) <= 31 AND mAttack:BallRow(p) >= 0 AND mAttack:BallRow(p) <= 21).
                END.
                CASE mAttack:Outcome:
                    WHEN AttackOutcome:Goal THEN
                    DO:
                        goals = goals + 1.
                        /* it left between the posts: rows 5 to 13, and columns 7 to 14 at the left goal or 17 to 24 at the right */
                        Assert:IsTrue(mAttack:BallRow(lastPoint) >= 5 AND mAttack:BallRow(lastPoint) <= 13).
                        IF team = 2 THEN Assert:IsTrue(mAttack:BallCol(lastPoint) >= 7 AND mAttack:BallCol(lastPoint) <= 14).
                        ELSE Assert:IsTrue(mAttack:BallCol(lastPoint) >= 17 AND mAttack:BallCol(lastPoint) <= 24).
                    END.
                    WHEN AttackOutcome:Saved THEN saved = saved + 1.
                    WHEN AttackOutcome:Blocked THEN blocked = blocked + 1.
                    WHEN AttackOutcome:Wide THEN wide = wide + 1.
                END CASE.
            END.
        END.
        /* over 300 attacks every kind of ending turns up */
        Assert:IsTrue(goals > 0).
        Assert:IsTrue(saved > 0).
        Assert:IsTrue(blocked + wide > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        mAttack:Run(2, NEW ScriptedRandom(GoalScript())).
        Assert:IsTrue(Refused("team0")).
        Assert:IsTrue(Refused("team3")).
        Assert:IsTrue(Refused("random")).
        Assert:IsTrue(Refused("startcol")).
        Assert:IsTrue(Refused("startrow")).
        Assert:IsTrue(Refused("shotcol")).
        Assert:IsTrue(Refused("shotrow")).
        Assert:IsTrue(Refused("ballcol")).
        Assert:IsTrue(Refused("ballrow")).
        Assert:IsTrue(Refused("keepercol")).
        Assert:IsTrue(Refused("keeperrow")).
    END METHOD.

END CLASS.
