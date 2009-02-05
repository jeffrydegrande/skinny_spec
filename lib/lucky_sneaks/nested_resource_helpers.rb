module LuckySneaks
  module NestedResourceHelpers
    def self.included(base)
      base.extend ExampleGroupMethods
    end
    
    # Overrides what Resourceful::Default::Accessors thinks controller_name is
    def controller_name
      @controller.controller_name
    end
    
    def parent_names
      self.class.read_inheritable_attribute :parents
    end
    
    # TODO: only recognizes the first parent passed to belongs_to
    def parent_name
      @parent_name ||= parent_names.first
    end
    
    def parent?
      !!parent_name
    end
    
    def parent_model
      class_for(parent_name)
    end
    
    def instance_variable_name
      controller_name
    end
    
    def mock_parent
      @mock_parent ||= mock(parent_name, :id => 1)
    end

    def parentize_params
      params["#{parent_name.to_s.underscore}_id"] = mock_parent.id
    end
    
    def create_nested_resource_stubs(options = {})
      @child_collection = collection = options.delete(:collection)
      member = options.delete(:member)
      
      collection.stub!(:find).with(:all).and_return(collection)
      collection.stub!(:build).with(any_args).and_return(member)
      
      mock_parent.stub!(instance_variable_name).and_return(collection)
      parent_model.stub!(:find).with(mock_parent.id.to_s).and_return(mock_parent)
    end

    def create_nested_resource_expectations(name)
      collection = instance_for(name)
      collection.should_receive(:find).with(:all).and_return(collection)
    end
    
    def create_nested_resource_instance_expectation(name)
      @child_collection.should_receive(:build).with(any_args).and_return(instance_for(name))
    end
    
    module ExampleGroupMethods
      def belongs_to(*parents)
        write_inheritable_attribute(:parents, parents.map(&:to_s))
      end
    end
  end
end
