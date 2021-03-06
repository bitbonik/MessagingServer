require 'spec_helper'

describe User do
  
  let(:username) {'konker'}
  let(:password) {'password'}
  let(:first_name) {'conker'}
  let(:last_name) {'shocka'}
  let(:device_id) {'testId'}
  let(:user) { User.create username:username, password:password,
    first_name:first_name, last_name:last_name, id:1 }
  let(:contact) {FactoryGirl.create :user, username: :contact, id:2 }  
  let(:non_contact) {
    FactoryGirl.create :user, username: :non_contact, id:3 }

  describe 'Creating a new user' do
    it 'should fail if the username is blank' do
      user = User.create :password => password
      user.should be_new_record
    end
    
    it 'should fail if the password is blank' do
      user = User.create :username => username
      user.should be_new_record
    end
    
    it 'should fail if the username already exists' do
      user.should_not be_new_record
      
      new_user = User.create :username => username, :password => password,
        :first_name => first_name, :last_name => last_name  
      new_user.should be_new_record
    end
    
    it 'should contain the username and password it was created with' do
      user.username.should == username
      user.password.should == password
      user.should_not be_new_record
    end
    
    it 'should return the full name it was created with' do
      user.first_name.should == first_name
      user.last_name.should == last_name
      user.should_not be_new_record
    end
    
  end
  
  describe 'Api key' do
    it 'should create a new api key' do
      user.generate_api_key!
      user.api_key.should_not == nil
    end
    
    it 'should remove an existing api key' do
      api_key = user.generate_api_key!
      user.remove_api_key! api_key
      user.api_key.should == nil
    end
    
    it 'should be able to generate json with parameters required to instantiate a new session' do
      user_with_details = user.with_session_details.to_json
      user_with_details.should include "name"
      user_with_details.should include "username"
      user_with_details.should include "id"
      user_with_details.should include "api_key"
      user_with_details.should include "last_update"
    end
  end

  describe 'Generating JSON' do
    it 'should create JSON with limited fields for mobile requests' do
      json = user.to_json
      json.should include "first_name"
      json.should include "last_name"
      json.should include "username"
      json.should include "id"
      json.should_not include "password"
    end
  end
  
  describe 'Contact requests' do
    before :each do
      user.add_contact(contact)
      contact.accept_contact(user)
    end
    
    it 'should confirm if a user is contacts with it' do
      user.contacts_with(contact).should == true
      user.contacts_with(non_contact).should == false
    end
    
    it 'should form a contact connection between users' do
      user.contacts.where(id:contact.id).first
        .should == contact
    end
    
    it 'should accept new contact requests' do
      contact.accept_contact(user)
      user.relationships.where(contact_id:contact.id)
        .first.approved.should == :true.to_s
      contact.relationships.where(contact_id:user.id)
        .first.approved.should == :true.to_s
    end
    
    it 'should disconnect contacts' do
      user.remove_contact(contact)
      user.relationships.where(contact_id:contact.id)
        .first.approved.to_s.should == "false"
    end
  end
  
  describe 'Adding a device' do
    it 'should be able to add a new device' do
      user.add_device!(device_id)
      user.device_id.should == device_id
    end
    
    it 'should be able to remove a device' do
      user.add_device!(device_id)
      user.remove_device!(device_id)
      user.device_id.should == nil
    end
  end
  
  describe 'Adding a photo' do
    it 'should be able to add a photo to the aws bucket' do
      user.set_photo("axcfdsagerqw")
    end
    
    it 'should return json containing the url for the photo' do
      user.set_photo("axcfdsagerqw")
      json = user.to_json
      json.should include "image_url"
    end
    
  end
end

    