# compliance module
module Compliance
  # extends encounter model
  module EncounterBase
    # methods for autoselect Codetype
    module AutoselectCodetype
      extend ActiveSupport::Concern

      included do
        def select_code_type(code_types)
          return if (code_types & ::Code::ICD_DX_CODETYPES).blank?
          @adx_count, @pdx_count, @rvdx_count = count_details
          @code_types = code_types
          worktype.inpatient? ? adx_pdx_combination : rvdx_pdx_combination
        end

        def count_details
          code_types = [::Code::ADX_CODETYPE, ::Code::PDX_CODETYPE, ::Code::RVDX_CODETYPE]
          code_types.map { |c| codes.by_code_type(c).count }
        end

        def adx_pdx_combination
          @adx_count == 1 ? pdx_sdx_condition : adx_pdx_sdx_condition
        end

        def pdx_sdx_condition
          @pdx_count == 1 ? ::Code::SDX_CODETYPE : ::Code::PDX_CODETYPE
        end

        def adx_pdx_sdx_condition
          value1 = @code_types.include?('ADx') ? ::Code::ADX_CODETYPE : ::Code::SDX_CODETYPE
          value2 = @code_types.include?('ADx') ? ::Code::ADX_CODETYPE : ::Code::PDX_CODETYPE
          @pdx_count == 0 ? value2 : value1
        end

        def rvdx_pdx_combination
          @rvdx_count == 1 ? pdx_sdx_condition : rvdx_pdx_sdx_condition
        end

        def rvdx_pdx_sdx_condition
          value1 = @code_types.include?('RVDx') ? ::Code::RVDX_CODETYPE : ::Code::SDX_CODETYPE
          value2 = @code_types.include?('RVDx') ? ::Code::RVDX_CODETYPE : ::Code::PDX_CODETYPE
          @pdx_count == 0 ? value2 : value1
        end
      end
    end
  end
end
