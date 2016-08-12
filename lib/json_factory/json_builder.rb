# frozen_string_literal: true

module JSONFactory
  class JSONBuilder
    attr_reader :attributes, :context

    def initialize(factory = nil, context_objects = {})
      @attributes = {}
      @context = Context.new(context_objects)

      return unless factory
      schema do |json|
        json.instance_eval(factory)
      end
    end

    def self.load_factory(path, context_objects = {})
      raise "jfactory file #{path} not found" unless File.exist?(path)
      new(File.open(path).read, context_objects)
    end

    def add_to_comtext(key, value)
      @context.add(key, value)
    end

    def schema(object = nil, &block)
      return self unless block_given?
      if object
        if object.is_a?(Array)
          collection(object, &block)
        else
          yield self, object
        end
      else
        yield self
      end
      self
    end

    def partial!(factory, context_objects = {})
      if File.exist?(factory)
        attributes.merge!(self.class.load_factory(factory, context_objects).attributes)
      else
        attributes.merge!(self.class.new(factory, context_objects).attributes)
      end
    end

    def collection(collection, &block)
      @attributes = collection.map { |object| self.class.new.schema(object, &block).attributes }
    end

    def method_missing(method_name, *arguments, &block)
      return set_value(method_name.to_s, arguments.at(0)) unless Kernel.block_given?
      return set_collection(method_name.to_s, arguments.at(0), &block) if arguments.at(0).is_a?(Array)
      set_object(method_name.to_s, &block)
    end

    def build
      Oj.dump(attributes)
    end

    private

    def set_value(key, value)
      @attributes[key] = value
    end

    def set_object(key, &block)
      @attributes[key] = self.class.new.schema(&block).attributes
    end

    def set_collection(key, collection, &block)
      @attributes[key] = collection.map { |object| self.class.new.schema(object, &block).attributes }
    end
  end
end
