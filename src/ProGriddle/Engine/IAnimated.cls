/* A real time game that has something moving on the screen that is not part of play, such as the animation that ends
   a game: a block fill, a fade. While Animating is true the controller keeps the clock running and redraws every tick,
   even if the game is over. When it goes false, a game that is over stops the clock as usual. A game that does not
   have such animations does not implement this. */
INTERFACE ProGriddle.Engine.IAnimated:

    DEFINE PUBLIC PROPERTY Animating AS LOGICAL NO-UNDO
        GET.

END INTERFACE.
