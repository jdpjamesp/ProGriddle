/* Finds the sound cues of one game: what has happened in it since the last look. A game keeps the times of its events (a lock, a
   clear, the end), so a cue source compares them with the ones it saw and says what is new. There is one per game, written
   next to the game and its cue enum, and the SoundRenderer asks it after every change of the picture. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.ICueSource:

    /* The cues that have happened since the last call, most important first, as a comma list of cue numbers (the integer of a
       cue enum, 1 to 64), or "" for none. Each event is reported once. A game that starts again is noticed and its old events
       are forgotten, so nothing sounds for them. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame).

    /* The priority group of a cue. Of the cues of one group that come in the same poll only the first is played, so a lock and a
       clear at the same moment make one sound, not two. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER).

END INTERFACE.
