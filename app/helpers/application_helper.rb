module ApplicationHelper
  def can?(role)
     current_user&.has_role?(role.to_s)
   end

end
