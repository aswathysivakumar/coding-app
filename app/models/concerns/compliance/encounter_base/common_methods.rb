# compliance module
module Compliance
  # extends encounter model
  module EncounterBase
    # common methods for encounters
    module CommonMethods
      extend ActiveSupport::Concern

      included do
        # States
        def coded?
          state == 'coded'
        end

        def review_completed?
          state == 'review_complete'
        end

        def needs_review?
          state == 'needs_review'
        end

        def state_title
          state.to_s.upcase.tr('_', ' ')
        end

        def bg_style
          if %w(under_review under_audit).include?(state)
            'background-color:#FFC0CB;'
          elsif %w(review_complete).include?(state)
            'background-color:#bbee99;'
          elsif %w(needs_review).include?(state)
            'background-color:#FFFF99;'
          else
            'background-color:#FFFFFF;'
          end
        end

        def coder_name
          return '-' if coder_id.nil?
          coder.try(:full_name)
        end

        def provider_name
          return '-' if provider_id.nil?
          provider.try(:full_name)
        end

        def payer_name
          return '-' if compliance_payer_id.nil?
          payer.try(:full_name)
        end

        def exception_codes?
          data_entry_mode == 'Exception Only'
        end

        def all_codes?
          data_entry_mode == 'All Codes'
        end

        def render_file_name
          exception_codes? ? 'exception_only_codes' : 'all_codes'
        end

        def render_code_review_file_name
          if exception_codes?
            'exception_only/code_review_content'
          else
            'audit_process/code_review_content'
          end
        end

        def worktype_template_type
          return '-' if worktype.work_type_value.blank?
          worktype.work_type_value
        end

        def ip?
          worktype_template_type == 'IP'
        end

        def complete_button
          review_completed? ? 'Update' : 'Complete'
        end

        def hide_accuracy
          coded? || (needs_review? && !copy_audit_codes)
        end

        def show_weighted_accuracy
          hide_accuracy ? '-' : weighted_accuracy.to_s
        end

        def show_basic_accuracy
          hide_accuracy ? '-' : basic_accuracy.to_s
        end

        def can_copy_audit_codes
          !copy_audit_codes && all_codes?
        end
      end
    end
  end
end
