class AddCurrentVersionToFlows < ActiveRecord::Migration
  def change
    add_column :flows, :current_version, :integer, default: 1
    Flow.all.each do |flow|
      flow.update current_version: flow.versions.size + 1
    end
  end
end
