/* A blast in Blast Buddies: it carves a hole in the ground (and the crumb rule clears what it leaves floating), then hurts and throws
   every buddy near it. A buddy whose middle is within the radius plus BlastReach pixels takes damage that falls in a straight line from the
   full damage at the centre to nothing at the edge, and is thrown away from the centre at a speed that falls the same way. The buddies
   hurt by the last blast can be read with HitCount, HitBuddy and HitDamage, for the damage numbers over them. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.Explosion FINAL:

    DEFINE PRIVATE VARIABLE mHits   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBuddy  AS Buddy   NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mDamage AS INTEGER NO-UNDO EXTENT 16.

    /* How many buddies the last blast hurt. */
    METHOD PUBLIC INTEGER HitCount():
        RETURN mHits.
    END METHOD.

    /* The buddy hurt, 1 to HitCount(), and what the blast took from it. */
    METHOD PUBLIC Buddy HitBuddy(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mHits THEN UNDO, THROW NEW GridException("There is no hit " + STRING(piIndex)).
        RETURN mBuddy[piIndex].
    END METHOD.

    METHOD PUBLIC INTEGER HitDamage(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mHits THEN UNDO, THROW NEW GridException("There is no hit " + STRING(piIndex)).
        RETURN mDamage[piIndex].
    END METHOD.

    /* Blows up at (piCx, piCy) with a radius and a damage at the centre. Every buddy of the plan that has not drowned is thrown, living or
       dead, and the living are hurt. Returns how many buddies were hurt. */
    METHOD PUBLIC INTEGER Detonate(INPUT poTerrain AS Terrain, INPUT poPlan AS TurnPlan, INPUT poPhysics AS BuddyPhysics,
                                   INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piRadius AS INTEGER, INPUT piDamage AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE b     AS Buddy   NO-UNDO.
        DEFINE VARIABLE reach AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE portion AS DECIMAL NO-UNDO.
        DEFINE VARIABLE dmg   AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed AS DECIMAL NO-UNDO.
        IF NOT VALID-OBJECT(poTerrain) OR NOT VALID-OBJECT(poPlan) OR NOT VALID-OBJECT(poPhysics) THEN
            UNDO, THROW NEW GridException("A blast needs a terrain, a plan and physics").
        mHits = 0.
        reach = piRadius + BuddyRules:BlastReach().
        poTerrain:Carve(piCx, piCy, piRadius).
        poTerrain:Crumble(piCx, piCy, piRadius).
        DO i = 1 TO poPlan:TeamCount():
            DO j = 1 TO poPlan:TeamAt(i):Count():
                b = poPlan:TeamAt(i):BuddyAt(j).
                IF b:State = BuddyState:Drowned THEN NEXT.
                /* the middle of the buddy is 5 pixels above its feet */
                dx = b:X() - piCx.
                dy = b:Y() - 5 - piCy.
                d = SQRT(DECIMAL(dx * dx + dy * dy)).
                IF d >= reach THEN NEXT.
                portion = (reach - d) / reach.
                IF NOT b:IsDead() THEN DO:
                    dmg = INTEGER(TRUNCATE(piDamage * portion, 0)).
                    IF dmg > 0 THEN DO:
                        dmg = b:Hurt(dmg).
                        IF mHits < EXTENT(mBuddy) THEN DO:
                            mHits = mHits + 1.
                            mBuddy[mHits] = b.
                            mDamage[mHits] = dmg.
                        END.
                    END.
                END.
                /* thrown straight away from the centre (straight up from the very middle), with a little lift */
                speed = BuddyRules:KnockbackMax() * portion.
                IF d = 0 THEN poPhysics:Launch(b, 0, - INTEGER(ROUND(speed, 0))).
                ELSE poPhysics:Launch(b, INTEGER(ROUND(speed * dx / d, 0)), INTEGER(ROUND(speed * dy / d, 0)) - BuddyRules:KnockbackLift()).
            END.
        END.
        RETURN mHits.
    END METHOD.

END CLASS.
