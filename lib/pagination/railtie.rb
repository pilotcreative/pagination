module Pagination
  class Railtie < Rails::Railtie
    initializer "pagination.initialization" do
      # Loads internal pagination classes
      require 'pagination/collection'
      require 'pagination/relation'
      require 'pagination/enumerable'
      require 'pagination/view_helpers'

      # Loads the :paginate view helper
      ActionView::Base.send :include, Pagination::ViewHelpers

      I18n::Railtie.config.after_initialize do
        Pagination::ViewHelpers.pagination_options.merge!({
          :previous_label => I18n.t('pagination.previous', :default => "Previous"),
          :next_label => I18n.t('pagination.next', :default => "Next")
        })
      end
    end
  end
end