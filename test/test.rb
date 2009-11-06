require File.dirname(__FILE__) + '/test_helper'
require 'action_view/test_case'
require 'pagination'

ActionController::Base.perform_caching = false

class Pagination::ViewHelpersTest < ActionView::TestCase
  context "pagination" do
    setup do
      @collection = [1,2,3,4,5,6,7,8,9,10]
      self.stubs(:controller).returns(ActionController::Base.new)
      @request = controller.request
    end
    should "return html" do
      expected = <<-HTML
        <div class="pagination"><span class="disabled prev_page">&laquo; Previous</span>
        <span class="current">1</span>
        <a href="/foo/bar?page=2" rel="next">2</a>
        <a href="/foo/bar?page=3">3</a>
        <a href="/foo/bar?page=2" class="next_page" rel="next">Next &raquo;</a></div>
      HTML
      expected.strip!.gsub!(/\s{2,}/, ' ')

      @request.params :page => 2

      assert_dom_equal expected, paginate(@collection, {:per_page => 4})
    end
  end

end
