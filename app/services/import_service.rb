class ImportService < ApplicationService
  require('csv')

  # Make the following attributes accessible outside of the class
  attr_reader :imported_successfully, :imported_unsuccessfully, :total, :model, :file

  def initialize(model, file)
    @imported_successfully = 0
    @imported_unsuccessfully = 0
    @total = 0
    @model = model
    @file = file
    @target = @model.to_s.downcase.pluralize
  end

  def call
    csv = CSV.read(@file, headers: true)
    @total = csv.count

    render_import_table(csv)

    csv.each_with_index do |row, index|
      @record = @model.new(row.to_hash)
      @record.save ? import_success(index) : import_fail(index)
      update_progress_bar(index)
    end
    self # return ImportService object to attr_reader attributes can be accessed
  end
  
  private 

  # render the import table
  def render_import_table(csv)
    Turbo::StreamsChannel.broadcast_replace_to "import_#{@target}",
         target: @target, 
         partial: "layouts/shared/import_table", 
         locals: {csv: csv, target: @target}
  end
  
  # increment imported_successfully and broadcast to the import target
  def import_success(index)
    @imported_successfully +=1 
    Turbo::StreamsChannel.broadcast_update_to "import_#{@target}",
         target: "#{@target}_#{index}", 
         content: "<span class='px-3 py-2 text-sm text-green-800 rounded-lg bg-green-50'>Imported Successfully</span>"
  end

  # increment imported_unsuccessfully and broadcast to the import target
  def import_fail(index)
    @imported_unsuccessfully +=1
    Turbo::StreamsChannel.broadcast_update_to "import_#{@target}",
         target: "#{@target}_#{index}", 
         content: "<span class='px-3 py-2 text-sm text-red-800 rounded-lg bg-red-50'>#{@record.errors.full_messages.join(", ")}</span>"
  end

  # update the progress bar
  def update_progress_bar(index)
    Turbo::StreamsChannel.broadcast_update_to "import_#{@target}",
         target:'import_form', 
         partial: 'layouts/shared/progress_bar', 
         locals: { index: index+1, total: @total, percentage: percentage(index+1, @total) }
    sleep 0.01 # delay to update progress bar
  end

  # calculate the percentage of the progress bar
  def percentage(index, total)
    (index)*100/total
  end

end
