module Plurk
  module BuildClass
    class <<self

      # Generate a attibutes class base on the content of a file with yaml format
      # @param ns [Module] the namespace of new class will belongs to.
      # @param file [String] filename to the file contains definition
      # @return [String] Generated class name (without namespace)
      def insert ns, file
        meta = YAML.load_file file

        raise ArgumentError, "missing class_name in `#{file}`" unless meta["class_name"]

        if  meta['attributes'] and
            meta['attributes'].is_a? Array and
            meta['attributes'].compact.length > 0
          ns.send( :const_set,
                   meta['class_name'],
                   Struct.new(*(meta['attributes'].map(&:to_sym)))
                   ).include(DataContainer)
          if meta['required_params'] and
            meta['required_params'].is_a? Array and
            meta['required_params'].compact.length > 0
            klass = ns.send(:const_get, meta['class_name'])
            klass.send(:define_singleton_method, "required_params") do
              return meta['required_params']
            end
            klass.send(:define_method, "type") do
              return meta['class_name'].downcase
            end

          end
        else
          ns.send( :const_set, meta['class_name'], meta['attributes'] || Class.new )
        end

        return meta["class_name"]

      end
    end

    # Modifies some behavior of origin `Struct`
    module DataContainer

      # Can accept a hash as initialization argument
      def initialize arg
        if arg.is_a? Hash

          if self.class.respond_to?(:required_params)
            unless self.class.required_params.map { |param| arg.key? param }.inject(true){ |o,i| (o and i) }
              raise ArgumentError, "Missing one of the required arguments: [#{self.class.required_params.join(", ")}]"
            end
          end

          super()

          arg.each_pair do |k,v|
            # drop not-in-member attributes
            send("#{k}=",v) if self.class.members.include? k.to_sym
          end
        else
          super(*arg)
        end
      end
    end

  end
end
