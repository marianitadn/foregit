require 'fileutils'
require 'json'

require 'foregit'

module Foregit

  class FileManager
    attr_reader :repo_path

    def initialize(settings)
      @settings = settings
      @repo_path = settings[:repo_path] or raise ArgumentError, 'No path for the repository was given!'
    end

    def find_file(file)
      relative_path = File.expand_path(file)
      if file.start_with? @repo_path and can_read_file? file
        return file
      elsif File.fnmatch?(@repo_path + '*', relative_path) and can_read_file? relative_path
        return relative_path
      end
      path = File.join(@repo_path, file)
      if can_read_file? path
        return path
      else
        return nil
      end
    end

    def dump_object_as_file(resource, file=nil)
      if file.nil?
        # If we don't have a file, it means it's a new configuration and a new
        # file has to be created beforehand.
        dir_path = ensure_directory(resource[:type])
        file_path = ensure_file(dir_path, resource[:name])
      else
        file_path = find_file(file)
      end

      File.open(file_path, 'w') do |file|
        content = remove_extra_content(resource[:content])
        file.write(JSON.pretty_generate(content))
      end

      return file_path
    end


    def get_repo_directories
      Dir.entries(@repo_path).reject! {|dir| dir.start_with? '.'}
    end

    def get_dir_json_files(dir)
      Dir.entries(File.join(@repo_path, dir)).reject! {|file| !file.end_with? '.json' or file.start_with? '.'}
    end

    def load_file_as_json(file)
      # Get file content.
      file_path = find_file(file)

      file_content = File.open(file_path, 'r').read
      return JSON.load(remove_extra_content(file_content))
    end

    def ensure_directory(directory)
      dir_path = File.join(@repo_path, directory)
      FileUtils.mkdir(dir_path) unless Dir.exists?(dir_path)
      return dir_path
    end

    def ensure_file(directory, file, extension='.json')
      file_path = File.join(directory, file + extension)
      FileUtils.touch(file_path) unless File.exists?(file_path)
      return file_path
    end

    def can_read_directory(directory)
      Dir.exists?(directory)
    end

    def can_read_file?(file)
      File.exists?(file) && File.readable?(file)
    end

    def remove_extra_content(content)
      # Remove fields which should be ignored, most of them are set when the
      # element is updated in the Foreman instance.
      @settings[:ignored_foreman_fields].each do |field|
        content.delete(field)
      end
      return content
    end
  end
end
