require 'open-uri'
require 'fileutils'
require_relative '../openstax/swagger/swagger_codegen'

namespace :openstax_swagger do
  desc <<-DESC.strip_heredoc
    Generate the Ruby API model bindings in the app/bindings directory.  swagger-codegen
    must be installed.  Run like `rake openstax_swagger:generate_model_bindings[1]` for version 1 API.
  DESC
  task :generate_model_bindings, [:api_major_version] => :environment do |tt,args|
    api_major_version = args[:api_major_version] || '1'
    output_dir = nil
    gem_name = 'does_not_matter'

    OpenStax::Swagger::SwaggerCodegen.execute(api_major_version) do |json|
      api_exact_version = json[:info][:version]
      output_dir = "#{Rails.application.root}/tmp/ruby-models/#{api_exact_version}"

      # Clean out anything that use to be there so old bindings do come back to life
      FileUtils.rm_rf(output_dir)

      {
        cmd_options: %w[-g ruby --global-property models],
        output_dir: output_dir,
        config: {
          gemName: gem_name,
          gemHomepage: 'https://does_not_matter.org',
          gemRequiredRubyVersion: '>= 2.4',
          disallowAdditionalPropertiesIfNotPresent: false, # double negative means to allow (but ignore) unlisted attributes
          moduleName: OpenStax::Swagger.configuration.model_bindings_module_proc.call(api_major_version),
          gemVersion: api_exact_version,
        }
      }
    end

    # Move the models to the app/bindings directory

    bindings_dir = OpenStax::Swagger.configuration.model_bindings_dir_proc.call(api_major_version)
    FileUtils::rm_rf(bindings_dir)
    FileUtils::mkdir_p(bindings_dir)
    FileUtils::cp(Dir.glob("#{output_dir}/lib/#{gem_name}/models/*.rb"), bindings_dir, verbose: true)
  end
end
