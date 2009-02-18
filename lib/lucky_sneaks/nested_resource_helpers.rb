module LuckySneaks
  # Assume Cat <tt>has_many :toys</tt>.
  module NestedResourceHelpers
    def self.included(base)
      base.extend ExampleGroupMethods
    end
    
    def controller_name
      @controller.controller_name
    end
    
    def parent_names
      self.class.read_inheritable_attribute(:parents) || []
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
      params
    end
    
    # Creates stubs on the mock parent for finding the collection of children
    # and an individual child. The mock collection and child should be passed
    # as <tt>:collection</tt> and <tt>:member</tt> options (<tt>:member</tt> is
    # optional).
    #
    #   # toys = options[:collection]
    #   # toy = options[:member]
    #   # cat = mock_parent
    #   Cat.find(cat.id)            #=> cat
    #   cat.toys                    #=> toys
    #   cat.toys.find(:all)         #=> toys
    #   cat.toys.build(any_args)    #=> toy
    #
    # If <tt>options[:member]</tt> is not nil:
    #
    #   cat.toys.find(toy.id)       #=> toy
    #   toy.cat                     #=> cat
    def create_nested_resource_stubs(options = {})
      @child_collection = collection = options.delete(:collection)
      member = options.delete(:member)
      
      unless member.nil?
        collection.stub!(:find).with(member.id).and_return(member)
        collection.stub!(:find).with(member.id.to_s).and_return(member)
        member.stub!(parent_name).and_return(mock_parent)
      end
      
      collection.stub!(:find).with(:all).and_return(collection)
      collection.stub!(:build).with(any_args).and_return(member)

      mock_parent.stub!(instance_variable_name).and_return(collection)
      parent_model.stub!(:find).with(mock_parent.id.to_s).and_return(mock_parent)
    end
    
    # Creates an expectation on the instance variable for <tt>name</tt> that
    # it should receive <tt>find(:all)</tt> <b>only if <tt>name</tt> is
    # plural</b>. Meant to be used by <tt>ControllerSpecHelpers::it_should_find</tt>.
    #
    #   # name = :toys
    #   cat.toys.find(:all)   #=> @toys
    def create_nested_resource_collection_expectations(name)
      if name.to_s.pluralize == name.to_s
        collection = instance_for(name)
        collection.should_receive(:find).with(:all).and_return(collection)
      end
    end
    
    # Creates an expectation on the child collection (e.g., <tt>parent.children</tt>)
    # that it should receive <tt>build</tt> and return the instance variable for
    # <tt>name</tt>.
    #
    #   # name = :toy
    #   cat.toys.build(any_args)   #=> @toy
    def create_nested_resource_instance_expectation(name)
      @child_collection.should_receive(:build).with(any_args).and_return(instance_for(name))
    end
    
    module ExampleGroupMethods
      
      # Makes stubbing nested resources easier.
      #
      # Say Cat <tt>has_many :toys</tt> and Toy <tt>belongs_to :cat</tt>. In
      # toys_controller.rb:
      #
      #   class ToysController < ApplicationController
      #     make_resourceful do
      #       actions :all
      #       belongs_to :cat
      #     end
      #   end
      #
      # In toys_controller_spec.rb:
      #
      #   describe ToysController do
      #     belongs_to :cat
      #
      #     ...
      #   end
      #
      # Now you can use the same stub_* and it_should_* methods as always, and
      # the stubbing and expectations needed by the parent model and collection
      # of child models is taken care of.
      #
      # <i>Note:</i> even though this method accepts any number of parents, only
      # the first one will be used in requests. This is a bug and will be
      # fixed...sooner or later.
      def belongs_to(*parents)
        write_inheritable_attribute(:parents, parents.map(&:to_s))
      end
    end
  end
end
