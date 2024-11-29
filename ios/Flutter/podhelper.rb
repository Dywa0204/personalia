# flutter/tools/podhelper.rb
require 'fileutils'
require 'json'

def parse_KV_file(file, separator='=')
  file_abs_path = File.expand_path(file)
  return {} unless File.exist? file_abs_path
  File.read(file_abs_path).split("\n").map { |line|
    line.split(separator, 2)
  }.reduce({}) { |map, ary|
    map[ary[0]] = ary[1]
    map
  }
end

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter build ios is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter build ios"
end

# Install pods needed to embed Flutter application, relative to this file.
def install_flutter_engine_pod(pod_name, flutter_application_path)
  engine_dir = File.expand_path(File.join(flutter_application_path, '.ios', 'Flutter'))
  raise "#{engine_dir} must exist. Make sure to run `flutter build ios` first" unless File.exist?(engine_dir)

  FileUtils.mkdir_p(engine_dir)

  pod pod_name, :path => File.join(flutter_application_path, '.ios', 'Flutter', 'engine')
end
