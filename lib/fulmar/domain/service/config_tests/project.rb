global_test 'project name is set' do |config|
  if config.project.name.blank?
    next {
      severity: :warning,
      message: 'Project name is not set (must be short, no spaces)'
    }
  end
end
