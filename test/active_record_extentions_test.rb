require File.dirname(__FILE__) + '/test_helper'
require 'active_record/base_extensions'
require 'active_record/scope_extensions'
require 'mocha'


class ActiveRecordExtentionsTest < Test::Unit::TestCase
  context "active record extentions" do
    setup do
      User.delete_all
      Article.delete_all
      
      @user1 = User.create :first_name => 'Bob', :last_name => 'Builder'
      @user2 = User.create :first_name => 'Bob', :last_name => 'Builder2'
      @user3 = User.create :first_name => 'Tom', :last_name => 'Builder'
      
      5.times do |i|
        Article.create(:title => "title_#{i}", :user => @user1)
      end
      
      3.times do |i|
        Article.create!(:title => "2title_#{i}", :user => @user2)
      end
    end

    should "return the same results with find_every_with_scope and find_every_without_scope" do
      assert_equal User.send(:find_every_with_scope, {}),
                   User.send(:find_every_without_scope, {})

      assert_equal User.send(:find_every_with_scope, :conditions => {:first_name => "Bob"}),
                   User.send(:find_every_without_scope, :conditions => {:first_name => "Bob"})
    end

    should "return ActiveRecord::NamedScope::Scope" do
      assert_equal ActiveRecord::NamedScope::Scope, User.all.class
      assert_equal ActiveRecord::NamedScope::Scope, User.all(:conditions => {:first_name => 'Bob'}).class
    end

    should "return an Array when called with :eager => true" do
      assert_equal Array, Article.all(:eager => true).class
      assert_equal Array, Article.all(:eager => true, :conditions => {:title => "title_1"}).class
    end
  end
end
