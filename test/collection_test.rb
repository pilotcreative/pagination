require File.dirname(__FILE__) + '/test_helper'
require File.dirname(__FILE__) + '/../lib/pagination/collection'
require File.dirname(__FILE__) + '/../lib/pagination/enumerable'

class CollectionTest < Test::Unit::TestCase
  context "collection test" do
    setup do
      Article.destroy_all
      5.times {|i| Article.create!(:id => i, :user => User.create)}
      @collection = Article.all
    end

    should "return elements from specific range" do
      # see: enumerable.rb
      # limit = per_page
      # offset = (current_page - 1) * limit
      [
        { :offset => 0,  :limit => 3,  :expected => [@collection[0],@collection[1], @collection[2]] },
        { :offset => 3,  :limit => 3,  :expected => [@collection[3],@collection[4]] },
        { :offset => 0,  :limit => 5,  :expected => [@collection[0],@collection[1], @collection[2], @collection[3], @collection[4]] },
        { :offset => 6,  :limit => 3,  :expected => [] },
      ].
      each do |conditions|
        expected = conditions.delete :expected
        assert_equal expected, @collection.paginate(conditions)
      end
    end

    context "init pagination collection" do
      setup do
        @paginated_collection = paginate_collection(@collection)
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

      should "array be shorter after paginate" do
        pag_array = paginate_collection(@collection, 1, 4)
        assert_not_equal  @collection, pag_array.count
        assert_equal 4, pag_array.count
      end

      should "rise an error InvalidPage" do
        assert_raise(Pagination::InvalidPage) { paginate_collection(@collection, -2, 2) }
        assert_raise(Pagination::InvalidPage) { paginate_collection(@collection, 1000, 2) }
      end

      should "rise an error ArgumentError" do
        assert_raise(ArgumentError) { paginate_collection(@collection, 2, -2) }
      end
    end

    context "collection is empty" do
      setup do
        @collection = []
        @paginated_collection = paginate_collection(@collection, 1, 1)
      end

      should "return total entries equal 0" do
        assert_equal @paginated_collection.total_entries, 0
      end
    end
    
    context "having already paginated collection" do
      setup do
        @collection = (11..20).to_a
        class << @collection
          def total_entries; 100; end
          def current_page; 2; end
          def per_page; 10; end
        end

        @paginated_collection = paginate_collection(@collection, 1, 1, 1)
      end

      should "use attribute values of the original collection" do
        assert_equal @collection, @paginated_collection
        assert_equal @collection.total_entries, @paginated_collection.total_entries
        assert_equal @collection.current_page, @paginated_collection.current_page
        assert_equal @collection.per_page, @paginated_collection.per_page
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
