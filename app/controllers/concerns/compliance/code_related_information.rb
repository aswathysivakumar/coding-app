# class Compliance
module Compliance
  # module CodeRelatedInformation
  module CodeRelatedInformation
    extend ActiveSupport::Concern

    included do
      def description_with_other_details
        render json: return_values(find_code).to_json
      end

      def return_values(code)
        if code.nil?
          no_match_found
        else
          return_code_values(code, params[:code_type])
        end
      end

      def no_match_found
        { obj1: 'NO MATCH FOUND' }
      end

      def return_code_values(code, code_type)
        case code_type.upcase
        when 'DRG', 'MS DRG', 'APR DRG', 'AP DRG', 'TRICARE DRG'
          code.description_with_other_details(@encounter)
        when 'SDX', 'PDX', 'ADX', 'RVDX', 'HCPCS', 'CHARGE CODE',
             'ICD PX', 'FAC ICD9', 'FAC ICD10', 'PRO', 'FAC',
             'CPT', 'FAC CPT', 'PRO CPT', 'FAC EM', 'PRO EM'
          code.description_with_other_details
        else
          '-'
        end
      end

      # Find code object from code and code_type
      def find_code
        ::Compliance::Code.new.find_code(@encounter, params[:code], params[:code_type], params)
      end
    end
  end
end
