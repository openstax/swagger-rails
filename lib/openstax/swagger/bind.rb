module OpenStax::Swagger
  module Bind

    protected

    def self.recursively_list_invalid_properties(object)
      if object.respond_to?(:valid?)
        if object.valid?
          klass = object.class
          klass.respond_to?(:attribute_map) ? klass.attribute_map.flat_map do |attr, _|
            value = object.send(attr)
            invalid_properties = recursively_list_invalid_properties value
            invalid_properties.empty? ? [] : [ "#{attr}: [ #{invalid_properties.join(', ')} ]" ]
          end : [ "#{klass} is valid but does not respond to #attribute_map" ]
        else
          object.respond_to?(:list_invalid_properties) ?
            object.list_invalid_properties :
            [ "#{object} is invalid but does not respond to #list_invalid_properties" ]
        end
      else
        case object
        when Array
          object.flat_map { |item| recursively_list_invalid_properties item }
        when Hash
          object.flat_map { |_, value| recursively_list_invalid_properties value }
        else
          []
        end
      end
    end

    def bind(data, bindings_class)
      begin
        # If `data` is a set of controller params, permit all the fields in them.  The binding
        # process will only use the fields we want to use.  If we want to start honoring read-only
        # fields, we may have to change this.

        data.permit! if data.respond_to?(:permit!)

        binding = bindings_class.new.build_from_hash(data.to_h.with_indifferent_access)

        # do some simple extra error checking
        keys_in_binding = binding.to_body.keys.map(&:to_s)
        keys_in_data = data.keys.map(&:to_s)

        unused_keys = keys_in_data - keys_in_binding
        keys_that_did_not_get_bound = unused_keys & bindings_class.swagger_types.keys.map(&:to_s)
        unrequested_keys = unused_keys - keys_that_did_not_get_bound

        if keys_that_did_not_get_bound.any?
          # NB: Some other things can generate ArgumentError besides this
          raise ArgumentError, "Some keys didn't make it into the binding: #{keys_that_did_not_get_bound}"
        end

        if unrequested_keys.any?
          raise ArgumentError, "Some unrequested keys were provided: #{unrequested_keys}"
        end
      rescue ArgumentError => ee
        return [nil, binding_error(status_code: 422, messages: [ee.message])]
      end

      invalid_properties = OpenStax::Swagger::Bind.recursively_list_invalid_properties binding

      return [binding, nil] if invalid_properties.empty?

      [binding, binding_error(status_code: 422, messages: invalid_properties)]
    end

    def binding_error(status_code:, messages:)
      raise "Implement a `binding_error(status_code:, messages:)` method in your " \
            "controller that returns a new object that can be serialized to JSON and " \
            "that has a `status_code` accessor"
    end

  end
end
