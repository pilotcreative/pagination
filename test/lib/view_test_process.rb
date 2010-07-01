gem 'actionpack', '2.3.5'
require 'action_controller'
require 'action_controller/test_process'

require 'pagination'

ActionController::Routing::Routes.draw do |map|
  map.connect 'dummy/page/:page', :controller => 'dummy'
  map.connect 'dummy/dots/page.:page', :controller => 'dummy', :action => 'dots'
  map.connect 'ibocorp/:page', :controller => 'ibocorp',
                               :requirements => { :page => /\d+/ },
                               :defaults => { :page => 1 }

  map.connect ':controller/:action/:id'
end

ActionController::Base.perform_caching = false

class Pagination::ViewTestCase < Test::Unit::TestCase
  if defined?(ActionController::TestCase::Assertions)
    include ActionController::TestCase::Assertions
  end
  if defined?(ActiveSupport::Testing::Deprecation)
    include ActiveSupport::Testing::Deprecation
  end

  def setup
    super
    @controller  = DummyController.new
    @request     = @controller.request
    @html_result = nil
    @template    = '<%= paginate collection, options do |tmp|; tmp.each do |t|; end; end %>'

    @view = ActionView::Base.new
    @view.assigns['controller'] = @controller
    @view.assigns['_request']   = @request
    @view.assigns['_params']  = @request.params
  end

  def default_test; end

  protected

    def paginate(collection = {}, options = {}, &block)

      Article.destroy_all
      11.times {|i| Article.create!(:id => i, :user => User.create)}

      if collection.instance_of? Hash
        @request.params :page => collection[:page] || 1
        collection = Article.all
      end
      options = {:per_page => 4, :controls => :top}.merge(options)

      locals = { :collection => collection, :options => options }

      unless @view.respond_to? :render_template
        # Rails 2.2
        @html_result = ActionView::InlineTemplate.new(@template).render(@view, locals)
      else
        if defined? ActionView::InlineTemplate
          # Rails 2.1
          args = [ ActionView::InlineTemplate.new(@view, @template, locals) ]
        else
          # older Rails versions
          args = [nil, @template, nil, locals]
        end

        @html_result = @view.render_template(*args)
      end

      @html_document = HTML::Document.new(@html_result, true, false)

      if block_given?
        classname = options[:class] || Pagination::ViewHelpers.pagination_options[:class]
        assert_select("div.#{classname}",1 , 'no main DIV', &block)
      end

    end

    def response_from_page_or_rjs
      @html_document.root
    end

    def validate_page_numbers expected, links, param_name = :page
      param_pattern = /\W#{CGI.escape(param_name.to_s)}=([^&]*)/

      assert_equal(expected, links.map { |e|
        e['href'] =~ param_pattern
        $1 ? $1.to_i : $1
      })
    end

    def assert_links_match pattern, links = nil, numbers = nil
      links ||= assert_select 'div.pagination a[href]' do |elements|
        elements
      end

      pages = [] if numbers

      links.each do |el|
        assert_match pattern, el['href']
        if numbers
          el['href'] =~ pattern
          pages << ($1.nil?? nil : $1.to_i)
        end
      end

      assert_equal numbers, pages, "page numbers don't match" if numbers
    end

    def assert_no_links_match pattern
      assert_select 'div.pagination a[href]' do |elements|
        elements.each do |el|
          assert_no_match pattern, el['href']
        end
      end
    end
end

class DummyRequest
  attr_accessor :symbolized_path_parameters

  def initialize
    @get = true
    @params = {}
    @symbolized_path_parameters = { :controller => 'foo', :action => 'bar'}
  end

  def get?
    @get
  end

  def post
    @get = false
  end

  def relative_url_root
    ''
  end

  def params(more = nil)
    @params.update(more) if more
    @params
  end
end

class DummyController
  attr_reader :request
  attr_accessor :controller_name

  def initialize
    @request = DummyRequest.new
    @url = ActionController::UrlRewriter.new(@request, @request.params)
  end

  def params
    @request.params
  end

  def url_for(params)
    @url.rewrite(params)
  end
end

module HTML
  Node.class_eval do
    def inner_text
      children.map(&:inner_text).join('')
    end
  end

  Text.class_eval do
    def inner_text
      self.to_s
    end
  end

  Tag.class_eval do
    def inner_text
      childless?? '' : super
    end
  end
end
