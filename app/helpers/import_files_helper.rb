module ImportFilesHelper
	def status_color(status)
    case status
    when "pending" then "secondary"
    when "processing" then "warning"
    when "completed" then "success"
    when "failed" then "danger"
    else "dark"
    end
  end
end
