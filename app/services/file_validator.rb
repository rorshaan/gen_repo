class FileValidator
	EXPECTED_HEADERS = {
		"Channel One" => [
			"S. No.", "Transaction ID", "Sender Msisdn", "Transaction Amount", "Transaction Date and Time",
      "Transaction Type", "Receiver Msisdn", "Service Name", "Transaction Status",
      "Reference Number", "Previous Balance", "Post Balance", "external_transaction_id"
		],
		"Channel Two" => [
			"Receipt No.",	
			"Completion Time",
			"Initiation Time",
			"Details",	
			"Transaction Status",	
			"Currency",
			"Paid In",
			"Withdrawn",	
			"Balance",	
			"Reason Type",	
			"Opposite Party",	
			"Linked Transaction ID"
		],
		"Channel Three" => [
			"Transfer_ID",	
			"Refer_Number",	
			"Trans_Date",	
			"Prev Balance",	
			"Post Bal",	
			"Amount",	
			"Transfer_Status",	
			"MoneyPayer/Receiver",	
			"Account",	
			"Original_Txn_ID",	
			"Status_Change_date",	
		],
		"Channel Four" => [
			"S. No.",
			"Transaction ID",	
			"Sender Msisdn",	
			"Transaction Amount",	
			"Transaction Date and Time",	
			"Transaction Type",	
			"Receiver Msisdn",
			"Service Name",
			"Transaction Status",	
			"Reference Number",	
			"Previous Balance",	
			"Post Balance",	
			"external_transaction_id",
		],
		"Channel Five" => [
			"Receipt No.",	
			"Completion Time",	
			"Initiation Time",	
			"Details",	
			"Transaction Status",
			"Currency",	
			"Paid In",	
			"Withdrawn",	
			"Balance",	
			"Reason Type",	
			"Opposite Party",	
			"Linked Transaction ID"
		],
		"Channel Six" => [
			"Transfer_ID",	
			"Refer_Number",	
			"Trans_Date",	
			"Prev Balance",	
			"Post Bal",	
			"Amount",	
			"Transfer_Status",	
			"MoneyPayer/Receiver",	
			"Account",	
			"Status_Change_date"
		]
	}.freeze


	def self.expected_for(model_name)
    EXPECTED_HEADERS[model_name] || []
  end

# header_array: array of strings (from spreadsheet row(1) OR keys from JSON objects)
	def initialize(model_name, header_array)
    @model_name = model_name.to_s
    @header = Array(header_array).map { |h| h.to_s.strip }
    # @spreadsheet = spreadsheet
    # @header = spreadsheet.row(1).map(&:strip)
  end

  def valid?(strict: false)
  	expected = self.class.expected_for(@model_name).map(&:to_s)
  	return expected == @header if strict

  	# flexible: all expected headers must be present in given header (allow extra columns)
    (expected - @header).empty?
  end

  def missing_columns
    expected = self.class.expected_for(@model_name).map(&:to_s)
    expected - @header
  end

  def error_message
    missing = missing_columns
    return nil if missing.empty?
    "Missing columns for #{@model_name}: #{missing.join(', ')}"
  end
end