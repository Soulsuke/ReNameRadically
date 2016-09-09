# ReNameR
A simple (and probably dirty) files mass-renamer in ruby.

IMPORTANT: this script is meant to be used on a Linux/Unix environment. It has
not been tested (and probably never will be) on different operating systems.
Tested on ruby version 2.3.1.
Run the script (with -h, maybe) and it will notify you of any gem it requires 
that has not been found on the system.

This script has the following functions:
 1. compact: renames a file to a CamelCase format, removing spaces and using
      capital letters to separate words. Other capital letters areconverted to
      lower case.
 2. widen: renames a file adding spaces to separate words in CamelCase format,
      and, depending on the case, before or after punctation.
 3. regex: replaces all occurrences of the given regex with the given 
      substitute string.
Note that all of these functions are recursive for folders, and will not change
the file extension.

It allows per-user configuration through a YAML file located in $HOME/.rnr.

When renaming a file, if there is already an existing one with the desired 
destination name, a numeric index will be appended before the file extension.
If the resulting new name would be empty, the file will not be renamed at all.
If the new file name would exceed 255 characters minus the extension's length,
it will be truncated.

Every other info you may need about this script can be found either running it
with the -h flag, or by reading its source code (which I'm trying to keep
readable and well commented).

