module SwaggerPathAndParametersSchema1
  include Swagger::Blocks
  include OpenStax::Swagger::SwaggerBlocksExtensions

  swagger_root do
    key :openapi, '3.0.0'
  end

  add_components do
    schema :StemBolt do
      key :required, [:id]

      property :name do
        key :type, :string
        key :nullify, true
        key :description, 'The stembolt name.'
      end

    end
  end


  swagger_path_and_parameters_schema '/stembolts' do
    operation :get do
      key :summary, 'A summary'
      key :operationId, 'getStembolts'
      key :tags, [
        'Stembolts'
      ]
      parameter do
        key :name, :param1
        key :schema, type: :string
        key :required, true
      end
      parameter do
        key :name, :param2
        key :schema, type: :string
        key :required, false
        key :description, 'Not param1'
      end
      response 200 do
        key :description, 'Success.'
        content 'application/json' do
          schema { key :$ref, :StemBolt }
        end
      end
    end
  end
end
