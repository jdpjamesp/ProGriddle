/* The second half of a game's cue source, for a game that has sounds which last as long as something goes on: the thrust of a
   ship, the hum of a saucer. Unlike a cue, which is an event, a loop is a state: the source says which loops should be sounding
   now, and the SoundRenderer starts the ones that have begun and stops the ones that have ended. A cue source that also
   implements this is used for loops with no other change. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.ILoopSource:

    /* The cues (cue numbers, 1 to 64, made from a recipe that loops) that should be sounding now, as a comma list, or "" for none.
       A game that is paused, over or between games has none. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame).

END INTERFACE.
