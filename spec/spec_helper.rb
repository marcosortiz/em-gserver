require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'em/gserver'
require 'easy_sockets'

TEST_LOGS_PATH = "test_logs"

def clean_logs
    FileUtils.rm_rf TEST_LOGS_PATH if File.exist? TEST_LOGS_PATH
end

def check_log_dir
    FileUtils.mkdir TEST_LOGS_PATH unless File.exist? TEST_LOGS_PATH
end

RSpec.configure do |config|
    config.before(:all) do
        clean_logs
        check_log_dir
    end
end