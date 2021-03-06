class SchedulesController < ApplicationController
  before_filter :chk_user
  before_filter :new_sch ,:only =>  [:new,:create]
  before_filter :re_sch ,:only =>  [:edit,:update]
  before_filter :cancel_sch ,:only =>  [:remove,:destroy]
  def new_sch
    if !any_role?('Client', 'Schedule')
      redirect_to '/homes/index'
    end
  end
  def re_sch
    if !any_role?('Client', 'Re Schedule')
      redirect_to '/homes/index'
    end
  end
  def cancel_sch
    if !any_role?('Client', 'Cancel Schedule')
      redirect_to '/homes/index'
    end
  end
  def index
    if client?
      @schedules = Schedule.includes(:exam).filtered(params[:search],client).paginate(:page => params[:page], :per_page => 20)
    else
      @schedules = Schedule.includes(:exam).filtered(params[:search],nil).paginate(:page => params[:page], :per_page => 20)
    end
  end
  def show
    @schedule = Schedule.find(params[:id])
  end
  def new
    @exam=client.exams
    @schedule = Schedule.new
    @candidates= client.candidates
    @candidates.delete_if {|c| !c.user.isAlive || !c.schedule_id.nil?  }
  end
  def edit
    @exam=Exam.all
    @schedule = Schedule. find(params[:id])
    @schedule.sh_date=@schedule.sh_date.strftime("%b-%d-%Y  %I:%M%p")
    @candidates=Candidate.all
    @candidates.select!  {|c| (@schedule.candidates.include?(c) && c.user.isAlive) ||( c.schedule_id.nil? && c.user.isAlive) }
  end
  def create
    @schedule = Schedule.new(params[:schedule])
    @schedule.client = client
    @exam=Exam.all
    @candidates=Candidate.all
    @schedule.created_by=current_user.user_email
    @candidates.delete_if {|c| !c.user.isAlive || !c.schedule_id.nil?  }
    if params[:schedule][:candidate_ids].values.join.to_i==0
      flash[:error]="Please select at least one candidate. "
      redirect_to  new_schedule_path
      return
    end
    if @schedule.save
      call_rake :send_schedule_mail, :schedule_id => @schedule.id
      redirect_to schedules_path, notice: 'Exam was successfully scheduled.'
    else
      render "new"
    end
  end
  def update
    @schedule = Schedule.find(params[:id])
    @exam=Exam.all
    @candidates=Candidate.all
    @candidates.select!  {|c| (@schedule.candidates.include?(c) && c.user.isAlive) ||( c.schedule_id.nil? && c.user.isAlive) }
    params[:schedule][:updated_by]=current_user.user_email
    if params[:schedule][:candidate_ids].values.join.to_i==0
      flash.now[:error]="Please select at least one candidate. "
      render action: "edit"
      return
    end
    respond_to do |format|
      if @schedule.update_attributes(params[:schedule])
        call_rake :send_update_schedule_mail, :schedule_id => @schedule.id
        format.html { redirect_to @schedule, notice: 'Exam was successfully rescheduled.' }
      else
        format.html { render action: "edit" }
      end
    end
  end
  def destroy
    @schedule = Schedule.find(params[:id])
    @schedule.candidates.each{|c| UserMailer.cancel_schedule_email(c.user,@schedule).deliver }
    #@users=User.joins(:roles).where(roles: {role_name: "Get Schedule Email"})
    #@users.each {|admin| UserMailer.cancel_schedule_email(admin,@schedule).deliver }
    @schedule.destroy
    respond_to do |format|
      format.html { redirect_to schedules_url, notice: 'Schedule was successfully cancelled.' }
    end
  end
  def remove
    @schedule=Schedule.find(params[:id])
    @candidate=Candidate.find(params[:candidate_id])
    @schedule.candidates.delete(@candidate)
    @schedule.destroy if @schedule.candidates.empty?
    redirect_to schedule_path(@schedule) if !@schedule.candidates.empty?
    redirect_to schedules_path if @schedule.candidates.empty?
    UserMailer.cancel_schedule_email(@candidate.user,@schedule)
  end
  def chk_user
    if !any_role?('Client','Schedule','Re Schedule','Cancel Schedule')
      redirect_to '/homes/index'
    end
  end
end
