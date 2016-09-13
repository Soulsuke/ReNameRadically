require 'minitest/autorun'
require "pathname"
require 'rename_radically'

class RNRTest < Minitest::Test

  def test_compact
    rnr = ReNameRadically.new "/tmp/ReNameRadically_tmp_config"
    file = "/tmp/Re Name Radically TEST 123.mp3"

    File.open file, "w"

    rnr.compact file

    if Pathname.new( "/tmp/ReNameRadicallyTest123.mp3" ).exist? then
      File.delete "/tmp/ReNameRadicallyTest123.mp3"
      File.delete "/tmp/ReNameRadically_tmp_config"

    else
      raise "Compact failed."
    end
  end

  def test_widen
    rnr = ReNameRadically.new "/tmp/ReNameRadically_tmp_config"
    file = "/tmp/ReNameRadicallyTest123.mp3"
    
    File.open file, "w"

    rnr.widen file

    if Pathname.new( "/tmp/Re Name Radically Test 123.mp3" ).exist? then
      File.delete "/tmp/Re Name Radically Test 123.mp3"
      File.delete "/tmp/ReNameRadically_tmp_config"

    else
      raise "Widen failed."
    end
  end

  def test_regex
    rnr = ReNameRadically.new "/tmp/ReNameRadically_tmp_config"
    file = "/tmp/ReNameRadicallyTest[123].mp3"
    
    File.open file, "w"

    rnr.regexRename file, "\[123\]", ""

    if Pathname.new( "/tmp/ReNameRadicallyTest.mp3" ).exist? then
      File.delete "/tmp/ReNameRadicallyTest.mp3"
      File.delete "/tmp/ReNameRadically_tmp_config"

    else
      raise "Regex failed."
    end
  end

  def test_script
    rnr = ReNameRadically.new "/tmp/ReNameRadically_tmp_config"

    Dir.chdir "/tmp"

    rnr.createScript *(Dir.entries ".")

    if Pathname.new( "/tmp/REN.bash" ).exist? then
      File.delete "/tmp/REN.bash"
      File.delete "/tmp/ReNameRadically_tmp_config"

    else
      raise "Script failed."
    end
  end

end

