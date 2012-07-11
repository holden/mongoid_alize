module Mongoid
  module Alize
    class ToManyCallback < ToCallback
      protected

      def define_callback
        klass.class_eval <<-CALLBACK, __FILE__, __LINE__ + 1
          def #{callback_name}#{force_param}
            field_values = #{field_values("self", :id => true)}
            (#{iterable_relation}).each do |inverse|
              #{pull_from_inverse}
              inverse.push(:#{prefixed_name}, field_values)
            end
          end
          protected :#{callback_name}
        CALLBACK
      end

      def define_destroy_callback
        klass.class_eval <<-CALLBACK, __FILE__, __LINE__ + 1
          def #{destroy_callback_name}
            (#{iterable_relation}).each do |inverse|
              #{pull_from_inverse}
            end
          end
          protected :#{destroy_callback_name}
        CALLBACK
      end

      def pull_from_inverse
        <<-CALLBACK
          # this pull works in the DB, but not in memory
          # ($pull w/ expression not currently supported by Mongoid)
          inverse.pull(:#{prefixed_name}, { "_id" => self.id })

          # manually do the pull in memory for now
          if inverse.#{prefixed_name}
            inverse.#{prefixed_name}.reject! do |hash|
              hash["_id"] == self.id
            end
          end
        CALLBACK
      end
    end
  end
end
