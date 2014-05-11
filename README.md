bloodarena3D
============

ABOUT: After encountering errors with my previous repository for this project, I'm gonna open this second repository to track further debugging and changes I make to the final code.

TD:

NOTES:

ISSUES:
-index-out-of-bounds crash caused by concurrent access of an ArrayList object.
need to go through the "Map" object and create SynchronizedList objects whenever ITERATING OVER or CHECKING AGAINST the ArrayList. addition/removal are fine. Remember: KeyPressed() is also a concurrent function.

-another index crash is caused by concurrent access of the texture arrays. for now, I will simply remove any runtime texture-shifting functionality to be implemented in a safer way later.
-chucK code don't work
