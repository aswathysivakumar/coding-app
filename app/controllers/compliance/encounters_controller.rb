# for compliance
module Compliance
  # for compliance encounter
  class EncountersController < ApplicationController
    custom_require_roles COMPLIANCE_WL_CR_ROLES,
                         controller: self, only: [:select_work_type, :data_entry,
                                                  :save_data_entry, :code_review, :audit_process,
                                                  :completed_worklist]
    include Compliance::DataEntry
    include Compliance::DataEntryExtension
    include Compliance::DataEntryExtension1
    include Compliance::CodeRelatedInformation
    include Compliance::WorkList
    include Compliance::CodeReview
    include Compliance::EncounterBase::AuditCodes
    include Compliance::EncounterBase::DrgImpact
    include Compliance::EncounterBase::AuditProcess
    include Compliance::EncounterBase::ExceptionOnly
    include Compliance::EncounterBase::EncounterHistory
    before_filter :initialize_work_type, only: %w(save_header_values)
    before_filter :initialize_encounter, only: %w(description_with_other_details add_codes
                                                  save_data_entry edit_audit_codes
                                                  edit_audit_code_details add_missing_codes
                                                  delete_audit_code update_drg_impact
                                                  soft_delete_code audit_process
                                                  save_audit_dd_poo update_drg_on_payer_change
                                                  add_exception_codes show_encounter_history)
    before_filter :initialize_code, only: %w(edit_audit_codes edit_audit_code_details
                                             update_drg_impact soft_delete_code
                                             save_audit_error_categories)
    before_filter :dd_poo_values, only: %w(save_header_values)
    before_filter :active_worktypes, only: [:completed_worklist, :select_work_type]
    before_filter :auditor_details, only: [:completed_worklist]
    before_filter :model_for_error_message, only: [:select_work_type]
    before_filter :compliance_codes, only: [:code_review]
    layout 'application-upd'

    private

    def initialize_work_type
      return if params[:values].blank?
      model = model_name(params[:values][:worktype_type])
      @work_type = model.find_by_id(params[:worktype_id])
    end

    def model_name(params)
      case params
      when 'WorkType', 'Production'
        WorkType
      when '::Compliance::WorkType', 'Compliance::WorkType', 'Compliance'
        ::Compliance::WorkType
      end
    end

    def initialize_encounter
      @code = params[:code]
      @type = params[:code_type]
      @encounter = ::Compliance::Encounter.find_by_id(params[:encounter])
      @work_type = @encounter.worktype
      @ip_encounter = @encounter.ip?
    end

    def initialize_code
      @compliance_code = ::Compliance::Code.find_by_id(params[:id])
    end

    def render_values
      local_values
      if params[:chose_type] =~ /DRG/
        render partial: 'drg_codes', locals: { header: "#{@type} Category", drg_type: @type,
                                               type: params[:type_name],
                                               template_type: @type, code_set: @drgcodes }
      else
        render partial: 'list_dx_px_codes', locals: { template_type: params[:chose_type],
                                                      type: params[:type_name],
                                                      header: @header, desc_id: @desc_id,
                                                      code_set: @codes }
      end
    end

    def local_values
      @header = params[:chose_type] == 'dx' ? 'Diagnosis Category' : 'Procedure Category'
      @desc_id = params[:chose_type] == 'dx' ? 'desc1' : 'desc2'
      @drgcodes = @encounter.code_list(params[:code_type])
      @codes = params[:chose_type] == 'dx' ? @dx_codes : @px_codes
    end

    def check_date_condition(key, value)
      if %w(discharge_date admit_date coded_date dob).include?(key) && !value.blank?
        value.convert_date
      else
        value
      end
    end

    def list_dx_px_codes
      listing_codes
    end

    def model_for_error_message
      @encounter = ::Compliance::Encounter.new
    end
  end
end
