# compliance module
module Compliance
  # encounter base
  module EncounterBase
    # Encounter History
    module EncounterTraceHistory
      extend ActiveSupport::Concern

      included do
        def import_method
          batch.blank? ? 'DataEntry' : 'Data Importation'
        end

        def imported_by
          batch.blank? ? '-' : batch.imported_user.full_name
        end

        def imported_at
          batch.blank? ? '-' : batch.imported_at.to_date.to_s(:us_format)
        end

        def file_name
          batch.blank? ? '-' : splited_file_name
        end

        def splited_file_name
          full_path = batch.filename.path.split('/')
          full_path[full_path.size - 1]
        end

        def audit_manager_name
          audit_manager.blank? ? '-' : audit_manager.full_name
        end

        def batchname
          batch.blank? ? '-' : batch.batch_name
        end

        def batch_selection_name
          batch_selection.blank? ? '-' : batch_selection.name
        end
      end
    end
  end
end
