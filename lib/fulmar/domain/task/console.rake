desc 'Open an interactive terminal within fulmar'
task :console, [:environment] do |_t, args|
  require 'irb'
  require 'irb/completion'
  ARGV.clear
  if args[:environment] && args[:environment].include?(':')
    environment, target = args[:environment].split(':')
    configuration.environment = environment.to_sym
    configuration.target = target.to_sym
  end
  IRB.start
end
