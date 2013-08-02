class FlightlinesController < ApplicationController
  # GET /flightlines
  # GET /flightlines.xml
  def index
    @flightlines = Flightline.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @flightlines }
    end
  end

  # GET /flightlines/1
  # GET /flightlines/1.xml
  def show
    @flightline = Flightline.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @flightline }
    end
  end

  # GET /flightlines/new
  # GET /flightlines/new.xml
  def new
    @flightline = Flightline.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @flightline }
    end
  end

  # GET /flightlines/1/edit
  def edit
    @flightline = Flightline.find(params[:id])
  end

  # POST /flightlines
  # POST /flightlines.xml
  def create
    @flightline = Flightline.new(params[:flightline])

    respond_to do |format|
      if @flightline.save
        format.html { redirect_to(@flightline, :notice => 'Flightline was successfully created.') }
        format.xml  { render :xml => @flightline, :status => :created, :location => @flightline }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @flightline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /flightlines/1
  # PUT /flightlines/1.xml
  def update
    @flightline = Flightline.find(params[:id])

    respond_to do |format|
      if @flightline.update_attributes(params[:flightline])
        format.html { redirect_to(@flightline, :notice => 'Flightline was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @flightline.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /flightlines/1
  # DELETE /flightlines/1.xml
  def destroy
    @flightline = Flightline.find(params[:id])
    @flightline.destroy

    respond_to do |format|
      format.html { redirect_to(flightlines_url) }
      format.xml  { head :ok }
    end
  end
end
