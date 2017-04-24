# compliance module
module Compliance
  # common methods for models
  module EncounterBase
    # code for Encounter related details
    module EncounterExtension
      extend ActiveSupport::Concern

      included do
        def self.values_complete_worklist
          select([:id, :account_number, :mrn, :admit_date, :discharge_date, :coded_date, :coder_id,
                  :reviewed_date, :auditor_id])
        end

        def self.date_type_column(date_type)
          if date_type == '1'
            'admit_date'
          elsif date_type == '2'
            'discharge_date'
          elsif date_type == '3'
            'coded_date'
          elsif date_type == '4'
            'audit_date'
          else
            ''
          end
        end

        def self.date_value(range_date)
          range_date.split(' - ')
        end

        def dd_poo_value(type)
          supplementary_elements.orig_type(type).first.try(:orig).try(:id)
        end

        def comment_value
          comment.try(:content)
        end

        def date_of_birth
          dob.blank? ? '' : dob.to_s(:us_format)
        end

        def admitdate
          admit_date.blank? ? '' : admit_date.to_s(:us_format)
        end

        def codeddate
          coded_date.blank? ? '' : coded_date.to_s(:us_format)
        end

        def code_list(drg_type)
          codes.by_code_type(drg_type)
        end
      end
    end
  end
end
