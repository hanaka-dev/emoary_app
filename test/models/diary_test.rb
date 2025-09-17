require "test_helper"

class DiaryTest < ActiveSupport::TestCase
  
  def setup
    @user = users(:michael)
    @diary = diaries(:one)
  end

  test "should be valid" do
    assert @diary.valid?
  end

  # 存在性制約
  test "user id should be present" do
    @diary.user = nil
    assert_not @diary.valid?
  end

  test "emo_1 should be present" do
    @diary.emo_1 = nil
    assert_not @diary.valid?
  end

  test "rate_1 should be present" do
    @diary.rate_1 = nil
    assert_not @diary.valid?
  end

  test "flag should be present" do
    @diary.flag = nil
    assert_not @diary.valid?
  end

  test "day_no should be present" do
    @diary.day_no = nil
    assert_not @diary.valid?
  end

  test "seq_no should be present" do
    @diary.seq_no = nil
    assert_not @diary.valid?
  end

  # 文字数制約
  test "content should be at most 140 characters" do
    @diary.content = "a"*141
    assert_not @diary.valid?
  end

  # 感情種別制約(emo_1~3は全て異なるべき。)
  test "emo_1 should be different from emo_2" do
    @diary.emo_2= @diary.emo_1
    assert_not @diary.valid?
  end
  
  test "emo_1 should be different from emo_3" do
    @diary.emo_3= @diary.emo_1
    assert_not @diary.valid?
  end
  
  test "emo_2 should be different from emo_3" do
    if !@diary.emo_2.nil? && !@diary.emo_3.nil?
      @diary.emo_3= @diary.emo_2
      assert_not @diary.valid?
    end
  end

  # emoがあるならrateもあるべき
  test "rate_1 should be present if emo_1 is present" do
    if !@diary.emo_1.nil?
      @diary.rate_1=nil
      assert_not @diary.valid?
    end
  end
  test "rate_2 should be present if emo_2 is present" do
    if !@diary.emo_2.nil?
      @diary.rate_2=nil
      assert_not @diary.valid?
    end
  end
  test "rate_3 should be present if emo_3 is present" do
    if !@diary.emo_3.nil?
      @diary.rate_3=nil
      assert_not @diary.valid?
    end
  end

  # emoは1から順に詰まっているべき
  test "emo2 should not be empty when emo3 exists" do
    @diary.assign_attributes(emo_2:nil, rate_2:nil, rate_3:50)
    assert_not @diary.valid?
  end

  # rateの値は1以上100以下
  test "rate_1 should be grater than 0" do
    if !@diary.emo_1.nil?
      @diary.assign_attributes(emo_3:nil, rate_1: 0, rate_2: 100, rate_3:0)
      assert_not @diary.valid?
      @diary.assign_attributes(emo_3:nil, rate_1: 1, rate_2: 99, rate_3:0)
      assert @diary.valid?
    end
  end
  test "rate_1 should be less than 101" do
    if !@diary.emo_1.nil?
      @diary.assign_attributes(emo_2:nil, emo_3:nil, rate_1: 100, rate_2: 0, rate_3:0)
      assert @diary.valid?
      @diary.assign_attributes(emo_2:nil, emo_3:nil, rate_1: 101, rate_2: 0, rate_3:0)
      assert_not @diary.valid?
    end
  end

  test "rate_2 should be grater than 0" do
    if !@diary.emo_2.nil?
      @diary.assign_attributes(emo_3:nil, rate_1: 100, rate_2: 0, rate_3:0)
      assert_not @diary.valid?
      @diary.assign_attributes(emo_3:nil, rate_1: 99, rate_2: 1, rate_3:0)
      assert @diary.valid?
    end
  end
  test "rate_2 should be less than 100" do
    if !@diary.emo_2.nil?
      @diary.assign_attributes(emo_3:nil, rate_1: 0, rate_2: 100, rate_3:0)
      assert_not @diary.valid?
      @diary.assign_attributes(emo_3:nil, rate_1: 1, rate_2: 99, rate_3:0)
      assert @diary.valid?
    end
  end

  test "rate_3 should be grater than 0" do
    if !@diary.emo_3.nil?
      @diary.assign_attributes(emo_2:nil, rate_1: 100, rate_2: 0, rate_3:0)
      assert_not @diary.valid?
      @diary.assign_attributes(emo_2: 2, emo_3: 3, rate_1: 98, rate_2: 1, rate_3:1)
      assert @diary.valid?
    end
  end
  test "rate_3 should be less than 100" do
    if !@diary.emo_3.nil?
      @diary.assign_attributes(emo_1:nil, emo_2:nil, rate_1: 0, rate_2: 0, rate_3:100)
      assert_not @diary.valid?
      @diary.assign_attributes(emo_1:1, emo_2:2, rate_1: 1, rate_2: 1, rate_3:98)
      assert @diary.valid?, @diary.errors.full_messages.to_sentence
    end
  end

  # rateの合計値は100
  test "sum of rates should not be anything other than 100" do
    @diary.rate_1=0
    assert_not @diary.valid?
  end
  
  test "sum of rates should be 100" do 
    assert @diary.valid?
  end

  


end
