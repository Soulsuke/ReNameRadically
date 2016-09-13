Gem::Specification.new do |s|
  s.name        = 'renamer'
  s.version     = '0.0.1'
  s.date        = '2016-09-13'
  s.summary     = 'ReNameR'
  s.description = 'A simple (and probably dirty) files mass-renamer.'
  s.homepage    = 'https://github.com/Soulsuke/ReNameR'
  s.license     = 'GPL-3.0'
  s.authors     = [ 'Maurizio Oliveri' ]
  s.email       = [ '6tsukiyami9@gmail.com' ]
  s.files       = [ 'lib/renamer.rb', 'bin/rnr' ]
  s.executables = [ 'rnr' ]
  s.add_runtime_dependency 'unicode', '~> 0.4', '>= 0.4.4.2'
end

