/* Settings held in memory only: a test double, and a stand-in when nothing should be saved.
   Save does nothing. */
USING Prolif.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.MemorySettings FINAL INHERITS AbstractSettings:

    METHOD PUBLIC OVERRIDE VOID Save():
    END METHOD.

END CLASS.
