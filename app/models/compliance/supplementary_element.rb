# for compliance
module Compliance
  # for dd and poo
  class SupplementaryElement < ActiveRecord::Base
    self.table_name = 'supplementary_elements'
    attr_accessible :audit_id, :audit_type, :auditor_id, :auditor_manager_id,
                    :compliance_encounter_id, :orig_id, :orig_type
    # Associations
    belongs_to :orig, polymorphic: true
    belongs_to :audit, polymorphic: true
    belongs_to :encounter, class_name: 'Compliance::Encounter',
                           foreign_key: 'compliance_encounter_id'
    # Scopes
    scope :find_encounter_id, ->(id) { where(compliance_encounter_id: id) }
    scope :by_orig_or_audit_type, ->(type) { where('orig_type = ? or audit_type = ?', type, type) }
    scope :discharge_dispositions, -> { where(orig_type: 'DischargeDisposition') }
    scope :point_of_origin, -> { where(orig_type: 'PointOfOrigin') }
    scope :orig_type, ->(type) { where(orig_type: type) }
    scope :audit_type, ->(type) { where(audit_type: type) }
    scope :incorrect, -> { where('orig_id<>audit_id') }
    scope :missing, -> { where('orig_id is NULL or orig_type is NULL') }
    # Validations
    validates :compliance_encounter_id, presence: true

    def self.transfer_codes(encounter)
      ActiveRecord::Base.transaction do
        eager_load(:encounter).where(compliance_encounter_id: encounter)
                              .update_all('audit_id=orig_id, audit_type=orig_type')
        encounter.update_attributes(copy_audit_codes: true)
      end
    end
  end
end
