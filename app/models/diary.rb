class GroupSumValidator < ActiveModel::Validator
  def validate(record)
    sum = options[:attributes].sum{|attribute| record.public_send(attribute).to_i}
    unless sum == options[:target]
      record.errors.add(:base, "sum of rates must equal 100")
    end
  end
end

class Diary < ApplicationRecord
  belongs_to :user
  validates :emo_1, presence: true
  validates :emo_2, presence: true, if: -> { emo_present?(:emo_3) }
  validate :emotions_are_unique
  validates :rate_1, presence: true, numericality: {greater_than:0, less_than_or_equal_to:100}
  validates :rate_2, presence: true, numericality: {greater_than:0, less_than_or_equal_to:100}, if: ->{emo_present?(:emo_2)}
  validates :rate_3, presence: true, numericality: {greater_than:0, less_than_or_equal_to:100}, if: ->{emo_present?(:emo_3)}
  validates_with GroupSumValidator, attributes: [:rate_1, :rate_2, :rate_3], target: 100
  validates :content, length:{maximum: 140}
  validates :flag, presence: true
  validates :day_no, presence: true
  validates :seq_no, presence: true


  private 
  def emo_present?(attr)
    public_send(attr).present?
  end


  def emotions_are_unique
    emos=[emo_1,emo_2,emo_3].compact
    unless emos.size==emos.uniq.size
      errors.add(:base, "emotions should be unique")
    end
  end

end


