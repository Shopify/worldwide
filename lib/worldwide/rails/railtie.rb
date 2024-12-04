# frozen_string_literal: true

require "rails/railtie"

module Worldwide
  module Rails
    class Railtie < ::Rails::Railtie
      SETUP = "worldwide.setup"

      initializer SETUP do |application|
        application.config.eager_load_namespaces << Worldwide

        Worldwide::Config.configure_i18n(i18n_config: application.config.i18n)
      end
    end
  end
end
