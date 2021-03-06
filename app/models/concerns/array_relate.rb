module ArrayRelate
  extend ActiveSupport::Concern

  module ClassMethods
    def array_belongs_to(attr_name, options = {})
      ids_column = set_ids_column(attr_name)

      # Set the polymorphic column accordly
      polymorphic = options.delete(:polymorphic)
      polymorphic_column = set_polymorphic_column(attr_name, polymorphic)

      creates_reader(attr_name, ids_column, polymorphic_column)
      creates_writer(attr_name, ids_column, polymorphic_column)
      creates_entity_class_getter(polymorphic_column)
    end

    private

    def creates_reader(attr_name, ids_column, polymorphic_column)
      class_eval <<-METHOD
        def #{attr_name}
          return [] if #{ids_column}.blank? || #{polymorphic_column}.blank?

          klass = #{polymorphic_column}.constantize
          #{ids_column}.map do |object_id|
            klass.find(object_id)
          end
        end
      METHOD
    end

    def creates_writer(attr_name, ids_column, polymorphic_column)
      class_eval <<-METHOD
        def #{attr_name}=(objs)
          return [] if objs.blank?
          objs = [objs] unless objs.is_a?(Array)

          self.#{ids_column} = objs.map(&:id)
          self.#{polymorphic_column} = objs.first.class.name
        end
      METHOD
    end

    def creates_entity_class_getter(polymorphic_column)
      class_eval <<-METHOD
        def object_entity_class
          return nil if #{polymorphic_column}.blank?
          "\#{#{polymorphic_column}\}::Entity".constantize
        end
      METHOD
    end

    def set_ids_column(attr_name)
      fail "The first argument is obligatory" unless attr_name

      if attr_name.is_a?(String)
        attr_name
      else
        "#{attr_name}_ids"
      end
    end

    def set_polymorphic_column(attr_name, polymorphic)
      return unless polymorphic

      if polymorphic.is_a?(String)
        polymorphic
      else
        "#{attr_name}_type"
      end
    end
  end
end
