# compliance module
module Compliance
  # Extends Category model for compliance users
  module ExtendedCategory
    extend ActiveSupport::Concern

    included do
      scope :dx_audit_dx, lambda {
        where(parent: 0, code_type: %w(Dx audit_dx))
      }

      scope :px_audit_px, lambda {
        where(parent: 0, code_type: %w(px audit_px))
      }

      scope :drg, lambda {
        where(parent: 0, code_type: 'DRG')
      }

      scope :compliance_dx_categories, lambda {
        where(parent: Category.dx_audit_dx).order(:name)
      }

      scope :compliance_px_categories, lambda {
        where(parent: Category.px_audit_px).order(:name)
      }

      scope :compliance_drg_categories, lambda {
        where(parent: Category.drg).order(:name)
      }

      def self.dx_categories
        compliance_dx_categories.map { |x| [x.full_name, x.id] }
      end

      def self.px_categories
        compliance_px_categories.map { |x| [x.full_name, x.id] }
      end

      def self.drg_categories
        compliance_drg_categories.map { |x| [x.full_name, x.id] }
      end
    end
  end
end
