class UsersController < ApplicationController

  before_action :set_user, only: [:show, :edit, :update, :destroy]

  #load_and_authorize_resource

  def index
     #@users = User.all #paginate(:page => params[:page], :per_page => 10)
     user = User.new
     @response = user.balanced_associate_token_with_customer
  end

  def new
    @user = User.new
  end

  def show    
  end  
  
  def create
    @user = User.new(user_params)
    respond_to do |format|
    	if @user.save 
          format.html { redirect_to @user, notice: 'Welcome!' }
        	format.json { render action: 'show', status: :created, location: @user }
    	else
        	format.html { render action: 'new' }
        	format.json { render json: @user.errors, status: :unprocessable_entity }
    	end
  	end
  end

  def edit    
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'Profile updated!' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user.destroy
    respond_to do |format|
      format.html { redirect_to users_url, notice: 'Account deleted' }
      format.json { head :no_content }
    end
  end

private
    # Use callbacks to share common setup or constraints between actions.
    def set_user
      @user = User.find(params[:id])
    end

end

#  def update
 #   if @user.update_with_password(params[:user])
  #    flash[:success] = "Profile updated"
   #   sign_in @user
    #  redirect_to @user
    #else
     # render 'edit'
    #end
  #end
     #@user_books = UserBook.where(:user_id => current_user).paginate(:page => params[:page], :per_page => 10)  #find_all_by_user_id(@user.id, :include => [:book])   #find user's books for shelf view
    #@user_books_count = @user_books.count      #for shelf Nav count