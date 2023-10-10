class Visitor < ApplicationRecord
  validates :name, presence: true
  validates :cpf, presence: true, uniqueness: true
end
