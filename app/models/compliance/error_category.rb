# Module Compliance
module Compliance
  # Class for Error Category
  class ErrorCategory < ActiveRecord::Base
    self.table_name = 'compliance_error_categories'
    attr_accessible :category_id, :compliance_code_id, :category_type, :updated_by_id
    # Associations
    belongs_to :category
    belongs_to :code, class_name: 'Compliance::Code', foreign_key: 'compliance_code_id'
    belongs_to :user, foreign_key: 'updated_by_id'
    # Scopes
    scope :by_category_id, ->(category_id) { where(category_id: category_id) }
    scope :by_type, ->(category_type) { where(category_type: category_type) }
  end
end
