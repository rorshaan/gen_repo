class ImportFile < ApplicationRecord
  belongs_to :user, optional: true

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }
end
