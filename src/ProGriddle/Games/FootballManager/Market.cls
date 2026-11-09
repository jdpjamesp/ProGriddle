/* The transfer market: after each match one player the club does not own is offered, and the manager may bid for him; and the manager may sell any player who is not injured to an offer the other club makes, or turn it down (and risk the player taking offence and getting injured). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Market FINAL:

    METHOD PRIVATE STATIC INTEGER Roll(INPUT poRandom AS IRandom, INPUT piMost AS INTEGER):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("The market needs a random source").
        RETURN poRandom:NextInt(piMost) + 1.
    END METHOD.

    /* The player on offer this week: one of those the club does not own, at random. */
    METHOD PUBLIC STATIC INTEGER Offer(INPUT poWorld AS FootballWorld, INPUT poRandom AS IRandom):
        RETURN poWorld:NthOutsider(Roll(poRandom, poWorld:OutsiderCount())).
    END METHOD.

    /* Whether the club has room for another player (at most 16). */
    METHOD PUBLIC STATIC LOGICAL CanSign(INPUT poWorld AS FootballWorld):
        RETURN poWorld:OwnedCount() < FootballRules:SquadMax().
    END METHOD.

    /* Bids piAmount for a player the club does not own. A full squad or too little cash gives SquadFull or NoMoney and changes nothing. Otherwise the club accepts if ten times a random 1 to 10 of the bid is at least five times his value: sixty chances in a hundred at his value, eighty at twice, a certainty at five times, none at under half. Accepted: the cash is paid, he joins as a reserve and his value is put back to what his skill is worth. Refused: his value goes up by a fifth. Throws GridException for a negative bid or a player the club owns. */
    METHOD PUBLIC STATIC BidResult Bid(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER, INPUT piAmount AS INTEGER, INPUT poRandom AS IRandom):
        IF piAmount = ? OR piAmount < 0 THEN UNDO, THROW NEW GridException("A bid cannot be " + STRING(piAmount)).
        IF poWorld:RoleOf(piPlayer) <> SquadRole:NotOwned THEN
            UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " is already in the squad").
        IF NOT CanSign(poWorld) THEN RETURN BidResult:SquadFull.
        IF piAmount > poWorld:Cash THEN RETURN BidResult:NoMoney.
        IF Roll(poRandom, 10) * piAmount >= 5 * poWorld:WorthOf(piPlayer) THEN
        DO:
            poWorld:SetWorth(piPlayer, poWorld:SkillOf(piPlayer) * FootballRules:ValueUnit() * poWorld:Multiplier).
            poWorld:Cash = poWorld:Cash - piAmount.
            poWorld:SetRole(piPlayer, SquadRole:Reserve).
            RETURN BidResult:Accepted.
        END.
        poWorld:SetWorth(piPlayer, INTEGER(TRUNCATE(poWorld:WorthOf(piPlayer) + poWorld:WorthOf(piPlayer) / 5, 0))).
        RETURN BidResult:Refused.
    END METHOD.

    /* Whether a player can be sold: he is in the squad and not injured. */
    METHOD PUBLIC STATIC LOGICAL CanSell(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER):
        RETURN poWorld:RoleOf(piPlayer) = SquadRole:Reserve OR poWorld:RoleOf(piPlayer) = SquadRole:Starter.
    END METHOD.

    /* What another club offers for a player: from 0.8 to just under 1.3 times his value, in steps of a thousandth. Throws GridException for a player who cannot be sold. */
    METHOD PUBLIC STATIC INTEGER SaleOffer(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER, INPUT poRandom AS IRandom):
        VAR DECIMAL extra.
        IF NOT CanSell(poWorld, piPlayer) THEN UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " cannot be sold").
        extra = Roll(poRandom, 5000) - 1.
        RETURN INTEGER(TRUNCATE(((8000 + extra) * poWorld:WorthOf(piPlayer)) / 10000, 0)).
    END METHOD.

    /* The club that makes an offer, a slot from 1 to 64 at random. */
    METHOD PUBLIC STATIC INTEGER BuyerSlot(INPUT poRandom AS IRandom):
        RETURN Roll(poRandom, FootballRules:ClubCount()).
    END METHOD.

    /* The manager accepts an offer of piAmount: the cash comes in and the player leaves the squad. Throws GridException for a player who cannot be sold. */
    METHOD PUBLIC STATIC VOID Sell(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER, INPUT piAmount AS INTEGER):
        IF NOT CanSell(poWorld, piPlayer) THEN UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " cannot be sold").
        IF piAmount = ? OR piAmount < 0 THEN UNDO, THROW NEW GridException("An offer cannot be " + STRING(piAmount)).
        poWorld:Cash = poWorld:Cash + piAmount.
        poWorld:SetRole(piPlayer, SquadRole:NotOwned).
    END METHOD.

    /* The manager turns an offer down: one time in three nothing happens, and otherwise the player is injured. Returns true when he was. */
    METHOD PUBLIC STATIC LOGICAL TurnDown(INPUT poWorld AS FootballWorld, INPUT piPlayer AS INTEGER, INPUT poRandom AS IRandom):
        IF NOT CanSell(poWorld, piPlayer) THEN UNDO, THROW NEW GridException(FootballNames:Player(piPlayer) + " cannot be sold").
        IF Roll(poRandom, 3) = 1 THEN RETURN FALSE.
        poWorld:SetRole(piPlayer, SquadRole:Injured).
        RETURN TRUE.
    END METHOD.

END CLASS.
