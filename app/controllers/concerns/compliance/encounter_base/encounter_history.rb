# class Compliance
module Compliance
  # module Batch Controller
  module EncounterBase
    # module Encounter History
    module EncounterHistory
      extend ActiveSupport::Concern
      included do
        def show_encounter_history
          render partial: '/compliance/encounters/audit_process/encounter_trace'
        end
      end
    end
  end
end
