require 'yaml'
require 'erb'
require 'resque'

Thread.abort_on_exception = true
Resque.redis = 'redis:6379'

ROOT = File.dirname(__FILE__) + '/../../../'
$redis = Redis.new(host: "redis")

APP_CONFIG = YAML.load(ERB.new(File.read(File.join(ROOT, "config", "application.yml"))).result)
APP_CONFIG['output_folder'] = ROOT + 'output'
Dir.mkdir(APP_CONFIG['output_folder']) if !Dir.exists?(APP_CONFIG['output_folder'])
