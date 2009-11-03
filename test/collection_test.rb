require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__)+'/../lib/pagination/collection'
require File.dirname(__FILE__)+'/../lib/pagination/enumerable'

class CollectionTest < Test::Unit::TestCase
  context "collection test" do
    setup do
      @collection = ('a'..'e').to_a
    end

    should "return elements from specific range" do
      # see: enumerable.rb
      # limit = per_page
      # offset = (current_page - 1) * limit
      [
        { :offset => 0,  :limit => 3,  :expected => %w( a b c ) },
        { :offset => 3,  :limit => 3,  :expected => %w( d e ) },
        { :offset => 0,  :limit => 5,  :expected => %w( a b c d e ) },
        { :offset => 6,  :limit => 3,  :expected => [] },
      ].
      each do |conditions|
        expected = conditions.delete :expected
        assert_equal expected, @collection.paginate(conditions)
      end
    end
  
    context "init pagination collection" do
      setup do
        @user = User.new :first_name => 'Bob', :last_name => 'Builder'
        @user.save!
        5.times{ |i|
          article = Article.new :title => "title_#{i}", :user => @user
          article.save!
        }

        @paginated_collection = paginate_collection(@user.articles)
      end

      should "return total pages" do
        assert_equal 3, @paginated_collection.total_pages
      end

      should "return previous page" do
        assert_equal 1, @paginated_collection.previous_page
      end

      should "return next page" do
        assert_equal 3, @paginated_collection.next_page
      end

      should "rise an error InvalidPage" do
        assert_raise(Pagination::InvalidPage) { paginate_collection(@user.articles, -2, 2) }
      end

      should "rise an error ArgumentError" do
        assert_raise(ArgumentError) { paginate_collection(@user.articles, 2, -2) }
      end
    end
  end
  
  private
    def paginate_collection(collection, current_page=2, per_page=2, total_entries=nil)
      Pagination::Collection.new(
            :collection => collection,
            :current_page => current_page,
            :per_page => per_page,
            :total_entries => total_entries
          )
    end
end