module LuckySneaks
  # These methods are probably only useful when using <tt>belongs_to</tt>.
  module NestedResourceHelpers
    def self.included(base)
      base.extend ExampleGroupMethods
    end
    
    def parent_name
      @parent_name ||= self.class.read_inheritable_attribute :parent
    end
    
    def parent?
      !!parent_name
    end
    
    def parent_model
      class_for(parent_name)
    end
    
    def instance_variable_name
      @controller.controller_name
    end
    
    def mock_parent
      @mock_parent ||= mock(parent_name, :id => 1)
    end
    
    # Adds the appropriate parent id to the params hash. Should be called before
    # eval_request.
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
      mock_parent.stub!(:to_s).and_return(mock_parent.id.to_s)
      
      parent_model.stub!(:find).with(mock_parent.id.to_s).and_return(mock_parent)
    end
    
    # Creates an expectation on the instance variable for <tt>name</tt> that
    # it should receive <tt>find(:all)</tt> <b>only if <tt>name</tt> is
    # plural</b>. Meant to be used by <tt>it_should_find</tt>.
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
    
    # This module exposes the <tt>belongs_to</tt> method for tidying up controller
    # specs for nested resources. See the docs on that method.
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
      #     describe "responding to GET :index" do
      #       before(:each) do
      #         @toys = stub_index(Toy)
      #       end
      # 
      #       it_should_find_and_assign :toys
      #       it_should_render_template :index
      #     end
      #
      #     ...
      #   end
      #
      # Now you can use the same stub_* and it_should_* methods as always, and
      # the stubbing and expectations needed by the parent model and collection
      # of child models are taken care of.
      #
      # <em>Note:</em> make_resourceful allows you to specify multiple parents in
      # a single <tt>belongs_to</tt> declaration. That isn't supported here. If
      # you need to test that behavior, separate your parents into multiple
      # describe blocks:
      #
      #   describe ToysController do
      #     describe "belonging to Cat" do
      #       belongs_to :cat
      #
      #       ...
      #     end
      #
      #     describe "belonging to Gerbil" do
      #       belongs_to :gerbil
      #
      #       ...
      #     end
      #   end
      def belongs_to(parent)
        write_inheritable_attribute(:parent, parent.to_s)
      end
    end
  end
end
