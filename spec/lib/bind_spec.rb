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
      expect(binding.a_defined_object['an_array'][2]['a_string']).to eq "ma"
    end

    it 'binds to a simple hash' do
      binding, error = bind(valid_hash, Api::V0::Bindings::TopLevel)
      expect(error).to be_nil
      expect(binding.an_integer).to eq 42
      expect(binding.an_arbitrary_object.with_indifferent_access).to eq arbitrary_object.with_indifferent_access
      expect(binding.a_defined_object['an_array'][2]['a_string']).to eq "ma"
    end

    it 'has bound items that detect invalidity' do
      binding, error = bind({}, Api::V0::Bindings::TopLevel)
      expect(error).to be_present
      expect(error.messages.first).to match(/an_integer cannot be nil/)
      expect(binding).not_to be_valid
    end

    xit 'can check for deep invalidity' do
      # Here the array items nested down a few levels are invalid, but the `.valid?` check
      # on the top level bound item doesn't recursively check validity, so it goes unnoticed.
      # If we want to use the bindings for schema validation, we'll need a way to get around
      # this.  Or we should use a separate schema validator.

      valid_params[:a_defined_object][:an_array] = %w(yo yo ma)
      binding, error = bind(valid_params, Api::V0::Bindings::TopLevel)
      expect(error).not_to be_nil
    end

  end

  # required when including Bind
  def binding_error(status_code:, messages:)
    OpenStruct.new(status_code: status_code, messages: messages)
  end

end
