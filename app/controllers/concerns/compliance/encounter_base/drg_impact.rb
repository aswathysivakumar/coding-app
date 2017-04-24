# class Compliance
module Compliance
  # module Batch Controller
  module EncounterBase
    # DRG impact calculation
    module DrgImpact
      extend ActiveSupport::Concern

      included do
        def render_drg(accuracy = [])
          render json: { code_id: @compliance_code.id, code_type: @compliance_code.code_type,
                         encounter: @encounter.id, weighted: accuracy[0],
                         basic: accuracy[1] }.to_json
        end

        def update_drg_impact
          code_type = @compliance_code.code_type
          drg_type = drg_type_hash[code_type]
          @drg_categories = Category.drg_categories
          @compliance_code.update_audit_base_rate
          render partial: '/compliance/encounters/audit_process/code_review_drg',
                 locals: { header: "#{code_type} Category", type: drg_type[:type],
                           code_set: @encounter.code_list(code_type) }, layout: false
        end

        def update_drg_on_payer_change
          @encounter.update_attributes(compliance_payer_id: params[:payer])
          @drg_categories = Category.drg_categories
          if params[:data_entry].blank?
            @encounter.drg.each(&:update_drg_base_rate)
            render partial: '/compliance/encounters/audit_process/code_review_all_drgs',
                   layout: false
          else
            @encounter.drg.each(&:update_orig_base_rate)
            render partial: '/compliance/encounters/data_entry_all_drgs', layout: false
          end
        end

        def drg_type_hash
          { 'DRG' => { type: 'ms_drg' }, 'MS DRG' => { type: 'ms_drg' },
            'APR DRG' => { type: 'apr_drg' },
            'AP DRG' => { type: 'ap_drg' }, 'TriCare DRG' => { type: 'tricare_drg' } }
        end

        def render_audit_values
          if params[:type].to_s.downcase =~ /drg/
            update_exception_values
            render_exception_values
          else
            folder_name =
              params[:exception] == 'Exception Only' ? 'exception_only' : 'audit_process'
            file_name = params[:type] == 'dx' ? 'code_review_dx' : 'code_review_px'
            render partial: "/compliance/encounters/#{folder_name}/#{file_name}", layout: false
          end
        end

        def render_show_dx_px_codes(code, code_types, from)
          name = dx_px_file_name(from)
          render partial: "/compliance/encounters/#{name}/show_dx_px_codes",
                 locals: { dx_px_codes: [code], show_delete: true, type: params[:type],
                           code_types: code_types,
                           dx_px_error_categories: dx_px_error_categories(params[:type]) },
                 layout: false
        end

        def dx_px_error_categories(type)
          type == 'dx' ? @dx_categories : @px_categories
        end

        def dx_px_file_name(from)
          from == 'exception' ? 'exception_only' : 'audit_process'
        end
      end
    end
  end
end
