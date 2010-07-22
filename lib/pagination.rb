# Loads internal pagination classes
require 'pagination/collection'
require 'pagination/relation'
require 'pagination/enumerable'
require 'pagination/view_helpers'

# Loads the :paginate view helper
ActionView::Base.send :include, Pagination::ViewHelpers
