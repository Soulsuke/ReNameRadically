# ReNameRadically

A simple (and probably dirty) files mass-renamer ruby gem with a handy
command line executable.  
Tested on ruby version 3.1.2.



### Installation
To install the gem, run:

>$ gem install rename_radically

On some systems you may have to use the `--user-install` flag.  



### Usage

**IMPORTANT:** this is meant to be used on a Linux/Unix environment. It has not
been tested (and probably never will be) on different operating systems.

To run the executable (you may want to run it with the -h flag the first time):
>$ rnr



### Functionalities
ReNameRadically has the following working modalities:  
- **compact:** renames a file to a CamelCase format, removing spaces and using
               capital letters to separate words. Other capital letters 
               areconverted to lower case.  
- **widen:** renames a file adding spaces to separate words in CamelCase 
             format, and, depending on the case, before or after punctation.  
- **regex:** replaces all occurrences of the given regex with the given 
             substitute string.  
- **renaming script:** creates a bash script to rename files, for whenever the
                       other modalities cannot yield the desired result.  
Note that modalities 1, 2 and 3 are recursive for folders, and that the file
extension will not be affected.  

Per-user configuration is handled through a YAML file (quote human readable)
located in:  
>~/.config/rnr/config.yml

When renaming a file, if there is already an existing one with the desired 
destination name, a numeric index will be appended before the file extension.
If the resulting new name would be empty, the file will not be renamed at all.
If the new file name would exceed 255 characters minus the extension's length,
it will be truncated.  

Every other info you may need about this gem can be found either reading its
source code (which I'm trying to keep readable and well commented), or by
running its executable file with the -h flag.  

