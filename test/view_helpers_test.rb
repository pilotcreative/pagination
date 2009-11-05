require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/lib/view_test_process'

class ViewHelpersTest < Pagination::ViewTestCase
  context "paginate method" do

    # TODO: @html_result return wrong string - two times the same, why???
#    should "test_full_output" do
#      paginate({:page => 1}, {:per_page => 4, :controls => :bottom})
#      expected = <<-HTML
#        <div class="pagination"><span class="disabled prev_page">&laquo; Previous</span>
#        <span class="current">1</span>
#        <a href="/foo/bar?page=2" rel="next">2</a>
#        <a href="/foo/bar?page=3">3</a>
#        <a href="/foo/bar?page=2" class="next_page" rel="next">Next &raquo;</a></div>
#      HTML
#      expected.strip!.gsub!(/\s{2,}/, ' ')
#
#      assert_dom_equal expected, @html_result
#    end
    
    should "show links to pages" do
      paginate do |pagination|
        assert_select 'a[href]', 3 do |elements|
          validate_page_numbers [2,3,2], elements
          assert_select elements.last, ':last-child', "Next &raquo;"
        end
        assert_select 'span', 2
        assert_select 'span.disabled:first-child', '&laquo; Previous'
        assert_select 'span.current', '1'
        assert_equal '&laquo; Previous 1 2 3 Next &raquo;', pagination.first.inner_text
      end
    end

    should "paginate with options" do
      paginate({:page => 2},
             :class => 'paginate', :previous_label => 'Prev', :next_label => 'Next') do
        assert_select 'a[href]', 4 do |elements|
          validate_page_numbers [1,1,3,3], elements
          # test rel attribute values:
          assert_select elements[1], 'a', '1' do |link|
            assert_equal 'prev start', link.first['rel']
          end
          assert_select elements.first, 'a', "Prev" do |link|
            assert_equal 'prev start', link.first['rel']
          end
          assert_select elements.last, 'a', "Next" do |link|
            assert_equal 'next', link.first['rel']
          end
        end
        assert_select 'span.current', '2'
      end
    end

    should "paginate using renderer class" do
      paginate( {}, :renderer => AdditionalLinkAttributesRenderer) do
        assert_select 'a[default=true]', 3
      end
    end

    # TODO: @html_result return wrong string - sholudnt return empty string, why???
#    should "no pagination when page count is one" do
#      paginate({:page => 1}, {:per_page => 30})
#      assert_equal '', @html_result
#    end

    should "paginate using renderer instance" do
      renderer = Pagination::LinkRenderer.new
      renderer.gap_marker = '<span class="my-gap">~~</span>'

      paginate({},  {:per_page => 2, :inner_window => 0, :outer_window => 0, :renderer => renderer}) do
        assert_select 'span.my-gap', '~~'
      end

      renderer = AdditionalLinkAttributesRenderer.new(:title => 'rendered')
      paginate({}, :renderer => renderer) do
        assert_select 'a[title=rendered]', 3
      end
    end

    should "previous next links have classnames" do
      paginate do |pagination|
        assert_select 'span.disabled.prev_page:first-child'
        assert_select 'a.next_page[href]:last-child'
      end
    end

    should "paginate without container" do
      paginate({}, :container => false)
      assert_select 'div.pagination', 0, 'main DIV present when it shouldn\'t'
    end

    should "paginate without page links" do
      paginate({:page => 2}, :page_links => false) do
        assert_select 'a[href]', 2 do |elements|
          validate_page_numbers [1,3], elements
        end
      end
    end

    should "paginate windows" do
      paginate({:page => 6}, {:per_page => 1, :inner_window => 1}) do |pagination|
        assert_select 'a[href]', 8 do |elements|
          validate_page_numbers [5,1,2,5,7,10,11,7], elements
          assert_select elements.first, 'a', '&laquo; Previous'
          assert_select elements.last, 'a', 'Next &raquo;'
        end
        assert_select 'span.current', '6'
        assert_equal '&laquo; Previous 1 2 &hellip; 5 6 7 &hellip; 10 11 Next &raquo;', pagination.first.inner_text
      end
    end

    should "paginate eliminates small gaps" do
      paginate({:page => 6}, {:per_page => 1, :inner_window => 2}) do
        assert_select 'a[href]', 12 do |elements|
          validate_page_numbers [5,1,2,3,4,5,7,8,9,10,11,7], elements
        end
      end
    end

    should "return container id" do
      paginate do |div|
        assert_nil div.first['id']
      end

      # magic ID
      paginate({}, :id => true) do |div|
        assert_equal 'fixnums_pagination', div.first['id']
      end

      # explicit ID
      paginate({}, :id => 'custom_id') do |div|
        assert_equal 'custom_id', div.first['id']
      end
    end

    should "paginate with custom page param" do
      paginate({}, {:param_name => :developers_page}) do
        assert_select 'a[href]', 4 do |elements|
          validate_page_numbers [1,1,3,3], elements, :developers_page
        end
      end
    end

    should "test_will_paginate_preserves_parameters_on_get" do
      @request.params :foo => { :bar => 'baz' }
      paginate
      assert_links_match /foo%5Bbar%5D=baz/
    end

    should "test_will_paginate_doesnt_preserve_parameters_on_post" do
      @request.post
      @request.params :foo => 'bar'
      paginate
      assert_no_links_match /foo=bar/
    end

    should "test_adding_additional_parameters" do
      paginate({}, :params => { :foo => 'bar' })
      assert_links_match /foo=bar/
    end

    should "test_adding_anchor_parameter" do
      paginate({}, :params => { :anchor => 'anchor' })
      assert_links_match /#anchor$/
    end

    should "test_removing_arbitrary_parameters" do
      @request.params :foo => 'bar'
      paginate({}, :params => { :foo => nil })
      assert_no_links_match /foo=bar/
    end

    should "test_adding_additional_route_parameters" do
      paginate({}, :params => { :controller => 'baz', :action => 'list' })
      assert_links_match %r{\Wbaz/list\W}
    end

    should "test_will_paginate_with_custom_page_param" do
      paginate({ :page => 2} , :param_name => :developers_page) do
        assert_select 'a[href]', 4 do |elements|
          validate_page_numbers [1,1,3,3], elements, :developers_page
        end
      end
    end

    should "test_will_paginate_with_atmark_url" do
      @request.symbolized_path_parameters[:action] = "@tag"
      renderer = Pagination::LinkRenderer.new

      paginate({ :page => 1 }, :renderer=>renderer)
      assert_links_match %r[/foo/@tag\?page=\d]
    end

    should "test_complex_custom_page_param" do
      @request.params :developers => { :page => 2 }

      paginate({}, :page => 2, :param_name => 'developers[page]') do
        assert_select 'a[href]', 4 do |links|
          assert_links_match /\?developers%5Bpage%5D=\d+$/, links
          validate_page_numbers [1,1,3,3], links, 'developers[page]'
        end
      end
    end

    should "test_custom_routing_page_param" do
      @request.symbolized_path_parameters.update :controller => 'dummy', :action => nil
      paginate({}, :per_page => 2) do
        assert_select 'a[href]', 6 do |links|
          assert_links_match %r{/page/(\d+)$}, links, [2, 3, 4, 5, 6, 2]
        end
      end
    end

    should "test_custom_routing_page_param_with_dot_separator" do
      @request.symbolized_path_parameters.update :controller => 'dummy', :action => 'dots'
      paginate({}, :per_page => 2) do
        assert_select 'a[href]', 6 do |links|
          assert_links_match %r{/page\.(\d+)$}, links, [2, 3, 4, 5, 6, 2]
        end
      end
    end

    should "test_custom_routing_with_first_page_hidden" do
      @request.symbolized_path_parameters.update :controller => 'ibocorp', :action => nil
      paginate({:page => 2}, :per_page => 2) do
        assert_select 'a[href]', 7 do |links|
          assert_links_match %r{/ibocorp(?:/(\d+))?$}, links, [nil, nil, 3, 4, 5, 6, 3]
        end
      end
    end

  end
end

class AdditionalLinkAttributesRenderer < Pagination::LinkRenderer
  def initialize(link_attributes = nil)
    super()
    @additional_link_attributes = link_attributes || { :default => 'true' }
  end

  def page_link(page, text, attributes = {})
    @template.link_to text, url_for(page), attributes.merge(@additional_link_attributes)
  end
end