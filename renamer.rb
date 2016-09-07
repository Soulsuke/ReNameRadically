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
req_gems = [ "json", "pathname", "unicode" ]
gems_missing = false

req_gems.each do |i|
  begin
    require i
  rescue LoadError
    unless gems_missing then
      gems_missing = true
      puts "You lack the following gems:"
    end
    puts " > #{i}"
  end
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

  # Default constructor: it ensures there's a valid config file in the
  # user's home directory.
  def initialize
    @config = "#{ENV['HOME']}/.rnr"

    # Attempt to read from the config file:
    begin
      @as_spaces = JSON.parse( File.read @config )["treated_as_spaces"]
      @delimiters = JSON.parse( File.read @config )["word_delimiters"]
      @ex_after = JSON.parse( File.read @config )["wide_no_space_after"]
      @ex_before = JSON.parse( File.read @config )["wide_no_space_before"]

      # Fastest way to check for data consistency:
      @as_spaces[0]
      @delimiters[0]
      @ex_after[0]
      @ex_before[0]

    # If it fails, create a new default config file:
    rescue
      config = {
                 "treated_as_spaces": [
                   "_"
                 ],
                 "word_delimiters": [
                   "-", "+", "(", ")", "'", "&", "."
                 ],
                 "wide_no_space_after": [
                  "'", "(", "-", "<", "[", "{", "-"
                 ],
                 "wide_no_space_before": [
                   ".", ",", "?", "!", "'", ")", "}", "]", ">", "-"
                 ]
               }

      # Attempt to create the file:
      begin 
        File.open @config, "w" do |f|
          f.puts JSON.pretty_generate config
        end

        puts "Created a new config file: #{@config}"

        # Then load the data (if something fails now, something's really
        # going on on this system):
        @as_spaces = JSON.parse( File.read @config )["treated_as_spaces"]
        @delimiters = JSON.parse( File.read @config )["word_delimiters"]
        @ex_after = JSON.parse( File.read @config )["wide_no_space_after"]
        @ex_before = JSON.parse( File.read @config )["wide_no_space_before"]

      # Something went horribly wrong: maybe there's no home folder, or its
      # permissions are all wrong... So, screw the config file and use default
      # values for this ride.
      rescue
        puts "WARNING: could not read/write file #{@config}, you might want" +
             " to check out why."

        @as_spaces = [ "_" ]
        @delimiters = [ "-", "+", "(", ")", "'", "&", "." ]
        @ex_after = [ "'", "(", "-", "<", "[", "{", "-" ]
        @ex_before = [ ".", ",", "?", "!", "'", ")", "}", "]", ">", "-" ]
      end
    end
  end

  # Private method: checks if the given files exist, then prints a list of the
  # not found ones and returns an array containing the Pathname objects of the
  # found ones.
  private def checkFiles( *files )
    # This will contain the not found files:
    failed = Array.new

    # This will contain the valid files:
    ok = Array.new

    # Now, check each file:
    files.each do |entry|
      tmp = Pathname.new( entry )

      if tmp.exist? and "." != tmp.to_s and ".." != tmp.to_s then
        ok.push tmp

      # This happens if the file has not been found:
      else
        failed.push entry
      end
    end

    # Print a list of the invalid files:
    failed.each_with_index do |entry, idx|
      if 0 == idx then
        puts "The following files will be ignored (not found or invalid):"
      end

      puts "- #{entry}"
    end

    # Return the arraid containing the valid ones:
    return ok
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
    
    # Rename the file:
    file.rename "#{file.dirname}/#{file_name.join}#{file.extname}"

    # Return the new file:
    return Pathname.new "#{file.dirname}/#{file_name.join}#{file.extname}"
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
  # compactFile and compactFolder to process resectedly the given files and
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

    # Complete new name:
    new_file_name = "#{file.dirname}/#{new_file_name}#{file.extname}"

    # Rename the file:
    file.rename new_file_name

    # Return the new file:
    return Pathname.new new_file_name
  end

  # Private method, called through widen: recursively renames a folder and
  # its content to a wide.
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
  # widenFile and widenFolder to process resectedly the given files and
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

end

###############################################################################
### Act III                                                                 ###
### Entry point for testing/standalone purposes.                            ###
###############################################################################
# Help reference function:
def help_reference()
  lines = Array.new

  # Help reference lines:
  lines.push "ReNameR: a simple file renamer."
  lines.push "Usage:"  
  lines.push "#{$0}                                  : recursively renames " +
             "every file and and folder in the current directory to a " +
             "CamelCase format."
  lines.push "#{$0} <file 1> ... <file n>            : recursively renames " +
             "the given files and folders to a CamelCase format."
  lines.push "#{$0} -w                               : recursively renames " +
             "every file and and folder in the current directory adding " +
             "spaces when needed."
  lines.push "#{$0} -w/--widen <file 1> ... <file n> : recursively renames " +
             "the given files and folders adding spaces when needed."
  lines.push "#{$0} -h                               : shows this help " +
             "reference."
  lines.push "\nSee the configuration file located in #{ENV['HOME']}/.rnr " +
             "to add your personal tweaks."

  # Max 80 characters per line! :3
  lines.each do |entry|
    puts entry
  end
end

rnr = Renamer.new

# Help reference check:
if [ "-h", "--help" ].include? ARGV[0] and 1 == ARGV.size then
  help_reference
  exit 0

# Reverse compact: 
elsif [ "-w", "--widen" ].include? ARGV[0] then
  tmp = Array.new ARGV
  tmp.uniq!
  tmp.shift

  # No other parameters: run this for every file in the current directory 
  # (except . and ..):
  if tmp.empty? then
    tmp = Dir.entries "."
    tmp.delete "."
    tmp.delete ".."
    rnr.widen *tmp

  # Else, do it just for the selected files:
  else
    rnr.widen *tmp
  end

# Compact:
else
  tmp = Array.new ARGV
  tmp.uniq!

  # No other parameters: run this for every file in the current directory
  # (except . and ..):
  if tmp.empty? then
    tmp = Dir.entries "."
    tmp.delete "."
    tmp.delete ".."
    rnr.compact *tmp

  # Else, do it just for the selected files:
  else
    rnr.compact *tmp
  end
end

