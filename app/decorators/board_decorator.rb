# Board decorator
class BoardDecorator < Draper::Decorator
  delegate_all

  def section_width
    ordered_columns.size * object.column_width
  end

  def ordered_sections
    object.sections.order('section_order ASC')
  end

  def ordered_columns
    object.columns.order('column_order ASC')
  end
end
