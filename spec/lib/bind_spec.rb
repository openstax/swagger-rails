require 'rails_helper'
require 'ostruct'

RSpec.describe 'bind' do

  include OpenStax::Swagger::Bind

  context 'schema one' do

    let(:arbitrary_object) {{
      foo: "bar",
      howdy: [1,2,3]
    }}

    let(:valid_params) {
      ActionController::Parameters.new(valid_hash)
    }

    let(:valid_hash) {
      {
        an_integer: 42,
        an_arbitrary_object: arbitrary_object,
        a_defined_object: {
          another_integer: 84,
          an_array: [
            {a_string: "yo"},
            {a_string: "yo"},
            {a_string: "ma"}
          ]
        }
      }
    }

    it 'binds to params' do
      binding, error = bind(valid_params, Api::V0::Bindings::TopLevel)
      expect(error).to be_nil
      expect(binding.an_integer).to eq 42
      expect(binding.an_arbitrary_object).to eq arbitrary_object.with_indifferent_access
      expect(binding.a_defined_object.an_array[2].a_string).to eq "ma"
    end

    it 'binds to a simple hash' do
      binding, error = bind(valid_hash, Api::V0::Bindings::TopLevel)
      expect(error).to be_nil
      expect(binding.an_integer).to eq 42
      expect(binding.an_arbitrary_object.with_indifferent_access).to eq arbitrary_object.with_indifferent_access
      expect(binding.a_defined_object.an_array[2].a_string).to eq "ma"
    end

    it 'has bound nested items that detect invalidity' do
      valid_params[:a_defined_object][:an_array] = %w(yo yo ma)
      binding, error = bind(valid_params, Api::V0::Bindings::TopLevel)
      expect(binding.a_defined_object.an_array[2]).not_to be_valid
    end

    it 'can check for deep invalidity' do
      valid_params[:a_defined_object][:an_array] = %w(yo yo ma)
      binding, error = bind(valid_params, Api::V0::Bindings::TopLevel)
      expect(error.messages).to eq [
        "a_defined_object: [ an_array: [ #{
          ([ 'invalid value for "a_string", a_string cannot be nil.' ] * 3).join(', ')
        } ] ]"
      ]
    end

  end

  # required when including Bind
  def binding_error(status_code:, messages:)
    OpenStruct.new(status_code: status_code, messages: messages)
  end

end
