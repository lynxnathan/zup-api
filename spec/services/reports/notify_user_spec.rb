require "spec_helper"

describe Reports::NotifyUser do
  let!(:item) { create(:reports_item) }
  let(:user) { item.user }
  let!(:status) { create(:status,
                        initial: false,
                        final: false,
                        title: 'Relato em andamento') }

  before do
    # Add status to category
    status.status_categories.create(
      category: item.category
    )

    user.groups = Group.guest
    user.save!
  end

  subject { described_class.new(item) }

  describe "#should_user_receive_status_notification?" do
    context "status isn't private" do
      it "returns true" do
        expect(
          subject.should_user_receive_status_notification?(status)
        ).to be_truthy
      end
    end

    context "status is private" do
      before do
        status.status_categories.find_by(
          category: item.category
        ).update(private: true)
      end

      it "returns false" do
        expect(
          subject.should_user_receive_status_notification?(status)
        ).to be_falsy
      end
    end

    context "user has permissions to manage reports items" do
      let(:group) { create(:group) }

      before do
        group.permission.update(manage_reports: true)
        item.user.groups = [group]
        item.user.save!
      end

      it "returns true" do
        expect(
          subject.should_user_receive_status_notification?(status)
        ).to be_truthy
      end
    end
  end
end
