class Reports::Category < Reports::Base
  include EncodedImageUploadable

  has_and_belongs_to_many :inventory_categories, class_name: 'Inventory::Category',
                          foreign_key: 'reports_category_id',
                          association_foreign_key: 'inventory_category_id'

  has_many :status_categories,
    class_name: 'Reports::StatusCategory',
    foreign_key: 'reports_category_id',
    dependent: :destroy
  has_many :statuses,
    class_name: "Reports::Status",
    through: :status_categories,
    source: :status

  has_many :reports,  class_name: 'Reports::Item', foreign_key: 'reports_category_id', dependent: :destroy

  belongs_to :parent_category, class_name: 'Reports::Category', foreign_key: 'parent_id'
  has_many :subcategories, class_name: 'Reports::Category', foreign_key: 'parent_id'

  scope :active, -> { where(active: true) }
  scope :main, -> { where(parent_id: nil) }

  mount_uploader :icon, IconUploader
  mount_uploader :marker, MarkerUploader

  validates :title, presence: true, uniqueness: true
  validates :icon, integrity: true, presence: true
  validates :marker, integrity: true, presence: true
  validates :color, presence: true, css_hex_color: true
  validates :confidential, inclusion: { in: [false, true] }

  accepts_encoded_file :icon, :marker
  expose_multiple_versions :icon, :marker

  def update_statuses!(statuses)
    raise 'statuses is not an array' unless statuses.kind_of?(Array)
    initial_used, final_used = false, false

    statuses = statuses.map do |status|
      status_params = status.slice('title', 'color', 'initial', 'final', 'active', 'private')

      if status_params['initial'].present?
        if status_params['initial'] == true && initial_used
          raise 'A report status must only have a single initial status'
        end

        initial_used = true
      end

      if status_params['final'].present?
        final_used = true
      end

      status_params['initial'] = convert_to_boolean(status_params['initial'])
      status_params['final'] = convert_to_boolean(status_params['final'])
      status_params['active'] = convert_to_boolean(status_params['active'])
      status_params['private'] = convert_to_boolean(status_params['private'])

      report_status = Reports::Status.where("LOWER(title) = LOWER(?)", status_params['title']).first

      unless report_status
        report_status = Reports::Status.create(
          title: status_params['title']
        )
      end

      if report_status.new_record?
        report_status.color = status_params['color']
        report_status.initial = status_params['initial']
        report_status.final = status_params['final']
        report_status.active = status_params['active']
        report_status.private = status_params['private']
      end

      [report_status, status_params]
    end

    unless initial_used && final_used
      raise 'A initial and final status must be defined'
    end

    self.status_categories = statuses.map do |info|
      status, params = info[0], info[1]
      status.save!

      # Create the many-to-many mapping
      self.status_categories.create_with(
        initial: params['initial'],
        final: params['final'],
        active: params['active'],
        private: params['private']
      ).find_or_create_by(status: status)
    end
  end

  def original_icon
    self.icon.to_s
  end

  class Entity < Grape::Entity
    expose :id
    expose :title
    expose :original_icon
    expose :icon_structure, as: :icon
    expose :marker_structure, as: :marker
    expose :color
    expose :resolution_time_enabled
    expose :resolution_time
    expose :private_resolution_time
    expose :user_response_time
    expose :allows_arbitrary_position
    expose :parent_id
    expose :statuses, using: Reports::Status::Entity
    expose :confidential

    with_options(if: { display_type: :full }) do
      expose :active
      expose :inventory_categories, using: Inventory::Category::Entity
      expose :subcategories, using: Entity
      expose :created_at
      expose :updated_at
    end
  end

  protected
    def convert_to_boolean(value)
      if value.kind_of?(String)
        value = (value == "false") ? false : true
      end

      value
    end
end
