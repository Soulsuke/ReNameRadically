# ReNameR
A simple (and probably dirty) files mass-renamer in ruby.

This script has the following functions:
 1. compact: renames a file to a CamelCase format, removing spaces and
    using capital letters to separate words. Other capital letters are
    converted to lower case.
 2. widen: renames a file adding spaces when needed.
 3. regex: replaces every occurrences of the fiven regex with the given 
    substitute.
Note that all of these functions are recursive for folders.

When renaming a file, if there already is one with the destination name, a
numeric index will be appended before the file extension. Also, if the 
resulting new name would be empty, the file will not be renamed at all.

It allows per-user configuration through a YAML file located in $HOME/.rnr.

Tested on ruby version 2.3.1.

Run the script (with -h, maybe) and it will notify you of any gem it requires 
that has not been found on the system.

Every other info you may need about this script can be found either running it
with the -h flag, or by reading its source code.

