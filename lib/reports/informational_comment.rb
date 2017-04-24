# reports
module Reports
  require 'spreadsheet'
  # Informational Comment Report
  class InformationalComment
    attr_reader :work_type_ids, :from, :to, :current_user, :f_date, :t_date, :active, :time_zone,
                :report_level, :active, :chart_status
    def initialize(args = {})
      args.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def data
      work_types = WorkType.where(id: work_type_ids).select('id, facility_id, work_type_value_id')
      @data = work_types.each_with_object({}) do |work_type, hash|
        production_data = production_data(work_type)
        hash[work_type.full_name_code] =
          { work_type: work_type, data: production_data,
            count: production_data.pluck(:id).uniq.size } unless production_data.blank?
      end
      Hash[@data.sort]
    end

    def production_data(work_type)
      coder_id = current_user.coder_ids_for(work_type)
      work_type.production_accounts.internal_data(f_date, t_date, coder_id)
    end

    def export
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet name: 'internal_comment_report'
      sheet = spreadsheet_headers(sheet)
      width_hash = { 0 => 20, 1 => 20, 2 => 15, 3 => 50, 4 => 50, 5 => 25, 6 => 25, 7 => 30 }
      width_hash.each { |key, value| sheet.column(key).width = value }
      sheet = internal_comment_table(sheet)
      book
    end

    def internal_comment_table(sheet)
      table_column = Extensions::Format.new.table_column
      table_column_center = Extensions::Format.new.table_column_center
      i = 4
      data.each do |key, production_accounts|
        production_accounts[:data].each do |production_account|
          i += 1
          sheet.row(i).default_format = table_column
          sheet[i, 0] = Policy.new.display_in_time_zone(production_account.created_at, time_zone, 'date')
          sheet.row(i).set_format(0, table_column_center)
          sheet[i, 1] = production_account.account_number
        end
        i += 2
      end
    end

    def internal_spreadsheet_headers(sheet, i, format)
      sheet.row(i).default_format = format
      infor_comment_headers.each_with_index do |header, column|
        sheet[i, column] = header
      end
      [sheet, i]
    end

    def spreadsheet_headers(sheet)
      heading = Extensions::Format.new.heading
      green_color = Extensions::Format.new.green_color
      sheet.row(0).default_format = heading
      sheet.row(1).default_format = green_color
      sheet[0, 0] = 'Internal Comment Report'
      sheet[1, 0] = "Coded Date - #{period}"
      sheet[2, 0] = "Total Accounts - #{data.values.sum { |x| x[:count] } }"
      sheet[3, 0] = "Report Generated On - #{Date.today.to_s(:us_format)}"
      (0..3).each { |i| sheet.merge_cells(i, 0, i, 3) }
      (0..3).each { |i| sheet.row(i).height = 20 }
      sheet
    end

    def infor_comment_headers
      %w(Coded\ Date Account\ Number Service\ Date Categories Internal\ Comment
         Created\ On Coder Provider)
    end

    def period
      from.eql?(to) ? "#{from.to_date.to_s(:us_format)}" :
        "#{from.to_date.to_s(:us_format)} - #{to.to_date.to_s(:us_format)}"
    end
  end
end
