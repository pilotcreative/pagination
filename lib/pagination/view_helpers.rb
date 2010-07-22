module Pagination
  # = Pagination view helpers
  #
  # The main view helper, #paginate, renders
  # pagination links around (top and bottom) given collection. The helper itself is lightweight
  # and serves only as a wrapper around LinkRenderer instantiation; the
  # renderer then does all the hard work of generating the HTML.
  #
  # == Global options for helpers
  #
  # Options for pagination helpers are optional and get their default values from the
  # <tt>Pagination::ViewHelpers.pagination_options</tt> hash. You can write to this hash to
  # override default options on the global level:
  #
  #   Pagination::ViewHelpers.pagination_options[:previous_label] = 'Previous page'
  #
  # By putting this into "config/initializers/pagination.rb" (or simply environment.rb in
  # older versions of Rails) you can easily translate link texts to previous
  # and next pages, as well as override some other defaults to your liking.
  module ViewHelpers
    # default options that can be overridden on the global level
    @@pagination_options = {
      :class          => 'pagination',
      :previous_label => '&laquo; Previous',
      :next_label     => 'Next &raquo;',
      :inner_window   => 4, # links around the current page
      :outer_window   => 1, # links around beginning and end
      :separator      => ' ', # single space is friendly to spiders and non-graphic browsers
      :controls       => :both,
      :per_page       => 10,
      :param_name     => :page,
      :params         => nil,
      :renderer       => 'Pagination::LinkRenderer',
      :page_links     => true,
      :container      => true
    }
    mattr_reader :pagination_options

    # Renders Digg/Flickr-style pagination for a Pagination::Collection
    # object. Nil is returned if there is only one page in total; no point in
    # rendering the pagination in that case...
    #
    # ==== Options
    # Display options:
    # * <tt>:previous_label</tt> -- default: "« Previous" (this parameter is called <tt>:prev_label</tt> in versions <b>2.3.2</b> and older!)
    # * <tt>:next_label</tt> -- default: "Next »"
    # * <tt>:page_links</tt> -- when false, only previous/next links are rendered (default: true)
    # * <tt>:inner_window</tt> -- how many links are shown around the current page (default: 4)
    # * <tt>:outer_window</tt> -- how many links are around the first and the last page (default: 1)
    # * <tt>:separator</tt> -- string separator for page HTML elements (default: single space)
    # * <tt>:controls</tt> -- display controls only at the <tt>:top</tt> or <tt>:bottom</tt> of the pagination block (default: <tt>:both</tt>)
    # * <tt>:per_page</tt> -- number of items displayed per page (default: 10)
    #
    # HTML options:
    # * <tt>:class</tt> -- CSS class name for the generated DIV (default: "pagination")
    # * <tt>:container</tt> -- toggles rendering of the DIV container for pagination links, set to
    #   false only when you are rendering your own pagination markup (default: true)
    # * <tt>:id</tt> -- HTML ID for the container (default: nil). Pass +true+ to have the ID
    #   automatically generated from the class name of objects in collection: for example, paginating
    #   ArticleComment models would yield an ID of "article_comments_pagination".
    #
    # Advanced options:
    # * <tt>:param_name</tt> -- parameter name for page number in URLs (default: <tt>:page</tt>)
    # * <tt>:params</tt> -- additional parameters when generating pagination links
    #   (eg. <tt>:controller => "foo", :action => nil</tt>)
    # * <tt>:renderer</tt> -- class name, class or instance of a link renderer (default:
    #   <tt>Pagination::LinkRenderer</tt>)
    #
    # All options not recognized by paginate will become HTML attributes on the container
    # element for pagination links (the DIV). For example:
    #
    #   <% paginate @posts, :style => 'font-size: small' do |posts| %>
    #     ...
    #   <% end %>
    #
    # ... will result in:
    #
    #   <div class="pagination" style="font-size: small"> ... </div>
    #
    def paginate(collection = [], options = {}, &block)
      options = options.symbolize_keys.reverse_merge Pagination::ViewHelpers.pagination_options

      collection = Pagination::Collection.new(options.merge(:collection => collection, :current_page => params[options[:param_name]]|| 1))

      # get the renderer instance
      renderer = case options[:renderer]
      when String
        options[:renderer].to_s.constantize.new
      when Class
        options[:renderer].new
      else
        options[:renderer]
      end

      # render HTML for pagination
      renderer.prepare collection, options, self
      pagination = renderer.to_html.to_s

      if block_given?
        yield collection and return nil unless collection.total_pages > 1

        top = [:top, :both].include?(options[:controls]) ? pagination : ""
        bottom = [:bottom, :both].include?(options[:controls]) ? pagination : ""
        return top + capture { yield collection } + bottom
      else
        collection
      end
    end
  end

  # This class does the heavy lifting of actually building the pagination
  # links. It is used by the <tt>paginate</tt> helper internally.
  class LinkRenderer

    # The gap in page links is represented by:
    #
    #   <span class="gap">&hellip;</span>
    attr_accessor :gap_marker

    def initialize
      @gap_marker = '<span class="gap">&hellip;</span>'
    end

    # * +collection+ is a Pagination::Collection instance or any other object
    #   that conforms to that API
    # * +options+ are forwarded from +paginate+ view helper
    # * +template+ is the reference to the template being rendered
    def prepare(collection, options, template)
      @collection = collection
      @options    = options
      @template   = template

      # reset values in case we're re-using this instance
      @total_pages = @param_name = @url_string = nil
    end

    # Process it! This method returns the complete HTML string which contains
    # pagination links. Feel free to subclass LinkRenderer and change this
    # method as you see fit.
    def to_html
      links = @options[:page_links] ? windowed_links : []
      # previous/next buttons
      links.unshift page_link_or_span(@collection.previous_page, 'disabled prev_page', @options[:previous_label])
      links.push    page_link_or_span(@collection.next_page,     'disabled next_page', @options[:next_label])

      html = links.join(@options[:separator]).html_safe
      @options[:container] ? @template.content_tag(:div, html, html_attributes) : html
    end

    # Returns the subset of +options+ this instance was initialized with that
    # represent HTML attributes for the container element of pagination links.
    def html_attributes
      return @html_attributes if @html_attributes
      @html_attributes = @options.except *(Pagination::ViewHelpers.pagination_options.keys - [:class])
      # pagination of Post models will have the ID of "posts_pagination"
      if @options[:container] and @options[:id] === true
        @html_attributes[:id] = @collection.first.class.name.underscore.pluralize + '_pagination'
      end
      @html_attributes
    end

  protected

    # Collects link items for visible page numbers.
    def windowed_links
      prev = nil

      visible_page_numbers.inject [] do |links, n|
        # detect gaps:
        links << gap_marker if prev and n > prev + 1
        links << page_link_or_span(n, 'current')
        prev = n
        links
      end
    end

    # Calculates visible page numbers using the <tt>:inner_window</tt> and
    # <tt>:outer_window</tt> options.
    def visible_page_numbers
      inner_window, outer_window = @options[:inner_window].to_i, @options[:outer_window].to_i
      window_from = current_page - inner_window
      window_to = current_page + inner_window

      # adjust lower or upper limit if other is out of bounds
      if window_to > total_pages
        window_from -= window_to - total_pages
        window_to = total_pages
      end
      if window_from < 1
        window_to += 1 - window_from
        window_from = 1
        window_to = total_pages if window_to > total_pages
      end

      visible   = (1..total_pages).to_a
      left_gap  = (2 + outer_window)...window_from
      right_gap = (window_to + 1)...(total_pages - outer_window)
      visible  -= left_gap.to_a  if left_gap.last - left_gap.first > 1
      visible  -= right_gap.to_a if right_gap.last - right_gap.first > 1

      visible
    end

    def page_link_or_span(page, span_class, text = nil)
      text ||= page.to_s

      if page and page != current_page
        classnames = span_class && span_class.index(' ') && span_class.split(' ', 2).last
        page_link page, text, :rel => rel_value(page), :class => classnames
      else
        page_span page, text, :class => span_class
      end
    end

    def page_link(page, text, attributes = {})
      @template.link_to text, url_for(page), attributes
    end

    def page_span(page, text, attributes = {})
      @template.content_tag :span, text, attributes
    end

    # Returns URL params for +page_link_or_span+, taking the current GET params
    # and <tt>:params</tt> option into account.
    def url_for(page)
      page_one = page == 1
      unless @url_string and !page_one
        @url_params = {}
        # page links should preserve GET parameters
        stringified_merge @url_params, @template.params if @template.request.get?
        stringified_merge @url_params, @options[:params] if @options[:params]

        if complex = param_name.index(/[^\w-]/)
          page_param = parse_query_parameters("#{param_name}=#{page}")

          stringified_merge @url_params, page_param
        else
          @url_params[param_name] = page_one ? 1 : 2
        end

        url = @template.url_for(@url_params)
        return url if page_one

        if complex
          @url_string = url.sub(%r!((?:\?|&amp;)#{CGI.escape param_name}=)#{page}!, "\\1\0")
          return url
        else
          @url_string = url
          @url_params[param_name] = 3
          @template.url_for(@url_params).split(//).each_with_index do |char, i|
            if char == '3' and url[i, 1] == '2'
              @url_string[i] = "\0"
              break
            end
          end
        end
      end
      # finally!
      @url_string.sub "\0", page.to_s
    end

  private

    def rel_value(page)
      case page
      when @collection.previous_page; 'prev' + (page == 1 ? ' start' : '')
      when @collection.next_page; 'next'
      when 1; 'start'
      end
    end

    def current_page
      @current_page ||= @collection.current_page
    end

    def total_pages
      @total_pages ||= @collection.total_pages
    end

    def param_name
      @param_name ||= @options[:param_name].to_s
    end

    # Recursively merge into target hash by using stringified keys from the other one
    def stringified_merge(target, other)
      other.each do |key, value|
        key = key.to_s # this line is what it's all about!
        existing = target[key]

        if value.is_a?(Hash) and (existing.is_a?(Hash) or existing.nil?)
          stringified_merge(existing || (target[key] = {}), value)
        else
          target[key] = value
        end
      end
    end

    def parse_query_parameters(params)
      if defined? Rack::Utils
        # For Rails > 2.3
        Rack::Utils.parse_nested_query(params)
      elsif defined?(ActionController::AbstractRequest)
        ActionController::AbstractRequest.parse_query_parameters(params)
      elsif defined?(ActionController::UrlEncodedPairParser)
        # For Rails > 2.2
        ActionController::UrlEncodedPairParser.parse_query_parameters(params)
      elsif defined?(CGIMethods)
        CGIMethods.parse_query_parameters(params)
      else
        raise "unsupported ActionPack version"
      end
    end
  end
end