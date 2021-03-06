require "spec_helper"

describe Reports::StatusControl do
  let(:category) { create(:reports_category_with_statuses) }

  subject { described_class.new(item) }

  describe "#overdue?" do
    let(:item) { create(:reports_item, category: category) }

    context "item isn't on final status" do
      before do
        other_status = category.status_categories.where.not(
          final: true
        ).first.status
        Reports::UpdateItemStatus.new(item).update_status!(other_status)
      end

      context "item is on initial status older than resolution time" do
        before do
          item.status_history.first.update(created_at: (category.resolution_time + 1.minute).seconds.ago)
        end

        it "returns true" do
          expect(subject.overdue?).to be_truthy
        end
      end

      context "item is on initial status newer than resolution time" do
        before do
          item.status_history.first.update(created_at: (category.resolution_time - 1.minute).seconds.ago)
        end

        it "returns false" do
          expect(subject.overdue?).to be_falsy
        end
      end
    end

    context "category doesn't have a resolution time set" do
      before do
        category.update(resolution_time: nil)
      end

      it "returns false" do
        expect(subject.overdue?).to be_falsy
      end
    end
  end
end

