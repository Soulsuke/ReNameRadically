require 'minitest/autorun'
require 'rename_radically'



class RNRTest < Minitest::Test

  def test_compact
    original = 'qualcosa è cambiato?!= Parte iv "'
    normalized_ok = 'QualcosaÈCambiato?!=ParteIV"'
    normalized = ReNameRadically.new.tester modality: :compact, text: original

    unless normalized_ok == normalized then
      raise "Expected ___#{normalized_ok}___ got ___#{normalized}___"
    end
  end



  def test_widen
    original = 'IlBelloÈAdessoVII123'
    normalized_ok = 'Il Bello È Adesso VII 123'
    normalized = ReNameRadically.new.tester modality: :widen, text: original

    unless normalized_ok == normalized then
      raise "Expected ___#{normalized_ok}___ got ___#{normalized}___"
    end
  end



  def test_regex
    original = 'Venerdì 13 parte XIV'
    normalized_ok = 'Sabato: 13 parte XIV'
    normalized = ReNameRadically.new.tester modality: :regex, text: original,
      r_pattern: 'Venerdì', r_sub: 'Sabato:'

    unless normalized_ok == normalized then
      raise "Expected ___#{normalized_ok}___ got ___#{normalized}___"
    end
  end

end

