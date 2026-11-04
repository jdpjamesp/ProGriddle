/* The bonus items that come out under the lobby, one kind for each pair of levels (see ForEachRules:ItemFor). Each has its own
   shape, so colour is never needed to tell them apart. */
ENUM ProGriddle.Games.ForEach.ItemKind:

    DEFINE ENUM Floppy = 1
                Tape
                Key
                Table
                Query
                Trigger
                Lock
                Server.

END ENUM.
