require 'rails_helper'

RSpec.describe 'swagger_path_and_parameters_schema' do

  it 'generates open api version 3 path and components definitions' do
    json = Swagger::Blocks.build_root_json([SwaggerPathAndParametersSchema1])
    expect(json[:paths]).to include({
      :"/stembolts" => hash_including({
        get: hash_including({
          summary: "A summary",
          operationId: "getStembolts",
          parameters: array_including([
            hash_including({
              name: :param1,
              schema: {type: 'string'},
            })
          ])
        }),
      })
    })

    expect(json[:components][:schemas]).to include({
      StemBolt: hash_including({
        required: ['id'],
        properties: hash_including({
          name: hash_including({
            type: :string,
            nullify: true,
            description: 'The stembolt name.',
          })
        })
      })
    })
  end

  it 'works when there are two path calls' do
    json = Swagger::Blocks.build_root_json([SwaggerPathAndParametersSchema2])

    expect(json[:paths]).to include({
      :"/stembolts" => hash_including({
        get: hash_including({
          summary: "A summary",
          operationId: "getStembolts"
        })
      })
    })

    expect(json[:definitions]).to include({
      "GetStemboltsParameters" => {
        properties: {
          param1: {type: :string},
          param2: {type: :string, description: "Not param1"}
        },
        required: ["param1"]
      }
    })
  end

end
