# frozen_string_literal: true

# Define and require global methods and variables
require 'logger'

def logger
  @logger ||= Logger.new($stdout)
end

def test?
  ENV['ORANGETHESES_ENV'] == 'test'
end

def development?
  return true unless ENV.key?('ORANGETHESES_ENV')

  ENV['ORANGETHESES_ENV'] == 'development'
end

def lando_env_path
  File.expand_path(
    File.join(
      File.dirname(__FILE__), 'config', 'lando_env'
    )
  )
end

# Set up a development environment unless we are within a Rails application, which presumably
# has its own development environment
require lando_env_path unless defined? Rails
