require 'spec_helper'

describe ContactsController do
  let(:api_key) { 'this is a randomly generated key, I promise' }
  let(:user) { FactoryGirl.build :user, username: :user, id:1, api_key:api_key}
  let(:device_id) {'APA91bGX8xFj5OxWUJYIqqngMIqLE9r9d_DsQNSm38WtMmcZD6-wbjFfoEy-eOc_PeeXmcPdxIA_SwSuJ91hLR02Rasg9xuwmBc_FW8BGvvdC2v2kYoB9UXusuMFHQvJKiTXinyGYJkrK56H37R4N6HnmghbOV6SawrPPqMFwaAYvaFEMJ-bFNY'}
  let(:contact) { FactoryGirl.build :user, username: :contact, id:2,
    device_id:device_id}
  let(:otro_contact) { FactoryGirl.build :user, username: :antonio, id:3,
    device_id:device_id}
  
  before :each do
    User.should_receive(:find_by_id).with(user.id.to_s).and_return(user)
  end
  
  describe 'when properly authenticated' do
    before :each do
      User.should_receive(:exists?).at_least(0).times.and_return(true)
    end
    
    it 'should return 200 and a list of all valid and pending contacts' do
      get :show, :user_id => user.id, :api_key => user.api_key
      contacts = JSON.parse response.body
      
      contacts.should_not == nil
      response.status.should == 200
    end
    
    it 'The json returned should contain the approval status of the contacts' do
      user.save
      contact.save
      otro_contact.save
      contact.add_contact(user)
      user.add_contact(otro_contact)
      get :show, :user_id => user.id, :api_key => user.api_key
      contacts = JSON.parse response.body
      contacts.first.should include "approved"
    end
    
    it 'should not return removed contacts' do
      user.save
      contact.save
      contact.add_contact(user)
      user.remove_contact(contact)
      get :show, :user_id => user.id, :api_key => user.api_key
      contacts = JSON.parse response.body
      contacts.size.should == 0
      
    end
    
    describe 'Requests with specific contacts' do
    
      it 'should create a contact request' do
        User.should_receive(:find_by_username).with(contact.username.to_s)
          .at_least(1).times.and_return(contact)
        post :create, contact_username: contact.username,
          :user_id => user.id, :api_key => user.api_key
        response.status.should == 200
      end
      
      it 'should sent the request to the user' do
        User.should_receive(:find_by_username).with(contact.username.to_s)
          .at_least(1).times.and_return(contact)
        post :create, contact_username: contact.username,
            :user_id => user.id, :api_key => user.api_key
        
      end
  
      it 'should accept contact request' do
        User.should_receive(:find_by_id).with(contact.id.to_s)
          .at_least(1).times.and_return(contact)
        contact.save
        user.save
        contact.add_contact(user)
        put :update, contact_id: contact.id, accept:"true",
            :user_id => user.id, :api_key => user.api_key
        response.status.should == 200
      end
  
      it 'should return error if the wrong user accepts contact request' do
        User.should_receive(:find_by_id).with(contact.id.to_s)
          .at_least(1).times.and_return(contact)
        user.add_contact(contact)
        put :update, contact_id: contact.id, accept:"true",
            :user_id => user.id, :api_key => user.api_key
        response.status.should == 403
      end
  
      it 'should delete contacts' do
        User.should_receive(:find_by_id).with(contact.id.to_s)
          .at_least(1).times.and_return(contact)
        contact.save
        user.add_contact(contact)
        delete :destroy, contact_id: contact.id,
            :user_id => user.id, :api_key => user.api_key
        response.status.should == 200
      end
    end
  end
  
  it 'should return 404 if the contact does not exist' do
    post :create, contact_username: contact.username,
        :user_id => user.id, :api_key => user.api_key
    response.status.should == 404
  end
end