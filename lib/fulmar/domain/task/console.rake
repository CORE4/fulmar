desc 'Open an interactive terminal within fulmar'
task :console do
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  IRB.start
end
