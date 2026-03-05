Gem::Specification.new do |s|
  s.name        = 'hexdump'
  s.version     = '0.1.0'
  s.summary     = 'Self-hosted error tracking + logging with local AI'
  s.description = 'Captures Rails exceptions, Sidekiq errors, and structured logs. Ships to your self-hosted Hexdump server for AI-powered grouping and analysis.'
  s.authors     = ['Bytecode']
  s.email       = 'hello@bytecode.hr'
  s.homepage    = 'https://github.com/bytecodehr/hexdump'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 3.0'

  s.files = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.require_paths = ['lib']

  # Zero runtime dependencies — only stdlib net/http + json
end
