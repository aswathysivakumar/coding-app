# compliance worktype
module Compliance
  # WorkType model
  class WorkType < ActiveRecord::Base
    self.table_name = 'compliance_work_types'
    attr_accessible :active, :client_id, :facility_id,
                    :work_type_value, :sampling_method, :comment,
                    :compliance_facility_id
    # Validations
    validates :work_type_value, presence: true
    validates :work_type_value, uniqueness: { case_sensitive: false,
                                              scope: [:compliance_facility_id] }
    # Associations
    belongs_to :comp_client, class_name: 'Compliance::Client',
                             foreign_key: 'comp_client_id'
    belongs_to :comp_facility, class_name: 'Compliance::Facility',
                               foreign_key: 'compliance_facility_id'
    has_many :reimbursements, class_name: 'Compliance::Reimbursement',
                              foreign_key: 'compliance_work_type_id',
                              dependent: :destroy
    has_many :payer_configurations, class_name: 'Compliance::PayerConfiguration',
                                    foreign_key: 'compliance_work_type_id', dependent: :destroy
    has_many :roles_users, class_name: 'RolesUser', foreign_key: 'compliance_work_type_id',
                           dependent: :destroy
    has_one :template_detail, class_name: 'Compliance::TemplateDetail',
                              foreign_key: 'compliance_work_type_id'
    has_many :comp_providers, class_name: 'Compliance::WorkTypesProvider',
                              foreign_key: 'compliance_work_type_id',
                              dependent: :destroy
    has_many :providers, through: :comp_providers
    has_many :compliance_encounters, as: :worktype, class_name: 'Compliance::Encounter'
    has_many :batches, as: :worktype, class_name: 'Compliance::Batch'
    has_many :payer_work_types, class_name: 'Compliance::PayersWorkType',
                                foreign_key: 'compliance_work_type_id'
    has_many :compliance_payers, through: :payer_work_types
    # Scopes
    scope :active, -> { where(active: true) }
    scope :inactive, -> { where(active: false) }
    scope :active_users, lambda {
      joins(comp_facility: :comp_client)
        .where('compliance_work_types.active = ?', true)
        .order('compliance_clients.name, compliance_facilities.code,
              compliance_work_types.work_type_value')
    }
    scope :order_by_name, lambda {
      joins(comp_facility: :comp_client)
        .order('compliance_clients.name, compliance_facilities.code,
              compliance_work_types.work_type_value')
    }

    scope :has_template, lambda {
      joins(:template_detail)
    }

    def full_name
      "#{comp_facility.comp_client.code} - #{comp_facility.code} - #{work_type_value}"
    end

    def full_name_code
      "#{client_name} : #{client_code} - #{comp_facility.code} - #{work_type_value}"
    end

    def client_id
      comp_facility.comp_client.id
    end

    def client_name
      comp_facility.comp_client.name
    end

    def client_code
      comp_facility.comp_client.code
    end

    def inpatient?
      work_type_value.casecmp('ip').zero?
    end

    def auditors
      roles_users.eager_load(:user).where(role_id: Role.auditor)
    end

    def payers
      payer_configurations.eager_load(:compliance_payer).map(&:compliance_payer).uniq
    end

    def coders
      roles_users.active.eager_load(:user).compliance_coder.map(&:user)
    end

    def providers
      comp_providers.eager_load(:provider).map(&:provider)
    end

    def options_for_providers
      providers.map { |x| [x.full_name, x.id] }
    end

    def options_for_payers
      payers.map { |x| [x.full_name, x.id] }
    end

    def options_for_coders
      coders.map { |x| [x.full_name, x.id] }
    end

    def options_for_auditors
      auditors.map { |x| [x.user.full_name, x.user.id] }
    end
  end
end
