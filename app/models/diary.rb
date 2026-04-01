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
  # boolean に presence: true すると false が常に無効になる（同日2枚目が保存できない）
  validates :flag, inclusion: { in: [ true, false ] }
  validates :day_no, presence: true
  validates :seq_no, presence: true

  after_destroy :reconcile_display_flags_after_destroy

  # 指定ユーザーの「その日（ユーザーTZの暦日）」のうち、created_at が最も早い1件だけ flag=true
  def self.reconcile_display_flags_for_user_journal_date!(user, journal_date, zone_name)
    Time.use_zone(zone_name) do
      range = journal_date.to_date.all_day
      ids = user.diaries.where(created_at: range).order(:created_at, :id).pluck(:id)
      return if ids.empty?

      user.diaries.where(id: ids).update_all(flag: false)
      user.diaries.where(id: ids.first).update_all(flag: true)
    end
  end

  # 感情情報の取り出し(emo_1~emo_3のいずれかの特定、呼び出し)
  def emo_data(n)
    EMOTIONS[self["emo_#{n}"]]
  end
  # 感情の名前の取り出し
  def emo_name(n)
    key = emo_data(n)[:key]
    I18n.t("emotions.#{key}")
  end
  # 感情の色の取り出し
  def emo_color(n)
    emo_data(n)[:color]
  end

  # 日記フォームの液体（linearGradient）と同じ比率の stop を SVG 用に返す
  # @return [Array<Array>] [[offset_percent, "#hex"], ...]
  def leaf_liquid_stops_for_svg
    items = (1..3).filter_map do |n|
      emo = public_send("emo_#{n}")
      rate = public_send("rate_#{n}")
      next if emo.blank? || rate.blank? || rate.to_i <= 0
      data = EMOTIONS[emo]
      next unless data
      color = data[:color] || data["color"]
      next if color.blank?
      { rate: rate.to_i, color: color.to_s }
    end
    return [[50.0, "#cccccc"]] if items.empty?

    cum = 0
    cum_arr = items.map { |it| cum += it[:rate]; cum }
    total = cum_arr.last.to_f
    items.each_with_index.map do |it, i|
      prev_cum = i.zero? ? 0 : cum_arr[i - 1]
      mid = prev_cum + it[:rate] / 2.0
      offset = total.positive? ? (mid / total * 100) : 0.0
      offset = [[offset, 100.0].min, 0.0].max
      [offset.round(4), it[:color]]
    end
  end

  private 
  def emo_present?(attr)
    public_send(attr).present?
  end

  def reconcile_display_flags_after_destroy
    u = User.find_by(id: user_id)
    return unless u

    zone = u.timezone_for_diaries
    journal_date = created_at.in_time_zone(zone).to_date
    Diary.reconcile_display_flags_for_user_journal_date!(u, journal_date, zone)
  end

  def emotions_are_unique
    emos=[emo_1,emo_2,emo_3].compact
    unless emos.size==emos.uniq.size
      errors.add(:base, "emotions should be unique")
    end
  end

end


