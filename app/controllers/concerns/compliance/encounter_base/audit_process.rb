# class Compliance
module Compliance
  # module Batch Controller
  module EncounterBase
    # DRG impact calculation and audit complete
    module AuditProcess
      extend ActiveSupport::Concern

      included do
        def save_audit_dd_poo
          params[:suppl_type] == 'audit' ? save_audit_suppl_values : save_orig_suppl_values
          render_supplementary_accuracy
        end

        def save_audit_suppl_values
          value = ::Compliance::SupplementaryElement.find_encounter_id(params[:encounter])
                                                    .by_orig_or_audit_type(params[:type])
                                                    .first_or_initialize
          value.audit_id = params[:code]
          value.audit_type = params[:type]
          value.save
        end

        def save_orig_suppl_values
          value = ::Compliance::SupplementaryElement.find_encounter_id(params[:encounter])
                                                    .by_orig_or_audit_type(params[:type])
                                                    .first_or_initialize
          value.orig_type = params[:type]
          value.orig_id = params[:code]
          value.save
        end

        def render_supplementary_accuracy
          accuracy = reload_encounter
          render json: { weighted: accuracy[0], basic: accuracy[1] }.to_json
        end

        def reload_encounter
          @encounter.save
          [@encounter.weighted_accuracy.to_f.round(2), @encounter.basic_accuracy.to_f.round(2)]
        end

        def save_audit_error_categories
          message =
            if @compliance_code.incorrect?
              save_or_remove_error_category
            else
              'You cannot add error category for a correct code.'
            end
          render partial: '/qa/encounter/show_codes', locals: { object: message }
        end

        def save_or_remove_error_category
          error_category = @compliance_code.error_categories.by_category_id(params[:category_id])
                                           .by_type(params[:category_type]).first_or_initialize
          params[:checked] == 'true' ? error_category.save : error_category.destroy
          'success'
        end

        def audit_process
          if %w(Complete Save Update).include?(params[:commit])
            complete_audit_process
          elsif params[:commit] == 'Delete'
            delete_audit_encounter
          end
        end

        def complete_audit_process
          convert_dates
          if @encounter.update_attributes(params[:compliance_encounter])
            save_or_complete_encounter
            url = session[:prev_page] ||
                  completed_worklist_compliance_encounters_path(work_type: @work_type)
            redirect_to url, notice: 'Encounter updated successfully'
          else
            redirect_to code_review_compliance_encounter(@encounter),
                        notice: "Couldn't update encounter successfully"
          end
        end

        def save_or_complete_encounter
          params[:commit] == 'Save' ? @encounter.under_review! : @encounter.complete_review!
        end

        def delete_audit_encounter
          if @encounter.destroy
            redirect_to completed_worklist_compliance_encounters_path(work_type: @work_type),
                        notice: 'Encounter deleted successfully'
          else
            redirect_to code_review_compliance_encounter(@encounter),
                        notice: "Couldn't delete encounter successfully"
          end
        end

        def convert_dates
          return if params.fetch(:compliance_encounter, nil).blank?
          [:dob, :admit_date, :discharge_date, :coded_date, :audit_date].each do |date|
            params[:compliance_encounter][date] =
              params[:compliance_encounter][date].to_s.convert_date
          end
        end
      end
    end
  end
end
