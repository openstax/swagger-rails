module Openstax
  module Swagger
    module RecordExtensions
      def to_api_binding(binding)
        binding.new(attributes_for_binding(binding))
      end

      def attributes_for_binding(binding)
        attributes.slice(*binding.acceptable_attributes.map(&:to_s))
      end
    end
  end
end
