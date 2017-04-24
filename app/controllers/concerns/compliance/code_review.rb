# class Compliance
module Compliance
  # module CodeReview Extension
  module CodeReview
    extend ActiveSupport::Concern

    included do
      def code_review
        session[:prev_page] = request.env['HTTP_REFERER']
        flash[:notice] = nil
        @headers = @encounter.prepare_header_data
        @encounter.generate_default_audit_codes if @encounter.can_copy_audit_codes
      end

      private

      def compliance_codes
        @encounter = ::Compliance::Encounter.find_by_id(params[:id])
        @work_type = @encounter.worktype
        allocate_code_values
        allocate_supplementary_values
        error_category_details
        @ip_encounter = @encounter.ip?
      end

      def allocate_code_values
        @dx_codes = @encounter.dx_codes
        @px_codes = @encounter.px_codes
        @discharge_disposition = @encounter.discharge_dispositions
        @poo = @encounter.point_of_origins
        @drg_codes = @encounter.drg_codes
      end

      def allocate_supplementary_values
        @providers = @work_type.options_for_providers
        @coders = @work_type.options_for_coders
        @auditors = @work_type.options_for_auditors
      end

      def error_category_details
        @dx_categories = Category.dx_categories
        @px_categories = Category.px_categories
        @drg_categories = Category.drg_categories
      end

      def autoselect_code_types(encounter, code_types, type)
        return unless type == 'dx'
        code_types = code_types.join.split(' ')
        encounter.select_code_type(code_types)
      end
    end
  end
end
