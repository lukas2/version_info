Gem::Specification.new do |s|
  s.name        = "version_info"
  s.version     = "1.0"
  s.platform    = Gem::Platform::RUBY
  s.author      = "Lukas Zielinski"
  s.email       = "lukas.zielinski@gmail.com"
  s.summary     = "Git Version Viewing Helper"
  s.description = "Can be used to display version info to users, e.g. the log-entries for
                   the most recent git-commits. Stores the commits in a file, so the data
                   is also available when the application is deployed with capistrano and
                   no .git-history is available in the location deployed to."
  s.files       = [ "lib/version_info.rb", "version_info.gemspec", "README.md" ]
end
