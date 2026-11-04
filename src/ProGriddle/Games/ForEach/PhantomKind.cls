/* The four phantoms, in the order of the roll call. Each hunts in its own way (see PhantomTargeting):

     Mary    the chaser: heads for Dibby, starts outside the lobby and winds up when the bits run low
     Rich    the ambusher: heads for the tile four ahead of Dibby
     Brian   the unpredictable one: aims from Mary's position and Dibby's
     Chip    the shy one: chases from far away and runs for his corner when close */
ENUM ProGriddle.Games.ForEach.PhantomKind:

    DEFINE ENUM Mary = 1
                Rich
                Brian
                Chip.

END ENUM.
