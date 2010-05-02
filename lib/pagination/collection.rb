module Pagination
  class InvalidPage < ArgumentError
    def initialize(page, max = 1)
      super "#{page} must be greater than 0" if page < 1
      super "#{page} must be less than #{max}" if page >= 1
    end
  end

  class Collection < Array
    attr_reader :current_page, :per_page, :total_entries, :total_pages

    def initialize(options = {})
      @collection = options[:collection]

      if (already_paginated = ([:current_page, :per_page, :total_entries].all? { |m| @collection.respond_to?(m) }))
        @current_page = @collection.current_page
        @per_page = @collection.per_page
        self.total_entries ||= @collection.total_entries
      else
        @current_page = options[:current_page].to_i
        @per_page = options[:per_page].to_i
        self.total_entries ||= @collection.count(:id, :distinct => true)
      end

      raise InvalidPage.new(@current_page) if @current_page < 1
      raise ArgumentError, "`per_page` setting cannot be less than 1 (#{@per_page} given)" if @per_page < 1

      replace(already_paginated ? @collection : @collection.paginate(:limit => limit, :offset => offset))

      raise InvalidPage.new(current_page, total_pages) if current_page > total_pages
    end

    def previous_page
      current_page - 1 if current_page > 1
    end

    def next_page
      current_page + 1 if current_page < total_pages
    end

    def offset
      offset = (current_page-1)*limit
    end

  protected

    def limit
      per_page
    end

    def total_entries=(number)
      @total_entries = number.to_i
      @total_pages = @total_entries > 0 ? (@total_entries / per_page.to_f).ceil : 1
    end

    def replace(array)
      result = super

      # The collection is shorter then page limit? Rejoice, because
      # then we know that we are on the last page!
      if total_entries.nil? and length < per_page and (current_page == 1 or length > 0)
        self.total_entries = offset + length
      end

      result
    end
  end
end
