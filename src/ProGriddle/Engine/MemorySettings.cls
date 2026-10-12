/* Settings held in memory only: a test double, and a stand-in when nothing should be saved.
   Save does nothing. */
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.MemorySettings FINAL INHERITS AbstractSettings:

    METHOD PUBLIC OVERRIDE VOID Save():
    END METHOD.

END CLASS.
