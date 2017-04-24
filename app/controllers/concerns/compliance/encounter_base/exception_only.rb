# class Compliance
module Compliance
  # module Batch Controller
  module EncounterBase
    # all methods related to Exception Only codes
    module ExceptionOnly
      extend ActiveSupport::Concern

      included do
        def save_code_count
          encounter = ::Compliance::Encounter.where(id: params[:encounter_id]).first_or_initialize
          count = encounter.exception_code_count.merge(params[:type] => params[:value].to_i)
          encounter.exception_code_count = count
          encounter.save
          render nothing: true
        end

        def add_exception_codes
          @type = params[:code_type]
          if can_add_code?
            code = save_exception_audit_code
            error_category_details
            code_types = autoselect_code_types(@encounter, params[:code_types], params[:type])
            render_exception_values(code, code_types)
          else
            render nothing: true
          end
        end

        def update_exception_values
          @type = params[:type].to_s.upcase.tr('_', ' ')
          params[:selected_type] = params[:type]
        end

        def render_exception_values(code = nil, code_types = nil)
          if params[:type].to_s.downcase =~ /drg/
            render partial: '/compliance/encounters/audit_process/code_review_drg',
                   locals: { header: "#{@type} Category", drg_type: @type,
                             type: params[:selected_type],
                             code_set: @encounter.code_list(@type) }, layout: false
          else
            render_show_dx_px_codes(code, code_types, 'exception')
          end
        end

        def save_exception_audit_code
          code = @encounter.codes.new
          ActiveRecord::Base.transaction do
            assign_exception_code_types(code)
            assign_exception_drg_code_types(code)
            assign_exception_code_values(code)
            save_modifier_and_quantity(code)
            code.save_categories_and_base_rate(params) if code.save
            @encounter.save
          end
          code
        end

        def save_modifier_and_quantity(code)
          code.modifier = params[:modifier]
          code.quantity = params[:quantity]
        end

        def assign_exception_code_types(code)
          assign_exception_code_poa(code)
          code.code_type = params[:code_type]
          assign_exception_only_codes(code)
        end

        def assign_exception_only_codes(code)
          code.orig_code = params[:orig_code].upcase unless params[:orig_code].blank?
          code.audit_code = params[:audit_code].upcase unless params[:audit_code].blank?
        end

        def assign_exception_code_poa(code)
          code.orig_poa = params[:orig_poa] unless params[:orig_code].blank?
          code.audit_poa = params[:audit_poa] unless params[:audit_code].blank?
        end

        def assign_exception_drg_code_types(code)
          return unless params[:type] =~ /DRG/
          code.soi = params[:soi]
          code.audit_soi = params[:audit_soi]
          code.rom = params[:rom]
          code.audit_rom = params[:audit_rom]
        end

        def assign_exception_code_values(code)
          assign_orig_exception_code_values(code)
          assign_audit_exception_code_values(code)
        end

        def assign_orig_exception_code_values(code)
          if params[:orig_code_id].blank? || params[:orig_code_class].blank?
            params[:code] = params[:orig_code]
            code.orig_code_category = find_code
          else
            code.orig_code_category_id = params[:orig_code_id]
            code.orig_code_category_type = params[:orig_code_class]
          end
        end

        def assign_audit_exception_code_values(code)
          if params[:code_id].blank? || params[:code_class].blank?
            params[:code] = params[:audit_code]
            code.audit_code_category = find_code
          else
            code.audit_code_category_id = params[:code_id]
            code.audit_code_category_type = params[:code_class]
          end
        end
      end
    end
  end
end
