class ContactsController < ApplicationController
  before_filter :authenticate_user
  before_filter :authorize_user
  before_filter :verify_contact, :only => [:create, :update, :destroy]
  
  def create
    connection = @current_user.add_contact(@contact)
    send_request_notification
    render :json => {:error => @contact.device_id}
  end
  
  def show
    contacts = []
    render :json => @current_user.relationships.where("approved <> ?", "false")
  end

  def update
    if params[:accept] && params[:accept] == true
      begin
        contact = @current_user.accept_contact(@contact)
        render :json => contact
      rescue Relationship::UnauthorizedError => error
        render status: :forbidden, :json => {:error => error.message}
      end
    end
  end

  def destroy
    removed_connection = @current_user.remove_contact(@contact)
    render :json => removed_connection
  end
  
  protected
  
  def authorize_user
    if @current_user.id.to_s != params[:id]
      return render :status => :forbidden, :json => {:error =>
        'Must be signed in as user to make request from it'}
    end
  end
  
  def verify_contact
    load_contact
    if !@contact
      render :status => :not_found,
        :json => {:error => "Contact not found"} and return
    end
  end

  def load_contact
    if params[:contact_id]
      @contact = User.find_by_id(params[:contact_id])
    elsif params[:contact_username]
      @contact = User.find_by_username(params[:contact_username]) 
    end
  end
  
  def send_request_notification
    return if @contact.device_id == nil
    
    device = Gcm::Device.find_by_registration_id(@contact.device_id)
    if !device
      device = Gcm::Device.create(:registration_id => @contact.device_id)
    end
    notification = Gcm::Notification.new
    notification.device = device
    notification.collapse_key = "updates_available"
    notification.delay_while_idle = false
    notification.data = {:registration_ids => [@contact.device_id], :data => 
      {:message_text => "User #{@current_user.username} has sent you a contact request"}}
    notification.save
    
    ApplicationHelper::send_notification(notification)
  end
end
