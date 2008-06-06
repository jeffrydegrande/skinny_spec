$:.unshift File.join(File.dirname(__FILE__), "..")
require "skinny_spec"

module LuckySneaks
  # These methods are designed to be used in your example [read: "it"] blocks
  # to make your view specs less brittle and more DRY. You might also be interested 
  # in checking out the example block [read: "describe"] level versions in of these
  # methods which can DRY things up even more:
  # LuckySneaks::ViewSpecHelpers::ExampleGroupLevelMethods
  module ViewSpecHelpers
    include LuckySneaks::CommonSpecHelpers
    include ActionController::PolymorphicRoutes
    
    def self.included(base) # :nodoc:
      base.extend ExampleGroupLevelMethods
    end
    
    # Wraps a matcher that checks if the receiver contains a <tt>FORM</tt> element with
    # its <tt>action</tt> attribute set to the specified path.
    def submit_to(path)
      have_tag("form[action=#{path}]")
    end
    
    # Wraps a matcher that checks is the receiver contains any of several form elements
    # that would return sufficient named parameters to allow editing of the specified
    # attribute on the specified instance. Example:
    # 
    #   response.should allow_editing(@foo, "bar")
    # 
    # can be satisfied by any of the following HTML elements:
    # 
    #   <input name="foo[bar]" type="text" />
    #   <input name="foo[bar]" type="checkbox" />
    #   <input name="foo[bar_ids][]" type="checkbox" />
    #   <select name="foo[bar]"></select>
    #   <textarea name="foo[bar]"></textarea>
    def allow_editing(instance, attribute)
      instance_name = instance.class.name.underscore.downcase
      if instance.send(attribute).is_a?(Time)
        have_tag(
          "input[name='#{instance_name}[#{attribute}]'],
          select[name=?]", /#{instance_name}\[#{attribute}\(.*\)\]/
        )
      else
        have_tag(
          "input[type='text'][name='#{instance_name}[#{attribute}]'],
          select[name='#{instance_name}[#{attribute}]'],
          textarea[name='#{instance_name}[#{attribute}]'],
          input[type='checkbox'][name='#{instance_name}[#{attribute}]'],
          input[type='checkbox'][name='#{instance_name}[#{attribute.to_s.tableize.singularize}_ids][]']"
        )
      end
    end

    # Wraps a matcher that checks if the receiver contains an <tt>A</tt> element (link) 
    # whose <tt>href</tt> attribute is set to the specified path or a <tt>FORM</tt>
    # element whose <tt>action</tt> attribute is set to the specified path.
    def have_link_or_button_to(path)
      have_tag(
        "a[href='#{path}'],
        form[action='#{path}'] input,
        form[action='#{path}'] button"
      )
    end
    alias have_link_to have_link_or_button_to
    alias have_button_to have_link_or_button_to
    
    # Wraps <tt>have_link_or_button_to new_polymorphic_path<tt> for the specified class which
    # corresponds with the <tt>new</tt> method of the controller.
    # 
    # <b>Note:</b> This method may takes a string or symbol representing the model's name
    # to send to <tt>have_link_or_button_to_show</tt> or the model's name itself.
    def have_link_or_button_to_new(name)
      have_link_or_button_to new_polymorphic_path(name.is_a?(ActiveRecord::Base) ? name : class_for(name))
    end

    # Wraps <tt>have_link_or_button_to polymorphic_path(instance)<tt> which
    # corresponds with the <tt>show</tt> method of the controller.
    def have_link_or_button_to_show(instance)
      have_link_or_button_to polymorphic_path(instance)
    end
    alias have_link_to_show have_link_or_button_to_show
    alias have_button_to_show have_link_or_button_to_show

    # Wraps <tt>have_link_or_button_to edit_polymorphic_path(instance)<tt> which
    # corresponds with the <tt>edit</tt> method of the controller.
    def have_link_or_button_to_edit(instance)
      have_link_or_button_to edit_polymorphic_path(instance)
    end
    alias have_link_to_edit have_link_or_button_to_edit
    alias have_button_to_edit have_link_or_button_to_edit

    # Wraps a matcher that checks if the receiver contains the HTML created by Rails'
    # <tt>button_to</tt> helper: to wit, a <tt>FORM</tt> element whose <tt>action</tt>
    # attribute is pointed at the <tt>polymorphic_path</tt> of the instance
    # and contains an <tt>INPUT</tt> named "_method" with a value of "delete".
    def have_button_to_delete(instance)
      path = polymorphic_path(instance)
      have_tag(
        "form[action='#{path}'] input[name='_method'][value='delete'] + input,
        form[action='#{path}'] input[name='_method'][value='delete'] + button"
      )
    end
    
    # Creates a <tt>mock_model</tt> instance and adds it to the <tt>assigns</tt> collection
    # using either the name passed as the first argument or the underscore version
    # of its class name. Accepts optional arguments to stub out additional methods
    # (and their return values) on the <tt>mock_model</tt> instance. Example:
    # 
    #   mock_and_assign(Foo, :stub => {:bar => "bar"})
    # 
    # is the same as running <tt>assigns[:foo] = mock_model(Foo, :bar => "bar")</tt>.
    # 
    #   mock_and_assign(Foo, "special_foo", :stub => {:bar => "baz"})
    # 
    # is the same as running <tt>assigns[:special_foo] = mock_model(Foo, :bar => "baz").
    # 
    # <b>Note:</b> Adding to the assigns collection returns the object added, so this can
    # be chained a la <tt>@foo = mock_and_assign(Foo)</tt>.
    def mock_and_assign(klass, *args)
      options = args.extract_options!
      mocked = if options[:stub]
        mock_model(klass, options[:stub])
      else
        mock_model(klass)
      end
      yield mocked if block_given?
      self.assigns[args.first || "#{klass}".underscore] = mocked
    end
    
    # Creates an array of <tt>mock_model</tt> instances in the manner of
    # <tt>mock_and_assign</tt>. Accepts <tt>option[:size]</tt> which sets the size
    # of the array (default is 3).
    def mock_and_assign_collection(klass, *args)
      options = args.dup.extract_options!
      return_me = Array.new(options[:size] || 3) do
        mocked = if options[:stub]
          mock_model(klass, options[:stub])
        else
          mock_model(klass)
        end
        yield mocked if block_given?
        mocked
      end
      self.assigns[args.first || "#{klass}".tableize] = return_me
    end
    
  private
    def do_render
      if @the_template
        render @the_template
      elsif File.exists?(File.join(RAILS_ROOT, "app/views", self.class.description_text))
        render self.class.description_text
      else
        error_message = "Cannot determine template for render. "
        error_message << "Please define @the_template in the before block "
        error_message << "or name your describe block so that it indicates the correct template."
        raise NameError, error_message
      end
    end
    
    # These methods are designed to be used at the example group [read: "describe"] level
    # to simplify and DRY up common expectations. Most of these methods are wrappers for
    # matchers which can also be used on the example level [read: within an "it" block]. See
    # LuckySneaks::ViewSpecHelpers for more information.
    module ExampleGroupLevelMethods
      include LuckySneaks::CommonSpecHelpers
      
      # Creates an expectation which calls <tt>submit_to</tt> on the response
      # from rendering the template. See that method for more details.
      def it_should_submit_to(hint = nil, &route)
        if hint.nil? && route.respond_to?(:to_ruby)
          hint = route.to_ruby.gsub(/(^proc \{)|(\}$)/, '').strip
        end
        it "should submit to #{(hint || route)}" do
          do_render
          response.should submit_to(instance_eval(&route))
        end
      end
      
      # Creates an expectation that the template uses Rails' <tt>form_for</tt> to generate
      # the proper form action and method to create or update the specified object.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name to create the expectation for <tt>form_for</tt>
      # not an instance variable, which would be nil in the scope of the example block.
      # If you use namespacing for your <tt>form_for</tt>, you'll have to manually write out
      # a similar spec.
      def it_should_have_form_for(name)
        it "should have a form_for(@#{name})" do
          template.should_receive(:form_for).with(instance_for(name))
        end
      end

      # Creates an expectation which calls <tt>allow_editing</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name to send to <tt>allow_editing</tt>
      # not an instance variable, which would be nil in the scope of the example block.
      def it_should_allow_editing(name, method)
        it "should allow editing of @#{name}##{method}" do
          do_render
          response.should allow_editing(instance_for(name), method)
        end
      end

      # Creates an expectation which calls <tt>have_link_or_button_to</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a block to evaluate the route in the example context
      # instead of the example group context.
      def it_should_link_to(hint = nil, &route)
        if hint.nil? && route.respond_to?(:to_ruby)
          hint = route.to_ruby.gsub(/(^proc \{)|(\}$)/, '').strip
        end
        it "should have a link/button to #{(hint || route)}" do
          do_render
          response.should have_link_or_button_to(instance_eval(&route))
        end
      end
      alias it_should_have_link_to it_should_link_to
      alias it_should_have_button_to it_should_link_to
      alias it_should_have_button_or_link_to it_should_link_to
      
      # Creates an expectation which calls <tt>have_link_or_button_to_new</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method may takes a string or symbol representing the model's name
      # to send to <tt>have_link_or_button_to_show</tt> or the model's name itself.
      def it_should_link_to_new(name)
        it "should have a link/button to create a new #{name}" do
          do_render
          response.should have_link_or_button_to_new(name)
        end
      end
      
      # Creates an expectation which calls <tt>have_link_or_button_to_show</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name to send to <tt>have_link_or_button_to_show</tt>
      # not an instance variable, which would be nil in the scope of the example block.
      def it_should_link_to_show(name)
        it "should have a link/button to show @#{name}" do
          do_render
          response.should have_link_or_button_to_show(instance_for(name))
        end
      end
      alias it_should_have_link_to_show it_should_link_to_show
      alias it_should_have_button_to_show it_should_link_to_show
      alias it_should_have_button_or_link_to_show it_should_link_to_show
      
      # Creates an expectation which calls <tt>have_link_or_button_to_show</tt>
      # for each member of the instance variable matching the specified name
      # on the response from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name and not an instance variable, which would be nil
      # in the scope of the example block.
      def it_should_link_to_show_each(name)
        it "should have a link/button to show each member of @#{name}" do
          do_render
          instance_for(name).each do |member|
            response.should have_link_or_button_to_show(member)
          end
        end
      end
      alias it_should_have_link_to_show_each it_should_link_to_show_each
      alias it_should_have_button_to_show_each it_should_link_to_show_each
      alias it_should_have_button_or_link_to_show_each it_should_link_to_show_each

      # Creates an expectation which calls <tt>have_link_or_button_to_edit</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name to send to <tt>have_link_or_button_to_edit</tt>
      # not an instance variable, which would be nil in the scope of the example block.
      def it_should_link_to_edit(name)
        it "should have a link/button to edit @#{name}" do
          do_render
          response.should have_link_or_button_to_edit(instance_for(name))
        end
      end
      alias it_should_have_link_to_edit it_should_link_to_edit
      alias it_should_have_button_to_edit it_should_link_to_edit
      alias it_should_have_button_or_link_to_edit it_should_link_to_edit

      # Creates an expectation which calls <tt>have_link_or_button_to_edit</tt>
      # for each member of the instance variable matching the specified name
      # on the response from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name and not an instance variable, which would be nil
      # in the scope of the example block.
      def it_should_link_to_edit_each(name)
        it "should have a link/button to edit each member of @#{name}" do
          do_render
          instance_for(name).each do |member|
            response.should have_link_or_button_to_edit(member)
          end
        end
      end
      alias it_should_have_link_to_edit_each it_should_link_to_edit_each
      alias it_should_have_button_to_edit_each it_should_link_to_edit_each
      alias it_should_have_button_or_link_to_edit_each it_should_link_to_edit_each

      # Creates an expectation which calls <tt>have_link_or_button_to_delete</tt> on the response
      # from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name to send to <tt>have_link_or_button_to_delete</tt>
      # not an instance variable, which would be nil in the scope of the example block.
      def it_should_link_to_delete(name)
        it "should have a link/button to delete @#{name}" do
          do_render
          response.should have_button_to_delete(instance_for(name))
        end
      end
      alias it_should_have_link_to_delete it_should_link_to_delete
      alias it_should_have_button_to_delete it_should_link_to_delete
      alias it_should_have_button_or_link_to_delete it_should_link_to_delete

      # Creates an expectation which calls <tt>have_link_or_button_to_delete</tt>
      # for each member of the instance variable matching the specified name
      # on the response from rendering the template. See that method for more details.
      # 
      # <b>Note:</b> This method takes a string or symbol representing the instance
      # variable's name and not an instance variable, which would be nil
      # in the scope of the example block.
      def it_should_link_to_delete_each(name)
        it "should have a link/button to delete each member of @#{name}" do
          do_render
          instance_for(name).each do |member|
            response.should have_button_to_delete(member)
          end
        end
      end
      alias it_should_have_link_to_delete_each it_should_link_to_delete_each
      alias it_should_have_button_to_delete_each it_should_link_to_delete_each
      alias it_should_have_button_or_link_to_delete_each it_should_link_to_delete_each
      
      def it_should_render(hint = nil, &block)
        if hint.nil? && block.respond_to?(:to_ruby)
          hint = block.to_ruby.gsub(/(^proc \{)|(\}$)/, '').strip
        end
        it "should render #{hint || route}" do
          template.expect_render &block
          do_render
        end
      end
    end
  end
end