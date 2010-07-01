# Loads extensions to Ruby on Rails libraries needed to support pagination and lazy loading
require 'active_record/base_extensions'
require 'active_record/scope_extensions'

# Loads internal pagination classes
require 'pagination/collection'
require 'pagination/named_scope'
require 'pagination/enumerable'
require 'pagination/view_helpers'

# Loads the :paginate view helper
ActionView::Base.send :include, Pagination::ViewHelpers

if defined?(ActionController::Base) and ActionController::Base.respond_to? :rescue_responses
  ActionController::Base.rescue_responses['Pagination::InvalidPage'] = :not_found
end