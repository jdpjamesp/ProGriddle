/* What the unknown things are called in one game, and which of them the hero has learnt. At the start of each game every potion kind is
   given a colour (red, blue, ...), every scroll kind a title made of nonsense syllables, every wand kind a metal or wood and every ring
   kind a stone, all different and all chosen with the random source, so the same colour means a different potion in the next game.
   Learn marks a kind as known (drinking it, reading it, a scroll of identify) and from then on it is called by its real name. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Disguises FINAL:

    /* potions 0 to 13, scrolls 14 to 27, wands 28 to 41, rings 42 to 55 */
    VAR PRIVATE CHARACTER[56] mName.
    VAR PRIVATE LOGICAL[56] mKnown.

    /* Gives every kind a new name and forgets everything learnt. Throws GridException for no random source. */
    CONSTRUCTOR PUBLIC Disguises(INPUT poRandom AS IRandom):
        Shuffle(poRandom).
    END CONSTRUCTOR.

    /* Starts again for a new game: new names, nothing known. */
    METHOD PUBLIC VOID Shuffle(INPUT poRandom AS IRandom):
        VAR INTEGER i.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Disguises need a random source").
        DO i = 1 TO 56:
            mKnown[i] = FALSE.
        END.
        Deal(poRandom, "red,blue,green,yellow,black,brown,orange,pink,purple,grey,white,silver,gold,violet,clear,vermilion,ecru,turquoise,magenta,amber,topaz,plaid,tan,tangerine", 0).
        Deal(poRandom, "aluminum,beryllium,bone,brass,bronze,copper,electrum,iron,lead,magnesium,mercury,nickel,pewter,pine,platinum,steel,tin,titanium,tungsten,zinc,oak,redwood", 28).
        Deal(poRandom, "agate,alexandrite,amethyst,carnelian,diamond,emerald,garnet,jade,moonstone,obsidian,onyx,opal,pearl,peridot,ruby,sapphire,zircon,lapis lazuli", 42).
        DO i = 15 TO 28:
            mName[i] = MakeTitle(poRandom, i).
        END.
    END METHOD.

    /* How the kind looks until it is known: the colour of a potion, the title of a scroll, the metal of a wand, the stone of a ring.
       Throws GridException for any other sort of item. */
    METHOD PUBLIC CHARACTER Appearance(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        RETURN mName[SlotOf(poType, piKind)].
    END METHOD.

    METHOD PUBLIC LOGICAL IsKnown(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        RETURN mKnown[SlotOf(poType, piKind)].
    END METHOD.

    /* The hero now knows what the kind is. */
    METHOD PUBLIC VOID Learn(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        mKnown[SlotOf(poType, piKind)] = TRUE.
    END METHOD.

    /* How many kinds of every sort the hero knows. */
    METHOD PUBLIC INTEGER KnownCount():
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 56:
            IF mKnown[i] THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The number of kinds of a sort that can be disguised: 14 for a potion, scroll, wand or ring and 0 for the rest. */
    METHOD PUBLIC STATIC INTEGER Kinds(INPUT poType AS ItemType):
        CASE poType:
            WHEN ItemType:Potion OR WHEN ItemType:Scroll OR WHEN ItemType:Wand OR WHEN ItemType:Ring THEN RETURN 14.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    METHOD PRIVATE INTEGER SlotOf(INPUT poType AS ItemType, INPUT piKind AS INTEGER):
        VAR INTEGER base.
        IF NOT VALID-OBJECT(poType) THEN UNDO, THROW NEW GridException("There is no sort of item to look up").
        CASE poType:
            WHEN ItemType:Potion THEN base = 0.
            WHEN ItemType:Scroll THEN base = 14.
            WHEN ItemType:Wand THEN base = 28.
            WHEN ItemType:Ring THEN base = 42.
            OTHERWISE UNDO, THROW NEW GridException("Only potions, scrolls, wands and rings have unknown names, not " + STRING(poType)).
        END CASE.
        IF piKind = ? OR piKind < 0 OR piKind > 13 THEN UNDO, THROW NEW GridException("There is no kind " + STRING(piKind)).
        RETURN base + piKind + 1.
    END METHOD.

    /* Deals 14 different names from a list into the 14 slots from piBase. */
    METHOD PRIVATE VOID Deal(INPUT poRandom AS IRandom, INPUT pcPool AS CHARACTER, INPUT piBase AS INTEGER):
        VAR CHARACTER[30] pool.
        VAR INTEGER i.
        VAR INTEGER n.
        VAR INTEGER p.
        n = NUM-ENTRIES(pcPool).
        DO i = 1 TO n:
            pool[i] = ENTRY(i, pcPool).
        END.
        DO i = 1 TO 14:
            p = poRandom:NextInt(n) + 1.
            mName[piBase + i] = pool[p].
            pool[p] = pool[n].
            n = n - 1.
        END.
    END METHOD.

    /* A title of one to three words, each of one to three syllables, that no other scroll has. */
    METHOD PRIVATE CHARACTER MakeTitle(INPUT poRandom AS IRandom, INPUT piSlot AS INTEGER):
        VAR CHARACTER syllables.
        VAR CHARACTER heading.
        VAR INTEGER words.
        VAR INTEGER w.
        VAR INTEGER s.
        VAR INTEGER j.
        VAR LOGICAL again.
        VAR INTEGER tries.
        syllables = "a,ab,ag,aks,ala,an,app,arg,arze,ash,bek,bie,bit,bjor,blu,bot,bu,byt,comp,con,cos,cre,dalf,dan,den,do,e,eep,el,eng,er,ere,erk,esh,evs,fa,fid,fri,fu,gan,gar,glen,gop,gre,ha,hyd,i,ing,ip,ish,it,ite,iv,jo,kho,kli,klis,la,lech,mar,me,mi,mic,mik,mon,mung,mur,nej,nelg,nep,ner,nes,nih,nin,o,od,ood,org,orn,ox,oxy,pay,ple,plu,po,pot,prok,re,rea,rhov,ri,ro,rog,rok,rol,sa,san,sat,sef,seh,shu,ski,sna,sne,snik,so,sol,sri,sta,sun,taf,tem,ther,ti,tox,trol,tue,turs,u,ulk,um,un,uni,ur,val,viv,vly,vom,wah,wed,werg,wex,whon,wun,xo,y,yot,yu,zant,zeb,zim,zok,zon,zum".
        REPEAT:
            tries = tries + 1.
            heading = "".
            words = poRandom:NextInt(3) + 1.
            DO w = 1 TO words:
                IF w > 1 THEN heading = heading + " ".
                DO s = 1 TO poRandom:NextInt(3) + 1:
                    heading = heading + ENTRY(poRandom:NextInt(NUM-ENTRIES(syllables)) + 1, syllables).
                END.
            END.
            again = FALSE.
            DO j = 15 TO piSlot - 1:
                IF mName[j] = heading THEN again = TRUE.
            END.
            IF NOT again THEN LEAVE.
            /* a random source that keeps giving the same title is given a number to keep the titles different */
            IF tries >= 40 THEN DO:
                heading = heading + " " + STRING(piSlot).
                LEAVE.
            END.
        END.
        RETURN heading.
    END METHOD.

END CLASS.
