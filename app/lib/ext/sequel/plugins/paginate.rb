module Sequel::Plugins::Paginate
  module DatasetMethods
    def paginate(page, per_page: 20)
      page = (page || 1).to_i || 1

      extension(:pagination).paginate(page, per_page)
    end
  end
end
