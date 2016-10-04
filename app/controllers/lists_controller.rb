class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  before_action :find_user, only: [:index]
  respond_to :html

  def index
    @lists = List.all
    respond_with(@lists)
  end

  def show
    customers = UserList.where(:list_id => @list.id)
    @users = Array.new
    customers.each do |c|
      @users.push(User.find(c.user_id))
    end
    respond_with(@list,@users)

  end

  def new
    @list = List.new
    respond_with(@list)
  end

  def edit
  end

  def create
    @list = List.new(list_params)
    flash[:notice] = 'List was successfully created.' if @list.save
    respond_with(@list)
  end

  # This function creates a new lists and associates all customers that are on the list to it
  def create_new_list
    name = params[:list_name]
    @list = List.new(name:name, user_id:current_user.id)
    @list.save
    user_list = params[:selected_users].split(",")
    # Now save each customer on that list
    @customer_list_errors = Array.new
    user_list.each do |u|
      u = UserList.new(list_id:@list.id, user_id:u)
      @customer_list_errors.push(u.errors.full_messages) if !u.save
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update
    flash[:notice] = 'List was successfully updated.' if @list.update(list_params)
    respond_with(@list)
  end

  def destroy
    @list.destroy
    respond_with(@list)
  end

  private
    def set_list
      @list = List.find(params[:id])
    end

    def list_params
      params.require(:list).permit(:id,:name,:user_id)
    end

    def find_user
      @list = List.find_by(user_id:current_user.id)
    end
end
