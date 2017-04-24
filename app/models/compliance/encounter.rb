# for compliance
module Compliance
  # for compliance encounters
  class Encounter < ActiveRecord::Base
    has_paper_trail on: [:create, :update], only: [:state, :auditor_id]
    self.table_name = 'compliance_encounters'
    include Compliance::EncounterBase::EncounterExtension
    include Compliance::EncounterBase::ShowCodes
    include Compliance::EncounterBase::CommonMethods
    include Compliance::EncounterBase::WorkLists
    include Compliance::EncounterBase::CodeReview
    include Compliance::EncounterBase::AutoselectCodetype
    include Compliance::EncounterBase::StateMachine
    include Compliance::EncounterBase::EncounterTraceHistory
    attr_accessible :account_number, :admit_date, :age, :audit_date,
                    :audit_manager_id, :auditor_id, :coded_date, :state,
                    :coder_id, :data_entry_mode, :discharge_date, :dob,
                    :gender, :los, :mrn, :payer_id, :provider_id, :compliance_payer_id,
                    :reviewed_date, :worktype_id, :worktype_type, :batch_selection_id,
                    :copy_audit_codes
    attr_reader :accuracy_calculator
    after_initialize :initialize_accuracy_calculator
    before_save :calculate_accuracy
    serialize :exception_code_count, Hash
    # associations
    belongs_to :worktype, polymorphic: true
    belongs_to :batch
    belongs_to :batch_selection
    has_many :codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                     dependent: :destroy
    accepts_nested_attributes_for :codes
    has_many :dx_codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                        dependent: :destroy, conditions: proc { "code_type IN (#{DX_CODETYPES})" }
    accepts_nested_attributes_for :dx_codes
    has_many :px_codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                        dependent: :destroy, conditions: proc { "code_type IN (#{PX_CODETYPES})" }
    accepts_nested_attributes_for :px_codes
    has_many :ms_drg_codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                            dependent: :destroy, conditions: proc { "code_type='MS DRG'" }
    accepts_nested_attributes_for :ms_drg_codes
    has_many :ap_drg_codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                            dependent: :destroy, conditions: proc { "code_type='AP DRG'" }
    accepts_nested_attributes_for :ap_drg_codes
    has_many :apr_drg_codes, class_name: 'Compliance::Code', foreign_key: 'compliance_encounter_id',
                             dependent: :destroy, conditions: proc { "code_type='APR DRG'" }
    accepts_nested_attributes_for :apr_drg_codes
    has_many :tricare_drg_codes, class_name: 'Compliance::Code',
                                 foreign_key: 'compliance_encounter_id', dependent: :destroy,
                                 conditions: proc { "code_type='TriCare DRG'" }
    accepts_nested_attributes_for :tricare_drg_codes

    has_many :supplementary_elements, class_name: 'Compliance::SupplementaryElement',
                                      foreign_key: 'compliance_encounter_id', dependent: :destroy
    has_many :discharge_dispositions, through: :supplementary_elements, source: :orig,
                                      source_type: 'DischargeDisposition'
    has_many :point_of_origins, through: :supplementary_elements, source: :orig,
                                source_type: 'PointOfOrigin'
    has_many :audit_discharge_dispositions, through: :supplementary_elements, source: :audit,
                                            source_type: 'DischargeDisposition'
    has_many :audit_point_of_origins, through: :supplementary_elements, source: :audit,
                                      source_type: 'PointOfOrigin'
    has_one :comment, class_name: 'Compliance::Comment', foreign_key: 'compliance_encounter_id',
                      dependent: :destroy
    belongs_to :payer, class_name: 'Compliance::Payer', foreign_key: 'compliance_payer_id'
    belongs_to :provider
    belongs_to :coder, class_name: 'User', foreign_key: 'coder_id'
    belongs_to :auditor, class_name: 'User', foreign_key: 'auditor_id'
    belongs_to :audit_manager, class_name: 'User', foreign_key: 'audit_manager_id'
    # scopes
    scope :for_worktype, ->(id) { where(worktype_id: id) }
    scope :find_account, lambda { |worktype_id, account_number|
      where(worktype_id: worktype_id, account_number: account_number)
    }
    scope :exception_only, -> { where(data_entry_mode: 'Exception Only') }
    scope :by_account_number, ->(account_no) { where(account_number: account_no) }
    scope :non_batch_encounters, -> { where('batch_selection_id is null') }
    scope :by_ids, ->(ids) { where(id: ids) }
    scope :select_fields, lambda {
      select(['compliance_encounters.id', :account_number, :mrn, :admit_date, :discharge_date,
              :los, :dob, :coder_id, :provider_id, :worktype_id, :worktype_type,
              :compliance_payer_id, :state])
    }
    # Validations
    validates :account_number, :worktype_id, :worktype_type, :discharge_date, presence: true
    validates :account_number, uniqueness: { scope: [:worktype_id, :worktype_type] }

    def initialize_accuracy_calculator
      @accuracy_calculator = ::Compliance::AccuracyCalculator.new(self)
    end

    def calculate_accuracy
      self.weighted_accuracy = accuracy_calculator.weighted_accuracy.round(2)
      self.basic_accuracy = accuracy_calculator.basic_accuracy.round(2)
    end
  end
end
