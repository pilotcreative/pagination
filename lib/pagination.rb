# Loads extensions to Ruby on Rails libraries needed to support pagination and lazy loading
require 'active_record/base_extensions'
require 'active_record/scope_extensions'

# Loads
require 'action_controller/rescue_with_helper'

# Loads internal pagination classes
require 'pagination/collection'
require 'pagination/named_scope'
require 'pagination/enumerable'
require 'pagination/view_helpers'

# Loads the :paginate view helper
ActionView::Base.send :include, Pagination::ViewHelpers

# Load :rescue_with_handler - solution: https://rails.lighthouseapp.com/projects/8994/tickets/2034-exceptions-in-views-hard-to-catch
ActionController::Base.send :include, RescueWithHelper

ActionController::Base.send(:rescue_from, Pagination::InvalidPage, :with => :not_found)

def not_found
   render :file => 'public/404.html', :status => :not_found
end