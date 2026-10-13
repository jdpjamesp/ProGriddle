/* Test double: a catalog of games given as text, one game per semicolon, each as program|title|blurb or program|title|blurb|accent.
   Not a test class itself (the name does not end in Tests). */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.FixedGameCatalog IMPLEMENTS IGameCatalog:

    DEFINE PRIVATE VARIABLE mGames AS CHARACTER NO-UNDO.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            IF mGames = "" THEN RETURN 0.
            RETURN NUM-ENTRIES(mGames, ";").
        END GET.

    CONSTRUCTOR PUBLIC FixedGameCatalog(INPUT pcGames AS CHARACTER):
        mGames = pcGames.
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER ProgramAt(INPUT piPlace AS INTEGER):
        RETURN ENTRY(1, ENTRY(piPlace, mGames, ";"), "|").
    END METHOD.

    METHOD PUBLIC CHARACTER TitleAt(INPUT piPlace AS INTEGER):
        RETURN ENTRY(2, ENTRY(piPlace, mGames, ";"), "|").
    END METHOD.

    METHOD PUBLIC CHARACTER AccentAt(INPUT piPlace AS INTEGER):
        DEFINE VARIABLE item AS CHARACTER NO-UNDO.
        item = ENTRY(piPlace, mGames, ";").
        RETURN (IF NUM-ENTRIES(item, "|") >= 4 THEN ENTRY(4, item, "|") ELSE "").
    END METHOD.

    METHOD PUBLIC CHARACTER BlurbAt(INPUT piPlace AS INTEGER):
        RETURN ENTRY(3, ENTRY(piPlace, mGames, ";"), "|").
    END METHOD.

END CLASS.
