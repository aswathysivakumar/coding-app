# Compliance module
module Compliance
  # Extends encounter model
  module EncounterBase
    # Functions related to the Code Review Process of encounters
    module CodeReview
      extend ActiveSupport::Concern

      included do
        def prepare_header_data
          result_hash = {}
          result_hash.merge!(static_values)
          result_hash.merge!(date_values)
          result_hash.merge!(dynamic_values)
          result_hash.merge!(los_value)
          result_hash
        end

        def static_values
          { client: worktype.full_name_code, account_no: account_number, mrn: mrn, dob: dob,
            gender: gender }
        end

        def date_values
          { admit_date: admit_date.blank? ? '-' : admit_date.try(:strftime, '%m/%d/%Y'),
            discharge_date: discharge_date.try(:strftime, '%m/%d/%Y'),
            coded_date: coded_date.blank? ? '-' : coded_date.try(:strftime, '%m/%d/%Y'),
            review_date: audit_date.blank? ? '-' : audit_date.try(:strftime, '%m/%d/%Y') }
        end

        def dynamic_values
          { provider: provider.try(:name), age: age_calc(dob), payer: payer.try(:full_name),
            auditor: auditor.blank? ? '-' : auditor.try(:full_name),
            coder: coder.try(:full_name), weighted_accuracy: '100%' }
        end

        def los_value
          return {} if worktype.work_type_value != 'IP'
          { los: los }
        end

        def generate_default_audit_codes
          generate_default_codes
          generate_default_supplementary_codes
        end

        def generate_default_codes
          return if codes.blank?
          ::Compliance::Code.transfer_codes(self)
        end

        def generate_default_supplementary_codes
          return if supplementary_elements.blank?
          ::Compliance::SupplementaryElement.transfer_codes(self)
        end

        def orig_dd_id
          discharge_dispositions.first.try(:id)
        end

        def audit_dd_id
          audit_discharge_dispositions.first.try(:id)
        end

        def orig_poo_id
          point_of_origins.first.try(:id)
        end

        def audit_poo_id
          audit_point_of_origins.first.try(:id)
        end

        def audited_date
          audit_date.try(:strftime, '%m/%d/%Y') || Date.today.strftime('%m/%d/%Y')
        end

        def age_calc(dob)
          return '-' if dob.blank?
          now = Time.now.utc.to_date
          now.year - dob.year - age_calc_condition(dob, now)
        end

        private

        def age_calc_condition(dob, now)
          ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
        end
      end
    end
  end
end
