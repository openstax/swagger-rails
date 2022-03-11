require 'open-uri'
require 'fileutils'

module OpenStax::Swagger::SwaggerCodegen

  # You can find flags for various configs by running:
  # swagger-codegen config-help -l <language>

  def self.execute(api_major_version)

    swagger_data = OpenStax::Swagger.configuration.json_proc.call(api_major_version)

    options = yield swagger_data

    # make sure the output dir exists
    FileUtils::mkdir_p(options[:output_dir])

    Tempfile.open(['swagger', '.json']) do |swagger_json|
      # Write the swagger data to a JSON file (so we don't have to run the web server
      # to provide it to swagger-codegen)
      swagger_json.write(swagger_data.to_json)
      swagger_json.flush

      Tempfile.open(['config', '.json']) do |config_file|
        config_file.write(options[:config].to_json)
        config_file.flush

        # Build and run the swagger-codegen command
        puts system('openapi-codegen', 'generate',
                    '-i', swagger_json.path,
                    '-o', options[:output_dir],
                    '-c', config_file.path,
                    *options[:cmd_options])

        if options[:post_process]
          Dir.chdir(options[:output_dir]) do
            options[:post_process].call(options)
          end
        end
      end
    end

  end

end
