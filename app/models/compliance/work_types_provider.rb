# for compliance
module Compliance
  # for compliance providers worktypes
  class WorkTypesProvider < ActiveRecord::Base
    self.table_name = 'compliance_work_types_providers'
    attr_accessible :compliance_client_id, :compliance_work_type_id, :provider_id
    # associations
    belongs_to :comp_client, class_name: 'Compliance::Client',
                             foreign_key: 'compliance_client_id'
    belongs_to :comp_worktype, class_name: 'Compliance::WorkType',
                               foreign_key: 'compliance_work_type_id'
    belongs_to :provider
    # scopes
    scope :find_client_id, ->(value) { where('compliance_client_id IN (?)', value) }
    scope :find_wtype_id, ->(value) { where('compliance_work_type_id IN (?)', value) }
  end
end
