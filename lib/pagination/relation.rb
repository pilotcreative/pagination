ActiveRecord::Relation.class_eval do
  def paginate(options = {})
    limit(options[:limit]).offset(options[:offset])
  end

  def _count
    count(:id, :distinct => true)
  end
end