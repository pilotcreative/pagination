require File.dirname(__FILE__) + '/test_helper'
require 'active_record/base_extensions'
require 'active_record/scope_extensions'
require 'mocha'


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

    should "call find_every when call all" do
      Article.expects(:find_every).returns(Article.all)
    end

    should "difference between Article.find_every_with_scope and Article.find_every_without_scope" do
      users1 = User.all
      users2 = User.all(:eager => true)
      assert_equal users1, users2
      assert_not_equal users1.class, users2.class

      users1 = User.all(:conditions => {:first_name => 'Bob'})
      users2 = User.all(:eager => true, :conditions => {:first_name => 'Bob'})
      assert_equal users1, users2
      assert_not_equal users1.class, users2.class
    end

    should "all returns class ActiveRecord::NamedScope::Scope" do
      assert_equal ActiveRecord::NamedScope::Scope, User.all.class
      assert_equal ActiveRecord::NamedScope::Scope, User.all(:conditions => {:first_name => 'Bob'}).class
    end

    should "all with eager returns Array" do
      assert_equal Array, Article.all(:eager => true).class
      assert_equal Array, Article.all(:eager => true, :conditions => {:user_id => @user.id}).class
    end
    
  end
end
