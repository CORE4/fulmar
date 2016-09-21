test 'project name is set' do |config|
  next :warning, 'Project name is not set (must be short, no spaces)' if config.project.name.blank?
end
