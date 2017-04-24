# compliance module
module Compliance
  # common scope methods for codes - drg, apr_drg, ap_drg, tricare_drg, cpt, hcpcs, charge_code
  module CommonScopes
    extend ActiveSupport::Concern

    included do
      # Associations
      has_many :orig_codes, as: :orig_code_category, class_name: 'Compliance::Code'
      has_many :audit_codes, as: :audit_code_category, class_name: 'Compliance::Code'
      # Scopes
      scope :between_dates, lambda { |code, date_of_service|
        where('code = ? and ? between effective_from and effective_to', code, date_of_service)
      }
      scope :less_effective_to, lambda { |code, date_of_service|
        where('code = ? and effective_to <= ?', code, date_of_service)
      }
      scope :greater_effective_from, lambda { |code, date_of_service|
        where('code = ? and effective_from >= ?', code, date_of_service)
      }
    end
  end
end
