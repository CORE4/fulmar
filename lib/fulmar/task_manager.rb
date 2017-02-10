require 'fulmar/version'

require 'fulmar/service/bootstrap_service'
require 'fulmar/service/helper_service'

require 'fulmar/domain/service/initialization_service'
require 'fulmar/domain/service/application_service'
require 'fulmar/domain/service/configuration_service'
require 'fulmar/domain/service/template_rendering_service'
require 'fulmar/domain/service/file_sync_service'

require 'fulmar/infrastructure/service/copy_service'
require 'fulmar/infrastructure/service/ssh_config_service'

require 'fileutils'

bootstrap = Fulmar::Service::BootstrapService.new
bootstrap.fly
