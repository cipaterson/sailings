module ApplicationHelper
  def can?(role)
     current_user&.has_role?(role.to_s)
   end

  def sort_link(label, column)
    new_dir = (@sort == column && @direction == "asc") ? "desc" : "asc"
    indicator = if @sort == column
      @direction == "asc" ? " ▲" : " ▼"
    else
      ""
    end
    link_to "#{label}#{indicator}", { sort: column, direction: new_dir }
  end
end
