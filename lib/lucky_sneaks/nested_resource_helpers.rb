module LuckySneaks
  module NestedResourceHelpers
    attr_accessor :child_collection
    
    def self.included(base)
      base.extend ExampleGroupMethods
    end
    
    def parent?
      !!self.class.read_inheritable_attribute(:parent)
    end
    
    def parent
      @parent ||= mock(parent_class, :id => 1)
    end
    
    def parent_class
      class_for(self.class.read_inheritable_attribute(:parent))
    end
    
    def child_collection_method
      model_class_name.underscore.pluralize.to_sym
    end
    
    def model_class_name
      @controller.controller_name.singularize.camelize
    end
    
    def create_nested_resource_stubs(collection)
      @child_collection = collection
      
      association_id = (parent_class.to_s.underscore + "_id").to_sym
      params[association_id] = parent.id
      
      @child_collection.stub!(:find).with(:all).and_return(@child_collection)
      parent.stub!(child_collection_method).and_return(@child_collection)
      parent_class.stub!(:find).with(parent.id.to_s).and_return(parent)
    end

    def create_nested_resource_expectations
      unless @child_collection.nil?
        @child_collection.should_receive(:find).with(:all).and_return(@child_collection)
      end
    end
    
    module ExampleGroupMethods
      def belongs_to(parent)
        write_inheritable_attribute(:parent, parent.to_s)
      end
    end
  end
end
