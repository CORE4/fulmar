require 'fulmar/version'

require 'fulmar/service/bootstrap_service'
require 'fulmar/service/helper_service'
require 'fulmar/service/logger_service'

require 'fulmar/domain/service/initialization_service'
require 'fulmar/domain/service/application_service'
require 'fulmar/domain/service/configuration_service'
require 'fulmar/domain/service/config_rendering_service'

require 'fulmar/service/common_helper_service'
require 'fulmar/domain/service/file_sync_service'

require 'fulmar/infrastructure/service/composer_service'
require 'fulmar/infrastructure/service/shell_service'
require 'fulmar/infrastructure/service/git_service'

require 'fulmar/infrastructure/service/database/database_service'

require 'ruby_wings'

bootstrap = Fulmar::Service::BootstrapService.new
bootstrap.fly
