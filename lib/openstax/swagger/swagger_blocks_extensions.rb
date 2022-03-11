module OpenStax::Swagger::SwaggerBlocksExtensions

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def add_properties(*schema_names, &block)
      node = @swagger_components_node || swagger_component {}
      schema_names.each do |schema_name|
        node.schema schema_name do
          instance_eval(&block)
        end
      end
    end

    def add_components(&block)
      node = @swagger_components_node
      if node.nil?
        swagger_component { instance_eval(&block) }
      else
        node.instance_eval(&block)
      end
    end
    # Same as call to `swagger_path` but also generates a `swagger_schema` for the parameters
    # so that controller code can bind the parameters to a binding.
    def swagger_path_and_parameters_schema(path, &block)
      swagger_path(path, &block).tap do |path_node|
        # When this is the first call against this `path`, the path_node is a `PathNode`
        # wrapping one `OperationNode`.  Afterwards it is an `OperationNode`.  This case
        # makes sure we are always dealing with the OperationNode.
        data = case path_node
        when Swagger::Blocks::Nodes::PathNode
          path_node.data[path_node.data.keys.first].data
        when Swagger::Blocks::Nodes::OperationNode
          path_node.data
        end

        if data[:operationId].blank?
          raise "Must set an operationId when generating a binding from a swagger_path"
        end

        binding_name = data[:operationId].camelcase + "Parameters"
        required_keys = []

        swagger_schema binding_name do
          data[:parameters].map(&:data).each do |parameter_hash|
            parameter_hash.symbolize_keys!
            required_keys.push(parameter_hash[:name]) if parameter_hash.delete(:required)
            property parameter_hash[:name] do
              parameter_hash.except(:in, :name).each do |key, value|
                key key, value
              end
            end
          end
          key :required, required_keys
        end
      end
    end
  end

end
