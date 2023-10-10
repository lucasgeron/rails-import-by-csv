require 'csv'

class ExportJob < ApplicationJob
  queue_as :default

  def perform(model, attributes)
    csv = CSV.generate(headers: true) do |csv|
      csv << attributes.map(&:to_s)
      model.all.each do |visitor|
        csv << attributes.map{ |attr| visitor.send(attr) }
      end
    end
  end

end
