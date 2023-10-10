require 'csv'

class ImportJob < ApplicationJob
  queue_as :default

  def perform(model, file)
    
    Turbo::StreamsChannel.broadcast_replace_to 'importVisitors', target:'visitors', partial: 'visitors/import_table'
    
    imported_sucessfully = 0
    imported_unsucessfully = 0
    
    csv = CSV.read(file, headers: true)
    total = csv.count
    
    csv.each_with_index do |row, index|
      Turbo::StreamsChannel.broadcast_update_to 'importVisitors', target:'import_form', partial: 'visitors/progress_bar', locals: {percent: ((index+1)*100/total) }
      visitor = model.new(row.to_hash)
      visitor.save ? imported_sucessfully += 1 : imported_unsucessfully += 1
      visitor.broadcast_append_to 'importVisitors', partial: 'visitors/import_visitor', locals: {row: index} 
    end
    return{imported_sucessfully: imported_sucessfully, imported_unsucessfully: imported_unsucessfully, total: total}
  end
end
