# class Compliance
module Compliance
  # module Data entry extension methods
  module DataEntryExtension1
    extend ActiveSupport::Concern

    included do
      def select_work_type
        session[:prev_page] = nil
        return unless params[:show]
        @work_type = model_name(params[:model_name]).find_by_id(params[:worktype_id])
        coders_providers_and_values
      end

      def coders_providers_and_values
        @coders = @work_type.coders
        @providers = @work_type.providers
        @worktype_value = @work_type.work_type_value
      end
    end
  end
end
