require File.dirname(__FILE__) + '/test_helper'
require 'active_record/base_extensions'
require 'active_record/scope_extensions'

class ActiveRecordExtentionsTest < Test::Unit::TestCase
  context "active record extentions" do
    setup do
      User.delete_all
      Article.delete_all
      
      @user = User.create :first_name => 'Bob', :last_name => 'Builder'
      @user2 = User.create :first_name => 'Bob', :last_name => 'Builder2'
      @user3 = User.create :first_name => 'Tom', :last_name => 'Builder'
      5.times{ |i|
        article = Article.new :title => "title_#{i}", :user => @user
        article.save!
      }
      
      3.times{ |i|
        article = Article.new :title => "2title_#{i}", :user => @user2
        article.save!
      }
    end

    should "return users from scope where first_name is Bob" do
      users_tab = User.find_every_with_scope(:conditions => {:first_name => 'Bob'})
      assert_equal [@user,@user2], users_tab
    end

    should "return users from scope where last_name is Builder" do
      users_tab = User.find_every_with_scope(:conditions => {:last_name => 'Builder'})
      assert_equal [@user, @user3], users_tab
    end

    should "return articles from scope without options" do
      articles_tab = Article.find_every_with_scope({})
      assert_equal 8, articles_tab.count
    end

    should "check scope extensions" do
      entries = User.bob.paginate(:offset => 0, :limit => 2)
      assert_equal 2, entries.size
    end

    should "return articles after pagination" do
      articles_tab = Article.find_every_with_scope({}).paginate(:limit => 2, :offset => 0)
      assert_equal 8, articles_tab.count
    end

    should "loading lazy" do
       articles_tab = Article.find_initial_with_eager_loading(:conditions => {:user_id => @user2.id})
       assert_equal @user2.articles.first, articles_tab
    end

  end
end
