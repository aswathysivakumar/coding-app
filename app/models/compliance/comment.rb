# for compliance
module Compliance
  # for compliance comments
  class Comment < ActiveRecord::Base
    self.table_name = 'compliance_comments'
    attr_accessible :compliance_encounter_id, :content
    # associations
    belongs_to :encounter, class_name: 'Compliance::Encounter',
                           foreign_key: 'compliance_encounter_id'
    # scopes
    scope :find_encounter_id, ->(id) { where(compliance_encounter_id: id) }
  end
end
