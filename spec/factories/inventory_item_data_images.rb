# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :inventory_item_data_image, class: 'Inventory::ItemDataImage' do
    association :item_data, factory: :inventory_item_data
    image { fixture_file_upload(Rails.root.join('spec/fixtures/images/valid_report_category_icon.png')) }
  end
end
