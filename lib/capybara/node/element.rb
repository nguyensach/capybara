# frozen_string_literal: true

module Capybara
  module Node
    ##
    #
    # A {Capybara::Node::Element} represents a single element on the page. It is possible
    # to interact with the contents of this element the same as with a document:
    #
    #     session = Capybara::Session.new(:rack_test, my_app)
    #
    #     bar = session.find('#bar')              # from Capybara::Node::Finders
    #     bar.select('Baz', from: 'Quox')      # from Capybara::Node::Actions
    #
    # {Capybara::Node::Element} also has access to HTML attributes and other properties of the
    # element:
    #
    #      bar.value
    #      bar.text
    #      bar[:title]
    #
    # @see Capybara::Node
    #
    class Element < Base
      def initialize(session, base, query_scope, query)
        super(session, base)
        @query_scope = query_scope
        @query = query
        @allow_reload = false
      end

      def allow_reload!
        @allow_reload = true
      end

      ##
      #
      # @return [Object]    The native element from the driver, this allows access to driver specific methods
      #
      def native
        synchronize { base.native }
      end

      ##
      #
      # Retrieve the text of the element. If `Capybara.ignore_hidden_elements`
      # is `true`, which it is by default, then this will return only text
      # which is visible. The exact semantics of this may differ between
      # drivers, but generally any text within elements with `display:none` is
      # ignored. This behaviour can be overridden by passing `:all` to this
      # method.
      #
      # @param [:all, :visible] type  Whether to return only visible or all text
      # @return [String]              The text of the element
      #
      def text(type = nil)
        type ||= :all unless session_options.ignore_hidden_elements or session_options.visible_text_only
        synchronize do
          if type == :all
            base.all_text
          else
            base.visible_text
          end
        end
      end

      ##
      #
      # Retrieve the given attribute
      #
      #     element[:title] # => HTML title attribute
      #
      # @param  [Symbol] attribute     The attribute to retrieve
      # @return [String]               The value of the attribute
      #
      def [](attribute)
        synchronize { base[attribute] }
      end

      ##
      #
      # @return [String]    The value of the form element
      #
      def value
        synchronize { base.value }
      end

      ##
      #
      # Set the value of the form element to the given value.
      #
      # @param [String] value    The new value
      # @param [Hash{}] options  Driver specific options for how to set the value
      #
      # @return [Capybara::Node::Element]  The element
      def set(value, **options)
        raise Capybara::ReadOnlyElementError, "Attempt to set readonly element with value: #{value}" if readonly?

        driver_supports_options = (base.method(:set).arity != 1)

        unless options.empty? || driver_supports_options
          warn "Options passed to Capybara::Node#set but the driver doesn't support them"
        end

        synchronize do
          if driver_supports_options
            base.set(value, options)
          else
            base.set(value)
          end
        end
        return self
      end

      ##
      #
      # Select this node if is an option element inside a select tag
      #
      # @return [Capybara::Node::Element]  The element
      def select_option
        warn "Attempt to select disabled option: #{value || text}" if disabled?
        synchronize { base.select_option }
        return self
      end

      ##
      #
      # Unselect this node if is an option element inside a multiple select tag
      #
      # @return [Capybara::Node::Element]  The element
      def unselect_option
        synchronize { base.unselect_option }
        return self
      end

      ##
      #
      # Click the Element
      #
      # @!macro click_modifiers
      #   @overload $0(*key_modifiers=[], offset={x: nil, y: nil})
      #     @param [Array<:alt, :control, :meta, :shift>] *key_modifiers  Keys to be held down when clicking
      #     @param [Hash] offset                          x and y coordinates to offset the click location from the top left corner of the element.  If not specified will click the middle of the element.
      # @return [Capybara::Node::Element]  The element
      def click(*keys, **offset)
        if keys.empty? && offset.empty?
          synchronize { base.click }
        else
          verify_click_options_support(__method__)
          synchronize { base.click(keys, offset) }
        end
        return self
      end

      ##
      #
      # Right Click the Element
      #
      # @macro click_modifiers
      # @return [Capybara::Node::Element]  The element
      def right_click(*keys, **offset)
        if keys.empty? && offset.empty?
          synchronize { base.right_click }
        else
          verify_click_options_support(__method__)
          synchronize { base.right_click(keys, offset) }
        end
        return self
      end

      ##
      #
      # Double Click the Element
      #
      # @macro click_modifiers
      # @return [Capybara::Node::Element]  The element
      def double_click(*keys, **offset)
        if keys.empty? && offset.empty?
          synchronize { base.double_click }
        else
          verify_click_options_support(__method__)
          synchronize { base.double_click(keys, offset) }
        end
        return self
      end

      ##
      #
      # Send Keystrokes to the Element
      #
      # @overload send_keys(keys, ...)
      #   @param [String, Symbol, Array<String,Symbol>] keys
      #
      # Examples:
      #
      #     element.send_keys "foo"                     #=> value: 'foo'
      #     element.send_keys "tet", :left, "s"   #=> value: 'test'
      #     element.send_keys [:control, 'a'], :space   #=> value: ' ' - assuming ctrl-a selects all contents
      #
      # Symbols supported for keys
      # :cancel
      # :help
      # :backspace
      # :tab
      # :clear
      # :return
      # :enter
      # :shift
      # :control
      # :alt
      # :pause
      # :escape
      # :space
      # :page_up
      # :page_down
      # :end
      # :home
      # :left
      # :up
      # :right
      # :down
      # :insert
      # :delete
      # :semicolon
      # :equals
      # :numpad0
      # :numpad1
      # :numpad2
      # :numpad3
      # :numpad4
      # :numpad5
      # :numpad6
      # :numpad7
      # :numpad8
      # :numpad9
      # :multiply      - numeric keypad *
      # :add           - numeric keypad +
      # :separator     - numeric keypad 'separator' key ??
      # :subtract      - numeric keypad -
      # :decimal       - numeric keypad .
      # :divide        - numeric keypad /
      # :f1
      # :f2
      # :f3
      # :f4
      # :f5
      # :f6
      # :f7
      # :f8
      # :f9
      # :f10
      # :f11
      # :f12
      # :meta
      # :command      - alias of :meta
      #
      # @return [Capybara::Node::Element]  The element
      def send_keys(*args)
        synchronize { base.send_keys(*args) }
        return self
      end

      ##
      #
      # Hover on the Element
      #
      # @return [Capybara::Node::Element]  The element
      def hover
        synchronize { base.hover }
        return self
      end

      ##
      #
      # @return [String]      The tag name of the element
      #
      def tag_name
        synchronize { base.tag_name }
      end

      ##
      #
      # Whether or not the element is visible. Not all drivers support CSS, so
      # the result may be inaccurate.
      #
      # @return [Boolean]     Whether the element is visible
      #
      def visible?
        synchronize { base.visible? }
      end

      ##
      #
      # Whether or not the element is checked.
      #
      # @return [Boolean]     Whether the element is checked
      #
      def checked?
        synchronize { base.checked? }
      end

      ##
      #
      # Whether or not the element is selected.
      #
      # @return [Boolean]     Whether the element is selected
      #
      def selected?
        synchronize { base.selected? }
      end

      ##
      #
      # Whether or not the element is disabled.
      #
      # @return [Boolean]     Whether the element is disabled
      #
      def disabled?
        synchronize { base.disabled? }
      end

      ##
      #
      # Whether or not the element is readonly.
      #
      # @return [Boolean]     Whether the element is readonly
      #
      def readonly?
        synchronize { base.readonly? }
      end

      ##
      #
      # Whether or not the element supports multiple results.
      #
      # @return [Boolean]     Whether the element supports multiple results.
      #
      def multiple?
        synchronize { base.multiple? }
      end

      ##
      #
      # An XPath expression describing where on the page the element can be found
      #
      # @return [String]      An XPath expression
      #
      def path
        synchronize { base.path }
      end

      ##
      #
      # Trigger any event on the current element, for example mouseover or focus
      # events. Does not work in Selenium.
      #
      # @param [String] event       The name of the event to trigger
      #
      # @return [Capybara::Node::Element]  The element
      def trigger(event)
        synchronize { base.trigger(event) }
        return self
      end

      ##
      #
      # Drag the element to the given other element.
      #
      #     source = page.find('#foo')
      #     target = page.find('#bar')
      #     source.drag_to(target)
      #
      # @param [Capybara::Node::Element] node     The element to drag to
      #
      # @return [Capybara::Node::Element]  The element
      def drag_to(node)
        synchronize { base.drag_to(node.base) }
        return self
      end

      def reload
        if @allow_reload
          begin
            reloaded = query_scope.reload.first(@query.name, @query.locator, @query.options)
            @base = reloaded.base if reloaded
          rescue => e
            raise e unless catch_error?(e)
          end
        end
        self
      end

      def inspect
        %(#<Capybara::Node::Element tag="#{base.tag_name}" path="#{base.path}">)
      rescue NotSupportedByDriverError
        %(#<Capybara::Node::Element tag="#{base.tag_name}">)
      rescue => e
        raise unless session.driver.invalid_element_errors.any? { |et| e.is_a?(et) }

        %(Obsolete #<Capybara::Node::Element>)
      end

    private

      def verify_click_options_support(method)
        raise ArgumentError, "The current driver does not support #{method} options" if base.method(method).arity.zero?
      end
    end
  end
end
