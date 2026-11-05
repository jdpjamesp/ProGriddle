/* The sort of thing an item is. The kind within the sort is a number of the enum of that sort (PotionKind, ScrollKind, WandKind, RingKind, WeaponKind, ArmourKind, FoodKind); gold and the amulet have no kind. */
ENUM ProGriddle.Games.Rogue.ItemType:

    DEFINE ENUM Gold = 0
                Food
                Weapon
                Armour
                Potion
                Scroll
                Wand
                Ring
                Amulet.

END ENUM.
