class PrikeysController < ApplicationController
  # GET /prikeys
  # GET /prikeys.xml
  def index
    @prikeys = Prikey.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @prikeys }
    end
  end

  # GET /prikeys/1
  # GET /prikeys/1.xml
  def show
    @prikey = Prikey.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @prikey }
    end
  end

  # GET /prikeys/new
  # GET /prikeys/new.xml
  def new
    @prikey = Prikey.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @prikey }
    end
  end

  # GET /prikeys/1/edit
  def edit
    @prikey = Prikey.find(params[:id])
  end

  # POST /prikeys
  # POST /prikeys.xml
  def create
    @prikey = Prikey.new(params[:prikey])

    respond_to do |format|
      if @prikey.save
        format.html { redirect_to(@prikey, :notice => 'Prikey was successfully created.') }
        format.xml  { render :xml => @prikey, :status => :created, :location => @prikey }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @prikey.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /prikeys/1
  # PUT /prikeys/1.xml
  def update
    @prikey = Prikey.find(params[:id])

    respond_to do |format|
      if @prikey.update_attributes(params[:prikey])
        format.html { redirect_to(@prikey, :notice => 'Prikey was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @prikey.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /prikeys/1
  # DELETE /prikeys/1.xml
  def destroy
    @prikey = Prikey.find(params[:id])
    @prikey.destroy

    respond_to do |format|
      format.html { redirect_to(prikeys_url) }
      format.xml  { head :ok }
    end
  end
end
