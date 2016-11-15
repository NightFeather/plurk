module Plurk
  module BuildClass
    class <<self
      def insert ns, file
        meta = YAML.load_file file
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
            ns.send(:const_get, meta['class_name'])
              .send(:define_singleton_method, "required_params") do
                return meta['required_params']
              end
          end
        else
          ns.send( :const_set, meta['class_name'], meta['attributes'] || Class.new )
        end
      end
    end

    module DataContainer
      def initialize arg
        if arg.is_a? Hash
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
