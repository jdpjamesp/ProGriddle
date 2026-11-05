/* The arcade window needs the .NET bridge, so these run under prowin -b (tools/run-tests.ps1 -Gui). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ArcadeWindowTests:

    DEFINE PRIVATE VARIABLE mLauncher AS RecordingGameLauncher NO-UNDO.
    DEFINE PRIVATE VARIABLE mWindow   AS ArcadeWindow          NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildWindow():
        mLauncher = NEW RecordingGameLauncher().
        mWindow = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog("run/run-a.p|Alpha|The first;run/run-b.p|Beta|The second"), mLauncher).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseWindow():
        IF VALID-OBJECT(mWindow) THEN DO:
            mWindow:ReleaseResources().
            mWindow:Dispose().
        END.
        mWindow = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsOneButtonForEveryGameInTheCatalog():
        Assert:Equals("Arcade", mWindow:Text).
        Assert:Equals(2, mWindow:GameCount).
        Assert:Equals("Alpha", mWindow:ButtonFor("run/run-a.p"):Text).
        Assert:Equals("Beta", mWindow:ButtonFor("run/run-b.p"):Text).
        Assert:IsTrue(mWindow:ButtonFor("run/run-a.p"):Enabled).
        Assert:IsTrue(mWindow:ButtonFor("run/run-b.p"):Enabled).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlayStartsThatGameAndSaysSo():
        mWindow:Play("run/run-b.p").
        Assert:Equals("run/run-b.p", mLauncher:Launched).
        Assert:Equals("Started Beta", mWindow:StatusLine).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsRunningShowsAsPlaying():
        mWindow:Play("run/run-a.p").
        Assert:IsTrue(mWindow:IsPlaying("run/run-a.p")).
        Assert:IsFalse(mWindow:IsPlaying("run/run-b.p")).
        Assert:Equals("Alpha (playing)", mWindow:ButtonFor("run/run-a.p"):AccessibleName).
        Assert:Equals("Beta", mWindow:ButtonFor("run/run-b.p"):AccessibleName).
        Assert:Equals("Alpha", mWindow:ButtonFor("run/run-a.p"):Text).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsRunningIsNotStartedAgainAndTheStatusSaysSo():
        mWindow:Play("run/run-a.p").
        mWindow:Play("run/run-a.p").
        Assert:Equals("run/run-a.p", mLauncher:Launched).
        Assert:Equals("Alpha is already running", mWindow:StatusLine).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatHasFinishedShowsAsReadyAgainOnTheNextUpdate():
        mWindow:Play("run/run-a.p").
        mLauncher:Finish("run/run-a.p").
        mWindow:Play("run/run-b.p").
        Assert:Equals("Alpha", mWindow:ButtonFor("run/run-a.p"):AccessibleName).
        Assert:Equals("Beta (playing)", mWindow:ButtonFor("run/run-b.p"):AccessibleName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsStartedAtTheLauncherIsShownAsPlayingToo():
        mLauncher:Launch("run/run-b.p").
        mWindow:Play("run/run-a.p").
        Assert:Equals("Beta (playing)", mWindow:ButtonFor("run/run-b.p"):AccessibleName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatFailsToStartLeavesItsButtonOnAndSaysWhy():
        mLauncher:FailWith = "No prowin here".
        mWindow:Play("run/run-a.p").
        Assert:Equals("", mLauncher:Launched).
        Assert:Equals("No prowin here", mWindow:StatusLine).
        Assert:IsTrue(mWindow:ButtonFor("run/run-a.p"):Enabled).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCaptionNamesEveryGame():
        Assert:Equals("Alpha and Beta, all cooking on the same grid.", mWindow:Caption).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCaptionListsThreeOrMoreGamesWithCommasAndAnd():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog("a|Alpha|1;b|Beta|2;c|Gamma|3"), mLauncher).
            Assert:Equals("Alpha, Beta and Gamma, all cooking on the same grid.", w:Caption).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnIconFileThatIsNotThereIsIgnored():
        mWindow:IconFile = "assets/no-such-icon.ico".
        mWindow:IconFile = "".
        Assert:Equals("", mWindow:IconFile).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheArtworkIconIsLoaded():
        mWindow:IconFile = "assets/progriddle.ico".
        Assert:IsTrue(VALID-OBJECT(mWindow:Icon)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyCatalogShowsNoButtonsAndSaysSo():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(""), mLauncher).
            Assert:Equals(0, w:GameCount).
            Assert:Equals("No games found", w:StatusLine).
            Assert:IsTrue(INDEX(w:Caption, "No games found") = 1).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleaseResourcesCanBeCalledMoreThanOnce():
        mWindow:AutoClose(60).
        mWindow:ReleaseResources().
        mWindow:ReleaseResources().
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AskingForAGameThatIsNotThereThrows():
        mWindow:ButtonFor("run/run-zzz.p").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AutoCloseNeedsASecondOrMore():
        mWindow:AutoClose(0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsATitle():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("", NEW FixedGameCatalog(""), mLauncher).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsACatalog():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("Arcade", ?, mLauncher).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheWindowNeedsALauncher():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(""), ?).
    END METHOD.

    /* A catalog of n games named G1 to Gn. */
    METHOD PRIVATE CHARACTER Games(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO piCount:
            result = result + (IF i > 1 THEN ";" ELSE "") + SUBSTITUTE("run/run-g&1.p|G&1|Game &1", i).
        END.
        RETURN result.
    END METHOD.

    /* The height of the window for a catalog of n games. */
    METHOD PRIVATE INTEGER HeightFor(INPUT piCount AS INTEGER):
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DEFINE VARIABLE h AS INTEGER      NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(Games(piCount)), mLauncher).
            h = w:ClientSize:Height.
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
        RETURN h.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FourGamesOrFewerFitTheUsualWindow():
        Assert:Equals(650, HeightFor(0)).
        Assert:Equals(650, HeightFor(1)).
        Assert:Equals(650, HeightFor(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UpToEightGamesFitTheUsualWindowInFourRowsOfSmallChips():
        Assert:Equals(650, HeightFor(5)).
        Assert:Equals(650, HeightFor(6)).
        Assert:Equals(650, HeightFor(7)).
        Assert:Equals(650, HeightFor(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheChipsAreSmallAndSitTwoToARowFortySixPixelsApart():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(Games(4)), mLauncher).
            Assert:Equals(232, w:ButtonFor("run/run-g1.p"):Width).
            Assert:Equals(40, w:ButtonFor("run/run-g1.p"):Height).
            Assert:Equals(w:ButtonFor("run/run-g1.p"):Height + 6, w:ButtonFor("run/run-g3.p"):Top - w:ButtonFor("run/run-g1.p"):Top).
            Assert:Equals(w:ButtonFor("run/run-g1.p"):Top, w:ButtonFor("run/run-g2.p"):Top).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoreThanEightGamesScrollInTheListInsteadOfLosingAny():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(Games(12)), mLauncher).
            Assert:Equals(650, w:ClientSize:Height).
            Assert:Equals(12, w:GameCount).
            Assert:Equals("G12", w:ButtonFor("run/run-g12.p"):Text).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    /* The window with the given games, and the accent name of one of them. */
    METHOD PRIVATE CHARACTER AccentIn(INPUT pcGames AS CHARACTER, INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE w      AS ArcadeWindow NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER    NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(pcGames), mLauncher).
            result = w:AccentNameFor(pcProgram).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
        RETURN result.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AColourAGameAsksForIsTheOneItGets():
        Assert:Equals("purple", AccentIn("run/run-a.p|Alpha|x|purple", "run/run-a.p")).
        Assert:Equals("teal", AccentIn("run/run-a.p|Alpha|x|TEAL", "run/run-a.p")).
        Assert:Equals("red", AccentIn("run/run-a.p|Alpha|x|red", "run/run-a.p")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameKeepsItsColourWhateverElseIsInTheList():
        DEFINE VARIABLE alone  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE second AS CHARACTER NO-UNDO.
        DEFINE VARIABLE third  AS CHARACTER NO-UNDO.
        alone = AccentIn("run/run-z.p|Zebra|x", "run/run-z.p").
        second = AccentIn("run/run-a.p|Alpha|x;run/run-z.p|Zebra|x", "run/run-z.p").
        third = AccentIn("run/run-a.p|Alpha|x;run/run-b.p|Beta|x;run/run-z.p|Zebra|x", "run/run-z.p").
        Assert:Equals(alone, second).
        Assert:Equals(alone, third).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AColourNameThatIsNotOneOfTheSevenFallsBackToTheTitlesOwn():
        Assert:Equals(AccentIn("run/run-a.p|Alpha|x", "run/run-a.p"),
                      AccentIn("run/run-a.p|Alpha|x|chartreuse", "run/run-a.p")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDefaultColourIsOneOfTheSeven():
        DEFINE VARIABLE c AS CHARACTER NO-UNDO.
        c = AccentIn("run/run-a.p|Alpha|x", "run/run-a.p").
        Assert:IsTrue(LOOKUP(c, "red,orange,blue,purple,green,yellow,teal") > 0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheColourOfAGameThatIsNotThereThrows():
        mWindow:AccentNameFor("run/run-zzz.p").
    END METHOD.

    /* Games in four categories (one of them none), in the form the fixed catalog takes. */
    METHOD PRIVATE CHARACTER SortedGames():
        RETURN "run/run-a.p|Alpha|1||Puzzle;run/run-b.p|Beta|2||Arcade;run/run-c.p|Gamma|3||Puzzle;"
             + "run/run-d.p|Delta|4;run/run-e.p|Eta|5||Arcade".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNoCategoriesThereAreNoTabs():
        Assert:Equals("", mWindow:TabNames).
        Assert:Equals("All", mWindow:ShownTab).
        Assert:Equals(2, mWindow:ShownCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CategoriesBecomeTabsInOrderThenOtherThenAll():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(SortedGames()), mLauncher).
            Assert:Equals("Arcade,Puzzle,Other,All", w:TabNames).
            Assert:Equals("Puzzle", w:TabFor("Puzzle"):Text).
            Assert:Equals("Puzzle games", w:TabFor("Puzzle"):AccessibleName).
            Assert:Equals("Arcade", w:ShownTab).
            Assert:Equals(2, w:ShownCount).
            w:ShowTab("All").
            Assert:Equals(5, w:ShownCount).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstTabIsShowingWhenTheWindowOpens():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog("a|Alpha|1||Zoo;b|Beta|2||Puzzle"), mLauncher).
            Assert:Equals("Puzzle,Zoo,All", w:TabNames).
            Assert:Equals("Puzzle", w:ShownTab).
            Assert:IsTrue(w:IsShown("b")).
            Assert:IsFalse(w:IsShown("a")).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATabShowsOnlyTheGamesOfItsCategory():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(SortedGames()), mLauncher).
            w:ShowTab("Puzzle").
            Assert:Equals("Puzzle", w:ShownTab).
            Assert:Equals(2, w:ShownCount).
            Assert:IsTrue(w:IsShown("run/run-a.p")).
            Assert:IsTrue(w:IsShown("run/run-c.p")).
            Assert:IsFalse(w:IsShown("run/run-b.p")).
            Assert:IsFalse(w:IsShown("run/run-d.p")).
            w:ShowTab("Other").
            Assert:Equals(1, w:ShownCount).
            Assert:IsTrue(w:IsShown("run/run-d.p")).
            w:ShowTab("All").
            Assert:Equals(5, w:ShownCount).
            Assert:IsTrue(w:IsShown("run/run-b.p")).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATabButtonIsNamedAfterTheCategoryItShows():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(SortedGames()), mLauncher).
            Assert:Equals("Arcade", w:TabFor("Arcade"):Name).
            Assert:Equals("All", w:TabFor("All"):Name).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACategoryIsMatchedIgnoringCaseAndSpaces():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog("a|Alpha|1||puzzle;b|Beta|2||  Puzzle "), mLauncher).
            Assert:Equals("puzzle,All", w:TabNames).
            w:ShowTab("puzzle").
            Assert:Equals(2, w:ShownCount).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTabsKeepTheWindowTheSameSizeAndTheCaptionShort():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(SortedGames()), mLauncher).
            Assert:Equals(650, w:ClientSize:Height).
            Assert:Equals("5 games in 3 groups, all cooking on the same grid.", w:Caption).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameStillStartsFromAFilteredList():
        DEFINE VARIABLE w AS ArcadeWindow NO-UNDO.
        DO ON ERROR UNDO, THROW:
            w = NEW ArcadeWindow("Arcade", NEW FixedGameCatalog(SortedGames()), mLauncher).
            w:ShowTab("Arcade").
            w:Play("run/run-e.p").
            Assert:Equals("run/run-e.p", mLauncher:Launched).
            Assert:Equals("Started Eta", w:StatusLine).
            FINALLY:
                IF VALID-OBJECT(w) THEN DO:
                    w:ReleaseResources().
                    w:Dispose().
                END.
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AskingIfAGameThatIsNotThereIsShownThrows():
        mWindow:IsShown("run/run-zzz.p").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ShowingATabThatIsNotThereThrows():
        mWindow:ShowTab("Puzzle").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AskingForATabThatIsNotThereThrows():
        mWindow:TabFor("Puzzle").
    END METHOD.

END CLASS.
