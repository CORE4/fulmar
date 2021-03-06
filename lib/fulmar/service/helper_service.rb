module Fulmar
  module Service
    # Provides internal helper methods
    class HelperService
      class << self
        ##
        # Reverse file lookup in path
        # @param path [String]
        # @param filename [String]
        def reverse_file_lookup(path, filename)
          paths = get_parent_directory_paths(path)

          paths.each do |directory|
            file_path = directory + '/' + filename
            return file_path if File.exist? file_path
          end

          false
        end

        private

        ##
        # Get paths of each parent directory
        # @param path [String]
        # @param paths [Array]
        # @return [Array] A list of paths
        def get_parent_directory_paths(path, paths = [])
          paths << path

          parent_dir_path = File.expand_path('..', path)

          parent_dir_path == '/' || parent_dir_path.include?(':/') ? paths : get_parent_directory_paths(parent_dir_path, paths)
        end
      end
    end
  end
end
