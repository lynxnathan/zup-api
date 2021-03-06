module Reports
  class GetCommentsForUser
    attr_reader :item, :user

    def initialize(item, user)
      @item, @user = item, user
    end

    def comments
      return [] if item.comments.count == 0
      comments = item.comments.with_visibility(visibility)
    end

    private

    def visibility
      user_permissions = UserAbility.new(user)

      if user_permissions.can?(:view, item) && user_permissions.can?(:edit, item)
        Reports::Comment::INTERNAL
      elsif user.id == item.user_id
        Reports::Comment::PRIVATE
      else
        Reports::Comment::PUBLIC
      end
    end
  end
end
