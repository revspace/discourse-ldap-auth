class LDAPUser
  attr_reader :name, :email, :username, :user

  def initialize (auth_info)
    @name = auth_info[:name]
    @email = auth_info[:email]
    @username = auth_info[:nickname]
    @user = SiteSetting.ldap_lookup_users_by == 'username' ? User.find_by_username(@username) : User.find_by_email(@email)
    create_user_groups(auth_info[:groups]) unless self.account_exists?
  end

  def auth_result
    result = Auth::Result.new
    result.name = @name
    result.username = @username
    result.email = @email
    result.user = @user
    if result.respond_to? :overrides_username
      result.overrides_username = true if !account_exists?
    else
      # TODO: Remove once Discourse 2.8 stable is released
      result.omit_username = true
    end
    result.email_valid = true
    return result
  end

  def account_exists?
    return !@user.nil?
  end

  private
  def create_user_groups(user_groups)
    return if user_groups.nil?
    #user account must exist in order to create user groups
    @user = User.create!(name: self.name, email: self.email, username: self.username, approved: true, approved_by_id: Discourse.system_user.id, approved_at: Time.now)
    @user.activate
    user_groups.each do |group_name|
      group = Group.find_by(name: group_name)
      @user.groups << group unless group.nil?
    end
  end
end
