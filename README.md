# ReNameR
A simple (and probably dirty) mass-files renamer in ruby.

This script has two functions:
 1. compact: renames a file into its CamelCase version, removing spaces and
    using capital letters to separate words. Other capital letters are
    converted to lower case.
 2. widen: renames a file adding spaces when needed.
Note that both these functions are recursive for folders.

Every other info you may need about this script can be found either running it
with the -h flag, or by reading its source code.

