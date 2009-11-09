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
      users = User.all(:conditions => {:first_name => 'Bob'})
      assert_equal [@user,@user2], users
      assert_equal users, User.find_every_with_scope(:conditions => {:first_name => 'Bob'})
    end

    should "lazy loading" do
      articles = Article.all(:select => "title")
      assert_nil articles[1].user
    end

    should "run lazy loading for name scope" do
      bobs = User.bob.all(:eager => true, :conditions => {:last_name => 'Builder2'})
      assert_equal 3, bobs.first.articles.count
    end

    should "return all users" do
      User.expects(:all).returns(User.find_every_with_scope({}))
      assert_equal 3, User.all.count
    end

    should "respond to active record extentions" do
      assert User.respond_to?(:find_every_with_scope)
      assert Article.respond_to?(:find_initial_with_eager_loading)
    end

  end
end
