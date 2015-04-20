module Fulmar
  module Domain
    module Service
      module Helper
        # Provides access helper to the database service from within a task
        module VhostHelper
          def vhost_name
            branch = git.current_branch
            match = branch.match(/f\d+_([a-zA-Z0-9]+)/)
            if match
              match[1]
            else
              error "Cannot deploy branch '#{branch}'"
              fail 'Branch must match specification for feature branches (f1234_name)'
            end
          end
        end
      end
    end
  end
end
