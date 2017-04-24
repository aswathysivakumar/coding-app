# module for reports
module Reports
  # For Informational Comment Report
  class InformationalCommentController < ApplicationController
    custom_require_roles %w(system_admin user_admin)
    before_filter :initialize_report_name, only: [:index]
    # before_filter :initialize_parameters, only: [:index]
    layout 'application-upd'
    respond_to :html, :js

    def index
      initial_variables
      return if @sel_client.blank?
      information_comment_report = Reports::InformationalComment.new(options(params))
      informational_comment_data = information_comment_report.data
      if params[:commit] == 'Export'
        book = information_comment_report.export
        spreadsheet = StringIO.new
        book.write spreadsheet
        send_data spreadsheet.string, filename: "#{@report_name}.xls",
                                      type: 'application/vnd.ms-excel'
      end
      save_update_filter(params)
    end

    def options(params)
      { from: @from, to: @to, f_date: @f_date, t_date: @t_date, work_type_ids: params[:client],
        active: @active, time_zone: @sel_zone, current_user: @current_user,
        chart_status: params[:chart_status]
      }
    end

    private

    def initialize_report_name
      @report_name ||= 'Internal Comment Report'
    end
    
    def initial_variables
      get_params_from_filters(params[:id], params[:from_method])
      default_values_for_reports
      save_filter_methods(@report_name)
      initialize_time_params
      params[:current_user_id] = @current_user.id
      @active = params[:ChkUsr].blank?
      @sel_client = params[:client]
      @clients =
        @current_user.work_type_names_based_on_role(@active).map { |w| [w.fullnamecode, w.id] }
    end
  end
end
