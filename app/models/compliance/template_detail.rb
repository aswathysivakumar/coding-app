# for saving template details of code category
module Compliance
  # class Template Detail
  class TemplateDetail < ActiveRecord::Base
    self.table_name = 'compliance_template_details'
    attr_accessible :template_values
    serialize :template_values, Hash
    belongs_to :comp_worktype, class_name: 'Compliance::WorkType',
                               foreign_key: 'compliance_work_type_id'
  end
end
