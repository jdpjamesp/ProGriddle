/* The command that is waiting for an item or a direction. None when nothing is. */
ENUM ProGriddle.Games.Rogue.RogueAction:

    DEFINE ENUM None = 0
                Quaff
                ReadScroll
                Eat
                Wield
                Wear
                TakeOff
                PutOn
                RemoveRing
                DropItem
                ThrowItem
                Zap
                Identify.

END ENUM.
