class ClientsController < ApplicationController
  before_action :set_client, only: [:show, :edit, :update, :destroy]
  before_action :chk_user
  def chk_user
    if !admin?
      redirect_to '/homes/index'
    end
  end
  # GET /clients
  def index
    @clients = Client.all
  end

  # GET /clients/1
  def show
  end

  # GET /clients/new
  def new
    @client = Client.new
    @client.build_user
  end

  # GET /clients/1/edit
  def edit
  end

  # POST /clients
  def create
    @client = Client.new(params[:client])
    @client.user.encrypt_password
    @client.user.roles.push(Role.find_by_role_name('Client'))
    if @client.save
      redirect_to @client, notice: 'Client was successfully created.'
    else
      render action: 'new'
    end
  end

  # PATCH/PUT /clients/1
  def update
    if @client.update(client_params)
      redirect_to @client, notice: 'Client was successfully updated.'
    else
      render action: 'edit'
    end
  end

  # DELETE /clients/1
  def destroy
    @client.destroy
    redirect_to clients_url, notice: 'Client was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_client
      @client = Client.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    #def client_params
    #  params.require(:client).permit(:name, :phone, :company, user: [])
    #end
end
