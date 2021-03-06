class Reports::SearchItems
  attr_reader :category, :user,
              :inventory_item, :position_params,
              :statuses, :begin_date,
              :end_date, :limit,
              :group_by_inventory_item, :sort,
              :order, :paginator, :page,
              :per_page, :address, :query,
              :signed_user, :overdue, :clusterize, :zoom

  def initialize(user, opts = {})
    @position_params = opts[:position]
    @address         = opts[:address]
    @category        = opts[:category] || []
    @inventory_item  = opts[:inventory_item]
    @user            = opts[:user]
    @query           = opts[:query]
    @limit           = opts[:limit]
    @begin_date      = opts[:begin_date]
    @end_date        = opts[:end_date]
    @statuses        = opts[:statuses]
    @overdue         = opts[:overdue]
    @sort            = opts[:sort] || "created_at"
    @order           = opts[:order] || "desc"
    @paginator       = opts[:paginator]
    @group_by_inventory_item = opts[:group_by_inventory_item]
    @page            = opts[:page] || 1
    @per_page        = opts[:per_page] || 25
    @signed_user     = user
    @clusterize      = opts[:clusterize] || false
    @zoom            = opts[:zoom]
  end

  def search
    scope = Reports::Item.all
    scope = scope.includes(:user)
    scope = scope.includes(:images)
    scope = scope.includes(:category)
    scope = scope.includes(:inventory_item)

    permissions = UserAbility.new(signed_user)

    if inventory_item
      scope = scope.where(inventory_item_id: inventory_item.id)
    end

    if group_by_inventory_item
      # Select only unique inventory_item_id
      scope = scope.select(
        <<-SQL
          DISTINCT ON (COALESCE(inventory_item_id, id)) reports_items.*
        SQL
      )
    end

    if query
      scope = scope.joins(:user).like_search(
        "users.name" => query,
        address: query,
        protocol: query
      )
    end

    if user
      if user.kind_of?(Array)
        users_ids = user.map { |u| u.id }
      elsif user.kind_of?(User)
        users_ids = user.id
      end

      scope = scope.where(user_id: users_ids)
    end

    if category
      if category.kind_of?(Array)
        categories_ids = category.map { |c| c.id }
      elsif category.kind_of?(Reports::Category)
        categories_ids = [category.id]
      end
    end

    if !permissions.can?(:manage, Reports::Category)
      categories_user_can_see = permissions.reports_categories_visible

      if categories_ids.any?
        categories_ids = categories_user_can_see & categories_ids
      else
        categories_ids = categories_user_can_see
      end

      scope = scope.where(reports_category_id: categories_ids)
    elsif categories_ids.any?
      scope = scope.where(reports_category_id: categories_ids)
    end

    if position_params
      if clusterize
        position_params[:distance] = position_params[:distance].to_f * 2
      end

      scope = Reports::SearchItemsByGeolocation.new(
        scope, position_params, address
      ).scope_with_filters
    elsif address
      scope = scope.like_search(address: address)
    end

    if limit
      scope = scope.limit(limit)
    end

    if begin_date || end_date
      if begin_date && end_date
        scope = scope.where('reports_items.created_at' => begin_date..end_date)
      elsif begin_date
        scope = scope.where("reports_items.created_at >= ?", begin_date)
      elsif end_date
        scope = scope.where("reports_items.created_at <= ?", end_date)
      end
    end

    if overdue
      scope = scope.where(overdue: overdue)
    end

    if statuses
      scope = scope.where('reports_status_id IN (?)', statuses.map(&:id))
    end

    # WTF
    sort = self.sort
    if sort && !clusterize &&
        %w(created_at updated_at id reports_status_id user_name).include?(sort) &&
        order.downcase.in?('desc', 'asc')

      if sort == 'user_name'
        sort = 'users.name'
      elsif sort == 'id'
        sort = 'scope.id'
      end

      scope = Reports::Item.find_by_sql(
        <<-SQL
          SELECT scope.*
          FROM (#{scope.to_sql}) scope
          INNER JOIN users
          ON users.id = scope.user_id
          ORDER BY #{sort} #{order.upcase}
        SQL
      )

      if paginator.present?
        scope = paginator.call(scope)
      end
    elsif position_params.blank?
      scope = scope.paginate(page: page, per_page: per_page)
    end

    if position_params && clusterize
      Reports::ClusterizeItems.new(scope, zoom).results
    else
      scope
    end
  end
end
