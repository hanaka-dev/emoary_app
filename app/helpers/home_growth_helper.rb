# frozen_string_literal: true

module HomeGrowthHelper
  # 35 枚で 1 周。36 枚目からまた sprout 相当の見た目に戻る（表示するのはその周の「直近 N 枚」）
  CYCLE_SIZE = 35

  def self.visible_diary_count_for_total(total)
    return 0 if total.zero?

    ((total - 1) % CYCLE_SIZE) + 1
  end

  # ウィンドウ内の日記枚数に応じた成長フェーズ
  def home_growth_phase_for(count)
    case count
    when 0..2 then :sprout
    when 3..21 then :leaves
    else :tree
    end
  end

  def render_home_growth_svg(asset_basename, slot_to_diary, gradient_id_prefix, wrapper_class:)
    path = Rails.root.join("app/assets/images/#{asset_basename}.svg")
    raw = File.read(path)
    frag = Nokogiri::HTML::DocumentFragment.parse(raw)
    svg = frag.at_css("svg")
    return "".html_safe unless svg

    defs = Nokogiri::XML::Node.new("defs", svg.document)
    first_el = svg.elements.first
    if first_el
      first_el.add_previous_sibling(defs)
    else
      svg.add_child(defs)
    end

    svg.css("g.slot").each do |slot|
      key = slot["data-slot"]
      diary = slot_to_diary[key]
      leaf_path = slot.at_css("g.leaf path")
      if diary.present? && leaf_path
        grad_id = "#{gradient_id_prefix}_d#{diary.id}_s#{key}".gsub(/[^a-zA-Z0-9_-]/, "")
        append_linear_gradient(defs, svg.document, grad_id, diary.leaf_liquid_stops_for_svg)
        leaf_path["fill"] = "url(##{grad_id})"
        slot["data-diary-id"] = diary.id.to_s
        slot.remove_attribute("style")
        slot["class"] = slot_classes_without_empty(slot["class"])
      else
        slot.remove_attribute("style")
        slot.remove_attribute("aria-hidden")
        slot["class"] = (slot_classes_without_empty(slot["class"]) + [ "home-growth-slot--empty" ]).uniq.join(" ")
        if leaf_path
          leaf_path["fill"] = "none"
          leaf_path["stroke"] = "black" if leaf_path["stroke"].blank?
        end
      end
    end

    %(<div class="#{ERB::Util.html_escape(wrapper_class)}">#{svg.to_html}</div>).html_safe
  end

  def home_growth_slot_map_sprout(diaries)
    { "1" => diaries[0], "2" => diaries[1] }
  end

  def home_growth_slot_map_leaves_branch(diaries, branch_index)
    base = branch_index * 7
    (1..7).each_with_object({}) do |s, h|
      h[s.to_s] = diaries[base + s - 1]
    end
  end

  def home_growth_slot_map_tree(diaries)
    (1..35).each_with_object({}) do |s, h|
      h[s.to_s] = diaries[s - 1]
    end
  end

  def slot_classes_without_empty(class_string)
    class_string.to_s.split(/\s+/).reject { |c| c == "home-growth-slot--empty" }
  end
  private :slot_classes_without_empty

  def append_linear_gradient(defs, document, grad_id, stops)
    lg = Nokogiri::XML::Node.new("linearGradient", document)
    lg["id"] = grad_id
    lg["x1"] = "0%"
    lg["y1"] = "100%"
    lg["x2"] = "50%"
    lg["y2"] = "13.4%"
    stops.each do |offset, color|
      stop = Nokogiri::XML::Node.new("stop", document)
      stop["offset"] = "#{offset}%"
      stop["stop-color"] = color.to_s
      lg.add_child(stop)
    end
    defs.add_child(lg)
  end
  private :append_linear_gradient
end
