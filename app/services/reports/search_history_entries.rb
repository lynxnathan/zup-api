module Reports
  class SearchHistoryEntries
    attr_reader :item_id, :kind, :created_at, :user_id, :object_id

    def initialize(params = {})
      @item_id = params[:item_id]
      @kind = params[:kind]
      @created_at = params[:created_at]
      @user_id = params[:user_id]
      @object_id = params[:object_id]
    end

    def search
      scope = Reports::ItemHistory

      if item_id
        scope = scope.where(reports_item_id: item_id)
      end

      if user_id
        scope = scope.where(user_id: user_id)
      end

      if kind
        scope = scope.where(kind: kind)
      end

      if object_id
        # TODO: This `objects_ids` column name info should be get from ArrayRelate
        scope = scope.where('? = ANY(reports_item_histories.objects_ids)', object_id)
      end

      if created_at && (created_at[:begin] || created_at[:end])
        begin_date = created_at[:begin]
        end_date = created_at[:end]

        if begin_date && end_date
          scope = scope.where(reports_item_histories: { created_at: begin_date..end_date })
        elsif begin_date
          scope = scope.where("reports_item_histories.created_at >= ?", begin_date)
        elsif end_date
          scope = scope.where("reports_item_histories.created_at <= ?", end_date)
        end
      end

      scope
    end
  end
end
