class CaseStepDataImage < ActiveRecord::Base
  mount_uploader :image, ImageUploader

  belongs_to :case_step_data

  def url
    self.image.url
  end

  class Entity < Grape::Entity
    expose :url
  end
end
