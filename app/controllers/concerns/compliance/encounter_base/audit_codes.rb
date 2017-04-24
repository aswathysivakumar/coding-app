# class Compliance
module Compliance
  # module Batch Controller
  module EncounterBase
    # Audit Codes
    module AuditCodes
      extend ActiveSupport::Concern

      included do
        def edit_audit_codes
          save_audit_code
          values = return_values(@compliance_code.audit_code_category)
          accuracy = reload_encounter
          if @compliance_code.code_type =~ /DRG/
            render_drg(accuracy)
          else
            render json: values.merge(code: @compliance_code.audit_code,
                                      weighted: accuracy[0], basic: accuracy[1]).to_json
          end
        end

        def save_audit_code
          params[:code] ||= params.fetch(:compliance_code, {})[:audit_code]
          save_audit_code_soi
          @compliance_code.audit_code_category = find_code
          @compliance_code.save
        end

        def save_audit_code_soi
          params[:soi] ||= params.fetch(:compliance_code, {})[:audit_soi]
          @compliance_code.audit_code = params[:code].to_s.upcase
          @compliance_code.audit_soi = params[:soi]
        end

        def edit_audit_code_details
          @compliance_code.update_attributes(params.fetch(:compliance_code, {}))
          accuracy = reload_encounter
          hash = object_key_hash(params.fetch(:compliance_code, {}))
          render json: hash.merge(weighted: accuracy[0], basic: accuracy[1]).to_json
        end

        def object_key_hash(params)
          key = params.keys.first
          { obj1: audit_value(key) }
        end

        def audit_value(key)
          return '-' if key.nil?
          if key == 'audit_poa'
            @compliance_code.audit_poa
          elsif key == 'audit_soi'
            @compliance_code.audit_soi
          elsif key == 'audit_rom'
            @compliance_code.audit_rom
          end
        end

        def add_missing_codes
          @type = params[:code_type]
          if can_add_code?
            code = save_missing_audit_code
            error_category_details
            code_types = autoselect_code_types(@encounter, params[:code_types], params[:type])
            render_show_dx_px_codes(code, code_types, 'all_codes')
          else
            render nothing: true
          end
        end

        def save_missing_audit_code
          code = @encounter.codes.new(audit_code: params[:audit_code].upcase)
          ActiveRecord::Base.transaction do
            assign_audit_code_types(code)
            assign_audit_code_values(code)
            code.save_categories(params) if code.save
            @encounter.save
          end
          code
        end

        def assign_audit_code_types(code)
          code.code_type = params[:code_type]
          code.audit_poa = params[:audit_poa]
          code.modifier = params[:modifier]
          code.quantity = params[:quantity]
        end

        def assign_audit_code_values(code)
          if params[:code_id].blank? || params[:code_class].blank?
            params[:code] = params[:audit_code]
            code.audit_code_category = find_code
          else
            code.audit_code_category_id = params[:code_id]
            code.audit_code_category_type = params[:code_class]
          end
        end

        def delete_audit_code
          code = ::Compliance::Code.find_by_id(params[:code_id])
          return if code.blank?
          return unless code.destroy
          error_category_details
          reload_encounter
          render_audit_values
        end

        def soft_delete_code
          @compliance_code.update_attributes(soft_delete: params[:soft_delete])
          accuracy = reload_encounter
          render json: { weighted: accuracy[0], basic: accuracy[1] }.to_json
        end
      end
    end
  end
end
