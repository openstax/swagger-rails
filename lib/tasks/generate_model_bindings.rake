require 'open-uri'
require 'fileutils'
require 'active_support/core_ext/string/strip'
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
        cmd_options: %w[-l ruby -D models],
        output_dir: output_dir,
        config: {
          gemName: gem_name,
          gemHomepage: 'https://does_not_matter.org',
          gemRequiredRubyVersion: '>= 2.4',
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

    # When data is deserializing into a binding, there's a line that builds binding objects from
    # serialized values.  It instantiates a new object and then calls `build_from_hash` on the object,
    # passing it the deserialized object value.  That passed value is expected to be a hash, but if it
    # isn't, `build_from_hash` returns nil instead of `self` as it does in normal operation.  This
    # difference means that when we have invalid deserialized values we end up with a bunch of nils
    # instead of blank objects.  Blank objects are preferred as they let us call methods like `valid?`
    # on them.  The following monkey patch ensures that we are always left with a binding instance and
    # not a nil.

    bad_line_that_can_return_nil = "temp_model.build_from_hash(value)"
    fixed_line_that_returns_model = "temp_model.tap{|tm| tm.build_from_hash(value)}"

    Dir.glob("#{bindings_dir}/*.rb") do |file_name|
      text = File.read(file_name)
      replace = text.gsub!(bad_line_that_can_return_nil, fixed_line_that_returns_model)
      File.open(file_name, "w") { |file| file.puts replace }
    end

  end
end
