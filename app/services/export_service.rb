class ExportService < ApplicationService
  require('csv')

  def initialize(model, attributes)
    @model = model
    @attributes = attributes
  end
  
  def call
    csv = CSV.generate(headers: true) do |csv|
      csv << @attributes.map(&:to_s)
      @model.all.each do |record|
        csv << @attributes.map{ |attr| record.send(attr) }
      end
    end
  end

end
