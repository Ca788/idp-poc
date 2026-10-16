# frozen_string_literal: true

module ApiPagination
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  def paginate(scope)
    per_page = [params[:per_page].to_i, MAX_PER_PAGE].min
    per_page = DEFAULT_PER_PAGE if per_page <= 0
    scope.page(params[:page]).per(per_page)
  end
end
