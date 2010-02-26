require 'rubygems'
gem 'test-unit', '1.2.3'
require 'test/unit'
gem 'activerecord', '2.3.5'
require 'active_record'
require 'shoulda'
require 'logger'


ActiveRecord::Base.configurations = {'sqlite3' => {:adapter => 'sqlite3', :database => ':memory:'}}
ActiveRecord::Base.establish_connection('sqlite3')

ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::WARN

ActiveRecord::Schema.define(:version => 0) do
  create_table :users do |t|
    t.string :first_name, :default => ''
    t.string :last_name, :default => ''
  end

  create_table :articles do |t|
    t.string :title, :default => ''
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
  has_many :articles
  named_scope :bob, :conditions => {:first_name => 'Bob'}

  def find_all
    User.find_all
  end
end

class Article < ActiveRecord::Base
  belongs_to :user
end
