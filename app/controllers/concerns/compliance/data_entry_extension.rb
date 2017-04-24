# class Compliance
module Compliance
  # module User Role Configuration
  module DataEntryExtension
    extend ActiveSupport::Concern

    included do
      def save_dd_poo
        value = ::Compliance::SupplementaryElement.find_encounter_id(params[:encounter_id])
                                                  .orig_type(params[:type]).first_or_initialize
        value.orig_id = params[:code]
        value.save
        render nothing: true
      end

      def insert_comment
        comment = ::Compliance::Comment.find_encounter_id(params[:encounter_id])
                                       .first_or_initialize
        comment.content = params[:content]
        comment.save
        render nothing: true
      end

      def delete_encounter
        return if @encounter.blank?
        @encounter.destroy
      end

      def save_data_entry
        if %w(Save Save\ &\ Audit).include?(params[:commit])
          save_data
          save_data_extension
          save_data_extension1
          redirect_conditions
        elsif params[:commit] == 'Delete'
          delete_encounter
          redirect_conditions
        end
      end

      def save_data
        @encounter.mrn = params[:medical_record_number]
        @encounter.dob =
          params[:header_date_of_birth].convert_date unless params[:header_date_of_birth].blank?
        @encounter.gender = params[:gender]
      end

      def save_data_extension
        @encounter.provider_id = params[:provider_number]
        @encounter.compliance_payer_id = params[:payer]
        @encounter.admit_date =
          params[:admit_date].convert_date unless params[:admit_date].blank?
        @encounter.los = params[:los]
      end

      def save_data_extension1
        @encounter.coded_date =
          params[:coded_date].convert_date unless params[:coded_date].blank?
        @encounter.coder_id = params[:coder]
        @encounter.needs_review! if @encounter.coded?
        @encounter.save
      end

      def redirect_conditions
        if params[:commit] == 'Save'
          save_redirect_condition('Saved')
        elsif params[:commit] == 'Save & Audit'
          redirect_to code_review_compliance_encounter_path(@encounter)
        elsif params[:commit] == 'Delete'
          save_redirect_condition('Deleted')
        end
      end

      def save_redirect_condition(value)
        flash[:notice] = "Encounter #{value} Successfully"
        modelname = class_name(@work_type.class.to_s)
        redirect_to select_work_type_compliance_encounters_path(model_name: modelname,
                                                                worktype_id: @work_type.id,
                                                                show: true)
      end

      def class_name(model_name)
        case model_name
        when 'WorkType'
          'Production'
        when '::Compliance::WorkType', 'Compliance::WorkType'
          'Compliance'
        end
      end

      def dd_poo_values
        @dd = DischargeDisposition.all
        @poo = PointOfOrigin.all
      end
    end
  end
end
