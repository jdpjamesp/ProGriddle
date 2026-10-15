/* The five pieces a snake is drawn from (docs/design/snake-art.md 2.1): the head, the head with its tongue out, a straight
   piece of body, a corner and the tail. Each is turned to face the way it needs to. */
ENUM ProGriddle.Games.Snake.SnakePart:

    DEFINE ENUM Head = 0
                HeadTongue
                Straight
                Corner
                Tail.

END ENUM.
