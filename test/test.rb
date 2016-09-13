require 'minitest/autorun'
require "pathname"
require 'renamer'

class ReNameRTest < Minitest::Test

  def test_compact
    rnr = ReNameR.new "/tmp/ReNamer_tmp_config"
    file = "/tmp/ReNameR TEST 123.mp3"

    File.open file, "w"

    rnr.compact file

    if Pathname.new( "/tmp/RenamerTest123.mp3" ).exist? then
      File.delete "/tmp/RenamerTest123.mp3"
      File.delete "/tmp/ReNamer_tmp_config"

    else
      raise "Compact failed."
    end
  end

  def test_widen
    rnr = ReNameR.new "/tmp/ReNamer_tmp_config"
    file = "/tmp/RenamerTest123.mp3"
    
    File.open file, "w"

    rnr.widen file

    if Pathname.new( "/tmp/Renamer Test 123.mp3" ).exist? then
      File.delete "/tmp/Renamer Test 123.mp3"
      File.delete "/tmp/ReNamer_tmp_config"

    else
      raise "Widen failed."
    end
  end

  def test_regex
    rnr = ReNameR.new "/tmp/ReNamer_tmp_config"
    file = "/tmp/ReNameRTest[123].mp3"
    
    File.open file, "w"

    rnr.regexRename file, "\[123\]", ""

    if Pathname.new( "/tmp/ReNameRTest.mp3" ).exist? then
      File.delete "/tmp/ReNameRTest.mp3"
      File.delete "/tmp/ReNamer_tmp_config"

    else
      raise "Regex failed."
    end
  end

  def test_script
    rnr = ReNameR.new "/tmp/ReNamer_tmp_config"

    Dir.chdir "/tmp"

    rnr.createScript *(Dir.entries ".")

    if Pathname.new( "/tmp/REN.bash" ).exist? then
      File.delete "/tmp/REN.bash"
      File.delete "/tmp/ReNamer_tmp_config"

    else
      raise "Script failed."
    end
  end

end

