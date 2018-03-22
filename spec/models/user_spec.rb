require "rails_helper"
require 'lib/civicrm_spec'

describe User do
  let(:attr) { FactoryGirl.attributes_for :user }
  let(:user) { FactoryGirl.create(:user) }

  before(:each) do
    stub_civicrm
  end

  it_behaves_like "civicrm_user_methods"

  it "creates a new instance given a valid attributes" do
    User.create!(attr)
  end

  describe "password management" do
    it "resets password reset tokens upon email change" do
      user.update_attributes(reset_password_token: "stub_token")
      user.update_attributes(email: "2" + user.email)
      user.confirm
      expect(user.reset_password_token).to be_nil
    end

    it "resets password reset tokens upon password change" do
      user.update_attributes(reset_password_token: "stub_token")
      expect(user.reset_password_token).not_to be_nil
      user.update_attributes(password: "My new password is pretty great")
      expect(user.reset_password_token).to be_nil
    end

    it "allows new users to use weak passwords" do
      result = set_weak_password(user)
      expect(result).to be_truthy
    end

    it "makes sure admins are using strong passwords" do
      user = FactoryGirl.create(:user, admin: true)

      result = set_weak_password(user)
      expect(result).to be_falsey

      result = set_strong_password(user)
      expect(result).to be_truthy
    end

    it "allows users to reset their password when password_expired = false" do
      user = FactoryGirl.create(:user, password_expired: false)
      expect(set_strong_password(user)).to be_truthy
    end

    it "resets the password_expired flag when password changes" do
      user = FactoryGirl.create(:user, password_expired: true)
      set_strong_password(user)
      expect(user.password_expired).to be_falsey
    end
  end

  describe "track user actions" do
    let(:ahoy) { Ahoy::Tracker.new }
    let(:action_page) { FactoryGirl.create :action_page_with_petition }

    it "knows if the user has taken a given action" do
      ahoy.authenticate(user)
      track_signature(action_page)

      expect(user.taken_action?(action_page)).to be_truthy
    end

    it "ranks users" do
      record_several_actions
      expect(user.percentile_rank).to eq(50)
    end
  end
end

def record_several_actions
  FactoryGirl.create(:user)
  ahoy.authenticate(FactoryGirl.create(:user))
  3.times { track_signature(action_page) }

  ahoy.authenticate(FactoryGirl.create(:user))
  1.times { track_signature(action_page) }

  ahoy.authenticate(user)
  2.times { track_signature(action_page) }
  track_view(action_page)
end

def track_signature(action_page)
  ahoy.track "Action",
    { type: "action", actionType: "signature", actionPageId: action_page.id },
    action_page: action_page
end

def track_view(action_page)
  ahoy.track "View",
    { type: "action", actionType: "view", actionPageId: action_page.id },
    action_page: action_page
end
