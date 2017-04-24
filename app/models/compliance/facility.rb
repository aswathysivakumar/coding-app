# compliance
module Compliance
  # compliance facility
  class Facility < ActiveRecord::Base
    self.table_name = 'compliance_facilities'
    attr_accessible :compliance_client_id, :code, :active, :name
    # after_create :deactivate_self
    after_save :deactivate_work_types
    # Validations
    validates :name, presence: true
    validates :code, presence: true
    validates :code, length: { is: 3, message: 'should be 3 characters.' }
    validates :code, format: { with: /\A[a-zA-Z0-9]+\z/ }
    validates :name, format: { with: /\A[a-zA-Z0-9 -]+\z/ }
    validates :name, uniqueness: { case_sensitive: false,
                                   scope: [:compliance_client_id] }
    validates :code, uniqueness: { case_sensitive: false,
                                   scope: [:compliance_client_id] }
    # Associations
    has_many :comp_worktypes, class_name: 'Compliance::WorkType',
                              foreign_key: 'compliance_facility_id',
                              dependent: :destroy
    belongs_to :comp_client, class_name: 'Compliance::Client',
                             foreign_key: 'compliance_client_id'
    # Scopes
    scope :active, -> { where(active: true) }

    def deactivate_work_types
      return if active
      comp_worktypes.map do |x|
        next unless x.active
        x.update_attributes(active: false)
      end
    end

    # def deactivate_self
    #   update_attributes(active: false) unless comp_client.active?
    # end
  end
end
