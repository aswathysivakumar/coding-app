# class Compliance
module Compliance
  # module User Role Configuration
  module DataEntry
    extend ActiveSupport::Concern

    included do
      def data_entry
        model = model_name(params[:worktype_type])
        @work_type = model.find_by_id(params[:worktype_id])
        coders_providers_and_values
        render partial: '/compliance/encounters/data_entry'
      end

      def save_header_values
        @encounter =
          ::Compliance::Encounter.find_account(params[:worktype_id], params[:account_number])
                                 .first_or_initialize
        return if @encounter.blank?
        params[:values].each do |key, value|
          value = check_date_condition(key, value)
          @encounter.send("#{key}=", value)
        end
        @encounter.save
        list_code_details
      end

      def list_code_details
        listing_codes
        render partial: '/compliance/encounters/list_codes'
      end

      def listing_codes
        @dx_codes = @encounter.dx_codes
                              .sort_by { |code| Icd10Diagnosis::DX_CODE_ORDER[code.code_type] }
        @px_codes = @encounter.px_codes
      end

      def add_codes
        code_adding_condition
        list_dx_px_codes
        render_values
      end

      def delete_code
        code = ::Compliance::Code.find_by_id(params[:code_id])
        return if code.blank?
        @encounter = code.encounter
        @work_type = code.encounter.worktype
        @type = code.code_type
        code.destroy
        list_dx_px_codes
        render_values
      end

      def load_encounter_details
        encounter = ::Compliance::Encounter.by_account_number(params[:account_number])
                                           .for_worktype(params[:work_type]).first
        if encounter.blank?
          render nothing: true
        else
          render json: encounter.as_json.merge!(date_values(encounter))
        end
      end

      private

      def code_adding_condition
        add_code_values if can_add_code?
      end

      def can_add_code?
        if %w(ADx PDx).include?(@type) || @type =~ /DRG/
          check_code_count < 1
        elsif @type == 'RVDx'
          check_code_count < 3
        else
          true
        end
      end

      def check_code_count
        @encounter.codes.by_code_type(@type).size
      end

      def add_code_values
        code = @encounter.codes.new
        code.code_type = @type
        code.orig_code = @code.to_s.upcase
        assign_code_values(code)
        code.orig_poa = params[:poa]
        modifier_quantity(code)
        code.save
        code.update_orig_base_rate if @type =~ /DRG/
      end

      def modifier_quantity(code)
        code.modifier = params[:modifier]
        code.quantity = params[:quantity]
        code.soi = params[:soi]
        code.rom = params[:rom]
      end

      def assign_code_values(code)
        if params[:code_id].blank? || params[:code_class].blank?
          code.orig_code_category = find_code
        else
          code.orig_code_category_id = params[:code_id]
          code.orig_code_category_type = params[:code_class]
        end
      end

      def date_values(encounter)
        { dos: encounter.discharge_date.to_s(:us_format),
          date_of_birth: encounter.date_of_birth, admitdate: encounter.admitdate,
          codeddate: encounter.codeddate, age: encounter.age_calc(encounter.dob) }
      end
    end
  end
end
