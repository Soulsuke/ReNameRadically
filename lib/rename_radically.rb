require 'pathname'



=begin
This is the ReNameRadically class.

It's supposed to help renaming files in different ways:
compact:: renames a file to a CamelCase format, removing spaces and using
          capital letters to separate words. Other capital letters areconverted
          to lower case.
widen:: renames a file adding spaces to separate words in CamelCase format,
        and, depending on the case, before or after punctation.
regex:: replaces all occurrences of the given regex with the given 
        substitute string.
renaming script:: creates a bash script to rename files, for whenever the
                  other modalities cannot yield the desired result.
=end
class ReNameRadically

  #############################################################################
  ### Attributes                                                            ###
  #############################################################################

  # Dry run flag.
  attr_reader :dry_run

  # Array of characters to be treated as spaces
  attr_reader :as_spaces

  # Array of characters to used as word delimiters
  attr_reader :delimiters

  # Array of exceptions not to put a space after in widen mode.
  attr_reader :ex_after

  # Array of exceptions not to put a space before in widen mode.
  attr_reader :ex_before

  # Script name for script renaming mode.
  attr_reader :script



  #############################################################################
  ### Public instance methods                                               ###
  #############################################################################

  # Constructor.
  # Takes as parameters the config file path and the dry run flag.
  # Creates the config file if needed.
  def initialize( dry_run: false,
                  as_spaces: %w[ _ ],
                  delimiters: %w[ - + ( ) [ ] { } ' & . ! ? ],
                  ex_after: %w[ ' ( - < \[ { . ],
                  ex_before: %w[ . , ? ! ' ) \] } > - _ ],
                  script: 'REN.sh'
                )
    @dry_run = dry_run
    @as_spaces = as_spaces
    @delimiters = delimiters
    @ex_after = ex_after
    @ex_before = ex_before
    @script = script
   
    # Ensure any invalid values are not used:
    @as_spaces = Array.new unless @as_spaces.is_a? Array
    @delimiters = Array.new unless @delimiters.is_a? Array
    @ex_after = Array.new unless @ex_after.is_a? Array
    @ex_before = Array.new unless @ex_before.is_a? Array
    @script = 'REN.sh' if [ '', '.', '..' ].include? @script.to_s
  end



  # Simple tester function for strings.
  def tester( text:, modality:, r_pattern: '', r_sub: '' )
    # Turn this into a pathname:
    text = Pathname.new text

    return modality_regex text, r_pattern, r_sub if modality == :regex
    return send( "modality_#{modality}", text ) unless modality == :regex
  end



  # Recursively renames the given files using the given modality.
  # Returns a hash of not found or unchangeable files.
  def rename( files:, modality:, check_files: true, r_pattern: '', r_sub: '' )
    # Data to return:
    ret = Hash.new

    # If this is true then some extra steps have to be taken:
    if check_files then
      ret = check_files files
      files = ret.delete :ok
    end

    # Then check each of them
    files.each do |file|
      # Special case for regex pattern:
      if modality == :regex then
        file = perform_rename file: file,
          name: modality_regex( file, r_pattern, r_sub )

      # Rename the file using the right method:
      else
        file = perform_rename file: file,
          name: send( "modality_#{modality}", file )
      end

      # If we just renamed a folder, rename everything within it as well:
      rename files: file.children,
        modality: modality,
        check_files: false,
        r_pattern: r_pattern,
        r_sub: r_sub \
        if file.directory?
    end

    # Return what files gave an error:
    return ret
  end



  # Creates a bash script to rename files.
  # Returns nil if the file cannot be created in the current folder.
  # Otherwise returns a hash of not found or unchangeable files.
  def create_renaming_script( files )
    # Check for permissions first:
    return nil unless Pathname.new( '.' ).dirname.writable?

    # Sanitize files first:
    files = check_files files

    # Write the file:
    File.open @script, 'w' do |f|
      # Write the header and make it executable:
      f.puts "#! /usr/bin/env bash\n\n"
      f.chmod 0700

      # Write in each file:
      files.delete( :ok ).map do |file|
        f.puts "mv '#{file}' \\\n   '#{file}'\n\n"
      end

      # As a last thing add in the self-destruction line:
      f.puts "# Self-destruction line, you may not want to edit this:\n" \
        "rm '#{@script}'\n\n"
    end

    # Return what files gave an error:
    return files
  end



  #############################################################################
  ### Private instance methods                                              ###
  #############################################################################

  private

  # Renames a file, taking @dry_run into account.
  # Takes as parameters a Pathname and a new name.
  # The original file's extension is preserved.
  # If a file with the new name already exists, appends a number to it.
  # Returns the new file's pathname.
  def perform_rename( file:, name:, counter: nil )
    # Remove unwanted characters:
    name.gsub!( /(\/|\0)/, "" )

    # Add an underscore to the counter:
    counter = "_#{counter}" unless counter.nil?

    # Also the single file name is 255 characters, including the extension:
    name = name[ 0..(255 - file.extname.length - counter.to_s.length) ]

    # Compose the final name:
    destination = Pathname.new "#{file.dirname}/" \
      "#{name}#{counter}#{file.extname}"

    # Only rename the file if:
    #  - the new name isn't '.' or '..'
    #  - the name isn't empty
    #  - the new name is different than the old one
    if !name.match( /^\.{1,2}$/ ) and
       !name.empty? and
       file.basename != destination.basename
    then
      # If the destination already exist try again incrementing the counter:
      if destination.exist? then
        destination = perform_rename file: file,
          name: name,
          counter: (counter.to_s[ 1.. ].to_i + 1)

      # If it's a dry run, simply print a log:
      elsif @dry_run then
        puts "DRY RUN: #{file} => #{destination}"
        destination = file

      # Otherwise, rename:
      else
        file.rename destination
      end
    end

    # Always return the destination:
    return destination
  end



  # Checks if the given file names exist, prints a list of those not existing
  # and without write permissions, then returns an array of pathnames of the
  # rest.
  public
  def check_files( files )
    # Containers:
    not_found = Array.new
    no_permissions = Array.new
    ok = Array.new

    # Check each file:
    files.uniq.sort_by { |e| e.to_s.downcase }.each do |file|
      # Turn it into a pathname:
      file = Pathname.new file.to_s

      # Ignore these:
      next if file.basename.to_s.match( /^\.{1,2}$/ )

      # Check where it belongs:
      if !file.exist? then
        not_found << file
      elsif !file.writable? or !file.dirname.writable? then
        no_permissions << file
      else
        ok << file
      end
    end

    # Return only the valid files:
    return { ok: ok, not_found: not_found, no_permissions: no_permissions }
  end



  ### Renaming modalities
  #############################################################################

  # Generates a compacted file name for the given pathname.
  def modality_compact( file )
    # Take in the original file's name:
    name = file.basename( file.extname ).to_s
      # Turn these into spaces:
      .gsub( /(#{@as_spaces.map { |a| Regexp.escape a }.join '|'})/, ' ' )
      # Add spaces after these:
      .gsub( /(#{@delimiters.map { |a| Regexp.escape a }.join '|'})/, '\1 ' )
      # Split it on spaces:
      .split ' '

    # Do the capitalization:
    name.each_with_index do |word, idx|
      # Ignore roman numbers:
      name[ idx ] = word.capitalize unless word.match( /^[IVXLCDM]+$/ )
      name[ idx ] = word.upcase if word.match( /^[ivxlcdm]+$/ )
    end

    # Return the joined name:
    return name.join
  end



  # Generates a widened file name for the given pathname.
  def modality_widen( file )
    # This starts off empty:
    name = ''

    # Let's parse each character:
    file.basename( file.extname ).to_s.chars.each do |c|
      # To avoid extra spaces we have to follow these rules:
      #  1. c must not be a space
      #  2. name must not be empty
      #  3. name[ -1 ] must not be a space
      #  4. c must not be included in @ex_before
      #  5. name[-1] must not be included in @ex_after
      #  6. c and name[-1] must not both be numbers
      #  7. c must be equal to c.upcase
      #  8. c and name[ -1 ] must not be roman numbers
      if c != ' ' and
         !name.empty? and
         name[ -1 ] != ' ' and
         !@ex_before.include? c and
         !@ex_after.include? name[ 1 ] and
         !( c.match( /[0-9]/ ) and name[ -1 ].match( /[0-9]/ ) ) and
         c == c.upcase and
         !( c.match( /[IVXLCDM]/ ) and name[ -1 ].match( /[IVXLCDM]/ ) )
      then
        name += ' '
      end

      # Always add in the character:
      name += c
    end

    # Return the composed name:
    return name
  end



  # Generates a new file name for the given pathname using the given regex
  # pattern and sub value.
  def modality_regex( file, pattern, sub )
    return file.basename( file.extname ).to_s.gsub( /#{pattern}/, sub.to_s )
  end

end

