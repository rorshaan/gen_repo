class ImportFile < ApplicationRecord
  belongs_to :user, optional: true

  enum status: { pending: 0, processing: 1, completed: 2, failed: 3 }

  # return a public URL to error CSV (leading slash)
  def error_file_url
    return nil if error_file_path.blank?
    error_file_path.start_with?("/") ? error_file_path : "/#{error_file_path}"
  end

  def absolute_original_file_path
    return nil if file_path.blank?
    Rails.root.join("public", file_path)
  end

  def absolute_error_file_path
    return nil if error_file_path.blank?
    Rails.root.join("public", error_file_path)
  end
end
