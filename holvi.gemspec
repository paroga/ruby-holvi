Gem::Specification.new do |s|
  s.name        = 'holvi'
  s.version     = '0.0.1'
  s.date        = '2018-05-20'
  s.summary     = 'Holvi Scrapper'
  s.description = 'A gem to interact with holvi.com'
  s.authors     = ['Patrick Gansterer']
  s.email       = 'paroga@paroga.com'
  s.files       = ['lib/holvi.rb']
  s.homepage    =
    'https://github.com/paroga/ruby-holvi'
  s.license       = 'MIT'

  s.add_dependency 'mechanize'
end
