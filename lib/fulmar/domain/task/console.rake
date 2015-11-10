desc 'Open an interactive terminal within fulmar'
task :console, [:environment] do |_t, args|
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  if args[:environment] && args[:environment].include?(':')
    environment, target = args[:environment].split(':')
    configuration.environment = environment
    configuration.target = target
  end
  IRB.start
end
