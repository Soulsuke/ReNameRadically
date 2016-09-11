#! /usr/bin/env ruby

=begin
This is the Renamer class.
It's supposed to rename the given files or folders (recursively) to a compact
CamelCase version, or to add back spaces to an already compat file.

This code is written in a single "all-in-one" file to be run as a standalone
file. To require it into another project, simply remove Act III and the first
line of this file. You may also consider fixing Act I and the value of @config
as well.
=end 

###############################################################################
### Act I                                                                   ###
### Attempt to require the necessary gems.                                  ###
###############################################################################
# Required gems:
req_gems = [ "pathname", "unicode", "yaml" ]

# Control variable:
gems_missing = false

# Let's check the required gems!
req_gems.each do |i|
  # If requiring goes right, just move on.
  begin
    require i

  # If something went wrong, print out the gem's name.
  rescue LoadError
    # Also, print this message the first time:
    unless gems_missing then
      gems_missing = true
      puts "You lack the following ruby gems to run this script:"
    end

    puts " > #{i}"
  end
end

# ...Of course, there's no point in going on if a require failed.
if gems_missing then
  exit -1
end

###############################################################################
### Act II                                                                  ###
### Renamer class declaration.                                              ###
###############################################################################
class Renamer
  @config     # Location of the user config file.
  @as_spaces  # Array of characters to be treated as spaces
  @delimiters # Array of characters to used as word delimiters
  @ex_after   # Array of exceptions not to put a space after in widen mode.
  @ex_before  # Array of exceptions not to put a space before in widen mode.
  @script     # Script name for script renaming mode.

  # Default constructor: it ensures there's a valid config file in the
  # user's home directory.
  def initialize
    @config = "#{ENV['HOME']}/.rnr"

    # Attempt to read from the config file:
    begin
      loaded_config = YAML.load_file @config
      @as_spaces = loaded_config["as_spaces"]
      @delimiters = loaded_config["delimiters"]
      @ex_after = loaded_config["ex_after"]
      @ex_before = loaded_config["ex_before"]
      @script = loaded_config["script"]

      # Fastest way to check for data consistency:
      @as_spaces[0]
      @delimiters[0]
      @ex_after[0]
      @ex_before[0]
      @script = loaded_config["script"][0]

    # If it fails, create a new default config file:
    rescue
      # This is the best way I can think of to hardcode the default config file
      # without breaking the formatting.
      config = Array.new
      config.push "# Characters treated as spaces, which get removed while " +
                  "renaming a file in"
      config.push "# non-wide mode:"
      config.push "as_spaces:"
      config.push "- \"_\""
      config.push " "
      config.push "# Characters after which a word should be capitalized in" +
                  " non-wide mode:"
      config.push "delimiters:"
      config.push "- \"-\""
      config.push "- \"+\""
      config.push "- \"(\""
      config.push "- \")\""
      config.push "- \"[\""
      config.push "- \"]\""
      config.push "- \"{\""
      config.push "- \"}\""
      config.push "- \"'\""
      config.push "- \"&\""
      config.push "- \".\""
      config.push "- \"!\""
      config.push "- \"?\""
      config.push " "
      config.push "# Characters after which must not be added a space in " +
                  "wide mode:"
      config.push "ex_after:"
      config.push "- \"'\""
      config.push "- \"(\""
      config.push "- \"-\""
      config.push "- \"<\""
      config.push "- \"[\""
      config.push "- \"{\""
      config.push "- \".\""
      config.push " "
      config.push "# Characters before which must not be added a space in " +
                  "wide mode:"
      config.push "ex_before:"
      config.push "- \".\""
      config.push "- \",\""
      config.push "- \"?\""
      config.push "- \"!\""
      config.push "- \"'\""
      config.push "- \")\""
      config.push "- \"]\""
      config.push "- \"}\""
      config.push "- \">\""
      config.push "- \"-\""
      config.push "- \"_\""
      config.push " "
      config.push "# Name of the script file created by renaming script mode:"
      config.push "script:"
      config.push "- \"REN.bash\""
      config.push " "

      config = config.join "\n"

      loaded_config = YAML.load config

      # Attempt to create the file:
      begin 
        File.open @config, "w" do |f|
          f.puts config
        end
        puts "Created a new config file: #{@config}"

        # ...And be sure that everything went right:
        loaded_config = YAML.load_file @config

      # Something went horribly wrong: maybe there's no home folder, or its
      # permissions are all wrong... So, screw the config file and use default
      # values for this ride.
      rescue
        puts "WARNING: could not read/write file #{@config}, you might want" +
             " to check out why."
      end

      # Finally, valorize these:
      @as_spaces = loaded_config["as_spaces"]
      @delimiters = loaded_config["delimiters"]
      @ex_after = loaded_config["ex_after"]
      @ex_before = loaded_config["ex_before"]
      @script = loaded_config["script"][0]
    end
  end

  # Private method: checks if the given files exist, then prints a list of the
  # not found ones and returns an array containing the Pathname objects of the
  # found ones.
  private def checkFiles( *files )
    # This will contain the not found files:
    not_found = Array.new

    # This will contain files we do not have the permissions to move:
    no_permissions = Array.new

    # This will contain the valid files:
    ok = Array.new

    # Now, check each file:
    files.each do |entry|
      tmp = Pathname.new( entry )

      # The file exists!
      if tmp.exist? and "." != tmp.to_s and ".." != tmp.to_s then

        # And we do have the permissions to move it!
        if tmp.dirname.writable? then
          ok.push tmp

        # Apparently, we cannot rename it:
        else
          no_permissions.push tmp
        end

      # The file has not been found:
      else
        not_found.push entry
      end
    end

    # Print a list of not found files:
    not_found.each_with_index do |entry, idx|
      if 0 == idx then
        puts "The following files will be ignored (not found or invalid):"
      end

      puts "- #{entry}"
    end

    # Print a list of files we do not have permission to rename:
    no_permissions.each_with_index do |entry, idx|
      if 0 == idx then
        puts "You lack the permissions to move the following files:"
      end

      puts "- #{entry}"
    end

    # Return the arraid containing the valid ones:
    return ok
  end

  # Private method: will smartly rename a file (Pathname format) to
  # new_name, preserving the original path and extension. If another file with
  # the destination name already exists, the new one will have a number
  # appended to its name. Returns the new name of the file.
  private def smartRename( file, new_name )
    # Be sure to remove characters which are not allowed for file names:
    new_name.gsub! "/" ""
    new_name.gsub! "\0" ""

    # Also, the max name length is 255, including the extension:
    new_name.scan( /.{#{255 - "#{file.extname}".length}}/ )[0]

    # Hopefully, this is already the name that will be used:
    destination = Pathname.new "#{file.dirname}/#{new_name}#{file.extname}"

    # Rename the file only if the destination is different than the origin and
    # if the file name is not empty.
    unless file.basename == destination.basename or "#{new_name}".empty? or
           "." == new_name or ".." == new_name then
      # Index variable for worst-case scenario:
      index = 0

      # To be honest... If this goes beyond 2, the user is really just messing 
      # with us.
      while destination.exist? do
        index += 1
        destination = Pathname.new "#{file.dirname}/#{new_name}-#{index}" +
                                   "#{file.extname}"
      end

      # Rename away!
      file.rename destination
    end

    # In any case, return the destination (Pathname format):
    return destination
  end

  # Private method, called through compact: renames a single file to a compact
  # CamelCase version. This contains the main logic of renaming files in such
  # way. Returns the new name of the renamed file.
  private def compactFile( file )
    # Get the file's basename, without its extension:
    file_name = file.basename( file.extname ).to_s

    # Replace the characters contained in the "as_spaces" field in the config
    # file with spaces:
    @as_spaces.each do |rm|
      file_name[0].gsub! rm, " "
    end

    # Add a space after each delimiter:
    @delimiters.each do |delimiter|
      file_name.gsub! delimiter, "#{delimiter} "
    end

    # Now split it into parts that should be capitalized!
    file_name = file_name.split " "

    # And actually capitalize them:
    file_name.each_with_index do |entry, idx|
      file_name[idx] = Unicode::capitalize entry
    end
    
    # Rename the file and return its new name:
    return smartRename file, file_name.join
  end
  
  # Private method, called through compact: recursively renames a folder and
  # its content to a compact CamelCase version.
  private def compactFolder( folder )
    # Rename the folder:
    new_folder_name = compactFile folder

    # Then rename everything it contains, recursively:
    new_folder_name.entries.each do |entry|
      # Ignore "." and "..", though.
      if "." != entry.to_s and ".." != entry.to_s then
        compact Pathname.new "#{new_folder_name.realpath}/#{entry}"
      end
    end
  end

  # Public method: checks if the given files exist via checkFiles, then calls
  # compactFile and compactFolder to process respectedly the given files and
  # folders.
  def compact( *files )
    # First off: check if the files exist.
    existing = checkFiles *files

    # Behave differently for files and folders:
    existing.each do |entry|
      # Folders:
      if entry.directory? then
        compactFolder entry

      # Files:
      else
        compactFile entry
      end
    end
  end

  # Private method, called through widen: renames a single file to a wide
  # version. This contains the main logic of renaming files in such way.
  # Returns the new name of the renamed file.
  private def widenFile( file )
    # Put the file's basename into an array, without its extension:
    file_name = file.basename( file.extname ).to_s

    # This will be the file's new name:
    new_file_name = ""

    # Read the file name character by character:
    file_name.chars.each do |c|
      # To avoid useless spaces, these rules must be respected to add a space
      # before the current character:
      # 1. c must not be a space.
      # 2. new_file_name must not be empty
      # 3. new_file_name[-1] must not be a space
      # 4. c must not be included in @ex_before
      # 5. new_file_name[-1] must not be included in @ex_after
      # 6. c and new_file_name[-1] must not both be numbers
      # 6. c must be equal to Unicode::capitalize c 
      if c != " " and false == new_file_name.empty? and
         " " != new_file_name[-1] and false == ( @ex_before.include? c ) and
         false == ( @ex_after.include? new_file_name[-1] ) and
         ( nil == ( c =~ /[0-9]/ ) or
           nil == ( new_file_name[-1] =~ /[0-9]/ )
         ) and c == Unicode.capitalize( c ) then
        new_file_name += " "
      end

      # Always add the old character:
      new_file_name += c
    end

    # Rename the new file and return its new name:
    return smartRename file, new_file_name
  end

  # Private method, called through widen: recursively renames a folder and
  # its content to a wide name.
  private def widenFolder( folder )
    # Rename the folder:
    new_folder_name = widenFile folder

    # Then rename everything it contains, recursively:
    new_folder_name.entries.each do |entry|
      # Ignore "." and "..", though.
      if "." != entry.to_s and ".." != entry.to_s then
        widen Pathname.new "#{new_folder_name.realpath}/#{entry}"
      end
    end
  end

  # Public method: checks if the given files exist via checkFiles, then calls
  # widenFile and widenFolder to process respectedly the given files and
  # folders.
  def widen( *files )
    # First off: check if the files exist.
    existing = checkFiles *files

    # Behave differently for files and folders:
    existing.each do |entry|
      # Folders:
      if entry.directory? then
        widenFolder entry

      # Files:
      else
        widenFile entry
      end
    end
  end

  # Private method, called through regexRename: renames a single file using a
  # given regex. This contains the main logic of renaming files in such way.
  # Returns the new name of the renamed file.
  private def regexRenameFile( file, regex, with )
    # Get the file's basename, without its extension:
    file_name = file.basename( file.extname ).to_s

    # Apply the regex!
    file_name.gsub! regex, "#{with}"

    # Rename the file and return its new name:
    return smartRename file, file_name
  end

  # Private method, called through regexRename: recursively renames a folder 
  # and its content using a given regex.
  private def regexRenameFolder( folder, regex, with )
    # Rename the folder:
    new_folder_name = regexRenameFile folder, regex, "#{with}"

    # Then rename everything it contains, recursively:
    new_folder_name.entries.each do |entry|
      # Ignore "." and "..", though.
      if "." != entry.to_s and ".." != entry.to_s then
        regexRename Pathname.new( "#{new_folder_name.realpath}/#{entry}" ),
                                 regex, "#{with}"
      end
    end
  end

  # Public method: checks if the given files exist via checkFiles, then calls
  # regexRenameFile and regexRenameFolder to process respectedly the given
  # files and folders.
  def regexRename( *files, regex, with )
    # First off: check if the files exist.
    existing = checkFiles *files

    # Behave differently for files and folders:
    existing.each do |entry|
      # Folders:
      if entry.directory? then
        regexRenameFolder entry, regex, "#{with}"

      # Files:
      else
        regexRenameFile entry, regex, "#{with}"
      end
    end
  end

  # Public method: checks if it's possible to create a file in the current
  # directory. If successful, then checks if the given files exist via
  # checkFiles, then creates a bash script to easily rename them.
  def createScript( *files )
    # Pointless to go any further if the current directory is not writable:
    unless Pathname.new( "." ).dirname.writable? then
      puts "You do not have the permissions to create a file in this folder."
      exit -1
    end

    # Now check if the files exist.
    existing = checkFiles *files

    # Now, gotta be sure that @script is not in the list of the files that
    # should be renamed:
    existing.delete Pathname.new @script

    existing.each_with_index do |entry, idx|
      # Only the first time: create the script.
      if 0 == idx then
        File.open @script, "w" do |f|
          # Script header:
          f.puts "#!/usr/bin/env bash"
          f.puts ""

          # Make it executable:
          f.chmod 0700
        end
      end

      # Append the line to rename the current file:
      File.open @script, "a" do |f|
        f.puts "mv \"#{entry}\" \\"
        f.puts "   \"#{entry}\""
        f.puts ""
      end

      # Only the last time: add the last touches to the script.
      if idx == existing.size - 1 then
        File.open @script, "a" do |f|
          # Self destruct line:
          f.puts "# Self-destruction line, you may not want to edit this:"
          f.puts "rm \"#{@script}\""

          # And an empty line at the end, because I'm that kind of guy.
          f.puts ""
        end
      end
    end
  end

end

###############################################################################
### Act III                                                                 ###
### Entry point for testing/standalone purposes.                            ###
###############################################################################
# Help reference function:
def help_reference()
  lines = Array.new
  name = "#{File.basename $0}"

  # Help reference lines:
  # Header:
  lines.push "\e[33mReNameR: a simple file renamer.\e[0m"
  lines.push "\e[33mUsage:\e[0m"
  # Compact mode:
  lines.push "\e[34m#{name} <files>\e[0m: recursively renames the given " +
             "files and folders to a CamelCase format."
  # Widen mode:
  lines.push "\e[34m#{name} -w/--widen <files>\e[0m: recursively renames " +
             "the given files and folders adding spaces when needed."
  # Regex mode:
  lines.push "\e[34m#{name} -r/--regex <regex> <substitute> <files>\e[0m: " +
             "recursively renames the given files and folders replacing " +
             "any match of the given regex with the given substitute."
  # Renaming script mode:
  lines.push "\e[34m#{name} -s/--script <files>\e[0m: creates a bash script " +
             "to quickly rename the given files and folders, for whenever " +
             "the other modalities cannot yield the desired result."
  # Help switch:
  lines.push "\e[34m#{name} -h\e[0m: shows this help reference."
  # Footer:
  lines.push ""
  lines.push "\e[33mNOTE\e[0m: if no files are specified to a command, it " +
             "will process every file in the current folder."
  lines.push ""
  lines.push "See the configuration file located in \e[34m" +
             "#{ENV['HOME']}/.rnr\e[0m to add your personal tweaks."

  # Max 80 characters per line, but preserving words integrity! :3
  lines.each do |entry|
    # 80 characters line container:
    composed = ""

    # Split each message string on spaces:
    entry.split( " " ).each do |word|
      # If the current composed message plus the current word exceeds 80 is
      # within 80 characters, keep composing:
      if 80 >= "#{composed + " " + word}".length then
        # Add a space when needed:
        unless composed.empty? then
          composed += " "
        end
        composed += "#{word}"

      # If the current word would not fit in an 80 characters line, print the
      # current composed message, and start composing the next one with an
      # indentation of 2 spaces.
      else
        puts composed
        composed = "  #{word}"
      end
    end

    # Finally, print the last line:
    puts composed
  end
end

# Here it is! The main protagonist! The Renamer object!
rnr = Renamer.new

# Help reference:
if [ "-h", "--help" ].include? ARGV[0] and 1 == ARGV.size then
  help_reference
  exit 0

# Renaming script:
elsif [ "-s", "--script" ].include? ARGV[0] then
  tmp = Array.new ARGV
  tmp.shift
  tmp.uniq!

  # No other parameters: run this for every file in the current directory 
  # (except . and ..):
  if tmp.empty? then
    tmp = Dir.entries "."

    # Always remove "." and "..".
    tmp.delete "."
    tmp.delete ".."

    # This script is sort of harmless, so there is not going to be a check
    # for user consent.
  end

  rnr.createScript *tmp

# Regex:
elsif [ "-r", "--regex" ].include? ARGV[0] then
  tmp = Array.new ARGV
  tmp.shift
  regex = Regexp.new "#{tmp.shift}"
  substitute_with = "#{tmp.shift}".gsub! "\\", "\\\\"
  tmp.uniq!

  # 3 Parameters: everything in the current folder.
  if 3 == ARGV.size then
    tmp = Dir.entries "."

    # Always remove "." and "..".
    tmp.delete "."
    tmp.delete ".."
    
    # This could be quite dangerous if erroneously invoked (eg. in the user's
    # home directory). Better use a confirmation prompt:
    print "Do you really want to rename every file and folder in the " +
          "current directory (#{Dir.pwd})? [y/N] "
    answer = STDIN.gets.chomp

    # Abort from anything different than y/Y:
    unless "Y" == Unicode::capitalize( answer ) then
      puts "Operation aborted."
      exit 0
    end

  # User is a moron.
  elsif 3 > ARGV.size then
    puts "Must specify at one regex and one substitute for this modality."
    exit -1
  end

  rnr.regexRename *tmp, regex, substitute_with

# Widen: 
elsif [ "-w", "--widen" ].include? ARGV[0] then
  tmp = Array.new ARGV
  tmp.shift
  tmp.uniq!

  # No other parameters: run this for every file in the current directory 
  # (except . and ..):
  if tmp.empty? then
    tmp = Dir.entries "."

    # Always remove "." and "..".
    tmp.delete "."
    tmp.delete ".."
    
    # This could be quite dangerous if erroneously invoked (eg. in the user's
    # home directory). Better use a confirmation prompt:
    print "Do you really want to rename every file and folder in the " +
          "current directory (#{Dir.pwd})? [y/N] "
    answer = STDIN.gets.chomp

    # # Abort from anything different than y/Y:
    unless "Y" == Unicode::capitalize( answer ) then
      puts "Operation aborted."
      exit 0
    end
  end

  rnr.widen *tmp

# Compact:
else
  tmp = Array.new ARGV
  tmp.uniq!

  # No other parameters: run this for every file in the current directory
  # (except . and ..):
  if tmp.empty? then
    tmp = Dir.entries "."

    # Always remove "." and "..".
    tmp.delete "."
    tmp.delete ".."

    # This could be quite dangerous if erroneously invoked (eg. in the user's
    # home directory). Better use a confirmation prompt:
    print "Do you really want to rename every file and folder in the " +
          "current directory (#{Dir.pwd})? [y/N] "
    answer = STDIN.gets.chomp

    # Abort from anything different than y/Y:
    unless "Y" == Unicode::capitalize( answer ) then
      puts "Operation aborted."
      exit 0
    end
  end

  rnr.compact *tmp
end

