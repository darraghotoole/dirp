require "dirp/version"

module Dirp
	class Registry
		def self.create(&block)
			registry = Registry.new
			registry.instance_eval(&block)
			registry
		end

		def get(reference, build_stack = [])
			return instance_registry[reference] if instance_registry[reference]
			instance_registry[reference] = build(reference, build_stack)
		end

		def build(reference, build_stack)
			build_stack << reference
			class_to_build = get_class(reference)
			constructor = class_to_build.instance_method(:initialize)
			return class_to_build.new if(constructor.parameters.size == 0)

			constructor_params = constructor.parameters.map do |type, name|
				raise CircularDependencyError, "circular dependency while building '#{reference}'" if build_stack.include?(name)
				get(name, build_stack)
			end

			instance = class_to_build.allocate
			instance.send(:initialize, *constructor_params)
			return instance
		end

		def bind_alias(alias_reference, existing_reference)
			bind_instance(alias_reference, get(existing_reference))
		end

		def get_class(reference)
			raise NotBoundError, "'#{reference}' is not bound" unless class_registry[reference]
			class_registry[reference]
		end

		def bind(reference, candidate_class)
			raise AlreadyBoundError, "'#{reference} already bound" if class_registry[reference]
			class_registry[reference] = candidate_class
		end

		def bind_instance(reference, instance)
			bind(reference, instance.class)
			instance_registry[reference] = instance
		end

		def instance_registry
			@instance_registry ||= {}
		end

		def class_registry
			@class_registry ||= {}
		end
	end

	class AlreadyBoundError < RuntimeError
	end

	class NotBoundError < RuntimeError
	end

	class CircularDependencyError < RuntimeError
	end
end

