# frozen_string_literal: true

module Orangetheses
  class Railtie < Rails::Railtie
    rake_tasks do
      load 'tasks/orangetheses.rake'
    end
  end
end
