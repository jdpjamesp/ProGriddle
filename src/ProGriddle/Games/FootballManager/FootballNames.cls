/* The names of the original game: its 64 clubs (16 to each division, in slot order), its 24 players (eight defenders, eight midfielders, eight forwards) and the seven skill levels. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballNames FINAL:

    /* The club in a slot from 1 to 64: slots 1 to 16 are the first division, 17 to 32 the second and so on down. Throws GridException for any other slot. */
    METHOD PUBLIC STATIC CHARACTER Club(INPUT piSlot AS INTEGER):
        VAR CHARACTER list.
        IF piSlot = ? OR piSlot < 1 OR piSlot > FootballRules:ClubCount() THEN
            UNDO, THROW NEW GridException("There is no club in slot " + STRING(piSlot)).
        CASE TRUNCATE((piSlot - 1) / 16, 0):
            WHEN 0 THEN list = "Arsenal,Aston V.,Brighton,Coventry,Everton,Ipswich,Liverpool,Luton,Man.City,Man.Utd,Norwich,Notts.F.,Swansea,Spurs,Watford,West Ham".
            WHEN 1 THEN list = "Blackburn,Bolton,Cambridge,Charlton,Chelsea,Crystal P.,Derby Co.,Fulham,Grimsby,Leeds,Middlesbro,Newcastle,Oldham,Q.P.R.,Rotherham,Sheff.Wed".
            WHEN 2 THEN list = "Bradford,Brentford,Bristol R.,Cardiff,Doncaster,Exeter,Lincoln,Millwall,Newport,Orient,Oxford,Plymouth,Preston,Reading,Southend,Walsall".
            OTHERWISE list = "Blackpool,Bury,Colchester,Crewe,Darlington,Halifax,Hartlepool,Hereford,Hull,Mansfield,Port Vale,Rochdale,Scunthorpe,Stockport,Torquay,York City".
        END CASE.
        RETURN ENTRY(((piSlot - 1) MODULO 16) + 1, list).
    END METHOD.

    /* The player of the pool from 1 to 24. Throws GridException for any other number. */
    METHOD PUBLIC STATIC CHARACTER Player(INPUT piPlayer AS INTEGER):
        VAR CHARACTER list.
        IF piPlayer = ? OR piPlayer < 1 OR piPlayer > FootballRules:PoolSize() THEN
            UNDO, THROW NEW GridException("There is no player " + STRING(piPlayer)).
        CASE TRUNCATE((piPlayer - 1) / 8, 0):
            WHEN 0 THEN list = "P.Parkes,D.Watson,P.Neal,A.Martin,K.Sansom,M.Mills,R.Osman,S.Foster".
            WHEN 1 THEN list = "B.Robson,G.Hoddle,G.Rix,S.Hunt,G.Owen,R.Moses,B.Talbot,S.McCall".
            OTHERWISE list = "C.Regis,P.Withe,T.Morley,P.Barnes,E.Gates,K.Reeves,K.Keegan,G.Shaw".
        END CASE.
        RETURN ENTRY(((piPlayer - 1) MODULO 8) + 1, list).
    END METHOD.

    /* The position of a player of the pool: 1 to 8 defend, 9 to 16 play in midfield, 17 to 24 attack. */
    METHOD PUBLIC STATIC FootballPosition PositionOf(INPUT piPlayer AS INTEGER):
        IF piPlayer = ? OR piPlayer < 1 OR piPlayer > FootballRules:PoolSize() THEN
            UNDO, THROW NEW GridException("There is no player " + STRING(piPlayer)).
        RETURN FootballPosition:GetEnum(INTEGER(TRUNCATE((piPlayer - 1) / 8, 0)) + 1).
    END METHOD.

    /* The name of a skill level from 1 (Beginner) to 7 (Genius). Throws GridException for any other. */
    METHOD PUBLIC STATIC CHARACTER Level(INPUT piLevel AS INTEGER):
        IF piLevel = ? OR piLevel < 1 OR piLevel > FootballRules:LevelCount() THEN
            UNDO, THROW NEW GridException("There is no skill level " + STRING(piLevel)).
        RETURN ENTRY(piLevel, "Beginner,Novice,Average,Good,Expert,Super Expert,Genius").
    END METHOD.

END CLASS.
