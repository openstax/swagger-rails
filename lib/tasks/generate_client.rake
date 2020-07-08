require 'open-uri'
require 'fileutils'
require 'active_support/core_ext/string/strip'
require_relative '../openstax/swagger/swagger_codegen'
require_relative '../openstax/swagger/bundle_js_client'

namespace :openstax_swagger do
  desc <<-DESC.strip_heredoc
    Generate an API client in the clients directory.  swagger-codegen
    must be installed.  Run like `rake openstax_swagger:generate_client[0,ruby]` for the
    version 0 Ruby API client.
  DESC
  task :generate_client, [:api_major_version, :language] => :environment do |tt,args|
    api_major_version = args[:api_major_version] || '1'
    language = args[:language].to_sym
    raise "Must specify a language, e.g. ruby" if language.nil?
    output_dir = nil

    OpenStax::Swagger::SwaggerCodegen.execute(api_major_version) do |json|
      api_exact_version = json[:info][:version]
      output_dir = "#{Rails.application.root}/clients/#{api_exact_version}/#{language}"

      config = OpenStax::Swagger.configuration.client_language_configs[language]
      raise "Don't know #{language} config options yet, see `swagger-codegen config-help -l #{language}" unless config

      # Clean out anything that use to be there so old bindings do come back to life
      FileUtils.rm_rf(output_dir)

      {
        cmd_options: %W[-l #{language}],
        output_dir: output_dir,
        config: config.call(api_exact_version),
        post_process: OpenStax::Swagger.configuration.client_language_post_processing[language]
      }
    end
  end
end
