Gem::Specification.new do |s|
  s.name        = 'rename_radically'
  s.version     = '0.2.0'
  s.date        = '2016-10-27'
  s.summary     = 'ReNameRadically'
  s.description = 'A simple (and probably dirty) files mass-renamer.'
  s.homepage    = 'https://github.com/Soulsuke/ReNameR'
  s.license     = 'GPL-3.0'
  s.authors     = [ 'Maurizio Oliveri' ]
  s.email       = [ '6tsukiyami9@gmail.com' ]
  s.files       = [ 'lib/rename_radically.rb', 'bin/rnr' ]
  s.executables = [ 'rnr' ]
  s.add_runtime_dependency 'unicode', '~> 0.4', '>= 0.4.4.2'
end

