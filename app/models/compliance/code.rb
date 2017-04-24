# for compliance
module Compliance
  # for compliance codes
  class Code < ActiveRecord::Base
    self.table_name = 'compliance_codes'
    include Compliance::BaseRateCalculation
    include Compliance::CodeExtension
    include Compliance::CodeBase::CodeRelatedInformation
    attr_accessible :audit_code, :audit_code_category_id, :audit_code_category_type, :audit_poa,
                    :code_type, :compliance_encounter_id, :orig_code, :orig_code_category_id,
                    :orig_code_category_type, :orig_poa, :soi, :rom, :audit_soi, :audit_rom,
                    :soft_delete, :orig_base_rate, :audit_base_rate, :orig_reimbursement,
                    :audit_reimbursement
    attr_accessor :orig_weight_value, :audit_weight_value, :orig_reim, :audit_reim
    # associations
    belongs_to :encounter, class_name: 'Compliance::Encounter',
                           foreign_key: 'compliance_encounter_id'
    belongs_to :orig_code_category, polymorphic: true
    belongs_to :audit_code_category, polymorphic: true

    has_many :error_categories, class_name: 'Compliance::ErrorCategory',
                                foreign_key: 'compliance_code_id', dependent: :destroy
    has_many :categories, through: :error_categories
    accepts_nested_attributes_for :categories

    # scopes
    scope :origcode_category_type, ->(type) { where(orig_code_category_type: type) }
    scope :auditcode_category_type, ->(type) { where(audit_code_category_type: type) }
    scope :by_encounter, ->(encounter) { where(compliance_encounter_id: encounter) }
    scope :by_code_type, lambda { |code_type|
      new_code_type =
        ::Code::MS_DRG_CODES.include?(code_type) ? ::Code::MS_DRG_CODES : code_type
      where(code_type: new_code_type)
    }
    scope :dx, -> { where(code_type: ::Code::ICD_DX_CODETYPES) }
    scope :px, -> { where(code_type: ::Code::PX_CODETYPES) }
    scope :drgs, -> { where(code_type: ::Code::ALL_DRG_CODE_TYPES) }
    scope :adx, -> { where(code_type: ::Code::ADX_CODETYPE) }
    scope :cpt, -> { where(code_type: ::Code::CPT_CODETYPES) }
    scope :rvdx, -> { where(code_type: ::Code::RVDX_CODETYPE) }
    scope :pdx, -> { where(code_type: ::Code::PDX_CODETYPE) }
    scope :sdx, -> { where(code_type: ::Code::SDX_CODETYPE) }
    scope :drg, -> { where(code_type: ::Code::DRG_CODETYPE) }
    scope :hcpcs, -> { where(code_type: ::Code::HCPCS_CODETYPE) }
    scope :icd10, -> { where(code_type: ::Code::FAC_ICD10_CODETYPE) }
    scope :ip_px, -> { where(code_type: ::Code::ICD_PX_CODETYPES) }
    scope :em, -> { where(code_type: ::Code::EM_CODETYPES) }
    scope :missing, -> { where("orig_code is NULL or orig_code=''") }
    scope :missing_poa, -> { where("orig_poa is NULL or orig_poa=''") }
    scope :not_missing, -> { where('orig_code is not NULL or orig_code !=""') }
    scope :incorrect, lambda {
      where('audit_code is null or orig_code<>audit_code or soft_delete=true')
    }
    scope :incorrect_dx, -> { where('orig_code<>audit_code or orig_poa<>audit_poa') }
    scope :incorrect_poa, lambda {
      where('audit_code is null or orig_poa<>audit_poa or soft_delete=true')
    }
    scope :incorrect_drg, lambda {
      where('audit_code is null or orig_code<>audit_code or soi<>audit_soi')
    }
    scope :correct, -> { where('orig_code=audit_code') }

    def maintype
      CodeInfo.maintype(code_type)
    end

    def fac_cpt?
      CodeInfo.fac_cpt?(code_type)
    end

    def pro_cpt?
      CodeInfo.pro_cpt?(code_type)
    end

    def all_codes
      %w(CPT ICD\ Dx ICD\ Px DRG HCPCS CC MS\ DRG AP\ DRG APR\ DRG TriCare\ DRG)
    end

    def drg_codes
      %w(DRG APR\ DRG AP\ DRG TriCare\ DRG MS\ DRG)
    end

    def self.transfer_codes(encounter)
      ActiveRecord::Base.transaction do
        eager_load(:encounter).where(compliance_encounter_id: encounter)
                              .update_all('audit_code=orig_code,
                                           audit_code_category_id=orig_code_category_id,
                                           audit_code_category_type=orig_code_category_type,
                                           audit_poa=orig_poa, audit_soi=soi, audit_rom=rom,
                                           audit_base_rate=orig_base_rate,
                                           audit_reimbursement=orig_reimbursement')
        encounter.update_attributes(copy_audit_codes: true)
      end
    end
  end
end
